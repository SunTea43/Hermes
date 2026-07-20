require "test_helper"

class WhatsappMessageAuditTest < ActiveSupport::TestCase
  test "transitions status helpers" do
    audit = WhatsappMessageAudit.create!(
      user: users(:one),
      provider: "twilio",
      from_phone: "+573000000001",
      body: "hola",
      status: "received"
    )

    audit.mark_dispatched!(handler_name: "WhatsappBot::UnknownHandler", business: businesses(:one))
    assert_equal "dispatched", audit.reload.status
    assert_equal "WhatsappBot::UnknownHandler", audit.handler_name
    assert_equal businesses(:one), audit.business

    audit.mark_denied!(error_message: "nope")
    assert_equal "denied", audit.reload.status
    assert_equal "nope", audit.error_message
  end
end
