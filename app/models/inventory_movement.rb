class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user
end
