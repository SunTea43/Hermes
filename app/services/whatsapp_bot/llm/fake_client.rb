module WhatsappBot
  module Llm
    # Deterministic client for tests and local fallbacks.
    class FakeClient < Client
      def initialize(responses = {})
        @responses = responses
        @calls = []
      end

      attr_reader :calls

      def complete(system_prompt:, user_prompt:, response_schema: nil)
        @calls << { system_prompt: system_prompt, user_prompt: user_prompt, response_schema: response_schema }
        payload = @responses[user_prompt] || @responses[:default] || {
          "intent" => "unknown",
          "entities" => {},
          "confidence" => 0.0
        }
        payload.is_a?(String) ? payload : JSON.generate(payload)
      end
    end
  end
end
