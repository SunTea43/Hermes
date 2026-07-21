module WhatsappBot
  class PurchaseHandler < BaseHandler
    DONE_PATTERN = /\A(listo|ya|continuar|eso es todo|terminar|fin)\z/i

    def call
      case @state[:step]
      when :collecting_items
        handle_collecting_items
      when :awaiting_confirmation
        handle_confirmation_step
      else
        handle_initial_message
      end
    end

    private

    def handle_initial_message
      supplier = entity_value("supplier_name").presence || parse_supplier(@message)
      items = resolve_line_items(initial_line_specs)

      if items.empty?
        reply(ResponseRenderer.purchase_parse_error)
        return
      end

      draft = {
        supplier_name: supplier.presence || "Proveedor",
        items: items
      }

      @session.set(intent: :purchase, step: :collecting_items, draft: draft)
      reply(ResponseRenderer.purchase_cart(items: draft[:items], supplier_name: draft[:supplier_name]))
    end

    def handle_collecting_items
      draft = @state[:draft]

      if DONE_PATTERN.match?(@message.strip) || affirmative?
        @session.set(intent: :purchase, step: :awaiting_confirmation, draft: draft)
        reply(ResponseRenderer.purchase_confirm(
          supplier_name: draft[:supplier_name],
          items: draft[:items]
        ))
        return
      end

      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:purchase))
        return
      end

      added = resolve_line_items(parse_purchase_line_specs(@message))
      if added.empty?
        reply(ResponseRenderer.purchase_parse_error)
        return
      end

      draft[:items] = merge_items(draft[:items], added)
      @session.set(intent: :purchase, step: :collecting_items, draft: draft)
      reply(ResponseRenderer.purchase_cart(items: draft[:items], supplier_name: draft[:supplier_name]))
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
        input: {
          supplier_name: draft[:supplier_name],
          items: draft[:items]
        },
        idempotency_key: skill_key("registrar_compra")
      )
      @session.clear

      unless result.success?
        reply(ResponseRenderer.skill_error("registrar la compra", result.errors))
        return
      end

      reply(ResponseRenderer.purchase_recorded(
        reference_number: result.data[:reference_number],
        items: result.data[:items],
        total: result.data[:total]
      ))
    end

    def initial_line_specs
      entity_items = Array(entity_value("items")).presence
      return entity_items.map { |item| item.to_h.with_indifferent_access } if entity_items

      if entity_value("product_name").present?
        return [ {
          "product_name" => entity_value("product_name"),
          "quantity" => entity_value("quantity"),
          "unit_price" => entity_value("unit_price")
        } ]
      end

      parse_purchase_line_specs(@message)
    end

    def parse_purchase_line_specs(message)
      text = message.to_s
      if (match = text.match(/(?:de\s+)?([\w\s]+?):\s*(.+)\z/i))
        text = match[2]
      end

      text = text.sub(/\A\s*(recib[ií]|compra|compré|compre)\b[:\s]*/i, "")
      segments = text.split(/\s+y\s+|,\s*/i).map(&:strip).reject(&:blank?)
      segments.filter_map { |segment| parse_purchase_segment(segment) }
    end

    def parse_purchase_segment(segment)
      match = segment.match(/([\w\s]+?)\s+(\d+(?:[.,]\d+)?)\s*\w*\s+a\s+\$?([\d.,]+)/i) ||
        segment.match(/(\d+(?:[.,]\d+)?)\s*(\w+)?\s+(?:de\s+)?(.+?)\s+a\s+\$?([\d.,]+)/i)

      return nil unless match

      if match.captures.size == 3
        product_raw, qty_str, price_str = match.captures
        {
          "product_name" => product_raw.strip,
          "quantity" => qty_str.tr(",", ".").to_f,
          "unit_price" => price_str.tr(",", ".").to_f
        }
      else
        qty_str, _unit, product_raw, price_str = match.captures
        {
          "product_name" => product_raw.strip,
          "quantity" => qty_str.tr(",", ".").to_f,
          "unit_price" => price_str.tr(",", ".").to_f
        }
      end
    end

    def parse_supplier(message)
      match = message.to_s.match(/(?:de\s+)([\w\s]+?):/i)
      match&.captures&.first&.strip
    end

    def resolve_line_items(specs)
      Array(specs).filter_map { |spec| build_draft_item(spec) }
    end

    def build_draft_item(spec)
      data = spec.to_h.with_indifferent_access
      product = find_product(data[:product_name].to_s)
      return nil unless product

      quantity = data[:quantity].to_d
      unit_price = data[:unit_price].to_d
      return nil unless quantity.positive? && unit_price.positive?

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

    def find_product(name)
      return nil if name.blank?

      @business.products.active.where("lower(name) LIKE ?", "%#{name.downcase}%").first
    end
  end
end
