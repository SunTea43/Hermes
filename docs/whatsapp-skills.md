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

## Idempotencia

Las skills de escritura guardan el resultado en `whatsapp_skill_executions` indexado por `idempotency_key` (único). Si el proveedor reenvía el mismo mensaje, se devuelve el resultado anterior sin duplicar órdenes ni pagos.

Clave recomendada: `{provider_message_id}:{skill_name}`.
