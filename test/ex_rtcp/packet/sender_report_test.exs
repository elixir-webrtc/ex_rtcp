defmodule ExRTCP.Packet.SenderReportTest do
  use ExUnit.Case, async: true

  alias ExRTCP.Packet.{SenderReport, ReceptionReport}

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

  @ntp_timestamp 18_446_744_053_709_552_000
  @rtp_timestamp 1_234_554
  @packet_count 34_111_235
  @octet_count 11_324_123
  @profile_extension <<5, 5, 23, 8>>

  describe "decode/1" do
    test "packet without reports" do
      sender_report =
        <<@ssrc::32, @ntp_timestamp::64, @rtp_timestamp::32, @packet_count::32, @octet_count::32,
          @profile_extension::binary>>

      assert {:ok, decoded} = SenderReport.decode(sender_report, 0)

      assert %SenderReport{
               ssrc: @ssrc,
               ntp_timestamp: @ntp_timestamp,
               rtp_timestamp: @rtp_timestamp,
               packet_count: @packet_count,
               octet_count: @octet_count,
               reports: [],
               profile_extension: @profile_extension
             } = decoded
    end

    test "packet with reports" do
      sender_report =
        <<@ssrc::32, @ntp_timestamp::64, @rtp_timestamp::32, @packet_count::32, @octet_count::32,
          @report::binary, @report::binary, @profile_extension>>

      assert {:ok, decoded} = SenderReport.decode(sender_report, 2)

      assert %SenderReport{
               ssrc: @ssrc,
               ntp_timestamp: @ntp_timestamp,
               rtp_timestamp: @rtp_timestamp,
               packet_count: @packet_count,
               octet_count: @octet_count,
               reports: [@decoded_report, @decoded_report],
               profile_extension: @profile_extension
             } = decoded
    end

    test "invalid packet" do
      invalid_report = <<@ssrc::32, @ntp_timestamp::64, @rtp_timestamp::32>>

      assert {:error, :invalid_packet} = SenderReport.decode(invalid_report, 0)
    end
  end
end
