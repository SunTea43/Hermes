require "test_helper"

class RoleAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @role_assignment = role_assignments(:one)
  end

  test "should get index" do
    get role_assignments_url
    assert_response :success
  end

  test "should get new" do
    get new_role_assignment_url
    assert_response :success
  end

  test "should create role_assignment" do
    assert_difference("RoleAssignment.count") do
      post role_assignments_url, params: { role_assignment: { assigned_at: @role_assignment.assigned_at, assigned_modules: @role_assignment.assigned_modules, business_id: @role_assignment.business_id, ended_at: @role_assignment.ended_at, restrictions: @role_assignment.restrictions, role: "manager", status: @role_assignment.status, user_id: @role_assignment.user_id } }
    end

    assert_redirected_to role_assignment_url(RoleAssignment.last)
  end

  test "should show role_assignment" do
    get role_assignment_url(@role_assignment)
    assert_response :success
  end

  test "should get edit" do
    get edit_role_assignment_url(@role_assignment)
    assert_response :success
  end

  test "should update role_assignment" do
    patch role_assignment_url(@role_assignment), params: { role_assignment: { assigned_at: @role_assignment.assigned_at, assigned_modules: @role_assignment.assigned_modules, business_id: @role_assignment.business_id, ended_at: @role_assignment.ended_at, restrictions: @role_assignment.restrictions, role: @role_assignment.role, status: @role_assignment.status, user_id: @role_assignment.user_id } }
    assert_redirected_to role_assignment_url(@role_assignment)
  end

  test "should destroy role_assignment" do
    assert_difference("RoleAssignment.count", -1) do
      delete role_assignment_url(@role_assignment)
    end

    assert_redirected_to role_assignments_url
  end
end
