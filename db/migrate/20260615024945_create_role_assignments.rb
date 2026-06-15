class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.string :role
      t.string :assigned_modules
      t.text :restrictions
      t.datetime :assigned_at
      t.datetime :ended_at
      t.string :status

      t.timestamps
    end
  end
end
