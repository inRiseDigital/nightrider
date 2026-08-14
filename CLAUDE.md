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
- All three projects read/write the same **Firestore collections**: `users`, `events`, `venues`, `venueReports`, `logs`. **`docs/FIRESTORE_SCHEMA.md` is the authoritative schema — read it before touching any Firestore data model**, and treat `firestore.rules` as the tiebreaker if the two ever disagree. `firestore-tests/` is the executable form of that document (105 cases, `npm test`).
- An older schema spec still exists and is **superseded**: the root `db.mwb` / "Party App Db Schema" PDFs/docs. None of those collections or fields exist. Neither does `role`, `isOrganizer`, `organizer_requests`, `avatars`, or `live_hub_*`.
- **There are no Cloud Functions.** Admin actions are ordinary client writes authorised by `users/{uid}.isAdmin`, which only the Admin SDK can set. The four operations that cannot be client writes — setting `isAdmin`, deleting KYC objects, deleting an account, migrating documents — live in `nightride-webpanel/netlify/functions/` and `scripts/`.
- A parallel **organizer flow** (apply → verification → approved dashboard) exists in both `Nightride/lib/pages/organizer/` and `nightride-webpanel/app/organizer/`. Applying writes an `organizerApplication` (steps `venueAddress`/`nic`/`selfie`/`video`/`gps`) onto the applicant's `users/{uid}` doc; the admin's verdict lives separately in the create-once, admin-only `users/{uid}/private/organizerReview` — see `docs/FIRESTORE_SCHEMA.md`. The post-approval dashboard shells on both sides are still UI prototypes over mock/local data.
- The Flutter app talks to Firestore directly (`Nightride/lib/services/`) for auth, profiles, favourites, notifications; the agent backend has its own Firestore/Postgres access for events and memory.
- To run the whole stack fully locally (Firebase emulator suite, seeded via `scripts/seed-emulator/`, + local PartyAgent), see `LOCAL_DEV.md` and `Nightride/scripts/emulators.sh`.

## PartyAgent (AI backend)

LangGraph multi-agent system: **Supervisor routes each user turn to one of 6 specialist agents**, each of which ends the turn (next message re-enters at the supervisor). See `src/party_agent/graph.py` for the compiled `StateGraph`.

Specialists live in `src/party_agent/agents/<name>/` — `event_discovery`, `map_navigator`, `social_companion`, `gamification`, `night_recap`, `safety_support`. Each agent's behaviour/persona is authored in a top-level `agentN_*.md` file loaded via `agents/_md_loader.py`.

Key layers: `core/` (LLM factory, shared `AgentState`, prompts, cost tracking, observability), `supervisor/` (intent routing), `tools/` (what agents call), `integrations/` (raw external API clients — Google Maps, OpenWeather, Ticketmaster, Eventbrite, PredictHQ, SerpAPI, Uber, Instagram/TikTok, web crawler), `memory/` (LangGraph checkpointer + long-term store, Postgres/Redis), `safety/` (stealth mode, privacy, content filters), `api/` (FastAPI HTTP layer), `data/` (DB models + pgvector index).

**Models are configured per-role** in `src/party_agent/config.py`: router = Haiku, specialists = Sonnet, night_recap = Opus, crawl extractor = Haiku. Memory (Postgres + Redis) is optional — the graph compiles and runs without a checkpointer/store; the crawler fallback needs `crawl4ai` + a headless browser and is skipped if unavailable.

The `/chat` and `/chat/stream` routes require a verified-email Firebase ID token (`api/auth.py`, `require_verified_user`) — controlled by `AUTH_ENFORCED` + `FIREBASE_SERVICE_ACCOUNT` in `.env` (fails closed/503 if enforcement can't initialize). A `/maps/*` router (`api/routes/maps.py`) proxies Google Maps place search/details/travel-time. For local dev without a service account, set `AUTH_ENFORCED=false` and point at the Firebase emulator (see `LOCAL_DEV.md`).

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

Next.js App Router, TypeScript, Tailwind v4 with a brand design system (`--nr-*` tokens in `app/globals.css`). `next.config.mjs` sets `output: "export"` — a fully client-side static site (no server routes/route handlers/server actions) built to `out/` and deployed on **Netlify** (`netlify.toml`: `base = "nightride-webpanel"`, `publish = "out"`). Firebase (Firestore/Auth/Storage) is the real backend; `firebase.json`'s `hosting` block is an unused stub. Auth is the Firebase Auth SDK directly (`lib/firebase.ts`) — `next-auth` is a listed dependency but unused, don't build against it.

There are no Cloud Functions (see `docs/FIRESTORE_SCHEMA.md`'s privilege model) — the handful of operations that genuinely need an Admin SDK context (setting `isAdmin`, deleting KYC objects, deleting an account, migrating documents) run as **Netlify Functions** in `netlify/functions/` (`admin-kyc.mts`, `admin-retention.mts`, `admin-scheduled-retention.mts`, `admin-account.mts`) via `lib/firebase-admin.ts`.

Two independent surfaces live under `app/`:
- `app/admin/**` (users, clubs, events, organizers, admins, roles, activity) — general CRUD is still local mock state (`lib/admin/store.tsx` + seeded `lib/admin/mock-data.ts`), no Firestore wiring, no enforced auth gate. KYC review / retention / account-deletion (`lib/admin/kyc-retention.ts`) are the real, Netlify-Function-backed exception.
- `app/organizer/**` — `apply/` and `login/` are real and Firestore-backed against `docs/FIRESTORE_SCHEMA.md` (`lib/organizer/application-service.ts`). The post-login `(dashboard)` shell (`lib/organizer/dashboard/store.tsx`) is still mock data.

Firestore access rules and composite indexes are committed (`firestore.rules`, `firestore.indexes.json`), pinned by 105 rules tests in `firestore-tests/` (`npm test`).

```bash
cd nightride-webpanel
npm install
npm run dev                                           # next dev --webpack (turbopack disabled intentionally)
npm run build                                         # static export -> out/, what Netlify publishes
npm run lint
```

`npm run start` (`next start`) is a leftover script and does not work against a static export — there is no server to start.

## Conventions & gotchas

- **Never commit secrets.** `.env`, `firebase_service_account.json`, `google-services.json`, and `GoogleService-Info.plist` are gitignored per the root `.gitignore`. The PartyAgent needs a `firebase_service_account.json`; admin-elevation helper `set_admin.py` (root) reads it.
- **New `git worktree add` checkouts are missing gitignored files `flutter run` needs.** `Nightride/ios/Flutter/Debug.xcconfig` and `Release.xcconfig` (hold `GOOGLE_MAPS_API_KEY`), `Nightride/ios/Runner.xcworkspace`/`Pods/`, `Nightride/ios/Runner/GoogleService-Info.plist` (Firebase config), and `Nightride/.env` (declared as a pubspec asset, so its mere absence fails asset bundling even though it's not loaded at runtime) are all gitignored, so a fresh worktree lacks them — `flutter run -d <ios-sim>` fails in sequence with "Unable to open base configuration reference file...", then "No file or variants found for asset: .env.", then "Build input file cannot be found: .../GoogleService-Info.plist". Before running iOS in a new worktree: copy `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`, `ios/Runner/GoogleService-Info.plist`, and `.env` from an existing worktree's `Nightride/`, then run `cd Nightride/ios && pod install` to generate the workspace/Pods.
- The product is branded both "Night Ride" and "Night Rite" (e.g. "Open in Night Rite Map") — the mixed naming is intentional, not a typo to fix.
