defmodule ExRTCP.CompoundPacket do
  @moduledoc """
  Functionalities for decoding and encoding compound RTCP packets.
  """

  alias ExRTCP.Packet

  @doc """
  """
  @spec encode([struct()]) :: binary()
  def encode(packets) do
    # TODO
    <<>>
  end

  @doc """
  """
  # TODO better type
  @spec decode(binary()) :: {:ok, [struct()]} | {:error, atom()}
  def decode(raw) do
    # TODO
    []
  end
end
