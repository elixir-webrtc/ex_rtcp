defmodule ExRTCP.PacketTranscoder do
  @moduledoc false

  alias ExRTCP.Packet

  @type count() :: 0..31

  # Takes struct defined by module implementing this behaviour.
  # Returns `{encoded packet (w/o header), count (to decode in the header), packet type}`
  @callback encode(struct()) :: {binary(), count(), Packet.uint8()}

  # Takes encoded packet (w/o header) and count (from packet header)
  # Returns struct defined by module implementing this behaviour
  @callback decode(binary(), count()) :: {:ok, struct()} | {:error, Packet.decode_error()}
end
