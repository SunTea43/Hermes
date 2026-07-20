class WhatsappBusinessAuthorization < ApplicationRecord
  belongs_to :user
  belongs_to :business
  belongs_to :authorized_by, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :business_id }
  validate :user_must_have_business_access

  scope :enabled, -> { where(enabled: true) }

  private

  def user_must_have_business_access
    return if user.blank? || business.blank?
    return if user.can_access_business?(business)

    errors.add(:user, "must have access to the business")
  end
end
