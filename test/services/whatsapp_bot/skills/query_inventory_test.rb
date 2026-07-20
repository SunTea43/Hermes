require "test_helper"

class WhatsappBot::Skills::QueryInventoryTest < ActiveSupport::TestCase
  test "returns inventory for matching product" do
    result = WhatsappBot::Skills::QueryInventory.call(
      user: users(:one),
      business: businesses(:one),
      input: { product_name: "Arroz" }
    )

    assert result.success?
    assert_equal "Arroz", result.data[:product_name]
    assert_equal inventories(:one).current_quantity, result.data[:current_quantity]
  end

  test "fails when product is missing" do
    result = WhatsappBot::Skills::QueryInventory.call(
      user: users(:one),
      business: businesses(:one),
      input: { product_name: "NoExiste" }
    )

    assert_not result.success?
  end
end
