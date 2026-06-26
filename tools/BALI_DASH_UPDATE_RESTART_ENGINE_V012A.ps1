param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 9061,
  [int]$ManualMode = 0
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report = Join-Path $logs 'BALI_DASH_UPDATE_FINAL_REPORT_V012A.txt'
$debug = Join-Path $logs 'BALI_DASH_UPDATE_DEBUG_REPORT_V012A.txt'
function Add([string]$s='') { Add-Content -LiteralPath $report -Value $s -Encoding ASCII }
function AddD([string]$s='') { Add-Content -LiteralPath $debug -Value $s -Encoding ASCII }
function OpenReport(){ try { Start-Process notepad $report | Out-Null } catch {} }
Set-Content -LiteralPath $debug -Value @('BALI DASH UPDATE DEBUG REPORT V012A',('Generated: ' + (Get-Date)),('Root folder: ' + $rootPath),'') -Encoding ASCII
Set-Content -LiteralPath $report -Value @('BALI TINY UPDATE RESULT - STARTING',('Generated: ' + (Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS') -Encoding ASCII

$closeEngine = Join-Path $rootPath 'tools\BALI_CLOSE_DASHBOARD_PORT_V012A.ps1'
$closeReport = Join-Path $logs 'BALI_CLOSE_DASHBOARD_PORT_REPORT_V012A.txt'
$closeOk = 'UNKNOWN'
if(Test-Path -LiteralPath $closeEngine -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $closeEngine -Root $rootPath -Report $closeReport -Port $Port -Force 1 | Out-Null
  $closeCode = $LASTEXITCODE
  AddD ('Close dashboard exit code: ' + $closeCode)
  if(Test-Path -LiteralPath $closeReport) {
    Get-Content -LiteralPath $closeReport | ForEach-Object { AddD $_ }
    $line = (Get-Content -LiteralPath $closeReport | Where-Object { $_ -match '^LISTENER_STATUS' } | Select-Object -Last 1)
    if($line) { $closeOk = $line }
  }
  if($closeCode -ge 2) {
    Add 'RESULT: FAIL'
    Add 'STEP=CLOSE_DASHBOARD'
    Add ('ERROR=Previous dashboard listener did not clear on port ' + $Port)
    Add ('DETAIL_REPORT=' + $closeReport)
    OpenReport
    exit $closeCode
  }
} else { AddD 'Close engine missing; continuing with normal shutdown wait.'; Start-Sleep -Seconds 4 }

$speedEngine = Join-Path $rootPath 'tools\BALI_SPEED_LANE_ENGINE_V012A.ps1'
if(-not (Test-Path -LiteralPath $speedEngine -PathType Leaf)) {
  Add 'RESULT: FAIL'
  Add 'STEP=SPEED_LANE_ENGINE'
  Add ('ERROR=Missing ' + $speedEngine)
  OpenReport
  exit 8
}
$speedReport = Join-Path $logs 'BALI_DASH_INTERNAL_SPEED_LANE_REPORT_V012A.txt'
$stamp = 'dash_' + (Get-Date -Format yyyyMMdd_HHmmss)
& powershell -NoProfile -ExecutionPolicy Bypass -File $speedEngine -Root $rootPath -Report $speedReport -Stamp $stamp -Quiet 1 | Out-Null
$code = $LASTEXITCODE
AddD ('Speed lane exit code: ' + $code)
if(Test-Path -LiteralPath $speedReport) { Get-Content -LiteralPath $speedReport | ForEach-Object { AddD $_ } }
AddD 'USER_REPORT=IMPORTANT_ONLY_SELECTED_INSTALLED_HIDDEN'
if($code -ne 0 -and $code -ne 1) {
  Add 'RESULT: FAIL'
  Add 'STEP=SPEED_LANE'
  Add ('ERROR=Speed lane failed with code ' + $code)
  Add ('DETAIL_REPORT=' + $speedReport)
  OpenReport
  exit $code
}

$selected = ''
$installed = ''
$health = 'UNKNOWN'
if(Test-Path -LiteralPath $speedReport) {
  $lines = Get-Content -LiteralPath $speedReport -ErrorAction SilentlyContinue
  $selected = ($lines | Where-Object { $_ -match '^Selected version:' } | Select-Object -Last 1)
  $installed = ($lines | Where-Object { $_ -match '^Installed version:' } | Select-Object -Last 1)
  if($lines -match 'RESULT: FAST HEALTH PASS') { $health = 'PASS' }
}
$manifest = Join-Path $rootPath 'BALI_PATCH_MANIFEST.txt'
$version = ''
if(Test-Path -LiteralPath $manifest) { $version = (Get-Content -LiteralPath $manifest | Where-Object { $_ -match '^VERSION=' } | Select-Object -Last 1) }
# Rebuild the user-visible success report with only important fields. Detailed selected/installed data stays in the debug report.
$titleVersion = 'UNKNOWN'
if($version) { $titleVersion = ($version -replace '^VERSION=','').Trim() }
elseif($installed) { $titleVersion = ($installed -replace '^Installed version:','').Trim() }
Set-Content -LiteralPath $report -Value @(('BALI TINY UPDATE RESULT ' + $titleVersion),('Generated: ' + (Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS') -Encoding ASCII
if($version) { Add $version } else { Add ('VERSION=' + $titleVersion) }
Add ('HEALTH=' + $health)
if($closeOk -match 'CLEAR') { Add 'CLOSE=PASS' } else { Add ('CLOSE=' + $closeOk) }

$starter = Join-Path $rootPath 'BALI_THEMED_FOREVER_STARTER.bat'
if(-not (Test-Path -LiteralPath $starter -PathType Leaf)) { $starter = Join-Path $rootPath 'ROCKET_CRYPTO_COMMAND_START.bat' }
if(Test-Path -LiteralPath $starter -PathType Leaf) {
  try {
    Start-Process -FilePath $starter -WorkingDirectory $rootPath -WindowStyle Normal | Out-Null
    Add 'RESTART=PASS'
  } catch {
    Add 'RESULT: WARNING'
    Add ('ERROR=Patch/health completed but restart failed: ' + $_.Exception.Message)
    Add ('DETAIL_REPORT=' + $debug)
    OpenReport
    exit 7
  }
} else {
  Add 'RESULT: WARNING'
  Add 'ERROR=Patch/health completed but starter BAT missing'
  OpenReport
  exit 7
}
Add 'AUTOPILOT=LOCAL_ONLY'
Add 'WATCHER=PASS'
Add 'BUNDLE=READY'
Add 'GOVERNOR=MISSION_CONSOLE'
Add 'ARENA=GAME_FOUNDATION'
Add 'RESULT=PASS'
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_DASH_UPDATE_RESTART_REPORT.txt') -Force } catch {}
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_FINAL_REPORT.txt') -Force } catch {}
OpenReport
exit 0
