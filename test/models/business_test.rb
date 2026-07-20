require "test_helper"

class BusinessTest < ActiveSupport::TestCase
  test "belongs to an owner" do
    business = businesses(:one)
    assert_equal users(:one), business.owner
  end

  test "has many products" do
    business = businesses(:one)
    assert_includes business.products, products(:one)
  end

  test "has many sales orders" do
    assert_respond_to businesses(:one), :sales_orders
  end

  test "has many inventories" do
    assert_respond_to businesses(:one), :inventories
  end

  test "invalid owner_id raises validation error" do
    business = Business.new(name: "Test", currency: "COP", owner_id: 9_999_999)
    assert_not business.valid?
    assert_includes business.errors[:owner_id], "is invalid"
  end

  test "creates an active owner role assignment" do
    business = Business.create!(
      name: "Nueva tienda",
      currency: "COP",
      owner: users(:one)
    )

    assignment = business.role_assignments.find_by!(user: users(:one), role: "owner")
    assert_equal "active", assignment.status
  end

  test "moves the owner role assignment when owner changes" do
    business = Business.create!(
      name: "Tienda transferible",
      currency: "COP",
      owner: users(:one)
    )
    previous_assignment = business.role_assignments.find_by!(
      user: users(:one),
      role: "owner"
    )

    business.update!(owner: users(:two))

    assert_equal "inactive", previous_assignment.reload.status
    assert_equal "active", business.role_assignments.find_by!(
      user: users(:two),
      role: "owner"
    ).status
  end
end
