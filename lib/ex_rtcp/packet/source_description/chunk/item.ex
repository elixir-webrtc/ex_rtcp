defmodule ExRTCP.Packet.SourceDescription.Chunk.Item do
  @moduledoc """
  Item contained by chunks in Source Description RTCP packets.

  Includes items specified by `RFC 3550` as well as the MID SDES item
  specified in `RFC 8843`.
  """

  alias ExRTCP.Packet

  @type item_type() ::
          :cname
          | :name
          | :email
          | :phone
          | :location
          | :tool
          | :note
          | :priv
          | :mid

  @typedoc """
  Struct representing item contained by chunks in Source Description RTCP packets.

  Text must be shorter than 256 bytes.
  """
  @type t() :: %__MODULE__{
          type: item_type(),
          text: binary()
        }

  @enforce_keys [:type, :text]
  defstruct @enforce_keys

  @doc false
  @spec encode(t()) :: binary()
  def encode(%__MODULE__{type: item_type, text: text}) do
    id = type_to_id(item_type)

    <<id::8, byte_size(text)::8, text::binary>>
  end

  defp type_to_id(:cname), do: 1
  defp type_to_id(:name), do: 2
  defp type_to_id(:email), do: 3
  defp type_to_id(:phone), do: 4
  defp type_to_id(:location), do: 5
  defp type_to_id(:tool), do: 6
  defp type_to_id(:note), do: 7
  defp type_to_id(:priv), do: 8
  defp type_to_id(:mid), do: 15

  @doc false
  @spec decode(binary()) :: {:ok, t(), binary()} | {:error, Packet.decode_error()}
  def decode(<<id::8, len::8, text::binary-size(len), rest::binary>>) do
    item_type = id_to_type(id)

    if item_type != nil do
      {:ok, %__MODULE__{type: item_type, text: text}, rest}
    else
      {:error, :invalid_packet}
    end
  end

  def decode(_raw), do: {:error, :invalid_packet}

  defp id_to_type(1), do: :cname
  defp id_to_type(2), do: :name
  defp id_to_type(3), do: :email
  defp id_to_type(4), do: :phone
  defp id_to_type(5), do: :location
  defp id_to_type(6), do: :tool
  defp id_to_type(7), do: :note
  defp id_to_type(8), do: :priv
  defp id_to_type(15), do: :mid
  defp id_to_type(_other), do: nil
end
