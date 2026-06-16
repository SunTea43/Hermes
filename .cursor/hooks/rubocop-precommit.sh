#!/usr/bin/env bash
# Cursor hook: corre rubocop antes de cualquier `git commit`
set -e

input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

# Solo actuar en git commit (no git commit --amend ni otros subcomandos)
if ! echo "$command" | grep -qE '^git commit'; then
  echo '{"permission":"allow"}'
  exit 0
fi

# Obtener archivos .rb staged
cd "${CURSOR_WORKSPACE_DIR:-$(pwd)}"
STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.rb$' || true)

if [ -z "$STAGED" ]; then
  echo '{"permission":"allow"}'
  exit 0
fi

echo "🔍 Cursor hook: corriendo rubocop antes del commit..." >&2

if bundle exec rubocop --format progress $STAGED >&2; then
  echo '{"permission":"allow"}'
else
  echo '{
    "permission": "deny",
    "user_message": "Rubocop encontró ofensas en los archivos staged. Corregí los errores antes de commitear. Tip: `bundle exec rubocop -a`",
    "agent_message": "Rubocop failed on staged .rb files. Fix the offenses before committing."
  }'
fi
