require "test_helper"

class WhatsappBot::InterpreterTest < ActiveSupport::TestCase
  test "parses structured JSON from the LLM client" do
    client = WhatsappBot::Llm::FakeClient.new(
      default: {
        "intent" => "sale",
        "entities" => { "quantity" => 10, "product_name" => "arroz" },
        "confidence" => 0.91
      }
    )

    result = WhatsappBot::Interpreter.call("Vendí 10kg de arroz", client: client)

    assert_equal :sale, result.intent
    assert_equal 10, result.entities[:quantity]
    assert_in_delta 0.91, result.confidence, 0.001
  end

  test "retries once and falls back to clarify on invalid JSON" do
    client = Object.new
    calls = 0
    client.define_singleton_method(:complete) do |**_|
      calls += 1
      "not-json"
    end

    result = WhatsappBot::Interpreter.call("hola", client: client)

    assert_equal 2, calls
    assert_equal :clarify, result.intent
  end
end
