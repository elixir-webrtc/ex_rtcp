defmodule ExRTCP.Packet.ReceptionReportTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.ReceptionReport

  @ssrc 0x37B8307F
  @fraction_lost 0b00000110
  @total_lost 341_241
  @highest_sequence_number 44_321_412
  @jitter 23_234
  @last_sr 123_123_123
  @delay 65_536
  @profile_extension <<5, 5, 23, 8>>

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

  describe "decode/2" do
    test "single report" do
      report = @report <> @profile_extension

      assert {:ok, [decoded], @profile_extension} = ReceptionReport.decode(report, 1)

      assert @decoded_report == decoded
    end

    test "without extension" do
      assert {:ok, [decoded], <<>>} = ReceptionReport.decode(@report, 1)

      assert @decoded_report == decoded
    end

    test "multiple reports" do
      report = @report <> @report <> @profile_extension

      assert {:ok, [decoded1, decoded2], @profile_extension} = ReceptionReport.decode(report, 2)

      assert @decoded_report == decoded1
      assert @decoded_report == decoded2
    end

    test "invalid reports" do
      invalid_report =
        <<@ssrc::32, @fraction_lost::8, @total_lost::24, @highest_sequence_number::32>>

      report = @report <> invalid_report

      assert {:error, :invalid_packet} = ReceptionReport.decode(report, 2)
    end
  end
end
