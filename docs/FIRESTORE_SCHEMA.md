# Firestore schema — Night Ride / Night Rite

The authoritative document shape. `firestore.rules` enforces what is written
here; where the two disagree, the rules win and this file is the bug.

Conventions: `lowerCamelCase` field names, `Timestamp` for time, `GeoPoint` for
position, numbers for money, string enums instead of free text. Collection ids
are `lowerCamelCase` except `chat_sessions`, which keeps its existing name
because the client already uses it.

## Privilege model

There are no Cloud Functions. Admin actions are ordinary client writes
authorised by `users/{uid}.isAdmin`, a field only the Admin SDK can set. Four
things genuinely require an Admin SDK context, and all four belong to the
webpanel's server side:

| Operation | Why it cannot be a client write |
|---|---|
| Set `isAdmin` | Rules pin the field against every client, admins included |
| Delete KYC objects | Storage rules deny `delete` to every client |
| Delete an account | Client delete on `users/{uid}` would strand immutable KYC objects |
| Rewrite existing documents | One-off migration of pre-schema data |

Two invariants carry most of the security weight:

1. **An applicant never writes a verdict.** Everything an admin decides lives in
   `users/{uid}/private/organizerReview`, which the applicant may create exactly
   once in a pinned initial shape and can never update.
2. **The KYC attempt counter is admin-owned.** Storage paths are keyed by
   `organizerReview.steps.<id>.attempt`, so the retry cap is structural — an
   applicant cannot mint new upload paths.

## users/{uid}

Document id is the Firebase Auth uid. `role` and `isOrganizer` do not exist.
Organizer access is `organizerStatus == 'approved'` and nothing else.

```
users/{uid} {
  // identity
  email, displayName, username, pronouns, bio: string
  city, countryCode, ageRange: string
  avatarUrl: string                  // https URL of avatars/{uid}.jpg, "" if none
  instagram, facebook, phone: string
  interests, genres, vibes, features: string[]

  // gamification — client-authored by design, not an access-control surface
  rank, streakDays, partiesAttended, friendsCount: number
  lastActiveDate: string             // "YYYY-MM-DD", daily point-award guard

  // access — admin-owned, pinned against self-writes
  isAdmin: bool                      // Admin SDK only
  organizerStatus: 'none' | 'pending' | 'approved' | 'rejected' | 'revoked'

  organizerApplication: OrganizerApplication

  createdAt, updatedAt: Timestamp
}
```

`organizerStatus` is `'none'` on every document from creation — the create rule
requires it, so no query needs a missing-field branch. It duplicates
`organizerReview.status` deliberately: it keeps `isOrganizer()` on the same
cached document read as `isAdmin()`, and an admin writes both in one batch.

`rank` may only rise, by at most 50 per write. That bounds a single write, not a
session; the gamification counters are honour-system and are documented as such.

### OrganizerApplication — applicant-authored, advisory

```
OrganizerApplication {
  submitted: bool
  submittedAt: Timestamp             // == request.time, enforced
  profile: {
    orgName, venueName, instagram, website, bio: string
    eventTypes: string[]
    eventsPerMonth: number
  }
  steps: {
    venueAddress: {
      address, city, countryCode: string
      geo: GeoPoint | null           // dropped pin, or geocoder result
      placeId: string                // "" if the pin was hand-placed
    } | null
    nic:    { uploaded: bool }
    selfie: { uploaded: bool }
    video:  { uploaded: bool }
    gps:    { attempts: GpsObservation[] }
  }
}
```

Nothing here is load-bearing. `steps.nic.uploaded` and friends are the
applicant's claim that they uploaded something; the review UI derives the real
object paths from `kyc/{uid}/{stepId}/{attempt}/…`, which is deterministic, and
reads the objects directly. `profile.venueName` carries no verification status
because there is nothing to verify about a name — no document, sensor, or third
party settles it.

```
GpsObservation {
  point: GeoPoint
  accuracyM: number
  mocked: bool                       // geolocator Position.isMocked
  capturedAt: Timestamp              // client clock, see below
  attempt: number                    // the admin-owned attempt it belongs to
}
```

Timestamps inside array elements are client clocks: Firestore rejects
`serverTimestamp()` sentinels inside an array element. The trustworthy time is
`organizerApplication.submittedAt`, which rules pin to `request.time`; comparing
it against the last observation's `capturedAt` is what surfaces clock skew.

