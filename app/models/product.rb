class Product < ApplicationRecord
  belongs_to :business

  has_many :product_prices, dependent: :destroy
  has_many :purchase_order_items, dependent: :destroy
  has_many :sales_order_items, dependent: :destroy
  has_one :inventory, dependent: :destroy
end
