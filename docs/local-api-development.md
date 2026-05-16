# Local API-Backed Development

This guide runs the Flutter app against `apps/api` without source edits.

## 1. Prepare API Environment

From `apps/api`:

```sh
cp .env.example .env
```

Use one of these modes in `.env`:

1. Mock API mode (no secrets required):

```sh
LUMEN_AI_PROVIDER=mock
```

2. OpenAI API mode:

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

## 2. Start the API Gateway

Run from repo root:

```sh
./scripts/dev_api.sh
```

Default API URL: `http://127.0.0.1:3000`.

## 3. Run Flutter Web in API Mode

Run from repo root:

```sh
./scripts/dev_web_api.sh
```

Defaults:

- `LUMEN_API_BASE_URL=http://127.0.0.1:3000`
- `LUMEN_WEB_PORT=51910`

Override if needed:

```sh
LUMEN_API_BASE_URL=http://127.0.0.1:3001 LUMEN_WEB_PORT=52000 ./scripts/dev_web_api.sh
```

Then open:

```text
http://127.0.0.1:<LUMEN_WEB_PORT>
```

## 4. Manual Verification Checklist

1. Create a typed entry.
2. Edit and save that entry.
3. Use `Regenerate AI rewrite` on entry detail.
4. Create a voice entry and save transcript.

Expected:

- In mock API mode, rewrites include `[API mock: rewrite endpoint]`.
- In OpenAI mode, rewrites and transcription come from OpenAI responses.

## 5. Mobile/Emulator Base URL Notes

`localhost` differs by device:

- Web browser: `http://127.0.0.1:3000`
- Android emulator: `http://10.0.2.2:3000`
- iOS simulator: usually `http://127.0.0.1:3000`
- Physical devices: use your host machine LAN IP and matching firewall rules.

For non-web runs, pass `LUMEN_API_BASE_URL` explicitly:

```sh
flutter run --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://10.0.2.2:3000
```

## 6. Troubleshooting

1. Rewrites still look like Flutter mock output:
`[Flutter mock: ...]`
This means API mode was not enabled in the Flutter build. Rebuild using `./scripts/dev_web_api.sh`.

2. Browser still shows old behavior after changes:
Stop the current static server and run `./scripts/dev_web_api.sh` again.

3. `Regenerate AI rewrite` errors:
Confirm API process is running and `LUMEN_API_BASE_URL` points to the active port.

4. OpenAI mode fails immediately:
Verify `OPENAI_API_KEY` is present in `apps/api/.env` and `LUMEN_AI_PROVIDER=openai`.
