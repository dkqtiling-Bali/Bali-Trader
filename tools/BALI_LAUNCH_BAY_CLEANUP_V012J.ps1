param(

  [Parameter(Mandatory=$true)][string]$Root,

  [Parameter(Mandatory=$true)][string]$Report

)

$ErrorActionPreference = 'Continue'

$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')

$updates = Join-Path $rootPath 'updates'

$logs = Join-Path $rootPath 'logs'

New-Item -ItemType Directory -Force -Path $updates, $logs | Out-Null

function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }

function Get-VersionRankFromText([string]$Text) {

  $m = [regex]::Match($Text, '(?im)^VERSION=V(\d+)([A-Z])\s*$')

  if(-not $m.Success) { return 0 }

  $num = [int]$m.Groups[1].Value

  $letter = $m.Groups[2].Value.ToUpper()[0]

  $letterRank = [int][char]$letter - [int][char]'A'

  return ($num * 100) + $letterRank

}

function Get-VersionRankFromName([string]$Name) {

  $m = [regex]::Match($Name, 'V(\d+)([A-Z])')

  if(-not $m.Success) { return 0 }

  $num = [int]$m.Groups[1].Value

  $letter = $m.Groups[2].Value.ToUpper()[0]

  $letterRank = [int][char]$letter - [int][char]'A'

  return ($num * 100) + $letterRank

}

function Get-VersionTextFromName([string]$Name) {

  $m = [regex]::Match($Name, '(V\d+[A-Z])')

  if($m.Success) { return $m.Groups[1].Value }

  return 'UNKNOWN'

}

Set-Content -LiteralPath $Report -Value @(

  'BALI LAUNCH BAY CLEANUP REPORT V012J',

  ('Generated: ' + (Get-Date)),

  ('Root folder: ' + $rootPath),

  'Purpose: archive old patch ZIPs so the updater only sees current/future patches.',

  'Scope: Bali root folder and updates folder only. Downloads/Desktop are not moved.',

  'Safety: live orders OFF, champion lock LOCKED, no API keys.',

  ''

) -Encoding ASCII

$manifest = Join-Path $rootPath 'BALI_PATCH_MANIFEST.txt'

$currentText = if(Test-Path -LiteralPath $manifest) { Get-Content -LiteralPath $manifest -Raw -ErrorAction SilentlyContinue } else { '' }

$currentRank = Get-VersionRankFromText $currentText

$currentVersion = 'UNKNOWN'

$m = [regex]::Match($currentText, '(?im)^VERSION=(V\d+[A-Z])\s*$')

if($m.Success) { $currentVersion = $m.Groups[1].Value }

Add ('Installed version: ' + $currentVersion)

Add ('Installed rank: ' + $currentRank)

if($currentRank -le 0) { Add 'RESULT: CLEANUP SKIPPED - CURRENT VERSION UNKNOWN'; exit 1 }

$archive = Join-Path $updates ('applied_patch_archive\before_' + $currentVersion + '_' + (Get-Date -Format yyyyMMdd_HHmmss))

$dirs = @($rootPath, $updates) | Select-Object -Unique

$zips = foreach($d in $dirs) { if(Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Filter 'BALI_ROCKET_CRYPTO_COMMAND_*.zip' -File -ErrorAction SilentlyContinue } }

$zips = $zips | Where-Object { $_.FullName -notmatch '\\applied_patch_archive\\' -and $_.FullName -notmatch '\\_staging_' } | Sort-Object FullName -Unique

Add ''

Add '=== Patch ZIP cleanup ==='

$moved = 0

$kept = 0

foreach($z in $zips) {

  $rank = Get-VersionRankFromName $z.Name

  $ver = Get-VersionTextFromName $z.Name

  if($rank -gt 0 -and $rank -lt $currentRank) {

    New-Item -ItemType Directory -Force -Path $archive | Out-Null

    $dest = Join-Path $archive $z.Name

    $i = 1

    while(Test-Path -LiteralPath $dest) {

      $base = [System.IO.Path]::GetFileNameWithoutExtension($z.Name)

      $dest = Join-Path $archive ($base + '_' + $i + '.zip')

      $i++

    }

    try {

      Move-Item -LiteralPath $z.FullName -Destination $dest -Force -ErrorAction Stop

      Add ('ARCHIVED OLD PATCH ZIP: ' + $ver + ' :: ' + $z.FullName)

      $moved++

    } catch {

      Add ('WARNING: could not archive ' + $z.FullName + ' :: ' + $_.Exception.Message)

    }

  } else {

    Add ('KEPT PATCH ZIP: ' + $ver + ' :: ' + $z.FullName)

    $kept++

  }

}

if($moved -eq 0) { Add 'No old lower-version patch ZIPs needed archiving.' }

Add ''

Add '=== Staging cleanup ==='

$stages = Get-ChildItem -LiteralPath $updates -Directory -Filter '_staging_*' -ErrorAction SilentlyContinue

$removedStages = 0

foreach($s in $stages) {

  try {

    Remove-Item -LiteralPath $s.FullName -Recurse -Force -ErrorAction Stop

    Add ('REMOVED STAGING FOLDER: ' + $s.FullName)

    $removedStages++

  } catch { Add ('WARNING: could not remove staging folder ' + $s.FullName + ' :: ' + $_.Exception.Message) }

}

if($removedStages -eq 0) { Add 'No staging folders found.' }

Add ''

Add ('Archived old patch ZIP count: ' + $moved)

Add ('Kept current/future patch ZIP count: ' + $kept)

if($moved -gt 0) { Add ('Archive folder: ' + $archive) }

Add 'RESULT: LAUNCH BAY CLEANUP PASS'

try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_LAUNCH_BAY_CLEANUP_REPORT.txt') -Force } catch {}

exit 0

