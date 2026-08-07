require "net/http"
require "uri"
require "json"
require "base64"

module WhatsappBot
  module Media
    class OpenAiVisionClient
      def initialize(
        api_key: WhatsappBot::Config.media_vision_api_key,
        model: WhatsappBot::Config.media_vision_model,
        base_url: WhatsappBot::Config.media_vision_base_url,
        temperature: WhatsappBot::Config.agent_temperature,
        response_format: WhatsappBot::Config.media_vision_response_format
      )
        @api_key = api_key
        @model = model
        @base_url = base_url
        @temperature = temperature
        @response_format = response_format.to_sym
      end

      def interpret(file_path:, mime_type:, caption: nil, catalog_names: [])
        raise "#{WhatsappBot::Config.media_vision_api_key_env} is missing" if @api_key.blank?

        prompt = Prompts::InterpreterV1
        user_prompt = build_user_prompt(caption: caption, catalog_names: catalog_names)
        image_data = Base64.strict_encode64(File.binread(file_path))
        data_url = "data:#{mime_type.presence || "image/jpeg"};base64,#{image_data}"

        body = {
          model: @model,
          temperature: @temperature,
          messages: [
            { role: "system", content: prompt::SYSTEM },
            {
              role: "user",
              content: [
                { type: "text", text: user_prompt },
                { type: "image_url", image_url: { url: data_url } }
              ]
            }
          ],
          response_format: build_response_format(prompt::SCHEMA)
        }

        response = post_json("#{@base_url}/chat/completions", body)
        content = response.dig("choices", 0, "message", "content").to_s
        data = parse_json_content(content)
        raise "missing intent" if data["intent"].blank?

        Interpretation.new(
          intent: data["intent"],
          entities: data["entities"] || {},
          confidence: data["confidence"] || 0.0,
          raw: data.merge("source" => "image")
        )
      end

      private

      def build_response_format(schema)
        if @response_format == :json_schema
          {
            type: "json_schema",
            json_schema: {
              name: "whatsapp_interpretation",
              schema: schema,
              strict: true
            }
          }
        else
          { type: "json_object" }
        end
      end

      def build_user_prompt(caption:, catalog_names:)
        parts = [
          "Tu trabajo es leer la foto de una nota/lista/factura de tienda y extraer productos,",
          "cantidades, unidades y precios (si se ven). Usa el mismo JSON del intérprete de texto.",
          "Responde SOLO JSON válido con TODAS las claves de entities (null o [] si no aplican).",
          "IMPORTANTE sobre intent:",
          "- Si el caption del usuario deja claro que es compra (compré, recibí, compra) → intent=purchase.",
          "- Si el caption deja claro que es venta (vendí, venta, fiado) → intent=sale.",
          "- Si NO hay caption claro, NO adivines compra vs venta: usa intent=clarify y llena entities.items igual.",
          "Una lista de productos sola casi nunca basta para decidir compra o venta.",
          "Si el texto de la foto es ilegible, baja la confidence."
        ]
        parts << "Caption del usuario: #{caption}" if caption.present?
        if catalog_names.present?
          parts << "Catálogo de productos de la tienda (usa estos nombres cuando matcheen):"
          parts << catalog_names.first(80).join(", ")
        end
        parts.join("\n")
      end

      def parse_json_content(content)
        text = content.to_s.strip
        return JSON.parse(text) if text.start_with?("{")

        # Some providers wrap JSON in markdown fences.
        if (match = text.match(/```(?:json)?\s*(\{.*\})\s*```/m))
          return JSON.parse(match[1])
        end

        if (match = text.match(/(\{.*\})/m))
          return JSON.parse(match[1])
        end

        JSON.parse(text)
      end

      def post_json(url, body)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 15
        http.read_timeout = 90

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)

        raw = http.request(request)
        raise "Vision HTTP #{raw.code}: #{raw.body}" unless raw.is_a?(Net::HTTPSuccess)

        JSON.parse(raw.body)
      end
    end
  end
end
