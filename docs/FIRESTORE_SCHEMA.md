# Firestore schema — Night Ride / Night Rite

The authoritative document shape. `firestore.rules` enforces what is written
here; where the two disagree, the rules win and this file is the bug.

Conventions: `lowerCamelCase` field names, `Timestamp` for time, `GeoPoint` for
position, numbers for money, string enums instead of free text. Collection ids
are `lowerCamelCase` except `chat_sessions`, which keeps its existing name
because the client already uses it.

## Privilege model

There are no Cloud Functions. Admin actions are ordinary client writes
authorised by `users/{uid}.isAdmin`, a field only the Admin SDK can set. Six
things genuinely require an Admin SDK or Netlify Function context — four of
them the original set, plus team mutation and scheduled publish — and all six
belong to the webpanel's server side:

| Operation | Why it cannot be a client write |
|---|---|
| Set `isAdmin` | Rules pin the field against every client, admins included |
| Delete KYC objects | Storage rules deny `delete` to every client |
| Delete an account | Client delete on `users/{uid}` would strand immutable KYC objects |
| Rewrite existing documents | One-off migration of pre-schema data |
| Team mutation (`/api/organizer/team`) | Must fan out atomically across `venues.editors`/`.editorUids`, `team/{memberId}`, `venueInvites/{id}` and an activity entry, and accepting an invite is chicken-and-egg — the invitee is not yet an editor and so cannot write `editorUids` itself |
| Scheduled event publish | Rules cannot poll the clock; a Netlify function queries `status == 'scheduled' && scheduledPublish <= now` and flips the status |

Arguably eight, counting two named follow-ups rather than shipped code: FCM
push fanout (`pushCampaigns` create is shape-validated, but the rate limit
itself is enforced by the fanout function, not by rules — rules cannot count
documents) and boost payments. Both are called out where they occur below
rather than counted as live today.

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

The two states that look alike are worth pinning down, because only an admin can
write this field and an applicant must be able to apply without one:

| Situation | `organizerStatus` | `organizerApplication.submitted` |
|---|---|---|
| Never applied | `none` | `false` |
| Applied, nobody has looked yet | `none` | `true` |
| An admin has picked it up | `pending` | `true` |
| Decided | `approved` / `rejected` / `revoked` | `true` |

So the untriaged review queue is `submitted == true && organizerStatus == 'none'`,
ordered by `submittedAt`, and `'pending'` means a human has it — not merely that a
form was sent. The applicant cannot put themselves in either state.

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
  script: VideoScript | null         // video only, null on the other four
}

