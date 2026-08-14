# Nightride

Flutter (Dart 3.7+) mobile app for **Night Ride** — an AI nightlife companion for Dubai, Tokyo, London, and Melbourne. iOS/Android/web client. See the repo root `CLAUDE.md` for how this fits together with the PartyAgent backend and the webpanel.

## Stack

- State management: Riverpod (`flutter_riverpod` 3.x), with some codegen via `riverpod_generator`
- Navigation: a bottom-nav `IndexedStack` in `lib/pages/app_shell_page.dart` (Map / Home / Chat / Favourites / Profile) — index-based, not `go_router`, despite that dependency being present
- Responsive sizing via `flutter_screenutil`; theme lives in `lib/core/theme/`
- 12 locales under `lib/l10n/` — edit the `.arb` files, never the generated `app_localizations*.dart`
- Secrets/keys (Google Maps, Yelp, etc.) are compile-time constants read via `String.fromEnvironment` (`lib/core/config/maps_config.dart`), passed in with `--dart-define`. `.env` is not declared as a Flutter asset, so `flutter_dotenv` reads at runtime silently no-op and fall back to the dart-define value.

## Chat backend

The Chat tab streams from the PartyAgent backend over Server-Sent Events (`POST {BACKEND_URL}/chat/stream`, see `lib/data/services/chat_service.dart`). `BACKEND_URL` defaults to a devtunnel URL — override with `--dart-define=BACKEND_URL=...` for local or real builds.

## Organizer flow

A parallel organizer flow lives in `lib/pages/organizer/` (login, apply, home, shell) plus `lib/services/organizer_service.dart`, mirroring the apply/login flow in `nightride-webpanel/app/organizer/` and backed by the same Firestore `organizerApplication`/`organizerReview` data on the user's doc — see the repo root `docs/FIRESTORE_SCHEMA.md` for the schema.

## Local development against Firebase emulators

`scripts/emulators.sh` starts the Firebase emulator suite (Auth/Firestore/Storage) against the `nightride-a9173` project, persisting data to `emulator-data/` (gitignored) across restarts. See the repo root `LOCAL_DEV.md` for the full walkthrough — emulator setup, running PartyAgent locally against it, and seeding test data via `scripts/seed-emulator/`.

## Commands

```bash
flutter pub get
flutter gen-l10n                                            # regenerate localizations after editing .arb
dart run build_runner build --delete-conflicting-outputs   # regenerate Riverpod codegen
flutter run --dart-define=BACKEND_URL=... --dart-define=GOOGLE_MAPS_API_KEY=...
flutter analyze                                             # lint
flutter test                                                # all tests
dart run flutter_launcher_icons                             # regenerate app icons from assets/images/logo.png
```

## iOS release

Built by Codemagic (`codemagic.yaml`, workflow `ios-testflight`) on push to `main`; bumps the build number by +100 and publishes to TestFlight.
