json.extract! purchase_order_item, :id, :purchase_order_id, :product_id, :quantity, :unit_price, :subtotal, :notes, :created_at, :updated_at
json.url purchase_order_item_url(purchase_order_item, format: :json)
