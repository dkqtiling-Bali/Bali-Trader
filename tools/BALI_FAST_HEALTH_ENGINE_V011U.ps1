param(



  [Parameter(Mandatory=$true)][string]$Root,



  [Parameter(Mandatory=$true)][string]$Report



)



$ErrorActionPreference = 'Continue'



$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')



$logs = Join-Path $rootPath 'logs'



New-Item -ItemType Directory -Force -Path $logs | Out-Null



function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }



function Find-AppRoot {



  if(Test-Path -LiteralPath (Join-Path $rootPath 'app.py') -PathType Leaf) { return $rootPath }



  $names = @('bali_rocket_crypto_command_v011b','bali_rocket_crypto_command_v011c','bali_rocket_crypto_command_v011d','bali_rocket_crypto_command_v011e','bali_rocket_crypto_command_v011f','bali_rocket_crypto_command_v011h','bali_rocket_crypto_command_v011i','bali_rocket_crypto_command_v011j','bali_rocket_crypto_command_v011k','bali_rocket_crypto_command_v011l','bali_rocket_crypto_command_v011m','bali_rocket_crypto_command_v011n','bali_rocket_crypto_command')



  foreach($n in $names) { $p = Join-Path $rootPath $n; if(Test-Path -LiteralPath (Join-Path $p 'app.py') -PathType Leaf) { return $p } }



  $d = Get-ChildItem -LiteralPath $rootPath -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'app.py') -PathType Leaf } | Select-Object -First 1



  if($d) { return $d.FullName }



  return $null



}



function Find-Python {



  $cands = @(



    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python310\python.exe'),



    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'),



    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),



    (Join-Path $env:ProgramFiles 'Python310\python.exe'),



    (Join-Path $env:ProgramFiles 'Python311\python.exe'),



    (Join-Path $env:ProgramFiles 'Python312\python.exe')



  )



  foreach($c in $cands) {



    if(Test-Path -LiteralPath $c -PathType Leaf) {



      $out = & $c -c "import sys; print(sys.version.split()[0]); raise SystemExit(0 if sys.version_info >= (3,10) and sys.version_info < (3,13) else 8)" 2>&1



      if($LASTEXITCODE -eq 0) { return [pscustomobject]@{Path=$c; Version=($out | Select-Object -First 1)} }



    }



  }



  return $null



}



Set-Content -LiteralPath $Report -Value @(



  'BALI FAST HEALTH REPORT V011U',



  ('Generated: ' + (Get-Date)),



  ('Root folder: ' + $rootPath),



  'Safety: live orders OFF, champion lock LOCKED, no API keys.',



  ''



) -Encoding ASCII



$app = Find-AppRoot



if($app) { Add ('APP_ROOT=FOUND :: ' + $app) } else { Add 'APP_ROOT=MISSING'; Add 'RESULT: FAST HEALTH FAIL'; exit 2 }



$py = Find-Python



if($py) { Add ('PYTHON=FOUND :: ' + $py.Path); Add ('PYTHON_VERSION=' + $py.Version) } else { Add 'PYTHON=MISSING_GOOD_3_10_TO_3_12'; Add 'RESULT: FAST HEALTH FAIL'; exit 3 }



& $py.Path -m py_compile (Join-Path $app 'app.py') 2>&1 | ForEach-Object { Add ('PY_COMPILE: ' + $_) }



if($LASTEXITCODE -ne 0) { Add 'SYNTAX=FAIL'; Add 'RESULT: FAST HEALTH FAIL'; exit 4 } else { Add 'SYNTAX=PASS' }



if(Test-Path -LiteralPath (Join-Path $rootPath 'BALI_ONE_CLICK_UPDATE.bat')) { Add 'UPDATER_BAT=FOUND' } else { Add 'UPDATER_BAT=MISSING' }



if(Test-Path -LiteralPath (Join-Path $rootPath 'tools\BALI_ONE_CLICK_UPDATE_ENGINE_V011U.ps1')) { Add 'UPDATE_ENGINE_V011U=FOUND' } else { Add 'UPDATE_ENGINE_V011U=MISSING' }



