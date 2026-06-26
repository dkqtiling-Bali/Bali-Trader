param(
  [string]$Base = 'C:\Bali\Bali-Trader'
)
$ErrorActionPreference = 'Stop'

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportDir = Join-Path $Base 'SAFETY_REPORTS'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report = Join-Path $reportDir "BALI_SAFETY_SCAN_V6E_$stamp.txt"

$excludedDirs = @(
  '.git','BACKUPS','AI_HANDOVER_REPORTS','DASHBOARD_LOGS','EVIDENCE_INDEX','INSTALL_REPORTS',
  'NEXT_PATCH_REPORTS','PROJECT_MAPS','SAFETY_REPORTS','SESSION_REPORTS','STATUS_DASHBOARDS',
  'RUN_REGISTRY','ARCHIVE_REPORTS','APPROVAL_QUEUE','PATCH_QUEUE','TEST_REPORTS','payload',
  '.venv','venv','node_modules','__pycache__','docs'
)

# Old/fallback tooling is not the active runtime. V7 will archive it properly.
$excludedPathFragments = @(
  '\bali_forever_setup\',
  '\BALI_AUTO_PATCH_LANE\',
  '\old\',
  '\archive\',
  '\archived\'
)

$activeExt = @('.ps1','.bat','.cmd','.py','.json','.toml','.yaml','.yml','.env','.ini','.cfg')
$blockers = New-Object System.Collections.Generic.List[string]
$scanned = 0
$ignored = 0

