require "test_helper"

class WhatsappBot::Providers::ResolverTest < ActiveSupport::TestCase
  setup do
    WhatsappBot::Config.reload!
  end

  teardown do
    WhatsappBot::Config.reload!
  end

  test "for_inbound defaults to configured provider" do
    adapter = WhatsappBot::Providers::Resolver.for_inbound
    assert_equal WhatsappBot::Config.default_provider, adapter.name
  end

  test "for_inbound accepts explicit provider name" do
    adapter = WhatsappBot::Providers::Resolver.for_inbound("meta")
    assert_equal :meta, adapter.name
  end

  test "for_inbound raises for unknown provider" do
    assert_raises WhatsappBot::Providers::Resolver::UnknownProviderError do
      WhatsappBot::Providers::Resolver.for_inbound("unknown_bsp")
    end
  end

  test "for_outbound prefers phone override over business and default" do
    WhatsappBot::Config.with_settings(
      "phone_overrides" => { "+573009998877" => "meta" },
      "business_overrides" => { "1" => "twilio" }
    ) do
      adapter = WhatsappBot::Providers::Resolver.for_outbound(
        to_phone: "whatsapp:+573009998877",
        business_id: 1
      )
      assert_equal :meta, adapter.name
    end
  end

  test "for_outbound uses business override when phone has none" do
    WhatsappBot::Config.with_settings(
      "phone_overrides" => {},
      "business_overrides" => { businesses(:one).id.to_s => "meta" }
    ) do
      adapter = WhatsappBot::Providers::Resolver.for_outbound(
        to_phone: "+573000000099",
        business_id: businesses(:one).id
      )
      assert_equal :meta, adapter.name
    end
  end

  test "for_outbound falls back to default provider" do
    WhatsappBot::Config.with_settings(
      "phone_overrides" => {},
      "business_overrides" => {}
    ) do
      adapter = WhatsappBot::Providers::Resolver.for_outbound(to_phone: "+573000000099")
      assert_equal WhatsappBot::Config.default_provider, adapter.name
    end
  end
end
