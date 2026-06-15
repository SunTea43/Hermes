# Stack Tecnológico Recomendado - Proyecto Hermes

## Análisis de Contexto

**Tu perfil:**
- Experiencia: Ruby on Rails (full-stack)
- Capacidad: Desarrollo rápido, prototipado, arquitectura limpia

**Perfil de tu socio:**
- Experiencia: Cero profesional
- Rol: Conseguir clientes, no desarrollar
- Requerimiento: Curva de aprendizaje mínima si algún día contribuye

**Meta del MVP:**
- Tiempo: Semanas, no meses
- Alcance: Módulo de ventas + inventario + reportes básicos
- Escalabilidad: Eventual (no es crítica en MVP)

---

## Recomendación Principal: Ruby on Rails

### Por qué Rails es la opción óptima

#### ✅ **Ventajas para ti**
1. **Máxima velocidad de desarrollo** - Rails está optimizado para iteración rápida
   - Scaffolds automáticos de modelos/vistas/controladores
   - Migraciones de BD versadas
   - Helpers y validaciones incorporadas
2. **Ecosistema robusto** - Gemas consolidadas para cada requisito
   - WhatsApp: `twilio-ruby` (webhook + sending)
   - OCR: `google-cloud-vision` o `tesseract`
   - Reportes: `prawn` o `wicked_pdf`
   - Autenticación: `devise` (roles + permisos)
3. **Base de datos integrada** - ActiveRecord abstrae SQL, migraciones automáticas
4. **Testing nativo** - RSpec o Minitest ya configurados
5. **Despliegue simple** - Heroku, Render, Railway (Rails-friendly)

#### ✅ **Ventajas para el socio (si participa después)**
1. **Legibilidad** - Rails es "opinionado y explícito"
   - Convenciones sobre configuración = menos magia
   - Carpetas organizadas por función (models, views, controllers)
2. **Documentación extensa** - Comunidad grande = muchos tutoriales
3. **Curva suave para aprender** - Si necesita ajustar flujos, es comprensible

#### ❌ **Desventajas**
1. Overhead de servidor (vs Node/FastAPI) - No relevante para MVP
2. Startup lento (~5s primer request) - Aceptable para chat
3. Requiere Ruby + Bundler en producción - Pero simple de desplegar

---

## Stack Completo Recomendado

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend                             │
│  Rails Views (ERB) o minimal React (solo reportes)      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                  Backend API                            │
│  Rails 7+ con ActionMailer + ActionCable (websockets)   │
│  Autenticación: Devise (usuarios/roles)                 │
│  Autorización: Pundit (permisos por rol)                │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Integración WhatsApp                        │
│  Twilio API + twilio-ruby (webhook + sending)           │
│  O Meta WhatsApp Cloud API (si prefieres)               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Procesamiento Multimodal                    │
│  Google Cloud Vision (OCR de recibos)                   │
│  O Tesseract (OCR local, sin costo)                     │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Base de Datos                              │
│  PostgreSQL (confiable, JSON nativo para alertas)       │
└─────────────────────────────────────────────────────────┘
```

---

## Detalles Técnicos por Capas

### 1. Backend - Rails 7+

```ruby
# Gemfile
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"
rails "~> 7.1.0"

# Base de datos
gem "pg"

# Autenticación y roles
gem "devise"
gem "pundit"

# WhatsApp
gem "twilio-ruby"

# OCR
gem "google-cloud-vision"
# O alternativa local:
# gem "ruby-vips"
# gem "tesseract-ocr"

# Reportes PDF
gem "prawn"

# Background jobs (alertas, reportes programados)
gem "sidekiq"
gem "sidekiq-cron"

# API JSON
gem "active_model_serializers"

# Validaciones
gem "validates_timeliness"

# Development
group :development do
  gem "web-console"
  gem "listen"
end

