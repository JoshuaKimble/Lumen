# Lumen Workflow

Lumen uses GitHub Issues as the project task list and works directly on
`master` by default.

## Source Of Work

- GitHub Issues are the active task tracker.
- `docs/github-task-backlog.md` is the source backlog used to seed and review
  GitHub Issues.
- Product and technical context lives in the repo docs; issues should link back
  to those docs when the broader context matters.

## Working On Issues

Before starting meaningful work:

1. Read the relevant GitHub Issue.
2. Read any referenced docs.
3. Confirm the working tree is clean.
4. Work on `master` unless the change is risky enough to isolate.

Reference the issue in commits when practical. Use `Closes #<issue>` when a
commit fully completes the issue.

## Master-First Development

Working directly on `master` is acceptable when:

- The work is small or well understood.
- The change can be validated locally before commit.
- The work does not block other active work.
- The change can be reverted cleanly if needed.

Create a branch or pull request when:

- The work is risky or experimental.
- The change spans many unrelated areas.
- A long-running implementation would leave `master` unstable.
- Review, CI isolation, or side-by-side comparison would materially reduce risk.

## Completion Criteria

An issue is ready to close when:

- Acceptance criteria are met.
- Relevant checks have passed or skipped checks are documented.
- Docs are updated when conventions, product behavior, or architecture changed.
- The issue is referenced by the final commit or closed with a clear GitHub
  comment.

## Commit Standards

Use Conventional Commits for every commit. The local `commit-msg` hook enforces
the format documented in `AGENTS.md`.

## Mock AI Responses

Mock AI rewrite responses intentionally identify their source so local testing
shows which flow produced the result.

- Flutter mock responses begin with `[Flutter mock: ...]`.
- API mock rewrite responses begin with `[API mock: rewrite endpoint]`.
- Source labels should stay limited to mock/local development behavior and must
  not appear in real AI provider responses.

## API-Backed Runbook

Use [local-api-development.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/local-api-development.md)
for API-backed Flutter local runs, including `dart-define` flags, convenience
scripts, and localhost troubleshooting.

Use [platform-readiness.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/platform-readiness.md)
to clear Android/iOS local setup blockers and run platform smoke tests.
