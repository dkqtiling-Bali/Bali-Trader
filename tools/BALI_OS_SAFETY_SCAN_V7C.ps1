param([string]$Base = 'C:\Bali\Bali-Trader')
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$dir = Join-Path $Base 'SAFETY_REPORTS'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$out = Join-Path $dir "BALI_SAFETY_SCAN_V7C_$stamp.txt"

$ignoreDirs = @('SAFETY_REPORTS','AI_HANDOVER_REPORTS','DASHBOARD_LOGS','STATUS_DASHBOARDS','NEXT_PATCH_REPORTS','PROJECT_MAPS','EVIDENCE_INDEX','SESSION_REPORTS','RUN_REGISTRY','INSTALL_REPORTS','BACKUPS','ARCHIVE_REPORTS','.git','payload','docs')
$scanExt = @('.ps1','.bat','.cmd','.py','.json','.env','.ini','.yml','.yaml')
$blockers = New-Object System.Collections.Generic.List[string]

function Is-IgnoredPath([string]$path) {
  foreach ($d in $ignoreDirs) {
    if ($path -match "[\\/]$([regex]::Escape($d))[\\/]") { return $true }
  }
  return $false
}
function Is-SafePolicyLine([string]$line) {
  if ($line -match '(?i)NO[_ -]?API[_ -]?KEYS|NO[_ -]?KEYS|LIVE[_ -]?ORDERS[_ -]?OFF|LIVE[_ -]?TRADING[_ -]?OFF|CHAMPION[_ -]?LOCKED|NO live trading|does_not_enable_live_orders|does_not_unlock_champion|SKIP unsafe|block real danger|BLOCKED PATCHES|Safety preserved|Patch class') { return $true }
  if ($line -match '(?i)findstr|Scanner rule|possible live trading|possible champion|CHAMPION_UNLOCKED' -and $line -match '(?i)BALI_OS_SAFETY_SCAN|SAFETY_SCAN') { return $true }
  return $false
}
function Is-OldScannerOrPatchTool([string]$path) {
  $name = [System.IO.Path]::GetFileName($path)
  if ($name -match '(?i)BALI_OS_SAFETY_SCAN_V(4|5|6|7)|BALI_AI_HQ_V3_ANALYSE|BALI_ONE_CLICK_UPDATE_ENGINE|BALI_AUTO_PATCH_RUNNER') { return $true }
  return $false
}

$files = Get-ChildItem -Path $Base -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  ($scanExt -contains $_.Extension.ToLower()) -and -not (Is-IgnoredPath $_.FullName) -and -not (Is-OldScannerOrPatchTool $_.FullName)
}

foreach ($file in $files) {
  $n = 0
  foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
    $n++
    if (Is-SafePolicyLine $line) { continue }
    if ($line -match '(?i)^\s*(LIVE_TRADING|LIVE_ORDERS|ENABLE_LIVE_TRADING|ENABLE_LIVE_ORDERS)\s*[:=]\s*(ON|TRUE|1|YES|ENABLED)\b') {
      $blockers.Add("- $($file.FullName.Substring($Base.Length).TrimStart('\')) line $n - live trading/orders enabled :: $line")
    }
    if ($line -match '(?i)^\s*(CHAMPION_UNLOCKED|UNLOCK_CHAMPION|CHAMPION_LOCK)\s*[:=]\s*(ON|TRUE|1|YES|OFF|FALSE|0|ENABLED)\b') {
      if ($line -notmatch '(?i)CHAMPION_LOCK\s*[:=]\s*(ON|TRUE|1|YES|LOCKED)') {
        $blockers.Add("- $($file.FullName.Substring($Base.Length).TrimStart('\')) line $n - champion unlock risk :: $line")
      }
    }
    if ($file.Extension.ToLower() -eq '.py' -and $line -match '(?i)\b(create_order|place_order|market_buy|market_sell)\s*\(') {
      $blockers.Add("- $($file.FullName.Substring($Base.Length).TrimStart('\')) line $n - direct order placement call :: $line")
    }
    if ($line -match '(?i)^\s*(API_SECRET|API_KEY|PRIVATE_KEY|SECRET_KEY|ACCESS_TOKEN|PRIVATE_ENDPOINT)\s*[:=]\s*["''][A-Za-z0-9_\-]{12,}["'']') {
      $blockers.Add("- $($file.FullName.Substring($Base.Length).TrimStart('\')) line $n - possible real secret assignment :: [redacted]")
    }
  }
}

$status = if ($blockers.Count -eq 0) { 'PASS' } else { 'BLOCKED' }
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('BALI OS SAFETY SCAN V7C')
$lines.Add("Generated: $(Get-Date)")
$lines.Add("Base: $Base")
$lines.Add("Status: $status")
$lines.Add('')
$lines.Add('Scope: active launcher/tool/runtime/config files only. Generated reports, docs, payloads, backups, old scanners, and safety-policy text are ignored.')
$lines.Add('')
if ($blockers.Count -gt 0) {
  $lines.Add('BLOCKERS:')
  foreach ($b in $blockers) { $lines.Add($b) }
} else {
  $lines.Add('No active danger patterns found.')
  $lines.Add('Safety locks expected: LIVE_ORDERS_OFF | NO_API_KEYS | PUBLIC_DATA_ONLY | PAPER/SIM FIRST | CHAMPION_LOCKED')
}
$lines | Set-Content -Path $out -Encoding UTF8
Write-Host "Safety scan created: $out"
Write-Host "Safety status: $status"
if ($status -eq 'BLOCKED') { exit 1 } else { exit 0 }
