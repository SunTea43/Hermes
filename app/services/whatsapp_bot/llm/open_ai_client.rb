require "net/http"
require "json"
require "uri"

module WhatsappBot
  module Llm
    # OpenAI-compatible chat client (/chat/completions).
    # Works with OpenAI, Groq, and other compatible providers via Config.agent_llm_*.
    class OpenAiClient < Client
      def initialize(
        api_key: WhatsappBot::Config.agent_llm_api_key,
        api_key_env: WhatsappBot::Config.agent_llm_api_key_env,
        model: WhatsappBot::Config.agent_model,
        base_url: WhatsappBot::Config.agent_llm_base_url,
        temperature: WhatsappBot::Config.agent_temperature,
        response_format: WhatsappBot::Config.agent_llm_response_format
      )
        @api_key = api_key
        @api_key_env = api_key_env
        @model = model
        @base_url = base_url.to_s.delete_suffix("/")
        @temperature = temperature
        @response_format = response_format.to_sym
      end

      def complete(system_prompt:, user_prompt:, response_schema: nil)
        raise "#{@api_key_env} is missing" if @api_key.blank?

        body = {
          model: @model,
          temperature: @temperature,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ],
          response_format: build_response_format(response_schema)
        }

        response = post_json("#{@base_url}/chat/completions", body)
        response.dig("choices", 0, "message", "content").to_s
      end

      private

      def build_response_format(response_schema)
        use_schema = response_schema.present? && @response_format == :json_schema

        if use_schema
          {
            type: "json_schema",
            json_schema: {
              name: "whatsapp_interpretation",
              schema: response_schema,
              strict: true
            }
          }
        else
          { type: "json_object" }
        end
      end

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
