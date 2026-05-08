#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
contracts_dir="$repo_root/packages/api_contracts"

if [ ! -d "$contracts_dir" ]; then
  echo "Skipping contract checks: packages/api_contracts does not exist yet."
  exit 0
fi

cd "$contracts_dir"

if [ -f package.json ]; then
  npm install
  npm test
else
  echo "Skipping contract checks: packages/api_contracts/package.json does not exist yet."
fi
