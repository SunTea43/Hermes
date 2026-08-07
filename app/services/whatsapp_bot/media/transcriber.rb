module WhatsappBot
  module Media
    class Transcriber
      def self.call(file_path, mime_type: nil, client: nil)
        (client || default_client).transcribe(file_path, mime_type: mime_type)
      end

      def self.default_client
        case WhatsappBot::Config.media_transcriber
        when :fake
          FakeTranscriber.new
        else
          OpenAiTranscriber.new
        end
      end
    end
  end
end
