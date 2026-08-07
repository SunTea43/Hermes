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

      # Downloads provider media into a Tempfile. +media_ref+ is a Hash with
      # indifferent access: kind, id and/or url, mime_type, caption.
      def download_media(_media_ref)
        raise NotImplementedError
      end
    end
  end
end
