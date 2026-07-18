module WhatsappBot
  module Providers
    class TestAdapter < Base
      class << self
        attr_accessor :deliveries, :valid_signature

        def reset!
          self.deliveries = []
          self.valid_signature = true
        end
      end

      reset!

      def name
        :test
      end

      def parse_inbound(request)
        params = request.params
        Messages::InboundMessage.new(
          provider: name,
          provider_message_id: params[:MessageSid].presence || params["MessageSid"] || "TEST_SID",
          from: params[:From].presence || params["From"],
          to: params[:To].presence || params["To"],
          body: params[:Body].presence || params["Body"],
          raw_payload: params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
        )
      end

      def valid_signature?(_request)
        self.class.valid_signature
      end

      def deliver(outbound_message)
        self.class.deliveries << outbound_message
        outbound_message
      end
    end
  end
end
