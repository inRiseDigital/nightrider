# nightride-webpanel

Admin & organizer dashboard for Night Ride, built on Next.js 16 (App Router) + React 19 and deployed as a static site against Firebase.

## Stack

- Next.js 16 / React 19, TypeScript
- Tailwind v4 with a brand design system (`--nr-*` tokens in `app/globals.css`, mirrored from the Flutter app's `nr_design_system.dart`/`app_theme.dart`) + the Anton display font
- Firebase JS SDK (Auth + Firestore + Storage) — the same shared backend used by the rest of the Night Ride monorepo
- `react-map-gl` (Mapbox) for map views
- Static export: `next.config.mjs` sets `output: "export"` — there are no server routes/route handlers/server actions, the whole panel talks to Firebase directly from the browser

## Deploy

Netlify builds and serves the panel — `netlify.toml` at the repo root sets `base = "nightride-webpanel"`, `command = "npm run build"`, `publish = "out"`. That Netlify build is the client-facing deploy. Firebase is **not** used for hosting here (`firebase.json`'s `hosting` block is an unused stub) — Firebase is only the data backend. The `NEXT_PUBLIC_FIREBASE_*` vars in `.env.example` are public web config (not secrets — access is enforced by `firestore.rules`) and must be set in Netlify's environment variables, since they're inlined at build time.

Netlify also runs the small set of server-side functions the schema requires (see below), under `netlify/functions/`.

## Firestore schema

**`docs/FIRESTORE_SCHEMA.md` (repo root) is the authoritative schema** — read it before touching any Firestore data model. `firestore.rules` enforces it and is the tiebreaker if the two ever disagree; `firestore-tests/` is its executable form (105 cases, `npm test`). There is no `venues.approvals` subcollection, `kycStatus`/`kycDetails`/`appeals`/`banned`/`loginHistory` on `users`, `organizer_requests`, `avatars` as a collection, `live_hub_*`, or any Cloud Functions — an earlier draft of this README described that shape and none of it was ever built.

## What's actually built

### No Cloud Functions — a few Netlify Functions instead

Admin actions are ordinary client writes authorised by `users/{uid}.isAdmin`. Four operations genuinely need an Admin SDK context (setting `isAdmin`, deleting KYC objects, deleting an account, migrating documents) and run as Netlify Functions using `lib/firebase-admin.ts`:

| Function | Path | Purpose |
|---|---|---|
| `admin-kyc.mts` | `POST /api/admin/kyc` | delete KYC evidence on a decision |
| `admin-retention.mts` | `GET`/`POST /api/admin/retention` | dry run, or sweep on demand |
| `admin-scheduled-retention.mts` | `@daily`, not HTTP-reachable | unattended retention sweep |
| `admin-account.mts` | `DELETE /api/admin/account` | erase an account |

`lib/admin/kyc-retention.ts` is the client-side wiring for these — the real, backend-backed exception to the admin panel otherwise being a UI prototype (below).

### `app/admin/**` — admin panel (mostly UI prototype)

Dashboard, users, clubs, events, organizers, admins, roles, activity. General CRUD (ban, approve, promote, etc.) is still local React Context state seeded from deterministic mock data:

- `lib/admin/store.tsx` — in-memory state; actions only mutate local state and a local activity log
- `lib/admin/mock-data.ts` — seeded fake users/clubs/events (deliberately avoids `Math.random()`/`Date.now()` at module scope to avoid SSR/CSR hydration mismatches)
- `components/admin/ui/` — shared component library (Button, Badge, Card, DataTable, Modal, Drawer, ConfirmDialog, Toast, etc.)

**There is no Firestore wiring and no enforced auth gate on `/admin` routes** for this general CRUD — `isAdmin` exists only as a mock-data field used in UI filters, not a real permission check. Don't assume this surface reads or writes real data, except where it calls the Netlify Functions above.

### `app/organizer/**` — organizer flow (apply/login real, dashboard still mock)

- `apply/` and `login/` are real and Firestore-backed, matching `docs/FIRESTORE_SCHEMA.md`: an applicant's `organizerApplication` (steps `venueAddress`, `nic`, `selfie`, `video`, `gps`) lives on their own `users/{uid}` document (`lib/organizer/application-service.ts`); the admin's verdict lives separately in the create-once, admin-only `users/{uid}/private/organizerReview`. There is no separate `organizers` collection.
- Auth is the Firebase Auth SDK directly (`getAuth`, `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `onAuthStateChanged` in `lib/firebase.ts` / `lib/organizer/store.tsx`). `next-auth` is a listed dependency but is not used anywhere.
- The post-login `(dashboard)` shell (tonight/events/calendar/inbox/performance/promotion/reviews/team/venues/ai-visibility/settings) is still mock data (`lib/organizer/dashboard/store.tsx`) — a UI shell, not wired to a real backend yet.

## Commands

```bash
npm install
npm run dev      # next dev --webpack (turbopack disabled intentionally)
npm run build    # static export -> out/, what Netlify publishes
npm run lint
```

`npm run start` (`next start`) is a leftover script — it does not work against a static export (`output: "export"`, no server to start). To preview a production build locally, serve `out/` with any static file server (e.g. `npx serve out`).
