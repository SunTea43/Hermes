require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "role_for returns active role in business" do
    user = users(:one)
    business = businesses(:one)
    assert_equal "owner", user.role_for(business)
  end

  test "role_for returns nil when no assignment" do
    user = users(:two)
    business = businesses(:one)
    assert_nil user.role_for(business)
  end

  test "owns? returns true for owner" do
    user = users(:one)
    business = businesses(:one)
    assert user.owns?(business)
  end

  test "owns? returns false for non-owner" do
    user = users(:two)
    business = businesses(:one)
    assert_not user.owns?(business)
  end

  test "can_access_business? true for owner" do
    assert users(:one).can_access_business?(businesses(:one))
  end

  test "can_access_business? false with no assignment" do
    assert_not users(:two).can_access_business?(businesses(:one))
  end

  test "whatsapp authorization comes from the active role assignment" do
    user = users(:one)
    business = businesses(:one)

    assert user.whatsapp_authorized_for?(business)

    role_assignments(:one).update!(whatsapp_enabled: false)
    assert_not user.whatsapp_authorized_for?(business)
  end

  test "whatsapp_phone must be unique when present" do
    user = User.new(
      email: "duplicate-phone@example.com",
      password: "password123",
      whatsapp_phone: users(:one).whatsapp_phone
    )

    assert_not user.valid?
    assert_includes user.errors[:whatsapp_phone], "ya está en uso por otro usuario"
  end

  test "blank whatsapp_phone is allowed for multiple users" do
    first = User.create!(
      email: "blank-phone-one@example.com",
      password: "password123",
      whatsapp_phone: ""
    )
    second = User.new(
      email: "blank-phone-two@example.com",
      password: "password123",
      whatsapp_phone: "   "
    )

    assert_nil first.whatsapp_phone
    assert second.valid?
  end
end
