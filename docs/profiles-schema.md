# Profiles Schema (M3)

This document defines the `profiles` table introduced for milestone M3:
Profiles and Onboarding.

## Purpose

`public.profiles` stores the user-owned profile row that backs:

- onboarding completion state
- AI rewrite preferences
- scripture app preference routing
- theme preference hydration across signed-in sessions

The row is keyed 1:1 to `auth.users` through `profiles.id`.

## Columns

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key. References `auth.users(id)` with `on delete cascade`. |
| `email` | `text` | Required email snapshot used for hydration and recovery flows. |
| `display_name` | `text` | Nullable until onboarding is completed. Must be non-blank when present. |
| `rewrite_tone` | `text` | Required. Allowed values: `balanced`, `gentle`, `encouraging`, `reflective`. |
| `preserve_voice` | `boolean` | Required. Defaults to `true`. |
| `preferred_scripture_app` | `text` | Required. Allowed values: `none`, `gospel_library`, `you_version`, `bible_gateway`, `catholic`. |
| `theme_preference` | `text` | Required. Allowed values: `system`, `light`, `dark`. |
| `onboarding_completed` | `boolean` | Required. Defaults to `false`. Controls first-run routing after verification. |
| `created_at` | `timestamptz` | Required UTC creation timestamp. |
| `updated_at` | `timestamptz` | Required UTC update timestamp maintained by trigger. |

## App Model Alignment

The Flutter app maps this table through:

- [user_profile.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/profiles/domain/user_profile.dart)
- [rewrite_tone_preference.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/profiles/domain/rewrite_tone_preference.dart)
- [user_profile_mapper.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/profiles/data/user_profile_mapper.dart)

`theme_preference` and `preferred_scripture_app` intentionally reuse the
existing Flutter enums that already drive local settings behavior, so the
cloud-backed profile layer and device-local settings layer speak the same
storage values.

`apps/api` and `packages/api_contracts` do not yet contain profile types.
When those packages are created, their contracts should mirror the storage
values documented here instead of inventing new names.

## RLS-Ready Design

This schema is prepared for RLS work without enabling policies yet:

- user ownership is anchored on `profiles.id = auth.users.id`
- cascade delete preserves account-deletion semantics
- onboarding state is stored on the owned row rather than inferred elsewhere
- normalized preference values allow explicit `select` and `update` policies

The intended future policy shape is:

- authenticated users may `select` only their own profile row
- authenticated users may `insert` only a row whose `id` matches `auth.uid()`
- authenticated users may `update` only their own row

RLS policies remain part of the later security milestone rather than M3.
