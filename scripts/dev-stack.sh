#!/usr/bin/env bash
# Start the whole local stack described in LOCAL_DEV.md, each service in its
# own Terminal.app window so its logs stay live and interactive:
#
#   1. Firebase emulator suite   Auth 9099 / Firestore 8080 / Storage 9199 / UI 4000
#   2. PartyAgent backend        :8000
#   3. nightride-webpanel        :3000
#   4. Nightride Flutter app     iOS Simulator (or --web for Chrome)
#
# Only the emulator window matters at shutdown: it needs a clean Ctrl+C so
# --export-on-exit can write Nightride/emulator-data/. `dev-stack.sh --stop`
# does that for you, in the right order.
#
# Usage:
#   scripts/dev-stack.sh                      # start everything
#   scripts/dev-stack.sh --seed               # ...and (re)seed the emulator first
#   scripts/dev-stack.sh --seed --wipe        # ...wiping seeded collections first
#   scripts/dev-stack.sh --no-app             # backend + webpanel + emulators only
#   scripts/dev-stack.sh --web                # run the Flutter app on Chrome
#   scripts/dev-stack.sh --device <id>        # explicit Flutter device id
#   scripts/dev-stack.sh --stop               # stop everything, emulator last/cleanly
#
# Internal: `dev-stack.sh __run <service>` is what each Terminal window executes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$ROOT/scripts/dev-stack.sh"

PROJECT_ID="nightride-a9173"
BACKEND_URL="http://localhost:8000"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[31m  x %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- port helpers

# `|| true`: with `set -o pipefail`, lsof exiting 1 on "nothing listening"
# would otherwise fail the whole pipeline and kill the script under `set -e`.
port_pid() { lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | head -1 || true; }

wait_for_url() {
  local url="$1" label="$2" timeout="${3:-120}" waited=0
  while ! curl -fsS -m 2 "$url" >/dev/null 2>&1; do
    sleep 2
    waited=$((waited + 2))
    [ "$waited" -ge "$timeout" ] && return 1
  done
  info "$label ready"
}

# ----------------------------------------------------- per-service run targets
# These run *inside* the spawned Terminal windows.

run_emulators() {
  cd "$ROOT/Nightride"
  echo "== Firebase emulator suite =="
  echo "Ctrl+C here (never kill -9) so --export-on-exit writes emulator-data/."
  echo
  exec ./scripts/emulators.sh
}

run_backend() {
  cd "$ROOT/PartyAgent"
  echo "== PartyAgent backend :8000 =="
  echo
  # Both vars must be real shell env vars: config.py's pydantic-settings only
  # loads declared fields from .env, and firebase_admin reads os.environ.
  export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
  export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
  if [ -x .venv/bin/python ]; then
    exec .venv/bin/python run_server.py
  else
    exec python run_server.py
  fi
}

run_webpanel() {
  cd "$ROOT/nightride-webpanel"
  echo "== nightride-webpanel :3000 =="
  echo
  exec npm run dev
}

run_app() {
  cd "$ROOT/Nightride"
  local device="${DEV_STACK_DEVICE:?device not set}"
  echo "== Nightride Flutter app on $device =="
  echo
  local maps_key=""
  if [ -f ios/Flutter/Debug.xcconfig ]; then
    maps_key="$(grep -E '^GOOGLE_MAPS_API_KEY' ios/Flutter/Debug.xcconfig | cut -d= -f2- | tr -d ' ' || true)"
  fi
  exec flutter run -d "$device" \
    --dart-define=USE_FIREBASE_EMULATOR=true \
    --dart-define=BACKEND_URL="$BACKEND_URL" \
    --dart-define=GOOGLE_MAPS_API_KEY="$maps_key"
}

if [ "${1:-}" = "__run" ]; then
  case "${2:-}" in
    emulators) run_emulators ;;
    backend)   run_backend ;;
    webpanel)  run_webpanel ;;
    app)       run_app ;;
    *)         die "unknown service: ${2:-}" ;;
  esac
fi

# ------------------------------------------------------------ Terminal windows

# Opens a new Terminal.app window running `dev-stack.sh __run <service>`.
# One window per service rather than tabs: tabs need System Events keystrokes
# and the Accessibility permission, windows need neither.
open_window() {
  local service="$1" title="$2" extra_env="${3:-}"
  osascript >/dev/null <<APPLESCRIPT
tell application "Terminal"
  activate
  set w to do script "clear; ${extra_env}exec '${SELF}' __run ${service}"
  set custom title of (selected tab of window 1) to "${title}"
end tell
APPLESCRIPT
  info "opened Terminal window: $title"
}

