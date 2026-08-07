module WhatsappBot
  class BaseHandler
    def initialize(user, message, session, state = {}, business: nil, idempotency_key: nil, entities: {})
      @user = user
      @message = message
      @session = session
      @state = state
      @business = business
      @idempotency_key = idempotency_key
      @entities = entities.to_h.with_indifferent_access
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

    def entity_value(key)
      @entities[key]
    end

    def affirmative?
      @message.strip.match?(/\A(sí|si|yes|ok|confirmo|dale|va|correcto|claro)\z/i)
    end

    def negative?
      @message.strip.match?(/\A(no|cancelar|cancel|nope)\z/i)
    end

    # Runs a write skill and always clears the draft session afterwards.
    # On failure or exception, notifies the user that the operation was cancelled.
    def run_mutating_skill(action_label)
      result = yield
      unless result.success?
        reply(ResponseRenderer.skill_error(action_label, result.errors, cancelled: true))
        return nil
      end
      result
    rescue StandardError => e
      Rails.logger.error("[WhatsappBot] #{action_label} failed: #{e.class}: #{e.message}")
      reply(ResponseRenderer.skill_error(action_label, [ "error interno" ], cancelled: true))
      nil
    ensure
      @session.clear
    end
  end
end
