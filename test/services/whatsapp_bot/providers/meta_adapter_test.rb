require "test_helper"
require "openssl"

class WhatsappBot::Providers::MetaAdapterTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:params, :headers, :raw_post, keyword_init: true)

  setup do
    @adapter = WhatsappBot::Providers::MetaAdapter.new
  end

  test "parse_inbound builds a normalized inbound message from Cloud API payload" do
    payload = {
      "object" => "whatsapp_business_account",
      "entry" => [
        {
          "changes" => [
            {
              "value" => {
                "metadata" => {
                  "display_phone_number" => "15551234567",
                  "phone_number_id" => "123456"
                },
                "messages" => [
                  {
                    "from" => "573000000001",
                    "id" => "wamid.ABC123",
                    "timestamp" => "1710000000",
                    "type" => "text",
                    "text" => { "body" => "Vendí 10kg arroz" }
                  }
                ]
              }
            }
          ]
        }
      ]
    }

    request = FakeRequest.new(params: payload, raw_post: payload.to_json)
    inbound = @adapter.parse_inbound(request)

    assert_equal :meta, inbound.provider
    assert_equal "wamid.ABC123", inbound.provider_message_id
    assert_equal "+573000000001", inbound.from
    assert_equal "+15551234567", inbound.to
    assert_equal "Vendí 10kg arroz", inbound.body
    assert_nil inbound.media
  end

  test "parse_inbound returns nil for status-only callbacks" do
    payload = {
      "entry" => [
        {
          "changes" => [
            {
              "value" => {
                "statuses" => [ { "id" => "wamid.STATUS", "status" => "delivered" } ]
              }
            }
          ]
        }
      ]
    }

    request = FakeRequest.new(params: payload, raw_post: payload.to_json)

    assert_nil @adapter.parse_inbound(request)
  end

  test "parse_inbound extracts interactive button replies" do
    payload = {
      "entry" => [
        {
          "changes" => [
            {
              "value" => {
                "metadata" => { "display_phone_number" => "15551234567" },
                "messages" => [
                  {
                    "from" => "573000000001",
                    "id" => "wamid.BTN",
                    "type" => "interactive",
                    "interactive" => {
                      "type" => "button_reply",
                      "button_reply" => { "id" => "1", "title" => "Confirmar" }
                    }
                  }
                ]
              }
            }
          ]
        }
      ]
    }

    inbound = @adapter.parse_inbound(FakeRequest.new(params: payload, raw_post: payload.to_json))

    assert_equal "Confirmar", inbound.body
  end

  test "verify_subscription returns challenge when token matches" do
    ENV["META_WHATSAPP_VERIFY_TOKEN"] = "verify-token"
    request = FakeRequest.new(
      params: {
        "hub.mode" => "subscribe",
        "hub.verify_token" => "verify-token",
        "hub.challenge" => "12345"
      }
    )

    assert_equal "12345", @adapter.verify_subscription(request)
  ensure
    ENV.delete("META_WHATSAPP_VERIFY_TOKEN")
  end

  test "verify_subscription returns nil when token mismatches" do
    ENV["META_WHATSAPP_VERIFY_TOKEN"] = "verify-token"
    request = FakeRequest.new(
      params: {
        "hub.mode" => "subscribe",
        "hub.verify_token" => "wrong",
        "hub.challenge" => "12345"
      }
    )

    assert_nil @adapter.verify_subscription(request)
  ensure
    ENV.delete("META_WHATSAPP_VERIFY_TOKEN")
  end

  test "valid_signature? is true when validation is disabled" do
    assert_not WhatsappBot::Config.validate_signatures?
    assert @adapter.valid_signature?(FakeRequest.new(params: {}, headers: {}, raw_post: "{}"))
  end

  test "valid_signature? accepts matching X-Hub-Signature-256" do
    ENV["META_WHATSAPP_APP_SECRET"] = "app-secret"
    body = '{"object":"whatsapp_business_account"}'
    digest = OpenSSL::HMAC.hexdigest("SHA256", "app-secret", body)
    headers = { "X-Hub-Signature-256" => "sha256=#{digest}" }

    WhatsappBot::Config.with_settings("validate_signatures" => true) do
      assert @adapter.valid_signature?(FakeRequest.new(params: {}, headers: headers, raw_post: body))
    end
  ensure
    ENV.delete("META_WHATSAPP_APP_SECRET")
  end

  test "valid_signature? rejects missing signature when enabled" do
    ENV["META_WHATSAPP_APP_SECRET"] = "app-secret"
    headers = Object.new
    headers.define_singleton_method(:[]) { |_key| nil }

    WhatsappBot::Config.with_settings("validate_signatures" => true) do
      assert_not @adapter.valid_signature?(
        FakeRequest.new(params: {}, headers: headers, raw_post: "{}")
      )
    end
  ensure
    ENV.delete("META_WHATSAPP_APP_SECRET")
  end
end
