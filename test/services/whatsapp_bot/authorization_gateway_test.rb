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

  test "authorize! raises when user is inactive" do
    @user.update!(status: "inactive")

    error = assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
      WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: @business)
    end

    assert_equal "user inactive", error.message
  end

  test "authorize! raises when user has access but no whatsapp authorization" do
    whatsapp_business_authorizations(:one).update!(enabled: false)

    error = assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
      WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: @business)
    end

    assert_equal "user not authorized for whatsapp", error.message
  end

  test "authorize! allows an assigned user with whatsapp authorization" do
    other = businesses(:two)
    RoleAssignment.create!(
      user: @user,
      business: other,
      role: "viewer",
      status: "active",
      assigned_at: Time.current
    )
    WhatsappBusinessAuthorization.create!(
      user: @user,
      business: other,
      authorized_by: users(:two)
    )

    assert WhatsappBot::AuthorizationGateway.authorize!(user: @user, business: other)
  end
end
