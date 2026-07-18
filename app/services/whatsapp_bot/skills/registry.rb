module WhatsappBot
  module Skills
    class Registry
      SKILLS = {
        "registrar_venta" => RegisterSale,
        "registrar_compra" => RegisterPurchase,
        "registrar_pago" => RegisterPayment,
        "consultar_inventario" => QueryInventory,
        "listar_stock_bajo" => ListLowStock,
        "consultar_resumen_ventas" => SalesReport
      }.freeze

      class UnknownSkillError < StandardError; end

      def self.fetch(name)
        SKILLS.fetch(name.to_s) { raise UnknownSkillError, "Unknown skill: #{name}" }
      end

      def self.names
        SKILLS.keys
      end

      def self.call(name, **kwargs)
        fetch(name).call(**kwargs)
      end
    end
  end
end
