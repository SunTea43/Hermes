require "test_helper"

class PurchaseOrders::RecordInventoryEntryServiceTest < ActiveSupport::TestCase
  setup do
    @order = purchase_orders(:one)
    @user  = users(:one)
  end

  test "increases inventory for each item" do
    inventory = inventories(:one)
    before_qty = inventory.current_quantity
    item_qty   = @order.purchase_order_items.find_by(product: products(:one)).quantity

    result = PurchaseOrders::RecordInventoryEntryService.new(@order, user: @user).call

    assert result.success?
    assert_in_delta before_qty + item_qty, inventory.reload.current_quantity, 0.01
  end

  test "creates inventory movement per item" do
    assert_difference "InventoryMovement.count", @order.purchase_order_items.count do
      PurchaseOrders::RecordInventoryEntryService.new(@order, user: @user).call
    end
  end

  test "movement type is purchase_entry" do
    PurchaseOrders::RecordInventoryEntryService.new(@order, user: @user).call
    movement = InventoryMovement.last
    assert_equal "purchase_entry", movement.movement_type
    assert_equal "PurchaseOrder", movement.reference_type
    assert_equal @order.id, movement.reference_id
  end

  test "creates inventory record if product has none" do
    product_without_inv = Product.create!(
      business: businesses(:one), name: "Nuevo", unit_measure: "und", status: "active"
    )
    item = PurchaseOrderItem.create!(
      purchase_order: @order, product: product_without_inv, quantity: 5, unit_price: 1000
    )

    assert_difference "Inventory.count" do
      PurchaseOrders::RecordInventoryEntryService.new(@order, user: @user).call
    end

    item.destroy!
    product_without_inv.destroy!
  end
end
