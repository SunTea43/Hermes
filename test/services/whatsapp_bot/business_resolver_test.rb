require "test_helper"

class WhatsappBot::BusinessResolverTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
  end

  test "returns the single whatsapp-enabled accessible business" do
    businesses(:two).update!(whatsapp_enabled: false)
    # user one only owns business one
    result = WhatsappBot::BusinessResolver.call(@user)

    assert result.ok?
    assert_equal @business, result.business
  end

  test "returns not_authorized when no enabled businesses" do
    @business.update!(whatsapp_enabled: false)

    result = WhatsappBot::BusinessResolver.call(@user)

    assert_not result.ok?
    assert_equal :not_authorized, result.error
  end

  test "returns ambiguous when multiple enabled businesses" do
    other = businesses(:two)
    other.update!(owner: @user, whatsapp_enabled: true)
    authorize(other)

    result = WhatsappBot::BusinessResolver.call(@user)

    assert_not result.ok?
    assert_equal :ambiguous, result.error
  end

  test "uses default_whatsapp_business when set" do
    other = businesses(:two)
    other.update!(owner: @user, whatsapp_enabled: true)
    authorize(other)
    @user.update!(default_whatsapp_business: other)

    result = WhatsappBot::BusinessResolver.call(@user)

    assert result.ok?
    assert_equal other, result.business
  end

  test "prefers session business id" do
    other = businesses(:two)
    other.update!(owner: @user, whatsapp_enabled: true)
    authorize(other)
    @user.update!(default_whatsapp_business: @business)

    result = WhatsappBot::BusinessResolver.call(@user, session_business_id: other.id)

    assert result.ok?
    assert_equal other, result.business
  end

  test "returns not_authorized when user has access but no whatsapp authorization" do
    role_assignments(:one).update!(whatsapp_enabled: false)

    result = WhatsappBot::BusinessResolver.call(@user)

    assert_not result.ok?
    assert_equal :not_authorized, result.error
  end

  test "returns not_authorized for an inactive user" do
    @user.update!(status: "inactive")

    result = WhatsappBot::BusinessResolver.call(@user)

    assert_not result.ok?
    assert_equal :not_authorized, result.error
  end

  private

  def authorize(business)
    assignment = @user.role_assignments.active.find_by!(business: business)
    assignment.update!(
      whatsapp_enabled: true,
      whatsapp_authorized_by: @user,
      whatsapp_authorized_at: Time.current
    )
  end
end
