class CreateInventoryMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true
      t.decimal :previous_quantity
      t.decimal :new_quantity
      t.string :movement_type
      t.string :reference_type
      t.bigint :reference_id
      t.references :user, null: false, foreign_key: true
      t.datetime :moved_at
      t.text :notes

      t.timestamps
    end
  end
end
