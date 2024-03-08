defmodule ExRTCP.Packet.TransportFeedback.NACKTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.NACK

  @sender_ssrc 123_321
  @media_ssrc 112_231

  test "encode/1" do
    pid_1 = 35_042
    blp_1 = <<5, 1>>
    pid_2 = 21_042
    blp_2 = <<14, 81>>

    packet = %NACK{
      sender_ssrc: @sender_ssrc,
      media_ssrc: @media_ssrc,
      nacks: [%{pid: pid_1, blp: blp_1}, %{pid: pid_2, blp: blp_2}]
    }

    assert {encoded, 1, 205} = NACK.encode(packet)

    assert <<
             @sender_ssrc::32,
             @media_ssrc::32,
             pid_1::16,
             blp_1::binary-size(2),
             pid_2::16,
             blp_2::binary-size(2)
           >> == encoded
  end

  describe "decode/2" do
    test "valid packet" do
      pid_1 = 35_043
      blp_1 = <<2, 9>>
      nack_1 = <<pid_1::16, blp_1::binary>>
      pid_2 = 53_221
      blp_2 = <<4, 5>>
      nack_2 = <<pid_2::16, blp_2::binary>>

      raw_packet = <<@sender_ssrc::32, @media_ssrc::32, nack_1::binary, nack_2::binary>>

      assert {:ok, packet} = NACK.decode(raw_packet, 1)

      assert %NACK{
               sender_ssrc: @sender_ssrc,
               media_ssrc: @media_ssrc,
               nacks: [%{pid: ^pid_1, blp: ^blp_1}, %{pid: ^pid_2, blp: ^blp_2}]
             } = packet
    end

    test "invalid packet" do
      # blp of first nack is cut after 8 bits
      raw_packet = <<@sender_ssrc::32, @media_ssrc::32, 53::16, 0>>

      assert {:error, :invalid_packet} = NACK.decode(raw_packet, 1)
    end
  end
end
