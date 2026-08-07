require "net/http"
require "uri"
require "json"
require "base64"

module WhatsappBot
  module Media
    class OpenAiVisionClient
      def initialize(
        api_key: ENV["OPENAI_API_KEY"],
        model: WhatsappBot::Config.media_vision_model,
        base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"),
        temperature: WhatsappBot::Config.agent_temperature
      )
        @api_key = api_key
        @model = model
        @base_url = base_url
        @temperature = temperature
      end

      def interpret(file_path:, mime_type:, caption: nil, catalog_names: [])
        raise "OPENAI_API_KEY is missing" if @api_key.blank?

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
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "whatsapp_interpretation",
              schema: prompt::SCHEMA,
              strict: true
            }
          }
        }

        response = post_json("#{@base_url}/chat/completions", body)
        content = response.dig("choices", 0, "message", "content").to_s
        data = JSON.parse(content)
        raise "missing intent" if data["intent"].blank?

        Interpretation.new(
          intent: data["intent"],
          entities: data["entities"] || {},
          confidence: data["confidence"] || 0.0,
          raw: data.merge("source" => "image")
        )
      end

      private

      def build_user_prompt(caption:, catalog_names:)
        parts = [
          "Interpreta la imagen como un mensaje operativo de tienda (compra o venta).",
          "Usa el mismo JSON de intenciones/entidades del intérprete de texto.",
          "Si hay texto ilegible, baja la confidence o usa intent=clarify."
        ]
        parts << "Caption del usuario: #{caption}" if caption.present?
        if catalog_names.present?
          parts << "Catálogo de productos de la tienda (usa estos nombres cuando matcheen):"
          parts << catalog_names.first(80).join(", ")
        end
        parts.join("\n")
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
