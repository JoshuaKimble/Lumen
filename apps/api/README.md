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
```

The configured defaults are `gpt-5-mini` for rewrite/theme detection and
`gpt-4o-mini-transcribe` for transcription.

The gateway must not commit provider API keys or secrets. Local `.env` files are
ignored by git; keep real API keys out of commits, logs, and test fixtures.

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
