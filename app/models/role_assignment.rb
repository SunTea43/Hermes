class RoleAssignment < ApplicationRecord
  ROLES = %w[owner manager operator viewer].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :user
  belongs_to :business
  belongs_to :whatsapp_authorized_by, class_name: "User", optional: true

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }, allow_blank: true

  before_validation :set_defaults

  scope :active, -> { where(status: "active") }
  scope :whatsapp_enabled, -> { active.where(whatsapp_enabled: true) }

  private

  def set_defaults
    self.status = "active" if status.blank?
    self.assigned_at ||= Time.current
  end
end
