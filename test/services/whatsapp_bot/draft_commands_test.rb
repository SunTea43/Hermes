require "test_helper"

class WhatsappBot::DraftCommandsTest < ActiveSupport::TestCase
  setup do
    @draft = {
      supplier_name: "Juanito",
      items: [
        {
          product_id: 1,
          product_name: "Arroz",
          quantity: 50,
          unit_price: 2000,
          unit_measure: "kg",
          line_total: 100_000
        },
        {
          product_id: 2,
          product_name: "Aceite",
          quantity: 10,
          unit_price: 8000,
          unit_measure: "lt",
          line_total: 80_000
        }
      ]
    }
  end

  test "removes item by product name" do
    command = WhatsappBot::DraftCommands.parse("quitar aceite")
    status, updated = WhatsappBot::DraftCommands.apply(@draft, command)

    assert_equal :ok, status
    assert_equal 1, updated[:items].size
    assert_equal "Arroz", updated[:items].first[:product_name]
  end

  test "changes unit price" do
    command = WhatsappBot::DraftCommands.parse("cambiar precio arroz 1900")
    status, updated = WhatsappBot::DraftCommands.apply(@draft, command)

    assert_equal :ok, status
    arroz = updated[:items].find { |item| item[:product_name] == "Arroz" }
    assert_equal 1900, arroz[:unit_price]
    assert_equal 95_000, arroz[:line_total]
  end

  test "sets supplier" do
    command = WhatsappBot::DraftCommands.parse("proveedor Don Pedro")
    status, updated = WhatsappBot::DraftCommands.apply(@draft, command)

    assert_equal :ok, status
    assert_equal "Don Pedro", updated[:supplier_name]
  end
end
