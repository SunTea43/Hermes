module WhatsappBot
  class AuthorizationGateway
    class NotAuthorized < StandardError; end

    class << self
      def authorize!(user:, business:)
        raise NotAuthorized, "business required" if business.blank?
        raise NotAuthorized, "whatsapp disabled for business" unless business.whatsapp_enabled?
        raise NotAuthorized, "user cannot access business" unless user.can_access_business?(business)

        true
      end

      def authorize(user:, business:)
        authorize!(user: user, business: business)
        true
      rescue NotAuthorized
        false
      end
    end
  end
end
