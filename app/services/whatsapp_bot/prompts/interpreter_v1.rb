module WhatsappBot
  module Prompts
    # Facade over config/whatsapp_prompts/interpreter_v1.yml
    # Exposes VERSION / SYSTEM / SCHEMA as constants via const_missing so
    # callers can keep using Prompts::InterpreterV1::SYSTEM after YAML edits + Catalog.reload!
    module InterpreterV1
      class << self
        def definition
          Catalog.interpreter("interpreter_v1")
        end

        def retry_user_prompt(message)
          definition.retry_user_prompt(message)
        end

        def const_missing(name)
          case name
          when :VERSION then definition.version
          when :SYSTEM then definition.system
          when :SCHEMA then definition.schema
          else super
          end
        end
      end
    end
  end
end
