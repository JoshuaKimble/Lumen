# Lumen

Lumen is a Flutter journal application foundation for Android, iOS, and web.
The project is optimized for iterative development with Codex by keeping
architecture and coding standards in repo-canonical documentation.

The project is a monorepo with a Flutter app in `apps/mobile`, a Node
TypeScript AI backend gateway in `apps/api`, and shared OpenAPI contracts in
`packages/api_contracts`.

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

`./scripts/check.sh` runs the mobile, API, contract, and Supabase safety
checks used by CI.

API gateway commands:

```sh
cd apps/api
npm run typecheck
npm test
npm run build
```

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

For local Flutter web runs against the Node API, use
`docs/local-api-development.md`.

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

## Deployments

Production deploys currently use:

- Render for the Node API in `apps/api`
- Cloudflare Pages for the Flutter web build from `apps/mobile/build/web`
- GitHub Actions for CI, Cloudflare Pages deploys, and Supabase cloud
  migrations

Production configuration ownership is documented in:

- `docs/production-config-inventory.md`
- `docs/production-domains-and-auth.md`

## Project Memory

- Read `AGENTS.md` before changing code.
- Read `docs/product-requirements.md` before changing product behavior.
- Read `docs/technical-plan.md` before changing the implementation roadmap.
- Read `docs/workflow.md` before changing the GitHub issue workflow.
- Read `docs/github-task-backlog.md` before creating or revising GitHub tasks.
- Read `docs/architecture.md` before changing structure.
- Read `docs/privacy-controls-v1.md` before changing privacy, retention,
  export, or auditability expectations.
- Read `docs/security-boundaries.md` before changing auth, RLS, or user-owned
  data boundaries.
- Read `docs/supabase-environment-strategy.md` before Supabase environment or
  secret-management work.
- Add decision records under `docs/decisions/` for durable architecture changes.
