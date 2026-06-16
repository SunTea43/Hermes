# Hermes — Sistema de Gestión Comercial para Pequeños Negocios

Hermes es una plataforma multi-tenant de gestión comercial diseñada para pequeños negocios (tiendas, distribuidoras, minimercados). Permite registrar compras, ventas, inventario y cartera **desde WhatsApp**, y administrar roles y ver reportes contables desde un **portal web**.

---

## ¿Qué problema resuelve?

Los dueños de pequeños negocios en Latinoamérica llevan sus operaciones en papel, cuadernos o grupos de WhatsApp. Hermes convierte WhatsApp en su sistema de gestión: el negocio opera naturalmente por el canal que ya conocen, sin curva de aprendizaje.

---

## Canales de interacción

| Canal | Propósito |
|-------|-----------|
| **WhatsApp Bot** | Registro operativo diario: ventas, compras, pagos, consultas de stock |
| **Portal Web** | Administración: roles, permisos, reportes contables, exportación |

---

## Estado actual del proyecto — Fase 2

### ✅ Fase 1: Setup (completa)

- Proyecto Rails 8.1 inicializado con PostgreSQL
- Autenticación con Devise (`User` con `whatsapp_phone` único)
- Autorización con Pundit (políticas por rol y negocio)
- Esquema completo de base de datos (11 tablas migradas)
- Todos los modelos con sus asociaciones
- UI base: Bootstrap 5 + ViewComponent
- Background jobs con Solid Queue

### 🔄 Fase 2: Módulo de Ventas (en progreso)

- [x] Modelos `SalesOrder` y `SalesOrderItem` con nested attributes
- [x] CRUD completo: controllers + views para ventas, compras, pagos, productos, inventario
- [x] Navbar con secciones: Negocios, Productos, Compras, Ventas, Inventario
- [ ] Webhook de WhatsApp (integración Twilio)
- [ ] Parser de lenguaje natural (intenciones de venta/compra)
- [ ] Actualización automática de inventario al registrar venta/compra
- [ ] Flujos conversacionales con confirmación

### Pendiente (fases 3–6)

- Fase 3: Alertas de stock bajo
- Fase 4: Cartera / ventas a crédito y registro de pagos desde WhatsApp
- Fase 5: Reportes (dashboard diario, rentabilidad, cartera)
- Fase 6: OCR de recibos desde imágenes de WhatsApp

---

## Tech Stack

| Capa | Tecnología | Razón |
|------|------------|-------|
| **Backend** | Rails 8.1.2 (Ruby 3.x) | Velocidad de desarrollo, convenciones sólidas |
| **Base de datos** | PostgreSQL | ACID, JSON nativo, full-text search |
| **Autenticación** | Devise | Estándar Rails, manejo de sesiones y recuperación |
| **Autorización** | Pundit | Políticas granulares por rol y recurso |
| **UI** | Bootstrap 5 + ViewComponent | Componentes reutilizables, UI responsive |
| **Forms** | simple_form | Formularios más limpios con Bootstrap |
| **Jobs** | Solid Queue + Solid Cable | Alertas programadas, WebSockets |
| **WhatsApp** | Twilio (próximo) | Webhook + envío de mensajes |
| **OCR** | Google Cloud Vision / Tesseract (futuro) | Extracción de datos desde fotos de recibos |
| **Deploy** | Kamal / Railway / Render | Rails-friendly, escalable |

---

## Modelo de datos

El esquema está completamente migrado. Las 11 tablas principales:

```
users              — Usuarios del sistema (autenticados por email + whatsapp_phone)
businesses         — Negocios (multi-tenant, cada negocio es independiente)
role_assignments   — Asignación de rol (owner/manager/operator/viewer) por negocio
products           — Productos de un negocio
product_prices     — Historial de precios de compra/venta por producto
purchase_orders    — Órdenes de compra (proveedor → negocio)
purchase_order_items — Ítems de una orden de compra (snapshot de precio)
sales_orders       — Órdenes de venta (negocio → cliente)
sales_order_items  — Ítems de una orden de venta (snapshot de precio + descuento)
payments           — Pagos abonados contra una orden de venta
inventories        — Stock actual + alerta mínima por producto/negocio
inventory_movements — Auditoría completa de movimientos de inventario
```

### Decisiones de diseño clave

- **Snapshot de precio en ítems:** `unit_price` se guarda al momento de crear el ítem, no referencia el precio actual. Esto garantiza que historial contable sea inmutable.
- **Historial de precios separado:** `product_prices` con `start_at`/`end_at` permite ver precio histórico sin afectar transacciones pasadas.
- **Movimientos de inventario auditados:** cada cambio de stock genera un `inventory_movement` con cantidad anterior, nueva, tipo y usuario responsable.
- **Multi-tenant por negocio:** toda entidad operativa (órdenes, productos, inventario) está asociada a un `business_id`. Los usuarios acceden solo a los negocios donde tienen asignación activa.

