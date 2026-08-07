module WhatsappBot
  module Media
    class MultimodalInterpreter
      def self.call(file_path:, mime_type:, caption: nil, catalog_names: [], client: nil)
        (client || default_client).interpret(
          file_path: file_path,
          mime_type: mime_type,
          caption: caption,
          catalog_names: catalog_names
        )
      end

      def self.default_client
        case WhatsappBot::Config.media_vision
        when :fake
          FakeVisionClient.new
        else
          OpenAiVisionClient.new
        end
      end
    end
  end
end
