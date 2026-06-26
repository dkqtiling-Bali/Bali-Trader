param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Report
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $Report -Value @(
  'BALI FAST STATUS PACK V011L',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  'Purpose: compact paste-back report for faster ChatGPT patches.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII
# Current manifest summary.
$manifest = Join-Path $rootPath 'BALI_PATCH_MANIFEST.txt'
Add '=== Current manifest summary ==='
if(Test-Path -LiteralPath $manifest) {
  Get-Content -LiteralPath $manifest | Where-Object { $_ -match '^(VERSION|PATCH_NAME|PATCH_TYPE|MISSION|LIVE_ORDERS|CHAMPION_LOCK|API_KEYS_TOUCHED|TRADING_LOGIC_CHANGED|APP_PY_CHANGED|BALI_THEMED_DESKTOP_STARTER|FAST_UPDATE_SPEED_LANE|SHORTCUT_NAME|SUPERSEDES)=' } | ForEach-Object { Add $_ }
} else { Add 'ROOT_MANIFEST=MISSING' }
Add ''
# Run fast health into a nested report and copy key lines.
$healthEngine = Join-Path $rootPath 'tools\BALI_FAST_HEALTH_ENGINE_V011L.ps1'
$healthReport = Join-Path $logs 'BALI_FAST_HEALTH_REPORT_V011L.txt'
Add '=== Fast health summary ==='
if(Test-Path -LiteralPath $healthEngine) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $healthEngine -Root $rootPath -Report $healthReport | Out-Null
  if(Test-Path -LiteralPath $healthReport) {
    Get-Content -LiteralPath $healthReport | Where-Object { $_ -match '^(APP_ROOT|PYTHON|PYTHON_VERSION|SYNTAX|UPDATE_ENGINE|BALI_THEMED_ICON|DESKTOP_SHORTCUT|OLD_ROCKET_SHORTCUT|PORT_9061|RESULT:)' } | ForEach-Object { Add $_ }
  }
} else { Add 'FAST_HEALTH_ENGINE=MISSING' }
Add ''
# Last report snippets.
Add '=== Last report result lines ==='
$files = Get-ChildItem -LiteralPath $logs -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'REPORT|PACK' } | Sort-Object LastWriteTime -Descending | Select-Object -First 8
foreach($f in $files) {
  Add ('-- ' + $f.Name + ' :: ' + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
  $resultLines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '^(RESULT:|Selected version|Selected patch zip|Python selected|Syntax check|Dashboard|Desktop shortcut|Bali themed icon|Update active|V011[A-Z] marker|Safety:)' } | Select-Object -First 12
  foreach($l in $resultLines) { Add ('   ' + $l) }
}
Add ''
# Candidate zips.
Add '=== Patch ZIPs visible now ==='
$dirs = @((Join-Path $rootPath 'updates'), (Join-Path $env:USERPROFILE 'Downloads'), (Join-Path $env:USERPROFILE 'Desktop'), $rootPath) | Select-Object -Unique
$zips = foreach($d in $dirs) { if(Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Filter 'BALI_ROCKET_CRYPTO_COMMAND_*.zip' -File -ErrorAction SilentlyContinue } }
$zips | Where-Object { $_.FullName -notmatch '\\_staging_' -and $_.FullName -notmatch '\\backups\\' } | Sort-Object LastWriteTime -Descending | Select-Object -First 10 | ForEach-Object { Add ($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $_.FullName) }
Add ''
Add 'RESULT: FAST STATUS PACK READY'
Add 'Paste this report when asking for the next patch. It is designed to replace multiple long reports.'
try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_FAST_STATUS_PACK.txt') -Force } catch {}
exit 0
