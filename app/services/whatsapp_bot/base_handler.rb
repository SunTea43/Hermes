module WhatsappBot
  class BaseHandler
    def initialize(user, message, session, state = {}, business: nil, idempotency_key: nil)
      @user = user
      @message = message
      @session = session
      @state = state
      @business = business
      @idempotency_key = idempotency_key
    end

    def call
      raise NotImplementedError
    end

    private

    def reply(text)
      Sender.deliver(@user.whatsapp_phone, text, business_id: @business&.id)
    end

    def skill_key(skill_name)
      return nil if @idempotency_key.blank?

      "#{@idempotency_key}:#{skill_name}"
    end

    def affirmative?
      @message.strip.match?(/\A(sí|si|yes|ok|confirmo|dale|va|correcto|claro)\z/i)
    end

    def negative?
      @message.strip.match?(/\A(no|cancelar|cancel|nope)\z/i)
    end
  end
end
