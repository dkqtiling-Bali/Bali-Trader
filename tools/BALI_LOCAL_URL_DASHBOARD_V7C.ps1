param(
  [ValidateSet('local','lan')][string]$Mode = 'local',
  [int]$Port = 8787,
  [string]$Base = 'C:\Bali\Bali-Trader'
)
$ErrorActionPreference = 'Stop'
Set-Location $Base

function Get-LocalIp {
  try {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop | Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1 -ExpandProperty IPAddress
    if ($ip) { return $ip }
  } catch {}
  try { return ([System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) | Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPAddressToString -notlike '127.*' } | Select-Object -First 1).IPAddressToString } catch {}
  return 'YOUR-PC-IP'
}
function HtmlEncode([string]$s){
  if ($null -eq $s) { return '' }
  return [System.Net.WebUtility]::HtmlEncode([string]$s)
}
function ParseQuery([string]$query){
  $result = @{}
  if ([string]::IsNullOrWhiteSpace($query)) { return $result }
  $q = $query.TrimStart('?')
  foreach($part in $q -split '&'){
    if ([string]::IsNullOrWhiteSpace($part)) { continue }
    $kv = $part -split '=',2
    $key = [System.Uri]::UnescapeDataString(($kv[0] -replace '\+',' '))
    $val = ''
    if($kv.Count -gt 1){ $val = [System.Uri]::UnescapeDataString(($kv[1] -replace '\+',' ')) }
    if($key){ $result[$key] = $val }
  }
  return $result
}
function LatestFile($dir){ $p=Join-Path $Base $dir; if(Test-Path $p){ Get-ChildItem $p -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 } }
function GitState { try { Set-Location $Base; $s=git status --porcelain 2>$null; if($s){'DIRTY'}else{'CLEAN'} } catch {'UNKNOWN'} }
function LatestSafetyStatus {
  $f=LatestFile 'SAFETY_REPORTS'
  if(-not $f){ return 'UNKNOWN' }
  $txt=Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
  if($txt -match 'Status:\s*PASS|Safety status:\s*PASS'){ return 'PASS' }
  if($txt -match 'Status:\s*BLOCKED|Safety status:\s*BLOCKED'){ return 'BLOCKED' }
  return 'UNKNOWN'
}
function Send($ctx,[string]$body,[string]$contentType='text/html'){
  $bytes=[System.Text.Encoding]::UTF8.GetBytes($body)
  $ctx.Response.ContentType=$contentType + '; charset=utf-8'
  $ctx.Response.ContentLength64=$bytes.Length
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
  $ctx.Response.OutputStream.Close()
}
function Layout([string]$title,[string]$content){
  $git=GitState; $safe=LatestSafetyStatus
  return @"
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:#071017;color:#e8f6ff}header{padding:18px;background:#102332;border-bottom:1px solid #244b63}h1{margin:0;font-size:24px}.wrap{padding:16px;max-width:1100px;margin:auto}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:14px 0}.card{background:#102332;border:1px solid #244b63;border-radius:12px;padding:12px}.ok{color:#73ff9c}.bad{color:#ff7a7a}.warn{color:#ffd36b}.buttons{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.btn{display:block;text-decoration:none;color:#e8f6ff;background:#16415c;border:1px solid #2c6f94;border-radius:14px;padding:18px;font-size:18px;font-weight:700;text-align:center}.btn:hover{background:#1d587d}.small{font-size:13px;color:#aac7d6}.pre{white-space:pre-wrap;background:#061018;border:1px solid #244b63;border-radius:12px;padding:14px;overflow:auto}a{color:#8fd7ff}.toplink{float:right;color:#8fd7ff;text-decoration:none}footer{padding:20px;color:#aac7d6;text-align:center}</style>
</head><body><header><a class="toplink" href="/">Home</a><h1>$title</h1><div class="small">Bali OS V7C local dashboard — safe tooling only</div></header><div class="wrap">
<div class="cards"><div class="card">Safety<br><b class="$(if($safe -eq 'PASS'){'ok'}elseif($safe -eq 'BLOCKED'){'bad'}else{'warn'})">$safe</b></div><div class="card">Git<br><b class="$(if($git -eq 'CLEAN'){'ok'}elseif($git -eq 'DIRTY'){'warn'}else{'bad'})">$git</b></div><div class="card">Live Trading<br><b class="ok">OFF</b></div><div class="card">API Keys<br><b class="ok">NONE</b></div><div class="card">Champion Lock<br><b class="ok">ON</b></div></div>
$content
</div><footer>Keep the PowerShell server window open. Close it to stop the dashboard.</footer></body></html>
"@
}
function Home {
  $ip=Get-LocalIp
  $phone="http://${ip}:$script:ActualPort"
  $content=@"
<h2>Control Panel</h2>
<div class="buttons">
<a class="btn" href="/run?action=auto">START DAY / AUTO SESSION</a>
<a class="btn" href="/run?action=git">END DAY / GIT SAFE SAVE</a>
<a class="btn" href="/run?action=safety">SAFETY SCAN</a>
<a class="btn" href="/run?action=recommend">RECOMMEND NEXT PATCH</a>
<a class="btn" href="/run?action=handover">NEW CHAT HANDOVER</a>
<a class="btn" href="/latest?type=status">VIEW LATEST STATUS</a>
<a class="btn" href="/latest?type=recommendation">VIEW RECOMMENDATION</a>
<a class="btn" href="/latest?type=handover">VIEW HANDOVER</a>
<a class="btn" href="/latest?type=safety">VIEW SAFETY</a>
<a class="btn" href="/latest?type=log">VIEW LATEST LOG</a>
</div>
<p class="small">Local URL: <a href="http://localhost:$script:ActualPort">http://localhost:$script:ActualPort</a><br>Phone/LAN URL, if enabled and firewall allows: $phone</p>
"@
  return Layout 'BALI OS V7C DASHBOARD' $content
}
function LaunchAction([string]$action){
  $runner=Join-Path $Base 'tools\BALI_DASHBOARD_SAFE_RUN_V7C.bat'
  Start-Process -FilePath $runner -ArgumentList $action -WorkingDirectory $Base | Out-Null
}
function RunPage([string]$action){
  if($action -notin @('auto','git','safety','recommend','handover','status','map','evidence')){ $action='auto' }
  LaunchAction $action
  $content="<h2>Action launched: $(HtmlEncode $action)</h2><p>A visible console window should open on the PC and stay open after the action finishes.</p><p><a class='btn' href='/latest?type=log'>Open Latest Log</a></p><p><a href='/'>Back to dashboard</a></p>"
  return Layout 'BALI ACTION LAUNCHED' $content
}
function LatestPage([string]$type){
  $map=@{
    status='STATUS_DASHBOARDS'; recommendation='NEXT_PATCH_REPORTS'; handover='AI_HANDOVER_REPORTS'; safety='SAFETY_REPORTS'; log='DASHBOARD_LOGS'; evidence='EVIDENCE_INDEX'; map='PROJECT_MAPS'; session='SESSION_REPORTS'
  }
  if(-not $map.ContainsKey($type)){ $type='log' }
  $f=LatestFile $map[$type]
  if(-not $f){ return Layout 'Latest file' "<p>No latest file found for $type.</p>" }
  $txt=Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
  $content="<h2>Latest $type</h2><p class='small'>FILE: $(HtmlEncode $f.FullName)</p><div class='pre'>$(HtmlEncode $txt)</div><p><a href='/'>Back</a></p>"
  return Layout "Latest $type" $content
}

