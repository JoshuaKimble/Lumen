# Journal Cloud Schema (M6)

This document defines the first cloud-backed journal persistence schema for M6:
User-Owned Cloud Persistence + Sync.

## Purpose

The schema introduces four user-owned tables:

- `public.journal_entries`
- `public.journal_themes`
- `public.related_resources`
- `public.resource_feedback`

It also now defines two server-owned catalog tables that future resource
generation can retrieve from:

- `public.curated_resource_catalog`
- `public.curated_resource_theme_mappings`

They mirror the current Flutter journal domain closely enough for the existing
local models to hydrate into cloud-backed repositories later, while adding the
sync metadata needed for M6-M7 follow-up work.

## Table Overview

### Server-Owned Catalog Foundation

These catalog tables are not user-owned journaling records. They exist so the
API can rank against a durable curated source of truth rather than treating
`related_resources` as both the catalog and the output store.

### `curated_resource_catalog`

Stores reusable curated resource records and prompt-template-backed resource
records keyed by `catalog_key`.

Key columns:

- `catalog_key`
- `record_kind` (`resource`, `prompt_template`)
- `resource_type`
- `provider_key`
- `tradition_key`
- `title`
- `description`
- `canonical_url`
- `scripture_reference`
- `prompt_template`
- `content_text`
- `metadata`
- `is_active`

Design notes:

- `record_kind` keeps fixed resources and prompt-template-backed reflection
  prompts in one durable catalog foundation instead of splitting them too early.
- `metadata` allows structured provider or routing detail without exploding the
  first schema iteration.
- This table is server-owned and intentionally not exposed to authenticated
  clients.

### `curated_resource_theme_mappings`

Stores reusable semantic associations between catalog records and journal theme
ids using primary key `(catalog_key, theme_id)`.

Key columns:

- `catalog_key`
- `theme_id`
- `weight`

Design notes:

- Theme mappings give future retrieval a stable boundary before more advanced
  semantic ranking is introduced.
- `weight` is intentionally simple for the foundation: it encodes relative
  affinity, not a final user-facing confidence score.

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
- This table remains the user-visible output store for generated suggestions,
  not the server-owned catalog source of truth.

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

M7 enables RLS on all four journal tables and applies explicit ownership
policies:

- `anon` has no access
- `authenticated` can `select`, `insert`, `update`, and `delete` only rows
  where `user_id = auth.uid()`
- `update` policies use both `USING` and `WITH CHECK`
- `service_role` retains explicit grants for server-only workflows

This keeps the journal schema safe in `public` even when tables are reachable
through Supabase APIs, and it matches the local-first sync model already used
in Flutter repositories.

The curated catalog tables also live in `public`, but they are server-owned:

- `anon` and `authenticated` are explicitly revoked
- RLS is enabled with no user-facing policies
- future server-side suggestion orchestration reads them through privileged
  backend access rather than direct Flutter client access

## Seed And Ownership Strategy

- `supabase/seed.sql` provides a deterministic local-only baseline catalog seed
  for development and QA.
- Migration files define schema only; curated content rows are seeded
  idempotently outside migrations.
- Initial catalog ownership is editorial and code-managed: updates happen
  through reviewed seed SQL or later ingestion tooling, not ad hoc client
  writes.
- The seed is intentionally small and representative. It exists to unblock
  retrieval and ranking development, not to represent a production-sized
  library.

## App Model Alignment

The schema maps directly to the current Flutter journal domain:

- [journal_entry.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/journal_entry.dart)
- [journal_theme.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/journal_theme.dart)
- [related_resource.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/related_resource.dart)
- [resource_suggestion_service.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/resource_suggestion_service.dart)

This keeps the upcoming repository split focused on transport and sync concerns
rather than forcing a domain rewrite first.

For the catalog foundation decision, see:

- [0011-curated-resource-catalog-foundation.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0011-curated-resource-catalog-foundation.md)
