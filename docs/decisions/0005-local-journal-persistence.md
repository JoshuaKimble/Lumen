# 0005: Local Journal Persistence

Date: 2026-05-07

## Context

Lumen's MVP needs local-first journal persistence across Android, iOS, and web.
The product is still early, and persistence should not introduce database
complexity before the core journaling loop is proven.

## Decision

Use `shared_preferences` as the MVP local persistence layer for journal entries.
Store entries as JSON behind the `JournalRepository` contract.

## Consequences

- The Flutter app can persist entries locally on Android, iOS, and web with
  minimal setup.
- UI-facing providers continue to depend on `JournalRepository`, not storage
  details.
- Querying by date and theme is implemented in repository code over the stored
  entry list.
- This is not the final storage architecture for sensitive or large journal
  data. Encryption, SQLite/Drift, cloud sync, and migration strategy require
  later ADRs.
