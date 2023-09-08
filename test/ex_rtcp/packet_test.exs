defmodule ExRTCP.PacketTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet
  alias ExRTCP.Packet.Goodbye

  @version 2
  # empty Goodbye packet 
  @packet_type 203
  @count 0

  describe "decode/1" do
    test "simple packet" do
      bin = <<@version::2, 0::1, @count::5, @packet_type::8, 16::16>>

      assert {:ok, packet} = Packet.decode(bin)

      assert %Goodbye{
               ssrc: [],
               reason: nil
             } = packet
    end

    test "packet with padding" do
      bin = <<@version::2, 1::1, @count::5, @packet_type::8, 16::16>>
      padding = <<0::5*8, 6>>

      bin = bin <> padding

      assert {:ok, packet} = Packet.decode(bin)

      assert %Goodbye{
               ssrc: [],
               reason: nil
             } = packet
    end
  end
end
