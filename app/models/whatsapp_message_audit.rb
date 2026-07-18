class WhatsappMessageAudit < ApplicationRecord
  STATUSES = %w[received dispatched denied error].freeze

  belongs_to :user, optional: true
  belongs_to :business, optional: true

  validates :provider, :from_phone, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  def mark_dispatched!(handler_name:, business: nil)
    update!(
      status: "dispatched",
      handler_name: handler_name,
      business: business || self.business
    )
  end

  def mark_denied!(error_message:, business: nil)
    update!(
      status: "denied",
      error_message: error_message,
      business: business || self.business
    )
  end

  def mark_error!(error_message)
    update!(status: "error", error_message: error_message)
  end
end
