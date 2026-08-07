module WhatsappBot
  module Media
    module Normalize
      module_function

      def call(raw, message_type: nil)
        h = raw.to_h.with_indifferent_access
        mime = h[:mime_type].presence || h[:content_type]
        kind = h[:kind].presence || message_type.presence || kind_from_mime(mime)

        {
          kind: kind.to_s,
          id: h[:id],
          url: h[:url],
          mime_type: mime,
          caption: h[:caption]
        }.compact.with_indifferent_access
      end

      def kind_from_mime(mime)
        return nil if mime.blank?

        case mime.to_s
        when /\Aaudio\//i then "audio"
        when /\Aimage\//i then "image"
        when /\Avideo\//i then "video"
        else "document"
        end
      end
    end
  end
end
