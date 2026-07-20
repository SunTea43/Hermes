module WhatsappBot
  class AuthorizationGateway
    class NotAuthorized < StandardError; end

    class << self
      def authorize!(user:, business:, skill: nil)
        raise NotAuthorized, "business required" if business.blank?
        raise NotAuthorized, "user inactive" unless user.status == "active"
        raise NotAuthorized, "whatsapp disabled for business" unless business.whatsapp_enabled?
        raise NotAuthorized, "user cannot access business" unless user.can_access_business?(business)
        raise NotAuthorized, "user not authorized for whatsapp" unless user.whatsapp_authorized_for?(business)

        SkillAuthorization.authorize!(user: user, business: business, skill: skill) if skill
        true
      rescue SkillAuthorization::NotAuthorized => e
        raise NotAuthorized, e.message
      end

      def authorize(user:, business:, skill: nil)
        authorize!(user: user, business: business, skill: skill)
        true
      rescue NotAuthorized
        false
      end
    end
  end
end
