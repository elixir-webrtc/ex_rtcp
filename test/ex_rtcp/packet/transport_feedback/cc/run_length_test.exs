defmodule ExRTCP.Packet.TransportFeedback.CC.RunLengthTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.CC.RunLength

  @run_length 568
  @rest <<1, 6, 7, 8>>

  describe "decode/1" do
    test "chunk with `not_received` symbols" do
      raw = <<0::1, 0::2, @run_length::13, @rest::binary>>

      assert {:ok, chunk, [], @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :not_received,
               run_length: @run_length
             } = chunk
    end

    test "chunk with `small_delta` symbols" do
      deltas = for i <- 1..@run_length, do: rem(i, 137)
      deltas_raw = for delta <- deltas, do: <<delta>>, into: <<>>
      raw = <<0::1, 1::2, @run_length::13, deltas_raw::binary, @rest::binary>>

      rev_deltas = Enum.reverse(deltas)
      assert {:ok, chunk, ^rev_deltas, @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :small_delta,
               run_length: @run_length
             } = chunk
    end

    test "chunk with `large_delta` symbols" do
      deltas = for i <- 1..@run_length, do: i
      deltas_raw = for delta <- deltas, do: <<delta::16>>, into: <<>>
      raw = <<0::1, 2::2, @run_length::13, deltas_raw::binary, @rest::binary>>

      rev_deltas = Enum.reverse(deltas)
      assert {:ok, chunk, ^rev_deltas, @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :large_delta,
               run_length: @run_length
             } = chunk
    end

    test "chunk with invalid symbol" do
      raw = <<0::1, 3::2, @run_length::13, @rest::binary>>
      assert {:error, :invalid_packet} = RunLength.decode(raw)
    end

    test "chunk too short" do
      raw = <<0::1, 2::1, 45::8>>
      assert {:error, :invalid_packet} = RunLength.decode(raw)
    end
  end
end
