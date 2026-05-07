# Lumen Codex Guide

This file is the first thing Codex should read before changing this repo.
It captures durable project standards; update it when the team intentionally
changes how Lumen is built.

## Project

- Lumen is a Flutter journal app targeting Android, iOS, and web.
- The app package name is `lumen`.
- The initial native app id is `com.joshuakimble.lumen`.
- Flutter is pinned by the local toolchain to stable `3.35.7` with Dart `3.9.2`.

## Required Commands

Run these before handing off code changes when relevant:

```sh
flutter pub get
flutter analyze
flutter test
```

Use `dart format .` for formatting. Do not run formatters that rewrite files
unless the task includes code changes.

## Git Conventions

- Use Conventional Commits v1.0.0:
  `<type>[optional scope]: <description>`.
- Use lowercase commit types consistently.
- Use `feat` for user-facing features and `fix` for bug fixes.
- Prefer these supporting types when they fit: `docs`, `test`, `refactor`,
  `style`, `build`, `ci`, `chore`, `perf`, and `revert`.
- Add a scope when it clarifies the affected area, for example
  `feat(journal): add entry list`.
- Mark breaking changes with `!` before the colon or a `BREAKING CHANGE:`
  footer.
- Keep the description imperative, concise, and specific.
- Use a commit body when the reason for the change is not obvious from the
  summary.
- Split unrelated changes into separate commits when practical.
- Commit messages are enforced by `.githooks/commit-msg`. Keep
  `git config core.hooksPath .githooks` set for this repo.

## Architecture Standards

- Keep app-wide composition in `lib/src/app`.
- Keep product code feature-first under `lib/src/features/<feature>`.
- Use Riverpod for state and dependency injection.
- Use GoRouter for navigation.
- Put domain models and repository contracts in `domain`.
- Put concrete data sources and repository implementations in `data`.
- Put widgets, controllers, and route screens in `presentation`.
- UI widgets should be small, named, and testable.
- Avoid global mutable state. Prefer providers and constructor parameters.

## Coding Standards

- Follow `analysis_options.yaml`; do not silence lints without a specific reason.
- Optimize for clean code: code should be easy for another engineer to read,
  change, extend, and maintain.
- Prefer the simplest design that satisfies the current requirement. Do not add
  abstractions, configuration, or indirection before they remove real complexity.
- Follow standard Flutter and Dart conventions unless this guide states a local
  convention.
- Apply the boy scout rule: leave touched code clearer than it was.
- When fixing a defect, identify the root cause before changing behavior.
- Prefer immutable values, `const` constructors, and explicit return types for
  public APIs.
- Use descriptive, searchable, pronounceable names. Avoid type prefixes,
  encodings, and vague distinctions.
- Replace magic values with named constants when the value has domain meaning.
- Keep files, classes, widgets, and functions focused. Split them when they
  become hard to scan or test.
- Keep functions small, single-purpose, and free of hidden side effects.
- Prefer fewer arguments. Do not use flag arguments; expose separate methods or
  widgets for separate behavior.
- Prefer positive conditionals over negative conditionals.
- Declare variables close to their use and use explanatory variables for
  non-obvious expressions.
- Hide internal structure behind focused APIs. Avoid hybrid types that mix rich
  behavior with public mutable data.
- Write comments only for non-obvious decisions or constraints.
- Do not introduce persistence, sync, auth, encryption, or analytics without an
  architecture decision record.

## Project Memory

- `docs/architecture.md` is the canonical architecture overview.
- `docs/principles.md` is the canonical clean-code principles guide.
- `docs/decisions/` contains architecture decision records.
- Add a new decision record when changing state management, routing, persistence,
  sync, authentication, encryption, deployment, Git conventions, or public data
  contracts.
- Keep documentation factual and current. If code and docs disagree, update the
  stale one in the same change.

## Local Toolchain Notes

- `flutter doctor` found that the iOS simulator runtime is not installed.
- `flutter doctor` also reported an `adb` crash during connected-device
  detection under Rosetta/code signing. Revalidate Android devices before
  treating device testing as complete.
