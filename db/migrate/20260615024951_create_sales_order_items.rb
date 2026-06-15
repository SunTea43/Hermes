class CreateSalesOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_order_items do |t|
      t.references :sales_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity
      t.decimal :unit_price
      t.decimal :discount
      t.decimal :subtotal

      t.timestamps
    end
  end
end
