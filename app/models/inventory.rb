class Inventory < ApplicationRecord
  belongs_to :business
  belongs_to :product

  has_many :inventory_movements, dependent: :destroy
end
