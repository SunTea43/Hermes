module WhatsappBot
  module Media
    # Normalizes WhatsApp / provider audio mime types for download + STT upload.
    # Meta often sends "audio/ogg; codecs=opus", which must not become ".bin".
    module AudioFile
      module_function

      def base_mime(mime_type)
        mime_type.to_s.split(";").first.to_s.strip.downcase.presence
      end

      def extension_for(mime_type)
        case base_mime(mime_type)
        when "audio/ogg", "audio/opus", "application/ogg" then ".ogg"
        when "audio/mpeg", "audio/mp3" then ".mp3"
        when "audio/mp4", "audio/aac", "audio/m4a" then ".m4a"
        when "audio/wav", "audio/x-wav", "audio/wave" then ".wav"
        when "audio/webm" then ".webm"
        when "audio/flac" then ".flac"
        else
          raw = base_mime(mime_type).to_s
          return ".ogg" if raw.include?("ogg") || raw.include?("opus")
          return ".mp3" if raw.include?("mpeg") || raw.include?("mp3")
          ".bin"
        end
      end

      # Returns [filename, content_type] suitable for OpenAI-compatible STT APIs (Groq/OpenAI).
      def upload_identity(file_path, mime_type: nil)
        ext = File.extname(file_path.to_s)
        resolved_ext = if ext.blank? || ext == ".bin"
          extension_for(mime_type.presence || "audio/ogg")
        else
          ext
        end

        # Prefer .ogg for WhatsApp voice notes (ogg/opus).
        if %w[.bin .oga].include?(resolved_ext) || base_mime(mime_type).to_s.match?(/ogg|opus/)
          resolved_ext = ".ogg" unless %w[.ogg .opus].include?(resolved_ext)
        end

        content_type = case resolved_ext
        when ".ogg", ".opus" then "audio/ogg"
        when ".mp3" then "audio/mpeg"
        when ".m4a" then "audio/mp4"
        when ".wav" then "audio/wav"
        when ".webm" then "audio/webm"
        when ".flac" then "audio/flac"
        else base_mime(mime_type) || "application/octet-stream"
        end

        [ "whatsapp-audio#{resolved_ext}", content_type ]
      end
    end
  end
end
