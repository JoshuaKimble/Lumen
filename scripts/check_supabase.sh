#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[supabase-check] verifying required files..."
test -f supabase/config.toml
test -f supabase/seed.sql

echo "[supabase-check] verifying migration directory..."
if [[ ! -d supabase/migrations ]]; then
  echo "supabase/migrations directory is missing."
  exit 1
fi

mapfile -t migrations < <(find supabase/migrations -maxdepth 1 -type f -name "*.sql" | sort)
if [[ ${#migrations[@]} -eq 0 ]]; then
  echo "No migration files found under supabase/migrations."
  exit 1
fi

declare -A timestamps=()
for migration_path in "${migrations[@]}"; do
  filename="$(basename "$migration_path")"
  if [[ ! "$filename" =~ ^[0-9]{14}_[a-z0-9_]+\.sql$ ]]; then
    echo "Invalid migration filename: $filename"
    echo "Expected format: YYYYMMDDHHMMSS_snake_case.sql"
    exit 1
  fi

  ts="${filename%%_*}"
  if [[ -n "${timestamps[$ts]:-}" ]]; then
    echo "Duplicate migration timestamp detected: $ts"
    exit 1
  fi
  timestamps["$ts"]=1
done

echo "[supabase-check] verifying env safety..."
required_env_ignores=(
  ".env"
  ".env.*"
  "**/.env"
  "**/.env.*"
)
for pattern in "${required_env_ignores[@]}"; do
  if ! grep -Fqx "$pattern" .gitignore; then
    echo "Missing required .gitignore pattern: $pattern"
    exit 1
  fi
done

echo "[supabase-check] scanning tracked files for obvious secrets..."
secret_hits=0

scan_pattern() {
  local pattern="$1"
  local description="$2"
  if git grep -nE "$pattern" -- \
    ':!**/.env.example' \
    ':!scripts/check_supabase.sh' \
    ':!docs/*' \
    ':!*.md' \
    ':!supabase/config.toml' >/tmp/lumen_secret_scan.tmp 2>/dev/null; then
    echo "Potential ${description} secret detected:"
    cat /tmp/lumen_secret_scan.tmp
    secret_hits=1
  fi
}

scan_pattern 'sk-(proj|live|test)-[A-Za-z0-9]+' "OpenAI-style API key"
scan_pattern 'SUPABASE_SERVICE_ROLE_KEY=.*[^[:space:]]' "service-role key assignment"
scan_pattern 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' "JWT token"

rm -f /tmp/lumen_secret_scan.tmp

if [[ "$secret_hits" -ne 0 ]]; then
  exit 1
fi

echo "[supabase-check] pass"
