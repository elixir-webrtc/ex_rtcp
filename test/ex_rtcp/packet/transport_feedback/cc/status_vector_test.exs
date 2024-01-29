defmodule ExRTCP.Packet.TransportFeedback.CC.StatusVectorTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.CC.StatusVector

  @rest <<1, 6, 7, 8>>
  @rest_deltas [33, 13]

  describe "encode/2" do
    test "chunk with one-bit symbols" do
      deltas_raw = <<112, 88, 74, 47>>
      symbols_raw = <<0::1, 1::1, 1::1, 0::5, 1::1, 1::1, 0::4>>

      deltas = [112, 88, 74, 47]

      symbols =
        for <<s::1 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
          end
        end

      chunk = %StatusVector{symbols: symbols}
      {raw, @rest_deltas} = StatusVector.encode(chunk, deltas ++ @rest_deltas)

      assert <<
               1::1,
               0::1,
               symbols_raw::bitstring,
               deltas_raw::binary
             >> == raw
    end

    test "chunk with two-bit symbols" do
      deltas_raw = <<88, 1500::16, 2421::16>>
      symbols_raw = <<0::2, 1::2, 0::2, 2::2, 2::2, 0::2, 3::2>>

      deltas = [88, 1500, 2421]

      symbols =
        for <<s::2 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
            2 -> :large_delta
            3 -> :no_delta
          end
        end

      chunk = %StatusVector{symbols: symbols}
      {raw, @rest_deltas} = StatusVector.encode(chunk, deltas ++ @rest_deltas)

      assert <<
               1::1,
               1::1,
               symbols_raw::bitstring,
               deltas_raw::binary
             >> == raw
    end
  end

  describe "decode/1" do
    test "chunk with one-bit symbols" do
      deltas_raw = <<112, 88, 74, 47>>
      symbols_raw = <<0::1, 1::1, 1::1, 0::5, 1::1, 1::1, 0::4>>
      raw = <<1::1, 0::1, symbols_raw::bitstring, deltas_raw::binary, @rest::binary>>

      deltas = [47, 74, 88, 112]

      symbols =
        for <<s::1 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
          end
        end

      assert {:ok, chunk, ^deltas, @rest} = StatusVector.decode(raw)
      assert %StatusVector{symbols: ^symbols} = chunk
    end

    test "chunk with two-bit symbols" do
      deltas_raw = <<88, 1500::16, 2421::16>>
      symbols_raw = <<0::2, 1::2, 0::2, 2::2, 2::2, 0::2, 3::2>>
      raw = <<1::1, 1::1, symbols_raw::bitstring, deltas_raw::binary, @rest::binary>>

      deltas = [2421, 1500, 88]

      symbols =
        for <<s::2 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
            2 -> :large_delta
            3 -> :no_delta
          end
        end

      assert {:ok, chunk, ^deltas, @rest} = StatusVector.decode(raw)
      assert %StatusVector{symbols: ^symbols} = chunk
    end

    test "chunk too short" do
      raw = <<0::1, 2::1, 45::8>>
      assert {:error, :invalid_packet} = StatusVector.decode(raw)
    end
  end
end
