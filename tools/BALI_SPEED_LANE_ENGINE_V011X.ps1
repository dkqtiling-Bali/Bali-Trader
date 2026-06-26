param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Report,
  [Parameter(Mandatory=$true)][string]$Stamp,
  [int]$Quiet = 0
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $Report -Value @(
  'BALI SPEED LANE UPDATE REPORT V011X',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  'Purpose: update + fast health + Bali themed icon + cleanup + auto status + dash bridge check + final-report-only support.',
  'Mission: STARGATE RIVAL MODE - faster controlled upgrades for the challenger machine.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  'Quiet mode: intermediate reports stay in logs; dashboard flow opens one final report.',
  ''
) -Encoding ASCII

Add '=== Step 0: close previous dashboard if needed ==='
$closeEngine = Join-Path $rootPath 'tools\BALI_CLOSE_DASHBOARD_PORT_V011X.ps1'
$closeReport = Join-Path $logs 'BALI_CLOSE_DASHBOARD_PORT_REPORT_V011X.txt'
if(Test-Path -LiteralPath $closeEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $closeEngine -Root $rootPath -Report $closeReport -Port 9061 -Force 1 | Out-Null
  $closeCode = $LASTEXITCODE
  Add ('Close dashboard exit code: ' + $closeCode)
  if(Test-Path -LiteralPath $closeReport) { Get-Content -LiteralPath $closeReport | Where-Object { $_ -match '^(LISTENER_STATUS|NON_LISTENER|PORT_STATUS|STOP_PROCESS_SENT|TASKKILL_SENT|LISTENER_STATUS_AFTER_CLOSE|Closed count|Warning count|RESULT:)' } | Select-Object -First 28 | ForEach-Object { Add $_ } }
} else { Add 'WARNING: close dashboard engine missing; continuing.' }
Add ''

Add '=== Step 1: one-click update engine ==='
$updateEngine = Join-Path $rootPath 'tools\BALI_ONE_CLICK_UPDATE_ENGINE_V011X.ps1'
$updateReport = Join-Path $logs 'BALI_SPEED_LANE_INTERNAL_UPDATE_REPORT_V011X.txt'
if(Test-Path -LiteralPath $updateEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $updateEngine -Root $rootPath -Report $updateReport -Stamp ('speed_' + $Stamp) | Out-Null
  $updateCode = $LASTEXITCODE
  Add ('Update engine exit code: ' + $updateCode)
  if(Test-Path -LiteralPath $updateReport) {
    $lines = Get-Content -LiteralPath $updateReport -ErrorAction SilentlyContinue
    ($lines | Where-Object { $_ -match '^(Selected version|Selected patch zip|Installed version|Highest available patch|RESULT:|Patch zip|Next step)' } | Select-Object -First 15) | ForEach-Object { Add $_ }
  } else { Add 'WARNING: internal update report missing' }
  if($updateCode -ne 0 -and $updateCode -ne 1) { Add 'RESULT: SPEED LANE FAIL - UPDATE STEP FAILED'; exit $updateCode }
  if($updateCode -eq 1) { Add 'No newer patch found; continuing to health/icon/cleanup/status checks.' }
} else { Add 'WARNING: V011X update engine missing; skipping update step and running checks only.' }
Add ''

Add '=== Step 2: fast health ==='
$healthEngine = Join-Path $rootPath 'tools\BALI_FAST_HEALTH_ENGINE_V011X.ps1'
$healthReport = Join-Path $logs 'BALI_FAST_HEALTH_REPORT_V011X.txt'
if(Test-Path -LiteralPath $healthEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $healthEngine -Root $rootPath -Report $healthReport | Out-Null
  $healthCode = $LASTEXITCODE
  Add ('Fast health exit code: ' + $healthCode)
  if(Test-Path -LiteralPath $healthReport) {
    Get-Content -LiteralPath $healthReport | Where-Object { $_ -match '^(APP_ROOT|PYTHON|PYTHON_VERSION|SYNTAX|UPDATE_ENGINE|BALI_THEMED_ICON|DESKTOP_SHORTCUT|PORT_9061|LAUNCH_BAY|DASH_UPDATE|DASH_RESTART|ROOT_GUARD|CLOSE_PREVIOUS|FINAL_REPORT|RESULT:)' } | ForEach-Object { Add $_ }
  }
  if($healthCode -ne 0) { Add 'RESULT: SPEED LANE FAIL - HEALTH STEP FAILED'; exit $healthCode }
} else { Add 'RESULT: SPEED LANE FAIL - FAST HEALTH ENGINE MISSING'; exit 8 }
Add ''

