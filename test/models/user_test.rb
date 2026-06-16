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
end
