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
end