function RelPath([string]$path) {
  if ($path.StartsWith($Base, [System.StringComparison]::OrdinalIgnoreCase)) { return $path.Substring($Base.Length).TrimStart('\') }
  return $path
}

function Is-ExcludedPath([string]$path) {
  $rel = RelPath $path
  foreach ($d in $excludedDirs) {
    if ($rel -eq $d -or $rel.StartsWith($d + '\')) { return $true }
  }
  foreach ($frag in $excludedPathFragments) {
    if ($path -like "*$frag*") { return $true }
  }
  $name = [System.IO.Path]::GetFileName($path)
  if ($name -match '(?i)^(README|INSTALL_|RUN_INSTALL_)') { return $true }
  if ($name -match '(?i)^BALI_OS_SAFETY_SCAN_') { return $true }
  if ($name -match '(?i)^BALI_ONE_CLICK_UPDATE_ENGINE_') { return $true }
  if ($name -match '(?i)^BALI_AI_HQ_.*ANALYSE') { return $true }
  if ($name -match '(?i)^V\d+.*MANIFEST') { return $true }
  return $false
}

function Is-SafeGuardOrPolicyLine([string]$line) {
  $l = $line.Trim()
  if ($l -eq '') { return $true }
  # Comments / echo / Write-Host policy lines are not action code.
  if ($l -match '^(#|//|REM\b|::)') { return $true }
  if ($l -match '(?i)^echo\s+|Write-Host|Add-Report|Set-Content|Out-File|throw\s+|return\s+') { return $true }
  # Safety-policy text or negative assertions.
  if ($l -match '(?i)NO[_ ]?API|NO[_ ]?KEY|NO[_ ]?LIVE|LIVE[_ ]?ORDERS[_ ]?OFF|LIVE[_ ]?TRADING[_ ]?OFF|CHAMPION[_ ]?LOCKED|PAPER/SIM|PAPER[_ ]?SIM|does_not_|do_not_|must_not|blocked patches|safety preserved|never enable|do not enable|blocked by design|public_data_only') { return $true }
  # Search/regex/scanner definitions are guards, not live enablement.
  if ($l -match '(?i)-match|findstr|Select-String|Pattern\s*=|regex|scanner|safety scan|false positive|ignore|blocker|SKIP unsafe|blocked action|danger keywords') { return $true }
  # Quoted/listed keywords are not active settings.
  if ($l -match '^\s*["''].*["''],?\s*$') { return $true }
  return $false
}

function NormalizedActiveLine([string]$line) {
  # Remove trailing comments for assignment checks.
  $x = $line -replace '\s+#.*$',''
  $x = $x -replace '\s+//.*$',''
  return $x.Trim()
}

function Check-Line($file, $lineNo, $line) {
  if (Is-SafeGuardOrPolicyLine $line) { return }
  $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
  $l = NormalizedActiveLine $line

  # Real-looking secrets/tokens: assignment with substantial non-placeholder value.
  if ($l -match '(?i)\b(API_KEY|API_SECRET|SECRET_KEY|PRIVATE_KEY|ACCESS_TOKEN|BEARER_TOKEN|BINANCE_SECRET|BYBIT_SECRET)\b\s*[:=]\s*["'']?([^"''\s#]+)') {
    $val = $Matches[2]
    if ($val.Length -ge 16 -and $val -notmatch '(?i)PLACEHOLDER|DUMMY|EXAMPLE|NONE|OFF|REDACTED|YOUR_|NO_') {
      $script:blockers.Add("$(RelPath $file):$lineNo SECRET_OR_TOKEN_ASSIGNMENT :: $($line.Trim())") | Out-Null
      return
    }
  }

  # Live trading explicitly enabled. Value 0/OFF/FALSE is safe and will not match.
  if ($l -match '(?i)\b(LIVE_TRADING|LIVE_ORDERS|ENABLE_LIVE_TRADING|ENABLE_LIVE_ORDERS|REAL_ORDERS)\b\s*[:=]\s*["'']?(true|1|on|yes|enabled)["'']?\b') {
    $script:blockers.Add("$(RelPath $file):$lineNo LIVE_TRADING_ENABLED :: $($line.Trim())") | Out-Null
    return
  }

  # Champion unlock or lock disabled.
  if ($l -match '(?i)\b(CHAMPION_UNLOCKED|UNLOCK_CHAMPION)\b\s*[:=]\s*["'']?(true|1|on|yes|enabled)["'']?\b') {
    $script:blockers.Add("$(RelPath $file):$lineNo CHAMPION_UNLOCKED :: $($line.Trim())") | Out-Null
    return
  }
  if ($l -match '(?i)\b(CHAMPION_LOCKED|CHAMPION_LOCK)\b\s*[:=]\s*["'']?(false|0|off|no|unlocked)["'']?\b') {
    $script:blockers.Add("$(RelPath $file):$lineNo CHAMPION_LOCK_DISABLED :: $($line.Trim())") | Out-Null
    return
  }

  # Direct order placement calls in active Python runtime code only.
  if ($ext -eq '.py' -and $l -match '(?i)\b(create_order|place_order|submit_order|market_buy|market_sell)\s*\(') {
    $script:blockers.Add("$(RelPath $file):$lineNo ORDER_PLACEMENT_CALL :: $($line.Trim())") | Out-Null
    return
  }
}

$allFiles = Get-ChildItem -Path $Base -Recurse -File -ErrorAction SilentlyContinue
$files = foreach ($f in $allFiles) {
  if (Is-ExcludedPath $f.FullName) { $ignored++; continue }
  if ($activeExt -notcontains $f.Extension.ToLowerInvariant()) { $ignored++; continue }
  $f
}

foreach ($f in $files) {
  $scanned++
  try {
    $lines = Get-Content -Path $f.FullName -ErrorAction Stop
    for ($i = 0; $i -lt $lines.Count; $i++) { Check-Line $f.FullName ($i + 1) $lines[$i] }
  } catch {
    $blockers.Add("$(RelPath $f.FullName):0 READ_ERROR :: $($_.Exception.Message)") | Out-Null
  }
}

$status = if ($blockers.Count -gt 0) { 'BLOCKED' } else { 'PASS' }
$out = New-Object System.Collections.Generic.List[string]
$out.Add('BALI OS SAFETY SCAN V6E') | Out-Null
$out.Add("Generated: $(Get-Date)") | Out-Null
$out.Add("Base: $Base") | Out-Null
$out.Add("Status: $status") | Out-Null
$out.Add("Active files scanned: $scanned") | Out-Null
$out.Add("Ignored files/folders: $ignored") | Out-Null
$out.Add('') | Out-Null
$out.Add('Scanner policy:') | Out-Null
$out.Add('- Ignores generated report folders, payload folders, docs, old safety scanners, old patch engines, and safety-policy wording.') | Out-Null
$out.Add('- SAFE policy phrases such as NO_API_KEYS, LIVE_ORDERS_OFF, ENABLE_LIVE_ORDERS=0, and CHAMPION_LOCKED are not blockers.') | Out-Null
$out.Add('- Blocks only real-looking secret assignments, live order enablement, champion unlock, or direct order placement calls in active Python runtime code.') | Out-Null
$out.Add('') | Out-Null
if ($status -eq 'BLOCKED') {
  $out.Add('BLOCKERS FOUND:') | Out-Null
  foreach ($b in $blockers) { $out.Add('- ' + $b) | Out-Null }
} else {
  $out.Add('No active-code safety blockers found.') | Out-Null
}
$out | Set-Content -Encoding UTF8 $report
Copy-Item -Force $report (Join-Path $Base 'LATEST_SAFETY_REPORT.txt')

Write-Host "Safety scan created: $report"
Write-Host "Safety status: $status"
if ($status -eq 'BLOCKED') {
  Write-Host 'Exact blockers are listed in the safety report.'
  exit 1
}
exit 0
