param(
  [string]$Base = "C:\Bali\Bali-Trader",
  [switch]$WriteReport
)

$ErrorActionPreference = "Stop"

function Add-Finding {
  param($Level, $File, $Line, $Text, $Reason)
  [pscustomobject]@{ Level=$Level; File=$File; Line=$Line; Text=$Text; Reason=$Reason }
}

$findings = New-Object System.Collections.Generic.List[object]
$policySafePatterns = @(
  "NO_API_KEYS", "NO API KEYS", "NO API key", "NO_API", "NO API",
  "NO live trading", "NO LIVE TRADING", "LIVE_ORDERS_OFF", "live orders off",
  "CHAMPION_LOCKED", "champion locked", "NO champion unlock", "NO CHAMPION UNLOCK",
  "PAPER/SIM FIRST", "paper/sim", "PUBLIC_DATA_ONLY", "public data only",
  "do not enable", "never enable", "blocked", "safety preserved", "safety rules"
)

$hardSecretRegexes = @(
  '(?i)api[_ -]?secret\s*[:=]\s*[''"].{8,}',
  '(?i)secret[_ -]?key\s*[:=]\s*[''"].{8,}',
  '(?i)private[_ -]?key\s*[:=]\s*[''"].{8,}',
  '(?i)access[_ -]?token\s*[:=]\s*[''"].{12,}',
  '(?i)bearer\s+[A-Za-z0-9_\-\.]{20,}',
  '(?i)AKIA[0-9A-Z]{16}',
  '(?i)xox[baprs]-[A-Za-z0-9\-]{20,}',
  '(?i)sk-[A-Za-z0-9]{20,}'
)

$watchRegexes = @(
  '(?i)enable\s+live\s+trading',
  '(?i)live\s+trading\s*=\s*true',
  '(?i)LIVE_ORDERS_ON',
  '(?i)champion\s+unlock(ed)?\s*=\s*true',
  '(?i)CHAMPION_UNLOCKED',
  '(?i)add\s+api\s+key',
  '(?i)api[_ -]?key\s*[:=]'
)

$excludeDirs = @(".git", "__pycache__", "node_modules", ".venv", "venv")
$includeExt = @(".ps1", ".bat", ".cmd", ".py", ".md", ".txt", ".json", ".yml", ".yaml", ".ini", ".cfg")

$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $full = $_.FullName
  foreach ($d in $excludeDirs) { if ($full -match "[\\/]$([regex]::Escape($d))[\\/]") { return $false } }
  return $includeExt -contains $_.Extension.ToLowerInvariant()
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Base.Length).TrimStart("\", "/")
  $lines = @()
  try { $lines = Get-Content -LiteralPath $f.FullName -ErrorAction Stop } catch { continue }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    $trim = $line.Trim()
    $isPolicySafe = $false
    foreach ($p in $policySafePatterns) { if ($trim.IndexOf($p, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $isPolicySafe = $true; break } }

    foreach ($rx in $hardSecretRegexes) {
      if ($trim -match $rx) {
        if (-not $isPolicySafe) { $findings.Add((Add-Finding "BLOCK" $rel ($i+1) $trim "Possible real secret/token pattern")) }
      }
    }

    foreach ($rx in $watchRegexes) {
      if ($trim -match $rx) {
        if ($isPolicySafe) {
          $findings.Add((Add-Finding "INFO" $rel ($i+1) $trim "Safety policy mention, not a blocker"))
        } else {
          $findings.Add((Add-Finding "REVIEW" $rel ($i+1) $trim "Risk phrase outside obvious safety-policy context"))
        }
      }
    }
  }
}

$blocks = @($findings | Where-Object { $_.Level -eq "BLOCK" })
$reviews = @($findings | Where-Object { $_.Level -eq "REVIEW" })
$infos = @($findings | Where-Object { $_.Level -eq "INFO" })

$status = "PASS"
if ($blocks.Count -gt 0) { $status = "BLOCK" }
elseif ($reviews.Count -gt 0) { $status = "REVIEW" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportDir = Join-Path $Base "SAFETY_REPORTS"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$reportPath = Join-Path $reportDir ("BALI_SAFETY_SCAN_V4B_" + $stamp + ".txt")

$body = New-Object System.Collections.Generic.List[string]
$body.Add("BALI SAFETY SCAN V4B")
$body.Add("Generated: " + (Get-Date))
$body.Add("Base: " + $Base)
$body.Add("Status: " + $status)
$body.Add("Block findings: " + $blocks.Count)
$body.Add("Review findings: " + $reviews.Count)
$body.Add("Safety-policy mentions ignored/info: " + $infos.Count)
$body.Add("")
$body.Add("RULES")
$body.Add("- Safety-policy mentions such as NO_API_KEYS or NO live trading do not block Git save.")
$body.Add("- Real-looking secrets/tokens still block.")
$body.Add("- Live trading enablement/champion unlock outside safety-policy context requires review.")
$body.Add("")
foreach ($x in $findings) {
  $body.Add(("[{0}] {1}:{2} - {3}" -f $x.Level, $x.File, $x.Line, $x.Reason))
  if ($x.Text.Length -gt 240) { $body.Add("  " + $x.Text.Substring(0,240) + "...") } else { $body.Add("  " + $x.Text) }
}
$body | Set-Content -LiteralPath $reportPath -Encoding UTF8

$result = [pscustomobject]@{
  Status=$status
  Report=$reportPath
  BlockCount=$blocks.Count
  ReviewCount=$reviews.Count
  InfoCount=$infos.Count
}

if ($WriteReport) {
  Write-Host ("Safety scan created: " + $reportPath)
  Write-Host ("Safety status: " + $status)
}

return $result
