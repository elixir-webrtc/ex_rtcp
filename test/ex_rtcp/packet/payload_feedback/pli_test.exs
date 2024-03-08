defmodule ExRTCP.Packet.PayloadFeedback.PLITest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.PayloadFeedback.PLI

  @sender_ssrc 123_321
  @media_ssrc 112_231

  test "encode/1" do
    packet = %PLI{
      sender_ssrc: @sender_ssrc,
      media_ssrc: @media_ssrc
    }

    assert {encoded, 1, 206} = PLI.encode(packet)

    assert <<@sender_ssrc::32, @media_ssrc::32>> == encoded
  end

  describe "decode/2" do
    test "valid_packet" do
      raw_packet = <<@sender_ssrc::32, @media_ssrc::32>>

      assert {:ok, packet} = PLI.decode(raw_packet, 1)

      assert %PLI{
               sender_ssrc: @sender_ssrc,
               media_ssrc: @media_ssrc
             } = packet
    end

    test "invalid_packet" do
      # packet cut short
      raw_packet = <<@sender_ssrc::32, @media_ssrc::16>>

      assert {:error, :invalid_packet} = PLI.decode(raw_packet, 1)
    end
  end
end
