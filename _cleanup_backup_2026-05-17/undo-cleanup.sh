#!/usr/bin/env bash
# undo-cleanup.sh — Restores all files deleted by the 2026-05-17 cleanup
BACKUP="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$BACKUP")"

echo "Restoring Nightride/Agent/ ..."
cp -r "$BACKUP/Nightride_Agent/." "$ROOT/Nightride/Agent/"

echo "Restoring nightrider-agent/ ..."
cp -r "$BACKUP/nightrider-agent" "$ROOT/nightrider-agent"

echo "Restoring PartyAgent/frontend/ ..."
cp -r "$BACKUP/PartyAgent_frontend" "$ROOT/PartyAgent/frontend"

echo "Restoring db.mwb.bak ..."
cp "$BACKUP/db.mwb.bak" "$ROOT/db.mwb.bak"

echo "Restoring generate_timeline_pdf.py ..."
cp "$BACKUP/generate_timeline_pdf.py" "$ROOT/generate_timeline_pdf.py"

echo "All files restored."
