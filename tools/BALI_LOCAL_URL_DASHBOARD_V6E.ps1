param(
  [string]$Base = 'C:\Bali\Bali-Trader',
  [int]$Port = 8787
)
$ErrorActionPreference = 'Stop'
Set-Location $Base

function Get-LocalIPs {
  try {
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } |
      Select-Object -ExpandProperty IPAddress -Unique
  } catch { @() }
}
function LatestFile($dir) {
  $p = Join-Path $Base $dir
  if (-not (Test-Path $p)) { return $null }
  Get-ChildItem $p -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
function Read-Latest($kind) {
  $map = @{
    status='STATUS_DASHBOARDS'; recommendation='NEXT_PATCH_REPORTS'; handover='AI_HANDOVER_REPORTS';
    safety='SAFETY_REPORTS'; evidence='EVIDENCE_INDEX'; map='PROJECT_MAPS'; session='SESSION_REPORTS'; log='DASHBOARD_LOGS'
  }
  if (-not $map.ContainsKey($kind)) { return "Unknown view: $kind" }
  $f = LatestFile $map[$kind]
  if (-not $f) { return "No latest $kind file found." }
  return "FILE: $($f.FullName)`r`n`r`n" + (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
}
function GitState {
  try { $s = & git status --short 2>$null; if ($s) { 'DIRTY' } else { 'CLEAN' } } catch { 'UNKNOWN' }
}
function LatestRecLine {
  $f = LatestFile 'NEXT_PATCH_REPORTS'
  if (-not $f) { return 'No recommendation yet' }
  $txt = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
  $m = [regex]::Match($txt, 'Recommended Next Patch:\s*\r?\n([^\r\n]+)', 'IgnoreCase')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return $f.Name
}
function Html($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }
function Page($body) {
@"
<!doctype html>
<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Bali OS V6E</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;background:#071018;color:#e9f7ff;margin:0;padding:18px} .wrap{max-width:980px;margin:auto}
.card{background:#102233;border:1px solid #24445f;border-radius:18px;padding:16px;margin:12px 0;box-shadow:0 0 18px rgba(0,180,255,.15)}
h1{margin:0 0 8px;color:#6ee7ff}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px}.btn{display:block;text-align:center;padding:14px;border-radius:14px;background:#163a52;color:#fff;text-decoration:none;border:1px solid #41b5e6;font-weight:700}.btn:hover{background:#1d5273}.danger{color:#ffb4b4}.ok{color:#9cffc6}.muted{color:#aac0cc}pre{white-space:pre-wrap;background:#061018;border-radius:12px;padding:14px;overflow:auto}.pill{display:inline-block;padding:6px 10px;border-radius:999px;background:#0b1721;border:1px solid #2d566f;margin:4px}
</style></head><body><div class='wrap'>$body</div></body></html>
"@
}
function HomePage($message='') {
  $git = GitState
  $rec = LatestRecLine
  $safety = LatestFile 'SAFETY_REPORTS'
  $status = LatestFile 'STATUS_DASHBOARDS'
  $msgHtml = if ($message) { "<div class='card'><b>Result:</b> $(Html $message)</div>" } else { '' }
  Page @"
<h1>Bali OS V6E Control Dashboard</h1>
<div class='card'>
  <span class='pill'>Safety: safe scan required before actions</span>
  <span class='pill'>Git: $(Html $git)</span>
  <span class='pill'>Live Trading: OFF</span>
  <span class='pill'>API Keys: NONE</span>
  <span class='pill'>Champion Lock: ON</span>
  <p class='muted'>Base: $(Html $Base)</p>
  <p><b>Recommended next:</b> $(Html $rec)</p>
</div>
$msgHtml
<div class='card'><h2>Safe Actions</h2><div class='grid'>
<a class='btn' href='/run?action=auto'>START DAY / AUTO SESSION</a>
<a class='btn' href='/run?action=git'>END DAY / GIT SAFE SAVE</a>
<a class='btn' href='/run?action=safety'>SAFETY SCAN</a>
<a class='btn' href='/run?action=recommend'>RECOMMEND NEXT PATCH</a>
<a class='btn' href='/run?action=handover'>NEW CHAT HANDOVER</a>
<a class='btn' href='/run?action=evidence'>EVIDENCE INDEX</a>
</div></div>
<div class='card'><h2>View Latest</h2><div class='grid'>
<a class='btn' href='/view?type=status'>STATUS</a>
<a class='btn' href='/view?type=recommendation'>RECOMMENDATION</a>
<a class='btn' href='/view?type=handover'>HANDOVER</a>
<a class='btn' href='/view?type=safety'>SAFETY REPORT</a>
<a class='btn' href='/view?type=evidence'>EVIDENCE INDEX</a>
<a class='btn' href='/view?type=map'>PROJECT MAP</a>
<a class='btn' href='/view?type=session'>SESSION REPORT</a>
<a class='btn' href='/view?type=log'>DASHBOARD LOG</a>
</div></div>
<div class='card'><p class='muted'>Phone/LAN access is optional and limited to these safe actions. No arbitrary command box exists.</p></div>
"@
}
function TextPage($title,$text) {
  Page "<h1>$(Html $title)</h1><div class='card'><a class='btn' href='/'>Back</a></div><pre>$(Html $text)</pre>"
}
function Send($ctx,$html) {
  $bytes = [Text.Encoding]::UTF8.GetBytes($html)
  $ctx.Response.ContentType = 'text/html; charset=utf-8'
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
  $ctx.Response.OutputStream.Close()
}
function RunAction($action) {
  $allowed = @('auto','git','safety','recommend','handover','evidence','map','status')
  if ($allowed -notcontains $action) { return "Blocked unknown action: $action" }
  $bat = Join-Path $Base 'tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat'
  if (-not (Test-Path $bat)) { return "Missing safe runner: $bat" }
  # V6E fix: do not use cmd `start` with an unquoted title. That caused Windows to try to run `Bali` as a program.
  # Start cmd.exe directly and keep it open with /k so the operator can read the result.
  $args = "/k `"$bat`" $action"
  Start-Process -FilePath 'cmd.exe' -ArgumentList $args -WorkingDirectory $Base | Out-Null
  return "Started safe action '$action' in a visible console window on the Bali PC. Review that window or latest dashboard log when it finishes."
}

$listener = [System.Net.HttpListener]::new()
$prefixes = New-Object System.Collections.Generic.List[string]
$prefixes.Add("http://localhost:$Port/") | Out-Null
try { $prefixes.Add("http://127.0.0.1:$Port/") | Out-Null } catch {}
foreach ($p in $prefixes) { $listener.Prefixes.Add($p) }
try { $listener.Start() } catch { throw "Could not start local dashboard on port $Port. $($_.Exception.Message)" }

$ips = Get-LocalIPs
Write-Host '=========================================='
Write-Host '     BALI OS V6E LOCAL URL DASHBOARD'
Write-Host '=========================================='
Write-Host "Local URL: http://localhost:$Port"
foreach ($ip in $ips) { Write-Host "Possible phone URL: http://$ip`:$Port" }
Write-Host 'Keep this window open while using the URL dashboard.'
Write-Host 'Press Ctrl+C to stop.'
try { Start-Process "http://localhost:$Port" } catch {}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = $ctx.Request.Url.AbsolutePath.Trim('/').ToLowerInvariant()
    if ($path -eq 'run') {
      $a = $ctx.Request.QueryString['action']
      Send $ctx (HomePage (RunAction $a))
    } elseif ($path -eq 'view') {
      $t = $ctx.Request.QueryString['type']
      Send $ctx (TextPage "Latest $t" (Read-Latest $t))
    } else {
      Send $ctx (HomePage)
    }
  } catch {
    Send $ctx (TextPage 'Dashboard Error' $_.Exception.Message)
  }
}
