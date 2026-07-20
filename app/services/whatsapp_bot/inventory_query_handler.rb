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
        reply("✅ Todo el stock está sobre los mínimos.")
      else
        lines = items.map { |i|
          "- #{i[:product_name]}: #{i[:current_quantity]}#{i[:unit_measure]} (mín. #{i[:minimum_alert_quantity]})"
        }
        reply("⚠️ Productos bajo mínimo:\n#{lines.join("\n")}")
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
        reply("No encontré \"#{name}\" en tu inventario.")
        return
      end

      data = result.data
      status = data[:low] ? "⚠️" : "✅"
      reply("#{data[:product_name]}: #{data[:current_quantity]}#{data[:unit_measure]} #{status} (mín. #{data[:minimum_alert_quantity]})")
    end

    def extract_product_name
      @message
        .gsub(/cuánto|cuanto|stock|inventario|queda|hay|me|de|tengo/i, "")
        .strip
        .squeeze(" ")
    end
  end
end
