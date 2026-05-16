# Lumen API Gateway

`apps/api` is the Node TypeScript gateway for AI-backed transcription,
rewriting, and theme detection.

Current scope:

- Health endpoint.
- Mock AI provider boundary.
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

The gateway must not commit provider API keys or secrets. Add provider-specific
configuration only through environment variables in later issues.
