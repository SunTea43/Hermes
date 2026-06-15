json.extract! payment, :id, :sales_order_id, :amount, :paid_at, :payment_method, :payment_type, :payment_status, :recorded_by_id, :notes, :created_at, :updated_at
json.url payment_url(payment, format: :json)
