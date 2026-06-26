param([string]$Base = 'C:\Bali\Bali-Trader')
$ErrorActionPreference = 'Continue'
Write-Host '=========================================='
Write-Host '        BALI SAFE GIT SAVE V7C'
Write-Host '=========================================='
Write-Host 'SAFE_TOOLING_ONLY'
Write-Host 'No app.py edit. No trading logic change. No live trading. No keys.'
Write-Host ''

& (Join-Path $Base 'tools\BALI_OS_SAFETY_SCAN_V7C.ps1') -Base $Base
if ($LASTEXITCODE -ne 0) { throw 'Safety scan blocked Git save.' }

Set-Location $Base
$status = git status --porcelain
if (-not $status) {
  Write-Host 'Git already clean. Nothing to commit.'
  exit 0
}
Write-Host 'Current git changes:'
git status --short

$safePaths = @(
  'LEDGER.md','NEXT_PATCH.md','CONSTITUTION.md','BALI_OS_WORKFLOW.md','DEFINITION_OF_DONE.md','EVIDENCE_STANDARDS.md','PATCH_APPROVAL_RULES.md','AI_ENGINEER_QUEUE.md','PROJECT_MAP.md','EVIDENCE_INDEX.md','LATEST_CHAT_HANDOVER.txt',
  'BALI_START_HERE.bat','BALI_MASTER_CONTROL.bat','BALI_CONTROL_DASHBOARD.bat','BALI_PHONE_DASHBOARD.bat','BALI_SAFE_GIT_SAVE.bat',
  'tools/BALI_LOCAL_URL_DASHBOARD_V7C.ps1','tools/BALI_DASHBOARD_SAFE_RUN_V7C.bat','tools/BALI_OS_ENGINE_V7C.ps1','tools/BALI_OS_SAFETY_SCAN_V7C.ps1','tools/BALI_SAFE_GIT_SAVE_V7C.ps1','tools/BALI_URL_SERVER_HEALTHCHECK_V7C.ps1',
  'docs','INSTALL_REPORTS','SAFETY_REPORTS','STATUS_DASHBOARDS','NEXT_PATCH_REPORTS','PROJECT_MAPS','EVIDENCE_INDEX','SESSION_REPORTS','RUN_REGISTRY','DASHBOARD_LOGS'
)
foreach ($p in $safePaths) { if (Test-Path (Join-Path $Base $p)) { git add -- $p } }

$staged = git diff --cached --name-only
if (-not $staged) {
  Write-Host 'No safe files staged. Leaving other changes untouched.'
  exit 0
}
Write-Host 'Staged safe files:'
$staged | ForEach-Object { Write-Host "  $_" }
$msg = "Bali OS V7C dashboard safe tooling snapshot $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $msg
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
Write-Host 'Commit complete. Pushing to GitHub...'
git push
if ($LASTEXITCODE -ne 0) { throw 'Git push failed.' }

$recDir = Join-Path $Base 'NEXT_PATCH_REPORTS'
New-Item -ItemType Directory -Force -Path $recDir | Out-Null
$rec = Join-Path $recDir ("BALI_POST_SAVE_RECOMMENDATION_V7C_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt")
@"
BALI POST-SAVE RECOMMENDATION V7C
Generated: $(Get-Date)

Recommended Next Patch:
V8 Stable Tool Cleanup + Archive Manager

Patch Class:
SAFE_TOOLING_ONLY

Why:
The dashboard is now the operating layer. The next maintenance step should reduce old V4/V5/V6 fix clutter, archive old reports, and keep only current stable tools visible before strategy-proof development expands.

MISSION FIT:
Improves maintainability, automation, reporting clarity, and safe strategy discovery workflow.

BLOCKED PATCHES:
- LIVE_TRADING
- API_KEYS
- CHAMPION_UNLOCK
- PROFITABILITY_CLAIM_WITHOUT_EVIDENCE
- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE
"@ | Set-Content -Path $rec -Encoding UTF8
Write-Host 'PASS - Safe Git save complete.'
Write-Host "Post-save recommendation: $rec"
