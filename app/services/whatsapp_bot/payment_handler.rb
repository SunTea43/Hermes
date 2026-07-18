module WhatsappBot
  class PaymentHandler < BaseHandler
    def call
      case @state[:step]
      when :awaiting_confirmation
        handle_confirmation_step
      else
        handle_initial_message
      end
    end

    private

    def handle_initial_message
      parsed = parse_payment_message
      unless parsed
        reply('No entendí. Ejemplo: "María pagó $10,000".')
        return
      end

      order = find_pending_order(parsed[:customer_name])
      unless order
        reply("No encontré cartera pendiente para \"#{parsed[:customer_name]}\".")
        return
      end

      draft = {
        order_id: order.id,
        customer_name: order.customer_name,
        amount: parsed[:amount],
        order_total: order.total
      }

      remaining = order.total - (order.payments.sum(:amount) || 0)
      new_balance = [ remaining - parsed[:amount], 0 ].max
      @session.set(intent: :payment, step: :awaiting_confirmation, draft: draft)
      reply(ResponseRenderer.payment_confirm(
        customer_name: order.customer_name,
        remaining: remaining,
        reference_number: order.reference_number,
        amount: parsed[:amount],
        new_balance: new_balance
      ))
    end

    def handle_confirmation_step
      draft = @state[:draft]

      if negative?
        @session.clear
        reply(ResponseRenderer.cancelled(:payment))
        return
      end

      unless affirmative?
        reply(ResponseRenderer.confirm_yes_no)
        return
      end

      result = Skills::Registry.call(
        "registrar_pago",
        user: @user,
        business: @business,
        input: draft,
        idempotency_key: skill_key("registrar_pago")
      )
      @session.clear

      unless result.success?
        reply(ResponseRenderer.skill_error("registrar el pago", result.errors))
        return
      end

      data = result.data
      reply(ResponseRenderer.payment_recorded(
        customer_name: data[:customer_name],
        remaining: data[:remaining]
      ))
    end

    def find_pending_order(customer_name)
      @business.sales_orders
               .where(payment_condition: "credit")
               .where(payment_status: %w[pending partial])
               .where("lower(customer_name) LIKE ?", "%#{customer_name.downcase}%")
               .order(created_at: :desc)
               .first
    end

    def parse_payment_message
      match = @message.match(/([\w\s]+?)\s+pag[oó]\s+\$?([\d.,]+)/i)
      return nil unless match

      customer, amount_str = match.captures
      { customer_name: customer.strip, amount: amount_str.tr(",", ".").to_f }
    end
  end
end
