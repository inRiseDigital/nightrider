# CLAUDE.md

Monorepo for Night Ride / Night Rite — AI nightlife companion (Dubai, Tokyo, London, Melbourne).

| Path | Stack |
|---|---|
| `Nightride/` | Flutter app |
| `PartyAgent/` | Python/FastAPI AI chat backend |
| `nightride-webpanel/` | Next.js admin dashboard |
| `_cleanup_backup_2026-05-17/` | ignore |

Firebase (Auth + Firestore + Storage) is shared source of truth across all three.

Call `mcp__serena__initial_instructions` at start of session before coding tasks.

## Key docs
- `docs/FIRESTORE_SCHEMA.md` — authoritative Firestore schema, read before touching data model. `firestore.rules` is tiebreaker if they disagree.
- `LOCAL_DEV.md` — run full stack locally (Firebase emulator + local PartyAgent).
- Root `db.mwb` / "Party App Db Schema" docs are outdated, superseded by FIRESTORE_SCHEMA.md.

## Commands

**PartyAgent**
```bash
cd PartyAgent && source .venv/bin/activate
python run_server.py     # always use this, not bare uvicorn
pytest
ruff check src
```

**Nightride**
```bash
cd Nightride
flutter run --dart-define=BACKEND_URL=... --dart-define=GOOGLE_MAPS_API_KEY=...
flutter analyze
flutter test
```

**nightride-webpanel**
```bash
cd nightride-webpanel
npm run dev
npm run build   # static export -> out/, deployed on Netlify
npm run lint
```
(`npm run start` doesn't work — static export, no server.)

## Gotchas
- Never commit secrets (`.env`, service account JSONs, `GoogleService-Info.plist`).
- Fresh `git worktree add` checkouts miss gitignored files Flutter needs (Debug/Release.xcconfig, GoogleService-Info.plist, .env, Pods). Copy from an existing worktree, then `pod install`.
- "Night Ride" and "Night Rite" branding both intentional, not a typo.
