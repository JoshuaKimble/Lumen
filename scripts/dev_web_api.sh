#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
api_base_url="${LUMEN_API_BASE_URL:-http://127.0.0.1:3000}"
web_port="${LUMEN_WEB_PORT:-51910}"

cd "$repo_root/apps/mobile"

flutter build web --pwa-strategy=none \
  --dart-define=LUMEN_USE_API_AI=true \
  --dart-define=LUMEN_API_BASE_URL="$api_base_url"

cd "$repo_root/apps/mobile/build/web"
python3 -m http.server "$web_port" --bind 127.0.0.1
