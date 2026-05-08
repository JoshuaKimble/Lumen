#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
mobile_dir="$repo_root/apps/mobile"

if [ ! -d "$mobile_dir" ]; then
  echo "Missing Flutter app at apps/mobile." >&2
  exit 1
fi

cd "$mobile_dir"

flutter pub get
flutter analyze
flutter test

