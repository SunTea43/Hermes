class CreateBusinesses < ActiveRecord::Migration[8.1]
  def change
    create_table :businesses do |t|
      t.string :name
      t.text :description
      t.string :currency
      t.bigint :owner_id

      t.timestamps
    end
  end
end
