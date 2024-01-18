defmodule ExRTCP.Packet.TransportFeedback.CC.RunLength do
  @moduledoc """
  Run Length chunk contained by Transport-wide
  Congestion Control RTCP packets.
  """

  alias ExRTCP.Packet
  alias ExRTCP.Packet.TransportFeedback.CC

  @typedoc """
  Struct representing the Run Length chunk.

  See `draft-holmer-rmcat-transport-wide-cc-extensions-01`,
  sec. 3.1.3 for further explanation.
  """
  @type t() :: %__MODULE__{
          status_symbol: CC.status_symbol(),
          run_length: Packet.uint13()
        }

  @enforce_keys [:status_symbol, :run_length]
  defstruct @enforce_keys

  @doc false
  @spec decode(binary()) :: {:ok, t(), [non_neg_integer()], binary()} | {:error, :invalid_packet}
  def decode(<<0::1, status_symbol::2, run_length::13, rest::binary>>) do
    with {:ok, status_symbol} <- CC.get_status_symbol(status_symbol),
         {:ok, deltas, rest} <- parse_deltas(status_symbol, rest, run_length) do
      chunk = %__MODULE__{
        status_symbol: status_symbol,
        run_length: run_length
      }

      # notice that deltas is still reversed here,
      # so we can do a single Enum.reverse in `CC.parse_chunks`
      {:ok, chunk, deltas, rest}
    end
  end

  def decode(_raw), do: {:error, :invalid_packet}

  defp parse_deltas(symbol, raw, count, acc \\ [])
  defp parse_deltas(:not_received, raw, _count, _acc), do: {:ok, [], raw}

  defp parse_deltas(:small_delta, raw, 0, acc), do: {:ok, acc, raw}

  defp parse_deltas(:small_delta, <<delta::8, rest::binary>>, count, acc) do
    parse_deltas(:small_delta, rest, count - 1, [delta | acc])
  end

  defp parse_deltas(:large_delta, raw, 0, acc), do: {:ok, acc, raw}

  defp parse_deltas(:large_delta, <<delta::16, rest::binary>>, count, acc) do
    parse_deltas(:large_delta, rest, count - 1, [delta | acc])
  end

  defp parse_deltas(_symbol, _raw, _count, _acc), do: {:error, :invalid_packet}
end
