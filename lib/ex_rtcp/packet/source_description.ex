defmodule ExRTCP.Packet.SourceDescription do
  @moduledoc """
  Source Description RTCP packet type (`RFC 3550`).
  """

  alias ExRTCP.Packet.SourceDescription.Chunk

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 202

  @typedoc """
  Struct representing Source Description RTCP packet.

  Number of chunks is always less than 32 for a single source description packet.
  """
  @type t() :: %__MODULE__{
          chunks: [Chunk.t()]
        }

  defstruct chunks: []

  @impl true
  def encode(%__MODULE__{chunks: chunks}) do
    encoded = for chunk <- chunks, do: Chunk.encode(chunk), into: <<>>

    {encoded, length(chunks), @packet_type}
  end

  @impl true
  def decode(raw, count) do
    case do_decode(raw, count) do
      {:ok, chunks} -> {:ok, %__MODULE__{chunks: chunks}}
      {:error, _reson} = err -> err
    end
  end

  defp do_decode(raw, count, acc \\ [])
  defp do_decode(<<>>, 0, acc), do: {:ok, Enum.reverse(acc)}
  defp do_decode(<<>>, _count, _acc), do: {:error, :invalid_packet}

  defp do_decode(raw, count, acc) do
    case Chunk.decode(raw) do
      {:ok, chunk, rest} -> do_decode(rest, count - 1, [chunk | acc])
      {:error, _reason} = err -> err
    end
  end
end
