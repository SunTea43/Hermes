require "test_helper"

class WhatsappBot::ImageOrderHandlerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @business = businesses(:one)
    @session = WhatsappBot::Session.new(@user, business: @business)
    WhatsappBot::Providers::TestAdapter.reset!
    @entities = {
      "items" => [
        {
          "product_name" => "arroz",
          "quantity" => 50,
          "unit" => "kg",
          "unit_price" => 2000
        }
      ]
    }
  end

  def awaiting_kind_state
    {
      intent: :media_order,
      step: :awaiting_order_kind,
      draft: { entities: @entities }
    }
  end

  test "asks compra or venta after reading photo items" do
    WhatsappBot::ImageOrderHandler.new(
      @user,
      "",
      @session,
      {},
      business: @business,
      entities: @entities
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Leí esto de la foto/i, delivered.body)
    assert_match(/arroz/i, delivered.body)
    assert_match(/compra/i, delivered.body)
    assert_match(/venta/i, delivered.body)
  end

  test "compra hands off to purchase confirmation" do
    WhatsappBot::ImageOrderHandler.new(
      @user,
      "compra",
      @session,
      awaiting_kind_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/Compra a/i, delivered.body)
    assert_match(/¿Confirmo\?/i, delivered.body)
  end

  test "venta hands off to sale flow" do
    WhatsappBot::ImageOrderHandler.new(
      @user,
      "venta",
      @session,
      awaiting_kind_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/arroz|Total|¿A quién\?|listo/i, delivered.body)
  end

  test "cancel clears media order session" do
    WhatsappBot::ImageOrderHandler.new(
      @user,
      "cancelar",
      @session,
      awaiting_kind_state,
      business: @business
    ).call

    delivered = WhatsappBot::Providers::TestAdapter.deliveries.last
    assert_match(/cancelada/i, delivered.body)
  end
end
