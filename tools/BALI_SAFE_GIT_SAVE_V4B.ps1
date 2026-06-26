param(
  [string]$Base = "C:\Bali\Bali-Trader"
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $Base

Write-Host "=========================================="
Write-Host "        BALI SAFE GIT SAVE V4B"
Write-Host "=========================================="
Write-Host "SAFE_TOOLING_ONLY"
Write-Host "No app.py edit. No trading logic change. No live trading. No keys."
Write-Host ""

$scanScript = Join-Path $Base "tools\BALI_OS_SAFETY_SCAN_V4B.ps1"
if (-not (Test-Path -LiteralPath $scanScript)) { throw "Missing V4B safety scan script: $scanScript" }
$scan = & $scanScript -Base $Base -WriteReport

if ($scan.Status -eq "BLOCK") {
  Write-Host "BLOCKED: Safety scan found likely secret/token patterns. Review SAFETY_REPORTS first." -ForegroundColor Red
  exit 2
}

if ($scan.Status -eq "REVIEW") {
  Write-Host "REVIEW: Safety scan found risk phrases outside obvious safety-policy context." -ForegroundColor Yellow
  Write-Host "This save will continue only for safe docs/tooling files and will not stage app.py or strategy logic."
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw "Git not found in PATH." }

$statusBefore = git status --short
if (-not $statusBefore) {
  Write-Host "Git already clean. Nothing to save."
  exit 0
}

Write-Host "Current git changes:"
$statusBefore | ForEach-Object { Write-Host "  $_" }
Write-Host ""

$safePaths = @(
  "CONSTITUTION.md",
  "BALI_OS_WORKFLOW.md",
  "DEFINITION_OF_DONE.md",
  "EVIDENCE_STANDARDS.md",
  "PATCH_APPROVAL_RULES.md",
  "AI_ENGINEER_QUEUE.md",
  "LEDGER.md",
  "NEXT_PATCH.md",
  "PROJECT_MAP.md",
  "EVIDENCE_INDEX.md",
  "LATEST_CHAT_HANDOVER.txt",
  "BALI_MASTER_CONTROL.bat",
  "BALI_AI_HQ_V3.bat",
  "BALI_SAFE_GIT_SAVE.bat",
  "tools/BALI_OS_ENGINE.ps1",
  "tools/BALI_AI_HQ_V3_ANALYSE.ps1",
  "tools/BALI_SAFE_GIT_SAVE_V4B.ps1",
  "tools/BALI_OS_SAFETY_SCAN_V4B.ps1",
  "AI_HANDOVER_REPORTS",
  "INSTALL_REPORTS",
  "PROJECT_MAPS",
  "STATUS_DASHBOARDS",
  "NEXT_PATCH_REPORTS",
  "SAFETY_REPORTS",
  "EVIDENCE_INDEX",
  "BACKUPS"
)

foreach ($p in $safePaths) {
  if (Test-Path -LiteralPath (Join-Path $Base $p)) {
    git add -- $p | Out-Null
  }
}

$staged = git diff --cached --name-only
if (-not $staged) {
  Write-Host "No safe docs/tooling/report files were staged. Nothing committed."
  exit 0
}

$blockedStaged = @($staged | Where-Object {
  $_ -match "(^|/)app\.py$" -or
  $_ -match "(^|/)\.env" -or
  $_ -match "key" -or
  $_ -match "secret" -or
  $_ -match "credential" -or
  $_ -match "token" -or
  $_ -match "private" -or
  $_ -match "wallet" -or
  $_ -match "seed"
})
if ($blockedStaged.Count -gt 0) {
  git reset | Out-Null
  Write-Host "BLOCKED: One or more unsafe-looking files were staged. Staging reset." -ForegroundColor Red
  $blockedStaged | ForEach-Object { Write-Host "  $_" }
  exit 3
}

Write-Host "Staged safe files:"
$staged | ForEach-Object { Write-Host "  $_" }
Write-Host ""

$msg = "Bali OS safe tooling snapshot " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
git commit -m $msg

Write-Host ""
Write-Host "Commit complete. Pushing to GitHub..."
git push

Write-Host ""
Write-Host "PASS - Safe Git save complete."
Write-Host "Safety report: $($scan.Report)"
