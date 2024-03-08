defmodule ExRTCP.Packet.PayloadFeedback.FIR do
  @moduledoc """
  Payload-specific Full Intra Request (FIR)
  packet type (`RFC 5104`, sec. 4.3.1).
  """

  alias ExRTCP.Packet

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 206
  @feedback_type 4

  @type entry() :: %{
          ssrc: Packet.uint32(),
          seq_nr: Packet.uint8()
        }

  @typedoc """
  Struct representing Payload-specific FIR feedback RTCP message.
  """
  @type t() :: %__MODULE__{
          sender_ssrc: Packet.uint32(),
          media_ssrc: Packet.uint32(),
          entries: [entry()]
        }

  @enforce_keys [:sender_ssrc, :media_ssrc]
  defstruct [entries: []] ++ @enforce_keys

  @impl true
  def encode(packet) do
    %__MODULE__{
      sender_ssrc: sender_ssrc,
      media_ssrc: media_ssrc,
      entries: entries
    } = packet

    encoded_entries = encode_entries(entries)
    encoded = <<sender_ssrc::32, media_ssrc::32, encoded_entries::binary>>

    {encoded, @feedback_type, @packet_type}
  end

  defp encode_entries(entries, acc \\ <<>>)
  defp encode_entries([], acc), do: acc

  defp encode_entries([entry | entries], acc) do
    %{ssrc: ssrc, seq_nr: seq_nr} = entry
    encoded = <<ssrc::32, seq_nr::8, 0::24>>

    encode_entries(entries, acc <> encoded)
  end

  @impl true
  def decode(<<sender_ssrc::32, media_ssrc::32, rest::binary>>, _count) do
    with {:ok, entries} <- decode_entries(rest) do
      packet = %__MODULE__{
        sender_ssrc: sender_ssrc,
        media_ssrc: media_ssrc,
        entries: entries
      }

      {:ok, packet}
    end
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}

  defp decode_entries(raw, acc \\ [])
  defp decode_entries(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_entries(<<ssrc::32, seq_nr::8, 0::24, rest::binary>>, acc) do
    entry = %{ssrc: ssrc, seq_nr: seq_nr}
    decode_entries(rest, [entry | acc])
  end

  defp decode_entries(_raw, _acc), do: {:error, :invalid_packet}
end
