# Modelos de dominio — Hermes

Referencia de cada modelo ActiveRecord: atributos, validaciones, asociaciones y enums.

---

## User

Autenticado con Devise. Representa a cualquier persona que interactúa con el sistema (propietarios, gestores, operarios).

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `email` | string | único, requerido (Devise) |
| `whatsapp_phone` | string | único, identificador en el bot de WhatsApp |
| `name` | string | nombre de pantalla |
| `status` | string | `active` / `inactive` |
| `last_active_at` | datetime | última actividad registrada |

### Asociaciones

```ruby
has_many :owned_businesses       # negocios que creó (owner)
has_many :role_assignments        # asignaciones de rol en otros negocios
has_many :purchase_orders_created
has_many :sales_orders_created
has_many :payments_recorded
has_many :inventory_movements
```

### Métodos de autorización

```ruby
user.role_for(business)             # → "owner" | "manager" | "operator" | "viewer" | nil
user.owns?(business)                # → true si es el owner del negocio
user.owner_or_manager_for?(business)# → true si tiene rol suficiente para operaciones sensibles
user.can_access_business?(business) # → true si tiene cualquier asignación activa
```

---

## Business

Negocio multi-tenant. Toda entidad operativa (productos, órdenes, inventario) pertenece a un `Business`.

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `name` | string | nombre del negocio |
| `description` | text | descripción libre |
| `owner_id` | bigint FK | referencia a `users` |
| `currency` | string | ej. `COP`, `USD` |

### Asociaciones

```ruby
belongs_to :owner, class_name: "User"
has_many :products
has_many :purchase_orders
has_many :sales_orders
has_many :inventories
has_many :role_assignments
```

---

## RoleAssignment

Tabla de unión entre `User` y `Business` que define el rol y módulos habilitados.

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `role` | string | `owner` / `manager` / `operator` / `viewer` |
| `assigned_modules` | string | módulos habilitados (ej. `"sales,purchases"`) |
| `restrictions` | text | restricciones adicionales (ej. monto máximo) |
| `status` | string | `active` / `suspended` |
| `assigned_at` | datetime | inicio de vigencia |
| `ended_at` | datetime | fin de vigencia (NULL si activo) |

### Enums

```ruby
ROLES = %w[owner manager operator viewer].freeze
```

**Índice único:** `(user_id, business_id, role)` — un usuario no puede tener el mismo rol dos veces en el mismo negocio.

---

## Product

Producto de un negocio. El precio es histórico (ver `ProductPrice`).

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `name` | string | nombre del producto |
| `description` | text | |
| `unit_measure` | string | `kg`, `unidad`, `litro`, etc. |
| `status` | string | `active` / `inactive` |

### Asociaciones

```ruby
belongs_to :business
has_many :product_prices
has_many :purchase_order_items
has_many :sales_order_items
has_one :inventory
```

---

## ProductPrice

Historial de precios de un producto. Permite trazabilidad de cambios sin afectar transacciones anteriores.

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `unit_price` | decimal | precio por unidad de medida |
| `price_type` | string | `purchase` / `sale` |
| `start_at` | date | inicio de vigencia |
| `end_at` | date | fin de vigencia (NULL si es el precio actual) |
| `note` | string | razón del cambio de precio |

---

## PurchaseOrder

Orden de compra de un negocio a un proveedor.

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `reference_number` | string | único por negocio |
| `supplier_name` | string | nombre del proveedor |
| `status` | string | ver enums |
| `received_at` | datetime | fecha real de recepción |
| `notes` | text | |

### Enums

```ruby
STATUSES = %w[pending received partial cancelled].freeze
```

### Asociaciones

```ruby
belongs_to :business
belongs_to :created_by, class_name: "User"
has_many :purchase_order_items
accepts_nested_attributes_for :purchase_order_items
```

---

## PurchaseOrderItem

Ítem de una orden de compra. `unit_price` es un **snapshot**: guarda el precio al momento de registrar la compra.

| Columna | Tipo | Notas |
|---------|------|-------|
| `quantity` | decimal | |
| `unit_price` | decimal | snapshot del precio de compra |
| `subtotal` | decimal | `quantity × unit_price` |
| `notes` | text | |

---

## SalesOrder

Orden de venta de un negocio a un cliente.

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `reference_number` | string | único por negocio |
| `customer_name` | string | |
| `customer_identifier` | string | cédula u otro identificador (opcional) |
| `payment_condition` | string | `cash` / `credit` |
| `payment_status` | string | ver enums |
| `payment_due_at` | datetime | vencimiento para ventas a crédito |
| `total` | decimal | suma de subtotales de ítems |

### Enums

```ruby
STATUSES           = %w[pending completed cancelled].freeze
PAYMENT_CONDITIONS = %w[cash credit].freeze
PAYMENT_STATUSES   = %w[pending partial paid cancelled].freeze
```

### Asociaciones

```ruby
belongs_to :business
belongs_to :created_by, class_name: "User"
has_many :sales_order_items
has_many :payments
accepts_nested_attributes_for :sales_order_items
```

---

## SalesOrderItem

Ítem de una venta. `unit_price` es snapshot; `discount` puede ser monto o porcentaje (a definir en la capa de servicio).

| Columna | Tipo | Notas |
|---------|------|-------|
| `quantity` | decimal | |
| `unit_price` | decimal | snapshot del precio de venta |
| `discount` | decimal | descuento aplicado |
| `subtotal` | decimal | neto tras descuento |

---

## Payment

Pago abonado contra una `SalesOrder`. Permite pagos parciales (abonos a cartera).

### Atributos clave

| Columna | Tipo | Notas |
|---------|------|-------|
| `amount` | decimal | monto del pago |
| `paid_at` | datetime | fecha efectiva del pago |
| `payment_method` | string | `cash` / `transfer` / `other` |
| `payment_type` | string | `deposit` / `settlement` / `refund` / `adjustment` |
| `payment_status` | string | `recorded` / `voided` |
| `notes` | text | |

### Asociaciones

```ruby
belongs_to :sales_order
belongs_to :recorded_by, class_name: "User"
```

---

## Inventory

Stock actual de un producto en un negocio. Hay exactamente un `Inventory` por `(business, product)`.

| Columna | Tipo | Notas |
|---------|------|-------|
| `current_quantity` | decimal | stock actual |
| `minimum_alert_quantity` | decimal | umbral de alerta de stock bajo |
| `last_updated_at` | datetime | última actualización de cantidad |

**Índice único:** `(business_id, product_id)`

---

## InventoryMovement

Auditoría completa de cada cambio de stock.

| Columna | Tipo | Notas |
|---------|------|-------|
| `previous_quantity` | decimal | cantidad antes del movimiento |
| `new_quantity` | decimal | cantidad después |
| `movement_type` | string | `purchase_entry` / `sale_exit` / `adjustment` / `other` |
| `reference_type` | string | polymorphic: `"PurchaseOrder"` / `"SalesOrder"` |
| `reference_id` | bigint | ID de la orden que generó el movimiento |
| `moved_at` | datetime | fecha del movimiento |
| `notes` | text | |
