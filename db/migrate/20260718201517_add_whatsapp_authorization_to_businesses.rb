class AddWhatsappAuthorizationToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :whatsapp_enabled, :boolean, default: false, null: false
  end
end
