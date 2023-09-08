defmodule ExRTCP.Packet.GoodbyeTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.Goodbye

  @ssrc 0x37B8307F

  describe "decode/2" do
    test "packet with no reason" do
      ssrc = [@ssrc, @ssrc + 1, @ssrc + 2]
      bin = for i <- ssrc, do: <<i::32>>, into: <<>>

      assert {:ok, packet} = Goodbye.decode(bin, length(ssrc))

      assert %Goodbye{
               ssrc: decoded_ssrc,
               reason: nil
             } = packet

      assert Enum.sort(ssrc) == Enum.sort(decoded_ssrc)
    end

    test "packet with reason" do
      ssrc = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "apud"

      bin = for i <- ssrc, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary>>

      assert {:ok, packet} = Goodbye.decode(bin, length(ssrc))

      assert %Goodbye{
               ssrc: _decoded_ssrc,
               reason: ^reason
             } = packet
    end

    test "packet with reason that's not multiple of 32 bits" do
      ssrc = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "siema"

      bin = for i <- ssrc, do: <<i::32>>, into: <<>>
      padding = <<0, 0>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary, padding::binary>>

      assert {:ok, packet} = Goodbye.decode(bin, length(ssrc))

      assert %Goodbye{
               ssrc: _decoded_ssrc,
               reason: ^reason
             } = packet
    end

    test "invalid packet" do
      ssrc = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "siema"

      bin = for i <- ssrc, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, 20::8, reason::binary>>

      assert {:error, :invalid_packet} = Goodbye.decode(bin, length(ssrc))
    end
  end
end
