require "test_helper"

class WhatsappBot::SenderTest < ActiveSupport::TestCase
  test "deliver builds outbound message and delegates to resolved adapter" do
    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {}
    ) do
      WhatsappBot::Sender.deliver("+573000000001", "Ping", business_id: 42)
    end

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_equal "+573000000001", delivered.to
    assert_equal "Ping", delivered.body
    assert_equal 42, delivered.business_id
  end
end