VideoScript {
  format: 'text' | 'list'            // paragraphs, or a numbered shot list
  lines: string[]                    // 1..20 entries; one paragraph or one shot each
  revision: number                   // 0 on first publish, +1 on each admin edit
  updatedAt: Timestamp
  updatedBy: string                  // admin uid
}
```

Required initial shape, checked by the create rule: `status: 'none'`,
`decidedBy: ''`, `rejectionReason: ''`, `decidedAt: null`,
`phoneVerified: false`, every `attempt: 0`, every `script: null`, and step
statuses `venueAddress/nic/selfie: 'active'` with `gps: 'pending'` and
`video: 'pending'`.

Two of the five steps therefore start locked, each waiting on something an
admin has to do first.

`gps` starts `'pending'` and only an admin moves it to `'active'`, after
accepting `venueAddress` — a gps fix is only worth capturing once there is an
admin-verified address to measure it against. Accepting `venueAddress` is also
what creates the venue document: an admin reads the applicant's address data
together with `organizerApplication.profile.venueName`, creates
`venues/{venueId}`, and stamps the id into `steps.venueAddress.venueId`.

`video` starts `'pending'` too, and what moves it to `'active'` is an admin
publishing a walkthrough script into `steps.video.script`. The walkthrough is
not a generic recording — the admin decides what this particular venue has to
show on camera, and the applicant records against that list. So there is
nothing for the applicant to do until the script exists, and the step stays
locked until it does. In practice the admin writes the script once the other
four steps have been submitted: the applicant's own advisory claims
(`organizerApplication.steps.nic/selfie.uploaded`, the `venueAddress` draft,
and a non-empty `gps.attempts`) are what tell the panel the application is
ready for a script, which is why the applicant-facing UI can show "waiting for
your script" without any write of its own.

The script may be revised after publishing. Each revision bumps
`script.revision` and restamps `updatedAt`/`updatedBy`, and both the applicant
and the admin see a "revised" marker once `revision > 0`. A revision is not an
attempt: it never touches `steps.video.attempt`, so re-scripting does not
consume one of the applicant's three upload slots. As with the rest of this
document there is no history array — only the current script is stored, and the
trail of who changed it when is the `logs` entry each publish writes.

`script.lines` is capped at 20 entries by the rules. Per-entry length is
checked client-side only: rules cannot iterate a list, so the backstop for a
pathological script is Firestore's own 1 MB document limit.

A `needs_info` cycle on a file step means the admin advances `attempt`, which
opens exactly one fresh set of Storage paths. `attempt` is capped at 3 by the
rules; past that an admin must reset the step.

### Reapplying after a rejection

Because the review document is create-once and admin-only afterwards, a rejected
applicant cannot reopen their own steps — deliberately, since a self-service
retry would make the attempt cap meaningless. They are not stuck, though. The
loop is:

1. The applicant edits `organizerApplication` and sets `submittedAt` again. This
   is the one thing they can still do, and the rules pin it to `request.time`.
2. An admin sees them in the reapplication queue —
   `organizerStatus == 'rejected'` ordered by `organizerApplication.submittedAt`,
   which is what the second `users` composite index exists for.
3. The admin advances the relevant step's `attempt` and sets its status to
   `needs_info`. That opens exactly one fresh set of Storage paths.
4. The applicant uploads to the new attempt.

So every retry costs an admin one deliberate action, and the cap holds. The
webpanel therefore has no client-side "resubmit" button, and its absence is the
design rather than an omission.

Three shape questions this document was silent on, settled:

- Every step carries the full `ReviewStep` key set, including `venueId: null` on
  the four steps that will never use it and `script: null` on the four that will
  never carry one. A uniform shape means the review UI and the migration script
  index it the same way for all five.
- There is no per-attempt history array. `ReviewStep` holds only the current
  attempt, status and note. The trail is recoverable without one: each prior
  attempt's evidence still sits at its own immutable `kyc/{uid}/{step}/{n}/…`
  path until retention deletes it, and each decision is a `logs` entry. An
  in-document history array would duplicate both and grow unbounded.
- `venues.live` may be structurally absent, and that now covers the whole map,
  numerics included: a venue nobody has reported on has no door status, no
  queue count, and no crowd count, and inventing zeroes for `inVenue` or
  `queueMinutes` would be as much of a lie as inventing `'closed'` — hence the
  `!touched(['live'])` escape in the rules and the "N minutes ago" label
  rendering from `live.updatedAt` only when the map exists. `doorStatus` exists
  as its own field rather than as a widened `live.status` for the Flutter
  reasons given above (five-value app enum vs. four-value stored enum, and two
  exhaustive switches with no `default:`); the panel projects
  `doorStatus → status` for the fields the app already reads:
  `filling → open`, `capacity → soldOut`, `guestlist → vipOnly`,
  `open → open`, `closed → closed`.

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

users/{uid}/inbox/{messageId} {
  subject, from: string
  type: 'policy' | 'violation' | 'appeal'
  body: string
  venueId: string
  at: Timestamp                      // == request.time, enforced
  readAt: Timestamp | null
}
```

Messages are a subcollection, not an array on the session document: an inline
array grows without bound against the 1 MiB document limit and rewrites the
whole document on every turn.