The review UI computes the distance between a `GpsObservation.point` and the
accepted venue address by haversine at render time, shows both pins and the
accuracy circle, and flags a crossed distance/accuracy/`mocked` threshold for
attention. It never auto-rejects.

### users/{uid}/private/organizerReview — the verdict document

Created once by the applicant so the flow can start without an admin round-trip.
Every mutation after that is admin-only.

```
users/{uid}/private/organizerReview {
  status: 'none' | 'pending' | 'approved' | 'rejected' | 'revoked'
  appliedAt, decidedAt: Timestamp | null
  decidedBy: string                  // admin uid, "" when undecided
  rejectionReason: string            // "" unless status == 'rejected'
  phoneVerified: bool
  steps: {
    venueAddress: ReviewStep         // gates gps
    nic:    ReviewStep
    selfie: ReviewStep
    video:  ReviewStep
    gps:    ReviewStep
  }
  updatedAt: Timestamp
}

ReviewStep {
  status: 'pending' | 'active' | 'submitted' | 'needs_info' | 'accepted'
  attempt: number                    // 0..3, admin-advanced; keys the Storage path
  note: string                       // admin's request or rejection note, "" otherwise
  reviewedAt: Timestamp | null
  reviewedBy: string | null
  venueId: string | null             // venueAddress only, set when a venue is created
  mediaDeletedAt: Timestamp | null   // stamped when the objects are deleted
}
```

Required initial shape, checked by the create rule: `status: 'none'`,
`decidedBy: ''`, `rejectionReason: ''`, `decidedAt: null`,
`phoneVerified: false`, every `attempt: 0`, and step statuses
`venueAddress/nic/selfie/video: 'active'` with `gps: 'pending'`.

`gps` starts `'pending'` and only an admin moves it to `'active'`, after
accepting `venueAddress` — a gps fix is only worth capturing once there is an
admin-verified address to measure it against. Accepting `venueAddress` is also
what creates the venue document: an admin reads the applicant's address data
together with `organizerApplication.profile.venueName`, creates
`venues/{venueId}`, and stamps the id into `steps.venueAddress.venueId`.

A `needs_info` cycle on a file step means the admin advances `attempt`, which
opens exactly one fresh set of Storage paths. `attempt` is capped at 3 by the
rules; past that an admin must reset the step.

There is no `sha256`, no `extraSteps`, no postcard or video-call step type, and
no scheduling. Five pieces of evidence from a handful of applicants do not need
content-addressing, and a scheduled-call state machine has no UI and no writer.

### users/{uid} subcollections

```
users/{uid}/favourites/{eventId} {
  // denormalised event card, deliberately duplicated for offline rendering
  name, venueName, city, countryCode, coverImage, genre: string
  startAt: Timestamp
  savedAt: Timestamp
}

users/{uid}/settings/privacy {
  publicProfile, showLocation, showActivity, twoFactor: bool
}

users/{uid}/chat_sessions/{sessionId} {
  title: string
  createdAt, updatedAt: Timestamp
}
users/{uid}/chat_sessions/{sessionId}/messages/{messageId} {
  role: 'user' | 'assistant'
  text: string
  at: Timestamp
}
```

Messages are a subcollection, not an array on the session document: an inline
array grows without bound against the 1 MiB document limit and rewrites the
whole document on every turn.

Writes to `chat_sessions` require a verified email. The Auth emulator creates
accounts with `emailVerified: false`, so local seed data must set it explicitly
or chat will look broken.

## events/{eventId}

One shape, written identically by the organizer sheet, the admin panel, and any
scraper. Document id is auto-generated.

```
events/{eventId} {
  name: string                       // canonical title
  description: string

  venueId: string | null
  venueName: string                  // denormalised for list rendering
  city: string
  countryCode: string                // ISO-3166 alpha-2, uppercase
  geo: GeoPoint | null

  startAt: Timestamp
  endAt: Timestamp | null

  price: { min: number, max: number, currency: string, isFree: bool }
  ticketUrl, coverImage: string
  genre, category, vibe, language: string

  performers: [{ name: string, type: 'DJ'|'Band'|'Comedian'|'LiveAct'|'Other', bio: string }]
  policies: {
    ageRestriction: number
    refundPolicy: string
    reEntryAllowed, wheelchairAccessible, allowPets: bool
  }

  interestedCount: number            // marker-subcollection increments only
  popularityScore: number            // Admin SDK ingest only, 0 for hand-entered

  status: 'draft' | 'published' | 'archived'
  source: 'organizer' | 'admin' | 'scraped'
  organizerUid: string | null

  createdAt, updatedAt: Timestamp
}

events/{eventId}/interested/{uid} { at: Timestamp }
```

