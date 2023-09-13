defmodule ExRTCP.Packet.ReceptionReport do
  @moduledoc """
  Reception Reports carried by Sender/Receiver Report RTCP packets. 
  """

  alias ExRTCP.Packet

  @typedoc """
  Struct representing reception report present in Sender/Receiver Report RTCP packets.
  """
  @type t() :: %__MODULE__{
          ssrc: Packet.uint32(),
          fraction_lost: Packet.uint8(),
          total_lost: Packet.uint24(),
          highest_sequence_number: Packet.uint32(),
          jitter: Packet.uint32(),
          last_sr: Packet.uint32(),
          delay: Packet.uint32()
        }

  @enforce_keys [
    :ssrc,
    :fraction_lost,
    :total_lost,
    :highest_sequence_number,
    :jitter,
    :last_sr,
    :delay
  ]
  defstruct @enforce_keys

  @doc false
  @spec encode([t()], binary()) :: binary()
  def encode(reports, acc \\ <<>>)

  def encode([], acc), do: acc

  def encode([report | rest], acc) do
    %__MODULE__{
      ssrc: ssrc,
      fraction_lost: fraction_lost,
      total_lost: total_lost,
      highest_sequence_number: hsn,
      jitter: jitter,
      last_sr: last_sr,
      delay: delay
    } = report

    encoded =
      <<ssrc::32, fraction_lost::8, total_lost::24, hsn::32, jitter::32, last_sr::32, delay::32>>

    encode(rest, <<acc::binary, encoded::binary>>)
  end

  @doc false
  @spec decode(binary(), non_neg_integer(), [t()]) ::
          {:ok, [t()], binary()} | {:error, Packet.decode_error()}
  def decode(raw, count, acc \\ [])

  def decode(raw, 0, acc), do: {:ok, Enum.reverse(acc), raw}

  def decode(
        <<
          ssrc::32,
          fraction_lost::8,
          total_lost::24,
          highest_sequence_number::32,
          jitter::32,
          last_sr::32,
          delay::32,
          rest::binary
        >>,
        count,
        acc
      ) do
    report = %__MODULE__{
      ssrc: ssrc,
      fraction_lost: fraction_lost,
      total_lost: total_lost,
      highest_sequence_number: highest_sequence_number,
      jitter: jitter,
      last_sr: last_sr,
      delay: delay
    }

    decode(rest, count - 1, [report | acc])
  end

  def decode(_raw, _count, _acc), do: {:error, :invalid_packet}
end
