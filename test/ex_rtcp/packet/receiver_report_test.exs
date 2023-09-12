defmodule ExRTCP.Packet.ReceiverReportTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.{ReceiverReport, ReceptionReport}

  @ssrc 0x37B8307F
  @fraction_lost 0b00000110
  @total_lost 341_241
  @highest_sequence_number 44_321_412
  @jitter 23_234
  @last_sr 123_123_123
  @delay 65_536

  @report <<@ssrc::32, @fraction_lost::8, @total_lost::24, @highest_sequence_number::32,
            @jitter::32, @last_sr::32, @delay::32>>

  @decoded_report %ReceptionReport{
    ssrc: @ssrc,
    fraction_lost: @fraction_lost,
    total_lost: @total_lost,
    highest_sequence_number: @highest_sequence_number,
    jitter: @jitter,
    last_sr: @last_sr,
    delay: @delay
  }

  @profile_extension <<5, 5, 23, 8>>

  describe "encode/1" do
    test "packet without reports" do
      packet = %ReceiverReport{
        ssrc: @ssrc,
        reports: [],
        profile_extension: @profile_extension
      }

      assert {encoded, 0, 201} = ReceiverReport.encode(packet)

      valid = <<@ssrc::32, @profile_extension::binary>>

      assert encoded == valid
    end

    test "packet with report" do
      packet = %ReceiverReport{
        ssrc: @ssrc,
        reports: [@decoded_report, @decoded_report],
        profile_extension: @profile_extension
      }

      assert {encoded, 2, 201} = ReceiverReport.encode(packet)

      valid = <<@ssrc::32, @report, @report, @profile_extension::binary>>

      assert encoded == valid
    end
  end

  describe "decode/2" do
    test "packet without reports" do
      receiver_report = <<@ssrc::32, @profile_extension::binary>>

      assert {:ok, decoded} = ReceiverReport.decode(receiver_report, 0)

      assert %ReceiverReport{
               ssrc: @ssrc,
               reports: [],
               profile_extension: @profile_extension
             } = decoded
    end

    test "packet with reports" do
      receiver_report =
        <<@ssrc::32, @report::binary, @report::binary, @profile_extension>>

      assert {:ok, decoded} = ReceiverReport.decode(receiver_report, 2)

      assert %ReceiverReport{
               ssrc: @ssrc,
               reports: [@decoded_report, @decoded_report],
               profile_extension: @profile_extension
             } = decoded
    end

    test "invalid packet" do
      invalid_report = <<@ssrc::16>>

      assert {:error, :invalid_packet} = ReceiverReport.decode(invalid_report, 0)
    end
  end
end