---

## Roles y permisos

| Rol | Descripción |
|-----|-------------|
| `owner` | Propietario del negocio. Acceso total: crear gestores, cambiar precios, ver todos los reportes, eliminar registros. |
| `manager` | Gestor. Puede registrar compras, ventas, pagos y actualizar inventario. No puede eliminar ni cambiar precios globales. |
| `operator` | Operario. Puede registrar ventas y compras (según módulos asignados). No puede ver reportes financieros ni gestionar cartera. |
| `viewer` | Solo lectura. Accede únicamente a los reportes que le sean asignados. |

La autorización se implementa con **Pundit**. Cada policy consulta el rol del usuario en el negocio en cuestión mediante `User#role_for(business)` y `User#owner_or_manager_for?(business)`.

---

## Estructura del proyecto

```
hermes/
├── app/
│   ├── models/              # Entidades de dominio
│   ├── controllers/         # API REST + WhatsApp webhook (próximo)
│   ├── views/               # ERB con Bootstrap 5
│   ├── policies/            # Autorización Pundit por recurso
│   ├── components/          # ViewComponents (CardComponent, PageHeaderComponent)
│   ├── jobs/                # Background jobs (alertas, notificaciones)
│   └── services/            # Lógica de negocio desacoplada (próximo)
├── db/
│   ├── migrate/             # 14 migraciones versionadas
│   ├── schema.rb            # Estado actual del esquema
│   └── seeds.rb
├── config/
│   ├── routes.rb            # Recursos REST + Devise
│   └── recurring.yml        # Jobs programados (Solid Queue)
└── architecture.md          # Diseño de dominio y flujos
```

---

## Setup de desarrollo

### Prerrequisitos

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 20+ (para assets)
- Yarn

### Instalación

```bash
# Clonar e instalar dependencias
git clone <repo>
cd hermes
bundle install
yarn install

# Base de datos
bin/rails db:create db:migrate

# Servidor de desarrollo
bin/dev
```

La app estará disponible en `http://localhost:3000`.

### Variables de entorno

Crear `config/application.yml` o usar `credentials`:

```yaml
# Próximas integraciones
TWILIO_ACCOUNT_SID: "..."
TWILIO_AUTH_TOKEN: "..."
TWILIO_WHATSAPP_NUMBER: "whatsapp:+1234567890"
GCP_PROJECT_ID: "..."   # para OCR con Google Vision
```

---

## Flujos principales (WhatsApp — próximo)

### Registrar una venta

```
Usuario: "Vendí 10kg de arroz a Don Julio"
Bot:     "Don Julio. 10kg arroz × $2,000 = $20,000. ¿Contado o crédito?"
Usuario: "A crédito, cobra el viernes"
Bot:     "✅ Venta registrada VEN-001. Stock: 50kg → 40kg. Pendiente cobro: $20,000"
```

### Consultar inventario

```
Usuario: "¿Qué está bajo?"
Bot:     "⚠️ Aceite: 3L (mínimo 10L), Sal: 2kg (mínimo 5kg)"
```

### Registrar un pago

```
Usuario: "Don Julio pagó $10,000"
Bot:     "Abono registrado. Saldo pendiente Don Julio: $10,000 (vence viernes)"
```

---

## Reportes planificados

| Reporte | Disponible en |
|---------|--------------|
| Dashboard diario (ventas, compras, cartera) | WhatsApp + Web |
| Estado de cartera (clientes con deuda) | WhatsApp + Web |
| Análisis de inventario (stock, rotación) | Web |
| Rentabilidad por producto | Web |
| Movimientos mensuales | Web |
| Auditoría y trazabilidad | Web |
| Vista contable (P&L simplificado, flujo de caja) | Web (PDF/Excel) |

---

## Arquitectura de capas

```
Presentación     WhatsApp Bot Interface  ←→  Portal Web (Bootstrap)
                         ↓
Aplicación       Parser NLP · Webhook handler · API REST · Auth
                         ↓
Lógica negocio   Validaciones · Cálculos · Alertas · Reportes
                         ↓
Datos            ActiveRecord · Consultas · Transacciones ACID
                         ↓
Base de datos    PostgreSQL
```

---

## Requisitos no funcionales

| Requisito | Objetivo |
|-----------|----------|
| Disponibilidad | 99.5% |
| Latencia bot | < 3 segundos por interacción |
| Consistencia | ACID para transacciones con dinero |
| Auditoría | Cada cambio registra usuario, fecha y acción |
| Aislamiento | Cada usuario ve solo datos de sus negocios |
| Escala | 50–100 usuarios por negocio, múltiples negocios |
