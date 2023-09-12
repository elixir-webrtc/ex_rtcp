defmodule ExRTCP.Packet.SourceDescription.Chunk.ItemTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.SourceDescription.Chunk.Item

  @item_type :cname
  @item_id 1
  @text "12345"

  @rest <<1, 2, 3, 4, 5>>

  describe "encode/1" do
    test "simple item" do
      item = %Item{type: @item_type, text: @text}

      encoded = Item.encode(item)
      valid = <<@item_id::8, byte_size(@text)::8, @text::binary>>

      assert encoded == valid
    end
  end

  describe "decode/1" do
    test "valid item" do
      item = <<@item_id::8, byte_size(@text)::8, @text::binary, @rest::binary>>

      assert {:ok, decoded, @rest} = Item.decode(item)

      assert %Item{
               type: @item_type,
               text: @text
             } = decoded
    end

    test "invalid item" do
      item = <<@item_id::8, 8::8, 1, 2, 3>>

      assert {:error, :invalid_packet} = Item.decode(item)
    end
  end
end
