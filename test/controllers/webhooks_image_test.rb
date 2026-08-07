require "test_helper"

class WebhooksImageTest < ActionDispatch::IntegrationTest
  def with_test_provider
    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {},
      "media" => {
        "audio_enabled" => true,
        "image_enabled" => true,
        "max_bytes" => 16.megabytes,
        "whisper_model" => "whisper-1",
        "transcriber" => "fake",
        "vision" => "fake",
        "vision_model" => "gpt-4o-mini"
      }
    ) { yield }
  end

  test "image message is interpreted and dispatched as purchase draft" do
    user = users(:one)
    WhatsappBot::Providers::TestAdapter.reset!

    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:#{user.whatsapp_phone}",
        To: "whatsapp:+14155238886",
        Body: "",
        MessageSid: "SMimage1",
        MediaId: "MEDIMAGE1",
        MediaType: "image",
        MediaMimeType: "image/jpeg"
      }
    end

    assert_response :ok
    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Compra a Juanito/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)

    audit = WhatsappMessageAudit.last
    assert_equal "dispatched", audit.status
    assert_equal "image", audit.metadata["media_kind"]
    assert_equal "purchase", audit.metadata.dig("interpretation", "intent")
  end
end
