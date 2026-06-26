param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Report,
  [Parameter(Mandatory=$true)][string]$Stamp
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $Report -Value @(
  'BALI SPEED LANE UPDATE REPORT V011L',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  'Purpose: one double-click for update + fast health + Bali themed icon check.',
  'Mission: STARGATE RIVAL MODE - faster controlled upgrades for the challenger machine.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII

$updateEngine = Join-Path $rootPath 'tools\BALI_ONE_CLICK_UPDATE_ENGINE_V011L.ps1'
$updateReport = Join-Path $logs 'BALI_SPEED_LANE_INTERNAL_UPDATE_REPORT_V011L.txt'
if(Test-Path -LiteralPath $updateEngine -PathType Leaf) {
  Add '=== Step 1: one-click update engine ==='
  & powershell -NoProfile -ExecutionPolicy Bypass -File $updateEngine -Root $rootPath -Report $updateReport -Stamp ('speed_' + $Stamp) | Out-Null
  $updateCode = $LASTEXITCODE
  Add ('Update engine exit code: ' + $updateCode)
  if(Test-Path -LiteralPath $updateReport) {
    $lines = Get-Content -LiteralPath $updateReport -ErrorAction SilentlyContinue
    ($lines | Where-Object { $_ -match '^(Selected version|Selected patch zip|RESULT:|Patch zip|Next step)' } | Select-Object -First 12) | ForEach-Object { Add $_ }
  } else { Add 'WARNING: internal update report missing' }
  if($updateCode -ne 0 -and $updateCode -ne 1) { Add 'RESULT: SPEED LANE FAIL - UPDATE STEP FAILED'; exit $updateCode }
  if($updateCode -eq 1) { Add 'No new patch zip found; continuing to health/icon checks.' }
  Add ''
} else {
  Add 'WARNING: V011L update engine missing; skipping update step and running checks only.'
  Add ''
}

Add '=== Step 2: fast health ==='
$healthEngine = Join-Path $rootPath 'tools\BALI_FAST_HEALTH_ENGINE_V011L.ps1'
$healthReport = Join-Path $logs 'BALI_FAST_HEALTH_REPORT_V011L.txt'
if(Test-Path -LiteralPath $healthEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $healthEngine -Root $rootPath -Report $healthReport | Out-Null
  $healthCode = $LASTEXITCODE
  Add ('Fast health exit code: ' + $healthCode)
  if(Test-Path -LiteralPath $healthReport) {
    Get-Content -LiteralPath $healthReport | Where-Object { $_ -match '^(APP_ROOT|PYTHON|PYTHON_VERSION|SYNTAX|UPDATE_ENGINE|BALI_THEMED_ICON|DESKTOP_SHORTCUT|OLD_ROCKET_SHORTCUT|PORT_9061|RESULT:)' } | ForEach-Object { Add $_ }
  }
  if($healthCode -ne 0) { Add 'RESULT: SPEED LANE FAIL - HEALTH STEP FAILED'; exit $healthCode }
} else { Add 'RESULT: SPEED LANE FAIL - FAST HEALTH ENGINE MISSING'; exit 8 }
Add ''

Add '=== Step 3: Bali themed desktop icon ==='
$desk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Forever Starter.lnk'
$old = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Rocket Forever Starter.lnk'
$iconEngine = Join-Path $rootPath 'tools\BALI_CREATE_FOREVER_DESKTOP_ICON_V011L.ps1'
$iconReport = Join-Path $logs 'BALI_THEMED_DESKTOP_ICON_REPORT_V011L.txt'
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
Add 'RESULT: SPEED LANE PASS'
Add 'Next normal flow: put next patch ZIP in root/updates, then double-click BALI_SPEED_LANE_UPDATE.bat.'
Add 'For ChatGPT: paste this one report, not every full report, unless I ask for more.'
try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_SPEED_LANE_UPDATE_REPORT.txt') -Force } catch {}
exit 0
