defmodule ExRTCP.Packet.TransportFeedback.CC.StatusVectorTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.CC.StatusVector

  @rest <<1, 6, 7, 8>>

  describe "decode/1" do
    test "chunk with one-bit symbols" do
      symbols_raw = <<0::1, 1::1, 1::1, 0::5, 1::1, 1::1, 0::4>>
      deltas_raw = <<111, 88, 74, 23>>
      raw = <<1::1, 0::1, symbols_raw::bitstring, deltas_raw::binary, @rest::binary>>

      symbols =
        for <<s::1 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
          end
        end

      deltas = [23, 74, 88, 111]

      assert {:ok, chunk, ^deltas, @rest} = StatusVector.decode(raw)
      assert %StatusVector{symbols: ^symbols} = chunk
    end

    test "chunk with two-bit symbols" do
      symbols_raw = <<0::2, 1::2, 0::2, 2::2, 2::2, 0::4>>
      deltas_raw = <<88, 1500::16, 2421::16>>
      raw = <<1::1, 1::1, symbols_raw::bitstring, deltas_raw::binary, @rest::binary>>

      symbols =
        for <<s::2 <- symbols_raw>> do
          case s do
            0 -> :not_received
            1 -> :small_delta
            2 -> :large_delta
          end
        end

      deltas = [2421, 1500, 88]

      assert {:ok, chunk, ^deltas, @rest} = StatusVector.decode(raw)
      assert %StatusVector{symbols: ^symbols} = chunk
    end

    test "chunk with invalid symbols" do
      symbols_raw = <<3::2, 0::12>>
      raw = <<1::1, 1::1, symbols_raw::bitstring, @rest::binary>>
      assert {:error, :invalid_packet} = StatusVector.decode(raw)
    end

    test "chunk too short" do
      raw = <<0::1, 2::1, 45::8>>
      assert {:error, :invalid_packet} = StatusVector.decode(raw)
    end
  end
end
