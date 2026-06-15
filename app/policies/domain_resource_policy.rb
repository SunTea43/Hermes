# frozen_string_literal: true

class DomainResourcePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    can_access_business?
  end

  def create?
    return true unless business

    owner_or_manager?
  end

  def update?
    owner_or_manager?
  end

  def destroy?
    owner_or_manager?
  end

  private

  def business
    @business ||= begin
      if record.respond_to?(:business)
        record.business
      elsif record.respond_to?(:product)
        record.product&.business
      elsif record.respond_to?(:purchase_order)
        record.purchase_order&.business
      elsif record.respond_to?(:sales_order)
        record.sales_order&.business
      elsif record.respond_to?(:inventory)
        record.inventory&.business
      end
    end
  end

  class Scope < Scope
    def resolve
      if scope.column_names.include?("business_id")
        scope.where(business_id: accessible_business_ids)
      elsif scope.column_names.include?("product_id")
        scope.joins(:product).where(products: { business_id: accessible_business_ids })
      elsif scope.column_names.include?("purchase_order_id")
        scope.joins(:purchase_order).where(purchase_orders: { business_id: accessible_business_ids })
      elsif scope.column_names.include?("sales_order_id")
        scope.joins(:sales_order).where(sales_orders: { business_id: accessible_business_ids })
      elsif scope.column_names.include?("inventory_id")
        scope.joins(:inventory).where(inventories: { business_id: accessible_business_ids })
      else
        scope.none
      end
    end

    private

    def accessible_business_ids
      @accessible_business_ids ||= begin
        owned_ids = Business.where(owner_id: user.id).pluck(:id)
        assigned_ids = user.role_assignments.where(status: "active").pluck(:business_id)
        (owned_ids + assigned_ids).uniq
      end
    end
  end
end
