# Autorización de tiendas y usuarios para WhatsApp

Antes de operar por WhatsApp se deben cumplir tres condiciones:

1. La tienda tiene el canal habilitado.
2. El usuario está activo y puede acceder a la tienda como owner o mediante un rol activo.
3. Existe una autorización de WhatsApp habilitada para ese usuario y esa tienda.

## Configuración desde la aplicación

- En **Negocios → Editar**, activar “Habilitar operaciones por WhatsApp”.
- En **Usuarios → Editar → Acceso por WhatsApp**, seleccionar las tiendas que la persona puede operar.
- Si hay más de una tienda autorizada, seleccionar una tienda predeterminada.

La autorización individual se guarda en `whatsapp_business_authorizations`, incluyendo quién la concedió. Revocar el checkbox deshabilita la autorización sin eliminar su registro.

## Resolver la tienda operativa

`WhatsappBot::BusinessResolver` elige el negocio así:

1. `business_id` en la sesión de conversación (flujo multi-turno)
2. `users.default_whatsapp_business_id` si apunta a una tienda habilitada, accesible y autorizada
3. La única tienda habilitada y autorizada del usuario, si hay exactamente una
4. Si hay varias y no hay default → error `:ambiguous` (el bot pide configurar default)
5. Si no hay ninguna habilitada → error `:not_authorized`

## Permisos

`WhatsappBot::AuthorizationGateway` exige:

- `user.status == "active"`
- `business.whatsapp_enabled?`
- `user.can_access_business?(business)` (owner o `role_assignments` activas)
- `user.whatsapp_authorized_for?(business)`

La autorización del canal no reemplaza el rol: ambos deben estar vigentes. Los permisos específicos de cada skill se definen en la capa de skills.

## Auditoría

Cada mensaje entrante crea un `WhatsappMessageAudit` con estados:

| Status | Significado |
| --- | --- |
| `received` | Llegó el webhook |
| `dispatched` | Se enrutó a un handler |
| `denied` | Usuario desconocido, tienda no autorizada o sin permiso |
| `error` | Fallo inesperado |

Campos útiles: `provider`, `provider_message_id`, `from_phone`, `handler_name`, `business_id`, `metadata`.
