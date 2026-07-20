module WhatsappBot
  module Skills
    class RegisterSale < Base
      def self.skill_name = "registrar_venta"

      def call
        with_idempotency do
          product = @business.products.active.find_by(id: @input[:product_id])
          return failure("product not found") unless product

          quantity = @input[:quantity].to_d
          unit_price = @input[:unit_price].to_d
          return failure("invalid quantity") unless quantity.positive?

          total = quantity * unit_price
          order = nil
          inventory_result = nil

          ActiveRecord::Base.transaction do
            order = @business.sales_orders.create!(
              customer_name: @input[:customer_name],
              payment_condition: @input[:payment_condition],
              payment_status: "pending",
              total: total,
              created_by: @user,
              reference_number: next_reference
            )
            order.sales_order_items.create!(
              product_id: product.id,
              quantity: quantity,
              unit_price: unit_price,
              subtotal: total
            )
            inventory_result = SalesOrders::RecordInventoryExitService.call(order, user: @user)
            raise ActiveRecord::Rollback unless inventory_result.success?
          end

          return failure(inventory_result.errors) unless inventory_result&.success?

          inventory = @business.inventories.find_by(product_id: product.id)
          success(
            order_id: order.id,
            reference_number: order.reference_number,
            product_name: product.name,
            unit_measure: product.unit_measure,
            current_quantity: inventory&.current_quantity
          )
        end
      end

      private

      def next_reference
        last = @business.sales_orders.maximum(:id).to_i
        "VEN-#{format('%03d', last + 1)}"
      end
    end
  end
end
