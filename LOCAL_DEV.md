# Running the app fully locally (Firebase emulator + local backend)

This covers running the Nightride Flutter app against a **local Firebase
emulator suite** (no real `nightride-a9173` data touched) and a **local
PartyAgent backend**, instead of real Firebase / the devtunnel default.

## 1. One-time setup: Java

The Firestore/Storage emulators need a JVM. This machine didn't have one.

```bash
brew install openjdk
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

The `sudo ln` registers the JDK with macOS's system Java framework
(`/usr/bin/java`), machine-wide, for every user account — no per-shell
`PATH` export needed after this. Verify with `java -version`.

## 2. Start the Firebase emulator suite

```bash
cd Nightride
./scripts/emulators.sh
```

This runs `firebase emulators:start --project nightride-a9173
--import=./emulator-data --export-on-exit=./emulator-data` — Auth (9099),
Firestore (8080), Storage (9199), and the Emulator UI (4000). Data
persists in `Nightride/emulator-data/` (gitignored) across restarts, as
long as the process gets a clean shutdown (Ctrl+C / SIGTERM, not `kill -9`)
so `--export-on-exit` has time to write.

**Emulator UI**: http://127.0.0.1:4000 — browse Firestore/Auth/Storage
data live. It's hardcoded to whatever `--project` value the suite was
started with (confirm via `curl http://127.0.0.1:4000/api/config`) — it
can only ever show that one project's data, there's no UI switcher.

**Why `--project nightride-a9173`, not a `demo-*` project**: the app's
real Firestore requests already carry `nightride-a9173` (baked into
`firebase_options.dart`, unchanged by `useFirestoreEmulator` — that call
only redirects transport/host, never the project id). The emulators'
`singleProjectMode: true` (in `firebase.json`) makes *Auth* redirect
every request to whatever `--project` was passed, regardless of the
app's own project id. Firestore has no such override and always uses the
real id. Using `nightride-a9173` for `--project` too means Auth,
Firestore, and the Emulator UI all agree — a `demo-*` project would split
Auth into a different, invisible-in-the-UI namespace from Firestore.

Trade-off: a `demo-*` project id also gets automatic Firebase SDK
enforcement that refuses to ever fall through to the real backend if the
emulator wiring fails. Using the real id drops that specific guardrail
(the actual connection is still proven working here, so this is belt
without suspenders, not "unsafe").

## 3. Run the Flutter app against the emulator

```bash
cd Nightride
flutter run -d <device> --dart-define=USE_FIREBASE_EMULATOR=true
```

Wired in `lib/main.dart` right after `Firebase.initializeApp`: connects
`FirebaseAuth`/`FirebaseFirestore` to `localhost` (iOS Simulator/web) or
`10.0.2.2` (Android emulator — auto-detected, no manual switch needed).
Real physical device needs your Mac's LAN IP instead — not wired in yet.

Drop the flag entirely to go back to real Firebase — that's the default.

### Web panel (nightride-webpanel) against the emulator

```bash
cd nightride-webpanel
cp .env.example .env.local        # once
echo NEXT_PUBLIC_USE_FIREBASE_EMULATOR=true >> .env.local
npm run dev
```

Wired in `lib/firebase.ts`'s `getFirebaseAuth`/`getDb`/`getBucket` — same
`nightride-a9173` project id, only the transport changes, same as the
Flutter app above. Remove the env var (or delete `.env.local`) to go back
to real Firebase.

## 4. Run the backend (PartyAgent) locally and point the app at it

**The app does NOT actually read `.env` at runtime** — `Nightride/.env`
is not declared as a Flutter asset (`pubspec.yaml`), so
`dotenv.load(fileName: '.env')` in `main.dart` silently fails, and every
value that's supposed to come from `.env` (`BACKEND_URL`, `APP_API_KEY`)
falls back to whatever's baked in via `String.fromEnvironment` — which
for `BACKEND_URL` is a dead devtunnel default. Editing `.env` alone does
nothing right now. Pass values explicitly instead:

```bash
cd Nightride
flutter run -d <device> \
  --dart-define=USE_FIREBASE_EMULATOR=true \
  --dart-define=BACKEND_URL=http://localhost:8000
```

