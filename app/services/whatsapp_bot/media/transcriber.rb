module WhatsappBot
  module Media
    class Transcriber
      def self.call(file_path, mime_type: nil, client: nil)
        (client || default_client).transcribe(file_path, mime_type: mime_type)
      end

      def self.default_client
        case WhatsappBot::Config.media_stt_provider
        when :fake
          FakeTranscriber.new
        else
          # openai, groq, or any OpenAI-compatible endpoint configured in media.stt
          OpenAiTranscriber.new
        end
      end
    end
  end
end
