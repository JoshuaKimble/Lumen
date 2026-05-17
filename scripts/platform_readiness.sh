#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

cd "$repo_root/apps/mobile"

doctor_output="$(flutter doctor -v 2>&1 || true)"
printf '%s\n' "$doctor_output"

has_blocker=0

if printf '%s' "$doctor_output" | rg -q "iOS [0-9]+.*Simulator not installed"; then
  has_blocker=1
  cat <<'EOF'
[platform-readiness] Missing iOS Simulator runtime.
Fix:
  1. Open Xcode
  2. Xcode > Settings > Components
  3. Install the required iOS Simulator runtime
EOF
fi

if printf '%s' "$doctor_output" | rg -q "rosetta error: Attachment of code signature supplement failed"; then
  has_blocker=1
  cat <<'EOF'
[platform-readiness] adb Rosetta/code-signing crash detected.
Suggested fix sequence:
  1. Quit Android Studio and all emulators
  2. sdkmanager --uninstall "platform-tools"
  3. sdkmanager --install "platform-tools"
  4. softwareupdate --install-rosetta --agree-to-license
  5. xattr -dr com.apple.quarantine "$ANDROID_HOME/platform-tools"
  6. adb kill-server && adb start-server
  7. Re-run: flutter doctor -v
EOF
fi

if [ "$has_blocker" -eq 1 ]; then
  exit 1
fi

echo "[platform-readiness] No known Android/iOS blockers detected."
