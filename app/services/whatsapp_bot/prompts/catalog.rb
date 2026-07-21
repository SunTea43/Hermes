module WhatsappBot
  module Prompts
    # Loads versioned prompt YAML from config/whatsapp_prompts/*.yml
    class Catalog
      PROMPTS_DIR = Rails.root.join("config/whatsapp_prompts")

      class << self
        def interpreter(version = "interpreter_v1")
          cache[version.to_s] ||= load!(version.to_s)
        end

        def reload!
          @cache = {}
        end

        private

        def cache
          @cache ||= {}
        end

        def load!(version)
          path = PROMPTS_DIR.join("#{version}.yml")
          raise ArgumentError, "Missing WhatsApp prompt file: #{path}" unless path.exist?

          raw = YAML.safe_load(
            ERB.new(path.read).result,
            aliases: true,
            permitted_classes: [ Symbol ]
          ) || {}
          data = raw.with_indifferent_access

          Definition.new(
            version: data.fetch("version", version),
            instructions: data.fetch("instructions"),
            examples: data.fetch("examples", []),
            schema: data.fetch("schema"),
            retry_user_template: data.fetch(
              "retry_user_template",
              "Reintenta. Responde SOLO JSON válido.\nMensaje: %{message}"
            )
          )
        end
      end
    end
  end
end
