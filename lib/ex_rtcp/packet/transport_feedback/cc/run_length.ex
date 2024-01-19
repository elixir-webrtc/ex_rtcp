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
  @spec encode(t(), [float()]) :: {binary(), [float()]}
  def encode(chunk, deltas) do
    %__MODULE__{
      status_symbol: status_symbol,
      run_length: run_length
    } = chunk

    raw_status = CC.get_status_raw(status_symbol)
    raw_chunk = <<0::1, raw_status::2, run_length::13>>
    {raw_deltas, rest_deltas} = encode_deltas(status_symbol, run_length, deltas)

    {raw_chunk <> raw_deltas, rest_deltas}
  end

  defp encode_deltas(symbol, count, deltas, acc \\ <<>>)

  defp encode_deltas(symbol, _count, deltas, _acc)
       when symbol in [:not_received, :no_delta],
       do: {<<>>, deltas}

  defp encode_deltas(_symbol, 0, deltas, acc), do: {acc, deltas}

  defp encode_deltas(:small_delta, count, [delta | deltas], acc) do
    raw_delta = trunc(delta * 4)
    if raw_delta > 255, do: raise("Delta #{delta} is too big to fit in 1 byte")

    encode_deltas(:small_delta, count - 1, deltas, <<acc::binary, raw_delta>>)
  end

  defp encode_deltas(:large_delta, count, [delta | deltas], acc) do
    raw_delta = trunc(delta * 4)
    if raw_delta > 65_535, do: raise("Delta #{delta} is too big to fit in 2 bytes")

    encode_deltas(:large_delta, count - 1, deltas, <<acc::binary, raw_delta::16>>)
  end

  @doc false
  @spec decode(binary()) :: {:ok, t(), [float()], binary()} | {:error, :invalid_packet}
  def decode(<<0::1, raw_symbol::2, run_length::13, rest::binary>>) do
    status_symbol = CC.get_status_symbol(raw_symbol)

    with {:ok, deltas, rest} <- parse_deltas(status_symbol, rest, run_length) do
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

  defp parse_deltas(symbol, raw, _count, _acc)
       when symbol in [:not_received, :no_delta],
       do: {:ok, [], raw}

  defp parse_deltas(:small_delta, raw, 0, acc), do: {:ok, acc, raw}

  defp parse_deltas(:small_delta, <<delta::8, rest::binary>>, count, acc) do
    parse_deltas(:small_delta, rest, count - 1, [delta * 0.25 | acc])
  end

  defp parse_deltas(:large_delta, raw, 0, acc), do: {:ok, acc, raw}

  defp parse_deltas(:large_delta, <<delta::16, rest::binary>>, count, acc) do
    parse_deltas(:large_delta, rest, count - 1, [delta * 0.25 | acc])
  end

  defp parse_deltas(_symbol, _raw, _count, _acc), do: {:error, :invalid_packet}
end
