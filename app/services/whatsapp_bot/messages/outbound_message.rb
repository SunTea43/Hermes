module WhatsappBot
  module Messages
    OutboundMessage = Data.define(
      :to,
      :body,
      :media,
      :business_id
    ) do
      def initialize(to:, body:, media: nil, business_id: nil)
        super(
          to: to.to_s.delete_prefix("whatsapp:").strip,
          body: body.to_s,
          media: media,
          business_id: business_id
        )
      end
    end
  end
end
