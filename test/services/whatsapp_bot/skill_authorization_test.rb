require "test_helper"

class WhatsappBot::SkillAuthorizationTest < ActiveSupport::TestCase
  setup do
    @business = businesses(:one)
    @user = users(:two)
  end

  test "owner can execute every skill" do
    assert WhatsappBot::SkillAuthorization.authorize(
      user: users(:one),
      business: @business,
      skill: "registrar_pago"
    )
  end

  test "manager can execute write skills" do
    assign(role: "manager")

    assert authorized?("registrar_pago")
    assert authorized?("registrar_compra")
  end

  test "operator can execute reads" do
    assign(role: "operator")

    assert authorized?("consultar_inventario")
    assert authorized?("listar_stock_bajo")
    assert authorized?("consultar_resumen_ventas")
  end

  test "operator needs the matching module for sales and purchases" do
    assign(role: "operator", modules: "sales")

    assert authorized?("registrar_venta")
    assert_not authorized?("registrar_compra")
  end

  test "operator cannot register payments even with payments module" do
    assign(role: "operator", modules: "payments")

    assert_not authorized?("registrar_pago")
  end

  test "viewer can read but cannot write" do
    assign(role: "viewer")

    assert authorized?("consultar_inventario")
    assert_not authorized?("registrar_venta")
  end

  test "user without an active role is denied" do
    assert_not authorized?("consultar_inventario")
  end

  private

  def assign(role:, modules: nil)
    RoleAssignment.create!(
      user: @user,
      business: @business,
      role: role,
      assigned_modules: modules,
      status: "active",
      assigned_at: Time.current
    )
  end

  def authorized?(skill)
    WhatsappBot::SkillAuthorization.authorize(
      user: @user,
      business: @business,
      skill: skill
    )
  end
end
