# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_18_201519) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "businesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.text "description"
    t.string "name"
    t.bigint "owner_id"
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_enabled", default: false, null: false
    t.index [ "owner_id" ], name: "index_businesses_on_owner_id"
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.decimal "current_quantity"
    t.datetime "last_updated_at"
    t.decimal "minimum_alert_quantity"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "business_id", "product_id" ], name: "index_inventories_on_business_id_and_product_id", unique: true
    t.index [ "business_id" ], name: "index_inventories_on_business_id"
    t.index [ "product_id" ], name: "index_inventories_on_product_id"
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "inventory_id", null: false
    t.datetime "moved_at"
    t.string "movement_type"
    t.decimal "new_quantity"
    t.text "notes"
    t.decimal "previous_quantity"
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "inventory_id" ], name: "index_inventory_movements_on_inventory_id"
    t.index [ "reference_type", "reference_id" ], name: "index_inventory_movements_on_reference_type_and_reference_id"
    t.index [ "user_id" ], name: "index_inventory_movements_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "paid_at"
    t.string "payment_method"
    t.string "payment_status"
    t.string "payment_type"
    t.bigint "recorded_by_id"
    t.bigint "sales_order_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "recorded_by_id" ], name: "index_payments_on_recorded_by_id"
    t.index [ "sales_order_id" ], name: "index_payments_on_sales_order_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_at"
    t.string "note"
    t.string "price_type"
    t.bigint "product_id", null: false
    t.date "start_at"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index [ "product_id" ], name: "index_product_prices_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "status"
    t.string "unit_measure"
    t.datetime "updated_at", null: false
    t.index [ "business_id" ], name: "index_products_on_business_id"
  end

  create_table "purchase_order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.decimal "quantity"
    t.decimal "subtotal"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index [ "product_id" ], name: "index_purchase_order_items_on_product_id"
    t.index [ "purchase_order_id" ], name: "index_purchase_order_items_on_purchase_order_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "notes"
    t.datetime "received_at"
    t.string "reference_number"
    t.string "status"
    t.string "supplier_name"
    t.decimal "total"
    t.datetime "updated_at", null: false
    t.index [ "business_id", "reference_number" ], name: "index_purchase_orders_on_business_id_and_reference_number", unique: true
    t.index [ "business_id" ], name: "index_purchase_orders_on_business_id"
    t.index [ "created_by_id" ], name: "index_purchase_orders_on_created_by_id"
  end

  create_table "role_assignments", force: :cascade do |t|
    t.datetime "assigned_at"
    t.string "assigned_modules"
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.text "restrictions"
    t.string "role"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "business_id" ], name: "index_role_assignments_on_business_id"
    t.index [ "user_id", "business_id", "role" ], name: "index_role_assignments_on_user_business_role", unique: true
    t.index [ "user_id" ], name: "index_role_assignments_on_user_id"
  end

  create_table "sales_order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount"
    t.bigint "product_id", null: false
    t.decimal "quantity"
    t.bigint "sales_order_id", null: false
    t.decimal "subtotal"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index [ "product_id" ], name: "index_sales_order_items_on_product_id"
    t.index [ "sales_order_id" ], name: "index_sales_order_items_on_sales_order_id"
  end

  create_table "sales_orders", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "customer_identifier"
    t.string "customer_name"
    t.text "notes"
    t.string "payment_condition"
    t.datetime "payment_due_at"
    t.string "payment_status"
    t.string "reference_number"
    t.decimal "total"
    t.datetime "updated_at", null: false
    t.index [ "business_id", "reference_number" ], name: "index_sales_orders_on_business_id_and_reference_number", unique: true
    t.index [ "business_id" ], name: "index_sales_orders_on_business_id"
    t.index [ "created_by_id" ], name: "index_sales_orders_on_created_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "default_whatsapp_business_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_active_at"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "whatsapp_phone"
    t.index [ "default_whatsapp_business_id" ], name: "index_users_on_default_whatsapp_business_id"
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
    t.index [ "whatsapp_phone" ], name: "index_users_on_whatsapp_phone", unique: true
  end

  create_table "whatsapp_message_audits", force: :cascade do |t|
    t.text "body"
    t.bigint "business_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "from_phone", null: false
    t.string "handler_name"
    t.jsonb "metadata", default: {}, null: false
    t.string "provider", null: false
    t.string "provider_message_id"
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index [ "business_id" ], name: "index_whatsapp_message_audits_on_business_id"
    t.index [ "provider_message_id" ], name: "index_whatsapp_message_audits_on_provider_message_id"
    t.index [ "status" ], name: "index_whatsapp_message_audits_on_status"
    t.index [ "user_id" ], name: "index_whatsapp_message_audits_on_user_id"
  end

  add_foreign_key "businesses", "users", column: "owner_id"
  add_foreign_key "inventories", "businesses"
  add_foreign_key "inventories", "products"
  add_foreign_key "inventory_movements", "inventories"
  add_foreign_key "inventory_movements", "users"
  add_foreign_key "payments", "sales_orders"
  add_foreign_key "payments", "users", column: "recorded_by_id"
  add_foreign_key "product_prices", "products"
  add_foreign_key "products", "businesses"
  add_foreign_key "purchase_order_items", "products"
  add_foreign_key "purchase_order_items", "purchase_orders"
  add_foreign_key "purchase_orders", "businesses"
  add_foreign_key "purchase_orders", "users", column: "created_by_id"
  add_foreign_key "role_assignments", "businesses"
  add_foreign_key "role_assignments", "users"
  add_foreign_key "sales_order_items", "products"
  add_foreign_key "sales_order_items", "sales_orders"
  add_foreign_key "sales_orders", "businesses"
  add_foreign_key "sales_orders", "users", column: "created_by_id"
  add_foreign_key "users", "businesses", column: "default_whatsapp_business_id"
  add_foreign_key "whatsapp_message_audits", "businesses"
  add_foreign_key "whatsapp_message_audits", "users"
end
