# frozen_string_literal: true

class RoleAssignmentPolicy < DomainResourcePolicy
  def create?
    owner_or_manager?
  end

  def update?
    owner_or_manager?
  end

  def destroy?
    owner_or_manager?
  end
end
