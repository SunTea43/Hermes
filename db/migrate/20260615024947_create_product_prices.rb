class CreateProductPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :unit_price
      t.string :price_type
      t.date :start_at
      t.date :end_at
      t.string :note

      t.timestamps
    end
  end
end
