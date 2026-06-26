param(
  [string]$Base = "C:\Bali\Bali-Trader"
)

$ErrorActionPreference = "Stop"
$Base = (Resolve-Path -LiteralPath $Base).Path
Set-Location -LiteralPath $Base

Write-Host "=========================================="
Write-Host "        BALI SAFE GIT SAVE V5"
Write-Host "=========================================="
Write-Host "SAFE_TOOLING_ONLY"
Write-Host "No app.py edit. No trading logic change. No live trading. No keys."
Write-Host ""

$scanScript = "C:\Bali\Bali-Trader\tools\BALI_OS_SAFETY_SCAN_V5.ps1"
if (-not (Test-Path -LiteralPath $scanScript)) { throw "Missing V5 safety scan script: $scanScript" }
$scan = & $scanScript -Base $Base -WriteReport

if ($scan.Status -eq "BLOCK") {
  Write-Host "BLOCKED: Safety scan found a real blocker. Open the report below:" -ForegroundColor Red
  Write-Host $scan.Report
  exit 2
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw "Git not found in PATH." }

$statusBefore = @(git status --short)
if ($statusBefore.Count -eq 0) {
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
  "MISSION.md",
  "AI_RULES.md",
  "PROJECT_MAP.md",
  "EVIDENCE_INDEX.md",
  "LATEST_CHAT_HANDOVER.txt",
  "BALI_STATUS_LATEST.txt",
  "BALI_SESSION_LATEST.txt",
  "NEXT_PATCH_RECOMMENDATION_LATEST.txt",
  "BALI_MASTER_CONTROL.bat",
  "BALI_START_HERE.bat",
  "BALI_ONE_CLICK_SESSION.bat",
  "BALI_SAFE_GIT_SAVE.bat",
  "tools/BALI_OS_ENGINE.ps1",
  "tools/BALI_OS_ENGINE_V5.ps1",
  "tools/BALI_OS_SAFETY_SCAN_V5.ps1",
  "tools/BALI_SAFE_GIT_SAVE_V5.ps1",
  "AI_HANDOVER_REPORTS",
  "STATUS_DASHBOARDS",
  "NEXT_PATCH_REPORTS",
  "PROJECT_MAPS",
  "EVIDENCE_INDEX",
  "SAFETY_REPORTS",
  "SESSION_REPORTS",
  "RUN_REGISTRY",
  "APPROVAL_QUEUE",
  "PATCH_QUEUE",
  "TEST_REPORTS",
  "INSTALL_REPORTS"
)

$staged = New-Object System.Collections.Generic.List[string]
foreach ($p in $safePaths) {
  $full = Join-Path $Base $p
  if (Test-Path -LiteralPath $full) {
    git add -- $p
    $staged.Add($p)
  }
}

$stagedNow = @(git diff --cached --name-only)
if ($stagedNow.Count -eq 0) {
  Write-Host "No safe staged changes. Nothing committed."
  exit 0
}

Write-Host "Staged safe files:"
$stagedNow | ForEach-Object { Write-Host "  $_" }
Write-Host ""

$commitMsg = "Bali OS V5 automated experience snapshot " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

Write-Host "Commit complete. Pushing to GitHub..."
git push
if ($LASTEXITCODE -ne 0) { throw "git push failed" }

Write-Host ""
Write-Host "PASS - Safe Git save complete." -ForegroundColor Green
Write-Host "Safety report: $($scan.Report)"
