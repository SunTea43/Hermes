require "test_helper"

class WhatsappBusinessAuthorizationTest < ActiveSupport::TestCase
  test "requires the user to have access to the business" do
    authorization = WhatsappBusinessAuthorization.new(
      user: users(:one),
      business: businesses(:two),
      authorized_by: users(:two)
    )

    assert_not authorization.valid?
    assert_includes authorization.errors[:user], "must have access to the business"
  end

  test "allows an active role assignment" do
    RoleAssignment.create!(
      user: users(:one),
      business: businesses(:two),
      role: "viewer",
      status: "active",
      assigned_at: Time.current
    )

    authorization = WhatsappBusinessAuthorization.new(
      user: users(:one),
      business: businesses(:two),
      authorized_by: users(:two)
    )

    assert authorization.valid?
  end

  test "is unique per user and business" do
    duplicate = WhatsappBusinessAuthorization.new(
      user: users(:one),
      business: businesses(:one),
      authorized_by: users(:one)
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
