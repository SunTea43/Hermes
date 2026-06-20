module WhatsappBot
  class Session
    TTL = 10.minutes

    def initialize(user)
      @key = "whatsapp_session:#{user.id}"
    end

    def get
      Rails.cache.read(@key)
    end

    def set(data)
      Rails.cache.write(@key, data, expires_in: TTL)
    end

    def clear
      Rails.cache.delete(@key)
    end
  end
end
