class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :owned_businesses, class_name: "Business", foreign_key: :owner_id, dependent: :nullify
  has_many :role_assignments, dependent: :destroy
  has_many :purchase_orders_created, class_name: "PurchaseOrder", foreign_key: :created_by_id, dependent: :nullify
  has_many :sales_orders_created, class_name: "SalesOrder", foreign_key: :created_by_id, dependent: :nullify
  has_many :payments_recorded, class_name: "Payment", foreign_key: :recorded_by_id, dependent: :nullify
  has_many :inventory_movements, dependent: :nullify
end
