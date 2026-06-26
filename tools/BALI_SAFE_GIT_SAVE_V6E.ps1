param([string]$Base='C:\Bali\Bali-Trader')
$ErrorActionPreference = 'Stop'
Set-Location $Base
Write-Host '=========================================='
Write-Host '        BALI SAFE GIT SAVE V6E'
Write-Host '=========================================='
Write-Host 'SAFE_TOOLING_ONLY'
Write-Host 'No app.py edit. No trading logic change. No live trading. No keys.'
Write-Host ''

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base 'tools\BALI_OS_SAFETY_SCAN_V6E.ps1') -Base $Base
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED: Safety scan failed. Review latest SAFETY_REPORTS file.' }

$status = & git status --short
Write-Host 'Current git changes:'
if ($status) { $status | ForEach-Object { Write-Host "  $_" } } else { Write-Host '  CLEAN - nothing to save.'; exit 0 }

# Stage safe docs/tooling/report folders only. Deliberately avoid app.py/trading logic files.
$paths = @(
  'LEDGER.md','NEXT_PATCH.md','CONSTITUTION.md','BALI_OS_WORKFLOW.md','DEFINITION_OF_DONE.md','EVIDENCE_STANDARDS.md','PATCH_APPROVAL_RULES.md','AI_ENGINEER_QUEUE.md','PROJECT_MAP.md','EVIDENCE_INDEX.md',
  'LATEST_CHAT_HANDOVER.txt','LATEST_STATUS_DASHBOARD.txt','LATEST_RECOMMENDATION.txt',
  'BALI_START_HERE.bat','BALI_MASTER_CONTROL.bat','BALI_CONTROL_DASHBOARD.bat','BALI_URL_DASHBOARD.bat','BALI_SAFE_GIT_SAVE.bat',
  'docs','tools/BALI_OS_ENGINE_V6E.ps1','tools/BALI_OS_SAFETY_SCAN_V6E.ps1','tools/BALI_SAFE_GIT_SAVE_V6E.ps1','tools/BALI_LOCAL_URL_DASHBOARD_V6E.ps1','tools/BALI_DASHBOARD_SAFE_RUN_V6E.bat',
  'INSTALL_REPORTS','SAFETY_REPORTS','STATUS_DASHBOARDS','NEXT_PATCH_REPORTS','PROJECT_MAPS','EVIDENCE_INDEX','SESSION_REPORTS','RUN_REGISTRY','DASHBOARD_LOGS'
)
foreach ($p in $paths) { if (Test-Path (Join-Path $Base $p)) { & git add -- $p } }

$staged = & git diff --cached --name-only
if (-not $staged) { Write-Host 'Nothing safe staged. Leaving repo unchanged.'; exit 0 }
Write-Host 'Staged safe files:'
$staged | ForEach-Object { Write-Host "  $_" }

# Create a post-save recommendation file and stage it too.
$recDir = Join-Path $Base 'NEXT_PATCH_REPORTS'
New-Item -ItemType Directory -Force -Path $recDir | Out-Null
$recFile = Join-Path $recDir ("BALI_POST_SAVE_RECOMMENDATION_V6E_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
@(
  'BALI POST-SAVE RECOMMENDATION V6E',
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  '',
  'Recommended Next Patch:',
  'V7 Stable Tool Cleanup + Archive Manager',
  'Patch Class: SAFE_TOOLING_ONLY',
  '',
  'Why:',
  'Clean old V4/V5/V6 fix clutter and archive older reports so Bali OS stays simple before deeper evidence/strategy proof development.',
  '',
  'Safety preserved: LIVE_ORDERS_OFF, NO_API_KEYS, PUBLIC_DATA_ONLY, PAPER/SIM FIRST, CHAMPION_LOCKED.'
) | Set-Content -Encoding UTF8 $recFile
Copy-Item -Force $recFile (Join-Path $Base 'LATEST_RECOMMENDATION.txt')
& git add -- $recFile 'LATEST_RECOMMENDATION.txt'

$msg = "Bali OS V6E safe tooling snapshot $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
& git commit -m $msg
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
Write-Host 'Commit complete. Pushing to GitHub...'
& git push
if ($LASTEXITCODE -ne 0) { throw 'Git push failed.' }
Write-Host ''
Write-Host 'PASS - Safe Git save complete.'
Write-Host "Post-save recommendation: $recFile"
