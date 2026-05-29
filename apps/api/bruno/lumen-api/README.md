# Lumen API QA Bruno Collection

This collection is stored in the older `opencollection.yml` + request `.yml`
format because that matches the Bruno setup already in use on this machine.

Collection folder:

- `apps/api/bruno/lumen-api`

Environment files shipped with this collection:

- `environments/local.bru`
- `environments/cloud-shared.bru`
- `environments/local.json`
- `environments/cloud-shared.json`

Recommended workflow:

1. Edit your chosen env file and fill in Supabase auth credentials
2. In Bruno, set collection auth to `Bearer Token` with token `{{access_token}}`
3. Run feedback requests directly; request pre-request scripts auto-fetch `access_token` when missing
4. If needed, run `05 Supabase Login Set Token` manually as a fallback/debug step
5. Optionally keep a private copy as `*.local.bru` or `*.local.json`
   files (ignored by git)
6. Select the environment in Bruno

Suggested variables:

- `api_base_url` = `http://127.0.0.1:3000`
- `access_token` = populated automatically by login request
- `supabase_url` = your Supabase project URL
- `supabase_publishable_key` = your project publishable key
- `supabase_email` = login email for target env
- `supabase_password` = login password for target env
- `invalid_access_token` = `not-a-real-token`
- `resource_id` = any stable manual QA value like `manual-qa-resource`

Auth and token bootstrap behavior:

- Collection-level auth should be set in Bruno UI once, then requests use
  `auth: inherit`.
- Protected feedback requests (`10`, `13`, `14`) include a request-level
  pre-request script that checks `access_token` and runs
  `05 Supabase Login Set Token` automatically when missing.
- `05 Supabase Login Set Token` writes `access_token` into the active Bruno
  environment using `bru.setEnvVar`.
- Requests that intentionally bypass auth testing use `auth: none`
  (`00`, `05`, `11`, `12`).

Recommended manual QA coverage for issue `#80`:

- `10 Feedback Success`
- `11 Feedback Missing Token`
- `12 Feedback Invalid Token`
- `13 Feedback Invalid Action`
- `14 Feedback Spoofed User Id`