# ----------------------------------------------------------------------- --stop

stop_all() {
  bold "Stopping the local stack"
  pkill -f 'flutter_tools.snapshot run' 2>/dev/null && info "stopped flutter run" || true
  pkill -f 'run_server.py'             2>/dev/null && info "stopped PartyAgent" || true
  pkill -f 'next dev'                  2>/dev/null || true
  pkill -f 'next-server'               2>/dev/null && info "stopped webpanel" || true

  # The emulator CLI needs SIGTERM (not SIGKILL) and time to finish exporting.
  local pid
  pid="$(pgrep -f 'firebase emulators:start' | head -1 || true)"
  if [ -n "$pid" ]; then
    info "SIGTERM to emulator suite (pid $pid), waiting for data export..."
    kill -TERM "$pid"
    local waited=0
    while kill -0 "$pid" 2>/dev/null; do
      sleep 1
      waited=$((waited + 1))
      [ "$waited" -ge 60 ] && { warn "emulator still shutting down after 60s, leaving it alone"; break; }
    done
    if [ -d "$ROOT/Nightride/emulator-data/firestore_export" ]; then
      info "exported to Nightride/emulator-data/"
    else
      warn "no firestore_export in Nightride/emulator-data/ — data may not have been saved"
    fi
  fi

  # Orphaned Firestore emulator JVMs (parent CLI died without exporting) hold
  # port 8080 and block the next start; this is the exact failure LOCAL_DEV.md
  # does not cover.
  local orphan
  orphan="$(pgrep -f 'cloud-firestore-emulator' | head -1 || true)"
  if [ -n "$orphan" ]; then
    warn "orphan Firestore emulator still on pid $orphan (its in-memory data was never exported)"
    warn "kill it with: kill $orphan"
  fi
  bold "Done."
}

# --------------------------------------------------------------- device picker

pick_ios_device() {
  local booted
  booted="$(xcrun simctl list devices booted -j 2>/dev/null \
    | grep -oE '"udid" : "[^"]+"' | head -1 | cut -d'"' -f4 || true)"
  if [ -n "$booted" ]; then
    echo "$booted"
    return
  fi
  local candidate
  candidate="$(xcrun simctl list devices available -j 2>/dev/null \
    | grep -oE '"udid" : "[0-9A-F-]+"' | head -1 | cut -d'"' -f4 || true)"
  [ -z "$candidate" ] && return 1
  xcrun simctl boot "$candidate" >/dev/null 2>&1 || true
  open -a Simulator
  echo "$candidate"
}

# ------------------------------------------------------------------ start flow

DO_SEED=false
SEED_WIPE=false
RUN_APP=true
USE_WEB=false
DEVICE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --stop)   stop_all; exit 0 ;;
    --seed)   DO_SEED=true ;;
    --wipe)   SEED_WIPE=true ;;
    --no-app) RUN_APP=false ;;
    --web)    USE_WEB=true ;;
    --device) DEVICE="${2:?--device needs an id}"; shift ;;
    -h|--help) sed -n '2,30p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $1 (try --help)" ;;
  esac
  shift
done

bold "Preflight"
[ "$(uname)" = "Darwin" ] || die "this script drives Terminal.app, so it is macOS-only"
command -v java >/dev/null || die "no java — the Firestore/Storage emulators need a JVM (see LOCAL_DEV.md step 1)"
command -v flutter >/dev/null || { $RUN_APP && die "no flutter on PATH (use --no-app to skip the app)"; }
[ -f "$ROOT/Nightride/.env" ] || warn "Nightride/.env missing — it is a declared pubspec asset, so the iOS build will fail on asset bundling"
[ -f "$ROOT/Nightride/ios/Runner/GoogleService-Info.plist" ] || warn "Nightride/ios/Runner/GoogleService-Info.plist missing — iOS build will fail"
[ -f "$ROOT/Nightride/ios/Flutter/Debug.xcconfig" ] || warn "Nightride/ios/Flutter/Debug.xcconfig missing — no GOOGLE_MAPS_API_KEY will be passed"
[ -x "$ROOT/PartyAgent/.venv/bin/python" ] || warn "PartyAgent/.venv missing — falling back to whatever \`python\` resolves to"
[ -d "$ROOT/nightride-webpanel/node_modules" ] || warn "nightride-webpanel/node_modules missing — run npm install there first"
[ -f "$ROOT/nightride-webpanel/.env.local" ] || warn "nightride-webpanel/.env.local missing — the panel will hit REAL Firebase, not the emulator"
if [ -f "$ROOT/nightride-webpanel/.env.local" ] \
   && ! grep -q '^NEXT_PUBLIC_USE_FIREBASE_EMULATOR=true' "$ROOT/nightride-webpanel/.env.local"; then
  warn "NEXT_PUBLIC_USE_FIREBASE_EMULATOR is not true in .env.local — the panel will hit REAL Firebase"
