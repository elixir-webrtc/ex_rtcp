defmodule ExRTCP.Packet.GoodbyeTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.Goodbye

  @ssrc 0x37B8307F

  describe "encode/1" do
    test "packet with no reason" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]

      packet = %Goodbye{
        sources: sources,
        reason: nil
      }

      assert {encoded, 3, 203} = Goodbye.encode(packet)

      bin = for i <- sources, do: <<i::32>>, into: <<>>

      assert encoded == bin
    end

    test "packet with reason" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      reason = "1234"

      packet = %Goodbye{
        sources: sources,
        reason: reason
      }

      assert {encoded, 3, 203} = Goodbye.encode(packet)

      bin = for i <- sources, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary>>

      assert encoded == bin
    end

    test "packet with reason that's not multiple of 32 bits" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      reason = "123456"

      packet = %Goodbye{
        sources: sources,
        reason: reason
      }

      assert {encoded, 3, 203} = Goodbye.encode(packet)

      bin = for i <- sources, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary, 0, 0>>

      assert encoded == bin
    end
  end

  describe "decode/2" do
    test "packet with no reason" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      bin = for i <- sources, do: <<i::32>>, into: <<>>

      assert {:ok, packet} = Goodbye.decode(bin, length(sources))

      assert %Goodbye{
               sources: decoded_sources,
               reason: nil
             } = packet

      assert Enum.sort(sources) == Enum.sort(decoded_sources)
    end

    test "packet with reason" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "apud"

      bin = for i <- sources, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary>>

      assert {:ok, packet} = Goodbye.decode(bin, length(sources))

      assert %Goodbye{
               sources: _decoded_sources,
               reason: ^reason
             } = packet
    end

    test "packet with reason that's not multiple of 32 bits" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "siema"

      bin = for i <- sources, do: <<i::32>>, into: <<>>
      padding = <<0, 0>>
      bin = <<bin::binary, byte_size(reason)::8, reason::binary, padding::binary>>

      assert {:ok, packet} = Goodbye.decode(bin, length(sources))

      assert %Goodbye{
               sources: _decoded_sources,
               reason: ^reason
             } = packet
    end

    test "invalid packet" do
      sources = [@ssrc, @ssrc + 1, @ssrc + 2]
      # notice its multiple of 32 bits
      reason = "siema"

      bin = for i <- sources, do: <<i::32>>, into: <<>>
      bin = <<bin::binary, 20::8, reason::binary>>

      assert {:error, :invalid_packet} = Goodbye.decode(bin, length(sources))
    end
  end
end
