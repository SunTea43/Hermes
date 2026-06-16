module WhatsappBot
  class UnknownHandler < BaseHandler
    MENU = <<~MSG
      No entendí ese mensaje. Podés escribirme:

      📦 *Ventas*
      • "Vendí 10kg de arroz"
      • "Fiado a María 5kg arroz"

      🛒 *Compras*
      • "Recibí de Juanito: arroz 50kg a $2,000"

      💰 *Pagos*
      • "María pagó $10,000"

      📊 *Inventario*
      • "¿Cuánto arroz me queda?"
      • "¿Qué está bajo?"

      📈 *Reporte*
      • "Reporte del día"
    MSG

    def call
      reply(MENU)
    end
  end
end