# Test
group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
end
```

**Estructura de carpetas:**
```
hermes/
├── app/
│   ├── models/              # Entidades (Usuario, Producto, Orden, etc)
│   ├── controllers/         # API + WhatsApp webhook
│   ├── services/            # Lógica de negocio (compra, venta, fiado)
│   ├── policies/            # Autorización (Pundit)
│   ├── jobs/                # Background: alertas, reportes
│   └── mailers/
├── db/
│   ├── migrate/             # Migraciones (schema)
│   └── seeds.rb
├── spec/                    # Tests RSpec
├── config/
│   └── database.yml
└── Gemfile
```

### 2. Base de Datos - PostgreSQL

**Por qué PostgreSQL:**
- ACID transacciones (crítico para dinero)
- JSON nativo (para alertas, configuración por usuario)
- Full-text search (búsqueda de productos)
- Arrays (múltiples teléfonos por usuario)
- Migrations versionadas en Rails

**Ejemplo schema:**
```sql
CREATE TABLE usuarios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255),
  telefono_whatsapp VARCHAR(20) UNIQUE,
  rol VARCHAR(50), -- owner, manager, operator
  id_negocio BIGINT REFERENCES negocios(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE productos (
  id BIGSERIAL PRIMARY KEY,
  id_negocio BIGINT REFERENCES negocios(id),
  nombre VARCHAR(255),
  unidad_medida VARCHAR(50),
  created_at TIMESTAMP
);

CREATE TABLE precios_producto (
  id BIGSERIAL PRIMARY KEY,
  id_producto BIGINT REFERENCES productos(id),
  precio_unitario DECIMAL(10,2),
  tipo_precio VARCHAR(20), -- compra, venta
  fecha_vigencia_inicio DATE,
  fecha_vigencia_fin DATE,
  created_at TIMESTAMP
);

CREATE TABLE ordenes_venta (
  id BIGSERIAL PRIMARY KEY,
  id_negocio BIGINT REFERENCES negocios(id),
  numero_referencia VARCHAR(50) UNIQUE,
  cliente_nombre VARCHAR(255),
  condicion_pago VARCHAR(50), -- contado, fiado
  total DECIMAL(12,2),
  estado VARCHAR(50), -- completada, pendiente, fiada
  created_at TIMESTAMP
);

-- Similar para compras, fiados, inventario, etc.
```

### 3. Integración WhatsApp - Twilio

**Flujo:**
```
Usuario envía mensaje a +1234567890
    ↓
Twilio webhook → POST /webhooks/whatsapp
    ↓
Rails recibe y parsea mensaje
    ↓
Lógica de negocio procesa orden
    ↓
Rails responde vía Twilio API
    ↓
Usuario recibe respuesta en WhatsApp
```

**Código esquelético:**
```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def whatsapp
    incoming_message = params[:Body]
    sender_phone = params[:From]
    
    user = Usuario.find_by(telefono_whatsapp: sender_phone)
    
    # Parser de intención
    case incoming_message.downcase
    when /vend[ií]/
      handle_venta(user, incoming_message)
    when /compra?/
      handle_compra(user, incoming_message)
    when /inventario/
      handle_inventario(user)
    when /reporte/
      handle_reporte(user)
    else
      enviar_menu_principal(user)
    end
    
    render plain: ""
  end

  private

  def enviar_whatsapp(phone, message)
    client = Twilio::REST::Client.new
    client.messages.create(
      from: "whatsapp:+1234567890",
      to: "whatsapp:#{phone}",
      body: message
    )
  end
end
```

### 4. Procesamiento de Imágenes - OCR

**Opción 1: Google Cloud Vision (recomendado para MVP)**
```ruby
# app/services/ocr_service.rb
class OcrService
  def self.extract_from_image(image_url)
    require "google/cloud/vision"
    
    vision = Google::Cloud::Vision.new(project_id: ENV['GCP_PROJECT_ID'])
    image = vision.image(image_url)
    
    text = vision.text_detection(image)[0].description
    parse_receipt(text)
  end

  private

  def self.parse_receipt(text)
    # Regex para extraer: producto, cantidad, precio
    lines = text.split("\n")
    items = []
    
    lines.each do |line|
      # Patrón: "Arroz 50kg - $50000"
      if match = line.match(/(.+?)\s+(\d+(?:\.?\d+)?)\s*([a-z]+).*?(\d+[.,]\d+)/)
        items << {
          producto: match[1].strip,
          cantidad: match[2],
          unidad: match[3],
          precio: match[4]
        }
      end
    end
    
    items
  end
end
```

**Opción 2: Tesseract (OCR local, sin costo)**
```ruby
# Gemfile
gem "tesseract-ocr"

# app/services/ocr_service.rb
require "tesseract"

class OcrService
  def self.extract_from_image(image_path)
    client = Tesseract::Engine.new { |e|
      e.language = :spa  # Español
    }
    
    text = client.text_from_image(image_path)
    parse_receipt(text)
  end
end
```

### 5. Reportes - Prawn (PDF)

```ruby
# app/services/reporte_service.rb
class ReporteService
  def self.dashboard_diario(negocio, fecha)
    Prawn::Document.generate("dashboard_#{fecha}.pdf") do |pdf|
      pdf.text "Dashboard - #{fecha}", size: 20, style: :bold
      
      ventas = negocio.ordenes_venta.where('DATE(created_at) = ?', fecha).sum(:total)
      compras = negocio.ordenes_compra.where('DATE(created_at) = ?', fecha).sum(:total)
      fiados = negocio.ordenes_venta.where(condicion_pago: 'fiado', 'DATE(created_at) = ?', fecha).sum(:total)
      
      pdf.text "Ventas: $#{ventas}", size: 14
      pdf.text "Compras: $#{compras}", size: 14
      pdf.text "Fiados nuevos: $#{fiados}", size: 14
    end
  end
end
```

### 6. Background Jobs - Sidekiq + Cron

```ruby
# app/jobs/alertas_inventario_job.rb
class AlertasInventarioJob
  include Sidekiq::Job
  
  def perform
    Negocio.all.each do |negocio|
      negocio.inventarios.where('cantidad_actual < cantidad_minima_alerta').each do |inv|
        mensaje = "⚠️ #{inv.producto.nombre}: #{inv.cantidad_actual}#{inv.producto.unidad_medida} (mínimo: #{inv.cantidad_minima_alerta})"
        EnviarWhatsappJob.perform_async(negocio.propietario.telefono_whatsapp, mensaje)
      end
    end
  end
end

# config/sidekiq.yml
:cron:
  alertas_inventario:
    cron: '0 8 * * *'  # Diario a las 8am
    class: AlertasInventarioJob
```

---

## Alternativas Consideradas

### Node.js + Express
**Pros:** Más rápido (startup), JavaScript en frontend y backend  
**Contras:** Menos maduro para transacciones, más boilerplate, más opciones = más decisiones  
**Veredicto:** No recomendado para MVP de negocio con dinero

### FastAPI (Python)
**Pros:** Muy rápido, moderno, bueno para OCR/ML  
**Contras:** Menos convenciones, menos gemas de negocio consolidadas  
**Veredicto:** Viable pero más overhead inicial

### Django (Python)
**Pros:** Similar a Rails, ORM robusto, admin incorporado  
**Contras:** Tu experiencia es Rails, no Django  
**Veredicto:** Más curva de aprendizaje para ti

---

## Plan de MVP - Fases

### **Fase 1: Setup (1-2 semanas)**
- [ ] Crear proyecto Rails con `rails new hermes --database=postgresql`
- [ ] Configurar devise (autenticación)
- [ ] Configurar pundit (roles/permisos)
- [ ] Crear modelos: Usuario, Negocio, Producto, Inventario
- [ ] Crear BD con migraciones
- [ ] Tests RSpec básicos

### **Fase 2: Módulo Ventas (2-3 semanas)**
- [ ] Modelo: Orden_Venta, Items_Orden_Venta
- [ ] API REST para crear órdenes
- [ ] Webhook WhatsApp básico (parse texto)
- [ ] Respuestas conversacionales
- [ ] Actualizar inventario automático

### **Fase 3: Inventario (1 semana)**
- [ ] Modelo: Inventario, Movimientos_Inventario
- [ ] Alertas cuando stock < mínimo
- [ ] Dashboard de stock

### **Fase 4: Fiados (1 semana)**
- [ ] Modelo: Transacciones_Fiado, Pagos_Fiado
- [ ] Registrar fiados y pagos desde WhatsApp
- [ ] Reporte de deudores

### **Fase 5: Reportes (1 semana)**
- [ ] Dashboard diario (PDF)
- [ ] Reporte de fiados pendientes
- [ ] Reporte de rentabilidad por producto

### **Fase 6: OCR + Multimodal (1 semana, opcional para MVP)**
- [ ] Recibir imágenes en WhatsApp
- [ ] Extrar datos con Tesseract
- [ ] Crear orden automáticamente con confirmación

**Total: 7-9 semanas para MVP completo**

---

## Infraestructura Recomendada

### Base de datos
- **Local dev:** PostgreSQL con Homebrew
- **Staging/Prod:** Railway o Render (PostgreSQL managed)

### Backend
- **Local:** `rails s` (WEBrick)
- **Prod:** Railway, Render o Heroku
  - Escalado automático
  - SSL incluido
  - Sidekiq para jobs

### WhatsApp
- **Twilio:** $0.0075/SMS + costo de número
- **Meta Cloud API:** Más barato pero integración más compleja

### Storage de imágenes
- **Dev:** Carpeta local
- **Prod:** AWS S3 o Google Cloud Storage (con gem `aws-sdk-s3`)

---

## Resumen de Decisiones

| Componente | Opción | Razón |
|-----------|--------|-------|
| **Backend** | Rails 7+ | Tu experiencia + velocidad |
| **BD** | PostgreSQL | ACID + JSON + migraciones Rails |
| **Autenticación** | Devise | Consolidada, roles nativos |
| **Autorización** | Pundit | Granular, mantenible |
| **WhatsApp** | Twilio | Setup rápido, documentación |
| **OCR** | Tesseract | Gratis, local, sin deps externas |
| **Reportes** | Prawn | Simple, PDFs nativos en Rails |
| **Jobs** | Sidekiq + Cron | Alertas automáticas, probado |
| **Hosting** | Railway/Render | Rails-friendly, barato, escalable |

---

## Próximos Pasos

1. **Crear proyecto Rails:**
   ```bash
   rails new hermes --database=postgresql --css=bootstrap --skip-action-mailer
   ```

2. **Instalar gemas principales:**
   ```bash
   bundle add devise pundit twilio-ruby google-cloud-vision prawn sidekiq
   ```

3. **Configurar estructura inicial:**
   - Devise: `rails generate devise:install`
   - Modelos base: `rails generate model Usuario` (+ asociaciones)
   - Tests: `rails generate rspec:install`

4. **Crear documento de API** (endpoints WhatsApp)

5. **Prototipo conversacional** (flujos de texto plano primero, OCR después)

¿Quieres que empecemos con los pasos concretos?
