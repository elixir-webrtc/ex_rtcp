defmodule ExRTCP.Packet.SourceDescription.Chunk do
  @moduledoc """
  Chunk contained by Source Description RTCP packets.
  """

  alias ExRTCP.Packet
  alias ExRTCP.Packet.SourceDescription.Chunk.Item

  @typedoc """
  Struct representing chunk contained by Source Description RTCP packets.
  """
  @type t() :: %__MODULE__{
          ssrc: Packet.uint32(),
          items: [Item.t()]
        }

  @enforce_keys [:ssrc]
  defstruct @enforce_keys ++ [items: []]

  @doc false
  @spec encode(t()) :: binary()
  def encode(%__MODULE__{ssrc: ssrc, items: items}) do
    encoded_items = for item <- items, do: Item.encode(item), into: <<>>

    pad_len = 4 - rem(byte_size(encoded_items), 4)
    <<ssrc::32, encoded_items::binary, 0::pad_len*8>>
  end

  @doc false
  @spec decode(binary()) :: {:ok, t(), binary()} | {:error, Packet.decode_error()}
  def decode(<<ssrc::32, raw::binary>>) do
    case do_decode(raw) do
      {:ok, items, rest} -> {:ok, %__MODULE__{ssrc: ssrc, items: items}, rest}
      {:error, _reason} = err -> err
    end
  end

  def decode(_raw), do: {:error, :invalid_packet}

  defp do_decode(raw, acc \\ [])

  defp do_decode(<<0::8, rest::binary>>, acc) do
    rest = strip_zeros(rest)
    {:ok, acc, rest}
  end

  defp do_decode(raw, acc) do
    case Item.decode(raw) do
      {:ok, item, rest} -> do_decode(rest, [item | acc])
      {:error, _reason} = err -> err
    end
  end

  defp strip_zeros(<<0::8, rest::binary>>), do: strip_zeros(rest)
  defp strip_zeros(raw), do: raw
end
