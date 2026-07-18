class AddDefaultWhatsappBusinessToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :default_whatsapp_business, foreign_key: { to_table: :businesses }
  end
end
