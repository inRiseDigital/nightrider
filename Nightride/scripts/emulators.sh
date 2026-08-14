#!/usr/bin/env bash
# Start the Firebase emulator suite against nightride-a9173 (matches the
# project id baked into firebase_options.dart, so Auth/Firestore/the
# Emulator UI all agree on one project instead of splitting across
# whatever --project happens to be passed — see singleProjectMode below).
# Fully local: useAuthEmulator/useFirestoreEmulator in main.dart redirect
# the app here, real nightride-a9173 backend is never touched.
# Persists Firestore/Auth/Storage data across restarts.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p emulator-data
npx firebase-tools emulators:start \
  --project nightride-a9173 \
  --import=./emulator-data \
  --export-on-exit=./emulator-data
