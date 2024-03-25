defmodule ExRTCP.Packet.TransportFeedback.CCTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.CC
  alias ExRTCP.Packet.TransportFeedback.CC.{RunLength, StatusVector}

  @sender_ssrc 123_321
  @media_ssrc 112_231
  @base_sequence_number 50_001
  @reference_time -54_528
  @fb_pkt_count 36

  test "encode/1" do
    # run length chunk (34 packets with small delta)
    chunk_1_count = 32
    raw_chunk_1 = <<0::1, 1::2, chunk_1_count::13>>
    raw_deltas_1 = for i <- 1..chunk_1_count, do: <<i>>, into: <<>>

    chunk_1 = %RunLength{status_symbol: :small_delta, run_length: chunk_1_count}
    deltas_1 = for i <- 1..chunk_1_count, do: i

    # status vector chunk (mixed packets, two-bit symbols)
    raw_chunk_2 = <<1::1, 1::1, 2::2, 1::2, 2::2, 0::4, 3::2, 3::2>>
    raw_deltas_2 = <<-1234::16, 109, 5501::16>>

    symbols = [
      :large_delta,
      :small_delta,
      :large_delta,
      :not_received,
      :not_received,
      :no_delta,
      :no_delta
    ]

    chunk_2 = %StatusVector{symbols: symbols}
    deltas_2 = [-1234, 109, 5501]

    total_packet_count = chunk_1_count + 7

    packet = %CC{
      sender_ssrc: @sender_ssrc,
      media_ssrc: @media_ssrc,
      base_sequence_number: @base_sequence_number,
      packet_status_count: total_packet_count,
      reference_time: @reference_time,
      fb_pkt_count: @fb_pkt_count,
      packet_chunks: [chunk_1, chunk_2],
      recv_deltas: deltas_1 ++ deltas_2
    }

    assert {encoded, 15, 205} = CC.encode(packet)

    assert <<
             @sender_ssrc::32,
             @media_ssrc::32,
             @base_sequence_number::16,
             total_packet_count::16,
             @reference_time::signed-24,
             @fb_pkt_count::8,
             raw_chunk_1::binary,
             raw_chunk_2::binary,
             raw_deltas_1::binary,
             raw_deltas_2::binary,
             0,
             0,
             0
           >> == encoded
  end

  describe "decode/2" do
    test "valid packet" do
      # run length chunk (32 packets with small delta)
      chunk_1_count = 32
      raw_chunk_1 = <<0::1, 1::2, chunk_1_count::13>>
      raw_deltas_1 = for i <- 1..chunk_1_count, do: <<i>>, into: <<>>

      chunk_1 = %RunLength{status_symbol: :small_delta, run_length: chunk_1_count}
      deltas_1 = for i <- 1..chunk_1_count, do: i

      # status vector chunk (mixed packets, two-bit symbols)
      raw_chunk_2 = <<1::1, 1::1, 2::2, 1::2, 2::2, 0::4, 3::2, 3::2>>
      raw_deltas_2 = <<-1234::16, 109, 5501::16>>

      symbols = [
        :large_delta,
        :small_delta,
        :large_delta,
        :not_received,
        :not_received,
        :no_delta,
        :no_delta
      ]

      chunk_2 = %StatusVector{symbols: symbols}
      deltas_2 = [-1234, 109, 5501]

      total_packet_count = chunk_1_count + 7
      # need 3 bytes of padding
      raw_packet = <<
        @sender_ssrc::32,
        @media_ssrc::32,
        @base_sequence_number::16,
        total_packet_count::16,
        @reference_time::signed-24,
        @fb_pkt_count::8,
        raw_chunk_1::binary,
        raw_chunk_2::binary,
        raw_deltas_1::binary,
        raw_deltas_2::binary,
        0,
        0,
        0
      >>

      assert {:ok, packet} = CC.decode(raw_packet, 15)

      assert %CC{
               sender_ssrc: @sender_ssrc,
               media_ssrc: @media_ssrc,
               base_sequence_number: @base_sequence_number,
               packet_status_count: total_packet_count,
               reference_time: @reference_time,
               fb_pkt_count: @fb_pkt_count,
               packet_chunks: [chunk_1, chunk_2],
               recv_deltas: deltas_1 ++ deltas_2
             } == packet
    end

    test "invalid packet" do
      chunk_count = 32
      raw_chunk = <<0::1, 1::2, chunk_count::13>>
      # missing deltas at the end
      raw_deltas = for i <- 1..(chunk_count - 5), do: <<i>>, into: <<>>

      raw_packet = <<
        @sender_ssrc::32,
        @media_ssrc::32,
        @base_sequence_number::16,
        chunk_count::16,
        @reference_time::signed-24,
        @fb_pkt_count::8,
        raw_chunk::binary,
        raw_deltas::binary
      >>

      assert {:error, :invalid_packet} = CC.decode(raw_packet, 15)
    end

    test "packet with zero-ed status vector at the end" do
      raw_chunk = <<1::1, 0::1, 1::1, 1::1, 1::1, 1::1, 0::10>>
      raw_deltas = <<123, 211, 23, 55>>

      symbols = List.duplicate(:small_delta, 4) ++ List.duplicate(:not_received, 10)
      chunk = %StatusVector{symbols: symbols}
      deltas = [123, 211, 23, 55]

      # not realistic, this usually would be single RunLength chunk
      # but, for the sake of the test, let's make it a "trimmed" StatusVector
      total_packet_count = 4

      raw_packet = <<
        @sender_ssrc::32,
        @media_ssrc::32,
        @base_sequence_number::16,
        total_packet_count::16,
        @reference_time::signed-24,
        @fb_pkt_count::8,
        raw_chunk::binary,
        raw_deltas::binary,
        0,
        0
      >>

      assert {:ok, packet} = CC.decode(raw_packet, 15)

      assert %CC{
               sender_ssrc: @sender_ssrc,
               media_ssrc: @media_ssrc,
               base_sequence_number: @base_sequence_number,
               packet_status_count: total_packet_count,
               reference_time: @reference_time,
               fb_pkt_count: @fb_pkt_count,
               packet_chunks: [chunk],
               recv_deltas: deltas
             } == packet
    end
  end
end
