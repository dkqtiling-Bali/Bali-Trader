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





  'BALI THEMED DESKTOP STARTER ICON REPORT V011Y',





  ('Generated: ' + (Get-Date)),





  ('Root folder: ' + $rootPath),





  ('Desktop folder: ' + $desktop),





  'Mission: STARGATE RIVAL MODE - Bali themed forever starter for the challenger machine.',





  'Branding correction: the Desktop shortcut is Bali themed, not Bali Rocket branded.',





  'Safety: live orders OFF, champion lock LOCKED, no API keys.',





  ''





) -Encoding ASCII











$target = Join-Path $rootPath 'BALI_THEMED_FOREVER_STARTER.bat'





$fallbackTarget = Join-Path $rootPath 'ROCKET_CRYPTO_COMMAND_START.bat'





$iconL = Join-Path $rootPath 'assets\BALI_FOREVER_THEME_ICON_V011Y.ico'


$iconK = Join-Path $rootPath 'assets\BALI_FOREVER_THEME_ICON_V011K.ico'





$iconJ = Join-Path $rootPath 'assets\BALI_ROCKET_FOREVER_ICON_V011J.ico'





$newShortcut = Join-Path $desktop 'Bali Forever Starter.lnk'





$newRootShortcut = Join-Path $rootPath 'Bali Forever Starter.lnk'





$oldShortcut = Join-Path $desktop 'Bali Rocket Forever Starter.lnk'





$oldRootShortcut = Join-Path $rootPath 'Bali Rocket Forever Starter.lnk'











if(-not (Test-Path -LiteralPath $target -PathType Leaf)) {





  Add-Report ('WARNING: Bali-themed wrapper missing, falling back to: ' + $fallbackTarget)





  $target = $fallbackTarget





}





if(-not (Test-Path -LiteralPath $target -PathType Leaf)) {





  Add-Report 'RESULT: ICON CREATE FAILED'





  Add-Report ('Missing target launcher: ' + $target)





  exit 2





}





$icon = $iconL





if(-not (Test-Path -LiteralPath $icon -PathType Leaf)) { $icon = $iconK }





if(-not (Test-Path -LiteralPath $icon -PathType Leaf)) { $icon = $iconJ }





if(-not (Test-Path -LiteralPath $icon -PathType Leaf)) {





  Add-Report 'RESULT: ICON CREATE FAILED'





  Add-Report ('Missing Bali themed icon file: ' + $iconL)





  Add-Report ('Also checked compatibility icons: ' + $iconK + ' and ' + $iconJ)





  exit 3





}











try {





  foreach($old in @($oldShortcut, $oldRootShortcut)) {





    if(Test-Path -LiteralPath $old) {





      Remove-Item -LiteralPath $old -Force -ErrorAction SilentlyContinue





      Add-Report ('REMOVED OLD ROCKET-BRANDED SHORTCUT: ' + $old)





    }





  }





  $shell = New-Object -ComObject WScript.Shell





  foreach($path in @($newShortcut, $newRootShortcut)) {





    $s = $shell.CreateShortcut($path)





    $s.TargetPath = $target





    $s.WorkingDirectory = $rootPath





    $s.IconLocation = $icon





    $s.Description = 'Bali Forever Starter - Bali themed Stargate Rival Mode'





    $s.WindowStyle = 1





    $s.Save()





    Add-Report ('CREATED SHORTCUT: ' + $path)





  }





  Add-Report ''





  Add-Report 'RESULT: BALI THEMED DESKTOP ICON READY'





  Add-Report ('Desktop shortcut: ' + $newShortcut)





  Add-Report ('Target: ' + $target)





  Add-Report ('Icon: ' + $icon)





  Add-Report 'Use the desktop icon named Bali Forever Starter from now on.'





  Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_FOREVER_DESKTOP_ICON_REPORT.txt') -Force -ErrorAction SilentlyContinue





  Copy-Item -LiteralPath $Report -Destination (Join-Path $logs 'LAST_BALI_THEMED_DESKTOP_ICON_REPORT.txt') -Force -ErrorAction SilentlyContinue





  exit 0





} catch {





  Add-Report 'RESULT: ICON CREATE FAILED'





  Add-Report $_.Exception.Message





  exit 4





}





