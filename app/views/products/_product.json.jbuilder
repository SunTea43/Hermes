json.extract! product, :id, :business_id, :name, :description, :unit_measure, :status, :created_at, :updated_at
json.url product_url(product, format: :json)
