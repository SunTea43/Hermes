require "test_helper"

class ProductPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product_price = product_prices(:one)
  end

  test "should get index" do
    get product_prices_url
    assert_response :success
  end

  test "should get new" do
    get new_product_price_url
    assert_response :success
  end

  test "should create product_price" do
    assert_difference("ProductPrice.count") do
      post product_prices_url, params: { product_price: { end_at: @product_price.end_at, note: @product_price.note, price_type: @product_price.price_type, product_id: @product_price.product_id, start_at: @product_price.start_at, unit_price: @product_price.unit_price } }
    end

    assert_redirected_to product_price_url(ProductPrice.last)
  end

  test "should show product_price" do
    get product_price_url(@product_price)
    assert_response :success
  end

  test "should get edit" do
    get edit_product_price_url(@product_price)
    assert_response :success
  end

  test "should update product_price" do
    patch product_price_url(@product_price), params: { product_price: { end_at: @product_price.end_at, note: @product_price.note, price_type: @product_price.price_type, product_id: @product_price.product_id, start_at: @product_price.start_at, unit_price: @product_price.unit_price } }
    assert_redirected_to product_price_url(@product_price)
  end

  test "should destroy product_price" do
    assert_difference("ProductPrice.count", -1) do
      delete product_price_url(@product_price)
    end

    assert_redirected_to product_prices_url
  end
end
