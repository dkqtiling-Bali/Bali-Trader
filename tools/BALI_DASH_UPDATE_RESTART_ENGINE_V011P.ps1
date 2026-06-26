param(
  [Parameter(Mandatory=$true)][string]$Root,
  [int]$Port = 9061,
  [int]$ManualMode = 0
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report = Join-Path $logs 'BALI_DASH_UPDATE_RESTART_REPORT_V011P.txt'
function Add([string]$s='') { Add-Content -LiteralPath $report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $report -Value @(
  'BALI DASH UPDATE AUTO RESTART REPORT V011P',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  'Purpose: dashboard-triggered patch apply, fast health, cleanup, status pack, then dashboard restart.',
  'Mission: STARGATE RIVAL MODE - faster controlled upgrades from inside the dash.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII
Add '=== Step 0: dashboard handoff ==='
if($ManualMode -eq 1) {
  Add 'Manual mode: started from BALI_DASH_UPDATE_RESTART.bat. Close any running dashboard if the port stays busy.'
} else {
  Add 'Dashboard mode: server endpoint launched this bridge and should exit so files can be replaced safely.'
}
Add ('Waiting for dashboard port ' + $Port + ' to release before applying patch...')
Start-Sleep -Seconds 4
try {
  $portRows = netstat -ano | Select-String (':' + $Port)
  if($portRows) {
    Add ('PORT_' + $Port + '=STILL_ACTIVE_BEFORE_UPDATE')
    ($portRows | Select-Object -First 3) | ForEach-Object { Add ('PORT_DETAIL=' + $_.Line.Trim()) }
  } else {
    Add ('PORT_' + $Port + '=CLEAR_BEFORE_UPDATE')
  }
} catch { Add ('PORT_CHECK_WARNING=' + $_.Exception.Message) }
Add ''

Add '=== Step 1: speed lane apply/check ==='
$speedEngine = Join-Path $rootPath 'tools\BALI_SPEED_LANE_ENGINE_V011P.ps1'
if(-not (Test-Path -LiteralPath $speedEngine -PathType Leaf)) {
  # fallback for installs that have not refreshed the engine name yet
  $fallback = Join-Path $rootPath 'tools\BALI_SPEED_LANE_ENGINE_V011M.ps1'
  if(Test-Path -LiteralPath $fallback -PathType Leaf) { $speedEngine = $fallback }
}
if(-not (Test-Path -LiteralPath $speedEngine -PathType Leaf)) {
  Add 'RESULT: DASH UPDATE FAIL - SPEED LANE ENGINE MISSING'
  exit 8
}
$speedReport = Join-Path $logs 'BALI_DASH_INTERNAL_SPEED_LANE_REPORT_V011P.txt'
$stamp = 'dash_' + (Get-Date -Format yyyyMMdd_HHmmss)
& powershell -NoProfile -ExecutionPolicy Bypass -File $speedEngine -Root $rootPath -Report $speedReport -Stamp $stamp | Out-Null
$code = $LASTEXITCODE
Add ('Speed lane engine: ' + $speedEngine)
Add ('Speed lane exit code: ' + $code)
if(Test-Path -LiteralPath $speedReport) {
  Get-Content -LiteralPath $speedReport | Where-Object { $_ -match '^(Selected version|Selected patch zip|Installed version|Highest available patch|RESULT:|Patch zip|Compact status pack|Desktop shortcut|Next normal flow)' } | Select-Object -First 30 | ForEach-Object { Add $_ }
}
if($code -ne 0 -and $code -ne 1) {
  Add 'RESULT: DASH UPDATE FAIL - SPEED LANE FAILED'
  try { Start-Process notepad $report | Out-Null } catch {}
  exit $code
}
Add ''

Add '=== Step 2: restart dashboard ==='
$starter = Join-Path $rootPath 'BALI_THEMED_FOREVER_STARTER.bat'
if(-not (Test-Path -LiteralPath $starter -PathType Leaf)) { $starter = Join-Path $rootPath 'ROCKET_CRYPTO_COMMAND_START.bat' }
if(Test-Path -LiteralPath $starter -PathType Leaf) {
  Add ('Starting dashboard via: ' + $starter)
  try {
    Start-Process -FilePath $starter -WorkingDirectory $rootPath | Out-Null
    Add 'RESTART=LAUNCHED'
  } catch {
    Add ('RESTART=FAILED :: ' + $_.Exception.Message)
    Add 'RESULT: DASH UPDATE WARNING - PATCH APPLIED BUT RESTART FAILED'
    try { Start-Process notepad $report | Out-Null } catch {}
    exit 7
  }
} else {
  Add 'RESTART=FAILED :: no starter BAT found'
  Add 'RESULT: DASH UPDATE WARNING - PATCH APPLIED BUT STARTER MISSING'
  try { Start-Process notepad $report | Out-Null } catch {}
  exit 7
}
Add ''
Add 'RESULT: DASH UPDATE AUTO RESTART PASS'
Add 'Next normal flow: from the dashboard Updates tab, use Dashboard Update + Auto Restart after dropping the next patch ZIP into updates.'
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_DASH_UPDATE_RESTART_REPORT.txt') -Force } catch {}
try { Start-Process notepad $report | Out-Null } catch {}
exit 0
