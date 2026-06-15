# frozen_string_literal: true

class BusinessPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.can_access_business?(record)
  end

  def create?
    true
  end

  def update?
    owner_or_manager?
  end

  def destroy?
    owner_or_manager?
  end

  private

  def business
    record
  end

  class Scope < Scope
    def resolve
      owned = scope.where(owner_id: user.id)
      assigned = scope.joins(:role_assignments).where(role_assignments: { user_id: user.id, status: "active" })
      scope.where(id: owned.select(:id)).or(scope.where(id: assigned.select(:id))).distinct
    end
  end
end
