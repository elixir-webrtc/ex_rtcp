defmodule ExRTCP.PacketTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet
  alias ExRTCP.Packet.Goodbye

  @version 2
  # empty Goodbye packet 
  @packet_type 203
  @count 0

  describe "encode/1,2" do
    test "simple packet" do
      packet = %Goodbye{
        sources: [],
        reason: nil
      }

      encoded = Packet.encode(packet)
      bin = <<@version::2, 0::1, @count::5, @packet_type::8, 0::16>>

      assert encoded == bin
    end

    test "packet with padding" do
      packet = %Goodbye{
        sources: [],
        reason: nil
      }

      encoded = Packet.encode(packet, padding: 4)
      bin = <<@version::2, 1::1, @count::5, @packet_type::8, 1::16, 0, 0, 0, 4>>

      assert encoded == bin
    end
  end

  describe "decode/1" do
    test "simple packet" do
      bin = <<@version::2, 0::1, @count::5, @packet_type::8, 0::16>>

      assert {:ok, packet} = Packet.decode(bin)

      assert %Goodbye{
               sources: [],
               reason: nil
             } = packet
    end

    test "packet with padding" do
      bin = <<@version::2, 1::1, @count::5, @packet_type::8, 0::16>>
      padding = <<0::5*8, 6>>

      bin = bin <> padding

      assert {:ok, packet} = Packet.decode(bin)

      assert %Goodbye{
               sources: [],
               reason: nil
             } = packet
    end

    test "packet with unknown type" do
      bin = <<@version::2, 0::1, @count::5, 2::8, 0::16>>

      assert {:error, :unknown_type} = Packet.decode(bin)
    end
  end
end
