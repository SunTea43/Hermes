class CreateSalesOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_orders do |t|
      t.references :business, null: false, foreign_key: true
      t.string :reference_number
      t.bigint :created_by_id
      t.string :customer_name
      t.string :customer_identifier
      t.string :payment_condition
      t.string :payment_status
      t.datetime :payment_due_at
      t.decimal :total
      t.text :notes

      t.timestamps
    end
  end
end
