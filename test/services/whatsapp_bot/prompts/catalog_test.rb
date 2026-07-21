require "test_helper"

class WhatsappBot::Prompts::CatalogTest < ActiveSupport::TestCase
  setup do
    WhatsappBot::Prompts::Catalog.reload!
  end

  test "loads interpreter_v1 from yaml" do
    prompt = WhatsappBot::Prompts::Catalog.interpreter("interpreter_v1")

    assert_equal "interpreter_v1", prompt.version
    assert_includes prompt.system, "intérprete de intenciones"
    assert_includes prompt.system, "entities.items"
    assert_includes prompt.system, "Vendí 10kg arroz y 5lt aceite"
    assert_equal %w[intent entities confidence], prompt.schema[:required].map(&:to_s)
  end

  test "InterpreterV1 facade exposes constants-like API" do
    assert_equal "interpreter_v1", WhatsappBot::Prompts::InterpreterV1::VERSION
    assert_includes WhatsappBot::Prompts::InterpreterV1::SYSTEM, "Ejemplos:"
    assert_kind_of Hash, WhatsappBot::Prompts::InterpreterV1::SCHEMA
  end

  test "retry_user_prompt interpolates the message" do
    text = WhatsappBot::Prompts::InterpreterV1.retry_user_prompt("hola")

    assert_includes text, "hola"
    assert_includes text, "JSON válido"
  end

  test "raises when prompt file is missing" do
    assert_raises ArgumentError do
      WhatsappBot::Prompts::Catalog.interpreter("missing_prompt")
    end
  end
end
