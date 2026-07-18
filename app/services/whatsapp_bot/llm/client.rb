module WhatsappBot
  module Llm
    class Client
      def complete(system_prompt:, user_prompt:, response_schema: nil)
        raise NotImplementedError
      end
    end
  end
end
