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
  has_many :whatsapp_message_audits, dependent: :nullify
  has_many :whatsapp_authorized_role_assignments,
    -> { where(status: "active", whatsapp_enabled: true) },
    class_name: "RoleAssignment"
  has_many :authorized_whatsapp_businesses,
    through: :whatsapp_authorized_role_assignments,
    source: :business
  has_many :granted_whatsapp_role_assignments,
    class_name: "RoleAssignment",
    foreign_key: :whatsapp_authorized_by_id,
    dependent: :nullify,
    inverse_of: :whatsapp_authorized_by
  belongs_to :default_whatsapp_business, class_name: "Business", optional: true

  validates :status, inclusion: { in: STATUSES }, allow_blank: true
  validates :whatsapp_phone,
    uniqueness: { message: "ya está en uso por otro usuario" },
    allow_blank: true
  validate :default_whatsapp_business_must_be_accessible, if: -> { default_whatsapp_business_id.present? }

  before_validation :normalize_whatsapp_phone
  before_validation :set_default_status

  def role_for(business)
    role_assignments.find_by(business_id: business.id, status: "active")&.role
  end

  def display_name
    name.presence || email
  end

  def accessible_businesses
    Business.joins(:role_assignments)
      .where(role_assignments: { user_id: id, status: "active" })
      .distinct
  end

  def manageable_businesses
    managed_ids = role_assignments.where(role: %w[owner manager], status: "active").select(:business_id)
    Business.where(id: managed_ids).distinct
  end

  def owns?(business)
    business.owner_id == id
  end

  def owner_or_manager_for?(business)
    %w[owner manager].include?(role_for(business))
  end

  def can_access_business?(business)
    role_assignments.where(business_id: business.id, status: "active").exists?
  end

  def whatsapp_authorized_for?(business)
    active? && role_assignments.whatsapp_enabled.exists?(business_id: business.id)
  end

  def active?
    status == "active"
  end

  private

  def normalize_whatsapp_phone
    self.whatsapp_phone = whatsapp_phone.presence
  end

  def set_default_status
    self.status = "active" if status.blank?
  end

  def default_whatsapp_business_must_be_accessible
    return if can_access_business?(default_whatsapp_business) &&
      whatsapp_authorized_for?(default_whatsapp_business)

    errors.add(
      :default_whatsapp_business_id,
      "must be an accessible business authorized for WhatsApp"
    )
  end
end
