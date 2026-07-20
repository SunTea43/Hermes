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

      result = Skills::Registry.call(
        "registrar_compra",
        user: @user,
        business: @business,
        input: draft,
        idempotency_key: skill_key("registrar_compra")
      )
      @session.clear

      unless result.success?
        reply("No pude registrar la compra: #{result.errors.join(', ')}")
        return
      end

      data = result.data
      stock_msg = data[:current_quantity] ? " Stock #{data[:product_name]}: #{data[:current_quantity]}#{data[:unit_measure]}" : ""
      reply("✅ #{data[:reference_number]} registrada.#{stock_msg}")
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
  end
end
