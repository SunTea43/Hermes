class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_orders do |t|
      t.references :business, null: false, foreign_key: true
      t.string :reference_number
      t.bigint :created_by_id
      t.string :supplier_name
      t.string :status
      t.datetime :received_at
      t.text :notes

      t.timestamps
    end
  end
end
