#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found."
  exit 1
fi

cleanup() {
  supabase stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[supabase-migrations] starting local Supabase stack..."
supabase start

echo "[supabase-migrations] applying migrations + seed via db reset..."
supabase db reset

echo "[supabase-migrations] running RLS verification..."
docker exec -i supabase_db_lumen-local \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  < supabase/tests/user_owned_rls_verification.sql

echo "[supabase-migrations] migration apply check passed"
