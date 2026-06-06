# Production Domains And Auth URLs (Issue #95)

This document defines the current production-first URL plan for Lumen across
Flutter web, the Node API, and Supabase Auth.

The goal is to remove guesswork before production deploys are fully wired.

## Current Decision

Lumen will launch initially on provider-managed HTTPS domains and can upgrade
to custom domains later without changing the architecture.

Initial production URLs:

- Web: `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`
- API: `https://<render-service-name>.onrender.com`

Custom domains are allowed later, but they are not required to complete the
first production deployment path.

## Why This Order

- `#96` and `#98` need explicit production URLs before deployment wiring is
  complete.
- API CORS must know the exact browser origin.
- Supabase Auth URL Configuration must know the exact production web URL for
  verification and password-reset flows.
- Local development must keep working on localhost without pretending staging
  already exists.

## API CORS Rule

The API now follows this rule:

- always allow localhost browser origins for local development
- allow one exact deployed web origin via `LUMEN_ALLOWED_WEB_ORIGIN`

Set this in the Render production API service:

```text
LUMEN_ALLOWED_WEB_ORIGIN=https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev
```

When a custom web domain replaces the default Pages domain, update this value
to the new exact origin.

## Supabase Auth URL Configuration

Use Supabase Auth > URL Configuration with these values.

### Production

- `Site URL`:
  - `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`
- `Redirect URLs` allowlist:
  - `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`
  - `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev/auth/reset-password`

Production entries should stay exact. Supabase recommends exact production
redirect URLs instead of broad wildcards.

### Local Development

Allow the default local web paths used by the Flutter web workflow:

- `http://127.0.0.1:51910/**`
- `http://localhost:51910/**`

If a local run uses a different port, add that exact local origin or wildcard
pattern intentionally instead of broadening production URLs.

## Cloudflare Pages Setup

The initial production web URL comes from the Pages project subdomain:

- `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`

If a custom web domain is added later:

1. In Cloudflare, open Workers & Pages.
2. Open the Lumen Pages project.
3. Go to Custom domains.
4. Choose Set up a domain.
5. Add the desired domain or subdomain.
6. Complete the DNS step in the dashboard flow.

If the domain is an externally managed subdomain, point a CNAME record at
`<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`.

Do not create the CNAME first without attaching the domain in the Pages
dashboard. Cloudflare documents that this can leave the domain unresolved.

After the custom domain is live, update:

- Cloudflare Pages build env `LUMEN_API_BASE_URL` if the API origin changes
- Render env `LUMEN_ALLOWED_WEB_ORIGIN`
- Supabase Auth `Site URL`
- Supabase Auth redirect URL allowlist

## Render Setup

The initial production API URL comes from the Render web service subdomain:

- `https://<render-service-name>.onrender.com`

If a custom API domain is added later:

1. Open the Render web service.
2. Go to Settings > Custom Domains.
3. Add the desired domain.
4. Configure the DNS records Render requires.
5. Verify the domain in Render.

After the custom domain is active, update:

- Cloudflare Pages `LUMEN_API_BASE_URL`
- any smoke checks that hit the API directly
- any public docs that name the API origin

Render can keep the `onrender.com` URL or disable it after a custom domain is
verified.

## Local Compatibility

Local development remains unchanged:

- Flutter web continues to call the local API with `LUMEN_API_BASE_URL`
- localhost browser origins remain allowed by the API without extra env vars
- local Supabase flows remain separate from production URL configuration

## Environment Changes

This issue adds one production API environment variable:

- `LUMEN_ALLOWED_WEB_ORIGIN`

Current ownership:

- Source of truth: Render production API environment
- Example value: `https://<CLOUDFLARE_PAGES_PROJECT_NAME>.pages.dev`

## Follow-On Impact

- `#96` should use the Render default URL first, then optionally add a custom
  API domain later.
- `#98` should point Flutter web at the chosen production API URL through
  `LUMEN_API_BASE_URL`.
- `#99` smoke checks should hit the finalized production web URL and verify the
  API-backed paths from the browser.
