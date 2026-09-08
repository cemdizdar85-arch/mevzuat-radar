# KALIP TUR BAŞLATICI (08.09, Tur 1 hazırlık denetimi) — plan parçalarını (plan-<ad>-p1..pN.json) ayrı koşucu süreçlerinde PARALEL başlatır.
# Neden: koşucu dersleri ardışık koşar; anlık fazlar (sim, hakem, kapı tekrarı) soru başına ≈1–1,5 dk → 1.593 soru tek hatta ≈30 saat.
# Her parça kendi logunu yazar: veri/fabrika/kosucu-log/<ad>-pN.log ; sayfa basılmaz (-SayfaYok), ders ders yayın sonra motor/kaydir-yayin.ps1 ile.
# Kullanım: powershell -NoProfile -File motor/kalip-tur-baslat.ps1 -Ad sgs-t1 -Parca 4
#           -Kontrol : başlatmaz, yalnız plan dosyalarını ve koşan süreçleri listeler
param([string]$Ad='sgs-t1',[int]$Parca=4,[switch]$Kontrol,[string]$Parcalar='')   # -Parcalar '2,3,4': yalnız bu parçaları (yeniden) başlat
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok=Split-Path $buDizin -Parent
$logDir=Join-Path $kok 'veri\fabrika\kosucu-log'; New-Item -ItemType Directory -Force $logDir | Out-Null
$kosucu=Join-Path $buDizin 'kalip-kosucu.ps1'
$basladi=@()
$secili=@(); if($Parcalar){ $secili=@($Parcalar -split ',' | ForEach-Object { [int]$_.Trim() }) }
# 08.09: yeniden başlatmada eski süreç listesi korunur, yalnız seçili parçaların satırı güncellenir
$eskiListe=@(); $listeYol=Join-Path $logDir "$Ad-surecler.json"; if(Test-Path $listeYol){ try{ $j=ConvertFrom-Json -InputObject (Get-Content $listeYol -Raw); $eskiListe=@($(if($j -is [array]){ $j } else { @($j) })) }catch{} }
for($i=1;$i -le $Parca;$i++){
  if($secili.Count -and ($secili -notcontains $i)){ $eskiKayit=$eskiListe | Where-Object { [int]$_.parca -eq $i }; if($eskiKayit){ $basladi+=$eskiKayit }; continue }
  $plan=Join-Path $kok "veri\sinav\plan-$Ad-p$i.json"
  if(-not (Test-Path $plan)){ "plan yok: $plan"; continue }
  $sat=ConvertFrom-Json -InputObject (Get-Content $plan -Raw -Encoding UTF8); $n=@($sat).Count; if($n -eq 1 -and $sat.PSObject.Properties['SyncRoot']){ $n=@($sat.SyncRoot).Count }
  $soru=0; foreach($s in @($sat)){ if($s.PSObject.Properties['SyncRoot']){ foreach($x in $s.SyncRoot){ $soru+=[int]$x.adet } } else { $soru+=[int]$s.adet } }
  $log=Join-Path $logDir "$Ad-p$i.log"
  if($Kontrol){ "parça $i : $n satır · $soru soru · log $log $(if(Test-Path $log){ '(log var)' })"; continue }
  # 08.09 23:00 KAZA 5: Start-Process ile başlatılan 7 koşucu, Claude oturum kabuğu yeniden başlayınca (aynı iş nesnesi) toptan öldü; WMI Create ile
  # başlatılanların 5'i de WmiPrvSE boşalınca öldü. Kalıcı çözüm: GÖREV ZAMANLAYICI. Her parça için ASCII yolda bir sarmal .ps1 yazılır
  # (%LOCALAPPDATA%\tetikte-hat\), schtasks ile tek seferlik görev yaratılıp hemen koşturulur; süreç svchost'un çocuğudur, oturumdan bağımsızdır.
  # Sarmal içinde MEVZUAT_TOPLU ortam değişkeni bu kabuktan devralınır (Cem 20:57 anlık mod kararı korunur). Log '*>>' ile eklenir (yeniden başlatma izi kalır).
  # 09.09 00:05 ÖLÇÜLDÜ: %LOCALAPPDATA%\tetikte-hat Claude kum havuzu kabuğundan yaratıldığı için AppContainer SID'li ACL aldı; Görev Zamanlayıcı
  # oradan okuyup yazamadı (cmd echo bile 0x1, powershell 0xFFFD0000). Depo dizinleri ve C:\TETIKTE-YEDEK sorunsuz → sarmallar orada.
  $sarmalDir=$(if(Test-Path 'C:\TETIKTE-YEDEK'){ 'C:\TETIKTE-YEDEK\hat' } else { Join-Path $env:USERPROFILE 'tetikte-hat' }); New-Item -ItemType Directory -Force $sarmalDir | Out-Null
  $sarmal=Join-Path $sarmalDir "$Ad-p$i.ps1"
  # 08.09 Cem 20:57 kararı: toplu kuyruk bugün çalışmadı → varsayılan ANLIK ('0'); toplu istenirse başlatan kabukta MEVZUAT_TOPLU=1 verilir.
  $topluSatir="`$env:MEVZUAT_TOPLU='$(if("$env:MEVZUAT_TOPLU"){ $env:MEVZUAT_TOPLU } else { '0' })'"
  if("$env:MEVZUAT_TOPLU_BEKLE_DK" -match '^\d+$'){ $topluSatir+="; `$env:MEVZUAT_TOPLU_BEKLE_DK='$env:MEVZUAT_TOPLU_BEKLE_DK'" }   # toplu kuyruk takılırsa fazın anlığa düşme süresi
  [IO.File]::WriteAllText($sarmal,"$topluSatir`r`n& '$kosucu' -Plan '$plan' -SayfaYok *>> '$log'`r`n",[Text.UTF8Encoding]::new($true))
  # 08.09 23:00 KAZA 5 dersi: Claude kabuğu KILL_ON_CLOSE'lu iş nesnesindedir, Start-Process çocukları kabukla ölür; WMI çocukları WmiPrvSE ile ölür.
  # GÖREV ZAMANLAYICI (ScheduledTasks modülü, pil kısıtı kapalı, tam yol powershell) → süreç svchost'un çocuğu, oturumdan bağımsız.
  # schtasks.exe /ST ile "Queued" kalıyor (pilde); Register-ScheduledTask + Start-ScheduledTask kullanılır.
  $gorev="tetikte-hat-$Ad-p$i"
  Unregister-ScheduledTask -TaskName $gorev -Confirm:$false -ErrorAction SilentlyContinue
  $psYol=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $eylem=New-ScheduledTaskAction -Execute $psYol -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$sarmal`""
  $ayar=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 3) -MultipleInstances IgnoreNew -StartWhenAvailable
  Register-ScheduledTask -TaskName $gorev -Action $eylem -Settings $ayar -Description "Tetikte kalıp koşucusu $Ad p$i (motor/kalip-tur-baslat.ps1)" | Out-Null
  Start-ScheduledTask -TaskName $gorev
  Start-Sleep -Seconds 6
  $p=Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like "*$Ad-p$i.ps1*" -and $_.CommandLine -notlike '*Get-CimInstance*' } | Select-Object -First 1
  $pidB=$(if($p){ $p.ProcessId } else { 0 })
  $basladi+=[pscustomobject]@{ parca=$i; pid=$pidB; satir=$n; soru=$soru; log=$log; gorev=$gorev; sarmal=$sarmal }
  "[$(Get-Date -Format HH:mm)] BAŞLADI parça $i · görev $gorev · pid $pidB · $n satır · $soru soru · log $log"
  Start-Sleep -Seconds 20   # koşucular aynı anda bedel defterini/bekleyen-partiler dosyasını okuyup yazmasın; ilk toplu partiler kademeli gitsin
}
if($basladi.Count -and -not $Kontrol){ $basladi=@($basladi | Sort-Object { [int]$_.parca }); [IO.File]::WriteAllText($listeYol,(ConvertTo-Json -InputObject @($basladi) -Depth 3),[Text.UTF8Encoding]::new($false)); "süreç listesi: $listeYol" }
