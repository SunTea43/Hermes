module SalesOrders
  class RecordInventoryExitService < ApplicationService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize(sales_order, user:)
      @order = sales_order
      @user  = user
    end

    def call
      errors = []

      ActiveRecord::Base.transaction do
        @order.sales_order_items.includes(:product).each do |item|
          inventory = Inventory.find_by(business: @order.business, product: item.product)

          unless inventory
            errors << "No hay inventario registrado para #{item.product.name}"
            next
          end

          if inventory.current_quantity < item.quantity
            errors << "Stock insuficiente para #{item.product.name}: disponible #{inventory.current_quantity} #{item.product.unit_measure}"
          end
        end

        raise ActiveRecord::Rollback if errors.any?

        @order.sales_order_items.includes(:product).each do |item|
          inventory = Inventory.find_by!(business: @order.business, product: item.product)
          previous  = inventory.current_quantity

          inventory.update!(
            current_quantity: previous - item.quantity,
            last_updated_at: Time.current
          )

          InventoryMovement.create!(
            inventory: inventory,
            user: @user,
            previous_quantity: previous,
            new_quantity: inventory.current_quantity,
            movement_type: "sale_exit",
            reference_type: "SalesOrder",
            reference_id: @order.id,
            moved_at: Time.current,
            notes: "Salida por venta #{@order.reference_number}"
          )
        end
      end

      Result.new(success?: errors.empty?, errors: errors)
    end
  end
end