`inbox` is scoped to the person, not to the venue a message is about, even
though every message here originates from something an admin did to a venue
the organizer edits. That's deliberate: the topbar shows one inbox with one
unread dot across every venue an organizer touches, and scoping by person
means `isSelf(uid)` authorizes read/update with zero venue lookups, rather than
a fan-in across every venue the organizer has a role on. Admin-create,
recipient update limited to `onlyTouched(['readAt'])` — the organizer can mark
a message read and nothing else.

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

  status: 'draft' | 'scheduled' | 'in_review' | 'published' | 'cancelled' | 'archived'
        // `live` is NEVER stored. Derived at read time:
        // status == 'published' && startAt <= now && (endAt == null || now <= endAt)
  source: 'organizer' | 'admin' | 'scraped'
  organizerUid: string | null

  scheduledPublish: Timestamp | null // required non-null iff status == 'scheduled'
  cancelReason: string               // "", required non-empty iff status == 'cancelled'
  notifyOnChange: bool
  recurring: bool
  recurrenceLabel: string            // free text; nothing expands it server-side
  posterImage: string                // coverImage stays the card hero

  tickets: { currency: string, tiers: [{ name: string, price: number, qty: number }] }
        // <= 12 tiers. price.min/max/isFree is derived from this by the client on
        // every write, because price is what six Flutter queries and every list
        // card read, and rules cannot sum a list — that derivation is
        // client-enforced, and it is documented as such rather than pretended away.

  moderation: {                      // admin/producer-owned, pinned
    flag: '' | 'pending' | 'clean' | 'rejected'
    requestedAt: Timestamp
    eta: Timestamp | null            // a Timestamp, not the UI's free-text "~2h" —
                                      // a string can't be compared, sorted, or
                                      // re-rendered against the viewer's clock, and
                                      // the panel only ever displays it as elapsed
                                      // time anyway
    reviewedBy: string | null
    note: string
  }
  sales: {                           // producer-owned, pinned
    sold, gross: number
    currency: string
    updatedAt: Timestamp | null      // null means no producer has ever run for this
                                      // event; the panel renders that as "—", never
                                      // as "0" — a confident zero claims a sellout
                                      // count that nobody has actually taken
  }

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
`cover_image`, `venue_name`, `watchingCount`, `isTrending`, a free-text price,
and a separate `lineup: string[]` do not exist — `performers` already carries
name and bio, and a second lineup field on one document is the same
parallel-pipeline defect this document calls out below for the retired Live Hub
split; the panel projects `lineup[i] ↔ performers[i].name` with `type: 'DJ'` on
write. Trending is the top N by `interestedCount` among published events.
`endAt` is required non-null when `source == 'organizer'`: derived `live`
cannot guess an end time, and every organizer-authored event has one in the UI.
Scraped events keep `endAt: null`.

This document used to say "`status` has no review states: an admin unpublishes
by setting `archived`. A moderation queue would be a system with no operators
at this scale." That is no longer true, and the change is a reversal, not an
amendment: `in_review` plus the `moderation` map above *is* exactly the
moderation queue that sentence rejected, now that the operator exists — an
automated content scan flags events into `in_review`, and admins triage what it
flags. `archived` remains the unpublish verb. `cancelled` is not an
administrative state at all: it is a public statement about a night that is not
happening, which is why it is the one non-`published` status that stays
publicly readable (`status in ['published','cancelled']`) rather than dropping
out of every list the moment it changes. Nothing in the rules stops an
organizer moving `in_review` straight to `published`: rules cannot cheaply
express a transition matrix, and since the organizer already owns the event and
can publish directly from `draft`, gating `in_review` would be theatre —
`in_review` is a queue marker for the scan and for admins, not a lock on the
organizer.

Registering interest is a two-write batch — `events/{id}/interested/{uid}` and
the `interestedCount` increment together. The order is load-bearing: committed
on its own first, the marker makes the increment denied forever.

## venues/{venueId}

Globally seeded from OpenStreetMap. Document ids are `osm_{osmId}` for seeded
venues, auto-generated for the rest. There are now two ways a venue document
comes into existence: an admin accepting an applicant's `venueAddress` step, as
before, and an organizer creating one directly (`source == 'organizer'`,
`verified == false`, `ownerUid == auth.uid`, exactly one editor, that editor
holding `'owner'`). `verified` stays the thing only an admin grants, on either
path — self-creation buys an organizer a venue document, not standing.

