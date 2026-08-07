module WhatsappBot
  module Media
    # Resolves compra vs venta for image orders.
    # Default: clarify (ask in chat). Caption can short-circuit to purchase/sale.
    module ImageOrderKind
      SALE_CAPTION = /\b(venta|vend[ií]|fiado|crédito|credito)\b/i
      PURCHASE_CAPTION = /\b(compra|compr[eé]|recib[ií]|proveedor)\b/i

      module_function

      def normalize(interpretation, caption: nil)
        text = caption.to_s
        entities = interpretation.entities
        confidence = interpretation.confidence
        raw = interpretation.raw.to_h.merge("source" => "image")

        if text.match?(SALE_CAPTION)
          return Interpretation.new(intent: :sale, entities: entities, confidence: confidence, raw: raw.merge("order_kind" => "caption_sale"))
        end

        if text.match?(PURCHASE_CAPTION)
          return Interpretation.new(intent: :purchase, entities: entities, confidence: confidence, raw: raw.merge("order_kind" => "caption_purchase"))
        end

        # Without a clear caption, never trust a guessed purchase/sale from the photo alone.
        if %i[sale purchase].include?(interpretation.intent)
          return Interpretation.new(
            intent: :clarify,
            entities: entities,
            confidence: confidence,
            raw: raw.merge("order_kind" => "ask_user", "guard" => "image_kind_ambiguous")
          )
        end

        Interpretation.new(intent: interpretation.intent, entities: entities, confidence: confidence, raw: raw)
      end
    end
  end
end
