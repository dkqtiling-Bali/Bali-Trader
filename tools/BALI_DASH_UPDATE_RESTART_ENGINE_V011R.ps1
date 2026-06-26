param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 9061,
  [int]$ManualMode = 0
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report = Join-Path $logs 'BALI_DASH_UPDATE_FINAL_REPORT_V011R.txt'
function Add([string]$s='') { Add-Content -LiteralPath $report -Value $s -Encoding ASCII }
function OpenReport(){ try { Start-Process notepad $report | Out-Null } catch {} }
Set-Content -LiteralPath $report -Value @(
  'BALI DASH UPDATE FINAL REPORT V011R',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  'Purpose: close previous dashboard listener, apply patch, fast health, cleanup/status, auto restart, then one final report.',
  'Mode: quiet success flow. Intermediate reports stay in logs; errors open immediately.',
  'Close guard: LISTENING server on port 9061 must clear before restart; browser ESTABLISHED rows are ignored.',
  'Mission: STARGATE RIVAL MODE - faster controlled upgrades from inside the dash.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII
Add '=== Step 0: close previous dashboard listener ==='
$closeEngine = Join-Path $rootPath 'tools\BALI_CLOSE_DASHBOARD_PORT_V011R.ps1'
$closeReport = Join-Path $logs 'BALI_CLOSE_DASHBOARD_PORT_REPORT_V011R.txt'
$closeCode = 0
if(Test-Path -LiteralPath $closeEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $closeEngine -Root $rootPath -Report $closeReport -Port $Port -Force 1 | Out-Null
  $closeCode = $LASTEXITCODE
  Add ('Close dashboard exit code: ' + $closeCode)
  if(Test-Path -LiteralPath $closeReport) {
    Get-Content -LiteralPath $closeReport | Where-Object { $_ -match '^(LISTENER_STATUS|NON_LISTENER|PORT_STATUS|STOP_PROCESS_SENT|TASKKILL_SENT|LISTENER_STATUS_AFTER_CLOSE|Closed count|Warning count|RESULT:)' } | Select-Object -First 28 | ForEach-Object { Add $_ }
  }
  if($closeCode -ge 2) {
    Add 'RESULT: DASH UPDATE FAIL - PREVIOUS DASHBOARD LISTENER STILL ACTIVE'
    OpenReport
    exit $closeCode
  }
} else {
  Add 'WARNING: close dashboard engine missing; waiting for normal shutdown only.'
  Start-Sleep -Seconds 4
}
Add ''

Add '=== Step 1: speed lane apply/check ==='
$speedEngine = Join-Path $rootPath 'tools\BALI_SPEED_LANE_ENGINE_V011R.ps1'
if(-not (Test-Path -LiteralPath $speedEngine -PathType Leaf)) {
  $fallback = Join-Path $rootPath 'tools\BALI_SPEED_LANE_ENGINE_V011Q.ps1'
  if(Test-Path -LiteralPath $fallback -PathType Leaf) { $speedEngine = $fallback }
}
if(-not (Test-Path -LiteralPath $speedEngine -PathType Leaf)) {
  Add 'RESULT: DASH UPDATE FAIL - SPEED LANE ENGINE MISSING'
  OpenReport
  exit 8
}
$speedReport = Join-Path $logs 'BALI_DASH_INTERNAL_SPEED_LANE_REPORT_V011R.txt'
$stamp = 'dash_' + (Get-Date -Format yyyyMMdd_HHmmss)
& powershell -NoProfile -ExecutionPolicy Bypass -File $speedEngine -Root $rootPath -Report $speedReport -Stamp $stamp -Quiet 1 | Out-Null
$code = $LASTEXITCODE
Add ('Speed lane engine: ' + $speedEngine)
Add ('Speed lane exit code: ' + $code)
if(Test-Path -LiteralPath $speedReport) {
  Get-Content -LiteralPath $speedReport | Where-Object { $_ -match '^(Selected version|Selected patch zip|Installed version|Highest available patch|LISTENER_STATUS|RESULT:|Patch zip|Compact status pack|Desktop shortcut|Archived old patch|Kept current)' } | Select-Object -First 40 | ForEach-Object { Add $_ }
}
if($code -ne 0 -and $code -ne 1) {
  Add 'RESULT: DASH UPDATE FAIL - SPEED LANE FAILED'
  OpenReport
  exit $code
}
Add ''

Add '=== Step 2: restart dashboard ==='
$starter = Join-Path $rootPath 'BALI_THEMED_FOREVER_STARTER.bat'
if(-not (Test-Path -LiteralPath $starter -PathType Leaf)) { $starter = Join-Path $rootPath 'ROCKET_CRYPTO_COMMAND_START.bat' }
if(Test-Path -LiteralPath $starter -PathType Leaf) {
  Add ('Starting dashboard via: ' + $starter)
  try {
    Start-Process -FilePath $starter -WorkingDirectory $rootPath -WindowStyle Normal | Out-Null
    Add 'RESTART=LAUNCHED'
  } catch {
    Add ('RESTART=FAILED :: ' + $_.Exception.Message)
    Add 'RESULT: DASH UPDATE WARNING - PATCH APPLIED BUT RESTART FAILED'
    OpenReport
    exit 7
  }
} else {
  Add 'RESTART=FAILED :: no starter BAT found'
  Add 'RESULT: DASH UPDATE WARNING - PATCH APPLIED BUT STARTER MISSING'
  OpenReport
  exit 7
}
Add ''
Add 'RESULT: DASH UPDATE FINAL PASS'
Add 'Final report only: intermediate update/health/icon/cleanup reports were kept in logs unless an error happened.'
Add 'Next normal flow: drop next ZIP into updates, open dashboard Updates tab, click Dashboard Update + Auto Restart.'
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_DASH_UPDATE_RESTART_REPORT.txt') -Force } catch {}
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_FINAL_REPORT.txt') -Force } catch {}
OpenReport
exit 0
