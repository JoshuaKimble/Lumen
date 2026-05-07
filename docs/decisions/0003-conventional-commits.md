# 0003: Conventional Commits

Date: 2026-05-06

## Context

Lumen needs a consistent Git history that is readable by humans and can support
future automation such as changelog generation or release versioning.

## Decision

Use Conventional Commits v1.0.0 for commit messages. Commit summaries should use
`<type>[optional scope]: <description>`, with lowercase types and concise
imperative descriptions.

## Consequences

- Use `feat` for features and `fix` for bug fixes.
- Use supporting types such as `docs`, `test`, `refactor`, `style`, `build`,
  `ci`, `chore`, `perf`, and `revert` when they describe the change.
- Mark breaking changes with `!` in the type/scope prefix or a
  `BREAKING CHANGE:` footer.
- Split unrelated work into separate commits when practical.
- Enforce commit message format locally with the tracked `.githooks/commit-msg`
  hook and `core.hooksPath=.githooks`.
