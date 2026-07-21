class Business < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true

  has_many :products, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :sales_orders, dependent: :destroy
  has_many :inventories, dependent: :destroy
  has_many :role_assignments, dependent: :destroy
  has_many :whatsapp_message_audits, dependent: :nullify
  has_many :whatsapp_authorized_users,
    -> { where(role_assignments: { status: "active", whatsapp_enabled: true }) },
    through: :role_assignments,
    source: :user

  # Integer-backed enum. :inherit (2) means use global config/whatsapp.yml agent.default.
  # Key is :inherit (not :default) to avoid colliding with ActiveRecord's default APIs.
  enum :whatsapp_agent, {
    regex: 0,
    llm: 1,
    inherit: 2
  }, validate: true

  validates :owner_id, allow_nil: true,
    numericality: { only_integer: true },
    if: -> { owner_id.present? }
  validate :owner_must_exist, if: -> { owner_id.present? }

  after_save :sync_owner_role_assignment!, if: :saved_change_to_owner_id?

  scope :whatsapp_enabled, -> { where(whatsapp_enabled: true) }

  def resolved_whatsapp_agent
    inherit? ? WhatsappBot::Config.agent_default.to_s : whatsapp_agent
  end

  def llm_whatsapp_agent?
    resolved_whatsapp_agent == "llm"
  end

  private

  def owner_must_exist
    errors.add(:owner_id, :invalid) unless User.exists?(owner_id)
  end

  def sync_owner_role_assignment!
    role_assignments
      .where(role: "owner", status: "active")
      .where.not(user_id: owner_id)
      .update_all(status: "inactive", ended_at: Time.current, updated_at: Time.current)

    return if owner.blank?

    assignment = role_assignments.find_or_initialize_by(user: owner, role: "owner")
    assignment.update!(
      status: "active",
      ended_at: nil,
      assigned_at: assignment.assigned_at || Time.current
    )
  end
end
