# 0008: Journal Write-Through Sync Queue

- Status: Accepted
- Date: 2026-05-25

## Context

M6 introduces cloud-backed journal persistence, but the app remains local-first.
Journal edits must never depend on immediate network success, and retries need
to be deterministic, durable, and visible during troubleshooting.

## Decision

Lumen will use a local write-through sync queue for journal entry upserts and
deletes.

The queue design is:

- local persistence remains the source of truth for immediate UX
- signed-in journal writes enqueue a pending operation in local storage
- queue entries are deduplicated by `(user_id, entry_id)`
- the latest operation replaces any older pending operation for the same entry
- flush attempts run after enqueue and again when the repository is rebuilt
- retries use bounded backoff: `5s`, `15s`, `30s`, `60s`, then `300s`
- only the currently signed-in user’s queued operations are eligible to flush
- sync diagnostics are exposed through Riverpod state for future UI or support
  tooling

## Consequences

Positive:

- users can save and delete entries without blocking on the network
- duplicate queued writes collapse into one deterministic operation
- failed sync attempts preserve a retry schedule and error message
- later hydration and conflict resolution work can build on stable primitives

Tradeoffs:

- queue state adds another local persistence surface to maintain
- retries are opportunistic rather than connectivity-aware
- diagnostics exist in app state now, but no troubleshooting screen consumes
  them yet
