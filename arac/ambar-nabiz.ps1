#requires -Version 5.1
# ============================================================================
#  AMBAR NABZI — 15 dakikada bir ambar yoklaması + o anda kim çalışıyor   (BEDEL 0)
#
#  NEDEN (14.09.2026, Cem "gece sağlık kaydı"): 13.09 23:21–00:30 arasında ambar
#  dokumanlar tur= sorgularında 22–24 sn / 57014 verdi, bir kez 503 döndü; iki SGS
#  partisi kaynaksız basıldı. Sabah aynı sorgular 0,15–0,5 sn. Sebep anlık
#  yakalanamadı çünkü "o saatte ne koşuyordu" kaydı yoktu. Bu betik her yoklamada
#  süreyi VE o anda bu makinede koşan üretici/yutucu süreçleri VE GitHub'da süren
#  akışları tek satıra yazar; yavaşlama dönerse suçlu satırın içinde durur.
#
#  Kurulum : powershell -NoProfile -File arac/ambar-nabiz.ps1 -Kur     (görev: tetikte-ambar-nabiz, 15 dk)
#  Kaldırma: -Kaldir · Tek yoklama: parametresiz · Özet: -Rapor [-Saat 24]
#  Kayıt   : veri/fabrika/kosucu-log/ambar-nabiz.jsonl  (git'e girmez)
#  Ambara yük: yoklama başına 2 hafif GET (limit 1). Hiçbir yere yazmaz.
# ============================================================================
param([switch]$Kur,[switch]$Kaldir,[switch]$Rapor,[int]$Saat=24)
$ErrorActionPreference='Continue'
$depoKok=Split-Path -Parent $PSScriptRoot
$logDir=Join-Path $depoKok 'veri\fabrika\kosucu-log'; New-Item -ItemType Directory -Force $logDir | Out-Null
$kayit=Join-Path $logDir 'ambar-nabiz.jsonl'
$gorevAdi='tetikte-ambar-nabiz'

if($Kaldir){ Unregister-ScheduledTask -TaskName $gorevAdi -Confirm:$false -ErrorAction SilentlyContinue; 'görev kaldırıldı'; return }
if($Kur){
  $psYol=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $eylem=New-ScheduledTaskAction -Execute $psYol -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`""
  # -AtLogOn yönetici hakkı istiyor (kalip-nobetci 11.09 dersi): tek tetik, 1 dk sonra başla, 15 dk'da bir süresiz yinele
  $tetik=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
  $ayar=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -StartWhenAvailable
  Unregister-ScheduledTask -TaskName $gorevAdi -Confirm:$false -ErrorAction SilentlyContinue
  Register-ScheduledTask -TaskName $gorevAdi -Action $eylem -Trigger $tetik -Settings $ayar -Description 'Tetikte ambar nabzı: 15 dk ambar yoklaması + o anda koşan işler (arac/ambar-nabiz.ps1)' | Out-Null
  "görev kuruldu: $gorevAdi (15 dk) · kayıt $kayit"
  return
}
if($Rapor){
  if(-not (Test-Path $kayit)){ 'kayıt yok'; return }
  $sinir=(Get-Date).AddHours(-$Saat)
  $satirlar=@(Get-Content $kayit -Encoding UTF8 | ForEach-Object { try{ $_ | ConvertFrom-Json }catch{} } | Where-Object { $_ -and [datetime]::ParseExact($_.zaman,'yyyy-MM-dd HH:mm:ss',$null) -ge $sinir })
  $yavas=@($satirlar | Where-Object { $_.cikmis_sn -lt 0 -or $_.cikmis_sn -ge 5 })
  "son $Saat saat: $($satirlar.Count) yoklama · yavaş/yanıtsız $($yavas.Count)"
  foreach($s in $yavas){ "  {0} · çıkmış {1} sn · küçük {2} sn · yerel: {3} · github: {4}" -f $s.zaman,$s.cikmis_sn,$s.kucuk_sn,(@($s.yerel) -join '; '),(@($s.github) -join '; ') }
  return
}

# --- tek yoklama ---
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$KEY="$($env:SUPABASE_SERVICE_KEY)".Trim(); if(-not $KEY){ $KEY="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
$H=@{ apikey=$KEY; Authorization="Bearer $KEY"; Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$B='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/'
function Yokla([string]$yol){
  $sw=[Diagnostics.Stopwatch]::StartNew()
  try{ [void](Invoke-WebRequest -UseBasicParsing -Uri ($B+$yol) -Headers $H -TimeoutSec 30); return [math]::Round($sw.Elapsed.TotalSeconds,2) }
  catch{ $kod=''; try{ $kod=[int]$_.Exception.Response.StatusCode }catch{}; return [pscustomobject]@{ sn=-1; kod="$kod" } }
}
$c=Yokla 'dokumanlar?select=id&tur=eq.cikmis-soru&limit=1'
$k=Yokla 'kalip_parti?select=etiket&limit=1&order=etiket.asc'
# bu makinede ambara dokunabilecek süreçler (yalnız özet: betik adı + etiket/sınav)
$yerel=@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' or Name='pwsh.exe' or Name='node.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'kalip-parti-uret|parti-senkron|yut|rag-motor|marka|ihale|dayanak|havuz-kur' } | ForEach-Object {
  $cl="$($_.CommandLine)"; $b=([regex]::Match($cl,'[\w\-]+\.(ps1|js)')).Value; $et=([regex]::Match($cl,'-(Etiket|Sinav)\s+[''"]?([\w\-]+)')).Groups[2].Value
  "$b $et".Trim() })
# GitHub'da süren akışlar (gh yoksa ya da giriş yoksa boş kalır, yoklama yine yazılır)
$github=@()
$ghYol='C:\Program Files\GitHub CLI\gh.exe'
if(Test-Path $ghYol){ try{ Push-Location $depoKok; $ham=(& $ghYol run list --status in_progress --limit 20 --json workflowName 2>$null) -join ''; Pop-Location; if($ham){ $github=@(($ham | ConvertFrom-Json) | ForEach-Object { "$($_.workflowName)" }) } }catch{ try{ Pop-Location }catch{} } }
$satir=[ordered]@{
  zaman=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  cikmis_sn=$(if($c -is [pscustomobject]){ -1 }else{ $c }); cikmis_kod=$(if($c -is [pscustomobject]){ $c.kod }else{ '200' })
  kucuk_sn=$(if($k -is [pscustomobject]){ -1 }else{ $k }); kucuk_kod=$(if($k -is [pscustomobject]){ $k.kod }else{ '200' })
  yerel=$yerel; github=$github
}
[IO.File]::AppendAllText($kayit, ((ConvertTo-Json -InputObject $satir -Compress -Depth 4) + "`r`n"), [Text.UTF8Encoding]::new($false))
"nabız: çıkmış $($satir.cikmis_sn) sn · küçük $($satir.kucuk_sn) sn · yerel $($yerel.Count) · github $($github.Count)"
