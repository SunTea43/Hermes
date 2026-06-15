json.extract! sales_order, :id, :business_id, :reference_number, :created_by_id, :customer_name, :customer_identifier, :payment_condition, :payment_status, :payment_due_at, :total, :notes, :created_at, :updated_at
json.url sales_order_url(sales_order, format: :json)
