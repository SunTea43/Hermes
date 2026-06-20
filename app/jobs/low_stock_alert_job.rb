class LowStockAlertJob < ApplicationJob
  queue_as :default

  def perform
    Business.find_each do |business|
      low = business.inventories
                    .where("current_quantity < minimum_alert_quantity")
                    .includes(:product)

      next if low.empty?

      owner = business.owner
      next unless owner&.whatsapp_phone.present?

      msg = "⚠️ Stock bajo:\n" + low.map { |i|
        "- #{i.product.name}: #{i.current_quantity}#{i.product.unit_measure} (mín. #{i.minimum_alert_quantity})"
      }.join("\n")

      WhatsappBot::Sender.deliver(owner.whatsapp_phone, msg)
    end
  end
end
