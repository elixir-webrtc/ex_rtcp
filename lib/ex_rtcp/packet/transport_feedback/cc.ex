defmodule ExRTCP.Packet.TransportFeedback.CC do
  @moduledoc """
  Transport-wide Congestion Control Feedback packet type
  (`draft-holmer-rmcat-transport-wide-cc-extensions-01`).
  """

  alias __MODULE__.{RunLength, StatusVector}
  alias ExRTCP.Packet

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
          recv_deltas: [Packet.uint8() | Packet.uint16()]
        }

  @enforce_keys [
    :sender_ssrc,
    :media_ssrc,
    :base_sequence_number,
    :packet_status_count,
    :reference_time,
    :fb_pkt_count
  ]
  defstruct @enforce_keys ++ [packet_chunks: [], recv_deltas: []]

  @behaviour ExRTCP.PacketTranscoder

  @doc false
  @spec get_status_symbol(0..3) :: status_symbol()
  def get_status_symbol(0b00), do: :not_received
  def get_status_symbol(0b01), do: :small_delta
  def get_status_symbol(0b10), do: :large_delta
  def get_status_symbol(0b11), do: :no_delta

  @doc false
  @spec get_status_raw(status_symbol()) :: 0..3
  def get_status_raw(:not_received), do: 0b00
  def get_status_raw(:small_delta), do: 0b01
  def get_status_raw(:large_delta), do: 0b10
  def get_status_raw(:no_delta), do: 0b11

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

    chunks = encode_chunks(packet_chunks, recv_deltas)

    encoded = <<
      sender_ssrc::32,
      media_ssrc::32,
      base_sequence_number::16,
      packet_status_count::16,
      reference_time::signed-24,
      fb_pkt_count::8,
      chunks::binary
    >>

    padding =
      if rem(byte_size(encoded), 4) == 0 do
        <<>>
      else
        <<0::unit(8)-size(4 - rem(byte_size(encoded), 4))>>
      end

    {encoded <> padding, @feedback_type, @packet_type}
  end

  defp encode_chunks(chunks, deltas, acc \\ <<>>)
  defp encode_chunks([], [], acc), do: acc

  defp encode_chunks([chunk | chunks], deltas, acc) do
    %module{} = chunk
    {raw_chunk, rest_deltas} = module.encode(chunk, deltas)
    encode_chunks(chunks, rest_deltas, acc <> raw_chunk)
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
    with {:ok, chunks, deltas} <- decode_chunks(rest, packet_status_count) do
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

  defp decode_chunks(raw, count, chunks \\ [], deltas \\ [])

  # in theory, after chunks are processed, count should be 0
  # but we also accept values < 0 (so when there's more packets than header suggests)
  # we also ignore anything after the last chunk, which normally would be padded to 32 bit boundary
  defp decode_chunks(_raw, count, chunks, deltas) when count <= 0,
    do: {:ok, Enum.reverse(chunks), Enum.reverse(deltas)}

  defp decode_chunks(<<type::1, _rest::bitstring>> = raw, count, chunks, deltas) do
    module =
      case type do
        0 -> RunLength
        1 -> StatusVector
      end

    with {:ok, chunk, chunk_deltas, rest} <- module.decode(raw) do
      count_diff =
        case chunk do
          %RunLength{run_length: rl} -> rl
          %StatusVector{symbols: s} -> length(s)
        end

      decode_chunks(rest, count - count_diff, [chunk | chunks], chunk_deltas ++ deltas)
    end
  end

  defp decode_chunks(_raw, _count, _chunks, _deltas), do: {:error, :invalid_packet}
end
