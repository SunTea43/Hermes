class Product < ApplicationRecord
  belongs_to :business

  validates :name, presence: true
  validates :unit_measure, presence: true

  has_many :product_prices, dependent: :destroy
  has_many :purchase_order_items, dependent: :destroy
  has_many :sales_order_items, dependent: :destroy
  has_one :inventory, dependent: :destroy
end
