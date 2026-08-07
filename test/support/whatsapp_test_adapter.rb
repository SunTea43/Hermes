require "tempfile"

module WhatsappBot
  module Providers
    class TestAdapter < Base
      class << self
        attr_accessor :deliveries, :valid_signature, :downloaded_media_bytes

        def reset!
          self.deliveries = []
          self.valid_signature = true
          self.downloaded_media_bytes = "fake-audio-bytes"
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
          media: media_from(params),
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

      def download_media(media_ref)
        ref = Media::Normalize.call(media_ref)
        tempfile = Tempfile.new([ "whatsapp-test-media", ".ogg" ])
        tempfile.binmode
        tempfile.write(self.class.downloaded_media_bytes.to_s)
        tempfile.rewind
        tempfile
      end

      private

      def media_from(params)
        media_id = params[:MediaId].presence || params["MediaId"]
        media_type = params[:MediaType].presence || params["MediaType"]
        mime = params[:MediaMimeType].presence || params["MediaMimeType"]
        caption = params[:MediaCaption].presence || params["MediaCaption"]
        return nil if media_id.blank? && media_type.blank?

        [
          Media::Normalize.call(
            {
              kind: media_type.presence || "audio",
              id: media_id.presence || "TEST_MEDIA",
              mime_type: mime.presence || "audio/ogg",
              caption: caption
            }
          )
        ]
      end
    end
  end
end
