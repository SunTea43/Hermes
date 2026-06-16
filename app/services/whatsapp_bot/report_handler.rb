module WhatsappBot
  class ReportHandler < BaseHandler
    def call
      today   = Date.current
      orders  = @business.sales_orders.where(created_at: today.all_day)
      total   = orders.sum(:total)
      cash    = orders.where(payment_condition: "cash").sum(:total)
      credit  = orders.where(payment_condition: "credit").sum(:total)
      count   = orders.count

      pending = @business.sales_orders
                         .where(payment_condition: "credit")
                         .where(payment_status: %w[pending partial])
                         .sum(:total)

      low_count = @business.inventories
                           .where("current_quantity < minimum_alert_quantity")
                           .count

      lines = [
        "📊 Resumen del día #{today.strftime('%d/%m')}:",
        "- Ventas: #{count} (total $#{total})",
        "  • Contado: $#{cash}",
        "  • Crédito: $#{credit}",
        "- Cartera total pendiente: $#{pending}"
      ]
      lines << "⚠️ #{low_count} productos bajo mínimo" if low_count > 0

      reply(lines.join("\n"))
    end
  end
end
