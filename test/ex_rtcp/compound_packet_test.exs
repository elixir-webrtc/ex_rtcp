defmodule ExRTCP.CompoundPacketTest do
  use ExUnit.Case, async: true

  alias ExRTCP.CompoundPacket
  alias ExRTCP.Packet.ReceiverReport

  @ssrc 0x37B8307F
  @packet %ReceiverReport{ssrc: @ssrc, reports: [], profile_extension: <<>>}
  @encoded_packet <<@ssrc::32>>

  describe "encode/1" do
    test "packets without padding" do
      encoded = CompoundPacket.encode([@packet, @packet])

      valid_packet = <<2::2, 0::1, 0::5, 201::8, 1::16, @encoded_packet::binary>>

      valid = <<valid_packet::binary, valid_packet::binary>>

      assert valid == encoded
    end

    test "packets with padding" do
      encoded = CompoundPacket.encode([@packet, @packet], padding: 4)

      packet_1 = <<2::2, 0::1, 0::5, 201::8, 1::16, @encoded_packet::binary>>
      packet_2 = <<2::2, 1::1, 0::5, 201::8, 2::16, @encoded_packet::binary, 0, 0, 0, 4>>

      valid = <<packet_1::binary, packet_2::binary>>

      assert valid == encoded
    end
  end

  describe "decode/1" do
    test "valid packets" do
      packet_1 = <<2::2, 0::1, 0::5, 201::8, 1::16, @encoded_packet::binary>>
      packet_2 = <<2::2, 1::1, 0::5, 201::8, 2::16, @encoded_packet::binary, 0, 0, 0, 4>>
      packet = <<packet_1::binary, packet_2::binary>>

      assert {:ok, [decoded_1, decoded_2]} = CompoundPacket.decode(packet)

      assert decoded_1 == @packet
      assert decoded_2 == @packet
    end

    test "invalid_packets" do
      packet_1 = <<2::2, 0::1, 0::5, 201::8, 1::16, @encoded_packet::binary>>
      packet_2 = <<2::2, 1::1, 0::5, 201::8, 2::16, @encoded_packet::binary>>
      packet = <<packet_1::binary, packet_2::binary>>

      assert {:error, :invalid_packet} = CompoundPacket.decode(packet)
    end
  end
end
