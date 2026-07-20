module WhatsappBot
  module Providers
    class TwilioAdapter < Base
      def name
        :twilio
      end

      def parse_inbound(request)
        params = request.params

        Messages::InboundMessage.new(
          provider: name,
          provider_message_id: params[:MessageSid].presence || params["MessageSid"],
          from: params[:From].presence || params["From"],
          to: params[:To].presence || params["To"],
          body: params[:Body].presence || params["Body"],
          media: media_from(params),
          received_at: Time.current,
          raw_payload: params.to_unsafe_h.slice(
            "MessageSid", "AccountSid", "From", "To", "Body",
            "NumMedia", "SmsStatus", "WaId"
          )
        )
      end

      def valid_signature?(request)
        return true unless WhatsappBot::Config.validate_signatures?

        auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")
        signature = request.headers["X-Twilio-Signature"].to_s
        return false if signature.blank?

        validator = ::Twilio::Security::RequestValidator.new(auth_token)
        validator.validate(request.original_url, request.request_parameters, signature)
      end

      def deliver(outbound_message)
        client.messages.create(
          from: ENV.fetch("TWILIO_WHATSAPP_NUMBER"),
          to: "whatsapp:#{outbound_message.to}",
          body: outbound_message.body
        )
      end

      private

      def client
        ::Twilio::REST::Client.new(
          ENV.fetch("TWILIO_ACCOUNT_SID"),
          ENV.fetch("TWILIO_AUTH_TOKEN")
        )
      end

      def media_from(params)
        count = params[:NumMedia].to_i
        return nil if count <= 0

        Array.new(count) do |index|
          {
            url: params["MediaUrl#{index}"],
            content_type: params["MediaContentType#{index}"]
          }.compact
        end
      end
    end
  end
end
