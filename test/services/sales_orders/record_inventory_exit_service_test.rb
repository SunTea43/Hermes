require "test_helper"

class SalesOrders::RecordInventoryExitServiceTest < ActiveSupport::TestCase
  setup do
    @order = sales_orders(:one)
    @user  = users(:one)
  end

  test "decreases inventory for each item" do
    inventory = inventories(:one)
    before_qty = inventory.current_quantity

    result = SalesOrders::RecordInventoryExitService.new(@order, user: @user).call

    assert result.success?
    assert_in_delta before_qty - @order.sales_order_items.find_by(product: products(:one)).quantity,
                    inventory.reload.current_quantity, 0.01
  end

  test "creates an inventory movement per item" do
    assert_difference "InventoryMovement.count", @order.sales_order_items.count do
      SalesOrders::RecordInventoryExitService.new(@order, user: @user).call
    end
  end

  test "movement type is sale_exit" do
    SalesOrders::RecordInventoryExitService.new(@order, user: @user).call
    movement = InventoryMovement.last
    assert_equal "sale_exit", movement.movement_type
    assert_equal "SalesOrder", movement.reference_type
    assert_equal @order.id, movement.reference_id
  end

  test "returns failure when stock is insufficient" do
    inventories(:one).update!(current_quantity: 0)

    result = SalesOrders::RecordInventoryExitService.new(@order, user: @user).call

    assert_not result.success?
    assert result.errors.any?
  end

  test "does not change inventory on failure" do
    inventory = inventories(:one)
    inventory.update!(current_quantity: 0)
    before_qty = inventory.current_quantity

    SalesOrders::RecordInventoryExitService.new(@order, user: @user).call

    assert_equal before_qty, inventory.reload.current_quantity
  end
end