```
venues/{venueId} {
  name: string
  geo: GeoPoint
  geohash: string                    // 9-char, for radius queries
  type, typeLabel: string            // OSM amenity + display form
  city, countryCode, address: string
  openingHours, phone, website: string
  photos: string[]                   // <= 5; [0] hero, [1..4] gallery
  source: 'osm' | 'organizer' | 'admin'
  osmId: string | null
  ownerUid: string | null            // the approved organizer who manages door status
  verified: bool
  status: 'active' | 'closed'

  // Profile (mirrors VenueProfile). Direct writes by owner/manager — only
  // `name`/`address` above require an admin-reviewed venueEdits submission.
  about: string                      // <= 2000
  socialLinks: [{ network: string, value: string }]                 // <= 8
  genres: string[]                   // <= 10
  dressCode, agePolicy, tableLink: string
  cover: { min: number, max: number, currency: string }
  capacity: number                   // 0 means unknown
  amenities: string[]                // <= 20
  hours: [{ day, closed, open, close }]                             // exactly 7
  exceptions: [{ label, date, closed }]                             // <= 20
  timeZone: string                   // IANA, e.g. "Asia/Dubai" — see below

  // Authorization, denormalised
  editorUids: string[]               // query key: where editorUids array-contains uid
  editors: { <uid>: 'owner' | 'manager' | 'door' }                  // rules + role UI

  verification: { license: VenueVerifyStep, gps: VenueVerifyStep, video: VenueVerifyStep }

  live: {                            // door status, owner- or admin-written
    status:      'open' | 'closed' | 'vipOnly' | 'soldOut'
    crowdLevel:  'empty' | 'quiet' | 'moderate' | 'busy' | 'packed'
    queueStatus: 'noQueue' | 'short' | 'moderate' | 'long' | 'closed'
    doorStatus:  'open' | 'filling' | 'capacity' | 'guestlist' | 'closed'
    ticketsAvailable, tablesAvailable: bool
    tonightDj, offer: string
    inVenue: number                  // >= 0
    queueMinutes: number             // 0..600
    emergencyActive: bool
    flash: { active: bool, text: string, until: string } | null    // text <= 200
    updatedAt: Timestamp             // == request.time, enforced
  }

  createdAt, updatedAt: Timestamp
}

VenueVerifyStep { status: 'active'|'submitted'|'needs_info'|'done', attempt: 0..3,
                  note: string, reviewedAt, reviewedBy }
```

`timeZone` is a hard prerequisite, not a nicety: `OrganizerEvent` is `date` plus
local `startTime`/`endTime` strings, Firestore is `startAt`/`endAt` Timestamps,
and there is no correct mapping between the two without an IANA zone on the
venue. The browser fallback
(`Intl.DateTimeFormat().resolvedOptions().timeZone`) is right only for a Dubai
organizer sitting at a Dubai laptop — log it and fall back, never trust it as
the source of truth.

`doorStatus` is a new field rather than a widening of `live.status`, and the
reason is Flutter, not taste. `TonightState.status` in the app has five values
and `live.status` has four; any mapping between them collapses `open` and
`filling` into one bucket, which means a reload can silently change what the
organizer themselves selected. Widening the stored `live.status` enum instead
was not available either: `Nightride/lib/pages/live_hub_page.dart:27-62` and
`lib/pages/clubs_page.dart:29-64` each hold a five-value exhaustive switch with
no `default:` branch, so a sixth value would fail to compile on both screens.
`liveOk()` does not join `hasOnly`, so adding `doorStatus` and the two new
numerics costs the existing Flutter client nothing.

`live` is a map on the venue document rather than a `live/current`
subcollection: a subcollection turns the Live Hub club list into 1 + N reads
over a globally seeded collection. The "N minutes ago" label is rendered from
`live.updatedAt`, never stored as text. `menuSections` (below) is the opposite
call for the opposite reason: `live` is read by the 50-document Live Hub list,
so it has to be inline; the menu is read only by the venue-detail view that a
user has already opened, so a subcollection there costs 1+N on a screen that
was going to make a request anyway, and keeps a payload that can run to
hundreds of items off the list read entirely. Same reasoning, opposite
conclusion, because the read path differs.

