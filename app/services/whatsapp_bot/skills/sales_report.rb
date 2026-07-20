module WhatsappBot
  module Skills
    class SalesReport < Base
      def self.skill_name = "consultar_resumen_ventas"

      def call
        authorize_skill!

        today = Date.current
        orders = @business.sales_orders.where(created_at: today.all_day)

        success(
          date: today,
          count: orders.count,
          total: orders.sum(:total),
          cash: orders.where(payment_condition: "cash").sum(:total),
          credit: orders.where(payment_condition: "credit").sum(:total),
          pending_portfolio: @business.sales_orders
                                      .where(payment_condition: "credit")
                                      .where(payment_status: %w[pending partial])
                                      .sum(:total),
          low_stock_count: @business.inventories
                                    .where("current_quantity < minimum_alert_quantity")
                                    .count
        )
      end
    end
  end
end
