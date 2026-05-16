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
