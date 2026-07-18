module WhatsappBot
  class Interpreter
    class InvalidInterpretation < StandardError; end

    def self.call(message, client: nil)
      new(client: client).call(message)
    end

    def initialize(client: nil)
      @client = client || default_client
      @prompt = Prompts::InterpreterV1
    end

    def call(message)
      first = safe_interpret(message)
      return first if first && valid?(first)

      second = safe_interpret(message, retrying: true)
      return second if second && valid?(second)

      Interpretation.new(intent: :clarify, confidence: 0.0, raw: { error: "invalid_json" })
    end

    private

    def safe_interpret(message, retrying: false)
      interpret_once(message, retrying: retrying)
    rescue JSON::ParserError, InvalidInterpretation
      nil
    end

    def interpret_once(message, retrying: false)
      user_prompt = retrying ? "Reintentá. Respondé SOLO JSON válido.\nMensaje: #{message}" : message
      content = @client.complete(
        system_prompt: @prompt::SYSTEM,
        user_prompt: user_prompt,
        response_schema: @prompt::SCHEMA
      )
      parse(content)
    end

    def parse(content)
      data = JSON.parse(content)
      raise InvalidInterpretation, "missing intent" if data["intent"].blank?

      Interpretation.new(
        intent: data["intent"],
        entities: data["entities"] || {},
        confidence: data["confidence"] || 0.0,
        raw: data
      )
    end

    def valid?(interpretation)
      Interpretation::INTENTS.include?(interpretation.intent) &&
        interpretation.confidence.between?(0.0, 1.0)
    end

    def default_client
      case WhatsappBot::Config.agent_llm_provider
      when :fake then Llm::FakeClient.new
      else Llm::OpenAiClient.new
      end
    end
  end
end
