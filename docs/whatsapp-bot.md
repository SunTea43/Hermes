# WhatsApp Bot — Diseño e integración

Hermes usa WhatsApp como canal principal de operación. Este documento describe la arquitectura del bot, los flujos conversacionales y la integración con Twilio.

---

## Arquitectura del bot

```text
Usuario WhatsApp
      │
      ▼
Twilio Webhook ──→ POST /webhooks/whatsapp
      │
      ▼
WebhooksController
      │
      ▼
WhatsappBot::DispatchService    ← identifica intención
      │
      ├──→ SaleHandler          ← registra venta
      ├──→ PurchaseHandler      ← registra compra
      ├──→ PaymentHandler       ← registra pago
      ├──→ InventoryQueryHandler← consulta stock
      ├──→ ReportHandler        ← genera reporte
      └──→ UnknownHandler       ← menú de ayuda
      │
      ▼
WhatsappBot::Sender             ← envía respuesta vía Twilio API
```

---

## Identificación de usuario

El sistema identifica al usuario por su número de teléfono de WhatsApp (`params[:From]`), que se busca en `users.whatsapp_phone`.

Si el número no existe en la BD, el bot responde con un mensaje de error o invita al usuario a registrarse desde el portal web.

---

## Flujos conversacionales

### Venta al contado

```
Usuario → "Vendí 10kg de arroz"
Bot     → "10kg de Arroz × $2,500 = $25,000. ¿A quién? (nombre o 'venta general')"
Usuario → "Don Julio"
Bot     → "Venta a Don Julio por $25,000. ¿Contado o crédito?"
Usuario → "Contado"
Bot     → "✅ VEN-001 registrada. Stock Arroz: 100kg → 90kg"
```

### Venta a crédito

```text
Usuario → "Fiado a María 5kg arroz, cobra el viernes"
Bot     → "Venta a crédito: 5kg Arroz ($12,500) a María. Vence viernes 20/06.
           ¿Confirmo?"
Usuario → "Sí"
Bot     → "✅ VEN-002 registrada. Cartera pendiente María: $12,500"
```

### Pago de cartera

```text
Usuario → "María pagó $10,000"
Bot     → "María tiene saldo de $12,500 (VEN-002). Abono de $10,000.
           Saldo pendiente: $2,500. ¿Confirmo?"
Usuario → "Sí"
Bot     → "✅ Pago registrado. Saldo pendiente María: $2,500"
```

### Consulta de inventario

```text
Usuario → "¿Cuánto arroz me queda?"
Bot     → "Arroz: 90kg ✅ (mínimo: 20kg)"

Usuario → "¿Qué está bajo?"
Bot     → "⚠️ Productos bajo mínimo:
           - Aceite: 3L (mínimo 10L)
           - Sal: 2kg (mínimo 5kg)"
```

### Compra de inventario

```text
Usuario → "Recibí una compra de Juanito: arroz 50kg a $2,000/kg"
Bot     → "Compra a Juanito:
           - Arroz 50kg: $100,000
           Total: $100,000. ¿Confirmo?"
Usuario → "Sí"
Bot     → "✅ COM-001 registrada. Stock Arroz: 90kg → 140kg"
```

---

## Estados de sesión

El bot necesita mantener contexto entre mensajes consecutivos del mismo usuario (ej. el flujo de venta tarda 2-3 mensajes). El estado de conversación se guarda en caché:

```ruby
# app/services/whatsapp_bot/session.rb
module WhatsappBot
  class Session
    TTL = 10.minutes

    def initialize(user)
      @key = "whatsapp_session:#{user.id}"
    end

    def get = Rails.cache.read(@key)
    def set(data) = Rails.cache.write(@key, data, expires_in: TTL)
    def clear = Rails.cache.delete(@key)
  end
end
```

Estructura del estado:

```ruby
{
  intent: :sale,             # intención actual
  step: :awaiting_customer,  # paso en el flujo
  draft: {                   # datos recolectados
    product_id: 1,
    quantity: 10,
    unit_price: 2500
  }
}
```

---

## Configuración Twilio

### Variables de entorno requeridas

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
```

### Webhook en Twilio Console

En [console.twilio.com](https://console.twilio.com), configurar el sandbox de WhatsApp:

- **When a message comes in:** `https://tu-dominio.com/webhooks/whatsapp`
- **HTTP Method:** `POST`

Para desarrollo local, usar [ngrok](https://ngrok.com):

```bash
ngrok http 3000
# URL pública: https://abc123.ngrok.io/webhooks/whatsapp
```

### Enviar mensajes desde Rails

```ruby
# app/services/whatsapp_bot/sender.rb
module WhatsappBot
  class Sender
    def self.deliver(to_phone, message)
      client = Twilio::REST::Client.new(
        ENV["TWILIO_ACCOUNT_SID"],
        ENV["TWILIO_AUTH_TOKEN"]
      )
      client.messages.create(
        from: ENV["TWILIO_WHATSAPP_NUMBER"],
        to:   "whatsapp:#{to_phone}",
        body: message
      )
    end
  end
end
```

---

## Notificaciones proactivas

El bot puede enviar alertas sin que el usuario pregunte. Se implementan como jobs programados con Solid Queue:

### Alerta diaria de stock bajo (8:00 AM)

```ruby
# app/jobs/low_stock_alert_job.rb
class LowStockAlertJob < ApplicationJob
  def perform
    Business.find_each do |business|
      low = business.inventories
                    .where("current_quantity < minimum_alert_quantity")
                    .includes(:product)

      next if low.empty?

      msg = "⚠️ Stock bajo:\n" + low.map { |i|
        "- #{i.product.name}: #{i.current_quantity}#{i.product.unit_measure} (mín. #{i.minimum_alert_quantity})"
      }.join("\n")

      WhatsappBot::Sender.deliver(business.owner.whatsapp_phone, msg)
    end
  end
end
```

```yaml
# config/recurring.yml
low_stock_alert:
  class: LowStockAlertJob
  schedule: "0 8 * * *"   # diario a las 8am
```

### Recordatorio de cartera vencida (9:00 AM)

```ruby
class PortfolioReminderJob < ApplicationJob
  def perform
    Business.find_each do |business|
      overdue = business.sales_orders
                        .where(payment_condition: "credit")
                        .where(payment_status: %w[pending partial])
                        .where("payment_due_at <= ?", Date.tomorrow)

      next if overdue.empty?

      msg = "⏰ Cartera por cobrar:\n" + overdue.map { |o|
        days = (o.payment_due_at.to_date - Date.today).to_i
        label = days <= 0 ? "vencida" : "vence #{o.payment_due_at.strftime('%d/%m')}"
        "- #{o.customer_name}: $#{o.total} (#{label})"
      }.join("\n")

      WhatsappBot::Sender.deliver(business.owner.whatsapp_phone, msg)
    end
  end
end
```
