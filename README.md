# Lumen

Lumen is a Flutter journal application foundation for Android, iOS, and web.
The project is optimized for iterative development with Codex by keeping
architecture and coding standards in repo-canonical documentation.

The project is a monorepo with a Flutter app in `apps/mobile`, a planned Node
TypeScript AI backend gateway, and planned shared OpenAPI contracts.

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
./scripts/check.sh
```

`./scripts/check.sh` runs Flutter analysis/tests now and will also run API and
contract checks as those packages are added.

API contract commands:

```sh
cd packages/api_contracts
npm test
```

Flutter app commands:

```sh
cd apps/mobile
flutter run -d chrome
```

## Git Hooks

This repo keeps Git hooks in `.githooks`. Enable them after cloning:

```sh
git config core.hooksPath .githooks
```

The `commit-msg` hook enforces the Conventional Commits format documented in
`AGENTS.md`.

## Workflow

Lumen uses GitHub Issues as the active task tracker and works directly on
`master` by default. Create a branch or pull request when the change is risky,
long-running, or benefits from review/CI isolation.

Before starting work, read the relevant issue and linked docs. Reference issues
in commits when practical, and use `Closes #<issue>` when a commit completes an
issue.

For Supabase local database setup and migration workflows, use
`docs/supabase-migration-workflow.md`.

## Project Memory

- Read `AGENTS.md` before changing code.
- Read `docs/product-requirements.md` before changing product behavior.
- Read `docs/technical-plan.md` before changing the implementation roadmap.
- Read `docs/workflow.md` before changing the GitHub issue workflow.
- Read `docs/github-task-backlog.md` before creating or revising GitHub tasks.
- Read `docs/architecture.md` before changing structure.
- Read `docs/supabase-environment-strategy.md` before Supabase environment or
  secret-management work.
- Add decision records under `docs/decisions/` for durable architecture changes.
