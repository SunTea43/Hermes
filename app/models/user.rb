class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many :owned_businesses, class_name: "Business", foreign_key: :owner_id, dependent: :nullify
  has_many :role_assignments, dependent: :destroy
  has_many :purchase_orders_created, class_name: "PurchaseOrder", foreign_key: :created_by_id, dependent: :nullify
  has_many :sales_orders_created, class_name: "SalesOrder", foreign_key: :created_by_id, dependent: :nullify
  has_many :payments_recorded, class_name: "Payment", foreign_key: :recorded_by_id, dependent: :nullify
  has_many :inventory_movements, dependent: :nullify

  def role_for(business)
    role_assignments.find_by(business_id: business.id, status: "active")&.role
  end

  def owns?(business)
    business.owner_id == id
  end

  def owner_or_manager_for?(business)
    owns?(business) || %w[owner manager].include?(role_for(business))
  end

  def can_access_business?(business)
    return true if owns?(business)

    role_assignments.where(business_id: business.id, status: "active").exists?
  end
end
