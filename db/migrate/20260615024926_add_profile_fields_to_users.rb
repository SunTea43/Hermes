class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :whatsapp_phone, :string
    add_column :users, :status, :string
    add_column :users, :last_active_at, :datetime
  end
end
