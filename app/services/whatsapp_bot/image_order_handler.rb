module WhatsappBot
  # After vision extracts line items from a photo, ask whether it is a purchase or a sale.
  # Confirmations and missing fields continue in SaleHandler / PurchaseHandler via chat.
  class ImageOrderHandler < BaseHandler
    SALE_KIND = /\A(venta|vend[ií]|sale)\b/i
    PURCHASE_KIND = /\A(compra|compr[eé]|recib[ií]|purchase)\b/i

    def call
      case state_hash[:step]
      when :awaiting_order_kind
        handle_kind_reply
      else
        start_kind_prompt
      end
    end

    private

    def start_kind_prompt
      entities = normalized_entities
      unless entities_have_items?(entities)
        reply(ResponseRenderer.image_order_empty)
        return
      end

      @session.set(intent: :media_order, step: :awaiting_order_kind, draft: { entities: entities })
      reply(ResponseRenderer.image_order_ask_kind(items: entities["items"]))
    end

    def state_hash
      (@state || {}).to_h.with_indifferent_access
    end

    def handle_kind_reply
      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:media_order))
        return
      end

      entities = (state_hash.dig(:draft, :entities) || {}).with_indifferent_access
      text = @message.to_s.strip

      if text.match?(PURCHASE_KIND)
        hand_off(PurchaseHandler, entities)
      elsif text.match?(SALE_KIND)
        hand_off(SaleHandler, entities)
      else
        reply(ResponseRenderer.image_order_ask_kind(items: entities["items"], repeat: true))
      end
    end

    def hand_off(handler_class, entities)
      @session.clear
      handler_class.new(
        @user,
        @message,
        @session,
        {},
        business: @business,
        idempotency_key: @idempotency_key,
        entities: entities
      ).call
    end

    def normalized_entities
      entities = @entities.to_h.with_indifferent_access
      items = Array(entities[:items]).map { |item| item.to_h.with_indifferent_access }.reject { |item|
        item[:product_name].blank?
      }

      if items.blank? && entities[:product_name].present?
        items = [ {
          "product_name" => entities[:product_name],
          "quantity" => entities[:quantity],
          "unit" => entities[:unit],
          "unit_price" => entities[:unit_price]
        } ]
      end

      entities.merge("items" => items)
    end

    def entities_have_items?(entities)
      Array(entities["items"]).any? { |item| item.to_h.with_indifferent_access[:product_name].present? }
    end
  end
end
