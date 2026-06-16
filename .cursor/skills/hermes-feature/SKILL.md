---
name: hermes-feature
description: Implement a new feature in the Hermes Rails project following project conventions (Pundit policies, ViewComponent, Bootstrap, service objects, Rails tests). Use when the user asks to add a feature, implement an endpoint, create a new flow, or build something new in Hermes.
disable-model-invocation: true
---

# Hermes — Implementar una feature

## Stack de referencia

- **Rails 8.1** + PostgreSQL, Propshaft, Importmap
- **Auth:** Devise (`current_user`, `authenticate_user!`)
- **Authz:** Pundit (`authorize`, `policy_scope`, `verify_pundit_authorization`)
- **Forms:** SimpleForm + Bootstrap 5
- **UI:** ViewComponent (`CardComponent`, `PageHeaderComponent`)
- **Jobs:** Solid Queue (`ApplicationJob`)
- **Tests:** Rails Minitest (en `test/`)

## Workflow

Sigue este checklist en orden. Márcalo al inicio y actualízalo mientras avanzas.

```
- [ ] 1. Entender la feature y su alcance
- [ ] 2. Migración / cambios de esquema (si aplica)
- [ ] 3. Modelo(s) con validaciones y asociaciones
- [ ] 4. Policy Pundit
- [ ] 5. Service object (lógica de negocio)
- [ ] 6. Controller
- [ ] 7. Vistas (ERB + Bootstrap)
- [ ] 8. Rutas
- [ ] 9. Tests
- [ ] 10. Ejecutar tests y confirmar que pasan
```

---

## 1. Entender el alcance

Antes de escribir código, responde:
- ¿Qué entidades se crean, modifican o consultan?
- ¿Qué roles pueden hacer esta acción?
- ¿Se necesita migración?
- ¿Hay lógica de negocio compleja (cálculos, side-effects en inventario, etc.)?

---

## 2. Migración

Si se necesitan cambios en el esquema:

```bash
bin/rails generate migration AddXxxToYyy column:type
bin/rails db:migrate
```

Revisar `db/schema.rb` tras migrar.

---

## 3. Modelo

Convenciones obligatorias:

```ruby
class MiModelo < ApplicationRecord
  # Constantes de enum al inicio
  STATUSES = %w[active inactive].freeze

  # Asociaciones
  belongs_to :business
  belongs_to :created_by, class_name: "User", optional: true

  # Validaciones
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
end
```

---

## 4. Policy Pundit

Cada recurso nuevo necesita su policy. Sin ella, todos los actions fallarán.

```ruby
# app/policies/mi_modelo_policy.rb
class MiModeloPolicy < ApplicationPolicy
  def index?   = can_access_business?
  def show?    = can_access_business?
  def create?  = owner_or_manager?
  def update?  = owner_or_manager?
  def destroy? = user.owns?(record.business)

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(business: accessible_businesses)
    end

    private

    def accessible_businesses
      Business.where(owner: user).or(
        Business.joins(:role_assignments).where(
          role_assignments: { user: user, status: "active" }
        )
      )
    end
  end

  private

  def business = record.business
end
```

Ajustar permisos según la matriz de roles del proyecto (ver `docs/autorizacion.md`).

---

## 5. Service object (si hay lógica de negocio)

Para operaciones con side-effects (actualizar inventario, calcular totales, enviar notificaciones):

```ruby
# app/services/mi_modelos/create_service.rb
module MiModelos
  class CreateService
    def initialize(params, business:, user:)
      @params   = params
      @business = business
      @user     = user
    end

    def call
      ActiveRecord::Base.transaction do
        record = MiModelo.create!(@params.merge(business: @business, created_by: @user))
        # side-effects aquí
        record
      end
    end
  end
end
```

---

## 6. Controller

