class AddWhatsappAgentToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :whatsapp_agent, :integer, null: false, default: 0
  end
end
