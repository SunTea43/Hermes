# Autorización — Pundit

Hermes usa [Pundit](https://github.com/varvet/pundit) para controlar el acceso a recursos. Este documento describe el modelo de autorización y cómo extenderlo.

---

## Principio general

El acceso a cualquier recurso depende de dos condiciones:

1. **¿El usuario pertenece al negocio?** — verificado con `User#can_access_business?`
2. **¿El rol del usuario es suficiente?** — verificado con `User#role_for(business)`

La combinación de ambas se encapsula en `ApplicationPolicy`:

```ruby
def can_access_business?
  user.can_access_business?(business)
end

def owner_or_manager?
  user.owner_or_manager_for?(business)
end
```

Cada policy concreta define `business` retornando `record.business` (o `record` si el recurso ES el negocio).

---

## ApplicationController

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  after_action :verify_pundit_authorization   # falla si el controller no llamó authorize/policy_scope

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
end
```

El `after_action :verify_pundit_authorization` garantiza que ningún action quede sin autorización — si alguien añade un action y olvida `authorize`, el test lo captura.

---

## Matriz de permisos por acción

| Acción | Owner | Manager | Operator | Viewer |
|--------|-------|---------|----------|--------|
| `index?` | ✓ | ✓ | ✓ | ✓ |
| `show?` | ✓ | ✓ | ✓ | ✓* |
| `create?` | ✓ | ✓ | ✓** | ✗ |
| `update?` | ✓ | ✓ | ✗ | ✗ |
| `destroy?` | ✓ | ✗ | ✗ | ✗ |
| Cambiar precios | ✓ | ✗ | ✗ | ✗ |
| Asignar roles | ✓ | ✗ | ✗ | ✗ |
| Venta a crédito | ✓ | ✓ | ✗ | ✗ |
| Registrar pagos | ✓ | ✓ | ✗ | ✗ |

*Solo reportes asignados  
**Solo módulos asignados

---

## Cómo crear una nueva policy

```ruby
# app/policies/sales_order_policy.rb
class SalesOrderPolicy < ApplicationPolicy
  def index?   = can_access_business?
  def show?    = can_access_business?
  def create?  = owner_or_manager? || operator_with_module?("sales")
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

  def operator_with_module?(mod)
    assignment = user.role_assignments.find_by(business: business, status: "active")
    return false unless assignment
    assignment.assigned_modules.to_s.split(",").map(&:strip).include?(mod)
  end
end
```

---

## Pundit en controllers

```ruby
# En un action de colección:
def index
  @sales_orders = policy_scope(SalesOrder)
end

# En actions de instancia:
def show
  @sales_order = SalesOrder.find(params[:id])
  authorize @sales_order
end

def create
  @sales_order = SalesOrder.new(sales_order_params)
  authorize @sales_order        # evalúa create? con record sin persistir
  @sales_order.save
end
```

---

## Testing de policies

```ruby
# test/policies/sales_order_policy_test.rb
require "test_helper"

class SalesOrderPolicyTest < ActiveSupport::TestCase
  def setup
    @business = businesses(:tienda)
    @owner    = users(:owner)
    @manager  = users(:manager)
    @operator = users(:operator)
    @viewer   = users(:viewer)
    @order    = sales_orders(:order_one)
  end

  test "owner can destroy" do
    assert SalesOrderPolicy.new(@owner, @order).destroy?
  end

  test "manager cannot destroy" do
    refute SalesOrderPolicy.new(@manager, @order).destroy?
  end

  test "viewer cannot create" do
    refute SalesOrderPolicy.new(@viewer, SalesOrder.new(business: @business)).create?
  end
end
```
