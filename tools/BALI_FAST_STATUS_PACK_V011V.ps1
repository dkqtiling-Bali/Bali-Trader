param(

  [Parameter(Mandatory=$true)][string]$Root,

  [Parameter(Mandatory=$true)][string]$Report

)

$ErrorActionPreference = 'Continue'

$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')

$logs = Join-Path $rootPath 'logs'

$updates = Join-Path $rootPath 'updates'

New-Item -ItemType Directory -Force -Path $logs, $updates | Out-Null

function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }

Set-Content -LiteralPath $Report -Value @(

  'BALI FAST STATUS PACK V011V',

  ('Generated: ' + (Get-Date)),

  ('Root folder: ' + $rootPath),

  'Purpose: compact paste-back report for faster ChatGPT patches.',

  'Safety: live orders OFF, champion lock LOCKED, no API keys.',

  ''

) -Encoding ASCII

$manifest = Join-Path $rootPath 'BALI_PATCH_MANIFEST.txt'

Add '=== Current manifest summary ==='

if(Test-Path -LiteralPath $manifest) {

  Get-Content -LiteralPath $manifest | Where-Object { $_ -match '^(VERSION|PATCH_NAME|PATCH_TYPE|MISSION|LIVE_ORDERS|CHAMPION_LOCK|API_KEYS_TOUCHED|TRADING_LOGIC_CHANGED|APP_PY_CHANGED|BALI_THEMED_DESKTOP_STARTER|FAST_UPDATE_SPEED_LANE|LAUNCH_BAY_CLEANUP|NO_REAPPLY_CURRENT_VERSION|AUTO_STATUS_AFTER_SPEED_LANE|DASHBOARD_UPDATE_BRIDGE|DASHBOARD_UPDATE_BUTTON|AUTO_RESTART_AFTER_PATCH|SHORTCUT_NAME|SUPERSEDES)=' } | ForEach-Object { Add $_ }

} else { Add 'ROOT_MANIFEST=MISSING' }

Add ''

Add '=== Fast health summary ==='

$healthEngine = Join-Path $rootPath 'tools\BALI_FAST_HEALTH_ENGINE_V011V.ps1'

$healthReport = Join-Path $logs 'BALI_FAST_HEALTH_REPORT_V011V.txt'

if(Test-Path -LiteralPath $healthEngine) {

  & powershell -NoProfile -ExecutionPolicy Bypass -File $healthEngine -Root $rootPath -Report $healthReport | Out-Null

  if(Test-Path -LiteralPath $healthReport) {

    Get-Content -LiteralPath $healthReport | Where-Object { $_ -match '^(APP_ROOT|PYTHON|PYTHON_VERSION|SYNTAX|UPDATE_ENGINE|BALI_THEMED_ICON|DESKTOP_SHORTCUT|OLD_ROCKET_SHORTCUT|PORT_9061|LAUNCH_BAY|DASH_UPDATE|DASH_RESTART|RESULT:)' } | ForEach-Object { Add $_ }

  }

} else { Add 'FAST_HEALTH_ENGINE=MISSING' }

Add ''

Add '=== Launch bay cleanup summary ==='

$cleanupReport = Join-Path $logs 'LAST_LAUNCH_BAY_CLEANUP_REPORT.txt'

if(Test-Path -LiteralPath $cleanupReport) {

  Get-Content -LiteralPath $cleanupReport | Where-Object { $_ -match '^(Installed version|Archived old patch ZIP count|Kept current|Archive folder|RESULT:)' } | ForEach-Object { Add $_ }

} else { Add 'No cleanup report yet. Run BALI_SPEED_LANE_UPDATE.bat or BALI_LAUNCH_BAY_CLEANUP.bat.' }

Add ''

Add '=== Last report result lines ==='

$files = Get-ChildItem -LiteralPath $logs -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'REPORT|PACK' } | Sort-Object LastWriteTime -Descending | Select-Object -First 8

foreach($f in $files) {

  Add ('-- ' + $f.Name + ' :: ' + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))

  $resultLines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '^(RESULT:|Selected version|Selected patch zip|Installed version|Highest available patch|Python selected|Syntax check|Dashboard|Desktop shortcut|Safety:)' } | Select-Object -First 10

  foreach($l in $resultLines) { Add ('   ' + $l) }

}

Add ''

Add '=== Patch ZIPs visible in launch bay now ==='

$dirs = @($updates, $rootPath) | Select-Object -Unique

$zips = foreach($d in $dirs) { if(Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Filter 'BALI_ROCKET_CRYPTO_COMMAND_*.zip' -File -ErrorAction SilentlyContinue } }

$zips = $zips | Where-Object { $_.FullName -notmatch '\\applied_patch_archive\\' -and $_.FullName -notmatch '\\_staging_' } | Sort-Object LastWriteTime -Descending

if($zips) { $zips | Select-Object -First 10 | ForEach-Object { Add ($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $_.FullName) } } else { Add 'No active patch ZIPs in root/updates launch bay.' }

Add ''

Add '=== Archived patch ZIP folders ==='

$archives = Join-Path $updates 'applied_patch_archive'

if(Test-Path -LiteralPath $archives) {

  Get-ChildItem -LiteralPath $archives -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { Add ($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $_.FullName) }

} else { Add 'No archive folder yet.' }

Add ''

Add 'RESULT: FAST STATUS PACK READY'

Add 'Paste this compact report when asking for the next patch.'

try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_FAST_STATUS_PACK.txt') -Force } catch {}

exit 0

