module WhatsappBot
  module Media
    # Deterministic STT for tests and local development.
    class FakeTranscriber
      def initialize(text: "Recibí de Juanito: arroz 50kg a $2000")
        @text = text
        @calls = []
      end

      attr_reader :calls

      def transcribe(file_path, mime_type: nil)
        @calls << { file_path: file_path, mime_type: mime_type }
        @text
      end
    end
  end
end
