class AddWhatsappAuthorizationToRoleAssignments < ActiveRecord::Migration[8.1]
  def up
    add_column :role_assignments, :whatsapp_enabled, :boolean,
      null: false, default: false
    add_column :role_assignments, :whatsapp_authorized_at, :datetime
    add_reference :role_assignments, :whatsapp_authorized_by,
      foreign_key: { to_table: :users }

    execute <<~SQL
      INSERT INTO role_assignments (
        user_id,
        business_id,
        role,
        status,
        assigned_at,
        created_at,
        updated_at,
        whatsapp_enabled
      )
      SELECT
        businesses.owner_id,
        businesses.id,
        'owner',
        'active',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        FALSE
      FROM businesses
      WHERE businesses.owner_id IS NOT NULL
      ON CONFLICT (user_id, business_id, role) DO UPDATE
      SET status = 'active', ended_at = NULL, updated_at = CURRENT_TIMESTAMP
    SQL
  end

  def down
    remove_reference :role_assignments, :whatsapp_authorized_by,
      foreign_key: { to_table: :users }
    remove_column :role_assignments, :whatsapp_authorized_at
    remove_column :role_assignments, :whatsapp_enabled
  end
end
