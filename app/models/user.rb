class User < ApplicationRecord
  STATUSES = %w[active inactive].freeze

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

  validates :status, inclusion: { in: STATUSES }, allow_blank: true

  before_validation :set_default_status

  def role_for(business)
    role_assignments.find_by(business_id: business.id, status: "active")&.role
  end

  def display_name
    name.presence || email
  end

  def accessible_businesses
    owned = Business.where(owner_id: id)
    assigned = Business.joins(:role_assignments).where(role_assignments: { user_id: id, status: "active" })
    Business.where(id: owned.select(:id)).or(Business.where(id: assigned.select(:id))).distinct
  end

  def manageable_businesses
    managed_ids = role_assignments.where(role: %w[owner manager], status: "active").select(:business_id)
    Business.where(owner_id: id).or(Business.where(id: managed_ids)).distinct
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

  private

  def set_default_status
    self.status = "active" if status.blank?
  end
end
