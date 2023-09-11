defmodule ExRTCP.CompoundPacket do
  @moduledoc """
  Functionalities for decoding and encoding compound RTCP packets.
  """

  alias ExRTCP.Packet

  @doc """
  Encodes the packets as a compound packet and returns the resulting binary.

  Options:

    * `padding` - number of padding bytes added to the last packet, no
  padding is added by default, must be multiple of 4
  """
  @spec encode([struct()], padding: Packet.uint8()) :: binary()
  def encode(_packets, _opts \\ []) do
    # TODO
    <<>>
  end

  @doc """
  """
  @spec decode(binary()) :: {:ok, [struct()]} | {:error, atom()}
  def decode(raw) do
    case split_packets(raw) do
      {:error, _reason} = err -> err
      {:ok, []} -> {:error, :invalid_packet}
      {:ok, packets} -> {:ok, Enum.reverse(packets)}
    end
  end

  defp split_packets(raw, acc \\ [])
  defp split_packets(<<>>, acc), do: {:ok, acc}

  defp split_packets(raw, acc) do
    case get_packet(raw) do
      {:ok, :unknown_type, raw} -> split_packets(raw, acc)
      {:ok, packet, raw} -> split_packets(raw, [packet | acc])
      {:error, :invalid_packet} -> {:error, :invalid_packet}
    end
  end

  defp get_packet(<<_::16, len::16, _::binary>> = raw) do
    case raw do
      <<packet::binary-size(len * 4), rest::binary>> ->
        case Packet.decode(packet) do
          {:ok, packet} -> {:ok, packet, rest}
          {:error, :unknown_type} -> {:ok, :unknown_type, rest}
          {:error, _reason} = err -> err
        end

      _other ->
        {:error, :invalid_packet}
    end
  end

  defp get_packet(_raw), do: {:error, :invalid_packet}
end
