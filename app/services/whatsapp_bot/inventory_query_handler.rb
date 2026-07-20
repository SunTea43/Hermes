module WhatsappBot
  class InventoryQueryHandler < BaseHandler
    def call
      if low_stock_query?
        handle_low_stock
      else
        handle_product_query
      end
    end

    private

    def low_stock_query?
      @message.match?(/bajo|mínimo|minimo|qué.*falta|que.*falta/i)
    end

    def handle_low_stock
      result = Skills::Registry.call(
        "listar_stock_bajo",
        user: @user,
        business: @business,
        input: {}
      )

      items = result.data[:items] || []
      if items.empty?
        reply(ResponseRenderer.low_stock_ok)
      else
        reply(ResponseRenderer.low_stock_list(items))
      end
    end

    def handle_product_query
      name = extract_product_name
      result = Skills::Registry.call(
        "consultar_inventario",
        user: @user,
        business: @business,
        input: { product_name: name }
      )

      unless result.success?
        reply(ResponseRenderer.inventory_not_found(name))
        return
      end

      reply(ResponseRenderer.inventory_item(**result.data.slice(
        :product_name, :current_quantity, :unit_measure, :minimum_alert_quantity, :low
      ).symbolize_keys))
    end

    def extract_product_name
      @message
        .gsub(/cuánto|cuanto|stock|inventario|queda|hay|me|de|tengo/i, "")
        .strip
        .squeeze(" ")
    end
  end
end
