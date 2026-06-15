json.extract! inventory_movement, :id, :inventory_id, :previous_quantity, :new_quantity, :movement_type, :reference_type, :reference_id, :user_id, :moved_at, :notes, :created_at, :updated_at
json.url inventory_movement_url(inventory_movement, format: :json)
