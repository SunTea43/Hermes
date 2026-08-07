module WhatsappBot
  module Media
    # Turns an inbound WhatsApp message (text and/or media) into a text body
    # suitable for DispatchService. Audio is transcribed when enabled.
    class PrepareMessage
      Result = Data.define(:ok, :body, :error_code, :metadata) do
        def ok? = ok
        def error? = !ok
      end

      def self.call(inbound:, adapter:, audit: nil, transcriber: nil)
        new(inbound: inbound, adapter: adapter, audit: audit, transcriber: transcriber).call
      end

      def initialize(inbound:, adapter:, audit: nil, transcriber: nil)
        @inbound = inbound
        @adapter = adapter
        @audit = audit
        @transcriber = transcriber
      end

      def call
        media_list = Array(@inbound.media)
        return success(@inbound.body.to_s) if media_list.empty?

        ref = Normalize.call(media_list.first)
        case ref[:kind].to_s
        when "audio"
          prepare_audio(ref)
        when "image"
          prepare_image_placeholder(ref)
        else
          caption_or_unsupported(ref)
        end
      end

      private

      def prepare_audio(ref)
        unless WhatsappBot::Config.media_audio_enabled?
          return caption_fallback(ref, :audio_disabled)
        end

        tempfile = @adapter.download_media(ref)
        begin
          if File.size(tempfile.path) > WhatsappBot::Config.media_max_bytes
            return failure(:media_too_large, media_meta(ref))
          end

          text = Transcriber.call(
            tempfile.path,
            mime_type: ref[:mime_type],
            client: @transcriber
          )
          body = [ @inbound.body.presence, text.presence ].compact.join("\n").strip
          return failure(:empty_transcription, media_meta(ref)) if body.blank?

          success(body, media_meta(ref).merge("transcription_preview" => text.to_s.truncate(200)))
        ensure
          cleanup_tempfile(tempfile)
        end
      rescue StandardError => e
        Rails.logger.error("[WhatsappBot::Media::PrepareMessage] audio failed: #{e.class}: #{e.message}")
        failure(:transcription_failed, media_meta(ref).merge("error" => e.message))
      end

      def prepare_image_placeholder(ref)
        # Images are handled in a follow-up PR (multimodal). Caption still works.
        caption_fallback(ref, :image_not_supported)
      end

      def caption_or_unsupported(ref)
        caption_fallback(ref, :unsupported_media)
      end

      def caption_fallback(ref, error_when_blank)
        caption = ref[:caption].presence || @inbound.body.presence
        return success(caption, media_meta(ref)) if caption.present?

        failure(error_when_blank, media_meta(ref))
      end

      def success(body, metadata = {})
        merge_audit(metadata)
        Result.new(ok: true, body: body.to_s, error_code: nil, metadata: metadata)
      end

      def failure(code, metadata = {})
        merge_audit(metadata.merge("media_error" => code.to_s))
        Result.new(ok: false, body: "", error_code: code, metadata: metadata)
      end

      def media_meta(ref)
        {
          "media_kind" => ref[:kind],
          "media_id" => ref[:id],
          "media_mime_type" => ref[:mime_type]
        }.compact
      end

      def merge_audit(metadata)
        return if @audit.blank? || metadata.blank?

        @audit.update!(metadata: (@audit.metadata || {}).merge(metadata))
      end

      def cleanup_tempfile(tempfile)
        return if tempfile.nil?

        tempfile.close! if tempfile.respond_to?(:close!)
        path = tempfile.respond_to?(:path) ? tempfile.path : nil
        File.delete(path) if path.present? && File.exist?(path)
      rescue StandardError
        nil
      end
    end
  end
end
