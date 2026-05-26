#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for local Supabase fixture reset."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
  exit 1
fi

echo "[reset-dev-fixture] ensuring local Supabase stack is running..."
supabase start >/dev/null

echo "[reset-dev-fixture] deleting deterministic fixture user..."
docker exec -i supabase_db_lumen-local \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "delete from auth.users where id = '33333333-3333-3333-3333-333333333333' or email = 'seed.user@lumen.test';"

echo "Fixture removed."
