defmodule ExRTCP.Packet.Goodbye do
  @moduledoc """
  Goodbye RTCP packet type (RFC 3550).
  """

  alias ExRTCP.Packet

  @typedoc """
  Struct representing Goodbye RTCP packet.
  """
  @type t() :: %__MODULE__{
          ssrc: [Packet.uint32()],
          reason: String.t() | nil
        }

  @enforce_keys [:ssrc]
  defstruct @enforce_keys ++ [reason: nil]

  @doc false
  @spec decode(binary(), non_neg_integer()) :: {:ok, t()} | {:error, Packet.decode_error()}
  def decode(raw, count) do
    with {:ok, ssrc, raw} <- decode_ssrc(raw, count),
         {:ok, reason} <- decode_reason(raw) do
      {:ok,
       %__MODULE__{
         ssrc: ssrc,
         reason: reason
       }}
    end
  end

  defp decode_ssrc(raw, count, acc \\ [])
  defp decode_ssrc(raw, 0, acc), do: {:ok, acc, raw}

  defp decode_ssrc(<<ssrc::32, rest::binary>>, count, acc),
    do: decode_ssrc(rest, count - 1, [ssrc | acc])

  defp decode_ssrc(_raw, _count, _acc), do: {:error, :invalid_packet}

  defp decode_reason(<<>>), do: {:ok, nil}
  defp decode_reason(<<len::8, reason::binary-size(len), _rest::binary>>), do: {:ok, reason}
  defp decode_reason(_raw), do: {:error, :invalid_packet}
end
