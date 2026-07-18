class Business < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true

  has_many :products, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :sales_orders, dependent: :destroy
  has_many :inventories, dependent: :destroy
  has_many :role_assignments, dependent: :destroy
  has_many :whatsapp_message_audits, dependent: :nullify

  validates :owner_id, allow_nil: true,
    numericality: { only_integer: true },
    if: -> { owner_id.present? }
  validate :owner_must_exist, if: -> { owner_id.present? }

  scope :whatsapp_enabled, -> { where(whatsapp_enabled: true) }

  private

  def owner_must_exist
    errors.add(:owner_id, :invalid) unless User.exists?(owner_id)
  end
end
