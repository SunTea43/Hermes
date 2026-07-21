require "test_helper"

class WhatsappBot::ConfidenceGuardTest < ActiveSupport::TestCase
  test "keeps interpretation when confidence is high enough" do
    interpretation = WhatsappBot::Interpretation.new(intent: :sale, confidence: 0.9)

    result = WhatsappBot::ConfidenceGuard.call(interpretation, threshold: 0.7)

    assert_equal :sale, result.intent
  end

  test "downgrades to clarify when confidence is low" do
    interpretation = WhatsappBot::Interpretation.new(intent: :sale, confidence: 0.2)

    result = WhatsappBot::ConfidenceGuard.call(interpretation, threshold: 0.7)

    assert_equal :clarify, result.intent
    assert_equal "low_confidence", result.raw["guard"]
  end
end
