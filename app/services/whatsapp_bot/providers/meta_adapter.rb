require "net/http"
require "openssl"
require "json"
require "tempfile"

module WhatsappBot
  module Providers
    class MetaAdapter < Base
      GRAPH_API_VERSION = "v21.0"

      def name
        :meta
      end

      # Meta sends GET hub.* challenge during webhook subscription.
      # Returns the challenge string when valid, otherwise nil.
      def verify_subscription(request)
        params = request.params
        mode = params["hub.mode"].presence || params[:hub]&.dig(:mode)
        token = params["hub.verify_token"].presence || params[:hub]&.dig(:verify_token)
        challenge = params["hub.challenge"].presence || params[:hub]&.dig(:challenge)

        return nil unless mode == "subscribe"
        return nil if challenge.blank?

        expected_token = ENV.fetch("META_WHATSAPP_VERIFY_TOKEN")
        provided_token = token.to_s
        return nil if provided_token.blank? || provided_token.bytesize != expected_token.bytesize
        return nil unless ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)

        challenge.to_s
      end

      def parse_inbound(request)
        payload = payload_from(request)
        value = payload.dig("entry", 0, "changes", 0, "value") || {}
        message = Array(value["messages"]).first
        return nil if message.blank?

        Messages::InboundMessage.new(
          provider: name,
          provider_message_id: message["id"],
          from: message["from"],
          to: value.dig("metadata", "display_phone_number"),
          body: body_from(message),
          media: media_from(message),
          received_at: received_at_from(message),
          raw_payload: payload
        )
      end

      def valid_signature?(request)
        return true unless WhatsappBot::Config.validate_signatures?

        signature = request.headers["X-Hub-Signature-256"].to_s
        return false if signature.blank?

        digest = OpenSSL::HMAC.hexdigest(
          "SHA256",
          ENV.fetch("META_WHATSAPP_APP_SECRET"),
          request.raw_post.to_s
        )
        expected = "sha256=#{digest}"

        ActiveSupport::SecurityUtils.secure_compare(expected, signature)
      end

      def deliver(outbound_message)
        uri = URI("#{graph_base_url}/#{phone_number_id}/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{access_token}"
        request["Content-Type"] = "application/json"
        request.body = {
          messaging_product: "whatsapp",
          to: outbound_destination(outbound_message.to),
          type: "text",
          text: { preview_url: false, body: outbound_message.body }
        }.to_json

        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise "Meta WhatsApp deliver failed (#{response.code}): #{response.body}"
        end

        JSON.parse(response.body)
      end

      def download_media(media_ref)
        ref = Media::Normalize.call(media_ref)
        raise "Meta media id missing" if ref[:id].blank?

        meta = get_json("#{graph_base_url}/#{ref[:id]}", headers: auth_headers)
        download_url = meta["url"].presence
        raise "Meta media URL missing for #{ref[:id]}" if download_url.blank?

        download_to_tempfile(download_url, mime_type: ref[:mime_type] || meta["mime_type"])
      end

      private

      def graph_base_url
        "https://graph.facebook.com/#{GRAPH_API_VERSION}"
      end

      def phone_number_id
        ENV.fetch("META_WHATSAPP_PHONE_NUMBER_ID")
      end

      def access_token
        ENV.fetch("META_WHATSAPP_ACCESS_TOKEN")
      end

      def outbound_destination(phone)
        Messages::InboundMessage.normalize_phone(phone).delete_prefix("+")
      end

      def payload_from(request)
        raw = request.respond_to?(:raw_post) ? request.raw_post : nil
        if raw.present?
          JSON.parse(raw)
        else
          params = request.params
          hash = if params.respond_to?(:to_unsafe_h)
            params.to_unsafe_h
          else
            params.to_h
          end
          hash.deep_stringify_keys
        end
      rescue JSON::ParserError
        {}
      end

      def body_from(message)
        case message["type"]
        when "text"
          message.dig("text", "body").to_s
        when "button"
          message.dig("button", "text").to_s
        when "interactive"
          message.dig("interactive", "button_reply", "title").presence ||
            message.dig("interactive", "list_reply", "title").to_s
        when "image", "document", "video", "audio"
          message.dig(message["type"], "caption").to_s
        else
          ""
        end
      end

      def media_from(message)
        type = message["type"]
        return nil unless %w[image document video audio].include?(type)

        media = message[type] || {}
        [
          Media::Normalize.call(
            {
              kind: type,
              id: media["id"],
              mime_type: media["mime_type"],
              caption: media["caption"]
            },
            message_type: type
          )
        ]
      end

      def received_at_from(message)
        timestamp = message["timestamp"].to_i
        timestamp.positive? ? Time.zone.at(timestamp) : Time.current
      end

      def auth_headers
        { "Authorization" => "Bearer #{access_token}" }
      end

      def get_json(url, headers: {})
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| request[key] = value }
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise "Meta WhatsApp media metadata failed (#{response.code}): #{response.body}"
        end

        JSON.parse(response.body)
      end

      def download_to_tempfile(url, mime_type: nil)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        auth_headers.each { |key, value| request[key] = value }
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise "Meta WhatsApp media download failed (#{response.code}): #{response.body}"
        end

        ext = extension_for(mime_type)
        tempfile = Tempfile.new([ "whatsapp-media", ext ])
        tempfile.binmode
        tempfile.write(response.body)
        tempfile.rewind
        tempfile
      end

      def extension_for(mime_type)
        case mime_type.to_s
        when "audio/ogg", "audio/opus" then ".ogg"
        when "audio/mpeg" then ".mp3"
        when "audio/mp4", "audio/aac" then ".m4a"
        when "image/jpeg" then ".jpg"
        when "image/png" then ".png"
        when "image/webp" then ".webp"
        else ".bin"
        end
      end
    end
  end
end
