module WhatsappBot
  module Media
    # Deterministic vision interpreter for tests and local development.
    class FakeVisionClient
      def initialize(response = nil)
        @response = response || default_response
        @calls = []
      end

      attr_reader :calls

      def interpret(file_path:, mime_type:, caption: nil, catalog_names: [])
        @calls << {
          file_path: file_path,
          mime_type: mime_type,
          caption: caption,
          catalog_names: catalog_names
        }

        payload = @response.deep_dup
        if caption.to_s.match?(/venta|vend[ií]/i)
          payload = sale_response
        end

        Interpretation.new(
          intent: payload["intent"],
          entities: payload["entities"] || {},
          confidence: payload["confidence"] || 0.0,
          raw: payload.merge("source" => "image")
        )
      end

      private

      def default_response
        {
          "intent" => "purchase",
          "entities" => {
            "supplier_name" => "Juanito",
            "items" => [
              {
                "product_name" => "arroz",
                "quantity" => 50,
                "unit_price" => 2000
              }
            ]
          },
          "confidence" => 0.91
        }
      end

      def sale_response
        {
          "intent" => "sale",
          "entities" => {
            "customer_name" => "Don Julio",
            "payment_condition" => "cash",
            "items" => [
              {
                "product_name" => "arroz",
                "quantity" => 10
              }
            ]
          },
          "confidence" => 0.9
        }
      end
    end
  end
end
