require "test_helper"

class InventoryMovementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @inventory_movement = inventory_movements(:one)
  end

  test "should get index" do
    get inventory_movements_url
    assert_response :success
  end

  test "should get new" do
    get new_inventory_movement_url
    assert_response :success
  end

  test "should create inventory_movement" do
    assert_difference("InventoryMovement.count") do
      post inventory_movements_url, params: { inventory_movement: { inventory_id: @inventory_movement.inventory_id, moved_at: @inventory_movement.moved_at, movement_type: @inventory_movement.movement_type, new_quantity: @inventory_movement.new_quantity, notes: @inventory_movement.notes, previous_quantity: @inventory_movement.previous_quantity, reference_id: @inventory_movement.reference_id, reference_type: @inventory_movement.reference_type, user_id: @inventory_movement.user_id } }
    end

    assert_redirected_to inventory_movement_url(InventoryMovement.last)
  end

  test "should show inventory_movement" do
    get inventory_movement_url(@inventory_movement)
    assert_response :success
  end

  test "should get edit" do
    get edit_inventory_movement_url(@inventory_movement)
    assert_response :success
  end

  test "should update inventory_movement" do
    patch inventory_movement_url(@inventory_movement), params: { inventory_movement: { inventory_id: @inventory_movement.inventory_id, moved_at: @inventory_movement.moved_at, movement_type: @inventory_movement.movement_type, new_quantity: @inventory_movement.new_quantity, notes: @inventory_movement.notes, previous_quantity: @inventory_movement.previous_quantity, reference_id: @inventory_movement.reference_id, reference_type: @inventory_movement.reference_type, user_id: @inventory_movement.user_id } }
    assert_redirected_to inventory_movement_url(@inventory_movement)
  end

  test "should destroy inventory_movement" do
    assert_difference("InventoryMovement.count", -1) do
      delete inventory_movement_url(@inventory_movement)
    end

    assert_redirected_to inventory_movements_url
  end
end