fi

# Ports. Anything already listening is reported rather than killed: it might be
# a live emulator holding unexported data.
emulators_running=false
for p in 8080 9099 9199 4000; do
  pid="$(port_pid "$p")"
  if [ -n "$pid" ]; then
    emulators_running=true
    info "port $p already in use by pid $pid"
  fi
done
if $emulators_running; then
  if curl -fsS -m 2 "http://127.0.0.1:4000/api/config" >/dev/null 2>&1; then
    warn "an emulator suite is already running — reusing it, not starting a second one"
  else
    die "emulator ports are taken but the UI on :4000 is not responding (likely an orphan JVM). Run '$SELF --stop' and follow its instructions."
  fi
fi

backend_running=false
if [ -n "$(port_pid 8000)" ]; then
  backend_running=true
  warn "port 8000 in use — reusing the backend already there"
fi
webpanel_running=false
if [ -n "$(port_pid 3000)" ]; then
  webpanel_running=true
  warn "port 3000 in use — reusing the webpanel already there"
fi

bold "Starting services"

if ! $emulators_running; then
  open_window emulators "1 · emulators"
  wait_for_url "http://127.0.0.1:4000/api/config" "emulator suite" 180 \
    || die "emulator suite did not come up — check its Terminal window"
fi

if $DO_SEED; then
  bold "Seeding emulator data"
  [ -d "$ROOT/scripts/seed-emulator/node_modules" ] \
    || (cd "$ROOT/scripts/seed-emulator" && npm install --silent)
  seed_args=()
  if $SEED_WIPE; then seed_args+=(--wipe); fi
  ( cd "$ROOT/scripts/seed-emulator" \
    && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
       FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
       STORAGE_EMULATOR_HOST=http://127.0.0.1:9199 \
       node seed.mjs "${seed_args[@]}" )
fi

if ! $backend_running; then
  # Optional: Postgres + Redis for LangGraph memory. Without them the backend
  # logs "DB setup failed — running on InMemory only" and still serves fine.
  if docker info >/dev/null 2>&1; then
    if ( cd "$ROOT/PartyAgent" && docker-compose up -d >/dev/null 2>&1 ); then
      info "PartyAgent Postgres/Redis up (persistent memory)"
    else
      warn "docker-compose up failed — backend will run on InMemory memory"
    fi
  else
    info "docker not running — backend memory will be InMemory only (fine for local work)"
  fi
  open_window backend "2 · PartyAgent"
  wait_for_url "$BACKEND_URL/health" "backend" 120 || warn "backend /health not answering yet — check its window"
fi

if ! $webpanel_running; then
  open_window webpanel "3 · webpanel"
  wait_for_url "http://localhost:3000/" "webpanel" 120 || warn "webpanel not answering yet — check its window"
fi

if $RUN_APP; then
  if [ -z "$DEVICE" ]; then
    if $USE_WEB; then
      DEVICE="chrome"
    else
      DEVICE="$(pick_ios_device)" || die "no iOS simulator available — pass --device <id> or use --web"
    fi
  fi
  open_window app "4 · Nightride app" "export DEV_STACK_DEVICE='$DEVICE'; "
fi

cat <<SUMMARY

$(bold "Local stack up")
  Emulator UI   http://127.0.0.1:4000
  Firestore     127.0.0.1:8080     Auth 127.0.0.1:9099     Storage 127.0.0.1:9199
  PartyAgent    $BACKEND_URL/health
  Webpanel      http://localhost:3000        organizer apply: /organizer/apply
$( $RUN_APP && echo "  Flutter app   device $DEVICE (first iOS build takes a few minutes)" || true )

  Seeded logins (after --seed): admin|rider|applicant|organizer|rejected @nightride.test
  passwords: Admin|Rider|Applicant|Organizer|Rejected + Seed!123

  Stop everything, exporting emulator data cleanly:
    scripts/dev-stack.sh --stop
SUMMARY
