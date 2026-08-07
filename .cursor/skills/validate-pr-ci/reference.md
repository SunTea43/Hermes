# Referencia CI de PR — Hermes

Workflow: `.github/workflows/ci.yml`  
Triggers: `pull_request` (todas las ramas) y `push` a `main`.

Runner: `ubuntu-latest`. Ruby vía `ruby/setup-ruby@v1` con `bundler-cache: true`. Checkout: `actions/checkout@v7`.

---

## Job: `scan_ruby`

### Steps

1. **Checkout code** — clona el repo.
2. **Set up Ruby** — instala Ruby + `bundle install` cacheado.
3. **Scan for common Rails security vulnerabilities using static analysis**
   ```bash
   bin/brakeman --no-pager
   ```
   Nota: `bin/brakeman` antepone `--ensure-latest` automáticamente.
4. **Scan for known security vulnerabilities in gems used**
   ```bash
   bin/bundler-audit
   ```
   Usa `config/bundler-audit.yml` (lista `ignore:`).

### Fallos típicos y correcciones

| Síntoma | Corrección |
|---------|------------|
| Brakeman warning/error en controlador, SQL, mass-assignment, redirect | Corregir el código vulnerable (strong params, `find_by`, allowlist de redirects, etc.). |
| Falso positivo documentado de Brakeman | Preferir fix real; si es inevitable, usar ignore de Brakeman **acotado** y justificar en el PR. |
| `bin/brakeman` pide actualizar la gem | Actualizar `brakeman` en el Gemfile del grupo de desarrollo y regenerar lockfile. |
| bundler-audit CVE en dependencia | Actualizar la gem afectada (`bundle update <gem>`). |
| CVE que no aplica al uso en Hermes | Agregar el CVE a `ignore:` en `config/bundler-audit.yml` con comentario/justificación en el PR. No usar el placeholder `CVE-THAT-DOES-NOT-APPLY` como plantilla real. |

### Reproducción local

```bash
bin/brakeman --no-pager
bin/bundler-audit
# o explícito:
bin/bundler-audit check
```

---

## Job: `scan_js`

### Steps

1. **Checkout code**
2. **Set up Ruby** (importmap-rails vive en el bundle)
3. **Scan for security vulnerabilities in JavaScript dependencies**
   ```bash
   bin/importmap audit
   ```

### Fallos típicos y correcciones

| Síntoma | Corrección |
|---------|------------|
| CVE en paquete pinneado por importmap | Actualizar el pin en `config/importmap.rb` / vendor del asset a una versión parcheada. |
| Paquete sin fix upstream | Evaluar quitar/reemplazar dependencia; no silenciar el audit sin acuerdo. |

### Reproducción local

```bash
bin/importmap audit
```

---

## Job: `lint`

### Steps

1. **Checkout code**
2. **Set up Ruby**
3. **Prepare RuboCop cache** — cache en `tmp/rubocop` (`actions/cache@v6`), key por OS + hash de `.ruby-version`, configs RuboCop y `Gemfile.lock`.
4. **Lint code for consistent style**
   ```bash
   bin/rubocop -f github
   ```

Config: `.rubocop.yml` hereda de `rubocop-rails-omakase`.

### Fallos típicos y correcciones

| Síntoma | Corrección |
|---------|------------|
| Ofensas autocorregibles | `bin/rubocop -A path/al/archivo.rb` (preferir archivos del PR). |
| Ofensas de estilo no safe | Ajustar el código a mano según la regla. |
| Regla inadecuada al caso | Discusión en el PR; cambiar `.rubocop.yml` solo con justificación de estilo de equipo. |

### Reproducción local

```bash
bin/rubocop -f github
# solo archivos tocados:
bin/rubocop -f github $(git diff --name-only --diff-filter=AM origin/main...HEAD -- '*.rb')
```

---

## Job: `test`

### Services

- **postgres** (`POSTGRES_USER/PASSWORD=postgres`, puerto `5432`, healthcheck `pg_isready`)
- Redis/Valkey está comentado en el workflow.

### Steps

