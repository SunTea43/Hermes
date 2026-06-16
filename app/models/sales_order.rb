class SalesOrder < ApplicationRecord
  STATUSES = %w[pending completed cancelled].freeze
  PAYMENT_CONDITIONS = %w[cash credit].freeze
  PAYMENT_STATUSES = %w[pending partial paid cancelled].freeze

  belongs_to :business
  belongs_to :created_by, class_name: "User", optional: true

  has_many :sales_order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :sales_order_items,
    allow_destroy: true,
    reject_if: :all_blank

  def self.includes_detail
    includes(sales_order_items: :product, payments: :recorded_by, business: [], created_by: [])
  end

  def includes_detail
    self.class.where(id: id).includes_detail.first
  end

  def recalculate_total!
    update_columns(total: sales_order_items.sum(:subtotal))
  end

  def amount_paid
    payments.where(payment_status: "recorded").sum(:amount)
  end

  def amount_due
    (total || 0) - amount_paid
  end
end
