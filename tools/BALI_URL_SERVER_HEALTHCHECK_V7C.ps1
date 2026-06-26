param([int]$Port = 8787)
$ErrorActionPreference = 'SilentlyContinue'
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$Port/health" -TimeoutSec 2
  if ($r.StatusCode -eq 200) { Write-Host "PASS - Dashboard server responding on http://localhost:$Port"; exit 0 }
} catch {}
Write-Host "BLOCKED - Dashboard server not responding on http://localhost:$Port"
exit 1
