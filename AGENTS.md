# AGENTS.md — Hermes

## Idioma y tono (español)

- Usar **español neutro latinoamericano** orientado a Colombia (tú / usted según contexto formal de UI).
- **No usar voseo rioplatense / acento argentino** en textos de producto, prompts de LLM, respuestas del bot ni mensajes al usuario.
- Evitar formas como: *vos*, *sos*, *tenés*, *podés*, *querés*, *pedile*, *decime*, *escribime*, *configurá*, *registrate* (sin tilde de imperativo neutro), etc.
- Preferir: *tú/usted*, *eres*, *tienes*, *puedes*, *quiere*, *pídele*, *dime*, *escríbeme*, *configura*, *regístrate*.
- Los prompts del LLM deben instruir en este mismo registro; no imitar jerga argentina aunque el usuario escriba con voseo (sí se puede *entender* voseo en entradas; no *responder* con él).
- Mantener tono claro, cercano y profesional; sin regionalismos forzados.

## Alcance

Aplica a:

- `app/services/whatsapp_bot/prompts/**` y `config/whatsapp_prompts/**`
- Respuestas del bot (`ResponseRenderer`, handlers, webhooks)
- Copy de UI y documentación orientada a usuarios finales
- Nuevos strings en español que agregue el agente
