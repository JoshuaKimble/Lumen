# Production Config Inventory (Issue #94)

This document is the current production configuration inventory for Lumen.
It defines each required value, where it should live, and why.

Scope:

- Node API runtime configuration
- Flutter web build-time configuration
- CI/CD deployment configuration for Supabase migrations

## Source-Of-Truth Systems

- Render: production API runtime env vars
- Cloudflare Pages: production Flutter web build/runtime env vars
- GitHub Actions (`production` environment): deploy-time pipeline secrets/vars
- Local `apps/api/.env`: developer-only local runtime and migration tooling

## Inventory

| Key | Required For | Secret | Source Of Truth | Also In | Notes |
| --- | --- | --- | --- | --- | --- |
| `LUMEN_AI_PROVIDER` | API runtime | No | Render | local `.env` | `mock` or `openai` |
| `OPENAI_API_KEY` | API runtime (`openai`) | Yes | Render | local `.env` | Never in Flutter or repo |
| `LUMEN_OPENAI_REWRITE_MODEL` | API runtime | No | Render | local `.env` | Optional override |
| `LUMEN_OPENAI_THEME_MODEL` | API runtime | No | Render | local `.env` | Optional override |
| `LUMEN_OPENAI_TRANSCRIPTION_MODEL` | API runtime | No | Render | local `.env` | Optional override |
| `LUMEN_USE_SUPABASE` | API runtime + CI deploy | No | Render (API), GH Actions var (deploy) | local `.env` | Should be `true` in cloud-backed environments |
| `LUMEN_SUPABASE_URL` | API runtime + CI deploy | No | Render (API), GH Actions var (deploy) | local `.env`, Cloudflare Pages | Supabase project URL |
| `LUMEN_SUPABASE_PUBLISHABLE_KEY` | Flutter web auth config | No | Cloudflare Pages | local `.env` (dev scripts), API `.env.example` docs | Client-safe key |
| `LUMEN_SUPABASE_SECRET_KEY` | API privileged Supabase access | Yes | Render | local `.env` | Server-only key |
| `LUMEN_SUPABASE_DB_URL` | CI migration deploy | Yes | GH Actions secret (`production`) | local `.env` | Use direct connection (`:5432`) for GitHub-hosted runners |
| `LUMEN_API_BASE_URL` | Flutter web API calls | No | Cloudflare Pages | local shell/dev script | Public API origin |
| `LUMEN_USE_API_AI` | Flutter web AI path toggle | No | Cloudflare Pages | local shell/dev script | Build-time Dart define |
| `CLOUDFLARE_PAGES_PROJECT_NAME` | Web deploy pipeline | No | GH Actions variable | Cloudflare Pages project settings | Wrangler deploy target |
| `CLOUDFLARE_API_TOKEN` | Web deploy pipeline | Yes | GH Actions secret (`production`) | n/a | Token with Cloudflare Pages deploy permissions |
| `CLOUDFLARE_ACCOUNT_ID` | Web deploy pipeline | Yes | GH Actions secret (`production`) | n/a | Cloudflare account identifier |
| `PORT` | API runtime process port | No | Render | n/a | Render-provided |

## Required Production Notes

### Supabase URL and keys

- `LUMEN_SUPABASE_URL` is required in:
  - Render API runtime
  - Cloudflare Pages build env (for Flutter auth)
  - GitHub Actions deploy vars (for Supabase migration checks)
- `LUMEN_SUPABASE_PUBLISHABLE_KEY` is required only for Flutter/client auth.
- `LUMEN_SUPABASE_SECRET_KEY` is server-only and must never be exposed to Flutter.

### OpenAI API key

- `OPENAI_API_KEY` is API-only and must live only in Render (and local `.env` when needed).

### API base URL

- `LUMEN_API_BASE_URL` is required for Flutter web builds in Cloudflare Pages.

### Allowed CORS origins

- Current API behavior is hardcoded to allow only localhost origins in
  [apps/api/src/app.ts](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/api/src/app.ts).
- Production CORS origin configuration must be completed before production web
  rollout (tracked by issue `#95`).

### Auth site URL and redirect URLs

- Supabase Auth `SITE_URL` and redirect URL allowlist must include:
  - production web URL (Cloudflare Pages custom domain)
  - local development URL(s)
- Final production domain and auth URL alignment is tracked by issue `#95`.

## Duplicate-Value Justification

Some values must exist in more than one system:

- `LUMEN_SUPABASE_URL`
  - Render: API server-side Supabase integrations
  - Cloudflare Pages: Flutter web auth configuration
  - GitHub Actions: migration deploy checks and deploy job context
- `LUMEN_USE_SUPABASE`
  - Render: runtime behavior
  - GitHub Actions: deploy safety checks
- `LUMEN_SUPABASE_DB_URL`
  - GitHub Actions: production migration deploy path
  - local `.env`: manual migration tooling parity

These are intentional duplicates because each execution environment is isolated.

## Verification Performed

- Ran `./scripts/check_supabase.sh` successfully:
  - confirms env ignore coverage
  - scans tracked files for obvious committed secrets

## Cloudflare Pages Manual Setup

One-time requirements before the CI web deploy workflow can run:

1. Create the Cloudflare Pages project.
2. Set the Pages production branch to `master`.
3. Add GitHub repository variables:
   - `LUMEN_API_BASE_URL`
   - `LUMEN_SUPABASE_URL`
   - `LUMEN_SUPABASE_PUBLISHABLE_KEY`
   - `CLOUDFLARE_PAGES_PROJECT_NAME`
4. Add GitHub `production` environment secrets:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`

After setup, web deploy is handled by:

- `.github/workflows/web-pages.yml`

## Related Issues

- `#91` Unified CI/CD and Release Pipeline epic
- `#94` this audit
- `#95` production domains, CORS, auth URLs
- `#96` Render production API deploy
- `#98` Cloudflare Pages production deploy
- `#99` post-deploy smoke checks
