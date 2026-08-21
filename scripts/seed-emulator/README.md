# seed-emulator

Fills the local Firebase emulator (Auth + Firestore + Storage) with realistic
Night Ride / Night Rite data that matches `docs/FIRESTORE_SCHEMA.md` field for
field, so the Flutter app and the webpanel have something real to develop
against instead of an empty database.

This uses the Firebase Admin SDK, which bypasses every Firestore and Storage
security rule. That is exactly why it is the right tool for seed data — it can
write documents in states a client could never legally reach (an approved
organizer review, a rejected application with history, marker subcollections
that back up their counters) in one shot, without acting out the whole
multi-step flow through the rules. It is not a rules test; it does not assert
on permissions anywhere.

## Before you run it

**The Firebase emulator suite must already be running.** This script only
talks to emulators — see `Nightride/scripts/emulators.sh` for the project's
usual way to start one (Auth on 9099, Firestore on 8080, Storage on 9199,
project `nightride-a9173`). Start that first, in a separate terminal, and
leave it running.

## Install

From this directory:

```bash
npm install
```

## Run

With the emulator already running and its ports at the defaults above, just:

```bash
node seed.mjs
```

It prints the emulator hosts it's about to talk to, then writes Auth users,
Firestore documents, and a handful of Storage objects. It finishes by
printing a table of the accounts it created, with their passwords, so you can
log into the app or the webpanel immediately.

### Flags

- `--wipe` — deletes everything in the collections this script owns (`users`,
  `venues`, `events`, `venueReports`, `logs`, and their subcollections) and
  the `avatars/` and `kyc/` Storage prefixes, before seeding. Use this if
  you've been poking at the data by hand and want a clean slate.
- `--force` — seed even if none of `FIRESTORE_EMULATOR_HOST` /
  `FIREBASE_AUTH_EMULATOR_HOST` / `STORAGE_EMULATOR_HOST` are set in the
  environment. Without this flag, the script refuses to run unless
  `FIRESTORE_EMULATOR_HOST` is already set — that check exists so this script
  can never be pointed at a real Firebase project by accident. Passing
  `--force` does not change *where* it writes: it still targets the default
  local addresses below, it just skips the safety check.

### Idempotency

Running `node seed.mjs` twice leaves exactly the same data — no duplicates.
Every document uses a deterministic id (the cast's Auth uids are fixed
strings, venues use their real-world OSM ids or a stable admin slug, events
and reports use small sequential slugs like `evt-01` / `report-07`) and every
write is a full `set()`, not a merge, so reruns simply overwrite the same
documents with the same content.

The one deliberate exception is `events/*.startAt` / `endAt`: those are
computed relative to whenever the script actually runs (2 days ago through
about 6 weeks out), specifically so the app's and webpanel's date-range
queries have real data to page through regardless of what day it is. Rerun
the script on a different day and those two fields shift; nothing else does,
and no duplicate documents are ever created either way.

## What it targets

| Setting | Default | Overridable via |
|---|---|---|
| Project id | `nightride-a9173` | not overridable — hardcoded to match the rest of the repo |
| Firestore | `127.0.0.1:8080` | `FIRESTORE_EMULATOR_HOST` |
| Auth | `127.0.0.1:9099` | `FIREBASE_AUTH_EMULATOR_HOST` |
| Storage | `http://127.0.0.1:9199` | `STORAGE_EMULATOR_HOST` |

These match `Nightride/firebase.json` and `Nightride/scripts/emulators.sh`, so
the default run needs no configuration if you started the emulator the usual
way.

## What gets seeded

- **5 Auth + `users/{uid}` accounts**, covering every point in the organizer
  pipeline: a plain admin, a plain rider, an applicant mid-review, an
  approved organizer who owns a venue, and a rejected applicant with a
  needs_info history on their NIC upload.
- **8 venues** across Dubai, Tokyo, London, and Melbourne — six seeded as if
  from OpenStreetMap, two admin-added (one owned by the approved organizer).
  Five carry a `live` door-status map.
- **12 events** spread across all four countries and all three `source`
  values (`organizer`, `admin`, `scraped`), with `startAt` spanning 2 days ago
  to about 6 weeks out, one free event, a couple with performers and filled
  policies, and `interestedCount` values backed by real
  `events/{id}/interested/{uid}` marker documents.
- **20 venue reports**, varied 1–5 `vibeRating`, some with an empty comment,
  some with `upvoteCount` backed by real `venueReports/{id}/upvotes/{uid}`
  marker documents.
- **6 audit log entries** covering the organizer-approval, organizer-rejection,
  needs-info, KYC-accept, venue-create, and report-delete actions.
- **Storage objects**: an avatar each for the rider and the organizer (with
  `users.avatarUrl` pointed at the emulator's download URL for each), plus the
  applicant's `kyc/{uid}/nic/0/front.jpg`, `back.jpg`, and
  `selfie/0/capture.jpg`. These are tiny, genuinely valid 1×1 JPEGs generated
  in-process — nothing is fetched over the network.

## The cast

| Email | Role |
|---|---|
| `admin@nightride.test` | `isAdmin: true`, `organizerStatus: 'none'` |
| `rider@nightride.test` | Plain user, rank 120, favourites, a 3-message chat session |
| `applicant@nightride.test` | Application submitted, awaiting an admin's first pass |
| `organizer@nightride.test` | Approved, owns Sunset Rooftop Melbourne |
| `rejected@nightride.test` | Rejected after a failed NIC resubmission |

Passwords are printed at the end of every run — they're also fixed strings in
`seed.mjs` (search for `ACCOUNTS`) if you need them before that.

## Production test data (`seed-production-test-data.mjs`)

Separate from everything above. `seed.mjs` refuses to run anywhere but the
emulator by design; this pair is the opposite — it only ever runs against the
live `nightride-a9173` project, with a real
`firebase_service_account.json` at the repo root, and every uid/document id it
writes is prefixed `test-`.

```bash
cd scripts/seed-emulator
npm run seed:prod-test   -- --i-know-this-is-production
npm run unseed:prod-test -- --i-know-this-is-production   # deletes exactly what the above wrote
```

Both scripts refuse to do anything without the flag. The unseed script also
re-checks that every id it is about to delete starts with `test-` — the Admin
SDK bypasses `firestore.rules`, so a dropped prefix would otherwise delete a
real document.

What gets written: 5 Auth users + `users/{uid}` documents (admin, plain rider,
and organizers at approved / mid-verification / rejected), the matching
create-once `users/{uid}/private/organizerReview` verdict documents, one
`venues/{id}` owned by the approved organizer, and 3 `events/{id}`
(published-by-organizer, draft, admin-entered).

| Email | Role |
|---|---|
| `test-admin@nightride.test` | `isAdmin: true` |
| `test-rider@nightride.test` | Plain user |
| `test-organizer-verified@nightride.test` | `organizerStatus: 'approved'`, owns the test venue |
| `test-organizer-pending@nightride.test` | Submitted, untriaged (`organizerStatus: 'none'`) |
| `test-organizer-rejected@nightride.test` | `organizerStatus: 'rejected'` |

Passwords are printed at the end of the run, and are fixed strings in
`ACCOUNTS` in the script.

No Storage objects are written, so the KYC review panes render as missing
files for these accounts — enough to exercise the queue and the verdict
states, not enough to review an image.
