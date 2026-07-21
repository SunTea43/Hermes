module WhatsappBot
  class SaleHandler < BaseHandler
    DONE_PATTERN = /\A(listo|ya|continuar|eso es todo|terminar|fin)\z/i

    def call
      case @state[:step]
      when :collecting_items
        handle_collecting_items
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
      items = resolve_line_items(initial_line_specs)
      if items.empty?
        reply(ResponseRenderer.sale_parse_error)
        return
      end

      draft = {
        items: items,
        customer_name: entity_value("customer_name"),
        payment_condition: normalize_payment_condition(entity_value("payment_condition"))
      }

      if draft[:customer_name].present? && draft[:payment_condition].present?
        @session.set(intent: :sale, step: :awaiting_confirmation, draft: draft)
        reply(confirm_message(draft))
        return
      end

      if draft[:customer_name].present?
        @session.set(intent: :sale, step: :awaiting_payment_condition, draft: draft)
        reply(ResponseRenderer.sale_ask_payment_condition(customer_name: draft[:customer_name]))
        return
      end

      @session.set(intent: :sale, step: :collecting_items, draft: draft)
      reply(ResponseRenderer.sale_cart(items: draft[:items]))
    end

    def handle_collecting_items
      draft = @state[:draft]

      if DONE_PATTERN.match?(@message.strip)
        if draft[:items].blank?
          reply(ResponseRenderer.sale_parse_error)
          return
        end

        @session.set(intent: :sale, step: :awaiting_customer, draft: draft)
        reply(ResponseRenderer.sale_ask_customer(items: draft[:items]))
        return
      end

      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:sale))
        return
      end

      added = resolve_line_items(parse_sale_line_specs(@message))
      if added.empty?
        reply(ResponseRenderer.sale_parse_error)
        return
      end

      draft[:items] = merge_items(draft[:items], added)
      @session.set(intent: :sale, step: :collecting_items, draft: draft)
      reply(ResponseRenderer.sale_cart(items: draft[:items]))
    end

    def handle_customer_step
      draft = @state[:draft]
      draft[:customer_name] = @message.strip.presence || "venta general"
      @session.set(intent: :sale, step: :awaiting_payment_condition, draft: draft)
      reply(ResponseRenderer.sale_ask_payment_condition(customer_name: draft[:customer_name]))
    end

    def handle_payment_condition_step
      draft = @state[:draft]
      condition = normalize_payment_condition(@message)
      unless condition
        reply(ResponseRenderer.ask_cash_or_credit)
        return
      end

      draft[:payment_condition] = condition
      @session.set(intent: :sale, step: :awaiting_confirmation, draft: draft)
      reply(confirm_message(draft))
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
        input: {
          customer_name: draft[:customer_name],
          payment_condition: draft[:payment_condition],
          items: draft[:items]
        },
        idempotency_key: skill_key("registrar_venta")
      )
      @session.clear

      unless result.success?
        reply(ResponseRenderer.skill_error("registrar la venta", result.errors))
        return
      end

      reply(ResponseRenderer.sale_recorded(
        reference_number: result.data[:reference_number],
        items: result.data[:items],
        total: result.data[:total]
      ))
    end

    def confirm_message(draft)
      ResponseRenderer.sale_confirm(
        customer_name: draft[:customer_name],
        items: draft[:items],
        payment_condition: draft[:payment_condition],
        total: draft[:items].sum { |item| item[:quantity].to_d * item[:unit_price].to_d }
      )
    end

    def initial_line_specs
      entity_items = Array(entity_value("items")).presence
      return entity_items.map { |item| item.to_h.with_indifferent_access } if entity_items

      if entity_value("product_name").present?
        return [ {
          "product_name" => entity_value("product_name"),
          "quantity" => entity_value("quantity"),
          "unit" => entity_value("unit")
        } ]
      end

      parse_sale_line_specs(@message)
    end

    def parse_sale_line_specs(message)
      text = message.to_s.sub(/\A\s*(vend[ií]|venta|fiado|crédito|credito)\b[:\s]*/i, "")
      segments = text.split(/\s+y\s+|,\s*/i).map(&:strip).reject(&:blank?)
      segments.filter_map { |segment| parse_sale_segment(segment) }
    end

    def parse_sale_segment(segment)
      match = segment.match(/(\d+(?:[.,]\d+)?)\s*(\w+)?\s+(?:de\s+)?(.+)/i)
      return nil unless match

      qty_str, unit, product_raw = match.captures
      {
        "quantity" => qty_str.tr(",", ".").to_f,
        "unit" => unit,
        "product_name" => product_raw.strip
      }
    end

    def resolve_line_items(specs)
      Array(specs).filter_map { |spec| build_draft_item(spec) }
    end

    def build_draft_item(spec)
      data = spec.to_h.with_indifferent_access
      product = find_product(data[:product_name].to_s)
      return nil unless product

      quantity = data[:quantity].to_d
      return nil unless quantity.positive?

      price = product.product_prices.where(price_type: "sale").order(start_at: :desc).first
      unit_price = data[:unit_price].presence&.to_d || price&.unit_price || 0

      {
        product_id: product.id,
        product_name: product.name,
        quantity: quantity,
        unit_price: unit_price,
        unit_measure: product.unit_measure,
        line_total: quantity * unit_price
      }
    end

    def merge_items(existing, added)
      merged = Array(existing).map { |item| item.to_h.with_indifferent_access }
      added.each do |item|
        item = item.to_h.with_indifferent_access
        current = merged.find { |row| row[:product_id] == item[:product_id] }
        if current
          current[:quantity] = current[:quantity].to_d + item[:quantity].to_d
          current[:line_total] = current[:quantity].to_d * current[:unit_price].to_d
        else
          merged << item
        end
      end
      merged
    end

    def normalize_payment_condition(value)
      text = value.to_s.strip.downcase
      return "credit" if text.match?(/cr[eé]dito|credit|fiado/)
      return "cash" if text.match?(/contado|cash|efectivo/)

      nil
    end

    def find_product(name)
      return nil if name.blank?

      @business.products.active.where("lower(name) LIKE ?", "%#{name.downcase}%").first
    end
  end
end