if(Test-Path -LiteralPath (Join-Path $rootPath 'BALI_PATCH_MANIFEST.txt')) { Add 'ROOT_MANIFEST=FOUND' } else { Add 'ROOT_MANIFEST=MISSING' }
if(Test-Path -LiteralPath (Join-Path $rootPath 'tools\BALI_ROOT_GUARD_V011U.ps1')) { Add 'ROOT_GUARD_V011U=FOUND' } else { Add 'ROOT_GUARD_V011U=MISSING' }


$appPy = Join-Path $app 'app.py'
try {
  $appText = Get-Content -LiteralPath $appPy -Raw -ErrorAction Stop
  if($appText -match '/api/dashboard/update-restart') { Add 'DASH_UPDATE_BRIDGE=FOUND' } else { Add 'DASH_UPDATE_BRIDGE=MISSING' }
} catch { Add 'DASH_UPDATE_BRIDGE=CHECK_ERROR' }
if(Test-Path -LiteralPath (Join-Path $rootPath 'tools\BALI_DASH_UPDATE_RESTART_ENGINE_V011U.ps1')) { Add 'DASH_RESTART_ENGINE_V011U=FOUND' } else { Add 'DASH_RESTART_ENGINE_V011U=MISSING' }
if(Test-Path -LiteralPath (Join-Path $rootPath 'tools\BALI_CLOSE_DASHBOARD_PORT_V011U.ps1')) { Add 'CLOSE_PREVIOUS_DASHBOARD_ENGINE_V011U=FOUND' } else { Add 'CLOSE_PREVIOUS_DASHBOARD_ENGINE_V011U=MISSING' }
Add 'FINAL_REPORT_ONLY=ON'




$iconL = Join-Path $rootPath 'assets\BALI_FOREVER_THEME_ICON_V011U.ico'



$iconK = Join-Path $rootPath 'assets\BALI_FOREVER_THEME_ICON_V011K.ico'



if(Test-Path -LiteralPath $iconL -PathType Leaf) { Add 'BALI_THEMED_ICON=FOUND_V011U' }



elseif(Test-Path -LiteralPath $iconK -PathType Leaf) { Add 'BALI_THEMED_ICON=FOUND_V011K_ALIAS' }



else { Add 'BALI_THEMED_ICON=MISSING' }



$desk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Forever Starter.lnk'



if(Test-Path -LiteralPath $desk -PathType Leaf) { Add 'DESKTOP_SHORTCUT=FOUND :: Bali Forever Starter' } else { Add 'DESKTOP_SHORTCUT=NOT_CREATED_YET' }



$old = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bali Rocket Forever Starter.lnk'



if(Test-Path -LiteralPath $old -PathType Leaf) { Add 'OLD_ROCKET_SHORTCUT=STILL_PRESENT' }



$port = netstat -ano | Select-String ':9061'



if($port) { Add 'PORT_9061=LISTENING_OR_ACTIVE'; $port | Select-Object -First 3 | ForEach-Object { Add ('PORT_DETAIL=' + $_.Line.Trim()) } } else { Add 'PORT_9061=NOT_LISTENING_OK_IF_DASHBOARD_CLOSED' }



if(Test-Path -LiteralPath (Join-Path $rootPath 'BALI_LAUNCH_BAY_CLEANUP.bat')) { Add 'LAUNCH_BAY_CLEANUP_BAT=FOUND' } else { Add 'LAUNCH_BAY_CLEANUP_BAT=MISSING' }

if(Test-Path -LiteralPath (Join-Path $rootPath 'tools\BALI_LAUNCH_BAY_CLEANUP_V011U.ps1')) { Add 'LAUNCH_BAY_CLEANUP_ENGINE_V011U=FOUND' } else { Add 'LAUNCH_BAY_CLEANUP_ENGINE_V011U=MISSING' }

Add 'AUTOPILOT_UPDATE=FOUND_V011U'
Add 'IMPORTANT_REPORT_ONLY=ON'
Add 'RESULT: FAST HEALTH PASS'



try { Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_FAST_HEALTH_REPORT.txt') -Force } catch {}



exit 0



