#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
api_base_url="${LUMEN_API_BASE_URL:-http://127.0.0.1:3000}"
web_port="${LUMEN_WEB_PORT:-51910}"
api_env_file="$repo_root/apps/api/.env"

if [ -f "$api_env_file" ]; then
  # shellcheck disable=SC1090
  set -a
  . "$api_env_file"
  set +a
fi

supabase_flag="${LUMEN_USE_SUPABASE:-false}"
supabase_url="${LUMEN_SUPABASE_URL:-}"
supabase_publishable_key="${LUMEN_SUPABASE_PUBLISHABLE_KEY:-}"

if [ "$supabase_flag" = "true" ] && [ -z "$supabase_publishable_key" ]; then
  echo "Missing LUMEN_SUPABASE_PUBLISHABLE_KEY for Flutter web auth." >&2
  echo "Set it in apps/api/.env or export it before running ./scripts/dev_web_api.sh." >&2
  exit 1
fi

cd "$repo_root/apps/mobile"

flutter build web --pwa-strategy=none \
  --dart-define=LUMEN_USE_API_AI=true \
  --dart-define=LUMEN_API_BASE_URL="$api_base_url" \
  --dart-define=LUMEN_USE_SUPABASE="$supabase_flag" \
  --dart-define=LUMEN_SUPABASE_URL="$supabase_url" \
  --dart-define=LUMEN_SUPABASE_PUBLISHABLE_KEY="$supabase_publishable_key"

cd "$repo_root/apps/mobile/build/web"
python3 -m http.server "$web_port" --bind 127.0.0.1
