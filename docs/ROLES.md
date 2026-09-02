# Roles and where each one lives

Three roles — user, organizer, admin — spread across the Flutter app and the web
panel. Firebase Auth is the single identity; role comes from custom claims / the user
doc (see `FIRESTORE_SCHEMA.md`, `firestore.rules`).

| Role | Flutter app | Web panel |
|---|---|---|
| **User** | Full product: discovery, map, chat, badges, profile | — |
| **Organizer** | `lib/pages/organizer/` — apply, KYC capture, on-the-go shell (home / tonight / venue / account) | `app/organizer/` — apply flow + 12-section dashboard |
| **Admin** | `lib/pages/admin/` — panel + add event | `app/admin/` — Material 3 moderation console |

## Organizer journey end to end

1. **Apply** — from the app (`organizer_apply_flow_page`) or the panel
   (`app/organizer/apply/`, `lib/organizer/application-service.ts`). Venue lookup via
   Google Places.
2. **Verify** — KYC document/selfie capture in the app
   (`pages/organizer/verify/organizer_capture_screen`,
   `services/organizer_verification_service.dart`). Evidence goes to Storage.
3. **Review** — admin console `org-apps` section
   (`components/admin/m3/organizer-applications/`), list → applicant detail → venue
   detail → `DecisionBar` approve/reject. Evidence read through the `admin-kyc`
   Netlify function; retention/purge via `admin-retention` and
   `admin-scheduled-retention`.
4. **Operate** — approved organizer gets the panel dashboard (events, tonight,
   calendar, venues, team, inbox, reviews, performance, promotion, ai-visibility,
   settings) and the app organizer shell.

Details: `WEBPANEL.md`, `FLUTTER_APP.md`.

## Admin capabilities

Implemented: overview counts, organizer application review. Placeholders in the nav:
event review queue, venues directory, users & organizers, roles & access, audit log,
settings.

Claims are granted out-of-band by root `set_admin.py` or the `admin-account` Netlify
function.
