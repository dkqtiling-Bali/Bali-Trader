param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Report
)

$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$desktop = [Environment]::GetFolderPath('Desktop')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

function Add-Report([string]$Text='') {
  Add-Content -LiteralPath $Report -Value $Text -Encoding ASCII
}

Set-Content -LiteralPath $Report -Value @(
  'BALI ROCKET CRYPTO COMMAND - FOREVER DESKTOP STARTER ICON REPORT V011J',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  ('Desktop folder: ' + $desktop),
  'Mission: STARGATE RIVAL MODE - Bali Rocket challenger machine gets a permanent starter icon.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII

$target = Join-Path $rootPath 'BALI_ROCKET_FOREVER_STARTER.bat'
$fallbackTarget = Join-Path $rootPath 'ROCKET_CRYPTO_COMMAND_START.bat'
$iconJ = Join-Path $rootPath 'assets\BALI_ROCKET_FOREVER_ICON_V011J.ico'
$iconI = Join-Path $rootPath 'assets\BALI_ROCKET_FOREVER_ICON_V011I.ico'
$shortcut = Join-Path $desktop 'Bali Rocket Forever Starter.lnk'
$rootShortcut = Join-Path $rootPath 'Bali Rocket Forever Starter.lnk'

if(-not (Test-Path -LiteralPath $target -PathType Leaf)) {
  Add-Report ('WARNING: forever wrapper missing, falling back to: ' + $fallbackTarget)
  $target = $fallbackTarget
}
if(-not (Test-Path -LiteralPath $target -PathType Leaf)) {
  Add-Report 'RESULT: ICON CREATE FAILED'
  Add-Report ('Missing target launcher: ' + $target)
  exit 2
}
$icon = $iconJ
if(-not (Test-Path -LiteralPath $icon -PathType Leaf)) { $icon = $iconI }
if(-not (Test-Path -LiteralPath $icon -PathType Leaf)) {
  Add-Report 'RESULT: ICON CREATE FAILED'
  Add-Report ('Missing icon file: ' + $iconJ)
  Add-Report ('Also checked: ' + $iconI)
  exit 3
}

try {
  $shell = New-Object -ComObject WScript.Shell
  foreach($path in @($shortcut, $rootShortcut)) {
    $s = $shell.CreateShortcut($path)
    $s.TargetPath = $target
    $s.WorkingDirectory = $rootPath
    $s.IconLocation = $icon
    $s.Description = 'Bali Rocket Forever Starter - Stargate Rival Mode'
    $s.WindowStyle = 1
    $s.Save()
    Add-Report ('CREATED SHORTCUT: ' + $path)
  }
  Add-Report ''
  Add-Report 'RESULT: FOREVER DESKTOP ICON READY'
  Add-Report ('Desktop shortcut: ' + $shortcut)
  Add-Report ('Target: ' + $target)
  Add-Report ('Icon: ' + $icon)
  Add-Report 'Use the desktop icon to start Bali Rocket from now on.'
  Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_FOREVER_DESKTOP_ICON_REPORT.txt') -Force -ErrorAction SilentlyContinue
  exit 0
} catch {
  Add-Report 'RESULT: ICON CREATE FAILED'
  Add-Report $_.Exception.Message
  exit 4
}
