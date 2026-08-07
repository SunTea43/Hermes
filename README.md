# Hermes — Sistema de Gestión Comercial para Pequeños Negocios

Hermes es una plataforma multi-tenant de gestión comercial diseñada para pequeños negocios (tiendas, distribuidoras, minimercados). Permite registrar compras, ventas, inventario y cartera **desde WhatsApp**, y administrar roles y ver reportes desde un **portal web**.

---

## ¿Qué problema resuelve?

Los dueños de pequeños negocios en Latinoamérica llevan sus operaciones en papel, cuadernos o grupos de WhatsApp. Hermes convierte WhatsApp en su sistema de gestión: el negocio opera naturalmente por el canal que ya conocen, sin curva de aprendizaje.

---

## Canales de interacción

| Canal | Propósito |
|-------|-----------|
| **WhatsApp Bot** | Registro operativo diario: ventas, compras, pagos, consultas de stock, resumen del día |
| **Portal Web** | Administración: roles, permisos, CRUDs, importación Excel/CSV de productos |

---

## Estado actual del proyecto

### Completado

- Proyecto Rails 8.1 + PostgreSQL, Devise, Pundit, Bootstrap 5
- CRUDs web: negocios, productos, inventarios, compras, ventas, pagos
- WhatsApp: webhook Meta (default) / Twilio, adapters, auth por tienda
- Skills de dominio con idempotencia y permisos por rol
- Handlers conversacionales con confirmación en escrituras
- Interpreter LLM opcional por tienda + evals
- Response renderer determinista
- Jobs: alerta de stock bajo y recordatorio de cartera

### Documentación WhatsApp

| Documento | Contenido |
|-----------|-----------|
| [docs/whatsapp-architecture.md](docs/whatsapp-architecture.md) | Arquitectura actual, Mermaids WhatsApp + web |
| [docs/whatsapp-skills.md](docs/whatsapp-skills.md) | Descripción de cada skill + ejemplos |
| [docs/whatsapp-bot.md](docs/whatsapp-bot.md) | Flujos conversacionales y configuración |
| [docs/whatsapp-business-authorization.md](docs/whatsapp-business-authorization.md) | Auth de tiendas y usuarios |
| [docs/whatsapp-agent-switching.md](docs/whatsapp-agent-switching.md) | Regex vs LLM |
| [docs/whatsapp-provider-switching.md](docs/whatsapp-provider-switching.md) | Meta vs Twilio |
| [docs/whatsapp-evals.md](docs/whatsapp-evals.md) | Suite de evals del interpreter |

### Pendiente / roadmap

- Skills adicionales: buscar productos, cartera detallada, ajuste de inventario
- Reportes contables exportables (PDF/Excel) en el portal
- Audio e imágenes en WhatsApp para armar borradores de compra/venta (STT + multimodal, confirmar/editar/cancelar) — plan en [docs/whatsapp-architecture.md](docs/whatsapp-architecture.md#plan-audio-e-imágenes-para-órdenes-compra--venta)

---

## Tech Stack

| Capa | Tecnología | Razón |
|------|------------|-------|
| **Backend** | Rails 8.1 (Ruby 3.x) | Velocidad de desarrollo, convenciones sólidas |
| **Base de datos** | PostgreSQL | ACID, JSON nativo |
| **Autenticación** | Devise | Sesiones y recuperación |
| **Autorización** | Pundit | Políticas por rol y recurso |
| **UI** | Bootstrap 5 + ViewComponent | UI responsive |
| **Jobs** | Solid Queue | Alertas programadas |
| **WhatsApp** | Meta Cloud API (default) / Twilio | Webhook + envío vía adapters |
| **LLM (opcional)** | OpenAI-compatible | Interpreter de intenciones por tienda |
| **Deploy** | Kamal / Railway / Render | Rails-friendly |

---

## Modelo de datos

Tablas principales:

```
users                    — email + whatsapp_phone
businesses               — multi-tenant (+ whatsapp_enabled, whatsapp_agent)
role_assignments         — rol + módulos + whatsapp_enabled por tienda
products / product_prices
purchase_orders / purchase_order_items
sales_orders / sales_order_items
payments
inventories / inventory_movements
whatsapp_message_audits
whatsapp_skill_executions  — idempotencia de skills de escritura
```

### Decisiones de diseño clave

- **Snapshot de precio en ítems:** el historial contable no cambia si el precio actual se actualiza.
- **Movimientos de inventario auditados:** cada cambio genera `inventory_movement`.
- **Skills como frontera WhatsApp:** handlers no escriben directo; invocan `Skills::Registry`.
- **Multi-tenant por negocio:** toda entidad operativa lleva `business_id`.

---

## Roles y permisos

| Rol | Descripción |
|-----|-------------|
| `owner` | Acceso total al negocio |
| `manager` | Compras, ventas, pagos, inventario |
| `operator` | Ventas/compras según `assigned_modules` |
| `viewer` | Solo lectura |

Detalle: [docs/autorizacion.md](docs/autorizacion.md).

---

## Setup de desarrollo

### Prerrequisitos

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 20+
- Yarn

### Instalación

```bash
git clone <repo>
cd hermes
bundle install
yarn install
bin/rails db:create db:migrate db:seed
bin/dev
```

App en `http://localhost:3000`.

### Variables de entorno (WhatsApp / LLM)

```bash
# Meta (default)
META_WHATSAPP_ACCESS_TOKEN=...
META_WHATSAPP_PHONE_NUMBER_ID=...
META_WHATSAPP_APP_SECRET=...
META_WHATSAPP_VERIFY_TOKEN=...

# Twilio (opcional)
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_WHATSAPP_NUMBER=whatsapp:+...

# Interpreter LLM (opcional)
OPENAI_API_KEY=...
```

Ver [docs/whatsapp-bot.md](docs/whatsapp-bot.md) y [docs/whatsapp-provider-switching.md](docs/whatsapp-provider-switching.md).

---

## Flujos principales

### WhatsApp — venta

```
Usuario: "Vendí 10kg de arroz a Don Julio"
Bot:     confirma ítems → contado/crédito → ¿Confirmo?
Usuario: "Sí"
Bot:     "✅ VEN-001 registrada. Stock: ..."
```

### WhatsApp — compra

```
Usuario: "Recibí de Juanito: arroz 50kg a $2,000"
Bot:     resumen → ¿Confirmo? → "✅ COM-001 ..."
```

### WhatsApp — reporte (mensaje)

```
Usuario: "Reporte del día"
Bot:     "📊 Resumen del día ... Ventas / Contado / Crédito / Cartera"
```

### Portal — catálogo (Excel/CSV)

Productos → Importar Excel → subir `.xlsx`/`.csv` o descargar plantilla CSV.

Más ejemplos y Mermaids: [docs/whatsapp-skills.md](docs/whatsapp-skills.md).

---

## Arquitectura de capas

```
Presentación     WhatsApp Bot  ←→  Portal Web
                        ↓
Aplicación       Webhook · Dispatch · Interpreter · Skills · Pundit
                        ↓
Dominio          Órdenes · Inventario · Pagos · Reportes
                        ↓
Datos            ActiveRecord · PostgreSQL
```

---

## Requisitos no funcionales

| Requisito | Objetivo |
|-----------|----------|
| Latencia bot | < 3 s por interacción |
| Consistencia | ACID en transacciones con dinero/stock |
| Idempotencia | Reintentos del proveedor no duplican órdenes |
| Aislamiento | Solo datos de tiendas autorizadas |
| Auditoría | Mensajes WhatsApp y movimientos de inventario trazables |
