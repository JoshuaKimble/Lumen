# Lumen Architecture

Lumen starts as a small Flutter app with architecture chosen for long-lived
Codex collaboration: clear module boundaries, explicit project memory, and
low ceremony until product needs justify more structure.

`docs/principles.md` defines the clean-code posture for this project. The
architecture should remain simple, understandable, and resistant to unnecessary
configuration or abstraction.

## Application Shape

- `lib/main.dart` only bootstraps Flutter and Riverpod.
- `lib/src/app` owns app composition, routing, and theme.
- `lib/src/features` owns product behavior, grouped by feature.
- Each feature uses `domain`, `data`, and `presentation` folders when those
  boundaries exist.

## State Management

Riverpod is the default state and dependency injection system.

- Providers expose dependencies and feature state.
- Widgets consume providers with `ConsumerWidget` or `ConsumerStatefulWidget`.
- Business logic should live outside widgets when it needs tests or reuse.
- Repository contracts belong in the domain layer; implementations belong in
  the data layer.

## Routing

GoRouter is the default router.

- Routes are declared in app-level routing.
- Feature screens should be exported through route builders rather than letting
  unrelated features reach into implementation details.
- Route names and paths should stay stable once linked externally.

## Journal Feature Baseline

The initial journal feature is intentionally minimal. It proves the structure
with an in-memory repository and a home screen placeholder. Persistence, search,
tags, sync, encryption, and editor design are future decisions.

## Testing

- Widget tests cover app shell rendering and important user flows.
- Provider or repository tests cover business rules and data behavior.
- Platform-specific testing is required before claiming Android, iOS, or web
  readiness for release.

## Decisions

Use `docs/decisions/` for decisions that change durable architecture. Keep each
record short: context, decision, consequences, and date.
