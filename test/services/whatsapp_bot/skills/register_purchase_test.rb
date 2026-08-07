require "test_helper"

class WhatsappBot::Skills::RegisterPurchaseTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @product = products(:one)
  end

  test "creates purchase order and increases inventory" do
    inventory = inventories(:one)
    before = inventory.current_quantity

    result = WhatsappBot::Skills::RegisterPurchase.call(
      user: @user,
      business: @business,
      input: {
        supplier_name: "Juanito",
        items: [
          {
            product_id: @product.id,
            quantity: 10,
            unit_price: 2200
          }
        ]
      },
      idempotency_key: "SM-purchase-1:registrar_compra"
    )

    assert result.success?, result.errors.inspect
    assert_equal before + 10, inventory.reload.current_quantity
    assert_equal 1, WhatsappSkillExecution.where(idempotency_key: "SM-purchase-1:registrar_compra").count
  end
end
