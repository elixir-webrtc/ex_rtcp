defmodule ExRTCP.Packet.SourceDescription.ChunkTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.SourceDescription.Chunk
  alias ExRTCP.Packet.SourceDescription.Chunk.Item

  @ssrc 0x37B8307F

  @text "12345"
  @item %Item{type: :email, text: @text}
  @encoded_item <<3::8, byte_size(@text)::8, @text::binary>>
  @rest <<1, 2, 3, 4, 5, 6, 7, 8>>

  describe "encode/1" do
    test "chunk without items" do
      chunk = %Chunk{ssrc: @ssrc, items: []}

      encoded = Chunk.encode(chunk)

      assert encoded == <<@ssrc::32, 0, 0, 0, 0>>
    end

    test "chunk with items" do
      chunk = %Chunk{ssrc: @ssrc, items: [@item, @item]}

      encoded = Chunk.encode(chunk)
      valid = <<@ssrc::32, @encoded_item::binary, @encoded_item::binary, 0, 0>>

      assert encoded == valid
    end

    test "chunk with items ending at 32 bit boundary" do
      item = %Item{type: :cname, text: <<1, 1>>}
      chunk = %Chunk{ssrc: @ssrc, items: [item]}

      encoded = Chunk.encode(chunk)

      item = <<1::8, 2::8, 1, 1>>
      valid = <<@ssrc::32, item::binary, 0, 0, 0, 0>>

      assert encoded == valid
    end
  end

  describe "decode/1" do
    test "chunk without items" do
      chunk = <<@ssrc::32, 0, 0, 0, 0, @rest::binary>>

      assert {:ok, decoded, @rest} = Chunk.decode(chunk)

      assert %Chunk{
               ssrc: @ssrc,
               items: []
             } = decoded
    end

    test "chunk with items" do
      chunk = <<@ssrc::32, @encoded_item::binary, @encoded_item::binary, 0, 0, @rest::binary>>

      assert {:ok, decoded, @rest} = Chunk.decode(chunk)

      assert %Chunk{
               ssrc: @ssrc,
               items: [@item, @item]
             } = decoded
    end
  end
end
