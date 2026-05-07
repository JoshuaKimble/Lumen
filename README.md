# Lumen

Lumen is a Flutter journal application foundation for Android, iOS, and web.
The project is optimized for iterative development with Codex by keeping
architecture and coding standards in repo-canonical documentation.

## Toolchain

- Flutter stable `3.35.7`
- Dart `3.9.2`
- Android SDK installed locally
- Xcode and CocoaPods installed locally
- Chrome installed for web development

Known local setup items:

- Install the missing iOS simulator runtime in Xcode Settings > Components
  before iOS simulator testing.
- Recheck Android connected-device support after resolving the current `adb`
  Rosetta/code-signing crash reported by `flutter doctor`.

## Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Project Memory

- Read `AGENTS.md` before changing code.
- Read `docs/architecture.md` before changing structure.
- Add decision records under `docs/decisions/` for durable architecture changes.
