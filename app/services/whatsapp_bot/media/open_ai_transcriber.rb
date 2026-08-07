require "net/http"
require "uri"
require "json"
require "securerandom"

module WhatsappBot
  module Media
    class OpenAiTranscriber
      def initialize(
        api_key: ENV["OPENAI_API_KEY"],
        model: WhatsappBot::Config.media_whisper_model,
        base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1")
      )
        @api_key = api_key
        @model = model
        @base_url = base_url
      end

      def transcribe(file_path, mime_type: nil)
        raise "OPENAI_API_KEY is missing" if @api_key.blank?

        uri = URI("#{@base_url}/audio/transcriptions")
        file_name = File.basename(file_path.to_s)
        file_name = "#{file_name}.ogg" if File.extname(file_name).blank?

        boundary = "----HermesBoundary#{SecureRandom.hex(8)}"
        body = multipart_body(
          boundary: boundary,
          file_path: file_path,
          file_name: file_name,
          mime_type: mime_type.presence || "audio/ogg",
          model: @model
        )

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 15
        http.read_timeout = 60

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
        request.body = body

        raw = http.request(request)
        raise "STT HTTP #{raw.code}: #{raw.body}" unless raw.is_a?(Net::HTTPSuccess)

        JSON.parse(raw.body).fetch("text").to_s.strip
      end

      private

      def multipart_body(boundary:, file_path:, file_name:, mime_type:, model:)
        file_data = File.binread(file_path)
        [
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"model\"\r\n\r\n",
          "#{model}\r\n",
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"language\"\r\n\r\n",
          "es\r\n",
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"file\"; filename=\"#{file_name}\"\r\n",
          "Content-Type: #{mime_type}\r\n\r\n",
          file_data,
          "\r\n--#{boundary}--\r\n"
        ].join
      end
    end
  end
end
