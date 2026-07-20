module WhatsappBot
  module Skills
    class ListLowStock < Base
      def self.skill_name = "listar_stock_bajo"

      def call
        authorize_skill!

        items = @business.inventories
                         .where("current_quantity < minimum_alert_quantity")
                         .includes(:product)
                         .map do |inventory|
          {
            product_name: inventory.product.name,
            current_quantity: inventory.current_quantity,
            unit_measure: inventory.product.unit_measure,
            minimum_alert_quantity: inventory.minimum_alert_quantity
          }
        end

        success(items: items)
      end
    end
  end
end
