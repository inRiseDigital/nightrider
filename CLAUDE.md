# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a monorepo for **Night Ride / Night Rite** — an AI nightlife companion for Dubai, Tokyo, London, and Melbourne. Four independent sub-projects, three of which are deployable:

| Path | Stack | Role |
|---|---|---|
| `Nightride/` | Flutter (Dart 3.7+) | iOS/Android/web mobile app — the user-facing client |
| `PartyAgent/` | Python 3.11+, LangGraph + Claude, FastAPI | The AI chat backend the app streams from |
| `nightride-webpanel/` | Next.js 16 / React 19, Firebase | Admin & event-publisher dashboard |
| `_cleanup_backup_2026-05-17/` | — | Old backup; ignore |

Firebase (Auth + Firestore + Storage) is the shared source of truth across all three. The root also holds product/spec docs (`.pdf`/`.docx`), a DB schema (`db.mwb`, "Party App Db Schema" PDFs), and `Nightride_Infrastructure_Requirements.md` (hosting plan — Hetzner VPS for the agent, Firebase for data).

## How the pieces connect

- The Flutter app's **chat tab streams from the PartyAgent backend** over Server-Sent Events: `POST {BACKEND_URL}/chat/stream` (see `Nightride/lib/data/services/chat_service.dart`). `BACKEND_URL` is compiled in via `--dart-define` and defaults to a devtunnel URL — override it for real builds.
- All three projects read/write the same **Firestore collections**: `users`, `venues`, `events`, `approvals`, `logs`. Schema and workflow (KYC, approval queues, duplicate detection, auto-scan) are documented in `nightride-webpanel/README.md` — read it before touching any Firestore data model.
- The Flutter app talks to Firestore directly (`Nightride/lib/services/`) for auth, profiles, favourites, notifications; the agent backend has its own Firestore/Postgres access for events and memory.

## PartyAgent (AI backend)

LangGraph multi-agent system: **Supervisor routes each user turn to one of 6 specialist agents**, each of which ends the turn (next message re-enters at the supervisor). See `src/party_agent/graph.py` for the compiled `StateGraph`.

Specialists live in `src/party_agent/agents/<name>/` — `event_discovery`, `map_navigator`, `social_companion`, `gamification`, `night_recap`, `safety_support`. Each agent's behaviour/persona is authored in a top-level `agentN_*.md` file loaded via `agents/_md_loader.py`.

Key layers: `core/` (LLM factory, shared `AgentState`, prompts, cost tracking, observability), `supervisor/` (intent routing), `tools/` (what agents call), `integrations/` (raw external API clients — Google Maps, OpenWeather, Ticketmaster, Eventbrite, PredictHQ, SerpAPI, Uber, Instagram/TikTok, web crawler), `memory/` (LangGraph checkpointer + long-term store, Postgres/Redis), `safety/` (stealth mode, privacy, content filters), `api/` (FastAPI HTTP layer), `data/` (DB models + pgvector index).

**Models are configured per-role** in `src/party_agent/config.py`: router = Haiku, specialists = Sonnet, night_recap = Opus, crawl extractor = Haiku. Memory (Postgres + Redis) is optional — the graph compiles and runs without a checkpointer/store; the crawler fallback needs `crawl4ai` + a headless browser and is skipped if unavailable.

```bash
cd PartyAgent
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                                 # then paste ANTHROPIC_API_KEY
docker-compose up -d                                 # optional: Postgres + Redis for memory
python run_server.py                                 # serves FastAPI; PARTY_AGENT_PORT (default 8000)
python scripts/run_local.py                          # CLI sanity check, no server
pytest                                               # asyncio_mode=auto; testpaths=tests
pytest tests/path/to/test_file.py::test_name         # single test
ruff check src                                        # lint (line-length 100)
```

Always launch the server with `python run_server.py`, not the bare `uvicorn` CLI — on Windows psycopg's async pool requires a `SelectorEventLoop` that the script forces (see the module docstring).

## Nightride (Flutter app)

State management is **Riverpod** (`flutter_riverpod` 3.x, some codegen via `riverpod_generator`). Navigation is a bottom-nav `IndexedStack` in `lib/pages/app_shell_page.dart` (Map / Home / Chat / Favourites / Profile) — despite the `go_router` dependency and stale `lib/features/...` path comments, routing is index-based, not declarative. Config is loaded with `flutter_screenutil` (responsive sizing) and theme lives in `lib/core/theme/`.

Directory roles: `pages/` (screens), `components/` (reusable widgets), `providers/` (Riverpod state), `domain/` (models + `rank_system.dart`), `data/` (`*_dummy_data.dart` mock data, plus real `data/services/` and `data/models/` for chat), `services/` (Firestore/Auth/notifications), `l10n/` (12 locales — edit `.arb` files, never the generated `app_localizations*.dart`).

**Secrets/keys are compile-time constants**, not runtime env. Google Maps, Yelp, etc. are read via `String.fromEnvironment` (`lib/core/config/maps_config.dart`) and must be passed as `--dart-define`. `flutter_dotenv` is a dependency but `.env` is not loaded at startup.

```bash
cd Nightride
flutter pub get
flutter gen-l10n                                      # regenerate localizations after editing .arb
dart run build_runner build --delete-conflicting-outputs   # regenerate Riverpod codegen
flutter run --dart-define=BACKEND_URL=... --dart-define=GOOGLE_MAPS_API_KEY=...
flutter analyze                                       # lint (flutter_lints)
flutter test                                          # all tests
flutter test test/widget_test.dart                   # single test file
dart run flutter_launcher_icons                       # regenerate app icons from assets/images/logo.png
```

iOS release is built by **Codemagic** (`codemagic.yaml`, workflow `ios-testflight`), triggered on push to `main`, working dir `Nightride`, bundle id `com.therisetechvillage.nightride`. It bumps the build number by +100 and publishes to TestFlight.

## nightride-webpanel (admin dashboard)

Next.js App Router (`app/`) on Firebase. Auth via `next-auth` + Firebase; admin gate is a Firestore `users` doc field (`isAdmin`). Firestore access rules and composite indexes are committed (`firestore.rules`, `firestore.indexes.json`) — deploy them with the app. The README contains the full intended feature spec (admin queues, KYC, publisher dashboard, duplicate/geohash detection, Firebase Functions workflows) — much is spec, not yet built, so verify against `app/` before assuming a feature exists.

```bash
cd nightride-webpanel
npm install
npm run dev                                           # next dev (turbopack disabled intentionally)
npm run build && npm run start
npm run lint
```

## Conventions & gotchas

- **Never commit secrets.** `.env`, `firebase_service_account.json`, `google-services.json`, and `GoogleService-Info.plist` are gitignored per the root `.gitignore`. The PartyAgent needs a `firebase_service_account.json`; admin-elevation helper `set_admin.py` (root) reads it.
- The product is branded both "Night Ride" and "Night Rite" (e.g. "Open in Night Rite Map") — the mixed naming is intentional, not a typo to fix.
- Current work is on the `ios-build` branch; PRs target `main`.
