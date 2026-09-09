# KALIP KOŞUCU NÖBETÇİSİ (09.09.2026, KAZA 5–7 dersi): koşucular üç kez toptan öldü (23:00 kabuk yeniden başlaması, 02:47 Windows Update
# yeniden başlatması, 10:46 nedeni bilinmeyen konsol kapanışı 0xC000013A). Bu betik Görev Zamanlayıcı'da 5 dakikada bir koşar:
# plan-<ad>-pN.json için görev tanımlıysa, koşucu logu TAMAM ile bitmemişse ve görev çalışmıyorsa görevi yeniden başlatır.
# Koşucu önbellekten sürer, bitmiş etiketler damgadan ATLANIR; yeniden başlatma bedelsizdir.
# Kurulum: powershell -NoProfile -File motor/kalip-nobetci.ps1 -Kur      (görev: tetikte-hat-nobetci, 5 dk)
# Kaldırma: -Kaldir · Tek koşu: parametresiz · Günlük: veri/fabrika/kosucu-log/nobetci.log
param([switch]$Kur,[switch]$Kaldir)
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok=Split-Path $buDizin -Parent
$logDir=Join-Path $kok 'veri\fabrika\kosucu-log'
$nlog=Join-Path $logDir 'nobetci.log'
function Yaz([string]$s){ $satir="[$(Get-Date -Format 'dd.MM HH:mm:ss')] $s"; $satir; try{ [IO.File]::AppendAllText($nlog,"$satir`r`n",[Text.UTF8Encoding]::new($false)) }catch{} }
if($Kaldir){ Unregister-ScheduledTask -TaskName 'tetikte-hat-nobetci' -Confirm:$false -ErrorAction SilentlyContinue; Yaz 'nöbetçi görevi kaldırıldı'; return }
if($Kur){
  $sarmalDir=$(if(Test-Path 'C:\TETIKTE-YEDEK'){ 'C:\TETIKTE-YEDEK\hat' } else { Join-Path $env:USERPROFILE 'tetikte-hat' }); New-Item -ItemType Directory -Force $sarmalDir | Out-Null
  $sarmal=Join-Path $sarmalDir 'nobetci.ps1'
  [IO.File]::WriteAllText($sarmal,"& '$($MyInvocation.MyCommand.Path)' *>> '$($nlog -replace '\.log$','-kosu.log')'`r`n",[Text.UTF8Encoding]::new($true))
  Unregister-ScheduledTask -TaskName 'tetikte-hat-nobetci' -Confirm:$false -ErrorAction SilentlyContinue
  $psYol=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $eylem=New-ScheduledTaskAction -Execute $psYol -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$sarmal`""
  $tetik=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
  # -AtLogOn tetikleyicisi yönetici hakkı istiyor ("Erişim engellendi", 11:07); tek tetik: 1 dk sonra başla, 5 dk'da bir yinele (süresiz).
  $ayar=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -MultipleInstances IgnoreNew -StartWhenAvailable
  Register-ScheduledTask -TaskName 'tetikte-hat-nobetci' -Action $eylem -Trigger $tetik -Settings $ayar -Description 'Tetikte kalıp koşucu nöbetçisi: ölen hatları 5 dk içinde yeniden başlatır (motor/kalip-nobetci.ps1)' | Out-Null
  Yaz "nöbetçi görevi kuruldu (5 dk'da bir); sarmal $sarmal"
  return
}
# --- tek koşu: ölü hatları bul ve başlat ---
$gorevler=@(Get-ScheduledTask -TaskName 'tetikte-hat-sgs-*' -ErrorAction SilentlyContinue)
if(-not $gorevler.Count){ return }
$basladi=0
foreach($g in $gorevler){
  $ad=$g.TaskName -replace '^tetikte-hat-',''      # sgs-t1-p2, sgs-t2-p4 ...
  if($g.State -eq 'Running'){ continue }
  $log=Join-Path $logDir "$ad.log"
  if(-not (Test-Path $log)){ continue }
  # koşucu logunun son anlamlı satırı TAMAM ise plan bitmiştir; değilse hat yarım kalmıştır
  $son=@(Get-Content $log -Encoding Unicode -Tail 3 | Where-Object { "$_".Trim() }) | Select-Object -Last 1
  if("$son" -match '\bTAMAM\b'){ continue }
  # plan dosyası var mı (kalıntı görev olmasın)
  $plan=Join-Path $kok "veri\sinav\plan-$ad.json"; if(-not (Test-Path $plan)){ continue }
  # aynı hattın koşucusu başka yoldan canlıysa (eski başlatma) dokunma
  $canli=@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*\hat\$ad.ps1*" })
  if($canli.Count){ continue }
  try{ Start-ScheduledTask -TaskName $g.TaskName; $basladi++; Yaz "YENİDEN BAŞLATILDI: $ad (görev $($g.State) idi; son satır: $("$son".Trim().Substring(0,[Math]::Min(70,"$son".Trim().Length))))" }catch{ Yaz "BAŞLATILAMADI: $ad · $($_.Exception.Message)" }
  Start-Sleep -Seconds 8
}
if($basladi){ Yaz "toplam $basladi hat yeniden başlatıldı" }
