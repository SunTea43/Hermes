json.extract! business, :id, :name, :description, :currency, :owner_id, :created_at, :updated_at
json.url business_url(business, format: :json)
