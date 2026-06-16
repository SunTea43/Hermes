require "test_helper"

class SalesOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sales_order = sales_orders(:one)
  end

  test "GET index returns success" do
    get sales_orders_url
    assert_response :success
  end

  test "GET show returns success" do
    get sales_order_url(@sales_order)
    assert_response :success
  end

  test "GET new returns success" do
    get new_sales_order_url
    assert_response :success
  end

  test "GET edit returns success" do
    get edit_sales_order_url(@sales_order)
    assert_response :success
  end

  test "POST create creates a sales order and redirects" do
    assert_difference "SalesOrder.count" do
      post sales_orders_url, params: {
        sales_order: {
          business_id: businesses(:one).id,
          reference_number: "OV-TEST-#{SecureRandom.hex(4)}",
          customer_name: "Cliente Test",
          payment_condition: "cash",
          payment_status: "pending",
          total: 0
        }
      }
    end
    assert_redirected_to sales_order_url(SalesOrder.last)
  end

  test "POST create with invalid params renders new" do
    assert_no_difference "SalesOrder.count" do
      post sales_orders_url, params: {
        sales_order: { business_id: nil, reference_number: "" }
      }
    end
    assert_response :unprocessable_content
  end

  test "PATCH update changes customer name" do
    patch sales_order_url(@sales_order), params: {
      sales_order: { customer_name: "Julio Actualizado" }
    }
    assert_redirected_to sales_order_url(@sales_order)
    assert_equal "Julio Actualizado", @sales_order.reload.customer_name
  end

  test "DELETE destroy removes order" do
    assert_difference "SalesOrder.count", -1 do
      delete sales_order_url(@sales_order)
    end
    assert_redirected_to sales_orders_url
  end
end
