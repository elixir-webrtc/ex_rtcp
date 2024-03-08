defmodule ExRTCP.Packet.PayloadFeedback.PLI do
  @moduledoc """
  Payload-specific Picture Loss Indication (PLI)
  packet type (`RFC 4585`, sec. 6.3.1).
  """

  alias ExRTCP.Packet

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 206
  @feedback_type 1

  @typedoc """
  Struct representing Payload-specific PLI feedback RTCP message.
  """
  @type t() :: %__MODULE__{
          sender_ssrc: Packet.uint32(),
          media_ssrc: Packet.uint32()
        }

  @enforce_keys [:sender_ssrc, :media_ssrc]
  defstruct @enforce_keys

  @impl true
  def encode(packet) do
    %__MODULE__{
      sender_ssrc: sender_ssrc,
      media_ssrc: media_ssrc
    } = packet

    encoded = <<sender_ssrc::32, media_ssrc::32>>

    {encoded, @feedback_type, @packet_type}
  end

  @impl true
  def decode(<<sender_ssrc::32, media_ssrc::32>>, _count) do
    packet = %__MODULE__{
      sender_ssrc: sender_ssrc,
      media_ssrc: media_ssrc
    }

    {:ok, packet}
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}
end
