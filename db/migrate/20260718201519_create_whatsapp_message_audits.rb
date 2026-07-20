class CreateWhatsappMessageAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_message_audits do |t|
      t.references :user, null: true, foreign_key: true
      t.references :business, null: true, foreign_key: true
      t.string :provider, null: false
      t.string :provider_message_id
      t.string :from_phone, null: false
      t.text :body
      t.string :handler_name
      t.string :status, null: false, default: "received"
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :whatsapp_message_audits, :provider_message_id
    add_index :whatsapp_message_audits, :status
  end
end
