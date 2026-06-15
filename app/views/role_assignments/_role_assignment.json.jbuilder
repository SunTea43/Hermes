json.extract! role_assignment, :id, :user_id, :business_id, :role, :assigned_modules, :restrictions, :assigned_at, :ended_at, :status, :created_at, :updated_at
json.url role_assignment_url(role_assignment, format: :json)
