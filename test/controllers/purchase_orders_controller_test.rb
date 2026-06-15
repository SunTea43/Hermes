require "test_helper"

class PurchaseOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @purchase_order = purchase_orders(:one)
  end

  test "should get index" do
    get purchase_orders_url
    assert_response :success
  end

  test "should get new" do
    get new_purchase_order_url
    assert_response :success
  end

  test "should create purchase_order" do
    assert_difference("PurchaseOrder.count") do
      post purchase_orders_url, params: { purchase_order: { business_id: @purchase_order.business_id, created_by_id: @purchase_order.created_by_id, notes: @purchase_order.notes, received_at: @purchase_order.received_at, reference_number: "PO-#{SecureRandom.hex(4)}", status: @purchase_order.status, supplier_name: @purchase_order.supplier_name } }
    end

    assert_redirected_to purchase_order_url(PurchaseOrder.last)
  end

  test "should show purchase_order" do
    get purchase_order_url(@purchase_order)
    assert_response :success
  end

  test "should get edit" do
    get edit_purchase_order_url(@purchase_order)
    assert_response :success
  end

  test "should update purchase_order" do
    patch purchase_order_url(@purchase_order), params: { purchase_order: { business_id: @purchase_order.business_id, created_by_id: @purchase_order.created_by_id, notes: @purchase_order.notes, received_at: @purchase_order.received_at, reference_number: @purchase_order.reference_number, status: @purchase_order.status, supplier_name: @purchase_order.supplier_name } }
    assert_redirected_to purchase_order_url(@purchase_order)
  end

  test "should destroy purchase_order" do
    assert_difference("PurchaseOrder.count", -1) do
      delete purchase_order_url(@purchase_order)
    end

    assert_redirected_to purchase_orders_url
  end
end