`geohash` replaces the live Overpass call the app currently makes on every load.
`lat`/`lng`/`country_code`/`type_label`/`opening_hours`/`osm_id` do not exist.

Element shapes *inside* `hours`, `exceptions`, `socialLinks`, and `photos` are
checked client-side only: rules cannot iterate a list, the same limitation
already noted above for `script.lines`, so the only server-side backstop
against a malformed entry is Firestore's own 1 MB document limit. Written down
rather than left implied, the same way it is for the script.

This document used to say a `stats` map does not exist because "three counters
with no maintainer go stale." That objection still holds against exactly what
it was aimed at — unmaintained counters living on the hot venue document,
read on every Live Hub load as if they were current. It does not hold against
what's being added now, and the honest framing is a narrowing of the original
position, not a vindication of it: `venues/{venueId}/metrics/{periodId}` (below)
lives in a subcollection off the 50-document read path, is written only by a
named producer, and carries its own `updatedAt` so the dashboard renders "as of
[time]" rather than implying live freshness. If that producer is never built,
the subcollection is simply absent and the panel shows an empty state — the
same structural-absence pattern `venues.live` already uses, not a fallback
value pretending to be data.

Country-scoped venue queries must carry a `limit`. The seeded collection is
global, and an unbounded `where countryCode == …` pulls all of it.

### Organizer activity

The admin panel's pattern of batching a mutation together with a `logs` entry
does not transfer to organizers as-is. `logs` stays admin-create *and*
admin-read, and it has to stay that way: it is the collection admins use to
reconstruct their own decisions, and an organizer who could write into it could
forge entries in that record. Nothing is added to `logs` here.

The pattern does transfer to a venue-scoped collection instead:

```
venues/{venueId}/activity/{entryId} {
  actorUid, actorName: string
  what: string
  targetType, targetId: string
  at: Timestamp                      // == request.time, enforced
}
```

which organizers can write, so each mutation an editor makes commits its
activity entry in the same batch as the mutation itself. This is
accountability among teammates — "who changed my venue, and when" — not a
tamper-proof ledger; an editor with write access to the venue also has write
access to their own activity trail. It also grows unbounded, the same way
`logs` would without pruning, so it needs its own retention: pruning
`venues/*/activity` older than 180 days is a named follow-up, not something the
existing Retention pipeline (below) already does — that pipeline deletes Cloud
Storage objects, not Firestore documents, and pointing at it as if it already
covered this would overstate what's built.

### venues/{venueId}/menuSections/{sectionId}

```
venues/{venueId}/menuSections/{sectionId} {
  name: string
  order: number
  items: [{ id, name, price, desc, size, serves: string|number, tags: string[],
            nights: string[], soldOut: bool, image: string }]           // <= 100
  updatedAt: Timestamp
}
```

This is the subcollection the `live`-as-a-map paragraph above promises: the
menu is read only by the venue-detail view a user has already opened, so a
subcollection there costs 1+N on a screen that was going to make a request
anyway, and it keeps a payload that can run to hundreds of items off the
50-document Live Hub list entirely. Editing one section rewrites one document
instead of the whole menu.

### venues/{venueId}/metrics/{periodId}

```
venues/{venueId}/metrics/{periodId} {
  attendance: {...}
  funnel: {...}                      // stage counts only
  topNights: [{...}]
  updatedAt: Timestamp
}
```

This is the subcollection the `stats` reversal above promises. `periodId` is
deterministic — `last30` or `YYYY-Www` — rather than an auto-id, so the
dashboard reads one document by a known path: zero queries, zero indexes.
Only absolute counts are stored. The UI's `FunnelStage.width` (`"64%"`) and
`value` (`"14,300"`) are presentation the panel derives from the counts at
render time, and `TopNight.date` (`"Aug 8"`) becomes `at: Timestamp` here — a
percentage string or a formatted date string is a rendering decision, and
storing one would mean storing an answer that goes stale the moment the
denominator changes. If no producer has ever written a period's document, the
period is simply absent and the panel shows an empty state for it, the same
structural-absence pattern `venues.live` uses.

### venues/{venueId}/aiVisibility/current

