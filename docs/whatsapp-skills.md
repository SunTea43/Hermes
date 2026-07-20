# Skills de WhatsApp

Las skills son la frontera de lectura/escritura del bot. Los handlers (y más adelante el AI Agent) no persisten datos directamente: invocan skills registradas.

## Contrato

```ruby
WhatsappBot::Skills::Registry.call(
  "registrar_venta",
  user: user,
  business: business,
  input: { ... },
  idempotency_key: "#{provider_message_id}:registrar_venta"
)
```

Retorna `WhatsappBot::Skills::Base::Result` con `success?`, `data`, `errors` y `idempotent_replay`.

## Skills disponibles

| Nombre | Tipo | Clase |
| --- | --- | --- |
| `registrar_venta` | Escritura | `Skills::RegisterSale` |
| `registrar_compra` | Escritura | `Skills::RegisterPurchase` |
| `registrar_pago` | Escritura | `Skills::RegisterPayment` |
| `consultar_inventario` | Lectura | `Skills::QueryInventory` |
| `listar_stock_bajo` | Lectura | `Skills::ListLowStock` |
| `consultar_resumen_ventas` | Lectura | `Skills::SalesReport` |

## Permisos

Toda ejecución valida primero que el usuario esté activo, tenga acceso a la tienda y esté autorizado para WhatsApp. Luego aplica permisos por rol:

- `owner` y `manager`: todas las skills.
- `operator`: las skills de lectura; `registrar_venta` con módulo `sales` y `registrar_compra` con módulo `purchases`.
- `viewer`: solo las skills de lectura.
- `registrar_pago`: solo `owner` y `manager`.

`assigned_modules` usa nombres separados por coma, por ejemplo `sales,purchases`. Una revocación de usuario, tienda, rol o canal también bloquea el replay de una ejecución idempotente.

## Idempotencia

Las skills de escritura guardan el resultado en `whatsapp_skill_executions` indexado por `idempotency_key` (único). Si el proveedor reenvía el mismo mensaje, se devuelve el resultado anterior sin duplicar órdenes ni pagos.

Clave recomendada: `{provider_message_id}:{skill_name}`.
