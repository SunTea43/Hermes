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
      assert_difference "WhatsappMessageAudit.count", 1 do
        post webhooks_whatsapp_path, params: {
          From: "whatsapp:+579999999999",
          To: "whatsapp:+14155238886",
          Body: "Hola",
          MessageSid: "SMunknown"
        }
      end
    end

    assert_response :ok
    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_equal "+579999999999", delivered.to
    assert_match(/No encontré una cuenta/, delivered.body)
    assert_equal "denied", WhatsappMessageAudit.last.status
  end

  test "known phone dispatches to bot when business is authorized" do
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
    audit = WhatsappMessageAudit.last
    assert_equal "dispatched", audit.status
    assert_equal businesses(:one), audit.business
  end

  test "denies when business is not whatsapp enabled" do
    businesses(:one).update!(whatsapp_enabled: false)
    user = users(:one)

    with_test_provider do
      post webhooks_whatsapp_path, params: {
        From: "whatsapp:#{user.whatsapp_phone}",
        Body: "ayuda",
        MessageSid: "SMdisabled"
      }
    end

    assert_response :ok
    assert_match(/no tiene una tienda autorizada/, WhatsappBot::Providers::TestAdapter.deliveries.last.body)
    assert_equal "denied", WhatsappMessageAudit.last.status
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
