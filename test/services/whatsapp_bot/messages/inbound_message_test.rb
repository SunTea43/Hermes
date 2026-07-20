require "test_helper"

class WhatsappBot::Messages::InboundMessageTest < ActiveSupport::TestCase
  test "normalizes whatsapp: phone prefixes" do
    message = WhatsappBot::Messages::InboundMessage.new(
      provider: "twilio",
      provider_message_id: "SM123",
      from: "whatsapp:+573000000001",
      to: "whatsapp:+14155238886",
      body: "  hola  "
    )

    assert_equal :twilio, message.provider
    assert_equal "SM123", message.provider_message_id
    assert_equal "+573000000001", message.from
    assert_equal "+14155238886", message.to
    assert_equal "hola", message.body
  end
end
