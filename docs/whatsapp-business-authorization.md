# Autorización de tiendas para WhatsApp

Antes de operar por WhatsApp, la tienda debe estar **habilitada** y el usuario debe poder acceder a ella.

## Habilitar una tienda

Campo en `businesses.whatsapp_enabled` (default: `false`).

```ruby
business = Business.find(12)
business.update!(whatsapp_enabled: true)
```

Solo tiendas con `whatsapp_enabled: true` entran en la resolución del negocio operativo.

## Resolver la tienda operativa

`WhatsappBot::BusinessResolver` elige el negocio así:

1. `business_id` en la sesión de conversación (flujo multi-turno)
2. `users.default_whatsapp_business_id` si apunta a una tienda habilitada y accesible
3. La única tienda habilitada del usuario, si hay exactamente una
4. Si hay varias y no hay default → error `:ambiguous` (el bot pide configurar default)
5. Si no hay ninguna habilitada → error `:not_authorized`

```ruby
user.update!(default_whatsapp_business: business)
```

## Permisos

`WhatsappBot::AuthorizationGateway` exige:

- `business.whatsapp_enabled?`
- `user.can_access_business?(business)` (owner o `role_assignments` activas)

## Auditoría

Cada mensaje entrante crea un `WhatsappMessageAudit` con estados:

| Status | Significado |
| --- | --- |
| `received` | Llegó el webhook |
| `dispatched` | Se enrutó a un handler |
| `denied` | Usuario desconocido, tienda no autorizada o sin permiso |
| `error` | Fallo inesperado |

Campos útiles: `provider`, `provider_message_id`, `from_phone`, `handler_name`, `business_id`, `metadata`.