```
venues/{venueId}/aiVisibility/current {
  score: number                      // 0..100
  prompts: [{ prompt: string, weeklyAsks: number, rank: number | null }]
  tips: string[]
  updatedAt: Timestamp
}
```

`rank: null` means the venue is not shown for that prompt at all; the panel
derives the `"#1"` / `"Not shown"` text and the colour band from `rank`, not
the other way around. Absent when no producer has run, same as `metrics`.

### venues/{venueId}/promotions/{promoId}, pushCampaigns, promoState, boosts, rankPerks

```
venues/{venueId}/promotions/{promoId}     { ..., used: number }
venues/{venueId}/pushCampaigns/{campaignId} { ..., status: 'queued' | ... }
venues/{venueId}/promoState/current       { ... }             // display state only
venues/{venueId}/boosts/{boostId}         { ..., status: 'pending' | ... }
venues/{venueId}/rankPerks/current        { ... }
```

The push rate limit is not rules-enforceable, and this is stated plainly rather
than implied: rules cannot count documents, and nothing in rules can *mandate*
that a `pushCampaigns` create be accompanied by a matching `promoState`
increment. So a campaign create is shape-validated only (`status: 'queued'`),
and the FCM fanout function enforces the real limit before anything sends.
`promoState/current` is display state the organizer cannot write at all — it
reflects what the function has already done. A limit that merely looks
enforced by rules, and isn't, would be worse than this honest note.
`promotions` allow create with `used == 0` and pin `used` on every later
update; `boosts` follow the same allow-create-with-initial-state shape.
`menuSections` and `rankPerks` are public read, since guests see both; the rest
of this group is editor-read with `write: if false` — producer- or
function-owned, not organizer-owned.

### venues/{venueId}/team/{memberId}

```
venues/{venueId}/team/{memberId} {
  uid: string | null                 // null until the invite is accepted
  name, email, role: string
  invitedBy: string
  invitedAt, acceptedAt: Timestamp | null
}
```

Client-write is denied outright; `/api/organizer/team` owns every mutation
here (see Privilege model, above) because a single team change has to fan out
atomically across this document, `venues.editors`/`.editorUids`, and
`venueInvites`, and accepting an invite is chicken-and-egg — the invitee is not
yet an editor and so cannot write `editorUids` to become one. Until that
function exists, the dashboard reads a seeded roster.

## venueEdits/{venueId}

```
venueEdits/{venueId} {                // document id IS the venue id
  venueId: string
  status: 'pending' | 'approved' | 'rejected'
  listing: { name: string, address: string }   // only the two reviewed fields
  submittedBy: string
  submittedAt: Timestamp              // == request.time, enforced
  reviewedBy: string | null
  reviewedAt: Timestamp | null
  note: string
}
```

This is the reviewable draft for `venues.name`/`venues.address` — the only two
fields denied on the venue document itself, so a rename or re-address can only
land by going through here. Everything else an organizer edits (`about`,
`socialLinks`, `genres`, `hours`, `photos`, and the rest) is a direct write to
the venue document; it was never part of this collection's `listing`. The
document id being the venue id, rather than an auto-id, is the whole design:
saving a draft is one idempotent `setDoc`, discarding it is one `deleteDoc`,
the admin review queue is a plain single-collection query
(`status == 'pending'`), and the join back to the venue is free because the id
already is the join key.

Two alternatives were rejected on read cost and race behaviour respectively.
A `pendingListing` map on the venue document was rejected because
`live_hub_service.dart:28` runs `venues where countryCode == X limit 50` and
Firestore transfers whole documents on a query — a 2-4 KB draft on every one of
fifty venues is 100-200 KB of unreviewed draft riding along on every Live Hub
load, on mobile data, for venues nobody is even looking at. A
`venues/{id}/edits/{editId}` subcollection was rejected because the admin
queue would then need a collection-group index plus parsing the venue id back
out of the path, and auto-ids would let one venue have two concurrent drafts
in flight, which makes "discard" and "which draft actually got approved"
ambiguous. Resubmitting instead replaces the one draft in place and can never
carry a verdict — an organizer never writes `status`, `reviewedBy`, or
`reviewedAt`; approval is admin-only and copies `listing` onto the venue
document.

