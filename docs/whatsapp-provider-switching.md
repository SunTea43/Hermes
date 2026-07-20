# Cómo cambiar el proveedor de mensajes WhatsApp

Hermes desacopla el canal WhatsApp detrás de un **Provider Adapter**. El bot, los handlers y los jobs hablan con contratos internos (`InboundMessage` / `OutboundMessage`); el adapter concreto (Twilio, Meta, otro BSP) se resuelve por configuración.

## Contratos internos

| Contrato | Uso |
| --- | --- |
| `WhatsappBot::Messages::InboundMessage` | Mensaje entrante normalizado (`provider`, `provider_message_id`, `from`, `to`, `body`, …) |
| `WhatsappBot::Messages::OutboundMessage` | Mensaje saliente (`to`, `body`, `business_id` opcional) |
| `WhatsappBot::Providers::Base` | Interfaz: `parse_inbound`, `valid_signature?`, `deliver` (+ `verify_subscription` opcional) |
| `WhatsappBot::Sender` | Fachada de salida; elige adapter vía `Providers::Resolver` |

Adapters implementados:

- `WhatsappBot::Providers::MetaAdapter` (**default**)
- `WhatsappBot::Providers::TwilioAdapter`

## Webhooks por proveedor

| Ruta | Proveedor |
| --- | --- |
| `GET/POST /webhooks/whatsapp` | Default (`config/whatsapp.yml` → `default_provider`) |
| `GET/POST /webhooks/whatsapp/:provider` | Explícito (`meta`, `twilio`, etc.) |

Meta usa `GET` para el challenge de suscripción (`hub.mode`, `hub.verify_token`, `hub.challenge`) y `POST` para mensajes/estados.

Ejemplo Meta (explícito):

```text
GET/POST https://tu-dominio.com/webhooks/whatsapp/meta
```

## Configuración (`config/whatsapp.yml`)

```yaml
production:
  default_provider: meta
  validate_signatures: true
  phone_overrides: {}
  business_overrides: {}
```

### Cambiar el proveedor default

```yaml
production:
  default_provider: twilio
```

### Cambiar por número de teléfono (destino)

Útil para migrar cohortes pequeñas o un número de prueba:

```yaml
production:
  default_provider: meta
  phone_overrides:
    "+573001112233": twilio
```

La clave es el teléfono en E.164 **sin** el prefijo `whatsapp:`.

### Cambiar por cliente / tienda (`business_id`)

```yaml
production:
  default_provider: meta
  business_overrides:
    "12": twilio
```

### Precedencia de resolución (outbound)

1. Override por **teléfono** (`phone_overrides`)
2. Override por **business_id** (`business_overrides`)
3. `default_provider`

## Variables de entorno (Meta)

```bash
META_WHATSAPP_ACCESS_TOKEN=EAA...
META_WHATSAPP_PHONE_NUMBER_ID=1234567890
META_WHATSAPP_APP_SECRET=xxxxxxxx
META_WHATSAPP_VERIFY_TOKEN=un-token-que-vos-elegis
```

En Meta Developer Console:

1. Webhook callback URL: `https://tu-dominio.com/webhooks/whatsapp/meta`
2. Verify token: el mismo valor de `META_WHATSAPP_VERIFY_TOKEN`
3. Suscribir el campo `messages`

Con `validate_signatures: true`, el webhook exige `X-Hub-Signature-256`. En `development` y `test` la validación viene desactivada.

## Variables de entorno (Twilio)

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxx
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
```

## Agregar un proveedor nuevo

1. Implementar `WhatsappBot::Providers::TuAdapter < Base` con `parse_inbound`, `valid_signature?` y `deliver`.
2. Registrar el símbolo en `WhatsappBot::Providers::Resolver`.
3. Apuntar el webhook del proveedor a `/webhooks/whatsapp/tu_proveedor`.
4. Activar por default, por teléfono o por `business_id` en `config/whatsapp.yml`.
5. Comparar entrega/costo y, si hace falta, hacer rollback.

## Rollback

Quitar o revertir la entrada en `phone_overrides` / `business_overrides`, o restaurar `default_provider: twilio`. Los contratos internos no dependen del BSP.
