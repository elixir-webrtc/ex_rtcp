defmodule ExRTCP.Packet.SenderReport do
  @moduledoc """
  Sender Report RTCP packet type (RFC 3550).
  """

  @behaviour ExRTCP.PacketTranscoder

  @typedoc """
  Struct representing Sender Report RTCP packet.
  """
  @type t() :: %__MODULE__{}

  defstruct []

  @impl true
  def encode(_packet) do
    {<<>>, 0, 0}
  end

  @impl true
  def decode(_raw, _count) do
    {:ok, %__MODULE__{}}
  end
end
