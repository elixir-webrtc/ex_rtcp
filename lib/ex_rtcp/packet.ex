defmodule ExRTCP.Packet do
  @moduledoc """
  RTCP packet encoding and decoding functionalities.
  """

  @type uint8() :: 0..255
  @type uint16() :: 0..65_535
  @type uint24() :: 0..16_777_216
  @type uint32() :: 0..4_294_967_295
  @type uint64() :: 0..18_446_744_073_709_551_615

  @type packet() ::
          __MODULE__.SenderReport.t()
          | __MODULE__.ReceiverReport.t()
          | __MODULE__.SourceDescription.t()
          | __MODULE__.Goodbye.t()

  @typedoc """
  Possible `decode/1` errors.

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
  padding is added by default, must be multiple of 4, and smaller than 256
  """
  @spec encode(packet(), padding: uint8()) :: binary()
  def encode(packet, opts \\ [])

  def encode(%module{} = packet, opts) do
    {encoded, count, type} = module.encode(packet)

    {pad?, padding} =
      case Keyword.get(opts, :padding, 0) do
        0 ->
          {0, <<>>}

        pad_len ->
          if rem(pad_len, 4) != 0, do: raise("Padding length must be multiple of 4")
          {1, <<0::size(pad_len - 1)-unit(8), pad_len>>}
      end

    len = div(byte_size(encoded) + byte_size(padding), 4)

    <<2::2, pad?::1, count::5, type::8, len::16, encoded::binary, padding::binary>>
  end

  @doc """
  Decodes RTCP packet. Returns a struct representing the packet based on its type.

  This function assumes that passed binary is a packet of valid length and
  ignores `length` field in the header.
  """
  @spec decode(binary()) :: {:ok, packet()} | {:error, decode_error()}
  def decode(<<2::2, padding::1, count::5, type::8, _len::16, rest::binary>>) do
    with {:ok, raw} <- if(padding == 1, do: strip_padding(rest), else: {:ok, rest}),
         {:ok, module} <- get_type_module(type) do
      module.decode(raw, count)
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

  defp get_type_module(200), do: {:ok, __MODULE__.SenderReport}
  defp get_type_module(201), do: {:ok, __MODULE__.ReceiverReport}
  defp get_type_module(202), do: {:ok, __MODULE__.SourceDescription}
  defp get_type_module(203), do: {:ok, __MODULE__.Goodbye}
  defp get_type_module(_type), do: {:error, :unknown_type}
end
