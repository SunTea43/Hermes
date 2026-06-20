module PurchaseOrders
  class RecordInventoryEntryService < ApplicationService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize(purchase_order, user:)
      @order = purchase_order
      @user  = user
    end

    def call
      ActiveRecord::Base.transaction do
        @order.purchase_order_items.includes(:product).each do |item|
          inventory = Inventory.find_or_initialize_by(business: @order.business, product: item.product)
          previous  = inventory.current_quantity || 0

          inventory.assign_attributes(
            current_quantity: previous + item.quantity,
            minimum_alert_quantity: inventory.minimum_alert_quantity || 0,
            last_updated_at: Time.current
          )
          inventory.save!

          InventoryMovement.create!(
            inventory: inventory,
            user: @user,
            previous_quantity: previous,
            new_quantity: inventory.current_quantity,
            movement_type: "purchase_entry",
            reference_type: "PurchaseOrder",
            reference_id: @order.id,
            moved_at: Time.current,
            notes: "Entrada por compra #{@order.reference_number}"
          )
        end
      end

      Result.new(success?: true, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end
  end
end
