module WhatsappBot
  class Sender
    def self.deliver(to_phone, message)
      client = Twilio::REST::Client.new(
        ENV.fetch("TWILIO_ACCOUNT_SID"),
        ENV.fetch("TWILIO_AUTH_TOKEN")
      )
      client.messages.create(
        from: ENV.fetch("TWILIO_WHATSAPP_NUMBER"),
        to:   "whatsapp:#{to_phone}",
        body: message
      )
    end
  end
end
