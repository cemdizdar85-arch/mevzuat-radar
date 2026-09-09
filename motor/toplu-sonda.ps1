# TOPLU KUYRUK SONDASI (09.09.2026, Cem "ara ara deneyelim orayı, rakamı düşürmemiz lazım")
# Anthropic Message Batches kuyruğu bu hesapta gün içinde saatlerce durup sabah açılıyor (08–09.09 ölçümü: pencere ≈08:00–10:45).
# Bu betik 30 dakikada bir 2 istekli Haiku partisi (≈0,001 USD) gönderir, 8 dakika izler ve sonucu
#   veri/fabrika/toplu-kuyruk-sagligi.json  → { zaman, durum: "acik" | "kapali", sure_sn, parti }
# dosyasına yazar. Koşucu (kalip-kosucu.ps1) MEVZUAT_TOPLU='auto' iken her etiket başında bu dosyaya bakar: taze "acik" → -Toplu (yarı fiyat),
# yoksa anlık. Üretici ayrıca faz bazında MEVZUAT_TOPLU_BEKLE_DK sonra anlığa düşer. Kurulum: -Kur (görev tetikte-toplu-sonda, 30 dk).
param([switch]$Kur,[switch]$Kaldir,[int]$BekleDk=8)
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok=Split-Path $buDizin -Parent
$saglik=Join-Path $kok 'veri\fabrika\toplu-kuyruk-sagligi.json'
$nlog=Join-Path $kok 'veri\fabrika\kosucu-log\toplu-sonda.log'
function Yaz([string]$s){ $satir="[$(Get-Date -Format 'dd.MM HH:mm:ss')] $s"; $satir; try{ [IO.File]::AppendAllText($nlog,"$satir`r`n",[Text.UTF8Encoding]::new($false)) }catch{} }
if($Kaldir){ Unregister-ScheduledTask -TaskName 'tetikte-toplu-sonda' -Confirm:$false -ErrorAction SilentlyContinue; Yaz 'sonda görevi kaldırıldı'; return }
if($Kur){
  $sarmalDir=$(if(Test-Path 'C:\TETIKTE-YEDEK'){ 'C:\TETIKTE-YEDEK\hat' } else { Join-Path $env:USERPROFILE 'tetikte-hat' }); New-Item -ItemType Directory -Force $sarmalDir | Out-Null
  $sarmal=Join-Path $sarmalDir 'toplu-sonda.ps1'
  [IO.File]::WriteAllText($sarmal,"& '$($MyInvocation.MyCommand.Path)' *>> '$($nlog -replace '\.log$','-kosu.log')'`r`n",[Text.UTF8Encoding]::new($true))
  Unregister-ScheduledTask -TaskName 'tetikte-toplu-sonda' -Confirm:$false -ErrorAction SilentlyContinue
  $psYol=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $eylem=New-ScheduledTaskAction -Execute $psYol -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$sarmal`""
  $tetik=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 30)
  $ayar=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15) -MultipleInstances IgnoreNew -StartWhenAvailable
  Register-ScheduledTask -TaskName 'tetikte-toplu-sonda' -Action $eylem -Trigger $tetik -Settings $ayar -Description 'Tetikte toplu kuyruk sondası: 30 dk''da bir 2 istekli parti, sağlık dosyası (motor/toplu-sonda.ps1)' | Out-Null
  Yaz "sonda görevi kuruldu (30 dk); sarmal $sarmal"
  return
}
# --- tek koşu ---
$key=[Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User'); if(-not $key){ $key=$env:ANTHROPIC_API_KEY }
if(-not $key){ Yaz 'ANTHROPIC_API_KEY yok'; return }
$h=@{ 'x-api-key'=$key; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' }
$damga=Get-Date -Format 'HHmm'
$reqs=@(); foreach($i in 1..2){ $reqs+=@{ custom_id="tetikte-sonda-$damga-$i"; params=@{ model='claude-haiku-4-5-20251001'; max_tokens=5; messages=@(@{ role='user'; content="Yalnız $i yaz." }) } } }
$body=@{ requests=$reqs } | ConvertTo-Json -Depth 6
$t0=Get-Date; $durum='kapali'; $bid=''
try{
  $b=Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $h -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 60
  $bid="$($b.id)"
  while(((Get-Date)-$t0).TotalMinutes -lt $BekleDk){
    Start-Sleep -Seconds 20
    $s=Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$bid" -Headers @{ 'x-api-key'=$key; 'anthropic-version'='2023-06-01' } -TimeoutSec 60
    if($s.processing_status -eq 'ended'){ $durum=$(if([int]$s.request_counts.succeeded -ge 2){ 'acik' } else { 'kapali' }); break }
  }
  if($durum -ne 'acik'){ try{ Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches/$bid/cancel" -Headers @{ 'x-api-key'=$key; 'anthropic-version'='2023-06-01' } -TimeoutSec 60 | Out-Null }catch{} }
}catch{ Yaz "sonda hatası: $($_.Exception.Message)"; $durum='hata' }
$sure=[int]((Get-Date)-$t0).TotalSeconds
$onceki=$null; if(Test-Path $saglik){ try{ $onceki=(ConvertFrom-Json -InputObject (Get-Content $saglik -Raw)).durum }catch{} }
[IO.File]::WriteAllText($saglik,(ConvertTo-Json -InputObject @{ zaman=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); durum=$durum; sure_sn=$sure; parti=$bid; onceki=$onceki } -Compress),[Text.UTF8Encoding]::new($false))
Yaz "kuyruk: $durum ($sure sn, parti $bid)$(if($onceki -and $onceki -ne $durum){ " · DEĞİŞTİ: $onceki → $durum" })"
