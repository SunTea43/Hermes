class CreateWhatsappBusinessAuthorizations < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_business_authorizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.references :authorized_by, null: true, foreign_key: { to_table: :users }
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :whatsapp_business_authorizations,
      [ :user_id, :business_id ],
      unique: true,
      name: "idx_whatsapp_authorizations_on_user_and_business"
  end
end
