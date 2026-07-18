module WhatsappBot
  class ReportHandler < BaseHandler
    def call
      result = Skills::Registry.call(
        "consultar_resumen_ventas",
        user: @user,
        business: @business,
        input: {}
      )

      reply(ResponseRenderer.daily_report(**result.data.symbolize_keys.slice(
        :date, :count, :total, :cash, :credit, :pending_portfolio, :low_stock_count
      )))
    end
  end
end
