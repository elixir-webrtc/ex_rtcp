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

    test "items with different types (RFC 3550)" do
      types = [:cname, :name, :email, :phone, :location, :tool, :note, :priv]

      for {i, item_type} <- Enum.with_index(types, fn e, i -> {i + 1, e} end) do
        item = %Item{type: item_type, text: ""}
        assert <<^i::8, 0::8>> = Item.encode(item)
      end
    end

    test "MID item" do
      mid = "1234"
      mid_len = byte_size(mid)
      item = %Item{type: :mid, text: mid}
      assert <<15, ^mid_len, ^mid::binary>> = Item.encode(item)
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

    test "items with different types (RFC 3550)" do
      types = [:cname, :name, :email, :phone, :location, :tool, :note, :priv]

      for {i, item_type} <- Enum.with_index(types, fn e, i -> {i + 1, e} end) do
        item = <<i::8, 0::8>>
        assert {:ok, %Item{type: ^item_type}, <<>>} = Item.decode(item)
      end
    end

    test "MID item" do
      mid = <<1, 2, 3>>
      item = <<15, byte_size(mid), mid::binary>>

      assert {:ok, %Item{type: :mid, text: ^mid}, <<>>} = Item.decode(item)
    end

    test "invalid item" do
      item = <<@item_id::8, 8::8, 1, 2, 3>>

      assert {:error, :invalid_packet} = Item.decode(item)
    end
  end
end
