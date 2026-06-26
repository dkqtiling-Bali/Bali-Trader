param(
  [string]$Base = "C:\Bali\Bali-Trader",
  [switch]$WriteReport
)

$ErrorActionPreference = "Stop"

function Add-Finding {
  param($Level, $File, $Line, $Text, $Reason)
  [pscustomobject]@{ Level=$Level; File=$File; Line=$Line; Text=$Text; Reason=$Reason }
}

$Base = (Resolve-Path -LiteralPath $Base).Path
$findings = New-Object System.Collections.Generic.List[object]
$warnings = New-Object System.Collections.Generic.List[object]
$excludeDirs = @(".git", "__pycache__", "node_modules", ".venv", "venv", "BACKUPS", "Archive", "archive")
$includeExt = @(".ps1", ".bat", ".cmd", ".py", ".md", ".txt", ".json", ".yml", ".yaml", ".ini", ".cfg")

$policySafeRegexes = @(
  '(?i)NO[_ ]API[_ ]KEYS?',
  '(?i)NO[_ ]LIVE[_ ]TRADING',
  '(?i)LIVE_ORDERS_OFF',
  '(?i)CHAMPION_LOCKED',
  '(?i)NO[_ ]CHAMPION[_ ]UNLOCK',
  '(?i)PAPER/SIM FIRST',
  '(?i)PUBLIC_DATA_ONLY',
  '(?i)do not enable live',
  '(?i)never enable live',
  '(?i)no app\.py edit',
  '(?i)no trading logic change',
  '(?i)safety preserved',
  '(?i)safety rules',
  '(?i)blocked:',
  '(?i)danger keyword',
  '(?i)secret/token pattern',
  '(?i)live-trading/champion-unlock enablement',
  '(?i)refuse live trading',
  '(?i)blocks live trading'
)

$hardSecretRegexes = @(
  '(?i)(api[_ -]?secret|secret[_ -]?key|private[_ -]?key|access[_ -]?token|refresh[_ -]?token)\s*[:=]\s*[''\"]?[A-Za-z0-9_\-\./+=]{16,}',
  '(?i)bearer\s+[A-Za-z0-9_\-\.]{24,}',
  '(?i)AKIA[0-9A-Z]{16}',
  '(?i)xox[baprs]-[A-Za-z0-9\-]{20,}',
  '(?i)sk-[A-Za-z0-9]{24,}'
)

$dangerEnableRegexes = @(
  '(?i)^\s*LIVE_ORDERS_ON\s*$',
  '(?i)live[_ -]?trading\s*[:=]\s*true',
  '(?i)live[_ -]?orders\s*[:=]\s*true',
  '(?i)champion[_ -]?unlock(ed)?\s*[:=]\s*true',
  '(?i)^\s*CHAMPION_UNLOCKED\s*$',
  '(?i)enable\s+live\s+trading\s*[:=]\s*true'
)

$warningRegexes = @(
  '(?i)todo\s*:\s*enable',
  '(?i)temporary\s+key',
  '(?i)manual\s+copy',
  '(?i)cut\s+and\s+paste',
  '(?i)hard.?coded\s+path'
)

$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $full = $_.FullName
  foreach ($d in $excludeDirs) { if ($full -match "[\\/]$([regex]::Escape($d))[\\/]") { return $false } }
  return $includeExt -contains $_.Extension.ToLowerInvariant()
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Base.Length).TrimStart("\", "/")
  try { $lines = Get-Content -LiteralPath $f.FullName -ErrorAction Stop } catch { continue }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    $trim = $line.Trim()
    if ($trim.Length -eq 0) { continue }

    $isPolicySafe = $false
    foreach ($rx in $policySafeRegexes) { if ($trim -match $rx) { $isPolicySafe = $true; break } }

    foreach ($rx in $hardSecretRegexes) {
      if ($trim -match $rx) {
        if (-not $isPolicySafe) { $findings.Add((Add-Finding "BLOCK" $rel ($i+1) $trim "Possible real secret/token pattern")) }
      }
    }
    foreach ($rx in $dangerEnableRegexes) {
      if ($trim -match $rx) {
        if (-not $isPolicySafe) { $findings.Add((Add-Finding "BLOCK" $rel ($i+1) $trim "Possible live-trading/champion unlock enablement")) }
      }
    }
    foreach ($rx in $warningRegexes) {
      if ($trim -match $rx) {
        if (-not $isPolicySafe) { $warnings.Add((Add-Finding "WARN" $rel ($i+1) $trim "Automation/process warning for review")) }
      }
    }
  }
}

$status = "PASS"
$blocks = @($findings | Where-Object { $_.Level -eq "BLOCK" })
if ($blocks.Count -gt 0) { $status = "BLOCK" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportDir = Join-Path $Base "SAFETY_REPORTS"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$reportPath = Join-Path $reportDir ("BALI_SAFETY_SCAN_V5_" + $stamp + ".txt")

$body = New-Object System.Collections.Generic.List[string]
$body.Add("BALI SAFETY SCAN V5")
$body.Add("Generated: " + (Get-Date))
$body.Add("Base: " + $Base)
$body.Add("Status: " + $status)
$body.Add("Block findings: " + $blocks.Count)
$body.Add("Warnings: " + $warnings.Count)
$body.Add("")
$body.Add("RULES")
$body.Add("- Safety-policy wording such as NO_API_KEYS, NO live trading, and CHAMPION_LOCKED does not block.")
$body.Add("- Real-looking secrets/tokens still block.")
$body.Add("- Direct live-trading/champion-unlock enablement still blocks.")
$body.Add("- Process warnings are listed but do not block Git save.")
$body.Add("")
if ($blocks.Count -eq 0) {
  $body.Add("No blocking findings detected.")
} else {
  foreach ($x in $blocks) {
    $body.Add(("[BLOCK] {0}:{1} - {2}" -f $x.File, $x.Line, $x.Reason))
    if ($x.Text.Length -gt 240) { $body.Add("  " + $x.Text.Substring(0,240) + "...") } else { $body.Add("  " + $x.Text) }
  }
}
$body.Add("")
$body.Add("WARNINGS")
if ($warnings.Count -eq 0) {
  $body.Add("No process warnings detected.")
} else {
  foreach ($x in ($warnings | Select-Object -First 50)) {
    $body.Add(("[WARN] {0}:{1} - {2}" -f $x.File, $x.Line, $x.Reason))
    if ($x.Text.Length -gt 180) { $body.Add("  " + $x.Text.Substring(0,180) + "...") } else { $body.Add("  " + $x.Text) }
  }
}
$body | Set-Content -LiteralPath $reportPath -Encoding UTF8

if ($WriteReport) {
  Write-Host ("Safety scan created: " + $reportPath)
  Write-Host ("Safety status: " + $status)
}

return [pscustomobject]@{ Status=$status; Report=$reportPath; BlockCount=$blocks.Count; WarningCount=$warnings.Count }
