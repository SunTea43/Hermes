require "test_helper"

class SalesOrderTest < ActiveSupport::TestCase
  test "recalculate_total! sums item subtotals" do
    order = sales_orders(:one)
    order.update_columns(total: 0)
    order.recalculate_total!
    assert_equal order.sales_order_items.sum(:subtotal), order.reload.total
  end

  test "amount_paid returns sum of recorded payments" do
    order = sales_orders(:one)
    assert_equal 0, order.amount_paid
  end

  test "amount_due equals total when no payments" do
    order = sales_orders(:one)
    assert_equal order.total, order.amount_due
  end

  test "belongs to a business" do
    order = sales_orders(:one)
    assert_equal businesses(:one), order.business
  end
end
