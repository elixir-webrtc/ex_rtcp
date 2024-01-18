defmodule ExRTCP.Packet.TransportFeedback.CC.StatusVector do
  @moduledoc """
  Status Vector chunk contained by Transport-wide
  Congestion Control RTCP packets.
  """

  alias ExRTCP.Packet.TransportFeedback.CC

  @typedoc """
  Struct representing the Status Vector chunk.

  See `draft-holmer-rmcat-transport-wide-cc-extensions-01`,
  sec. 3.1.4 for further explanation.
  """
  @type t() :: %__MODULE__{
          symbols: [CC.status_symbol()]
        }

  @enforce_keys [:symbols]
  defstruct @enforce_keys

  @doc false
  @spec decode(binary()) :: {:ok, t(), [non_neg_integer()], binary()} | {:error, :invalid_packet}
  def decode(<<1::1, symbol_size::1, symbols::bitstring-14, rest::binary>>) do
    symbols =
      for <<raw_symbol::size(symbol_size + 1) <- symbols>> do
        CC.get_status_symbol(raw_symbol)
      end

    with {:ok, deltas, rest} <- parse_deltas(symbols, rest) do
      # notice that deltas is still reversed here,
      # so we can do a single Enum.reverse in `CC.parse_chunks`
      {:ok, %__MODULE__{symbols: symbols}, deltas, rest}
    end
  end

  def decode(_raw), do: {:error, :invalid_packet}

  defp parse_deltas(symbols, raw, acc \\ [])
  defp parse_deltas([], raw, acc), do: {:ok, acc, raw}

  defp parse_deltas([symbol | symbols], raw, acc)
       when symbol in [:not_received, :no_delta],
       do: parse_deltas(symbols, raw, acc)

  defp parse_deltas([symbol | symbols], raw, acc) do
    delta_size =
      case symbol do
        :small_delta -> 8
        :large_delta -> 16
      end

    case raw do
      <<delta::size(delta_size), rest::binary>> ->
        parse_deltas(symbols, rest, [delta | acc])

      _other ->
        {:error, :invalid_packet}
    end
  end
end
