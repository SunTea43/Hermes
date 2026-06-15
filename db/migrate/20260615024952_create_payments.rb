class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :sales_order, null: false, foreign_key: true
      t.decimal :amount
      t.datetime :paid_at
      t.string :payment_method
      t.string :payment_type
      t.string :payment_status
      t.bigint :recorded_by_id
      t.text :notes

      t.timestamps
    end
  end
end
