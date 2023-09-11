defmodule ExRTCP.Packet.SenderReport do
  @moduledoc """
  Sender Report RTCP packet type (RFC 3550).
  """

  @behaviour ExRTCP.PacketTranscoder

  alias ExRTCP.Packet
  alias ExRTCP.Packet.ReceptionReport

  @typedoc """
  Struct representing Sender Report RTCP packet.
  """
  @type t() :: %__MODULE__{
          ssrc: Packet.uint32(),
          ntp_timestamp: Packet.uint64(),
          rtp_timestamp: Packet.uint32(),
          packet_count: Packet.uint32(),
          octet_count: Packet.uint32(),
          reports: [ReceptionReport.t()],
          profile_extension: binary()
        }

  @enforce_keys [:ssrc, :ntp_timestamp, :rtp_timestamp, :packet_count, :octet_count]
  defstruct @enforce_keys ++ [reports: [], profile_extension: <<>>]

  @impl true
  def encode(_packet) do
    # TODO implement this
    {<<>>, 0, 0}
  end

  @impl true
  def decode(
        <<
          ssrc::32,
          ntp_time::64,
          rtp_time::32,
          packet_count::32,
          octet_count::32,
          rest::binary
        >>,
        count
      ) do
    packet = %__MODULE__{
      ssrc: ssrc,
      ntp_timestamp: ntp_time,
      rtp_timestamp: rtp_time,
      packet_count: packet_count,
      octet_count: octet_count
    }

    with {:ok, reports, rest} <- ReceptionReport.decode(rest, count) do
      packet = %{packet | reports: reports, profile_extension: rest}
      {:ok, packet}
    end
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}
end
