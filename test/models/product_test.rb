require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "belongs to a business" do
    product = products(:one)
    assert_equal businesses(:one), product.business
  end

  test "has one inventory" do
    product = products(:one)
    assert_instance_of Inventory, product.inventory
  end

  test "has many product prices" do
    product = products(:one)
    assert_respond_to product, :product_prices
  end

  test "active status is valid" do
    product = Product.new(business: businesses(:one), name: "Test", unit_measure: "kg", status: "active")
    assert product.valid?
  end
end
