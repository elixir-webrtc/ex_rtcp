defmodule ExRTCP.Packet.TransportFeedback.CC.StatusVector do
  @moduledoc """
  Status Vector chunk contained by Transport-wide
  Congestion Control RTCP packets.
  """

  alias ExRTCP.Packet.TransportFeedback.CC

  @typedoc """
  Struct representing the Status Vector chunk.

  `symbols` list length must be equal to either `7` or `14`.

  See `draft-holmer-rmcat-transport-wide-cc-extensions-01`,
  sec. 3.1.4 for further explanation.
  """
  @type t() :: %__MODULE__{
          symbols: [CC.status_symbol()]
        }

  @enforce_keys [:symbols]
  defstruct @enforce_keys

  @doc false
  @spec encode(t(), [float()]) :: {binary(), [float()]}
  def encode(%__MODULE__{symbols: symbols}, deltas) do
    symbol_size =
      case length(symbols) do
        14 -> 0
        7 -> 1
      end

    raw_symbols =
      for symbol <- symbols, into: <<>> do
        <<CC.get_status_raw(symbol)::size(symbol_size + 1)>>
      end

    raw_chunk = <<1::1, symbol_size::1, raw_symbols::bitstring>>
    {raw_deltas, rest_deltas} = encode_deltas(symbols, deltas)

    {raw_chunk <> raw_deltas, rest_deltas}
  end

  defp encode_deltas(symbols, deltas, acc \\ <<>>)
  defp encode_deltas([], deltas, acc), do: {acc, deltas}

  defp encode_deltas([symbol | symbols], deltas, acc)
       when symbol in [:not_received, :no_delta],
       do: encode_deltas(symbols, deltas, acc)

  defp encode_deltas([:small_delta | symbols], [delta | deltas], acc) do
    raw_delta = trunc(delta * 4)
    if raw_delta > 255, do: raise("Delta #{delta} is too big to fit in 1 byte")

    encode_deltas(symbols, deltas, <<acc::binary, raw_delta>>)
  end

  defp encode_deltas([:large_delta | symbols], [delta | deltas], acc) do
    raw_delta = trunc(delta * 4)
    if raw_delta > 65_535, do: raise("Delta #{delta} is too big to fit in 2 bytes")

    encode_deltas(symbols, deltas, <<acc::binary, raw_delta::16>>)
  end

  @doc false
  @spec decode(binary()) :: {:ok, t(), [float()], binary()} | {:error, :invalid_packet}
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
        parse_deltas(symbols, rest, [delta * 0.25 | acc])

      _other ->
        {:error, :invalid_packet}
    end
  end
end
