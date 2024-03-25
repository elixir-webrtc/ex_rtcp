defmodule ExRTCP.Packet.TransportFeedback.CC do
  @moduledoc """
  Transport-wide Congestion Control Feedback packet type
  (`draft-holmer-rmcat-transport-wide-cc-extensions-01`).
  """

  alias ExRTCP.Packet

  @type siema() :: atom()

  defmodule RunLength do
    @moduledoc """
    Run Length chunk contained by Transport-wide
    Congestion Control RTCP packets.
    """

    alias ExRTCP.Packet.TransportFeedback.CC

    @typedoc """
    Struct representing the Run Length chunk.

    See `draft-holmer-rmcat-transport-wide-cc-extensions-01`,
    sec. 3.1.3 for further explanation.
    """
    @type t() :: %__MODULE__{
            status_symbol: CC.status_symbol(),
            run_length: Packet.uint13()
          }

    @enforce_keys [:status_symbol, :run_length]
    defstruct @enforce_keys
  end

  defmodule StatusVector do
    @moduledoc """
    Status Vector chunk contained by Transport-wide
    Congestion Control RTCP packets.
    """

    alias ExRTCP.Packet.TransportFeedback.CC

    @typedoc """
    Struct representing the Status Vector chunk.

    `symbols` list length must be equal to either `7` or `14`.

    See `draft-holmer-rmcat-transport-wide-cc-extensions-01`,
    sec. 3.1.4 for further explanation.
    """
    @type t() :: %__MODULE__{
            symbols: [CC.status_symbol()]
          }

    @enforce_keys [:symbols]
    defstruct @enforce_keys
  end

  @behaviour ExRTCP.PacketTranscoder

  @packet_type 205
  @feedback_type 15

  @typedoc """
  Status of reported packets.

  See `draft-holmer-rmcat-transport-wide-cc-extensions-01`, sec. 3.1.1 for further explanation.
  Notice that this RFC section lists `11` value as *RESERVED*, but it is used in further
  examples as *packet received, w/o timestamp*, thus we treat it as a valid value.
  """
  @type status_symbol() :: :not_received | :no_delta | :small_delta | :large_delta

  @typedoc """
  Struct representing Transport-wide Congestion Control
  Feedback RTCP packet.

  Packet will be properly encoded only if the values are valid. Refer to
  `draft-holmer-rmcat-transport-wide-cc-extensions-01`, sec. 3 to see
  what values are considered valid, here's some important remarks:
    * `packet_status_count` must match the actual number of packets described
    by the feedback,
    * length of `recv_deltas` must match the number of packets that
    were described as `:small_delta` or `:large_delta` by the `packet_chunks`,
    * each of `recv_deltas` values must fit in 2 bytes (if it's `:large_delta`)
    or 1 byte (if it's `:small_delta`).

  Trying to encode a packet with invalid values will result in an undefined
  behaviour (most likely `encode/1` will raise).
  """
  @type t() :: %__MODULE__{
          sender_ssrc: Packet.uint32(),
          media_ssrc: Packet.uint32(),
          base_sequence_number: Packet.uint16(),
          packet_status_count: Packet.uint16(),
          reference_time: Packet.int24(),
          fb_pkt_count: Packet.uint8(),
          packet_chunks: [RunLength.t() | StatusVector.t()],
          recv_deltas: [Packet.uint8() | Packet.int16()]
        }

  @enforce_keys [
    :sender_ssrc,
    :media_ssrc,
    :base_sequence_number,
    :packet_status_count,
    :reference_time,
    :fb_pkt_count
  ]
  defstruct [
              packet_chunks: [],
              recv_deltas: []
            ] ++ @enforce_keys

  @impl true
  def encode(packet) do
    %__MODULE__{
      sender_ssrc: sender_ssrc,
      media_ssrc: media_ssrc,
      base_sequence_number: base_sequence_number,
      packet_status_count: packet_status_count,
      reference_time: reference_time,
      fb_pkt_count: fb_pkt_count,
      packet_chunks: packet_chunks,
      recv_deltas: recv_deltas
    } = packet

    chunks = encode_chunks(packet_chunks)
    delta_symbols = get_delta_symbols(packet_chunks)
    deltas = encode_deltas(delta_symbols, recv_deltas)

    encoded = <<
      sender_ssrc::32,
      media_ssrc::32,
      base_sequence_number::16,
      packet_status_count::16,
      reference_time::signed-24,
      fb_pkt_count::8,
      chunks::binary,
      deltas::binary
    >>

    padding =
      if rem(byte_size(encoded), 4) == 0 do
        <<>>
      else
        <<0::unit(8)-size(4 - rem(byte_size(encoded), 4))>>
      end

    {encoded <> padding, @feedback_type, @packet_type}
  end

  defp encode_chunks(chunks, acc \\ <<>>)
  defp encode_chunks([], acc), do: acc

  defp encode_chunks([%RunLength{status_symbol: symbol, run_length: len} | chunks], acc) do
    encoded_symbol = get_status_raw(symbol)
    encoded_chunk = <<0::1, encoded_symbol::2, len::13>>

    encode_chunks(chunks, acc <> encoded_chunk)
  end

  defp encode_chunks([%StatusVector{symbols: symbols} | chunks], acc) do
    symbol_size =
      case length(symbols) do
        14 -> 0
        7 -> 1
        _other -> raise "Length of symbols in StatusVector chunk must be equal to either 7 or 14"
      end

    encoded_symbols =
      for symbol <- symbols, into: <<>> do
        <<get_status_raw(symbol)::size(symbol_size + 1)>>
      end

    encoded_chunk = <<1::1, symbol_size::1, encoded_symbols::bitstring>>

    encode_chunks(chunks, acc <> encoded_chunk)
  end

  defp encode_deltas(delta_symbols, deltas, acc \\ <<>>)
  defp encode_deltas([], [], acc), do: acc

  defp encode_deltas([symbol | symbols], deltas, acc)
       when symbol in [:not_received, :no_delta],
       do: encode_deltas(symbols, deltas, acc)

  defp encode_deltas([:small_delta | symbols], [delta | deltas], acc) do
    if delta not in 0..255, do: raise("Delta #{delta} does not fit in 1 byte")

    encode_deltas(symbols, deltas, <<acc::binary, delta::8>>)
  end

  defp encode_deltas([:large_delta | symbols], [delta | deltas], acc) do
    if delta not in -32_768..32_767, do: raise("Delta #{delta} does not fit in 2 bytes")

    encode_deltas(symbols, deltas, <<acc::binary, delta::signed-16>>)
  end

  @impl true
  def decode(
        <<
          sender_ssrc::32,
          media_ssrc::32,
          base_sequence_number::16,
          packet_status_count::16,
          reference_time::signed-24,
          fb_pkt_count::8,
          rest::binary
        >>,
        _count
      ) do
    with {:ok, chunks, rest} <- decode_chunks(rest, packet_status_count),
         delta_symbols <- get_delta_symbols(chunks) |> Enum.take(packet_status_count),
         {:ok, deltas} <- decode_deltas(delta_symbols, rest) do
      packet = %__MODULE__{
        sender_ssrc: sender_ssrc,
        media_ssrc: media_ssrc,
        base_sequence_number: base_sequence_number,
        packet_status_count: packet_status_count,
        reference_time: reference_time,
        fb_pkt_count: fb_pkt_count,
        packet_chunks: chunks,
        recv_deltas: deltas
      }

      {:ok, packet}
    end
  end

  def decode(_raw, _count), do: {:error, :invalid_packet}

  defp decode_chunks(raw, count, acc \\ [])
  defp decode_chunks(raw, count, acc) when count <= 0, do: {:ok, Enum.reverse(acc), raw}

  defp decode_chunks(<<0::1, symbol::2, run_length::13, rest::binary>>, count, acc) do
    status_symbol = get_status_symbol(symbol)
    chunk = %RunLength{status_symbol: status_symbol, run_length: run_length}

    decode_chunks(rest, count - run_length, [chunk | acc])
  end

  defp decode_chunks(<<1::1, symbol_size::1, list::bitstring-14, rest::binary>>, count, acc) do
    symbols =
      for <<raw_symbol::size(symbol_size + 1) <- list>> do
        get_status_symbol(raw_symbol)
      end

    chunk = %StatusVector{symbols: symbols}

    decode_chunks(rest, count - length(symbols), [chunk | acc])
  end

  defp decode_chunks(_raw, _count, _chunks), do: {:error, :invalid_packet}

  defp decode_deltas(delta_symbols, raw, acc \\ [])
  defp decode_deltas([], _raw, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_deltas([symbol | symbols], raw, acc)
       when symbol in [:not_received, :no_delta],
       do: decode_deltas(symbols, raw, acc)

  defp decode_deltas([:small_delta | symbols], <<delta::8, rest::binary>>, acc),
    do: decode_deltas(symbols, rest, [delta | acc])

  defp decode_deltas([:large_delta | symbols], <<delta::signed-16, rest::binary>>, acc),
    do: decode_deltas(symbols, rest, [delta | acc])

  defp decode_deltas(_symbols, _raw, _acc), do: {:error, :invalid_packet}

  defp get_delta_symbols(chunks) do
    Enum.flat_map(chunks, fn
      %RunLength{status_symbol: symbol, run_length: len} -> List.duplicate(symbol, len)
      %StatusVector{symbols: symbols} -> symbols
    end)
  end

  defp get_status_symbol(0b00), do: :not_received
  defp get_status_symbol(0b01), do: :small_delta
  defp get_status_symbol(0b10), do: :large_delta
  defp get_status_symbol(0b11), do: :no_delta

  defp get_status_raw(:not_received), do: 0b00
  defp get_status_raw(:small_delta), do: 0b01
  defp get_status_raw(:large_delta), do: 0b10
  defp get_status_raw(:no_delta), do: 0b11
end
