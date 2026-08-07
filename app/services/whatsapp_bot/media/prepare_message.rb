module WhatsappBot
  module Media
    # Turns an inbound WhatsApp message (text and/or media) into a text body
    # (and optional pre-parsed interpretation) suitable for DispatchService.
    class PrepareMessage
      Result = Data.define(:ok, :body, :error_code, :metadata, :interpretation) do
        def ok? = ok
        def error? = !ok
      end

      def self.call(inbound:, adapter:, business: nil, audit: nil, transcriber: nil, vision_client: nil)
        new(
          inbound: inbound,
          adapter: adapter,
          business: business,
          audit: audit,
          transcriber: transcriber,
          vision_client: vision_client
        ).call
      end

      def initialize(inbound:, adapter:, business: nil, audit: nil, transcriber: nil, vision_client: nil)
        @inbound = inbound
        @adapter = adapter
        @business = business
        @audit = audit
        @transcriber = transcriber
        @vision_client = vision_client
      end

      def call
        media_list = Array(@inbound.media)
        return success(@inbound.body.to_s) if media_list.empty?

        ref = Normalize.call(media_list.first)
        case ref[:kind].to_s
        when "audio"
          prepare_audio(ref)
        when "image"
          prepare_image(ref)
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

      def prepare_image(ref)
        unless WhatsappBot::Config.media_image_enabled?
          return caption_fallback(ref, :image_disabled)
        end

        tempfile = @adapter.download_media(ref)
        begin
          if File.size(tempfile.path) > WhatsappBot::Config.media_max_bytes
            return failure(:media_too_large, media_meta(ref))
          end

          catalog = catalog_names
          caption = ref[:caption].presence || @inbound.body.presence
          interpretation = MultimodalInterpreter.call(
            file_path: tempfile.path,
            mime_type: ref[:mime_type],
            caption: caption,
            catalog_names: catalog,
            client: @vision_client
          )
          # Photo supplies line items; compra vs venta comes from caption or a follow-up message.
          interpretation = ImageOrderKind.normalize(interpretation, caption: caption)
          guarded = ConfidenceGuard.call(interpretation)
          body = caption.to_s

          success(
            body,
            media_meta(ref).merge(
              "vision_intent" => guarded.intent.to_s,
              "vision_confidence" => guarded.confidence
            ),
            interpretation: guarded
          )
        ensure
          cleanup_tempfile(tempfile)
        end
      rescue StandardError => e
        Rails.logger.error("[WhatsappBot::Media::PrepareMessage] image failed: #{e.class}: #{e.message}")
        caption = ref[:caption].presence || @inbound.body.presence
        return success(caption, media_meta(ref).merge("vision_error" => e.message)) if caption.present?

        failure(:vision_failed, media_meta(ref).merge("error" => e.message))
      end

      def caption_or_unsupported(ref)
        caption_fallback(ref, :unsupported_media)
      end

      def caption_fallback(ref, error_when_blank)
        caption = ref[:caption].presence || @inbound.body.presence
        return success(caption, media_meta(ref)) if caption.present?

        failure(error_when_blank, media_meta(ref))
      end

      def success(body, metadata = {}, interpretation: nil)
        merge_audit(metadata)
        if interpretation
          merge_audit(
            "interpretation" => interpretation.raw,
            "prompt_version" => Prompts::InterpreterV1::VERSION
          )
        end
        Result.new(
          ok: true,
          body: body.to_s,
          error_code: nil,
          metadata: metadata,
          interpretation: interpretation
        )
      end

      def failure(code, metadata = {})
        merge_audit(metadata.merge("media_error" => code.to_s))
        Result.new(ok: false, body: "", error_code: code, metadata: metadata, interpretation: nil)
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

      def catalog_names
        return [] if @business.blank?

        @business.products.active.order(:name).limit(80).pluck(:name)
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
