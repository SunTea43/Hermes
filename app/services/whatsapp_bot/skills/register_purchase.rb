module WhatsappBot
  module Skills
    class RegisterPurchase < Base
      def self.skill_name = "registrar_compra"

      def call
        with_idempotency do
          product = @business.products.active.find_by(id: @input[:product_id])
          return failure("product not found") unless product

          quantity = @input[:quantity].to_d
          unit_price = @input[:unit_price].to_d
          return failure("invalid quantity") unless quantity.positive?

          total = quantity * unit_price
          order = nil

          ActiveRecord::Base.transaction do
            order = @business.purchase_orders.create!(
              supplier_name: @input[:supplier_name],
              status: "received",
              total: total,
              received_at: Time.current,
              created_by: @user,
              reference_number: next_reference
            )
            order.purchase_order_items.create!(
              product_id: product.id,
              quantity: quantity,
              unit_price: unit_price,
              subtotal: total
            )
            PurchaseOrders::RecordInventoryEntryService.call(order, @user)
          end

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
        last = @business.purchase_orders.maximum(:id).to_i
        "COM-#{format('%03d', last + 1)}"
      end
    end
  end
end
