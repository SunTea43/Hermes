require "test_helper"

class WhatsappBot::Providers::TwilioAdapterTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:params, :headers, :original_url, :request_parameters, keyword_init: true)

  setup do
    @adapter = WhatsappBot::Providers::TwilioAdapter.new
  end

  test "parse_inbound builds a normalized inbound message" do
    request = FakeRequest.new(
      params: ActionController::Parameters.new(
        "MessageSid" => "SMabc",
        "From" => "whatsapp:+573000000001",
        "To" => "whatsapp:+14155238886",
        "Body" => "Vendí 10kg arroz",
        "NumMedia" => "0"
      )
    )

    inbound = @adapter.parse_inbound(request)

    assert_equal :twilio, inbound.provider
    assert_equal "SMabc", inbound.provider_message_id
    assert_equal "+573000000001", inbound.from
    assert_equal "+14155238886", inbound.to
    assert_equal "Vendí 10kg arroz", inbound.body
    assert_nil inbound.media
  end

  test "parse_inbound accepts hash with indifferent access from Rails request params" do
    request = FakeRequest.new(
      params: {
        MessageSid: "SMhash",
        AccountSid: "AC123",
        From: "whatsapp:+573000000001",
        To: "whatsapp:+14155238886",
        Body: "Hola",
        NumMedia: "0",
        UnexpectedField: "not persisted"
      }.with_indifferent_access
    )

    inbound = @adapter.parse_inbound(request)

    assert_equal "SMhash", inbound.provider_message_id
    assert_equal(
      {
        "MessageSid" => "SMhash",
        "AccountSid" => "AC123",
        "From" => "whatsapp:+573000000001",
        "To" => "whatsapp:+14155238886",
        "Body" => "Hola",
        "NumMedia" => "0"
      },
      inbound.raw_payload
    )
    assert_not_includes inbound.raw_payload, "UnexpectedField"
  end

  test "parse_inbound includes media when present" do
    request = FakeRequest.new(
      params: ActionController::Parameters.new(
        "MessageSid" => "SMmedia",
        "From" => "whatsapp:+573000000001",
        "To" => "whatsapp:+14155238886",
        "Body" => "",
        "NumMedia" => "1",
        "MediaUrl0" => "https://example.com/img.jpg",
        "MediaContentType0" => "image/jpeg"
      )
    )

    inbound = @adapter.parse_inbound(request)

    assert_equal 1, inbound.media.size
    assert_equal "https://example.com/img.jpg", inbound.media.first[:url]
    assert_equal "image/jpeg", inbound.media.first[:content_type]
  end

  test "valid_signature? is true when validation is disabled" do
    assert_not WhatsappBot::Config.validate_signatures?
    assert @adapter.valid_signature?(
      FakeRequest.new(
        params: {},
        headers: {},
        original_url: "http://example.test",
        request_parameters: {}
      )
    )
  end

  test "valid_signature? is false when enabled and header is missing" do
    WhatsappBot::Config.with_settings("validate_signatures" => true) do
      ENV["TWILIO_AUTH_TOKEN"] = "token"
      request = FakeRequest.new(
        params: {},
        headers: {},
        original_url: "http://example.test/webhooks/whatsapp",
        request_parameters: {}
      )
      # ActionDispatch headers need [] access - use a simple hash-like object
      headers = Object.new
      headers.define_singleton_method(:[]) { |_key| nil }
      request = FakeRequest.new(
        params: {},
        headers: headers,
        original_url: "http://example.test/webhooks/whatsapp",
        request_parameters: {}
      )

      assert_not @adapter.valid_signature?(request)
    end
  ensure
    ENV.delete("TWILIO_AUTH_TOKEN")
  end
end
