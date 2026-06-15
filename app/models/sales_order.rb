class SalesOrder < ApplicationRecord
  belongs_to :business
  belongs_to :created_by, class_name: "User", optional: true

  has_many :sales_order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
end
