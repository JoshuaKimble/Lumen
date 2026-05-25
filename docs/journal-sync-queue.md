# Journal Sync Queue (M6)

This document defines the first write-through sync queue for cloud-backed
journal entries.

## Purpose

The app remains local-first. Saving or deleting an entry must complete against
local storage even when cloud sync is unavailable.

The queue provides:

- durable pending write storage
- deterministic deduplication
- bounded retry scheduling
- observable sync diagnostics

## Operation Model

Each queued operation stores:

- `queueKey`
- `userId`
- `entryId`
- `type`: `upsert` or `delete`
- optional serialized `JournalEntry` payload
- `enqueuedAt`
- `nextAttemptAt`
- `attemptCount`
- optional `lastErrorMessage`

`queueKey` is derived as `userId:entryId`.

That gives one pending operation slot per user-owned entry and prevents
duplicate queued writes from accumulating.

## Deduplication Rules

- a new save replaces any older save or delete for the same `queueKey`
- a delete replaces any older save or delete for the same `queueKey`
- the queue therefore stores only the latest pending intent for a given entry

## Flush Behavior

- queue flush is attempted after each enqueue
- queue flush is also attempted when the hybrid repository is rebuilt
- only operations for the current signed-in user are eligible to flush
- operations are flushed in enqueue order
- the coordinator stops after the first failure and preserves the remaining
  queue

## Retry Policy

Failed operations are rescheduled with bounded backoff:

- attempt 1: `5s`
- attempt 2: `15s`
- attempt 3: `30s`
- attempt 4: `60s`
- attempt 5+: `300s`

On failure the queue stores:

- incremented `attemptCount`
- `nextAttemptAt`
- `lastErrorMessage`

## Diagnostics

The sync diagnostics state exposes:

- pending operation count
- whether a flush is in progress
- last attempted sync time
- last successful sync time
- last failure time
- last failure message
- next scheduled retry time

This is intentionally enough for later troubleshooting UI, logs, or support
instrumentation without forcing the app to block on cloud health.