Add '=== Step 3: Bali themed desktop icon ==='
$desk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Forever Starter.lnk'
$old = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Rocket Forever Starter.lnk'
$iconEngine = Join-Path $rootPath 'tools\BALI_CREATE_FOREVER_DESKTOP_ICON_V011X.ps1'
$iconReport = Join-Path $logs 'BALI_THEMED_DESKTOP_ICON_REPORT_V011X.txt'
if((Test-Path -LiteralPath $desk -PathType Leaf) -and -not (Test-Path -LiteralPath $old -PathType Leaf)) {
  Add 'Desktop icon already OK: Bali Forever Starter'
} elseif(Test-Path -LiteralPath $iconEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $iconEngine -Root $rootPath -Report $iconReport | Out-Null
  $iconCode = $LASTEXITCODE
  Add ('Icon engine exit code: ' + $iconCode)
  if(Test-Path -LiteralPath $iconReport) { Get-Content -LiteralPath $iconReport | Where-Object { $_ -match '^(CREATED|REMOVED|RESULT:|Desktop shortcut|Target|Icon)' } | ForEach-Object { Add $_ } }
  if($iconCode -ne 0) { Add 'RESULT: SPEED LANE WARNING - ICON STEP NEEDS ATTENTION'; exit $iconCode }
} else { Add 'WARNING: icon engine missing, skipping icon creation' }
Add ''

Add '=== Step 4: launch bay cleanup ==='
$cleanupEngine = Join-Path $rootPath 'tools\BALI_LAUNCH_BAY_CLEANUP_V011X.ps1'
$cleanupReport = Join-Path $logs 'BALI_LAUNCH_BAY_CLEANUP_REPORT_V011X.txt'
if(Test-Path -LiteralPath $cleanupEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $cleanupEngine -Root $rootPath -Report $cleanupReport | Out-Null
  $cleanupCode = $LASTEXITCODE
  Add ('Cleanup exit code: ' + $cleanupCode)
  if(Test-Path -LiteralPath $cleanupReport) { Get-Content -LiteralPath $cleanupReport | Where-Object { $_ -match '^(Installed version|ARCHIVED|KEPT|REMOVED STAGING|Archived old patch ZIP count|Kept current|Archive folder|RESULT:)' } | Select-Object -First 25 | ForEach-Object { Add $_ } }
  if($cleanupCode -ne 0 -and $cleanupCode -ne 1) { Add 'RESULT: SPEED LANE WARNING - CLEANUP STEP NEEDS ATTENTION'; exit $cleanupCode }
} else { Add 'WARNING: cleanup engine missing, skipping launch bay cleanup' }
Add ''

Add '=== Step 5: auto compact status pack ==='
$statusEngine = Join-Path $rootPath 'tools\BALI_FAST_STATUS_PACK_V011X.ps1'
$statusReport = Join-Path $logs 'BALI_FAST_STATUS_PACK_V011X.txt'
if(Test-Path -LiteralPath $statusEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $statusEngine -Root $rootPath -Report $statusReport | Out-Null
  $statusCode = $LASTEXITCODE
  Add ('Status pack exit code: ' + $statusCode)
  Add ('Compact status pack: ' + $statusReport)
  if(Test-Path -LiteralPath $statusReport) { Get-Content -LiteralPath $statusReport | Where-Object { $_ -match '^(VERSION=|RESULT: FAST HEALTH|RESULT: FAST STATUS|APP_ROOT=|PYTHON_VERSION=|DESKTOP_SHORTCUT=)' } | Select-Object -First 12 | ForEach-Object { Add $_ } }
} else { Add 'WARNING: status pack engine missing, skipping auto status pack' }
Add ''
Add 'RESULT: SPEED LANE PASS'
Add 'Next normal flow: leave dashboard open; autopilot applies newer local patches from updates.'
Add 'For ChatGPT: paste only the tiny final dashboard report unless there is a warning/fail.'
try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_SPEED_LANE_UPDATE_REPORT.txt') -Force } catch {}
exit 0
