class AddTotalToPurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :purchase_orders, :total, :decimal
  end
end
