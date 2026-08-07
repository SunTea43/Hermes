require "test_helper"

class WhatsappBot::PurchaseHandlerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @session = WhatsappBot::Session.new(@user, business: @business)
    WhatsappBot::Providers::TestAdapter.reset!
  end

  def draft_with(*extra_items)
    items = [
      {
        product_id: products(:one).id,
        product_name: "Arroz",
        quantity: 50,
        unit_price: 2000,
        unit_measure: "kg",
        line_total: 100_000
      }
    ]
    items.concat(extra_items)
    {
      intent: :purchase,
      step: :awaiting_confirmation,
      draft: {
        supplier_name: "Juanito",
        items: items
      }
    }
  end

  test "initial purchase goes to confirmation" do
    WhatsappBot::PurchaseHandler.new(
      @user,
      "Recibí de Juanito: arroz 50kg a $2000",
      @session,
      {},
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Compra a Juanito/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
    assert_match(/quitar/, delivered.body)
  end

  test "cancel clears session without creating purchase" do
    assert_no_difference "PurchaseOrder.count" do
      WhatsappBot::PurchaseHandler.new(
        @user,
        "cancelar",
        @session,
        draft_with,
        business: @business
      ).call
    end

    assert_equal "Compra cancelada.", WhatsappBot::Providers::TestAdapter.deliveries.last.body
  end

  test "quitar updates draft and asks confirmation again" do
    aceite = @business.products.create!(
      name: "Aceite",
      unit_measure: "lt",
      status: "active"
    )
    state = draft_with(
      {
        product_id: aceite.id,
        product_name: "Aceite",
        quantity: 10,
        unit_price: 8000,
        unit_measure: "lt",
        line_total: 80_000
      }
    )

    WhatsappBot::PurchaseHandler.new(
      @user,
      "quitar aceite",
      @session,
      state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Arroz/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
    assert_no_match(/Aceite/, delivered.body)
  end

  test "compre without price uses catalog purchase price" do
    products(:one).product_prices.create!(
      price_type: "purchase",
      unit_price: 2200,
      start_at: Time.current
    )

    WhatsappBot::PurchaseHandler.new(
      @user,
      "Compré 10 kg de arroz",
      @session,
      {},
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Arroz/, delivered.body)
    assert_match(/\$2200/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
  end

  test "compre a supplier extracts supplier and items" do
    WhatsappBot::PurchaseHandler.new(
      @user,
      "Compré a Juanito 50kg de arroz a 2000",
      @session,
      {},
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Compra a Juanito/, delivered.body)
    assert_match(/50kg Arroz = \$100000/, delivered.body)
  end

  test "llm entities without unit_price still build draft from catalog" do
    products(:one).product_prices.create!(
      price_type: "purchase",
      unit_price: 2200,
      start_at: Time.current
    )

    WhatsappBot::PurchaseHandler.new(
      @user,
      "Compré 10 kg de arroz",
      @session,
      {},
      business: @business,
      entities: {
        "items" => [
          { "product_name" => "arroz", "quantity" => 10, "unit" => "kg", "unit_price" => nil }
        ],
        "supplier_name" => nil
      }
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Arroz/, delivered.body)
    assert_match(/\$2200/, delivered.body)
  end

  test "confirmation skill error cancels draft and notifies user" do
    original = WhatsappBot::Skills::Registry.method(:call)
    WhatsappBot::Skills::Registry.define_singleton_method(:call) { |*| raise ArgumentError, "boom" }

    begin
      WhatsappBot::PurchaseHandler.new(
        @user,
        "sí",
        @session,
        draft_with,
        business: @business
      ).call
    ensure
      WhatsappBot::Skills::Registry.define_singleton_method(:call, original)
    end

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/No pude registrar la compra/, delivered.body)
    assert_match(/Operación cancelada/, delivered.body)
  end
end
