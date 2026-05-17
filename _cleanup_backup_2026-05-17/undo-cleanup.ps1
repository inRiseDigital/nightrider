# undo-cleanup.ps1 — Restores all files deleted by the 2026-05-17 cleanup
$root   = Split-Path -Parent $PSScriptRoot
$backup = $PSScriptRoot

Write-Host "Restoring Nightride/Agent/ ..."
Copy-Item -Path "$backup\Nightride_Agent\*" -Destination "$root\Nightride\Agent" -Recurse -Force

Write-Host "Restoring nightrider-agent/ ..."
Copy-Item -Path "$backup\nightrider-agent" -Destination "$root\nightrider-agent" -Recurse -Force

Write-Host "Restoring PartyAgent/frontend/ ..."
Copy-Item -Path "$backup\PartyAgent_frontend" -Destination "$root\PartyAgent\frontend" -Recurse -Force

Write-Host "Restoring db.mwb.bak ..."
Copy-Item -Path "$backup\db.mwb.bak" -Destination "$root\db.mwb.bak" -Force

Write-Host "Restoring generate_timeline_pdf.py ..."
Copy-Item -Path "$backup\generate_timeline_pdf.py" -Destination "$root\generate_timeline_pdf.py" -Force

Write-Host "All files restored."
