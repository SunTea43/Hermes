class PurchaseOrder < ApplicationRecord
  STATUSES = %w[pending received partial cancelled].freeze

  belongs_to :business
  belongs_to :created_by, class_name: "User", optional: true

  has_many :purchase_order_items, dependent: :destroy
end
