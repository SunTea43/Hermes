require "test_helper"

class WhatsappBot::ResponseRendererTest < ActiveSupport::TestCase
  test "sale confirmation snapshot" do
    text = WhatsappBot::ResponseRenderer.sale_confirm(
      customer_name: "Don Julio",
      quantity: 10,
      unit_measure: "kg",
      product_name: "Arroz",
      total: 25_000,
      payment_condition: "cash"
    )

    assert_equal(
      "Venta a Don Julio: 10kg Arroz = $25000 (contado). ¿Confirmo? (sí/no)",
      text
    )
  end

  test "sale recorded with stock snapshot" do
    text = WhatsappBot::ResponseRenderer.sale_recorded(
      reference_number: "VEN-001",
      product_name: "Arroz",
      current_quantity: 90,
      unit_measure: "kg"
    )

    assert_equal "✅ VEN-001 registrada. Stock Arroz: 90kg", text
  end

  test "inventory item snapshots low and ok" do
    ok = WhatsappBot::ResponseRenderer.inventory_item(
      product_name: "Arroz",
      current_quantity: 90,
      unit_measure: "kg",
      minimum_alert_quantity: 20,
      low: false
    )
    low = WhatsappBot::ResponseRenderer.inventory_item(
      product_name: "Sal",
      current_quantity: 2,
      unit_measure: "kg",
      minimum_alert_quantity: 5,
      low: true
    )

    assert_equal "Arroz: 90kg ✅ (mín. 20)", ok
    assert_equal "Sal: 2kg ⚠️ (mín. 5)", low
  end

  test "daily report snapshot" do
    text = WhatsappBot::ResponseRenderer.daily_report(
      date: Date.new(2026, 6, 18),
      count: 3,
      total: 50_000,
      cash: 30_000,
      credit: 20_000,
      pending_portfolio: 12_500,
      low_stock_count: 2
    )

    assert_equal <<~MSG.strip, text
      📊 Resumen del día 18/06:
      - Ventas: 3 (total $50000)
        • Contado: $30000
        • Crédito: $20000
      - Cartera total pendiente: $12500
      ⚠️ 2 productos bajo mínimo
    MSG
  end

  test "unknown menu is stable" do
    assert_includes WhatsappBot::ResponseRenderer.unknown_menu, "Vendí 10kg de arroz"
    assert_includes WhatsappBot::ResponseRenderer.unknown_menu, "Reporte del día"
  end

  test "payment confirm snapshot" do
    text = WhatsappBot::ResponseRenderer.payment_confirm(
      customer_name: "María",
      remaining: 12_500,
      reference_number: "VEN-002",
      amount: 10_000,
      new_balance: 2_500
    )

    assert_equal(
      "María tiene saldo de $12500 (VEN-002). Abono de $10000.\nSaldo pendiente: $2500. ¿Confirmo?",
      text
    )
  end
end
