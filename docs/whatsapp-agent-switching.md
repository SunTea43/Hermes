# Cómo cambiar el agente de WhatsApp

Hermes puede enrutar mensajes con el dispatcher **regex** (default) o con un **Interpreter LLM** que produce `{ intent, entities, confidence }`. Las skills, el renderer y el provider adapter no cambian.

## Niveles de configuración

### 1. Por tienda (`businesses.whatsapp_agent`)

| Valor en BD | Ruby | Comportamiento |
| --- | --- | --- |
| `0` | `regex` / `regex?` | Dispatcher por expresiones regulares (actual) |
| `1` | `llm` / `llm?` | Interpreter LLM + guard de confianza |
| `2` | `inherit` / `inherit?` | Usa el default global de `config/whatsapp.yml` |

Es un **enum integer-backed** en `Business`. La clave Ruby es `:inherit` (no `:default`) para no chocar con APIs de ActiveRecord.

```ruby
business = Business.find(12)
business.update!(whatsapp_agent: :llm)     # activar AI
business.update!(whatsapp_agent: :regex)   # volver al bot clásico
business.update!(whatsapp_agent: :inherit) # seguir config/whatsapp.yml → agent.default
```


### 2. Default global (`config/whatsapp.yml`)

```yaml
production:
  agent:
    default: regex          # o llm
    llm_provider: openai    # openai | groq | fake
    model: gpt-4o-mini
    temperature: 0
    confidence_threshold: 0.7
    # base_url / api_key_env opcionales (si no, usan presets)
```

Cuando una tienda tiene `whatsapp_agent: inherit` (2), se usa `agent.default`.

Presets LLM:

| `llm_provider` | Env key | Base URL | Modelo default |
| --- | --- | --- | --- |
| `openai` | `OPENAI_API_KEY` | `https://api.openai.com/v1` | `gpt-4o-mini` |
| `groq` | `GROQ_API_KEY` | `https://api.groq.com/openai/v1` | `openai/gpt-oss-20b` (soporta `json_schema`) |
| `fake` | — | — | — |

Si usas otro modelo Groq sin structured outputs, pon `agent.response_format: json_object`.

En `development` el default es `groq` (STT + Interpreter). En `test`, `fake`.

## Variables de entorno (LLM)

```bash
# Si agent.llm_provider=openai
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1   # opcional

# Si agent.llm_provider=groq (development)
GROQ_API_KEY=gsk_...
```


## Prompt versionado (YAML)

Los prompts viven en `config/whatsapp_prompts/*.yml` (hoy `interpreter_v1.yml`).

Estructura:

```yaml
version: interpreter_v1
instructions: |
  Texto del system prompt...
retry_user_template: |
  Reintenta... %{message}
examples:
  - user: "Vendí 10kg de arroz"
    json:
      intent: sale
      entities: {}
      confidence: 0.9
schema:
  type: object
  ...
```

Para iterar el prompt: edita el YAML (instrucciones o ejemplos). Para un cambio mayor, copia el archivo a `interpreter_v2.yml` y apunta el código/`VERSION` a esa versión. Mide regresiones con la suite de evals.

El loader es `WhatsappBot::Prompts::Catalog`; la fachada `WhatsappBot::Prompts::InterpreterV1` mantiene la API `SYSTEM` / `SCHEMA` / `VERSION`.

## Guardrails del Interpreter

1. Salida JSON estructurada (`intent` enum + `entities` + `confidence`)
2. `temperature: 0`
3. Reintento único si el JSON es inválido
4. `ConfidenceGuard`: si `confidence < threshold` → `clarify` (menú/ayuda, sin ejecutar skills de escritura)
5. Las escrituras siguen exigiendo confirmación conversacional en los handlers

## Rollback

```ruby
Business.find(12).update!(whatsapp_agent: :regex)
# o
# config/whatsapp.yml → agent.default: regex
```

No hace falta tocar skills ni providers.
