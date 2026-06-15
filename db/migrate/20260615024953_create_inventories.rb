class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :business, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :current_quantity
      t.decimal :minimum_alert_quantity
      t.datetime :last_updated_at

      t.timestamps
    end
  end
end
