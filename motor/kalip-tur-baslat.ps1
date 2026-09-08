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
  # 08.09 dersi: Start-Process argümanında boşluklu yol tırnaklanır; -File ile çağrılan betikte $PSScriptRoot boş gelebilir (koşucu $buDizin ile kök hesaplar)
  $arg="-NoProfile -ExecutionPolicy Bypass -Command `"& '$kosucu' -Plan '$plan' -SayfaYok *> '$log'`""
  $p=Start-Process -FilePath 'powershell' -ArgumentList $arg -WindowStyle Hidden -PassThru
  $basladi+=[pscustomobject]@{ parca=$i; pid=$p.Id; satir=$n; soru=$soru; log=$log }
  "[$(Get-Date -Format HH:mm)] BAŞLADI parça $i · pid $($p.Id) · $n satır · $soru soru · log $log"
  Start-Sleep -Seconds 20   # koşucular aynı anda bedel defterini/bekleyen-partiler dosyasını okuyup yazmasın; ilk toplu partiler kademeli gitsin
}
if($basladi.Count -and -not $Kontrol){ $basladi=@($basladi | Sort-Object { [int]$_.parca }); [IO.File]::WriteAllText($listeYol,(ConvertTo-Json -InputObject @($basladi) -Depth 3),[Text.UTF8Encoding]::new($false)); "süreç listesi: $listeYol" }
