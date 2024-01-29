defmodule ExRTCP.Packet.TransportFeedback.CC.RunLengthTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.TransportFeedback.CC.RunLength

  @run_length 568
  @rest <<1, 6, 7, 8>>
  @rest_deltas [153, 221]

  describe "encode/2" do
    test "chunk with `not_received` symbols" do
      chunk = %RunLength{
        status_symbol: :not_received,
        run_length: @run_length
      }

      deltas = [54, 43]
      {raw, ^deltas} = RunLength.encode(chunk, deltas)

      assert <<0::1, 0::2, @run_length::13>> == raw
    end

    test "chunk with `no_delta` symbols" do
      chunk = %RunLength{
        status_symbol: :no_delta,
        run_length: @run_length
      }

      deltas = [54, 43]
      {raw, ^deltas} = RunLength.encode(chunk, deltas)

      assert <<0::1, 3::2, @run_length::13>> == raw
    end

    test "chunk with `small_delta` symbols" do
      deltas = for i <- 1..@run_length, do: rem(i, 256)

      chunk = %RunLength{
        status_symbol: :small_delta,
        run_length: @run_length
      }

      {raw, @rest_deltas} = RunLength.encode(chunk, deltas ++ @rest_deltas)

      deltas_raw = for delta <- deltas, do: <<delta>>, into: <<>>

      assert <<
               0::1,
               1::2,
               @run_length::13,
               deltas_raw::binary
             >> == raw
    end

    test "chunk with `large_delta` symbols" do
      deltas = for i <- 1..@run_length, do: rem(i * 20, 32_000)

      chunk = %RunLength{
        status_symbol: :large_delta,
        run_length: @run_length
      }

      {raw, @rest_deltas} = RunLength.encode(chunk, deltas ++ @rest_deltas)

      deltas_raw = for delta <- deltas, do: <<delta::16>>, into: <<>>

      assert <<
               0::1,
               2::2,
               @run_length::13,
               deltas_raw::binary
             >> == raw
    end
  end

  describe "decode/1" do
    test "chunk with `not_received` symbols" do
      raw = <<0::1, 0::2, @run_length::13, @rest::binary>>

      assert {:ok, chunk, [], @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :not_received,
               run_length: @run_length
             } = chunk
    end

    test "chunk with `no_delta` symbols" do
      raw = <<0::1, 3::2, @run_length::13, @rest::binary>>

      assert {:ok, chunk, [], @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :no_delta,
               run_length: @run_length
             } = chunk
    end

    test "chunk with `small_delta` symbols" do
      deltas = for i <- 1..@run_length, do: rem(i, 256)
      deltas_raw = for delta <- deltas, do: <<delta>>, into: <<>>
      raw = <<0::1, 1::2, @run_length::13, deltas_raw::binary, @rest::binary>>

      recv_deltas = Enum.reverse(deltas)
      assert {:ok, chunk, ^recv_deltas, @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :small_delta,
               run_length: @run_length
             } = chunk
    end

    test "chunk with `large_delta` symbols" do
      deltas = for i <- 1..@run_length, do: rem(i * 20, 32_000)
      deltas_raw = for delta <- deltas, do: <<delta::16>>, into: <<>>
      raw = <<0::1, 2::2, @run_length::13, deltas_raw::binary, @rest::binary>>

      recv_deltas = Enum.reverse(deltas)
      assert {:ok, chunk, ^recv_deltas, @rest} = RunLength.decode(raw)

      assert %RunLength{
               status_symbol: :large_delta,
               run_length: @run_length
             } = chunk
    end

    test "chunk too short" do
      raw = <<0::1, 2::1, 45::8>>
      assert {:error, :invalid_packet} = RunLength.decode(raw)
    end
  end
end
