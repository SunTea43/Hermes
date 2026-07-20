module WhatsappBot
  class SaleHandler < BaseHandler
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
        reply(ResponseRenderer.sale_parse_error)
        return
      end

      product = find_product(parsed[:product_name])
      unless product
        reply(ResponseRenderer.product_not_found(parsed[:product_name]))
        return
      end

      price = product.product_prices.where(price_type: "sale").order(start_at: :desc).first
      unit_price = price&.unit_price || 0

      draft = {
        product_id: product.id,
        product_name: product.name,
        quantity: parsed[:quantity],
        unit_price: unit_price,
        unit_measure: product.unit_measure
      }

      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :sale, step: :awaiting_customer, draft: draft)
      reply(ResponseRenderer.sale_ask_customer(
        quantity: draft[:quantity],
        unit_measure: draft[:unit_measure],
        product_name: draft[:product_name],
        unit_price: draft[:unit_price],
        total: total
      ))
    end

    def handle_customer_step
      draft = @state[:draft]
      draft[:customer_name] = @message.strip
      @session.set(intent: :sale, step: :awaiting_payment_condition, draft: draft)
      reply(ResponseRenderer.sale_ask_payment_condition(customer_name: draft[:customer_name]))
    end

    def handle_payment_condition_step
      draft = @state[:draft]
      condition = @message.strip.downcase

      unless condition.match?(/contado|crédito|credito/)
        reply(ResponseRenderer.ask_cash_or_credit)
        return
      end

      draft[:payment_condition] = condition.match?(/cr/) ? "credit" : "cash"
      total = draft[:quantity] * draft[:unit_price]
      @session.set(intent: :sale, step: :awaiting_confirmation, draft: draft)
      reply(ResponseRenderer.sale_confirm(
        customer_name: draft[:customer_name],
        quantity: draft[:quantity],
        unit_measure: draft[:unit_measure],
        product_name: draft[:product_name],
        total: total,
        payment_condition: draft[:payment_condition]
      ))
    end

    def handle_confirmation_step
      draft = @state[:draft]

      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:sale))
        return
      end

      unless affirmative?
        reply(ResponseRenderer.confirm_yes_no)
        return
      end

      result = Skills::Registry.call(
        "registrar_venta",
        user: @user,
        business: @business,
        input: draft,
        idempotency_key: skill_key("registrar_venta")
      )
      @session.clear

      unless result.success?
        reply(ResponseRenderer.skill_error("registrar la venta", result.errors))
        return
      end

      reply(ResponseRenderer.sale_recorded(**result.data.slice(
        :reference_number, :product_name, :current_quantity, :unit_measure
      ).symbolize_keys))
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
  end
end
