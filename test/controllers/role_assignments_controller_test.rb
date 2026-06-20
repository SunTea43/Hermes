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

    assert_redirected_to user_url(RoleAssignment.last.user)
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
    assert_redirected_to user_url(@role_assignment.user)
  end

  test "should destroy role_assignment" do
    assert_difference("RoleAssignment.count", -1) do
      delete role_assignment_url(@role_assignment)
    end

    assert_redirected_to user_url(@role_assignment.user)
  end

  test "manager should not update role assignments from other businesses" do
    sign_in users(:two)

    patch role_assignment_url(role_assignments(:one)), params: {
      role_assignment: {
        user_id: role_assignments(:one).user_id,
        business_id: role_assignments(:one).business_id,
        role: "viewer",
        status: "active"
      }
    }

    assert_redirected_to root_url
    assert_equal "owner", role_assignments(:one).reload.role
  end

  test "manager should not create role assignments for other businesses" do
    sign_in users(:two)

    assert_no_difference("RoleAssignment.count") do
      post role_assignments_url, params: {
        role_assignment: {
          user_id: users(:two).id,
          business_id: businesses(:one).id,
          role: "viewer",
          status: "active"
        }
      }
    end

    assert_redirected_to root_url
  end
end
