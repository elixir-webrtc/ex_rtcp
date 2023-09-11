defmodule ExRTCP.CompoundPacket do
  @moduledoc """
  Functionalities for decoding and encoding compound RTCP packets.
  """

  @doc """
  """
  @spec encode([struct()]) :: binary()
  def encode(_packets) do
    # TODO
    <<>>
  end

  @doc """
  """
  # TODO better type
  @spec decode(binary()) :: {:ok, [struct()]} | {:error, atom()}
  def decode(_raw) do
    # TODO
    {:ok, []}
  end
end
