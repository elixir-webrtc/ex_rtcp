defmodule ExRCTP.CapturedTest do
  use ExUnit.Case, async: true
  # this module contains tests based
  # on real-world captured packets
  # expected values based on Wiresharks's dissection

  alias ExRTCP.Packet
  alias ExRTCP.Packet.{SenderReport, ReceiverReport, ReceptionReport}

  test "captured receiver report" do
    bin =
      <<0x82, 0xC9, 0x00, 0x0D, 0xC8, 0x96, 0xB9, 0x7D, 0x21, 0xF5, 0x20, 0x3C, 0x13, 0x4F, 0xB0,
        0xD8, 0x72, 0xE0, 0x63, 0x80, 0xCB, 0x46, 0x06, 0x02, 0x09, 0x40, 0x54, 0xE2, 0x8D, 0xD4,
        0x2D, 0x6B, 0xFD, 0xA3, 0xD5, 0x94, 0xC5, 0x34, 0x27, 0x87, 0x61, 0x2D, 0x70, 0x45, 0x89,
        0x6D, 0x91, 0x48, 0x36, 0xE6, 0x81, 0xA4, 0x73, 0x2C, 0x1D, 0x8E>>

    assert {:ok, packet} = Packet.decode(bin)

    assert %ReceiverReport{
             ssrc: 0xC896B97D,
             reports: [report_1, report_2]
           } = packet

    assert %ReceptionReport{
             ssrc: 0x21F5203C,
             fraction_lost: 19,
             total_lost: 5_222_616,
             last_sequence_number: 1_927_308_160,
             jitter: 3_410_363_906,
             last_sr: 155_210_978,
             delay: 2_379_492_715
           } = report_1

    assert %ReceptionReport{
             ssrc: 0xFDA3D594,
             fraction_lost: 197,
             total_lost: 3_417_991,
             last_sequence_number: 1_630_367_813,
             jitter: 2_305_659_208,
             last_sr: 921_076_132,
             delay: 1_932_270_990
           } = report_2
  end

  test "captured sender report" do
    bin =
      <<0x80, 0xC8, 0x00, 0x06, 0xC3, 0x02, 0xF4, 0x1A, 0xFA, 0xFD, 0xF9, 0xDE, 0x8D, 0x4A, 0x01,
        0xE3, 0x27, 0x40, 0xC3, 0xAE, 0x12, 0xF0, 0x30, 0x5C, 0x28, 0xFD, 0x58, 0xE0>>

    assert {:ok, packet} = Packet.decode(bin)

    assert %SenderReport{
             ssrc: 0xC302F41A,
             ntp_timestamp: 0xFAFDF9DE8D4A01E3,
             rtp_timestamp: 658_555_822,
             packet_count: 317_730_908,
             octet_count: 687_692_000,
             reports: []
           } = packet
  end
end
