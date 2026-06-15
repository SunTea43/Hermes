require "test_helper"

class SalesOrderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sales_order_item = sales_order_items(:one)
  end

  test "should get index" do
    get sales_order_items_url
    assert_response :success
  end

  test "should get new" do
    get new_sales_order_item_url
    assert_response :success
  end

  test "should create sales_order_item" do
    assert_difference("SalesOrderItem.count") do
      post sales_order_items_url, params: { sales_order_item: { discount: @sales_order_item.discount, product_id: @sales_order_item.product_id, quantity: @sales_order_item.quantity, sales_order_id: @sales_order_item.sales_order_id, subtotal: @sales_order_item.subtotal, unit_price: @sales_order_item.unit_price } }
    end

    assert_redirected_to sales_order_item_url(SalesOrderItem.last)
  end

  test "should show sales_order_item" do
    get sales_order_item_url(@sales_order_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_sales_order_item_url(@sales_order_item)
    assert_response :success
  end

  test "should update sales_order_item" do
    patch sales_order_item_url(@sales_order_item), params: { sales_order_item: { discount: @sales_order_item.discount, product_id: @sales_order_item.product_id, quantity: @sales_order_item.quantity, sales_order_id: @sales_order_item.sales_order_id, subtotal: @sales_order_item.subtotal, unit_price: @sales_order_item.unit_price } }
    assert_redirected_to sales_order_item_url(@sales_order_item)
  end

  test "should destroy sales_order_item" do
    assert_difference("SalesOrderItem.count", -1) do
      delete sales_order_item_url(@sales_order_item)
    end

    assert_redirected_to sales_order_items_url
  end
end
