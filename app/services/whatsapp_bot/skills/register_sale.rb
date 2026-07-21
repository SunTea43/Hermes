module WhatsappBot
  module Skills
    class RegisterSale < Base
      def self.skill_name = "registrar_venta"

      def call
        with_idempotency do
          items, errors = normalized_items
          return failure("no items") if items.empty? && errors.empty?
          return failure(errors) if errors.any?

          order = nil
          inventory_result = nil

          ActiveRecord::Base.transaction do
            order = @business.sales_orders.create!(
              customer_name: @input[:customer_name],
              payment_condition: @input[:payment_condition],
              payment_status: "pending",
              total: 0,
              created_by: @user,
              reference_number: next_reference
            )

            items.each do |item|
              subtotal = item[:quantity] * item[:unit_price]
              order.sales_order_items.create!(
                product_id: item[:product].id,
                quantity: item[:quantity],
                unit_price: item[:unit_price],
                subtotal: subtotal
              )
            end

            order.recalculate_total!
            inventory_result = SalesOrders::RecordInventoryExitService.call(order, user: @user)
            raise ActiveRecord::Rollback unless inventory_result.success?
          end

          return failure(inventory_result.errors) unless inventory_result&.success?

          success(
            order_id: order.id,
            reference_number: order.reference_number,
            total: order.total,
            items: items.map { |item|
              inventory = @business.inventories.find_by(product_id: item[:product].id)
              {
                product_name: item[:product].name,
                unit_measure: item[:product].unit_measure,
                quantity: item[:quantity],
                current_quantity: inventory&.current_quantity
              }
            }
          )
        end
      end

      private

      def normalized_items
        raw_items = Array(@input[:items]).presence || [ legacy_item ].compact
        items = []
        errors = []

        raw_items.each do |raw|
          resolved = resolve_item(raw)
          if resolved[:error]
            errors << resolved[:error]
          else
            items << resolved
          end
        end

        [ items, errors ]
      end

      def legacy_item
        return if @input[:product_id].blank?

        @input.slice(:product_id, :quantity, :unit_price, :product_name, :unit_measure)
      end

      def resolve_item(raw)
        data = raw.with_indifferent_access
        product = @business.products.active.find_by(id: data[:product_id])
        return { error: "product not found" } unless product

        quantity = data[:quantity].to_d
        unit_price = data[:unit_price].to_d
        return { error: "invalid quantity" } unless quantity.positive?

        {
          product: product,
          quantity: quantity,
          unit_price: unit_price
        }
      end

      def next_reference
        last = @business.sales_orders.maximum(:id).to_i
        "VEN-#{format('%03d', last + 1)}"
      end
    end
  end
end
