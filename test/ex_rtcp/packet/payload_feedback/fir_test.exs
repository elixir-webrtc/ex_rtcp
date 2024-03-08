defmodule ExRTCP.Packet.PayloadFeedback.FIRTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.PayloadFeedback.FIR

  @sender_ssrc 123_321
  @media_ssrc 112_231

  test "encode/1" do
    ssrc_1 = 123_433
    seq_nr_1 = 5
    ssrc_2 = 699_811
    seq_nr_2 = 8

    packet = %FIR{
      sender_ssrc: @sender_ssrc,
      media_ssrc: @media_ssrc,
      entries: [%{ssrc: ssrc_1, seq_nr: seq_nr_1}, %{ssrc: ssrc_2, seq_nr: seq_nr_2}]
    }

    assert {encoded, 4, 206} = FIR.encode(packet)

    assert <<
             @sender_ssrc::32,
             @media_ssrc::32,
             ssrc_1::32,
             seq_nr_1::8,
             0::24,
             ssrc_2::32,
             seq_nr_2::8,
             0::24
           >> == encoded
  end

  describe "decode/2" do
    test "valid_packet" do
      ssrc_1 = 35_043
      seq_nr_1 = 9
      entry_1 = <<ssrc_1::32, seq_nr_1::8, 0::24>>
      ssrc_2 = 32_043
      seq_nr_2 = 14
      entry_2 = <<ssrc_2::32, seq_nr_2::8, 0::24>>

      raw_packet = <<@sender_ssrc::32, @media_ssrc::32, entry_1::binary, entry_2::binary>>

      assert {:ok, packet} = FIR.decode(raw_packet, 4)

      assert %FIR{
               sender_ssrc: @sender_ssrc,
               media_ssrc: @media_ssrc,
               entries: [%{ssrc: ^ssrc_1, seq_nr: ^seq_nr_1}, %{ssrc: ^ssrc_2, seq_nr: ^seq_nr_2}]
             } = packet
    end

    test "invalid_packet" do
      # packet cut short
      raw_packet = <<@sender_ssrc::32, @media_ssrc::32, 53::32, 5::8>>

      assert {:error, :invalid_packet} = FIR.decode(raw_packet, 4)
    end
  end
end
