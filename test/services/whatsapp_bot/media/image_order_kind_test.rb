require "test_helper"

class WhatsappBot::Media::ImageOrderKindTest < ActiveSupport::TestCase
  def interpretation(intent:, caption_entities: true)
    WhatsappBot::Interpretation.new(
      intent: intent,
      entities: {
        "items" => [ { "product_name" => "arroz", "quantity" => 10, "unit_price" => 2000 } ]
      },
      confidence: 0.9,
      raw: { "source" => "image" }
    )
  end

  test "forces clarify when photo has no caption" do
    result = WhatsappBot::Media::ImageOrderKind.normalize(interpretation(intent: :purchase), caption: nil)

    assert_equal :clarify, result.intent
    assert_equal "arroz", result.entities[:items].first["product_name"]
    assert_equal "ask_user", result.raw["order_kind"]
  end

  test "caption compra keeps purchase" do
    result = WhatsappBot::Media::ImageOrderKind.normalize(
      interpretation(intent: :clarify),
      caption: "compra de Juanito"
    )

    assert_equal :purchase, result.intent
  end

  test "caption venta keeps sale" do
    result = WhatsappBot::Media::ImageOrderKind.normalize(
      interpretation(intent: :clarify),
      caption: "venta"
    )

    assert_equal :sale, result.intent
  end
end
