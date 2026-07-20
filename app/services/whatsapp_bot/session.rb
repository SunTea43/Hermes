module WhatsappBot
  class Session
    TTL = 10.minutes

    def initialize(user, business: nil)
      @key = "whatsapp_session:#{user.id}"
      @business = business
    end

    def get
      Rails.cache.read(@key)
    end

    def set(data = nil, **kwargs)
      payload = (data.nil? ? kwargs : data).to_h.symbolize_keys
      payload = payload.merge(business_id: @business.id) if @business
      Rails.cache.write(@key, payload, expires_in: TTL)
    end

    def clear
      Rails.cache.delete(@key)
    end
  end
end
