module WhatsappBot
  module Prompts
    class Definition
      attr_reader :version, :instructions, :examples, :schema, :retry_user_template

      def initialize(version:, instructions:, examples:, schema:, retry_user_template:)
        @version = version
        @instructions = instructions.to_s.strip
        @examples = Array(examples)
        @schema = schema.deep_symbolize_keys
        @retry_user_template = retry_user_template.to_s.strip
      end

      def system
        @system ||= build_system
      end

      def retry_user_prompt(message)
        format(retry_user_template, message: message)
      end

      private

      def build_system
        return instructions if examples.empty?

        example_block = examples.map { |example|
          data = example.with_indifferent_access
          json = data[:json].is_a?(String) ? data[:json] : data[:json].to_json
          %(Usuario: "#{data[:user]}"\nJSON: #{json})
        }.join("\n\n")

        "#{instructions}\n\nEjemplos:\n#{example_block}"
      end
    end
  end
end
