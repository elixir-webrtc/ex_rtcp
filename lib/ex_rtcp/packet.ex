defmodule ExRTCP.Packet do
  @moduledoc """
  RTCP packet encoding and decoding functionalities.
  """

  @type uint8() :: 0..255
  @type uint16() :: 0..65_535
  @type uint32() :: 0..4_294_967_295

  @typedoc """
  Possible `decode/1` errors:

    * `:invalid_packet` - this binary could not be parsed as a valid RTCP packet
    * `:unknown_type` - this type of RTCP packet is not supported or does not exist
  """
  @type decode_error() ::
          :invalid_packet
          | :unknown_type

  @doc """
  Encodes the packet and returns the resulting binary.

  Options:

    * `padding` - number of padding bytes added to packet, no
  padding is added by default
  """
  @spec encode(struct(), padding: uint8()) :: binary()
  def encode(packet, opts \\ [])

  def encode(packet, opts) do
    # TODO
    <<>>
  end

  @doc """
  Decodes RTCP packet. Returns a struct representing the packet based on its type.
  """
  @spec decode(binary()) :: {:ok, struct()} | {:error, decode_error()}
  def decode(<<2::2, padding::1, count::5, type::8, _len::16, rest::binary>>) do
    with {:ok, raw} <- if(padding == 1, do: strip_padding(rest), else: {:ok, rest}) do
      decode_as(type, count, raw)
    end
  end

  defp strip_padding(raw) do
    size = byte_size(raw)

    with <<_rest::binary-size(size - 1), len>> <- raw,
         <<rest::binary-size(size - len), _rest::binary>> <- raw do
      {:ok, rest}
    else
      _other -> {:error, :invalid_packet}
    end
  end

  defp decode_as(200, _count, raw), do: __MODULE__.SenderReport.decode(raw)
  defp decode_as(201, _count, raw), do: __MODULE__.ReceiverReport.decode(raw)
  defp decode_as(203, count, raw), do: __MODULE__.Goodbye.decode(raw, count)
  defp decode_as(_type, _count, _raw), do: {:error, :unknown_type}
end
