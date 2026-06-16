---
name: develop-feature
description: Build a feature in the Hermes project based on technical specifications. Use when the user provides specs for a new feature, flow, endpoint, or module to implement.
disable-model-invocation: true
---

# develop-feature

El usuario proveerá las especificaciones técnicas. Lee el código existente para entender el contexto y construye lo que corresponda.

## Workflow

Crea este checklist al inicio y actualízalo mientras avanzas:

```
- [ ] Leer specs y determinar qué hay que construir
- [ ] Crear worktree para desarrollo en paralelo (/parallel-development)
- [ ] Migración (si el schema cambia)
- [ ] Modelo(s) y asociaciones
- [ ] Policy Pundit (si el recurso requiere autorización)
- [ ] Lógica de negocio (service object si hay side-effects)
- [ ] Controller y rutas
- [ ] Vistas
- [ ] Tests
- [ ] Ejecutar tests — confirmar que pasan
```

---

## Políticas Pundit

Si la feature expone un recurso a través de un controller, **siempre** crea la policy correspondiente. Sin ella, `verify_pundit_authorization` fallará en todos los actions.

La policy va en `app/policies/<recurso>_policy.rb` y debe implementar:
- Cada action del controller (`index?`, `show?`, `create?`, `update?`, `destroy?`, y cualquier action custom)
- `Scope#resolve` para filtrar colecciones por negocio/usuario

Basarse en los roles y la lógica existente en `ApplicationPolicy` y `User`.

---

## Tests

Por cada feature, incluir tests que demuestren que funciona:

- **Modelos:** validaciones, asociaciones, métodos de instancia
- **Controllers:** cada action — éxito, parámetros inválidos, y casos de autorización (acceso denegado)
- **Service objects:** el flujo principal y los casos de error

Al terminar, ejecutar:

```bash
bin/rails test
```

Mostrar el output completo antes de cerrar. La feature está lista solo cuando el resultado es **0 failures, 0 errors**.
