class AddWhatsappAgentToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :whatsapp_agent, :string, null: false, default: "regex"
  end
end
