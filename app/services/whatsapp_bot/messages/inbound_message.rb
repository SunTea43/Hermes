module WhatsappBot
  module Messages
    InboundMessage = Data.define(
      :provider,
      :provider_message_id,
      :from,
      :to,
      :body,
      :media,
      :received_at,
      :raw_payload
    ) do
      def initialize(provider:, provider_message_id:, from:, to:, body:, media: nil, received_at: Time.current, raw_payload: {})
        super(
          provider: provider.to_sym,
          provider_message_id: provider_message_id.to_s.presence,
          from: self.class.normalize_phone(from),
          to: self.class.normalize_phone(to),
          body: body.to_s.strip,
          media: media,
          received_at: received_at,
          raw_payload: raw_payload
        )
      end

      def self.normalize_phone(value)
        value.to_s.delete_prefix("whatsapp:").strip
      end
    end
  end
end
