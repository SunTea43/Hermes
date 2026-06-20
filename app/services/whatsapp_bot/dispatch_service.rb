module WhatsappBot
  class DispatchService
    SALE_PATTERNS = /\b(vendí|vendi|venta|fiado|crédito|credito|cobr)\b/i
    PURCHASE_PATTERNS = /\b(recibí|recibi|compra|compré|compre|proveedor)\b/i
    PAYMENT_PATTERNS = /\b(pagó|pago|abono|canceló|cancelo|pagando)\b/i
    INVENTORY_PATTERNS = /\b(cuánto|cuanto|stock|inventario|queda|hay|bajo)\b/i
    REPORT_PATTERNS = /\b(reporte|resumen|ventas del día|ventas de hoy|balance)\b/i

    def self.call(user, message)
      new(user, message).call
    end

    def initialize(user, message)
      @user    = user
      @message = message
      @session = Session.new(user)
    end

    def call
      state = @session.get

      # Si hay un flujo en curso, continuar ese handler
      if state
        handler_for_state(state).call
      else
        handler_for_message.call
      end
    end

    private

    def handler_for_state(state)
      case state[:intent]
      when :sale      then SaleHandler.new(@user, @message, @session, state)
      when :purchase  then PurchaseHandler.new(@user, @message, @session, state)
      when :payment   then PaymentHandler.new(@user, @message, @session, state)
      else
        @session.clear
        handler_for_message
      end
    end

    def handler_for_message
      case @message
      when SALE_PATTERNS      then SaleHandler.new(@user, @message, @session, {})
      when PURCHASE_PATTERNS  then PurchaseHandler.new(@user, @message, @session, {})
      when PAYMENT_PATTERNS   then PaymentHandler.new(@user, @message, @session, {})
      when INVENTORY_PATTERNS then InventoryQueryHandler.new(@user, @message, @session)
      when REPORT_PATTERNS    then ReportHandler.new(@user, @message, @session)
      else                         UnknownHandler.new(@user, @message, @session)
      end
    end
  end
end
