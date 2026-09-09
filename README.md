# Home Assistant Firefly-Pico Add-on

Packages [Firefly-Pico](https://github.com/cioraneanu/firefly-pico) — a mobile-optimized
companion web app for [Firefly III](https://github.com/firefly-iii/firefly-iii) — as a
Home Assistant Supervisor add-on. It doesn't run its own copy of Firefly III; it's a
frontend/companion that talks to an existing Firefly III instance's API (custom entity
icons, sub-tags, transaction templates, and an AI "Ramble" assistant for fast expense
entry).

## Why a wrapper, not a from-source build

Unlike this maintainer's [Icecast add-on](https://github.com/override80/homeassistant-icecast-addon),
Firefly-Pico ships an official multi-arch (amd64/arm64) production image
(`cioraneanu/firefly-pico`) that already bundles nginx, PHP-FPM, redis and the built
frontend behind a single `supervisord`-managed entrypoint. There's no upstream bug to
work around here, so this add-on just wraps that image: it adds `su-exec`/`jq`, reads
Supervisor's `/data/options.json` to export the right environment variables, redirects
the app's SQLite database into the add-on's own `/data` (so it survives updates and
rebuilds), then hands off to the image's original entrypoint as its normal `www-data`
user — no changes to the app itself.

## Configuration

| Option | Required | Description |
|---|---|---|
| `firefly_url` | yes | Base URL of your Firefly III instance, reachable from this container (e.g. another Supervisor add-on's internal address, `http://<slug>.local.hass.io:<port>`) |
| `timezone` | yes | Backend timezone, e.g. `Europe/Rome` |
| `assistant_llm_endpoint` / `_model` / `_api_key` / `_context` | no | Any OpenAI-compatible chat completions endpoint, for the "Ramble" AI assistant |
| `assistant_transcription_endpoint` / `_model` / `_api_key` / `_language` | no | Voice transcription endpoint, for audio Rambles |

Leave the optional fields blank to disable those features — the app's own defaults apply.

## First-run setup

1. Start the add-on and open its web UI on port `6977`.
2. In Firefly III: **Options → Profile → OAuth → Create Personal Access Token**.
3. In Firefly-Pico: **Settings → Setup**, paste that token.

## Persistent data

The SQLite database lives under this add-on's own `/data/database` — it survives add-on
updates and rebuilds, and is included in Supervisor backups like any other add-on's data.