## venueInvites/{inviteId}

```
venueInvites/{inviteId} {
  venueId, venueName: string
  email: string
  role: 'manager' | 'door'
  invitedBy: string
  invitedAt, expiresAt: Timestamp
  acceptedAt: Timestamp | null
  acceptedByUid: string | null
}
```

Function-owned, same as `team`: client writes are denied, and
`/api/organizer/team` is what creates and resolves invites as part of the
atomic fan-out described above. The one thing a client may read directly is an
invite addressed to it — `resource.data.email == request.auth.token.email` —
so an invitee can see their own pending invite without needing editor access
to the venue they haven't joined yet.

## venueReports/{reportId}

```
venueReports/{reportId} {
  venueId: string
  venueName: string                  // denormalised for list rendering
  uid: string                        // author, == request.auth.uid
  username, avatarUrl: string
  city, countryCode: string
  tag: string
  vibeRating: number                 // 1..5
  comment: string                    // "", or up to 500 chars
  upvoteCount: number
  createdAt: Timestamp               // == request.time, enforced

  reply: { text: string, byUid: string, byName: string, at: Timestamp } | null
  flaggedByOwner: bool
}

venueReports/{reportId}/upvotes/{voterUid} { at: Timestamp }
```

`venueName` is denormalised for the same reason `events.venueName` is: the Live
Hub renders fifty reports at a time and joining each one back to its venue would
be fifty extra reads for one string.

`comment` is always present, defaulting to `""` — omitting the field is what
made every commentless report fail the old rule. `vibeRating` is validated as a
number in 1..5 rather than `is int`, because a slider yields `4.0`.

An upvote is the same two-write batch as event interest, with the same ordering
requirement. Upvotes are permanent by design: there is no un-upvote, and racing
batches can over-count by one.

`reply` is public: guests see it posted under the report, not tucked behind an
admin view. Only a venue's `owner` or `manager` role may write one, and only for
the venue the report is about — `door` cannot, the same split as listing edits.
This is the one place in the schema where the `editorUids` denormalisation does
*not* save a `get()`, because the document being guarded is the report, not the
venue: checking "is this uid an owner/manager of `report.venueId`" still needs a
read of that venue document. Everywhere else in this schema the arrays exist
precisely to avoid that read on a hot path; here the trade runs the other way on
purpose, because replies are rare enough that one document access per reply
costs nothing worth optimising away. The write is pinned to
`onlyTouched(['reply', 'flaggedByOwner'])` — that constraint, not politeness, is
what stops an owner rewriting the guest's `comment` or `vibeRating` under cover
of "replying" to it. `reply == null` stays a legal write so "delete the posted
reply" is just clearing the field, not a special path.

`flaggedByOwner` is a request for admin attention, not a removal, and that
distinction is the whole point of the field: a flagged report stays publicly
readable exactly as before, and only an admin can delete it. The obvious
misreading is "flag hides the report" — it does not hide anything; it queues it
for a human.

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
        | 'kyc.script'                // a walkthrough script published or revised
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

