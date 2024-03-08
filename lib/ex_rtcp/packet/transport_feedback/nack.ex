defmodule ExRTCP.Packet.TransportFeedback.NACK do
  @moduledoc """
  Transport layer feedback message with generic NACKs
  packet type (`RFC 4585`, sec. 6.2.1).
  """

  alias ExRTCP.Packet

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 205
  @feedback_type 1

  @typedoc """
  Generic NACK message, as described in `RFC 4585`, sec. 6.2.1.
  `blp` must be a 16-bit binary.
  """
  @type generic_nack() :: %{
          pid: Packet.uint16(),
          blp: binary()
        }

  @typedoc """
  Struct representing Transport layer NACK feedback RTCP message.
  """
  @type t() :: %__MODULE__{
          sender_ssrc: Packet.uint32(),
          media_ssrc: Packet.uint32(),
          nacks: [generic_nack()]
        }

  @enforce_keys [:sender_ssrc, :media_ssrc]
  defstruct [nacks: []] ++ @enforce_keys

  @impl true
  def encode(packet) do
    %__MODULE__{
      sender_ssrc: sender_ssrc,
      media_ssrc: media_ssrc,
      nacks: nacks
    } = packet

    encoded_nacks = encode_nacks(nacks)
    encoded = <<sender_ssrc::32, media_ssrc::32, encoded_nacks::binary>>

    {encoded, @feedback_type, @packet_type}
  end

  defp encode_nacks(nacks, acc \\ <<>>)
  defp encode_nacks([], acc), do: acc

  defp encode_nacks([nack | nacks], acc) do
    %{pid: pid, blp: blp} = nack
    encoded = <<pid::16, blp::binary-size(2)>>

    encode_nacks(nacks, acc <> encoded)
  end

  @impl true
  def decode(<<sender_ssrc::32, media_ssrc::32, rest::binary>>, _count) do
    with {:ok, nacks} <- decode_nacks(rest) do
      packet = %__MODULE__{
        sender_ssrc: sender_ssrc,
        media_ssrc: media_ssrc,
        nacks: nacks
      }

      {:ok, packet}
    end
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}

  defp decode_nacks(raw, acc \\ [])
  defp decode_nacks(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_nacks(<<pid::16, blp::binary-size(2), rest::binary>>, acc) do
    nack = %{pid: pid, blp: blp}
    decode_nacks(rest, [nack | acc])
  end

  defp decode_nacks(_raw, _acc), do: {:error, :invalid_packet}
end
