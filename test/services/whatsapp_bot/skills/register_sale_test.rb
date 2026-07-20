require "test_helper"

class WhatsappBot::Skills::RegisterSaleTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @product = products(:one)
    @input = {
      product_id: @product.id,
      product_name: @product.name,
      quantity: 2,
      unit_price: 2500,
      unit_measure: @product.unit_measure,
      customer_name: "Don Julio",
      payment_condition: "cash"
    }
  end

  test "creates sale order and decreases inventory" do
    inventory = inventories(:one)
    before = inventory.current_quantity

    result = WhatsappBot::Skills::RegisterSale.call(
      user: @user,
      business: @business,
      input: @input,
      idempotency_key: "SM-sale-1:registrar_venta"
    )

    assert result.success?
    assert_equal before - 2, inventory.reload.current_quantity
    assert_equal 1, WhatsappSkillExecution.where(idempotency_key: "SM-sale-1:registrar_venta").count
  end

  test "replays without duplicating when same idempotency key" do
    key = "SM-sale-2:registrar_venta"

    first = WhatsappBot::Skills::RegisterSale.call(
      user: @user,
      business: @business,
      input: @input,
      idempotency_key: key
    )
    inventory_after_first = inventories(:one).reload.current_quantity

    assert_no_difference [ "SalesOrder.count", "WhatsappSkillExecution.count" ] do
      second = WhatsappBot::Skills::RegisterSale.call(
        user: @user,
        business: @business,
        input: @input,
        idempotency_key: key
      )

      assert second.success?
      assert second.idempotent_replay
      assert_equal first.data[:order_id], second.data[:order_id]
    end

    assert_equal inventory_after_first, inventories(:one).reload.current_quantity
  end

  test "fails when product does not belong to business" do
    result = WhatsappBot::Skills::RegisterSale.call(
      user: @user,
      business: @business,
      input: @input.merge(product_id: products(:two).id),
      idempotency_key: "SM-sale-3:registrar_venta"
    )

    assert_not result.success?
    assert_includes result.errors, "product not found"
  end

  test "viewer cannot create a sale" do
    viewer = users(:two)
    RoleAssignment.create!(
      user: viewer,
      business: @business,
      role: "viewer",
      status: "active",
      assigned_at: Time.current,
      whatsapp_enabled: true,
      whatsapp_authorized_by: @user,
      whatsapp_authorized_at: Time.current
    )

    assert_no_difference [ "SalesOrder.count", "WhatsappSkillExecution.count" ] do
      assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
        WhatsappBot::Skills::RegisterSale.call(
          user: viewer,
          business: @business,
          input: @input,
          idempotency_key: "SM-sale-viewer:registrar_venta"
        )
      end
    end
  end

  test "revoked user cannot replay an idempotent result" do
    key = "SM-sale-revoked:registrar_venta"
    WhatsappBot::Skills::RegisterSale.call(
      user: @user,
      business: @business,
      input: @input,
      idempotency_key: key
    )
    role_assignments(:one).update!(whatsapp_enabled: false)

    assert_raises WhatsappBot::AuthorizationGateway::NotAuthorized do
      WhatsappBot::Skills::RegisterSale.call(
        user: @user,
        business: @business,
        input: @input,
        idempotency_key: key
      )
    end
  end
end
