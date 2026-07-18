module WhatsappBot
  module Skills
    class RegisterPayment < Base
      def self.skill_name = "registrar_pago"

      def call
        with_idempotency do
          AuthorizationGateway.authorize!(user: @user, business: @business)

          order = @business.sales_orders.find_by(id: @input[:order_id])
          return failure("order not found") unless order

          amount = @input[:amount].to_d
          return failure("invalid amount") unless amount.positive?

          payment = nil
          remaining = nil

          ActiveRecord::Base.transaction do
            payment = order.payments.create!(
              amount: amount,
              payment_method: "cash",
              payment_type: "collection",
              payment_status: "completed",
              paid_at: Time.current,
              recorded_by: @user
            )

            total_paid = order.payments.sum(:amount)
            remaining = order.total - total_paid
            order.update!(payment_status: remaining <= 0 ? "paid" : "partial")
          end

          success(
            payment_id: payment.id,
            order_id: order.id,
            customer_name: order.customer_name,
            remaining: [ remaining, 0 ].max
          )
        end
      end
    end
  end
end
