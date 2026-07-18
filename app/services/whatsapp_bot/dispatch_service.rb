module WhatsappBot
  class DispatchService
    SALE_PATTERNS = /\b(vendí|vendi|venta|fiado|crédito|credito|cobr)\b/i
    PURCHASE_PATTERNS = /\b(recibí|recibi|compra|compré|compre|proveedor)\b/i
    PAYMENT_PATTERNS = /\b(pagó|pago|abono|canceló|cancelo|pagando)\b/i
    INVENTORY_PATTERNS = /\b(cuánto|cuanto|stock|inventario|queda|hay|bajo)\b/i
    REPORT_PATTERNS = /\b(reporte|resumen|ventas del día|ventas de hoy|balance)\b/i

    def self.call(user, message, business:, audit: nil)
      new(user, message, business: business, audit: audit).call
    end

    def initialize(user, message, business:, audit: nil)
      @user = user
      @message = message
      @business = business
      @audit = audit
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

    def handler_for_state(state)
      case state[:intent]
      when :sale then SaleHandler.new(@user, @message, @session, state, business: @business)
      when :purchase then PurchaseHandler.new(@user, @message, @session, state, business: @business)
      when :payment then PaymentHandler.new(@user, @message, @session, state, business: @business)
      else
        @session.clear
        handler_for_message
      end
    end

    def handler_for_message
      case @message
      when SALE_PATTERNS then SaleHandler.new(@user, @message, @session, {}, business: @business)
      when PURCHASE_PATTERNS then PurchaseHandler.new(@user, @message, @session, {}, business: @business)
      when PAYMENT_PATTERNS then PaymentHandler.new(@user, @message, @session, {}, business: @business)
      when INVENTORY_PATTERNS then InventoryQueryHandler.new(@user, @message, @session, business: @business)
      when REPORT_PATTERNS then ReportHandler.new(@user, @message, @session, business: @business)
      else UnknownHandler.new(@user, @message, @session, business: @business)
      end
    end
  end
end
