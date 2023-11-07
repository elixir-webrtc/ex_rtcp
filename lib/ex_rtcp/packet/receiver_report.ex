defmodule ExRTCP.Packet.ReceiverReport do
  @moduledoc """
  Receiver Report RTCP packet type (`RFC 3550`).
  """

  alias ExRTCP.Packet
  alias ExRTCP.Packet.ReceptionReport

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 201

  @typedoc """
  Struct representing Receiver Report RTCP packet.

  Number of reception reports is always less than 32 for a single receiver report.
  """
  @type t() :: %__MODULE__{
          ssrc: Packet.uint32(),
          reports: [ReceptionReport.t()],
          profile_extension: binary()
        }

  @enforce_keys [:ssrc]
  defstruct @enforce_keys ++ [reports: [], profile_extension: <<>>]

  @impl true
  def encode(%__MODULE__{ssrc: ssrc, reports: reports, profile_extension: extension}) do
    encoded_reports = ReceptionReport.encode(reports)
    encoded = <<ssrc::32, encoded_reports::binary, extension::binary>>

    {encoded, length(reports), @packet_type}
  end

  @impl true
  def decode(<<ssrc::32, rest::binary>>, count) do
    packet = %__MODULE__{ssrc: ssrc}

    with {:ok, reports, rest} <- ReceptionReport.decode(rest, count) do
      packet = %{packet | reports: reports, profile_extension: rest}
      {:ok, packet}
    end
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}
end
