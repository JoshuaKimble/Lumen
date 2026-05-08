#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

"$repo_root/scripts/check_mobile.sh"
"$repo_root/scripts/check_api.sh"
"$repo_root/scripts/check_contracts.sh"

