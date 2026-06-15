class AddDomainForeignKeysAndIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :whatsapp_phone, unique: true

    add_index :businesses, :owner_id
    add_foreign_key :businesses, :users, column: :owner_id

    add_index :purchase_orders, [ :business_id, :reference_number ], unique: true
    add_index :purchase_orders, :created_by_id
    add_foreign_key :purchase_orders, :users, column: :created_by_id

    add_index :sales_orders, [ :business_id, :reference_number ], unique: true
    add_index :sales_orders, :created_by_id
    add_foreign_key :sales_orders, :users, column: :created_by_id

    add_index :payments, :recorded_by_id
    add_foreign_key :payments, :users, column: :recorded_by_id

    add_index :inventories, [ :business_id, :product_id ], unique: true

    add_index :role_assignments, [ :user_id, :business_id, :role ], unique: true, name: "index_role_assignments_on_user_business_role"

    add_index :inventory_movements, [ :reference_type, :reference_id ]
  end
end
