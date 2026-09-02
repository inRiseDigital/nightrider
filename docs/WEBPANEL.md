# `nightride-webpanel/` — web panel

Next.js (App Router, JS/TS mix) hosting **two independent surfaces** that happen to
share a repo, a Firebase project, and nothing else: the organizer dashboard and the
internal admin console. Deployed on Netlify (`netlify.toml`); privileged operations run
in Netlify functions with the Firebase Admin SDK.

## Layout

| Path | Contents |
|---|---|
| `app/organizer/` | Organizer login, `apply/` onboarding flow, `(dashboard)` route group |
| `app/admin/` | Admin console (single page) + `login/` |
| `components/organizer/`, `components/admin/` | UI for each surface, no sharing between them |
| `lib/organizer/`, `lib/admin/` | Data access, hooks, validation per surface |
| `lib/firebase.ts`, `lib/firebase-admin.ts` | Client SDK vs Admin SDK init |
| `netlify/functions/` | Privileged admin endpoints |
| `firestore.rules`, `firestore.indexes.json`, `storage.rules` | Deployed security rules (tested from `firestore-tests/`) |

## Organizer surface

Routes under `app/organizer/`:

- `login/` — organizer sign-in.
- `apply/` — multi-step organizer application flow (`_components/`, `lib/organizer/application-service.ts`, `validation.ts`, Google Places lookup via `lib/organizer/google-maps.ts`).
- `(dashboard)/` route group, wrapped by `layout.tsx` + `components/organizer/dashboard/DashboardShell.tsx` (sidebar, topbar, `nav-items.ts`). Each `page.tsx` is a 5-line shim that renders one section component:

| Route | Section component |
|---|---|
| `dashboard` | `OverviewSection` |
| `tonight` | `TonightSection` |
| `events` | `EventsSection` (+ `EventEditor`) |
| `calendar` | `CalendarSection` |
| `venues` | `VenuesSection` (+ `VenueAppPreview`, `VenueVerifyPending`) |
| `team` | `TeamSection` |
| `inbox` | `InboxSection` |
| `reviews` | `ReviewsSection` |
| `performance` | `PerformanceSection` |
| `promotion` | `PromotionSection` |
| `ai-visibility` | `AiVisibilitySection` |
| `settings` | `SettingsSection` |

State lives in `lib/organizer/dashboard/store.tsx` (React context) with
`browser-stores.ts` for local persistence, `types.ts`, `format.ts`, `constants.ts`.

**Status caveat:** this describes the target state the schema in
`docs/FIRESTORE_SCHEMA.md` now supports, not what is wired today — this task
lands before the sections are rewired to read it, so `mock-data.ts` is still
what most of them render. Once wired, `Overview`, `Tonight`, `Events`,
`Calendar`, `Venues`, `Team`, `Inbox`, `Reviews`, and `Settings` read real
Firestore collections that already exist and are already written by some
producer — `events`, `venues` (including `live`, `editors`/`editorUids`, and
listing edits via `venueEdits`), `venueReports`, `users/{uid}/inbox`, and
`team`/`venueInvites` (client-write denied; the dashboard reads a seeded roster
until `/api/organizer/team` exists).

Four sections are different in kind, not just in sequencing: `Performance`,
`AiVisibility`, `Promotion`, and its boost sub-feature read real
collections — `venues/{id}/metrics`, `venues/{id}/aiVisibility`, the
promotion trio (`promotions`, `pushCampaigns`, `promoState`), and `boosts` —
whose *producers* do not exist yet. No job computes a funnel, scores AI
visibility, or fans out a push, so these collections are seeded from
`scripts/` for now rather than kept current by anything running in
production. A section reading its collection and finding data is not evidence
the number is live; check whether the producer named in
`docs/FIRESTORE_SCHEMA.md` for that collection has actually been built. The
`apply/` flow still writes to Firestore directly, as before.

## Admin surface

`app/admin/page.tsx` is a single-page Material 3 console — deliberately not real Next
routes. `lib/admin/useAdminNav.ts` holds the selected nav section and, inside organizer
applications, which of list/detail/venue is showing.

Nav sections (`lib/admin/m3-data.ts`):

| Group | Items |
|---|---|
| Overview | `overview` (Dashboard) |
| Content review | `org-apps` (Organizer applications, badged with pending count), `event-queue` |
| Directory | `venues`, `users` |
| System | `roles`, `audit`, `settings` |

**Only `overview` and `org-apps` are implemented.** Everything else renders
`components/admin/m3/Placeholder.tsx` (`isPlaceholder` in `useAdminNav`).

Components in `components/admin/m3/`: `AdminGate` (auth gate), `AdminLoginForm`,
`Sidebar`, `Topbar`, `Overview`, `Placeholder`, `SimulatedBadge`, and
`organizer-applications/` (`OrgAppsList`, `OrgDetailHeader`, `ExistingOrgDetail`,
`VenueDetail`, `VerificationFlow`, `DecisionBar`).

`lib/admin/`: `firestore.ts`, `schema.ts`, `auth.tsx`, `errors.ts`, `present.ts`,
`geo.ts`, hooks (`useOverviewData`, `useApplicantsList`, `useApplicantDetail`,
`useVenueDetail`), `kyc-evidence.ts`, `kyc-retention.ts`, `mock-overlay.ts`
(watch this one — it can dress mock records as real; `SimulatedBadge` marks them).

## Netlify functions

`netlify/functions/`, Admin SDK only — never import these from the browser bundle:

- `admin-account.mts` — privileged account operations (custom claims / role grants).
- `admin-kyc.mts` — access to organizer KYC evidence.
- `admin-retention.mts` — manual KYC-evidence retention/purge.
- `admin-scheduled-retention.mts` — scheduled version of the same.

Root `set_admin.py` grants the admin claim out-of-band.

See also: `ROLES.md`, `FIRESTORE_SCHEMA.md`, `../LOCAL_DEV.md`.
