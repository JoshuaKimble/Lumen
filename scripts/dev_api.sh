#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

cd "$repo_root/apps/api"

if [ -f ".env" ]; then
  # shellcheck disable=SC1091
  set -a
  . ./.env
  set +a
fi

npm run dev
