require "net/http"
require "json"
require "uri"

module WhatsappBot
  module Llm
    class OpenAiClient < Client
      def initialize(
        api_key: ENV["OPENAI_API_KEY"],
        model: WhatsappBot::Config.agent_model,
        base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"),
        temperature: WhatsappBot::Config.agent_temperature
      )
        @api_key = api_key
        @model = model
        @base_url = base_url
        @temperature = temperature
      end

      def complete(system_prompt:, user_prompt:, response_schema: nil)
        raise "OPENAI_API_KEY is missing" if @api_key.blank?

        body = {
          model: @model,
          temperature: @temperature,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ]
        }

        if response_schema
          body[:response_format] = {
            type: "json_schema",
            json_schema: {
              name: "whatsapp_interpretation",
              schema: response_schema,
              strict: true
            }
          }
        else
          body[:response_format] = { type: "json_object" }
        end

        response = post_json("#{@base_url}/chat/completions", body)
        response.dig("choices", 0, "message", "content").to_s
      end

      private

      def post_json(url, body)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)

        raw = http.request(request)
        raise "LLM HTTP #{raw.code}: #{raw.body}" unless raw.is_a?(Net::HTTPSuccess)

        JSON.parse(raw.body)
      end
    end
  end
end
