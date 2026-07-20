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
        reply('No entendí. Ejemplo: "Recibí de Juanito: arroz 50kg a $2,000".')
        return
      end

      product = find_product(parsed[:product_name])
      unless product
        reply(ResponseRenderer.product_not_found(parsed[:product_name], in_inventory: false))
        return
      end

      draft = {
        product_id: product.id,
        product_name: product.name,
        supplier_name: parsed[:supplier_name],
        quantity: parsed[:quantity],
        unit_price: parsed[:unit_price],
        unit_measure: product.unit_measure
      }

      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :purchase, step: :awaiting_confirmation, draft: draft)
      reply(ResponseRenderer.purchase_confirm(
        supplier_name: draft[:supplier_name],
        product_name: draft[:product_name],
        quantity: draft[:quantity],
        unit_measure: draft[:unit_measure],
        total: total
      ))
    end

    def handle_confirmation_step
      draft = @state[:draft]

      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:purchase))
        return
      end

      unless affirmative?
        reply(ResponseRenderer.confirm_yes_no)
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
        reply(ResponseRenderer.skill_error("registrar la compra", result.errors))
        return
      end

      reply(ResponseRenderer.purchase_recorded(**result.data.slice(
        :reference_number, :product_name, :current_quantity, :unit_measure
      ).symbolize_keys))
    end

    def parse_purchase_message
      match = @message.match(/(?:de\s+)?([\w\s]+?):\s*([\w\s]+?)\s+(\d+(?:[.,]\d+)?)\s*\w*\s+a\s+\$?([\d.,]+)/i)
      return nil unless match

      supplier, product_raw, qty_str, price_str = match.captures
      {
        supplier_name: supplier.strip,
        product_name: product_raw.strip,
        quantity: qty_str.tr(",", ".").to_f,
        unit_price: price_str.tr(",", ".").to_f
      }
    end

    def find_product(name)
      @business.products.active.where("lower(name) LIKE ?", "%#{name.downcase}%").first
    end
  end
end
