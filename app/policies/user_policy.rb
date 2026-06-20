# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    manager_for_any_business?
  end

  def show?
    record == user || manageable_user?
  end

  def create?
    manager_for_any_business?
  end

  def update?
    record == user || manageable_user?
  end

  private

  def manageable_user?
    managed_business_ids = user.manageable_businesses.select(:id)

    record.role_assignments.where(business_id: managed_business_ids).exists? ||
      record.owned_businesses.where(id: managed_business_ids).exists?
  end

  def manager_for_any_business?
    user.manageable_businesses.exists?
  end

  class Scope < Scope
    def resolve
      managed_business_ids = user.manageable_businesses.select(:id)
      assigned = scope.joins(:role_assignments).where(role_assignments: { business_id: managed_business_ids })
      owners = scope.joins(:owned_businesses).where(businesses: { id: managed_business_ids })

      scope.where(id: user.id).or(scope.where(id: assigned.select(:id))).or(scope.where(id: owners.select(:id))).distinct
    end
  end
end