venuePhotos/{venueId}/hero.jpg | gallery/{0..3}.jpg | menu/{itemId}.jpg
eventMedia/{eventId}/cover.jpg | poster.jpg
venueKyc/{venueId}/{license|gps|video}/{attempt}/…
```

`venuePhotos` and `eventMedia` are replaceable content: a hero image or an
event poster gets swapped, not preserved as evidence, so both allow ordinary
`write` (not create-only) and `delete` for editors, are publicly readable, and
sit behind their own sibling `match` blocks rather than one shared wildcard so
each prefix stays a known, bounded object set. `venueKyc` is the opposite case
— immutable evidence, copying the `kyc/` semantics on this page exactly, the
`resource == null` clause included, keyed on `venues.verification.<id>.attempt`
(pinned against organizer writes) so the retry cap is structural for venue
verification the same way it is for applicant KYC. The `resource == null`
reasoning below applies to `venueKyc` and does not apply to `venuePhotos` or
`eventMedia` — copying it onto them would make re-uploading a hero image
permanently denied, which is the opposite of what replaceable content needs.

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

The walkthrough video is capped at 5 minutes, 720p, H.264/AAC MP4, 250 MB —
enforced by the recorder preset, a client pre-check, and the Storage rule. The
app extracts the poster frame at capture. There is no thumbnail Cloud Function:
standing up a function runtime, its deploy pipeline, and its IAM surface to
produce one JPEG per applicant is disproportionate, and the poster is navigation
chrome, never evidence — the admin reviews the video itself in a streaming
player. Uploads are resumable; 250 MB over venue Wi-Fi is a multi-minute upload
that will get backgrounded.

Avatars sit in a separate top-level prefix because they are world-readable and
KYC never is. `users.avatarUrl` holds the public download URL; base64 image
blobs are no longer stored in Firestore documents.

### Retention

Identity images are deleted 30 days after approval and 90 days after final
rejection; the walkthrough video is retained while the organizer is active and
deleted 90 days after rejection; gps observations are structured, tiny, and
retained indefinitely.

Deletion runs in a **Netlify Function** using the Admin SDK — the Storage rules
deny `delete` to every client, so an inline client delete is impossible.

Not a Next route handler: the panel sets `output: "export"` in
`next.config.mjs` and is published to Netlify as a static site, so it has no
Next server to host one. Netlify Functions are the runtime this project already
deploys, which is what keeps the "no Cloud Functions" position honest rather than
merely stated — the alternative was standing up a Firebase Functions runtime, its
deploy pipeline, and its IAM surface for what is now six operations.

| Function | Path | Purpose |
|---|---|---|
| `admin-kyc.mts` | `POST /api/admin/kyc` | delete evidence on a decision |
| `admin-retention.mts` | `GET`/`POST /api/admin/retention` | dry run, or sweep on demand |
| `admin-scheduled-retention.mts` | `@daily`, not HTTP-reachable | the unattended sweep |
| `admin-account.mts` | `DELETE /api/admin/account` | erase an account |

The schedule is not optional decoration. An inline delete on the approve action
cannot fire thirty days later, and the bucket lifecycle rule only catches objects
at 180 days, so without a daily run the 30-day window is a paragraph rather than
a policy. Its audit entries are attributed to `system`, because no admin
performed them.

A bucket lifecycle rule of `age > 180 days` on `kyc/**` backstops anything the
sweep misses. Object Versioning stays off for this prefix: it would resurrect
deleted identity documents. `venueKyc/**` joins this sweep, `admin-retention.mts`
and `admin-scheduled-retention.mts`, and the same 180-day bucket lifecycle rule
— it is identity evidence, keyed the same way applicant KYC is. `venuePhotos`
and `eventMedia` do not join it: they are content, not identity documents, and
retention has no reason to touch them.

Firestore metadata (paths, sizes, reviewer, timestamps, notes) is retained
permanently, which preserves a provable audit trail at no breach cost. A NIC-
plus-selfie pair is exactly the bundle used for identity fraud elsewhere, and
the London cohort puts this under UK GDPR, so scheduled deletion is a
requirement rather than hygiene.

## Client prerequisites

- `firebase_storage` is absent from `Nightride/pubspec.yaml`.
- The `camera` package is absent. The selfie liveness prompt and the 60-second
  recorder need it rather than `image_picker`, and camera/microphone usage
  strings are not declared in `Info.plist` or `AndroidManifest.xml`.
- Storage CORS is already configured (`cors.json`) and `storageBucket` is
  already in the web Firebase config.
- `nightride-webpanel/lib/firebase.ts` already exports storage — as
  `getBucket()`, used by `lib/organizer/application-service.ts` and
  `lib/admin/kyc-evidence.ts` — not as a bare `getStorage`.
- `venues` is not seeder-less. `scripts/seed-emulator/seed.mjs` writes venues
  (around line 1454) in the current, post-migration shape. What is stale is
  the *other* seeder: `scripts/seed_venues.py` writes pre-migration snake_case
  documents (`lat`/`lng`/`country_code`/`opening_hours`, no `geo`, `geohash`,
  or `live`) directly into `venues` — the most-read collection in the system —
  and is being retired rather than kept in sync with this schema.
