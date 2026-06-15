json.extract! product_price, :id, :product_id, :unit_price, :price_type, :start_at, :end_at, :note, :created_at, :updated_at
json.url product_price_url(product_price, format: :json)
