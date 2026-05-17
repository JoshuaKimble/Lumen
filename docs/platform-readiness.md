# Platform Readiness

This runbook closes local platform blockers for Android, iOS, and web testing.

## 1. Run Doctor

From repo root:

```sh
./scripts/platform_readiness.sh
```

If no known blockers are detected, continue to smoke tests.

## 2. Fix Known Android Blocker: `adb` Rosetta Crash

If `flutter doctor -v` shows:

`rosetta error: Attachment of code signature supplement failed`

Use this sequence:

```sh
sdkmanager --uninstall "platform-tools"
sdkmanager --install "platform-tools"
softwareupdate --install-rosetta --agree-to-license
xattr -dr com.apple.quarantine "$ANDROID_HOME/platform-tools"
adb kill-server
adb start-server
flutter doctor -v
```

If `sdkmanager` is not on `PATH`, use:

`$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager`

## 3. Fix Known iOS Blocker: Missing Simulator Runtime

If `flutter doctor -v` reports missing iOS simulator runtime:

1. Open Xcode.
2. Xcode -> Settings -> Components.
3. Install the required iOS Simulator runtime.
4. Re-run `flutter doctor -v`.

## 4. API Base URL Defaults For Platform Runs

When `LUMEN_USE_API_AI=true` and `LUMEN_API_BASE_URL` is not set:

- Android defaults to `http://10.0.2.2:3000` (Android emulator host loopback).
- iOS defaults to `http://127.0.0.1:3000`.
- Web defaults to `http://127.0.0.1:3000`.

Override explicitly when needed:

```sh
flutter run --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://<host>:3000
```

## 5. Smoke Test Commands

From `apps/mobile`:

```sh
flutter run -d chrome
flutter run -d <android-device-id>
flutter run -d <ios-simulator-id>
```

For API mode:

```sh
flutter run -d chrome --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://127.0.0.1:3000
flutter run -d <android-device-id> --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://10.0.2.2:3000
flutter run -d <ios-simulator-id> --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://127.0.0.1:3000
```
