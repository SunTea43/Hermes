json.extract! inventory, :id, :business_id, :product_id, :current_quantity, :minimum_alert_quantity, :last_updated_at, :created_at, :updated_at
json.url inventory_url(inventory, format: :json)
