module WhatsappBot
  class BusinessResolver
    Result = Data.define(:business, :error) do
      def ok?
        error.nil? && business.present?
      end
    end

    def self.call(user, session_business_id: nil)
      new(user, session_business_id: session_business_id).call
    end

    def initialize(user, session_business_id: nil)
      @user = user
      @session_business_id = session_business_id
    end

    def call
      authorized = authorized_businesses
      return Result.new(business: nil, error: :not_authorized) if authorized.empty?

      if @session_business_id.present?
        business = authorized.find { |item| item.id == @session_business_id.to_i }
        return Result.new(business: business, error: business ? nil : :not_authorized)
      end

      if @user.default_whatsapp_business_id.present?
        business = authorized.find { |item| item.id == @user.default_whatsapp_business_id }
        return Result.new(business: business, error: nil) if business
      end

      return Result.new(business: authorized.first, error: nil) if authorized.one?

      Result.new(business: nil, error: :ambiguous)
    end

    private

    def authorized_businesses
      return Business.none unless @user.status == "active"

      @user.authorized_whatsapp_businesses
           .where(id: @user.accessible_businesses.select(:id))
           .whatsapp_enabled
           .distinct
    end
  end
end
