# Lumen

Lumen is a Flutter journal application foundation for Android, iOS, and web.
The project is optimized for iterative development with Codex by keeping
architecture and coding standards in repo-canonical documentation.

The planned project shape is a monorepo with a Flutter app, Node TypeScript AI
backend gateway, and shared OpenAPI contracts.

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

## Git Hooks

This repo keeps Git hooks in `.githooks`. Enable them after cloning:

```sh
git config core.hooksPath .githooks
```

The `commit-msg` hook enforces the Conventional Commits format documented in
`AGENTS.md`.

## Project Memory

- Read `AGENTS.md` before changing code.
- Read `docs/product-requirements.md` before changing product behavior.
- Read `docs/technical-plan.md` before changing the implementation roadmap.
- Read `docs/github-task-backlog.md` before creating or revising GitHub tasks.
- Read `docs/architecture.md` before changing structure.
- Add decision records under `docs/decisions/` for durable architecture changes.
