defmodule ExRTCP.Packet.SourceDescriptionTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.SourceDescription
  alias ExRTCP.Packet.SourceDescription.Chunk
  alias ExRTCP.Packet.SourceDescription.Chunk.Item

  @text "12345"
  @item %Item{type: :cname, text: @text}
  @encoded_item <<1::8, byte_size(@text)::8, @text::binary>>

  @ssrc 0x37B8307F
  @chunk %Chunk{ssrc: @ssrc, items: [@item, @item]}
  @encoded_chunk <<@ssrc::32, @encoded_item::binary, @encoded_item::binary, 0, 0>>

  describe "encode/1" do
    test "packet with no chunks" do
      packet = %SourceDescription{chunks: []}

      assert {encoded, 0, 202} = SourceDescription.encode(packet)

      assert encoded == <<>>
    end

    test "packet with chunks" do
      packet = %SourceDescription{chunks: [@chunk, @chunk]}

      assert {encoded, 2, 202} = SourceDescription.encode(packet)

      assert encoded == <<@encoded_chunk::binary, @encoded_chunk::binary>>
    end
  end

  describe "decode/2" do
    test "packet with no chunks" do
      assert {:ok, decoded} = SourceDescription.decode(<<>>, 0)

      assert %SourceDescription{
               chunks: []
             } = decoded
    end

    test "packet with chunks" do
      packet = <<@encoded_chunk::binary, @encoded_chunk::binary>>

      assert {:ok, decoded} = SourceDescription.decode(packet, 2)

      assert %SourceDescription{
               chunks: [@chunk, @chunk]
             } = decoded
    end

    test "invalid packet" do
      # invalid item type
      item = <<50::8, byte_size(@text), @text::binary>>
      chunk = <<@ssrc::32, item::binary, 0>>
      packet = <<chunk::binary>>

      assert {:error, :invalid_packet} = SourceDescription.decode(packet, 1)
    end
  end
end
