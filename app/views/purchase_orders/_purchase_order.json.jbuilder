json.extract! purchase_order, :id, :business_id, :reference_number, :created_by_id, :supplier_name, :status, :received_at, :notes, :created_at, :updated_at
json.url purchase_order_url(purchase_order, format: :json)
