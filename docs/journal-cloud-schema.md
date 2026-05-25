# Journal Cloud Schema (M6)

This document defines the first cloud-backed journal persistence schema for M6:
User-Owned Cloud Persistence + Sync.

## Purpose

The schema introduces four user-owned tables:

- `public.journal_entries`
- `public.journal_themes`
- `public.related_resources`
- `public.resource_feedback`

They mirror the current Flutter journal domain closely enough for the existing
local models to hydrate into cloud-backed repositories later, while adding the
sync metadata needed for M6-M7 follow-up work.

## Table Overview

### `journal_entries`

Stores the primary journal entry row keyed by `(user_id, id)`.

Key columns:

- `id`: client-owned entry identifier from the Flutter app
- `source`: `voice` or `text`
- `original_text`: original journal content
- `rewritten_text`: latest AI rewrite snapshot
- `title`, `summary`, `last_regenerated_at`
- `client_updated_at`, `version`, `sync_state`
- `created_at`, `updated_at`

Design notes:

- `id` remains a text identifier because the current app already treats entry
  ids as client-generated strings.
- `client_updated_at` is separate from `updated_at` so future merge logic can
  compare the user's local write time against the persisted server row.
- `sync_state` is stored now because later local/cloud composition work needs a
  stable place to persist conflict or retry metadata.

### `journal_themes`

Stores normalized theme rows for an entry using primary key
`(user_id, entry_id, theme_id)`.

Key columns:

- `entry_id`
- `theme_id`
- `name`
- `display_name`
- `weight`

Design notes:

- Theme rows cascade with their parent entry.
- `theme_id` reuses the semantic id already used throughout Flutter UI routing
  and theme summaries.

### `related_resources`

Stores related resources keyed by `(user_id, resource_id)`.

Key columns:

- `resource_id`
- `entry_id`
- `theme_id`
- `title`
- `type`
- `source_type`
- `match_reason`
- `confidence`
- `url`
- `scripture_reference`
- `description`

Design notes:

- `entry_id` is a foreign key when a resource is entry-attached.
- `theme_id` remains a semantic lookup field instead of a hard foreign key so
  theme-only suggestions can be stored without inventing synthetic theme rows.
- `scripture_reference` is included even though the current OpenAPI suggestion
  contract does not yet expose it, because the Flutter domain model already
  uses it for scripture-link routing.

### `resource_feedback`

Stores one feedback row per `(user_id, resource_id)`.

Key columns:

- `resource_id`
- `entry_id`
- `theme_id`
- `action`
- `note`
- `client_updated_at`
- `version`
- `sync_state`
- `created_at`, `updated_at`

Design notes:

- The current app already persists feedback by `resource_id`, so the cloud
  table follows the same ownership model.
- `note` is included to match the API contract even though the Flutter UI does
  not collect free-form notes yet.

## Sync Metadata

The schema adds the following sync-oriented fields where they are materially
useful to merge and retry workflows:

- `client_updated_at`
- `version`
- `sync_state`

They are intentionally on `journal_entries` and `resource_feedback`, which are
the two user-owned records that can change independently in the current
product. `journal_themes` and `related_resources` are treated as entry-derived
child rows for now.

## RLS And Data API Readiness

This migration is RLS-ready but does **not** enable RLS policies or grant Data
API access yet.

That is intentional:

- M7 owns the final RLS policy design.
- New Supabase projects may no longer auto-expose `public` tables to the Data
  API by default, and explicit grants without RLS would be unsafe.

The intended future policy shape is per-user ownership:

- `select` only your own rows
- `insert` only rows whose `user_id` matches `auth.uid()`
- `update` only your own rows with matching `WITH CHECK`
- `delete` only your own rows

## App Model Alignment

The schema maps directly to the current Flutter journal domain:

- [journal_entry.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/journal_entry.dart)
- [journal_theme.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/journal_theme.dart)
- [related_resource.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/related_resource.dart)
- [resource_suggestion_service.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/resource_suggestion_service.dart)

This keeps the upcoming repository split focused on transport and sync concerns
rather than forcing a domain rewrite first.
