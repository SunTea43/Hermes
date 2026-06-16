require "test_helper"

class SalesOrderItemTest < ActiveSupport::TestCase
  test "compute_subtotal without discount" do
    item = SalesOrderItem.new(
      sales_order: sales_orders(:one),
      product: products(:one),
      quantity: 5,
      unit_price: 2800,
      discount: 0
    )
    item.save!
    assert_equal 14000.0, item.subtotal.to_f
  end

  test "compute_subtotal applies percentage discount" do
    item = SalesOrderItem.new(
      sales_order: sales_orders(:one),
      product: products(:one),
      quantity: 10,
      unit_price: 1000,
      discount: 10
    )
    item.save!
    assert_equal 9000.0, item.subtotal.to_f
  end

  test "validates quantity greater than zero" do
    item = SalesOrderItem.new(
      sales_order: sales_orders(:one),
      product: products(:one),
      quantity: 0,
      unit_price: 2800
    )
    assert_not item.valid?
    assert_includes item.errors[:quantity], "must be greater than 0"
  end

  test "validates unit_price non-negative" do
    item = SalesOrderItem.new(
      sales_order: sales_orders(:one),
      product: products(:one),
      quantity: 1,
      unit_price: -1
    )
    assert_not item.valid?
  end

  test "saving item updates parent order total" do
    order = sales_orders(:one)
    before_total = order.total

    SalesOrderItem.create!(
      sales_order: order,
      product: products(:one),
      quantity: 1,
      unit_price: 100,
      discount: 0
    )

    assert_not_equal before_total, order.reload.total
  end
end
