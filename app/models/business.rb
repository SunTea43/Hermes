class Business < ApplicationRecord
	belongs_to :owner, class_name: "User", optional: true

	has_many :products, dependent: :destroy
	has_many :purchase_orders, dependent: :destroy
	has_many :sales_orders, dependent: :destroy
	has_many :inventories, dependent: :destroy
	has_many :role_assignments, dependent: :destroy
end