Rules validate the shape on every create and update. This is not belt-and-braces:
Firestore excludes a document missing an ordered field from the result set
entirely, so an event written without `startAt` or `name` vanishes from search,
home, and trending rather than rendering badly, and a missing `geo` puts a map
pin at (0,0). Three clients write here and nothing normalises on the way in.

`title`, `date`, `start_time`, `created_at`, `price_hint`, `country_code`,
`cover_image`, `venue_name`, `watchingCount`, `isTrending` and a free-text price
do not exist. Trending is the top N by `interestedCount` among published events.
`status` has no review states: an admin unpublishes by setting `archived`. A
moderation queue would be a system with no operators at this scale.

Registering interest is a two-write batch — `events/{id}/interested/{uid}` and
the `interestedCount` increment together. The order is load-bearing: committed
on its own first, the marker makes the increment denied forever.

## venues/{venueId}

Globally seeded from OpenStreetMap. Document ids are `osm_{osmId}` for seeded
venues, auto-generated for the rest. Organizers cannot create venue documents;
accepting an applicant's `venueAddress` step is what creates one.

```
venues/{venueId} {
  name: string
  geo: GeoPoint
  geohash: string                    // 9-char, for radius queries
  type, typeLabel: string            // OSM amenity + display form
  city, countryCode, address: string
  openingHours, phone, website: string
  photos: string[]
  source: 'osm' | 'organizer' | 'admin'
  osmId: string | null
  ownerUid: string | null            // the approved organizer who manages door status
  verified: bool
  status: 'active' | 'closed'

  live: {                            // door status, owner- or admin-written
    status:      'open' | 'closed' | 'vipOnly' | 'soldOut'
    crowdLevel:  'empty' | 'quiet' | 'moderate' | 'busy' | 'packed'
    queueStatus: 'noQueue' | 'short' | 'moderate' | 'long' | 'closed'
    ticketsAvailable, tablesAvailable: bool
    tonightDj, offer: string
    updatedAt: Timestamp             // == request.time, enforced
  }

  createdAt, updatedAt: Timestamp
}
```

`live` is a map on the venue document rather than a `live/current`
subcollection: a subcollection turns the Live Hub club list into 1 + N reads
over a globally seeded collection. The "N minutes ago" label is rendered from
`live.updatedAt`, never stored as text.

`geohash` replaces the live Overpass call the app currently makes on every load.
`lat`/`lng`/`country_code`/`type_label`/`opening_hours`/`osm_id` and a `stats`
map do not exist — three counters with no maintainer go stale; a venue's event
count is a query and its vibe average comes from the reports the Live Hub
already reads.

Country-scoped venue queries must carry a `limit`. The seeded collection is
global, and an unbounded `where countryCode == …` pulls all of it.

## venueReports/{reportId}

```
venueReports/{reportId} {
  venueId: string
  uid: string                        // author, == request.auth.uid
  username, avatarUrl: string
  city, countryCode: string
  tag: string
  vibeRating: number                 // 1..5
  comment: string                    // "", or up to 500 chars
  upvoteCount: number
  createdAt: Timestamp               // == request.time, enforced
}

venueReports/{reportId}/upvotes/{voterUid} { at: Timestamp }
```

`comment` is always present, defaulting to `""` — omitting the field is what
made every commentless report fail the old rule. `vibeRating` is validated as a
number in 1..5 rather than `is int`, because a slider yields `4.0`.

An upvote is the same two-write batch as event interest, with the same ordering
requirement. Upvotes are permanent by design: there is no un-upvote, and racing
batches can over-count by one.

## Live Hub — composition, not a collection

There is no `live_hub_*` collection. The tab is three queries:

- **Clubs** — `venues where countryCode == X limit N`, reading `live` inline
- **Reports** — `venueReports orderBy createdAt desc limit 50`
- **Social** — `events where status == 'published' && source == 'scraped'
  orderBy popularityScore desc`

A second parallel event pipeline was the defect in the old three-collection
split; scraped listings are events and live in `events`.

## logs/{logId}

```
logs/{logId} {
  action: 'event.publish' | 'event.archive' | 'organizer.approve'
        | 'organizer.reject' | 'organizer.revoke' | 'venue.create'
        | 'report.delete' | 'kyc.needsInfo' | 'kyc.accept'
  actorUid: string
  targetType: 'event' | 'venue' | 'user' | 'report'
  targetId: string
  summary: string                    // one line, <= 500 chars
  at: Timestamp                      // == request.time, enforced
}
```

