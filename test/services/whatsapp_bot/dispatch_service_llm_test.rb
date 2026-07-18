require "test_helper"

class WhatsappBot::DispatchServiceLlmTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @business.update!(whatsapp_agent: "llm")
    WhatsappBot::Providers::TestAdapter.reset!
    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {}
    ) { @settings_block = true }
  end

  test "routes inventory intent from interpreter to inventory handler" do
    client = WhatsappBot::Llm::FakeClient.new(
      default: {
        "intent" => "inventory_query",
        "entities" => { "product_name" => "arroz" },
        "confidence" => 0.95
      }
    )

    WhatsappBot::Config.with_settings(
      "default_provider" => "test",
      "phone_overrides" => {},
      "business_overrides" => {}
    ) do
      WhatsappBot::DispatchService.call(
        @user,
        "cuanto arroz queda",
        business: @business,
        llm_client: client
      )
    end

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Arroz/, delivered.body)
  end

  test "falls back to unknown menu on low confidence" do
    client = WhatsappBot::Llm::FakeClient.new(
      default: {
        "intent" => "sale",
        "entities" => {},
        "confidence" => 0.1
      }
    )

    WhatsappBot::Config.with_settings("default_provider" => "test") do
      WhatsappBot::DispatchService.call(
        @user,
        "algo raro",
        business: @business,
        llm_client: client
      )
    end

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/No entendí ese mensaje/, delivered.body)
  end
end
