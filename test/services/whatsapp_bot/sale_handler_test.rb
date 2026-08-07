require "test_helper"

class WhatsappBot::SaleHandlerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @session = WhatsappBot::Session.new(@user, business: @business)
    WhatsappBot::Providers::TestAdapter.reset!
  end

  def payment_step_state
    {
      intent: :sale,
      step: :awaiting_payment_condition,
      draft: {
        customer_name: "Juanito",
        items: [
          {
            product_id: products(:one).id,
            product_name: "Arroz",
            quantity: 3,
            unit_price: 2500,
            unit_measure: "kg",
            line_total: 7500
          }
        ]
      }
    }
  end

  test "payment condition accepts contado and asks confirmation" do
    WhatsappBot::SaleHandler.new(
      @user,
      "Contado",
      @session,
      payment_step_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/contado/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
  end

  test "payment condition accepts credito and asks confirmation" do
    WhatsappBot::SaleHandler.new(
      @user,
      "Crédito",
      @session,
      payment_step_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/crédito/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
  end

  test "payment condition cancel clears session" do
    assert_no_difference "SalesOrder.count" do
      WhatsappBot::SaleHandler.new(
        @user,
        "cancelar",
        @session,
        payment_step_state,
        business: @business
      ).call
    end

    assert_equal "Venta cancelada.", WhatsappBot::Providers::TestAdapter.deliveries.last.body
  end

  test "payment condition invalid reply reminds options including cancelar" do
    WhatsappBot::SaleHandler.new(
      @user,
      "tarjeta",
      @session,
      payment_step_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Contado/, delivered.body)
    assert_match(/Crédito/, delivered.body)
    assert_match(/cancelar/, delivered.body)
  end

  def confirmation_state(extra_items: [])
    {
      intent: :sale,
      step: :awaiting_confirmation,
      draft: {
        customer_name: "Juanito",
        payment_condition: "cash",
        items: [
          {
            product_id: products(:one).id,
            product_name: "Arroz",
            quantity: 3,
            unit_price: 2500,
            unit_measure: "kg",
            line_total: 7500
          },
          *extra_items
        ]
      }
    }
  end

  test "confirmation allows adding missing products" do
    aceite = @business.products.create!(
      name: "Aceite",
      unit_measure: "lt",
      status: "active"
    )
    aceite.product_prices.create!(
      price_type: "sale",
      unit_price: 8000,
      start_at: Time.current
    )

    WhatsappBot::SaleHandler.new(
      @user,
      "también 2lt de aceite",
      @session,
      confirmation_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Arroz/, delivered.body)
    assert_match(/Aceite/, delivered.body)
    assert_match(/¿Confirmo\?/, delivered.body)
    assert_match(/agregar productos/, delivered.body)
  end
end