```ruby
class MiModelosController < ApplicationController
  before_action :set_mi_modelo, only: %i[show edit update destroy]

  def index
    @mi_modelos = policy_scope(MiModelo)
  end

  def show    = authorize @mi_modelo
  def new
    @mi_modelo = MiModelo.new
    authorize @mi_modelo
  end

  def create
    @mi_modelo = MiModelo.new(mi_modelo_params)
    authorize @mi_modelo
    if @mi_modelo.save
      redirect_to @mi_modelo, notice: "Creado exitosamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit    = authorize @mi_modelo
  def update
    authorize @mi_modelo
    if @mi_modelo.update(mi_modelo_params)
      redirect_to @mi_modelo, notice: "Actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @mi_modelo
    @mi_modelo.destroy!
    redirect_to mi_modelos_path, notice: "Eliminado.", status: :see_other
  end

  private

  def set_mi_modelo = @mi_modelo = MiModelo.find(params[:id])
  def mi_modelo_params = params.expect(mi_modelo: [:name, :status, :business_id])
end
```

---

## 7. Vistas

Usar `PageHeaderComponent` y `CardComponent` consistentemente:

**index.html.erb**
```erb
<% content_for :title, "Mi Módulo" %>
<%= render PageHeaderComponent.new(title: "Mi Módulo") do %>
  <%= link_to "+ Nuevo", new_mi_modelo_path, class: "btn btn-primary" %>
<% end %>
```

**_form.html.erb**
```erb
<%= simple_form_for @mi_modelo do |f| %>
  <%= f.input :name %>
  <%= f.input :status, collection: MiModelo::STATUSES %>
  <%= f.submit class: "btn btn-primary" %>
<% end %>
```

---

## 8. Rutas

Agregar a `config/routes.rb`:

```ruby
resources :mi_modelos
```

O anidado si corresponde:

```ruby
resources :businesses do
  resources :mi_modelos, shallow: true
end
```

---

## 9. Tests

### Modelo

```ruby
# test/models/mi_modelo_test.rb
require "test_helper"

class MiModeloTest < ActiveSupport::TestCase
  test "valid with required fields" do
    record = MiModelo.new(name: "Test", business: businesses(:one), status: "active")
    assert record.valid?
  end

  test "invalid without name" do
    record = MiModelo.new(business: businesses(:one), status: "active")
    assert_not record.valid?
    assert_includes record.errors[:name], "can't be blank"
  end

  test "invalid status rejects unknown values" do
    record = MiModelo.new(name: "Test", business: businesses(:one), status: "invalid")
    assert_not record.valid?
  end
end
```

### Controller

```ruby
# test/controllers/mi_modelos_controller_test.rb
require "test_helper"

class MiModelosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user      = users(:owner)
    @mi_modelo = mi_modelos(:one)
    sign_in @user
  end

  test "GET index" do
    get mi_modelos_url
    assert_response :success
  end

  test "GET show" do
    get mi_modelo_url(@mi_modelo)
    assert_response :success
  end

  test "POST create with valid params" do
    assert_difference("MiModelo.count") do
      post mi_modelos_url, params: { mi_modelo: { name: "Nuevo", status: "active", business_id: businesses(:one).id } }
    end
    assert_redirected_to mi_modelo_url(MiModelo.last)
  end

  test "POST create with invalid params" do
    assert_no_difference("MiModelo.count") do
      post mi_modelos_url, params: { mi_modelo: { name: "" } }
    end
    assert_response :unprocessable_content
  end
end
```

Agregar fixtures en `test/fixtures/mi_modelos.yml`:

```yaml
one:
  name: Fixture One
  status: active
  business: one
```

---

## 10. Ejecutar tests y confirmar

Al terminar, ejecutar:

```bash
bin/rails test test/models/mi_modelo_test.rb test/controllers/mi_modelos_controller_test.rb
```

Si todos pasan:

```bash
bin/rails test
```

**Criterio de aceptación:**
- 0 failures, 0 errors
- `bin/rails routes | grep mi_modelo` muestra las rutas esperadas
- La app corre sin errores: `bin/rails runner "puts MiModelo.count"`

Confirmar al usuario con el output de los tests antes de cerrar.
