module WhatsappBot
  class DispatchService
    SALE_PATTERNS = /\b(vendí|vendi|venta|fiado|crédito|credito|cobr)\b/i
    PURCHASE_PATTERNS = /\b(recibí|recibi|compra|compré|compre|proveedor)\b/i
    PAYMENT_PATTERNS = /\b(pagó|pago|abono|canceló|cancelo|pagando)\b/i
    INVENTORY_PATTERNS = /\b(cuánto|cuanto|stock|inventario|queda|hay|bajo)\b/i
    REPORT_PATTERNS = /\b(reporte|resumen|ventas del día|ventas de hoy|balance)\b/i

    def self.call(user, message, business:, audit: nil, idempotency_key: nil)
      new(user, message, business: business, audit: audit, idempotency_key: idempotency_key).call
    end

    def initialize(user, message, business:, audit: nil, idempotency_key: nil)
      @user = user
      @message = message
      @business = business
      @audit = audit
      @idempotency_key = idempotency_key
      @session = Session.new(user, business: business)
    end

    def call
      AuthorizationGateway.authorize!(user: @user, business: @business)

      state = @session.get
      handler = if state
        handler_for_state(state)
      else
        handler_for_message
      end

      @audit&.mark_dispatched!(handler_name: handler.class.name, business: @business)
      handler.call
    end

    private

    def handler_kwargs
      { business: @business, idempotency_key: @idempotency_key }
    end

    def handler_for_state(state)
      case state[:intent]
      when :sale then SaleHandler.new(@user, @message, @session, state, **handler_kwargs)
      when :purchase then PurchaseHandler.new(@user, @message, @session, state, **handler_kwargs)
      when :payment then PaymentHandler.new(@user, @message, @session, state, **handler_kwargs)
      else
        @session.clear
        handler_for_message
      end
    end

    def handler_for_message
      case @message
      when SALE_PATTERNS then SaleHandler.new(@user, @message, @session, {}, **handler_kwargs)
      when PURCHASE_PATTERNS then PurchaseHandler.new(@user, @message, @session, {}, **handler_kwargs)
      when PAYMENT_PATTERNS then PaymentHandler.new(@user, @message, @session, {}, **handler_kwargs)
      when INVENTORY_PATTERNS then InventoryQueryHandler.new(@user, @message, @session, **handler_kwargs)
      when REPORT_PATTERNS then ReportHandler.new(@user, @message, @session, **handler_kwargs)
      else UnknownHandler.new(@user, @message, @session, **handler_kwargs)
      end
    end
  end
end