$ports = @($Port,8788,8789,8790,8791,8792) | Select-Object -Unique
$listener = $null
$script:ActualPort = $null
foreach($p in $ports){
  try{
    $l = New-Object System.Net.HttpListener
    if($Mode -eq 'lan'){
      $l.Prefixes.Add("http://+:$p/")
    } else {
      $l.Prefixes.Add("http://localhost:$p/")
    }
    $l.Start()
    $listener=$l; $script:ActualPort=$p; break
  } catch {
    Write-Host "Port/prefix failed: $p - $($_.Exception.Message)"
  }
}
if(-not $listener){ throw 'Could not start dashboard server. Try running local mode as Administrator only if needed, or check Windows Firewall/port use.' }

Write-Host '=========================================='
Write-Host '        BALI OS V7C URL DASHBOARD'
Write-Host '=========================================='
Write-Host "Mode: $Mode"
Write-Host "Project: $Base"
Write-Host "Local URL: http://localhost:$script:ActualPort"
if($Mode -eq 'lan'){ Write-Host "Phone/LAN URL: http://$(Get-LocalIp):$script:ActualPort" }
Write-Host 'Keep this window open. Press Ctrl+C to stop.'
Write-Host ''

while($listener.IsListening){
  $ctx=$listener.GetContext()
  try{
    $path=$ctx.Request.Url.AbsolutePath
    $qs=ParseQuery $ctx.Request.Url.Query
    if($path -eq '/health'){ Send $ctx 'OK' 'text/plain'; continue }
    if($path -eq '/run'){ Send $ctx (RunPage $qs['action']); continue }
    if($path -eq '/latest'){ Send $ctx (LatestPage $qs['type']); continue }
    Send $ctx (Home)
  } catch {
    Send $ctx (Layout 'Dashboard error' "<div class='pre'>$(HtmlEncode $_.Exception.Message)</div>")
  }
}
