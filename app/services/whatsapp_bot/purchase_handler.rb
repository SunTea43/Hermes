module WhatsappBot
  class PurchaseHandler < BaseHandler
    def call
      case @state[:step]
      when :awaiting_confirmation
        handle_confirmation_step
      else
        handle_initial_message
      end
    end

    private

    def handle_initial_message
      parsed = parse_purchase_message
      unless parsed
        reply("No entendí. Ejemplo: \"Recibí de Juanito: arroz 50kg a $2,000\".")
        return
      end

      product = find_product(parsed[:product_name])
      unless product
        reply("No encontré el producto \"#{parsed[:product_name]}\".")
        return
      end

      draft = {
        product_id:    product.id,
        product_name:  product.name,
        supplier_name: parsed[:supplier_name],
        quantity:      parsed[:quantity],
        unit_price:    parsed[:unit_price],
        unit_measure:  product.unit_measure
      }

      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :purchase, step: :awaiting_confirmation, draft: draft)
      reply("Compra a #{draft[:supplier_name]}:\n- #{draft[:product_name]} #{draft[:quantity]}#{draft[:unit_measure]}: $#{total}\nTotal: $#{total}. ¿Confirmo?")
    end

    def handle_confirmation_step
      draft = @state[:draft]

      if negative?
        @session.clear
        reply("Compra cancelada.")
        return
      end

      unless affirmative?
        reply("Responde 'sí' para confirmar o 'no' para cancelar.")
        return
      end

      order = create_purchase_order(draft)
      @session.clear

      inventory = @business.inventories.find_by(product_id: draft[:product_id])
      stock_msg = inventory ? " Stock #{draft[:product_name]}: #{inventory.current_quantity}#{draft[:unit_measure]}" : ""
      reply("✅ #{order.reference_number} registrada.#{stock_msg}")
    end

    def create_purchase_order(draft)
      total = draft[:quantity] * draft[:unit_price]
      order = @business.purchase_orders.create!(
        supplier_name:    draft[:supplier_name],
        status:           "received",
        total:            total,
        received_at:      Time.current,
        created_by:       @user,
        reference_number: generate_reference
      )
      order.purchase_order_items.create!(
        product_id: draft[:product_id],
        quantity:   draft[:quantity],
        unit_price: draft[:unit_price],
        subtotal:   total
      )
      PurchaseOrders::RecordInventoryEntryService.call(order, @user)
      order
    end

    def parse_purchase_message
      match = @message.match(/(?:de\s+)?([\w\s]+?):\s*([\w\s]+?)\s+(\d+(?:[.,]\d+)?)\s*\w*\s+a\s+\$?([\d.,]+)/i)
      return nil unless match

      supplier, product_raw, qty_str, price_str = match.captures
      {
        supplier_name: supplier.strip,
        product_name:  product_raw.strip,
        quantity:      qty_str.tr(",", ".").to_f,
        unit_price:    price_str.tr(",", ".").to_f
      }
    end

    def find_product(name)
      @business.products.active.where("lower(name) LIKE ?", "%#{name.downcase}%").first
    end

    def generate_reference
      last = @business.purchase_orders.maximum(:id).to_i
      "COM-#{format('%03d', last + 1)}"
    end
  end
end
