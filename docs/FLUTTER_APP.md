# `Nightride/` — Flutter app

The consumer app, plus lightweight organizer and admin surfaces in the same binary.
Riverpod for state, ScreenUtil for sizing, `flutter_localizations` + ARB for i18n
(12 locales), Firebase Auth/Firestore/Storage for data.

Entry: `lib/main.dart` — one `MaterialApp` (light/dark themes with a user-selectable
accent, locale from settings) whose `home` is `SplashScreen`. There is no router: pages
are pushed imperatively, and the signed-in shell is `pages/app_shell_page.dart`
(IndexedStack over home / map / chat / favourites / profile with
`components/app_bottom_nav_bar.dart`).

## User surface (`lib/pages/`)

| Area | Pages |
|---|---|
| Entry / auth | `splash_page`, `auth/sign_in_page`, `auth/sign_up_page`, `forgotPw/`, `onboard_questionnaire_page` |
| Shell | `app_shell_page` |
| Discovery | `home_page`, `explore_page`, `category_detail_page`, `events_grid_page`, `event_detail_page`, `clubs_page`, `venue_details_page`, `place_details_page` |
| Search | `search_page`, `venue_search_detail_page` |
| Map | `map_page` |
| Social / live | `live_hub_page` |
| Gamification | `badges_collection_page`, `badge_claim_page` |
| Chat | `chat_screen` (PartyAgent client, gated by `components/chat/chat_verification_gate.dart`) |
| Account | `profile_page`, `edit_profile_page`, `favourites_page`, `notifications_page`, `settings_page` |

## Organizer surface (`lib/pages/organizer/`)

`organizer_login_page`, `organizer_apply_flow_page`, `organizer_verify_page` +
`verify/organizer_capture_screen` (document/selfie capture for KYC), then
`organizer_shell_page` over `organizer_home_page`, `organizer_tonight_page`,
`organizer_venue_page`, `organizer_account_page`. Backed by
`services/organizer_service.dart` and `services/organizer_verification_service.dart`.

The webpanel organizer dashboard is the fuller surface; the app version is the
on-the-go subset. See `ROLES.md`.

## Admin surface (`lib/pages/admin/`)

`admin_panel_page`, `admin_add_event_page`, backed by
`services/admin_actions_service.dart`. Minimal by design — real moderation lives in the
webpanel admin console.

## Support layers

- `services/` — `auth_service`, `firestore_service`, `user_profile_service`,
  `favourites_service`, `notification_service`, `organizer_service`,
  `organizer_verification_service`, `admin_actions_service`.
- `data/services/` — outward-facing integrations: `chat_service` +
  `chat_history_service` (PartyAgent), `maps_service`, `places_service`,
  `open_map_service`, `overpass_service`, `yelp_service`, `live_hub_service`,
  `privacy_service`.
- `data/models/` — `chat_message`, `chat_session`.
- `domain/` — `event`, `home_models`, `search_models`, `profile_models`,
  `live_hub_models`, `rank_system`.
- `providers/` — `app_nav_provider`, `home_providers`, `common_search_providers`,
  `nearby_venues_provider`, `live_hub_providers`, `profile_providers`,
  `settings_providers`.
- `components/` — shared widgets, grouped loosely by screen (`home_*`, `profile_*`,
  `search_*`, `venue_*`, `map_*`, plus `auth/`, `chat/`, `layout/`).
- `core/` — `theme/`, `responsive/`, `config/maps_config.dart`.
- `l10n/` — ARB + generated localizations for ar, de, en, es, fr, it, ja, ko, nl, pt,
  sv, zh.

**Status caveat:** `lib/data/*_dummy_data.dart` (`home`, `search`, `map`, `live_hub`,
`profile`) still backs parts of the UI. Before changing a screen, check whether it
reads Firestore or a dummy list.

## Gotchas

- Fresh `git worktree add` checkouts miss gitignored files Flutter needs
  (`Debug.xcconfig`/`Release.xcconfig`, `GoogleService-Info.plist`, `.env`, `Pods`).
  Copy from an existing worktree, then `pod install`.
- `ScreenUtil` design width is clamped in `main.dart` so `.w` does not over-inflate on
  tablets/foldables — don't hardcode a design size.

See also: `PARTYAGENT.md`, `FIRESTORE_SCHEMA.md`, `../LOCAL_DEV.md`.
