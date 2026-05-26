#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for local Supabase fixture seeding."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
  exit 1
fi

echo "[seed-dev-fixture] ensuring local Supabase stack is running..."
supabase start >/dev/null

echo "[seed-dev-fixture] applying deterministic journal fixture..."
docker exec -i supabase_db_lumen-local \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  < supabase/dev_seed_one_week_journal.sql

echo
echo "Seeded local fixture user:"
echo "  email:    seed.user@lumen.test"
echo "  password: LumenSeed123!"
