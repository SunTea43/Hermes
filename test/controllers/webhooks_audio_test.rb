require "test_helper"

class WebhooksAudioTest < ActionDispatch::IntegrationTest
  def with_test_provider
    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {},
      "media" => {
        "audio_enabled" => true,
        "image_enabled" => false,
        "max_bytes" => 16.megabytes,
        "stt" => { "provider" => "fake" }
      }
    ) { yield }
  end

  test "audio message is transcribed and dispatched as purchase draft" do
    user = users(:one)
    WhatsappBot::Providers::TestAdapter.reset!

    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:#{user.whatsapp_phone}",
        To: "whatsapp:+14155238886",
        Body: "",
        MessageSid: "SMaudio1",
        MediaId: "MEDAUDIO1",
        MediaType: "audio",
        MediaMimeType: "audio/ogg"
      }
    end

    assert_response :ok
    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Compra a Juanito/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)

    audit = WhatsappMessageAudit.last
    assert_equal "dispatched", audit.status
    assert_equal "audio", audit.metadata["media_kind"]
  end
end
