require "test_helper"

class WhatsappBot::Evals::RunnerTest < ActiveSupport::TestCase
  test "scorecard passes with a perfect fake client seeded from expected cases" do
    responses = {}
    Dir[Rails.root.join("test/evals/cases/*.yml")].each do |path|
      YAML.safe_load_file(path).each do |row|
        expected = row.fetch("expected")
        responses[row.fetch("message")] = {
          "intent" => expected.fetch("intent"),
          "entities" => expected["entities"] || {},
          "confidence" => 0.95
        }
      end
    end

    client = WhatsappBot::Llm::FakeClient.new(responses)
    scorecard = WhatsappBot::Evals::Runner.call(client: client)

    assert scorecard.passed
    assert_in_delta 1.0, scorecard.intent_accuracy, 0.001
    assert_in_delta 1.0, scorecard.entity_exact_match, 0.001
    assert_operator scorecard.consistency, :>=, 0.95
  end

  test "scorecard fails when intents are wrong" do
    client = WhatsappBot::Llm::FakeClient.new(
      default: {
        "intent" => "unknown",
        "entities" => {},
        "confidence" => 0.1
      }
    )

    scorecard = WhatsappBot::Evals::Runner.call(client: client)

    assert_not scorecard.passed
    assert_operator scorecard.intent_accuracy, :<, 0.9
  end
end
