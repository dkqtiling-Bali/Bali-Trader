param(
  [Parameter(Mandatory=$true)][string]$Start
)
$ErrorActionPreference = 'SilentlyContinue'
function Looks-LikeInstallRoot([string]$p) {
  if([string]::IsNullOrWhiteSpace($p)) { return $false }
  if(Test-Path -LiteralPath (Join-Path $p 'bali_rocket_crypto_command_v011b\app.py') -PathType Leaf) { return $true }
  if(Test-Path -LiteralPath (Join-Path $p 'app.py') -PathType Leaf) { return $true }
  return $false
}
$p = [System.IO.Path]::GetFullPath($Start).TrimEnd('\')
# If launched inside an extracted patch folder under updates, climb to the real Bali root.
$cur = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
for($i=0; $i -lt 8 -and $cur; $i++) {
  $candidate = $cur.FullName.TrimEnd('\')
  if(Looks-LikeInstallRoot $candidate) {
    # Avoid accepting an extracted patch folder as root if it lives under an updates folder.
    if($candidate -notmatch '\\updates\\BALI_ROCKET_CRYPTO_COMMAND_') {
      Write-Output $candidate
      exit 0
    }
  }
  # If this candidate is an extracted patch folder under updates, parent of updates is the real root.
  if($candidate -match '^(.*)\\updates\\BALI_ROCKET_CRYPTO_COMMAND_.*$') {
    $real = $Matches[1]
    if(Looks-LikeInstallRoot $real) {
      Write-Output $real
      exit 0
    }
  }
  $cur = $cur.Parent
}
# Last fallback: if current path contains \updates\, return the parent before updates.
if($p -match '^(.*)\\updates(\\.*)?$') {
  $real = $Matches[1]
  if(Test-Path -LiteralPath $real -PathType Container) {
    Write-Output $real
    exit 0
  }
}
Write-Output $p
exit 0