1. **Install packages** — `libpq-dev`, `node-gyp`
2. **Checkout code**
3. **Set up Ruby**
4. **Run tests**
   ```bash
   bin/rails db:test:prepare test
   ```
   Env CI:
   - `RAILS_ENV=test`
   - `DATABASE_URL=postgres://postgres:postgres@localhost:5432/hermes_test`

### Fallos típicos y correcciones

| Síntoma | Corrección |
|---------|------------|
| Failure/error en test unitario o de integración | Arreglar implementación o actualizar expectativa si el comportamiento nuevo es intencional. |
| Error de migración / schema | Corregir migración; asegurar que `db:test:prepare` corre limpio. |
| Dependencia de Redis/credenciales | No asumir Redis en CI (está comentado). Evitar tests que requieran servicios no levantados. |
| Flaky por orden/tiempo | Hacer el test determinista (fixtures, travel_to, stubs). |

### Reproducción local

```bash
export RAILS_ENV=test
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/hermes_test
bin/rails db:test:prepare test
# o un archivo:
bin/rails test test/path/al_test.rb
```

Si usas Postgres local con otras credenciales, adapta `DATABASE_URL`; el esquema de preparación debe ser el mismo (`db:test:prepare`).

---

## Job: `system-test`

### Services

Igual que `test` (Postgres). Redis comentado.

### Steps

1. **Install packages** — `libpq-dev`, `node-gyp`
2. **Checkout code**
3. **Set up Ruby**
4. **Run System Tests**
   ```bash
   bin/rails db:test:prepare test:system
   ```
   Mismo `DATABASE_URL` / `RAILS_ENV` que `test`.
5. **Keep screenshots from failed system tests** (solo si el job falla)
   - Artifact: `screenshots`
   - Path: `tmp/screenshots`
   - Driver local: Selenium headless Chrome (`test/application_system_test_case.rb`)

### Fallos típicos y correcciones

| Síntoma | Corrección |
|---------|------------|
| Elemento no encontrado / timeout Capybara | Ajustar UI, selectores o esperas; revisar screenshot. |
| Fallo de JS/asset en página | Verificar importmap / asset pipeline en el flujo tocado. |
| Auth/sesión en system test | Reusar helpers de sign-in existentes; no hardcodear datos frágiles. |
| Pantalla en blanco / 500 | Revisar log del test y screenshot; suele ser excepción de servidor. |

### Reproducción local

```bash
export RAILS_ENV=test
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/hermes_test
bin/rails db:test:prepare test:system
# screenshots tras fallo:
ls tmp/screenshots
```

Descargar artifact remoto:

```bash
gh run download <run-id> -n screenshots
```

---

## Fuera del CI de PR: `whatsapp-evals.yml`

- Triggers: cron `0 6 * * *` (06:00 UTC) y `workflow_dispatch`
- Job `evals`: Postgres + `bin/rails db:test:prepare` + `bin/rails eval:run`
- Secrets: `OPENAI_API_KEY`, `OPENAI_BASE_URL`
- **No** corre automáticamente al crear un PR

Solo diagnosticar/arreglar este workflow si el usuario lo pide o si está fallando el schedule.

---

## Relación con `bin/ci`

`bin/ci` → `config/ci.rb`. Diferencias vs Actions:

| Aspecto | `bin/ci` | GitHub `ci.yml` |
|---------|----------|-----------------|
| RuboCop | sí | sí (`-f github`) |
| bundler-audit | sí | sí |
| importmap audit | sí | sí |
| brakeman | sí (flags `--quiet --exit-on-warn --exit-on-error`) | `--no-pager` (+ `--ensure-latest` del binstub) |
| yarn audit | sí | no |
| `rails test` | sí | sí (+ `db:test:prepare` en Actions) |
| seeds replant | sí | no |
| system tests | comentado | **sí** (job dedicado) |

Para validar “lo que verá el PR”, prioriza los cinco jobs de Actions, no solo `bin/ci`.

---

## Comandos `gh` útiles

```bash
# checks del PR actual
gh pr checks

# runs del workflow CI en la rama
gh run list --workflow=ci.yml --branch "$(git branch --show-current)" --limit 5

# logs solo de steps fallidos
gh run view <run-id> --log-failed

# re-dispatch del último run (si aplica)
gh run rerun <run-id> --failed
```
