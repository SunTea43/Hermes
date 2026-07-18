module WhatsappBot
  class ReportHandler < BaseHandler
    def call
      result = Skills::Registry.call(
        "consultar_resumen_ventas",
        user: @user,
        business: @business,
        input: {}
      )
      data = result.data

      lines = [
        "📊 Resumen del día #{data[:date].strftime('%d/%m')}:",
        "- Ventas: #{data[:count]} (total $#{data[:total]})",
        "  • Contado: $#{data[:cash]}",
        "  • Crédito: $#{data[:credit]}",
        "- Cartera total pendiente: $#{data[:pending_portfolio]}"
      ]
      lines << "⚠️ #{data[:low_stock_count]} productos bajo mínimo" if data[:low_stock_count].to_i.positive?

      reply(lines.join("\n"))
    end
  end
end
