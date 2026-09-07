# KALIP PARTI KOSUCUSU - 30 soru, 8 ders, ardisik (07.09.2026 gece, Cem "30 soru bas, kontrol edeyim, son okey")
# Her ders icin kalip-parti-uret.ps1 tam hatla kosar (soru + adim + verilenler + giris + ikiz + sim Sonnet + hakem, butun kapilar),
# bugun basilan konular dislanir, sonra hakem EVET ve sim dogru olanlardan secim dosyasi yazilir, sayfa ve karne basilir.
# Ardisik kosu: API tavanina carpmamak icin. Loglar veri/fabrika/parti30-log/ altinda.
param([string]$Kok=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Continue'
$uret=Join-Path $PSScriptRoot 'kalip-parti-uret.ps1'
# bugun (07.09) basilan / referans konular: tekrar uretilmez
$disla='deger dusuklugu|ortak maliyet|denetim kaniti yeterlil|dikey yuzde|genel islem kosul|toplu is sozlesme|disiplin ceza|duran varlik|muhasebe bilgi sistemi|vergiyi doguran|kurumlar vergisi mukellef'
$dersler=@(
  @{ regex='Finansal Muhasebe';            etiket='sgs-fmuh-p30';    adet=6; tavan=350 },
  @{ regex='Maliyet Muhasebesi';           etiket='sgs-maliyet-p30'; adet=5; tavan=600 },
  @{ regex='Mali Tablolar Analizi';        etiket='sgs-mta-p30';     adet=3; tavan=350 },
  @{ regex='Denetim';                      etiket='sgs-denetim-p30'; adet=4; tavan=350 },
  @{ regex='Vergi Hukuku';                 etiket='sgs-vergi-p30';   adet=4; tavan=350 },
  @{ regex='Ticaret Hukuku';               etiket='sgs-ticaret-p30'; adet=3; tavan=350 },
  @{ regex='Is ve Sosyal Guvenlik Hukuku'; etiket='sgs-issgk-p30';   adet=3; tavan=350 },
  @{ regex='Meslek Hukuku';                etiket='sgs-meslek-p30';  adet=2; tavan=350 }
)
$logDir=Join-Path $Kok 'veri\fabrika\parti30-log'; New-Item -ItemType Directory -Force $logDir | Out-Null
$t0=Get-Date
foreach($d in $dersler){
  $log=Join-Path $logDir ($d.etiket+'.log')
  "[$(Get-Date -Format HH:mm)] BASLIYOR $($d.etiket) · adet $($d.adet)"
  & powershell -NoProfile -File $uret -Sinav SGS -DersRegex $d.regex -Adet $d.adet -Etiket $d.etiket -KonuDisla $disla -DonemPencere 7 -Zorluk zor -UzunlukTavan $d.tavan -Verilenler -KonuGiris -Simulasyon -SimModel claude-sonnet-5 *> $log
  $ozet=Select-String -Path $log -Pattern 'pencere: kp|HAKEM (EVET|HAYIR)|SIM (DO|YAN|yetmedi)|DUSTU|DÜŞTÜ|BOZUK:|KAYNAK BORCU|yazildi' | ForEach-Object { $_.Line }
  "[$(Get-Date -Format HH:mm)] BITTI $($d.etiket)"; $ozet
}
# secim: hakem EVET ve simulasyon yanlis olmayan sorular
$secim=@()
foreach($d in $dersler){
  $cf=Join-Path $Kok "veri\fabrika\kalip-parti-$($d.etiket).json"; if(-not (Test-Path $cf)){ continue }
  $c=Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v.soru){ continue }
    if("$($v.hakem.karar)" -ne 'EVET'){ continue }
    $simOk=$true; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    # 07.09 A kovası (SORU-BASMA-KURALLARI 8.1): yayın şartı = hakem ∧ sim ∧ KÖR ÇÖZÜM ✓ ∧ İKİNCİ HAKEM EVET; ikisi de yoksa ya da düşükse seçilmez
    if(-not ($v.PSObject.Properties['kor_cozum'] -and $v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $secim+=[pscustomobject]@{ etiket=$d.etiket; id=$p.Name; ders=$d.regex; konu="$($v.konu)"; donem=[int]$v.donem }
  }
}
$secYol=Join-Path $Kok 'veri\sinav\kaydir-secim\parti30-secim.json'
[IO.File]::WriteAllText($secYol,(ConvertTo-Json -InputObject $secim -Depth 3),[Text.UTF8Encoding]::new($false))
"SECIM: $($secim.Count) soru -> $secYol"
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'kaydir-coz.ps1') -SecimDosya parti30-secim.json -Cikti KAYDIR-COZ-30.html *> (Join-Path $logDir 'builder.log')
Get-Content (Join-Path $logDir 'builder.log') | Select-String -Pattern 'yazildi|Exception|Cannot' | ForEach-Object { $_.Line }
$etk=($dersler | ForEach-Object { $_.etiket }) -join ','
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'soru-karnesi.ps1') -Etiketler $etk -Cikti KARNE-30.html *> (Join-Path $logDir 'karne.log')
Get-Content (Join-Path $logDir 'karne.log') | Select-Object -Last 10
"[$(Get-Date -Format HH:mm)] TAMAM · sure $([int]((Get-Date)-$t0).TotalMinutes) dk"
