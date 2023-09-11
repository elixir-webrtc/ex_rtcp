defmodule ExRTCP.Packet.Goodbye do
  @moduledoc """
  Goodbye RTCP packet type (RFC 3550).
  """

  alias ExRTCP.Packet

  @packet_type 203

  @typedoc """
  Struct representing Goodbye RTCP packet.
  """
  @type t() :: %__MODULE__{
          sources: [Packet.uint32()],
          reason: String.t() | nil
        }

  @enforce_keys [:sources]
  defstruct @enforce_keys ++ [reason: nil]

  @doc false
  @spec encode(t()) :: {binary(), non_neg_integer(), non_neg_integer()}
  def encode(packet) do
    sources = encode_sources(packet.sources)
    reason = encode_reason(packet.reason)

    {sources <> reason, length(packet.sources), @packet_type}
  end

  defp encode_sources(sources, acc \\ <<>>)
  defp encode_sources([], acc), do: acc

  defp encode_sources([ssrc | rest], acc),
    do: encode_sources(rest, <<ssrc::32, acc::binary>>)

  defp encode_reason(nil), do: <<>>

  defp encode_reason(reason) do
    len = byte_size(reason)

    pad_len =
      case rem(len, 4) do
        0 -> 0
        other -> 4 - other
      end

    <<len::8, reason::binary, 0::pad_len*8>>
  end

  @doc false
  @spec decode(binary(), non_neg_integer()) :: {:ok, t()} | {:error, Packet.decode_error()}
  def decode(raw, count) do
    with {:ok, sources, raw} <- decode_sources(raw, count),
         {:ok, reason} <- decode_reason(raw) do
      {:ok,
       %__MODULE__{
         sources: sources,
         reason: reason
       }}
    end
  end

  defp decode_sources(raw, count, acc \\ [])
  defp decode_sources(raw, 0, acc), do: {:ok, acc, raw}

  defp decode_sources(<<ssrc::32, rest::binary>>, count, acc),
    do: decode_sources(rest, count - 1, [ssrc | acc])

  defp decode_sources(_raw, _count, _acc), do: {:error, :invalid_packet}

  defp decode_reason(<<>>), do: {:ok, nil}
  defp decode_reason(<<len::8, reason::binary-size(len), _rest::binary>>), do: {:ok, reason}
  defp decode_reason(_raw), do: {:error, :invalid_packet}
end
