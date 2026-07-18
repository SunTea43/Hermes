module WhatsappBot
  class Sender
    def self.deliver(to_phone, message, business_id: nil)
      deliver_message(
        Messages::OutboundMessage.new(
          to: to_phone,
          body: message,
          business_id: business_id
        )
      )
    end

    def self.deliver_message(outbound_message)
      Providers::Resolver.for_outbound(
        to_phone: outbound_message.to,
        business_id: outbound_message.business_id
      ).deliver(outbound_message)
    end
  end
end
