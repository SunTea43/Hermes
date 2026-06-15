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
end
