---
name: validate-pr-ci
description: >-
  Valida y corrige los pipelines de GitHub Actions al crear o actualizar un PR
  en Hermes. Usa cuando el usuario mencione CI, pipelines, checks del PR,
  Actions fallidos, brakeman, bundler-audit, rubocop, importmap audit, tests
  o system tests, o pida dejar el PR verde antes del merge.
disable-model-invocation: true
---

# validate-pr-ci

Valida qué corre en CI al abrir un PR, reproduce los fallos en local y aplica las correcciones pertinentes hasta que los checks queden verdes.

Fuente de verdad del pipeline de PR: [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml).

Detalle por job, comandos y patrones de error: [reference.md](reference.md).

## Cuándo usarlo

- Antes o justo después de abrir un PR (`gh pr create`)
- Cuando un check de Actions falla en el PR
- Como cierre de `/develop-feature` / `/parallel-development` antes de pedir merge

## Scope del pipeline de PR

En `pull_request` solo corre el workflow **CI** (`ci.yml`). Jobs en paralelo:

| Job | Qué valida | Comando local equivalente |
|-----|------------|---------------------------|
| `scan_ruby` | Brakeman + bundler-audit | `bin/brakeman --no-pager` · `bin/bundler-audit` |
| `scan_js` | Vulnerabilidades JS (importmap) | `bin/importmap audit` |
| `lint` | Estilo Ruby (RuboCop) | `bin/rubocop -f github` |
| `test` | Tests unitarios/integración + DB | `DATABASE_URL=... bin/rails db:test:prepare test` |
| `system-test` | System tests + screenshots en fallo | `DATABASE_URL=... bin/rails db:test:prepare test:system` |

**No forma parte del CI de PR:** `whatsapp-evals.yml` (cron diario / `workflow_dispatch`). No bloquear el PR por ese workflow salvo que el usuario lo pida.

`bin/ci` es un atajo local útil, pero **no es idéntico** a Actions (incluye seeds/yarn y omite system tests). Preferir los comandos de la tabla al diagnosticar un check concreto.

---

## Workflow

Crea este checklist y actualízalo:

```
- [ ] Identificar PR / rama y leer estado de checks
- [ ] Mapear fallos a jobs de ci.yml
- [ ] Reproducir en local el job fallido (comando exacto)
- [ ] Aplicar corrección mínima en el código/config del repo
- [ ] Re-correr el mismo comando hasta verde
- [ ] Push y verificar checks remotos
- [ ] Reportar resultado por job
```

### 1. Estado del PR

```bash
gh pr view --json number,url,headRefName,statusCheckRollup
gh pr checks
```

Si no hay PR aún, validar en local todos los jobs de la tabla antes de abrir el PR.

### 2. Diagnosticar

Para cada check en rojo:

1. Leer el log del job (`gh run view <id> --log-failed` o la UI de Actions).
2. Identificar el **step** exacto (no solo el nombre del job).
3. Abrir [reference.md](reference.md) en la sección de ese job.
4. Reproducir con el comando local indicado (mismas flags que CI cuando existan).

### 3. Corregir

Aplicar el fix más pequeño que deje verde ese step. Reglas:

- **No** debilitar CI (quitar steps, bajar severidad, ignorar CVE sin justificación) solo para pasar.
- **Sí** se puede actualizar ignores en `config/bundler-audit.yml` si el CVE no aplica — documentar por qué en el PR.
- Autocorregir estilo con `bin/rubocop -A` solo sobre archivos tocados por el cambio, salvo que el usuario pida un sweep más amplio.
- Tests: arreglar código o tests del alcance del PR; no borrar assertions para “pasar”.
- System tests: usar screenshots de `tmp/screenshots` (o el artifact `screenshots` del run) para entender el fallo de UI.

Orden de prioridad si fallan varios jobs a la vez:

1. `lint` (rápido, suele desbloquear ruido)
2. `scan_ruby` / `scan_js` (seguridad)
3. `test`
4. `system-test`

### 4. Verificar en local (suite PR)

Con Postgres local disponible (mismas credenciales que CI o las del `.env` de desarrollo/test):

```bash
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
bin/rubocop -f github
bin/rails db:test:prepare test
bin/rails db:test:prepare test:system
```

Si solo falló un job, re-correr ese job; al final, al menos el job corregido + un sanity check del blast radius (tests del área tocada).

### 5. Remoto

```bash
git push
gh pr checks --watch
```

Reportar solo cuando un `gh pr checks` fresco muestre todos los jobs de **CI** en verde (o explique blockers ajenos al PR).

---

## Formato del reporte

```markdown
## CI del PR #<n>

| Job | Estado | Acción |
|-----|--------|--------|
| scan_ruby | ✅/❌ | … |
| scan_js | ✅/❌ | … |
| lint | ✅/❌ | … |
| test | ✅/❌ | … |
| system-test | ✅/❌ | … |

### Fallos y fixes
- **job/step**: causa → cambio aplicado → comando que quedó verde
```

---

## Integración con otras skills

- Tras `/parallel-development` + implementación: correr este flujo antes o justo después de `gh pr create`.
- No hace merge ni force-push; deja el PR listo para revisión humana.
- Si el fallo parece de infraestructura (Actions down, cache corrupta, Postgres del runner): reintentar el run una vez; si persiste, reportar al usuario sin inventar cambios de código.
