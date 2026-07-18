# Evals del Interpreter WhatsApp

Suite puntuada (no pass/fail por caso) para medir calidad del Interpreter LLM.

## Dataset

Casos en `test/evals/cases/*.yml` (ventas, compras, pagos, inventario, reportes, ambiguos).

Umbrales en `test/evals/thresholds.yml`:

- `intent_accuracy`
- `entity_exact_match`
- `consistency` (misma intención en N corridas)

## Ejecutar

```bash
# Con API real (requiere OPENAI_API_KEY)
bin/rails eval:run

# Con cliente fake perfecto (útil en local/CI unitario)
EVAL_FAKE=1 bin/rails eval:run
```

## CI

Job nightly `.github/workflows/whatsapp-evals.yml` (06:00 UTC + `workflow_dispatch`).

Secret requerido: `OPENAI_API_KEY` (opcional `OPENAI_BASE_URL`).

No corre en cada PR: costo + variabilidad. Los tests deterministas (`test/services/whatsapp_bot`) sí van en el job `test` normal.
