#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="$ROOT_DIR/apps/api/.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  . "$ENV_FILE"
  set +a
fi

required_vars=(
  LUMEN_USE_SUPABASE
  LUMEN_SUPABASE_URL
  LUMEN_SUPABASE_DB_URL
)

echo "[supabase-cloud-push] verifying shared cloud configuration..."
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required variable: $var_name"
    exit 1
  fi
done

if [[ "$LUMEN_USE_SUPABASE" != "true" ]]; then
  echo "Expected LUMEN_USE_SUPABASE=true for shared cloud migration push."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found."
  exit 1
fi

echo "[supabase-cloud-push] previewing pending migrations..."
supabase db push --db-url "$LUMEN_SUPABASE_DB_URL" --include-all --dry-run

echo "[supabase-cloud-push] applying pending migrations..."
supabase db push --db-url "$LUMEN_SUPABASE_DB_URL" --include-all

echo "[supabase-cloud-push] listing remote migration history..."
supabase migration list --db-url "$LUMEN_SUPABASE_DB_URL"

echo "[supabase-cloud-push] pass"
