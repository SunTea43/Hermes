class PurchaseOrder < ApplicationRecord
  STATUSES = %w[pending received partial cancelled].freeze

  belongs_to :business
  belongs_to :created_by, class_name: "User", optional: true

  has_many :purchase_order_items, dependent: :destroy
  accepts_nested_attributes_for :purchase_order_items,
    allow_destroy: true,
    reject_if: :all_blank

  def recalculate_total!
    update_columns(total: purchase_order_items.sum(:subtotal))
  end
end
