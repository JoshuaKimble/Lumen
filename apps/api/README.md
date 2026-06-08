# Lumen API Gateway

`apps/api` is the Node TypeScript gateway for AI-backed transcription,
rewriting, and theme detection.

Current scope:

- Health endpoint.
- Mock AI provider boundary.
- OpenAI provider support for rewrite, theme detection, and transcription.
- TypeScript typecheck and tests.

Mock rewrite responses are intentionally labeled with
`[API mock: rewrite endpoint]` so local testing makes it obvious that the
backend mock provider produced the text. Real provider responses must not include
mock source labels.

Commands:

```sh
npm install
npm run typecheck
npm test
npm run build
npm run dev
```

For end-to-end local API-backed Flutter runs, see
`docs/local-api-development.md` from the repository root.

## AI Provider Configuration

The gateway defaults to mock mode and does not require secrets:

```sh
LUMEN_AI_PROVIDER=mock
```

To enable the OpenAI provider boundary locally, copy `.env.example` to `.env`
and set:

```sh
LUMEN_AI_PROVIDER=openai
OPENAI_API_KEY=sk-proj-...
```

Optional model overrides:

```sh
LUMEN_OPENAI_REWRITE_MODEL=gpt-5-mini
LUMEN_OPENAI_THEME_MODEL=gpt-5-mini
LUMEN_OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
LUMEN_OPENAI_TIMEOUT_MS=60000
LUMEN_OPENAI_TRANSCRIPTION_CHUNK_SECONDS=45
```

The configured defaults are `gpt-5-mini` for rewrite/theme detection and
`gpt-4o-mini-transcribe` for transcription. The OpenAI request timeout defaults
to `60000` milliseconds. WAV transcription requests are chunked into `45`
second segments by default to reduce long-recording truncation risk; other
formats currently remain single-pass.

The gateway must not commit provider API keys or secrets. Local `.env` files are
ignored by git; keep real API keys out of commits, logs, and test fixtures.

## Supabase Configuration (Foundation)

Supabase config is currently optional and disabled by default.

When enabled, the API fails fast on startup if required vars are missing:

```sh
LUMEN_USE_SUPABASE=true
LUMEN_SUPABASE_URL=https://your-project-ref.supabase.co
LUMEN_SUPABASE_SECRET_KEY=sb_secret_...
```

Secret keys are server-only and must never be exposed to Flutter clients.

## CORS Configuration

The API always allows localhost browser origins for local development.

Set this environment variable in deployed API environments to allow the
production Flutter web origin:

```sh
LUMEN_ALLOWED_WEB_ORIGIN=https://lumen-app.pages.dev
```

Use the exact deployed web origin only. Do not include path segments.

## Privacy And Error Handling

- The API remains stateless for journal data in the MVP.
- Request handlers and provider code must not log raw journal text, transcripts,
  base64 audio payloads, prompts, or API keys.
- Provider failures are mapped to safe API errors:
  - `provider_rate_limited` (`429`)
  - `provider_timeout` (`504`)
  - `provider_unavailable` (`503`)
  - `provider_response_invalid` (`502`)
  - `provider_error` (`502`)
- API responses intentionally avoid returning raw provider error payloads.