(Fixing `.env` loading for real would mean adding it to `pubspec.yaml`'s
`assets:` — deliberately not done, since that would also ship the
Mapbox token in plaintext inside real release IPAs, and ship the dead
devtunnel default to production if anyone forgets to override it. Keep
using `--dart-define` for local backend testing.)

Start PartyAgent itself:

```bash
cd PartyAgent
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 GOOGLE_CLOUD_PROJECT=nightride-a9173 python run_server.py
```

Both env vars are required together, and **must be real shell env vars,
not just lines in `PartyAgent/.env`** — `config.py` uses pydantic-settings'
`env_file` loading, which only populates fields declared on the
`Settings` class. Neither var is a declared field, so pydantic silently
ignores them if they're only in `.env`; `firebase_admin` reads them
straight from `os.environ`, which never gets populated that way.

- `FIREBASE_AUTH_EMULATOR_HOST` — makes `firebase_admin.auth.verify_id_token()`
  accept the local Auth emulator's unsigned (`alg: none`) tokens instead
  of only real Firebase-signed ones.
- `GOOGLE_CLOUD_PROJECT` — there's no `firebase_service_account.json` on
  this machine, so `firebase_admin.initialize_app()` has no other way to
  learn which project's tokens to trust. Without it, every request fails
  with a generic `401 "Invalid token"` — the real underlying error
  (`A project ID is required to access the auth service.`) gets masked by
  a broad `except Exception` in `PartyAgent/src/party_agent/api/auth.py`.

Without `AUTH_ENFORCED=false` in `PartyAgent/.env` (that one *is* read
correctly, since it's a real pydantic-settings field), the backend still
enforces the `email_verified` gate — fine as long as the signed-in test
user has a verified email in the Auth emulator.

## 5. Seeding test data

`scripts/seed-emulator/` fills an empty emulator with data that matches
`docs/FIRESTORE_SCHEMA.md` exactly, using the Admin SDK — which bypasses
security rules, and is the reason it is the right tool for seed data.

```bash
cd scripts/seed-emulator
npm install                     # once
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
STORAGE_EMULATOR_HOST=http://127.0.0.1:9199 \
  node seed.mjs
```

It refuses to run without `FIRESTORE_EMULATOR_HOST`, so it cannot be
pointed at production by accident, and it is idempotent — a second run
overwrites rather than duplicates. `--wipe` clears the collections it owns
first. It prints the five seeded accounts and their passwords at the end;
they cover every access state (admin, plain user, submitted applicant,
approved organizer, rejected applicant), and all of them have
`emailVerified: true`, because chat writes are gated on a verified email
and the Auth emulator otherwise defaults it to false.

The old approach in this section — pulling real events over the public
REST API and PATCHing them in — no longer works, and is worth
understanding rather than just deleting. `events` was `allow read: if
true`; it is now readable only per-document for published events, so an
anonymous *list* is denied outright. That is the rule working, not a
regression.

## 6. Rules tests

`firestore-tests/` runs the security rules against a real emulator that it
starts and tears down itself, on non-default ports (Firestore 8180,
Storage 9299) so it never collides with the suite you are developing
against.

```bash
cd firestore-tests
npm install                     # once
npm test
```

105 cases across users, the organizer review document, events, venues,
venue reports, logs and Storage. They are the executable form of
`docs/FIRESTORE_SCHEMA.md`: if the two disagree, the tests are right.

## 7. Migrating pre-schema data

`scripts/migrate-schema/` rewrites documents written before the current
schema — legacy events in particular, which have no `startAt` and so drop
out of every indexed query rather than merely rendering badly.

```bash
cd scripts/migrate-schema
npm install                     # once
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node migrate.mjs            # dry run
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node migrate.mjs --apply    # commit
```

Dry run is the default because it rewrites real user data. `--apply`
commits; `--delete-retired` removes the retired collections and only runs
alongside `--apply`, never in the same pass that writes. Targeting
anything that is not an emulator requires `--i-know-this-is-production`.
Running it twice is a no-op.
