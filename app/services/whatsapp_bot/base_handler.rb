module WhatsappBot
  class BaseHandler
    def initialize(user, message, session, state = {})
      @user    = user
      @message = message
      @session = session
      @state   = state
      @business = user.owned_businesses.first
    end

    def call
      raise NotImplementedError
    end

    private

    def reply(text)
      Sender.send(@user.whatsapp_phone, text)
    end

    def affirmative?
      @message.strip.match?(/\A(sí|si|yes|ok|confirmo|dale|va|correcto|claro)\z/i)
    end

    def negative?
      @message.strip.match?(/\A(no|cancelar|cancel|nope)\z/i)
    end
  end
end
