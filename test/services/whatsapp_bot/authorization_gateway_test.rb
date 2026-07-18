require "test_helper"

class WhatsappBot::AuthorizationGatewayTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
  end

  test "authorize! succeeds for owner of enabled business" do
    assert WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: @business)
  end

  test "authorize! raises when whatsapp is disabled" do
    @business.update!(whatsapp_enabled: false)

    assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
      WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: @business)
    end
  end

  test "authorize! raises when user cannot access business" do
    other = businesses(:two)

    assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
      WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: other)
    end
  end

  test "authorize returns false instead of raising" do
    @business.update!(whatsapp_enabled: false)

    assert_not WhatsappBot::AuthorizationGateway.authorize(user: @user, business: @business)
  end
end
