
param([string]$RootPath)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($RootPath)){ $RootPath=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs=Join-Path $RootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_ARENA_REFEREE_SCORE_ROUND_REPORT_V012F.txt'
function Add([string]$line){ Add-Content -LiteralPath $report -Value $line -Encoding ASCII }
Set-Content -LiteralPath $report -Value @('BALI ARENA REFEREE SCORE ROUND V012F',('Generated: ' + (Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS','MODE=SIM_ONLY','RAW_LIVE_DATA_ONLY=ON','') -Encoding ASCII
$bridge=Join-Path $RootPath 'game_arena\bridge\shared_drop'
$baliDir=Join-Path $bridge 'from_bali'
$gateDir=Join-Path $bridge 'from_stargate'
$resultDir=Join-Path $bridge 'round_results'
$scoreDir=Join-Path $RootPath 'game_arena\bridge\scoreboard'
New-Item -ItemType Directory -Force -Path $baliDir,$gateDir,$resultDir,$scoreDir | Out-Null
function LatestJson($dir){ Get-ChildItem -LiteralPath $dir -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }
function LoadJson($file){ if(-not $file){ return $null }; try { return Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json } catch { return $null } }
function N($obj,$name,$fallback){ try { $v=$obj.$name; if($null -eq $v){ return $fallback }; return [double]$v } catch { return $fallback } }
function B($obj,$name){ try { return [bool]$obj.$name } catch { return $false } }
function Score($bot){
  if($null -eq $bot){ return @{score=-999; safety='MISSING'; detail='missing check-in'} }
  $origin=''; try { $origin=([string]$bot.data_origin).ToUpperInvariant() } catch {}
  $required=@('data_origin','source_exchange','source_symbol','market_timestamp_utc','captured_at_utc','raw_ticks_count')
  foreach($k in $required){ try { if($null -eq $bot.$k -or [string]::IsNullOrWhiteSpace([string]$bot.$k)){ return @{score=-999; safety='RAW_LIVE_DATA_FAIL'; detail=('missing ' + $k)} } } catch { return @{score=-999; safety='RAW_LIVE_DATA_FAIL'; detail=('missing ' + $k)} } }
  if($origin -ne 'RAW_LIVE_DATA'){ return @{score=-999; safety='RAW_LIVE_DATA_FAIL'; detail=('blocked origin ' + $origin)} }
  if((N $bot 'raw_ticks_count' 0) -lt 1){ return @{score=-999; safety='RAW_LIVE_DATA_FAIL'; detail='raw_ticks_count too low'} }
  $live=B $bot 'orders_live'; $keys=B $bot 'api_keys_present'; $viol=N $bot 'safety_violations' 0
  if($live -or $keys -or $viol -gt 0){ return @{score=-999; safety='FAIL'; detail='safety violation'} }
  $profit=N $bot 'profit_pct' 0
  $dd=[math]::Abs((N $bot 'max_drawdown_pct' 0))
  $risk=N $bot 'risk_events' 0
  $uptime=N $bot 'uptime_pct' 100
  $signal=N $bot 'signal_quality' 50
  $score=[math]::Round(($profit*10) - ($dd*4) - ($risk*5) + ($uptime*0.25) + ($signal*0.2),2)
  return @{score=$score; safety='PASS'; detail='raw live data scored'}
}
$baliFile=LatestJson $baliDir; $gateFile=LatestJson $gateDir
$bali=LoadJson $baliFile; $gate=LoadJson $gateFile
$baliScore=Score $bali; $gateScore=Score $gate
if($null -eq $baliFile){ Add 'BALI_CHECKIN=MISSING' } else { Add ('BALI_CHECKIN=' + $baliFile.Name) }
if($null -eq $gateFile){ Add 'STARGATE_CHECKIN=MISSING' } else { Add ('STARGATE_CHECKIN=' + $gateFile.Name) }
$winner='DRAW'
if($baliScore.score -gt $gateScore.score){ $winner='BALI' }
elseif($gateScore.score -gt $baliScore.score){ $winner='STARGATE' }
$roundId='ROUND_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
$result=[ordered]@{
  version='V012F'; round_id=$roundId; mode='SIM_ONLY'; bridge='SHARED_FOLDER_JSON_ONLY'; raw_live_data_only=$true;
  bali_checkin= if($baliFile){$baliFile.FullName}else{''}; stargate_checkin= if($gateFile){$gateFile.FullName}else{''};
  bali_score=$baliScore.score; stargate_score=$gateScore.score; winner=$winner;
  bali_safety=$baliScore.safety; stargate_safety=$gateScore.safety;
  safety='LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS';
  notes='RAW LIVE DATA ONLY SIM referee score. No fake/seed/mock scoring data. No orders, no API keys, no remote commands.'
}
$resultPath=Join-Path $resultDir ($roundId + '_V012F.json')
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resultPath -Encoding ASCII
$scoreboard=[ordered]@{
  version='V012F'; mode='SIM_ONLY'; rounds_scored=1; last_round=$roundId; last_winner=$winner;
  bali=@{score=$baliScore.score; safety=$baliScore.safety; xp=[math]::Max(0,[int]($baliScore.score)); level=1};
  stargate=@{score=$gateScore.score; safety=$gateScore.safety; xp=[math]::Max(0,[int]($gateScore.score)); level=1};
  result_file=$resultPath; safety='LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS'
}
$scoreboard | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $scoreDir 'ARENA_SCOREBOARD_V012F.json') -Encoding ASCII
Add ('BALI_SCORE=' + $baliScore.score)
Add ('STARGATE_SCORE=' + $gateScore.score)
Add ('WINNER=' + $winner)
Add ('ROUND_RESULT=' + $resultPath)
Add 'REFEREE_SCOREBOARD=READY_SIM_ONLY'
Add 'RAW_LIVE_DATA_ONLY=ON'
Add 'RESULT=REFEREE_SCORE_ROUND_PASS'
try { Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_ARENA_REFEREE_SCORE_ROUND_REPORT.txt') -Force } catch {}
