# CLAUDE.md

Monorepo for Night Ride / Night Rite — AI nightlife companion (Dubai, Tokyo, London, Melbourne).

## First, always

Call `mcp__serena__initial_instructions` before any coding task — first tool call of the
session, before reading files or planning.

| Path | What it is | Detail |
|---|---|---|
| `Nightride/` | Flutter app — user product plus organizer and admin surfaces in one binary | `docs/FLUTTER_APP.md` |
| `PartyAgent/` | Python/FastAPI backend — LangGraph supervisor over six chat agents | `docs/PARTYAGENT.md` |
| `nightride-webpanel/` | Next.js panel — two surfaces: organizer dashboard, admin console | `docs/WEBPANEL.md` |
| `firestore-tests/` | Vitest tests for `firestore.rules` / indexes / storage rules | — |
| `docs/`, `scripts/` | Schema + architecture docs; dev-stack, seed, migrate scripts | — |

Firebase (Auth + Firestore + Storage) is shared source of truth across all three.
Roles are user / organizer / admin — who does what, and where, is in `docs/ROLES.md`.

Read the relevant `docs/` file before working in a subproject — each one lists routes,
key modules, and which parts are still mock data.

## Naming — what a request usually means

Two clients have organizer and admin surfaces, so a bare name is ambiguous. Ask which
one if the request touches both.

| Phrase | Read first | Then edit |
|---|---|---|
| "organizer dashboard" | `docs/WEBPANEL.md` § Organizer surface | `nightride-webpanel/components/organizer/dashboard/sections/*.tsx` — routes are 5-line shims in `app/organizer/(dashboard)/*/page.tsx` |
| "all organizer dashboards" / "every section" | same | all 12 section components above |
| "organizer app screens" | `docs/FLUTTER_APP.md` § Organizer surface | `Nightride/lib/pages/organizer/**` |
| "apply flow" / "onboarding" | `docs/ROLES.md` § Organizer journey | `nightride-webpanel/app/organizer/apply/**` and `Nightride/lib/pages/organizer/organizer_apply_flow_page.dart` — both clients |
| "admin panel" / "admin console" | `docs/WEBPANEL.md` § Admin surface | `nightride-webpanel/components/admin/m3/**` |
| "admin app" | `docs/FLUTTER_APP.md` § Admin surface | `Nightride/lib/pages/admin/**` |
| "the app" | `docs/FLUTTER_APP.md` | `Nightride/` |
| "the agent" / "chat backend" | `docs/PARTYAGENT.md` | `PartyAgent/src/party_agent/**` |

Editing a panel section means editing the section component, not the `page.tsx` shim.

## Key docs
- `docs/FIRESTORE_SCHEMA.md` — authoritative Firestore schema, read before touching data model. `firestore.rules` is tiebreaker if they disagree.
- `docs/ROLES.md` — user/organizer/admin, and the organizer apply → verify → review → operate flow.
- `docs/WEBPANEL.md`, `docs/FLUTTER_APP.md`, `docs/PARTYAGENT.md` — per-subproject structure.
- `LOCAL_DEV.md` — how to run full stack locally (Firebase emulator + local PartyAgent).
- Root `db.mwb` / "Party App Db Schema" docs are outdated, superseded by FIRESTORE_SCHEMA.md.

## Gotchas
- Never commit secrets (`.env`, service account JSONs, `GoogleService-Info.plist`).
- Fresh `git worktree add` checkouts miss gitignored files Flutter needs (Debug/Release.xcconfig, GoogleService-Info.plist, .env, Pods). Copy from an existing worktree, then `pod install`.
- Large parts of the organizer dashboard and the Flutter home/search/map screens still render mock data (`lib/organizer/dashboard/mock-data.ts`, `Nightride/lib/data/*_dummy_data.dart`). Verify before assuming a screen is wired to Firestore.
- "Night Ride" and "Night Rite" branding both intentional, not a typo.
