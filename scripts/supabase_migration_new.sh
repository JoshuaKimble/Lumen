#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/supabase_migration_new.sh <migration_name>"
  exit 1
fi

supabase migration new "$1"
