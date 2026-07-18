module WhatsappBot
  module Skills
    class QueryInventory < Base
      def self.skill_name = "consultar_inventario"

      def call
        AuthorizationGateway.authorize!(user: @user, business: @business)

        name = @input[:product_name].to_s
        inventory = @business.inventories
                             .joins(:product)
                             .where("lower(products.name) LIKE ?", "%#{name.downcase}%")
                             .includes(:product)
                             .first

        return failure("product not found") unless inventory

        success(
          product_name: inventory.product.name,
          current_quantity: inventory.current_quantity,
          unit_measure: inventory.product.unit_measure,
          minimum_alert_quantity: inventory.minimum_alert_quantity,
          low: inventory.current_quantity < inventory.minimum_alert_quantity
        )
      end
    end
  end
end
