module WhatsappBot
  module Providers
    class Resolver
      class UnknownProviderError < StandardError; end

      @adapters = { twilio: TwilioAdapter }

      class << self
        def adapters
          @adapters
        end

        def register(name, adapter_class)
          @adapters[name.to_sym] = adapter_class
        end

        def for_inbound(provider_name = nil)
          build(provider_name.presence || WhatsappBot::Config.default_provider)
        end

        # Resolves the outbound adapter for a destination phone and optional business.
        # Precedence: phone override → business override → default provider.
        def for_outbound(to_phone:, business_id: nil)
          phone = Messages::InboundMessage.normalize_phone(to_phone)
          provider =
            WhatsappBot::Config.phone_overrides[phone] ||
            business_provider(business_id) ||
            WhatsappBot::Config.default_provider

          build(provider)
        end

        def build(provider_name)
          key = provider_name.to_sym
          adapter_class = adapters[key]
          raise UnknownProviderError, "Unknown WhatsApp provider: #{provider_name}" unless adapter_class

          adapter_class.new
        end

        private

        def business_provider(business_id)
          return if business_id.blank?

          WhatsappBot::Config.business_overrides[business_id.to_s]
        end
      end
    end
  end
end
