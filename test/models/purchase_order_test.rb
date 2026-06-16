require "test_helper"

class PurchaseOrderTest < ActiveSupport::TestCase
  test "valid statuses are defined" do
    assert_includes PurchaseOrder::STATUSES, "pending"
    assert_includes PurchaseOrder::STATUSES, "received"
    assert_includes PurchaseOrder::STATUSES, "partial"
    assert_includes PurchaseOrder::STATUSES, "cancelled"
  end

  test "recalculate_total! sums item subtotals" do
    order = purchase_orders(:one)
    order.update_columns(total: 0)
    order.recalculate_total!
    assert_equal order.purchase_order_items.sum(:subtotal), order.reload.total
  end

  test "belongs to a business" do
    order = purchase_orders(:one)
    assert_equal businesses(:one), order.business
  end
end
