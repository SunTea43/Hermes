module WhatsappBot
  module Providers
    class Base
      def name
        raise NotImplementedError
      end

      def parse_inbound(_request)
        raise NotImplementedError
      end

      def valid_signature?(_request)
        raise NotImplementedError
      end

      def deliver(_outbound_message)
        raise NotImplementedError
      end
    end
  end
end
