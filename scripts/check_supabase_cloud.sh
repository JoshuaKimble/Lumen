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

echo "[supabase-cloud-check] verifying shared cloud configuration..."
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required variable: $var_name"
    exit 1
  fi
done

if [[ "$LUMEN_USE_SUPABASE" != "true" ]]; then
  echo "Expected LUMEN_USE_SUPABASE=true for shared cloud validation."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found."
  exit 1
fi

echo "[supabase-cloud-check] querying shared cloud database..."
supabase db query 'select 1 as ok;' --db-url "$LUMEN_SUPABASE_DB_URL" >/tmp/lumen_supabase_cloud_query.txt
cat /tmp/lumen_supabase_cloud_query.txt

echo "[supabase-cloud-check] listing remote migration history..."
supabase migration list --db-url "$LUMEN_SUPABASE_DB_URL" >/tmp/lumen_supabase_cloud_migrations.txt
cat /tmp/lumen_supabase_cloud_migrations.txt

rm -f /tmp/lumen_supabase_cloud_query.txt /tmp/lumen_supabase_cloud_migrations.txt

echo "[supabase-cloud-check] pass"
