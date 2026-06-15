class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }, allow_nil: false
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false

  before_save :compute_subtotal

  private

  def compute_subtotal
    self.subtotal = (quantity || 0) * (unit_price || 0)
  end
end
