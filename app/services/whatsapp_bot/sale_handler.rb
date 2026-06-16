module WhatsappBot
  class SaleHandler < BaseHandler
    # Paso 1: parsear mensaje inicial → pedir cliente
    # Paso 2: recibir cliente → pedir condición de pago
    # Paso 3: recibir condición → confirmar y guardar

    def call
      case @state[:step]
      when :awaiting_customer
        handle_customer_step
      when :awaiting_payment_condition
        handle_payment_condition_step
      when :awaiting_confirmation
        handle_confirmation_step
      else
        handle_initial_message
      end
    end

    private

    def handle_initial_message
      parsed = parse_sale_message
      unless parsed
        reply("No entendí. Ejemplo: \"Vendí 10kg de arroz\" o \"Fiado a María 5kg arroz\".")
        return
      end

      product = find_product(parsed[:product_name])
      unless product
        reply("No encontré el producto \"#{parsed[:product_name]}\" en tu inventario.")
        return
      end

      price = product.product_prices.where(price_type: "sale").order(start_at: :desc).first
      unit_price = price&.unit_price || 0

      draft = {
        product_id:   product.id,
        product_name: product.name,
        quantity:     parsed[:quantity],
        unit_price:   unit_price,
        unit_measure: product.unit_measure
      }

      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :sale, step: :awaiting_customer, draft: draft)
      reply("#{draft[:quantity]}#{draft[:unit_measure]} de #{draft[:product_name]} × $#{draft[:unit_price]} = $#{total}. ¿A quién? (nombre o 'venta general')")
    end

    def handle_customer_step
      draft = @state[:draft]
      draft[:customer_name] = @message.strip
      @session.set(intent: :sale, step: :awaiting_payment_condition, draft: draft)
      reply("Venta a #{draft[:customer_name]}. ¿Contado o crédito?")
    end

    def handle_payment_condition_step
      draft = @state[:draft]
      condition = @message.strip.downcase

      unless condition.match?(/contado|crédito|credito/)
        reply("Responde 'contado' o 'crédito'.")
        return
      end

      draft[:payment_condition] = condition.match?(/cr/) ? "credit" : "cash"
      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :sale, step: :awaiting_confirmation, draft: draft)

      cond_label = draft[:payment_condition] == "credit" ? "crédito" : "contado"
      reply("Venta a #{draft[:customer_name]}: #{draft[:quantity]}#{draft[:unit_measure]} #{draft[:product_name]} = $#{total} (#{cond_label}). ¿Confirmo? (sí/no)")
    end

    def handle_confirmation_step
      draft = @state[:draft]

      if negative?
        @session.clear
        reply("Venta cancelada.")
        return
      end

      unless affirmative?
        reply("Responde 'sí' para confirmar o 'no' para cancelar.")
        return
      end

      order = create_sale_order(draft)
      @session.clear

      inventory = @business.inventories.find_by(product_id: draft[:product_id])
      stock_msg = inventory ? " Stock #{draft[:product_name]}: #{inventory.current_quantity}#{draft[:unit_measure]}" : ""
      reply("✅ #{order.reference_number} registrada.#{stock_msg}")
    end

    def create_sale_order(draft)
      total = draft[:quantity] * draft[:unit_price]
      order = @business.sales_orders.create!(
        customer_name:     draft[:customer_name],
        payment_condition: draft[:payment_condition],
        payment_status:    "pending",
        total:             total,
        created_by:        @user,
        reference_number:  generate_reference
      )
      order.sales_order_items.create!(
        product_id: draft[:product_id],
        quantity:   draft[:quantity],
        unit_price: draft[:unit_price],
        subtotal:   total
      )
      SalesOrders::RecordInventoryExitService.call(order, @user)
      order
    end

    def parse_sale_message
      match = @message.match(/(\d+(?:[.,]\d+)?)\s*(\w+)?\s+(?:de\s+)?(.+)/i)
      return nil unless match

      qty_str, _unit, product_raw = match.captures
      qty = qty_str.tr(",", ".").to_f
      { quantity: qty, product_name: product_raw.strip }
    end

    def find_product(name)
      @business.products.active.where("lower(name) LIKE ?", "%#{name.downcase}%").first
    end

    def generate_reference
      last = @business.sales_orders.maximum(:id).to_i
      "VEN-#{format('%03d', last + 1)}"
    end
  end
end