Create-only, admin-read, written alongside the action it records. An
accountability record, not a tamper-proof ledger: an admin with write access to
the target also has write access to the log. Full before/after document maps are
not stored — an unbounded copy of every mutated document on a collection nobody
prunes is a storage problem pretending to be an audit trail.

Retired, and denied explicitly so the intent is on the record: `approvals`,
`organizer_requests`, `avatars`, `live_hub_clubs`, `live_hub_reports`,
`live_hub_social`. Also absent: `kycStatus`, `kycDetails`, `appeals`, `banned`,
`loginHistory`. Account suspension is the Firebase Auth `disabled` flag, not a
Firestore boolean nothing checks.

## Cloud Storage

```
avatars/{uid}.jpg

kyc/{uid}/nic/{attempt}/front.jpg
kyc/{uid}/nic/{attempt}/back.jpg
kyc/{uid}/selfie/{attempt}/capture.jpg
kyc/{uid}/video/{attempt}/walkthrough.mp4
kyc/{uid}/video/{attempt}/poster.jpg
```

`{attempt}` is `organizerReview.steps.<id>.attempt`, which only an admin
advances. With create-only permission and an explicit `resource == null` check,
that makes two properties structural rather than a matter of client behaviour:
reviewed evidence cannot be overwritten, and an applicant cannot burn storage,
because they cannot move the number in the path. Filenames are pinned per step,
so an attempt directory cannot be filled with arbitrary objects.

The `resource == null` clause is not redundant, and this is worth stating
plainly because the intuition carried over from Firestore is wrong: in Cloud
Storage, `create` does **not** imply the object is absent. A content re-upload
to an existing path writes a new generation of an immutable object and is still
classified as a create; `update` covers metadata-only mutation. Without that
clause, `allow create` alone leaves reviewed evidence overwritable by the
applicant who submitted it. The rules test suite pins this
(`firestore-tests/tests/storage.test.js`).

The walkthrough video is capped at 60 seconds, 720p, H.264/AAC MP4, 30 MB —
enforced by the recorder preset, a client pre-check, and the Storage rule. The
app extracts the poster frame at capture. There is no thumbnail Cloud Function:
standing up a function runtime, its deploy pipeline, and its IAM surface to
produce one JPEG per applicant is disproportionate, and the poster is navigation
chrome, never evidence — the admin reviews the video itself in a streaming
player. Uploads are resumable; 30 MB over venue Wi-Fi is a multi-minute upload
that will get backgrounded.

Avatars sit in a separate top-level prefix because they are world-readable and
KYC never is. `users.avatarUrl` holds the public download URL; base64 image
blobs are no longer stored in Firestore documents.

### Retention

Identity images are deleted 30 days after approval and 90 days after final
rejection; the walkthrough video is retained while the organizer is active and
deleted 90 days after rejection; gps observations are structured, tiny, and
retained indefinitely.

Deletion runs in the webpanel's **server route** using the Admin SDK — the
Storage rules deny `delete` to every client, so an inline client delete is
impossible, and the webpanel already ships a server. A bucket lifecycle rule of
`age > 180 days` on `kyc/**` backstops anything the admin flow misses. Object
Versioning stays off for this prefix: it would resurrect deleted identity
documents.

Firestore metadata (paths, sizes, reviewer, timestamps, notes) is retained
permanently, which preserves a provable audit trail at no breach cost. A NIC-
plus-selfie pair is exactly the bundle used for identity fraud elsewhere, and
the London cohort puts this under UK GDPR, so scheduled deletion is a
requirement rather than hygiene.

## Client prerequisites

- `firebase_storage` is absent from `Nightride/pubspec.yaml`.
- `nightride-webpanel/lib/firebase.ts` exports `getAuth` and `getFirestore` but
  no `getStorage`.
- The `camera` package is absent. The selfie liveness prompt and the 60-second
  recorder need it rather than `image_picker`, and camera/microphone usage
  strings are not declared in `Info.plist` or `AndroidManifest.xml`.
- Storage CORS is already configured (`cors.json`) and `storageBucket` is
  already in the web Firebase config.
- `venues` has no seeder yet. Until one exists the collection is empty, and the
  map plus Live Hub have nothing to read while seven app files still call
  Overpass live.
