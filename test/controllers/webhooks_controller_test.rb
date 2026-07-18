require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def with_test_provider
    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {}
    ) { yield }
  end

  test "unknown phone gets registration reply and ok" do
    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:+579999999999",
        To: "whatsapp:+14155238886",
        Body: "Hola",
        MessageSid: "SMunknown"
      }
    end

    assert_response :ok
    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_equal "+579999999999", delivered.to
    assert_match(/No encontré una cuenta/, delivered.body)
  end

  test "known phone dispatches to bot" do
    user = users(:one)
    replies_before = WhatsappBot::Providers::TestAdapter.deliveries.size

    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:#{user.whatsapp_phone}",
        To: "whatsapp:+14155238886",
        Body: "ayuda",
        MessageSid: "SMknown"
      }
    end

    assert_response :ok
    assert WhatsappBot::Providers::TestAdapter.deliveries.size > replies_before
  end

  test "explicit provider route uses named adapter" do
    user = users(:one)

    with_test_provider do
      post whatsapp_provider_webhook_path(provider: "test"), params: {
        From: "whatsapp:#{user.whatsapp_phone}",
        Body: "ayuda",
        MessageSid: "SMroute"
      }
    end

    assert_response :ok
    assert WhatsappBot::Providers::TestAdapter.deliveries.any?
  end

  test "unknown provider raises" do
    assert_raises WhatsappBot::Providers::Resolver::UnknownProviderError do
      post whatsapp_provider_webhook_path(provider: "meta"), params: {
        From: "whatsapp:+573000000001",
        Body: "hola"
      }
    end
  end

  test "invalid signature returns forbidden" do
    WhatsappBot::Providers::TestAdapter.valid_signature = false

    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:+573000000001",
        Body: "hola",
        MessageSid: "SMbad"
      }
    end

    assert_response :forbidden
    assert_empty WhatsappBot::Providers::TestAdapter.deliveries
  end
end
