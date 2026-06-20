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
      low = @business.inventories
                     .where("current_quantity < minimum_alert_quantity")
                     .includes(:product)

      if low.empty?
        reply("✅ Todo el stock está sobre los mínimos.")
      else
        lines = low.map { |i| "- #{i.product.name}: #{i.current_quantity}#{i.product.unit_measure} (mín. #{i.minimum_alert_quantity})" }
        reply("⚠️ Productos bajo mínimo:\n#{lines.join("\n")}")
      end
    end

    def handle_product_query
      # Extraer nombre de producto del mensaje
      name = extract_product_name
      inventory = @business.inventories
                           .joins(:product)
                           .where("lower(products.name) LIKE ?", "%#{name.downcase}%")
                           .includes(:product)
                           .first

      unless inventory
        reply("No encontré \"#{name}\" en tu inventario.")
        return
      end

      status = inventory.current_quantity < inventory.minimum_alert_quantity ? "⚠️" : "✅"
      reply("#{inventory.product.name}: #{inventory.current_quantity}#{inventory.product.unit_measure} #{status} (mín. #{inventory.minimum_alert_quantity})")
    end

    def extract_product_name
      @message
        .gsub(/cuánto|cuanto|stock|inventario|queda|hay|me|de|tengo/i, "")
        .strip
        .squeeze(" ")
    end
  end
end
