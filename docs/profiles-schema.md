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

The rewrite API contract now mirrors these values through the optional
`personalization` object on `POST /v1/entries/rewrite`, with explicit defaults
of `rewriteTone = balanced` and `preserveVoice = true` for backward
compatibility when older clients omit personalization.

## RLS Design

M7 enables RLS on `public.profiles` and applies explicit ownership policies:

- `anon` has no access to profile rows
- `authenticated` may `select`, `insert`, `update`, and `delete` only the row
  whose `id` matches `auth.uid()`
- the `update` policy includes both `USING` and `WITH CHECK`
- `service_role` keeps explicit grants for server-only paths

That matches the intended ownership model from M3 while making the table safe
for Supabase API access in the exposed `public` schema.
