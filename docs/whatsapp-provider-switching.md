# Cómo cambiar el proveedor de mensajes WhatsApp

Hermes desacopla el canal WhatsApp detrás de un **Provider Adapter**. El bot, los handlers y los jobs hablan con contratos internos (`InboundMessage` / `OutboundMessage`); el adapter concreto (Twilio, Meta, otro BSP) se resuelve por configuración.

## Contratos internos

| Contrato | Uso |
| --- | --- |
| `WhatsappBot::Messages::InboundMessage` | Mensaje entrante normalizado (`provider`, `provider_message_id`, `from`, `to`, `body`, …) |
| `WhatsappBot::Messages::OutboundMessage` | Mensaje saliente (`to`, `body`, `business_id` opcional) |
| `WhatsappBot::Providers::Base` | Interfaz: `parse_inbound`, `valid_signature?`, `deliver` |
| `WhatsappBot::Sender` | Fachada de salida; elige adapter vía `Providers::Resolver` |

Hoy el único adapter implementado es `WhatsappBot::Providers::TwilioAdapter`.

## Webhooks por proveedor

| Ruta | Proveedor |
| --- | --- |
| `POST /webhooks/whatsapp` | Default (`config/whatsapp.yml` → `default_provider`) |
| `POST /webhooks/whatsapp/:provider` | Explícito (`twilio`, futuro `meta`, etc.) |

Ejemplo Twilio (explícito):

```text
POST https://tu-dominio.com/webhooks/whatsapp/twilio
```

## Configuración (`config/whatsapp.yml`)

```yaml
production:
  default_provider: twilio
  validate_signatures: true
  phone_overrides: {}
  business_overrides: {}
```

### Cambiar el proveedor default

```yaml
production:
  default_provider: meta   # cuando exista WhatsappBot::Providers::MetaAdapter
```

### Cambiar por número de teléfono (destino)

Útil para migrar cohortes pequeñas o un número de prueba:

```yaml
production:
  default_provider: twilio
  phone_overrides:
    "+573001112233": meta
```

La clave es el teléfono en E.164 **sin** el prefijo `whatsapp:`.

`Sender.deliver("+573001112233", "Hola")` usará el adapter `meta` para ese destino; el resto seguirá en Twilio.

### Cambiar por cliente / tienda (`business_id`)

```yaml
production:
  default_provider: twilio
  business_overrides:
    "12": meta
```

Al enviar con contexto de tienda:

```ruby
WhatsappBot::Sender.deliver(
  user.whatsapp_phone,
  "Stock bajo…",
  business_id: business.id
)
```

### Precedencia de resolución (outbound)

1. Override por **teléfono** (`phone_overrides`)
2. Override por **business_id** (`business_overrides`)
3. `default_provider`

## Variables de entorno (Twilio)

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxx
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
```

Con `validate_signatures: true`, el webhook exige el header `X-Twilio-Signature`. En `development` y `test` la validación viene desactivada.

## Agregar un proveedor nuevo

1. Implementar `WhatsappBot::Providers::TuAdapter < Base` con `parse_inbound`, `valid_signature?` y `deliver`.
2. Registrar el símbolo en `WhatsappBot::Providers::Resolver::ADAPTERS`.
3. Apuntar el webhook del proveedor a `/webhooks/whatsapp/tu_proveedor`.
4. Activar por default, por teléfono o por `business_id` en `config/whatsapp.yml`.
5. Comparar entrega/costo y, si hace falta, hacer rollback volviendo el override a `twilio`.

## Rollback

Quitar o revertir la entrada en `phone_overrides` / `business_overrides`, o restaurar `default_provider: twilio`. Los contratos internos y la idempotencia (por `provider_message_id`) no dependen del BSP.
