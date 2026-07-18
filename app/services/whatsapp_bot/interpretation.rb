module WhatsappBot
  class Interpretation < Data.define(:intent, :entities, :confidence, :raw)
    INTENTS = %i[
      sale
      purchase
      payment
      inventory_query
      report
      unknown
      clarify
    ].freeze

    def initialize(intent:, entities: {}, confidence: 0.0, raw: {})
      normalized_intent = intent.to_sym
      normalized_intent = :unknown unless INTENTS.include?(normalized_intent)

      super(
        intent: normalized_intent,
        entities: entities.to_h.with_indifferent_access,
        confidence: confidence.to_f,
        raw: raw.to_h
      )
    end

    def known?
      intent != :unknown && intent != :clarify
    end
  end
end
