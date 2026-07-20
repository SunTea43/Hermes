class CreateWhatsappSkillExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_skill_executions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.string :skill_name, null: false
      t.string :idempotency_key, null: false
      t.string :input_hash, null: false
      t.jsonb :result_payload, null: false, default: {}

      t.timestamps
    end

    add_index :whatsapp_skill_executions, :idempotency_key, unique: true
    add_index :whatsapp_skill_executions, [ :business_id, :skill_name ]
  end
end
