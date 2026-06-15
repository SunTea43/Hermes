class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :unit_measure
      t.string :status

      t.timestamps
    end
  end
end
