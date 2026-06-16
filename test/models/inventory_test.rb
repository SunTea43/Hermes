require "test_helper"

class InventoryTest < ActiveSupport::TestCase
  test "belongs to business and product" do
    inv = inventories(:one)
    assert_equal businesses(:one), inv.business
    assert_equal products(:one), inv.product
  end

  test "current_quantity is set" do
    inv = inventories(:one)
    assert inv.current_quantity > 0
  end

  test "has many inventory movements" do
    assert_respond_to inventories(:one), :inventory_movements
  end
end
