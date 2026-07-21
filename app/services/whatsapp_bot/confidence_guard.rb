module WhatsappBot
  class ConfidenceGuard
    def self.call(interpretation, threshold: WhatsappBot::Config.agent_confidence_threshold)
      new(threshold: threshold).call(interpretation)
    end

    def initialize(threshold:)
      @threshold = threshold.to_f
    end

    def call(interpretation)
      return interpretation if interpretation.intent == :clarify
      return interpretation if interpretation.intent == :unknown
      return interpretation if interpretation.confidence >= @threshold

      Interpretation.new(
        intent: :clarify,
        entities: interpretation.entities,
        confidence: interpretation.confidence,
        raw: interpretation.raw.merge("guard" => "low_confidence")
      )
    end
  end
end
