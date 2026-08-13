#!/usr/bin/env bash
# Start the Firebase emulator suite against the offline demo-nightride project,
# persisting Firestore/Auth/Storage data across restarts.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p emulator-data
npx firebase-tools emulators:start \
  --project demo-nightride \
  --import=./emulator-data \
  --export-on-exit=./emulator-data
