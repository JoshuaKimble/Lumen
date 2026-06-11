# User Capabilities Schema

This document defines the server-managed authorization table introduced for
internal admin controls.

## Purpose

`public.user_capabilities` stores non-user-editable capability flags keyed 1:1
to `auth.users`.

The first capability is:

- `is_admin`

This table exists separately from `public.profiles` because profile data is
user-owned and user-editable, while authorization must remain service-managed.

## Columns

| Column | Type | Notes |
| --- | --- | --- |
| `user_id` | `uuid` | Primary key. References `auth.users(id)` with `on delete cascade`. |
| `is_admin` | `boolean` | Required. Defaults to `false`. Controls internal admin UI/server capability checks. |
| `created_at` | `timestamptz` | Required UTC creation timestamp. |
| `updated_at` | `timestamptz` | Required UTC update timestamp maintained by trigger. |

## Access Model

- `anon` has no access
- `authenticated` may only `select` their own row
- `authenticated` may not insert, update, or delete rows
- `service_role` may manage rows for administrative workflows

This makes the table safe to expose through Supabase APIs while keeping writes
reserved for privileged paths.

## Operational Admin Grant

To mark a signed-in Supabase user as admin in the shared cloud project, run:

```sql
insert into public.user_capabilities (user_id, is_admin)
select id, true
from auth.users
where lower(email) = lower('joshkimble@gmail.com')
on conflict (user_id) do update
set
  is_admin = excluded.is_admin,
  updated_at = timezone('utc', now());
```

For the related auth decision, see:

- [0012-supabase-user-capabilities.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0012-supabase-user-capabilities.md)
