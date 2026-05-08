#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
api_dir="$repo_root/apps/api"

if [ ! -d "$api_dir" ]; then
  echo "Skipping API checks: apps/api does not exist yet."
  exit 0
fi

cd "$api_dir"

if [ -f package.json ]; then
  npm run typecheck
  npm test
else
  echo "Skipping API checks: apps/api/package.json does not exist yet."
fi

