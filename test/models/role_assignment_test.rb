require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  test "whatsapp_enabled scope requires an active assignment and channel access" do
    assignment = role_assignments(:one)

    assert_includes RoleAssignment.whatsapp_enabled, assignment

    assignment.update!(status: "inactive")
    assert_not_includes RoleAssignment.whatsapp_enabled, assignment
  end

  test "records who enabled whatsapp on the role" do
    assignment = role_assignments(:one)

    assert assignment.whatsapp_enabled?
    assert_equal users(:one), assignment.whatsapp_authorized_by
    assert assignment.whatsapp_authorized_at.present?
  end
end
