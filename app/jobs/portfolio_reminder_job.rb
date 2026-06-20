class PortfolioReminderJob < ApplicationJob
  queue_as :default

  def perform
    Business.find_each do |business|
      overdue = business.sales_orders
                        .where(payment_condition: "credit")
                        .where(payment_status: %w[pending partial])
                        .where("payment_due_at <= ?", Date.tomorrow)

      next if overdue.empty?

      owner = business.owner
      next unless owner&.whatsapp_phone.present?

      msg = "⏰ Cartera por cobrar:\n" + overdue.map { |o|
        days = (o.payment_due_at.to_date - Date.today).to_i
        label = days <= 0 ? "vencida" : "vence #{o.payment_due_at.strftime('%d/%m')}"
        "- #{o.customer_name}: $#{o.total} (#{label})"
      }.join("\n")

      WhatsappBot::Sender.deliver(owner.whatsapp_phone, msg)
    end
  end
end
