# KALIP GECE KOŞUCUSU — GENEL (08.09, B kovası 12; 07.09 kalip-parti-30.ps1'in genelleştirilmiş hâli)
# Plan dosyasından (json dizi) ders ders ardışık koşar; her satır: { "ders":"regex", "etiket":"sgs-fmuh-p31", "adet":6, "tavan":350, "zorluk":"zor|kolay|karisik",
#   "sinav":"SGS", "disla":"regex", "konuDosya":"", "eskiKaynak":"" }  — eskiKaynak doluysa KURTARMA (FAZ U) koşar, yeni soru üretilmez.
# Her ders için: tam hat (soru/uyarlama + adımlar + verilenler + giriş + ikiz + sim Sonnet + hakem + kör çözüm + hakem2), sonra seçim
# (hakem EVET ∧ sim ✓ ∧ kör ✓ ∧ hakem2 EVET — SORU-BASMA-KURALLARI 8.1), Kaydır-Çöz sayfası ve karne. Loglar veri/fabrika/kosucu-log/<plan>/.
# Kullanım: powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-sgs-08-09.json
param([Parameter(Mandatory=$true)][string]$Plan,[string]$Kok=(Split-Path $PSScriptRoot -Parent),[switch]$SayfaYok)
$ErrorActionPreference='Continue'
$uret=Join-Path $PSScriptRoot 'kalip-parti-uret.ps1'
$planYol=$(if(Test-Path $Plan){ $Plan } else { Join-Path $Kok $Plan }); if(-not (Test-Path $planYol)){ throw "plan yok: $planYol" }
$planAd=[IO.Path]::GetFileNameWithoutExtension($planYol)
$satirlar=@(ConvertFrom-Json -InputObject (Get-Content $planYol -Raw -Encoding UTF8)); if($satirlar.Count -eq 1 -and $satirlar[0].PSObject.Properties['SyncRoot']){ $satirlar=@($satirlar[0].SyncRoot) }
$logDir=Join-Path $Kok "veri\fabrika\kosucu-log\$planAd"; New-Item -ItemType Directory -Force $logDir | Out-Null
$t0=Get-Date; $ozetTum=@()
foreach($s in $satirlar){
  $sinav=$(if($s.PSObject.Properties['sinav'] -and $s.sinav){ "$($s.sinav)" } else { 'SGS' })
  $log=Join-Path $logDir ("$($s.etiket).log")
  $arg=@('-Sinav',$sinav,'-DersRegex',"$($s.ders)",'-Adet',"$([int]$s.adet)",'-Etiket',"$($s.etiket)",'-UzunlukTavan',"$(if($s.PSObject.Properties['tavan'] -and $s.tavan){ [int]$s.tavan } else { 350 })",'-Verilenler','-KonuGiris','-Simulasyon','-SimModel','claude-sonnet-5')
  if($s.PSObject.Properties['eskiKaynak'] -and "$($s.eskiKaynak)"){ $arg+=@('-EskiKaynak',"$($s.eskiKaynak)",'-DonemPencere','0') }
  else { $arg+=@('-DonemPencere','7'); if($s.PSObject.Properties['zorluk'] -and "$($s.zorluk)" -eq 'zor'){ $arg+=@('-Zorluk','zor') }; if($s.PSObject.Properties['disla'] -and "$($s.disla)"){ $arg+=@('-KonuDisla',"$($s.disla)") }; if($s.PSObject.Properties['konuDosya'] -and "$($s.konuDosya)"){ $arg+=@('-KonuDosya',"$($s.konuDosya)") } }
  "[$(Get-Date -Format HH:mm)] BASLIYOR $($s.etiket) · $($s.ders) · adet $($s.adet)$(if($s.PSObject.Properties['eskiKaynak'] -and $s.eskiKaynak){ ' · KURTARMA' })"
  & powershell -NoProfile -File $uret @arg *> $log
  $oz=Select-String -Path $log -Pattern 'KONU LİSTESİ|konu tekil|SORU DÜŞTÜ|KURTARMA DÜŞTÜ|UYARLAMA OK|HAKEM (EVET|HAYIR)|HAKEM2 (EVET|HAYIR)|KÖR ÇÖZÜM|SIM (DO|YAN|yetmedi)|KAYNAK BORCU|BEDEL TOPLAM|yazildi' | ForEach-Object { $_.Line }
  "[$(Get-Date -Format HH:mm)] BITTI $($s.etiket)"; $oz
  $ozetTum+=[pscustomobject]@{ etiket="$($s.etiket)"; ders="$($s.ders)"; bedel=(($oz | Where-Object { $_ -match 'BEDEL TOPLAM' } | Select-Object -Last 1) -replace '.*≈','' -replace ' USD.*','') }
}
# seçim (8.1 yayın şartı)
$secim=@()
foreach($s in $satirlar){
  $cf=Join-Path $Kok "veri\fabrika\kalip-parti-$($s.etiket).json"; if(-not (Test-Path $cf)){ continue }
  $c=ConvertFrom-Json -InputObject (Get-Content $cf -Raw -Encoding UTF8)
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v.soru){ continue }
    if("$($v.hakem.karar)" -ne 'EVET'){ continue }
    $simOk=$true; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    if(-not ($v.PSObject.Properties['kor_cozum'] -and $v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $secim+=[pscustomobject]@{ etiket="$($s.etiket)"; id=$p.Name; ders="$(if($v.PSObject.Properties['ders'] -and $v.ders){ $v.ders } else { $s.ders })"; konu="$($v.konu)"; donem=[int]$v.donem; kurtarma=[bool]($v.PSObject.Properties['kurtarma'] -and $v.kurtarma) }
  }
}
$secYol=Join-Path $Kok "veri\sinav\kaydir-secim\$planAd-secim.json"
[IO.File]::WriteAllText($secYol,(ConvertTo-Json -InputObject @($secim) -Depth 3),[Text.UTF8Encoding]::new($false))
"SECIM: $($secim.Count) soru (yayın şartı: hakem ∧ sim ∧ kör ∧ hakem2) -> $secYol"
if(-not $SayfaYok -and $secim.Count){
  & powershell -NoProfile -File (Join-Path $PSScriptRoot 'kaydir-coz.ps1') -SecimDosya "$planAd-secim.json" -Cikti "KAYDIR-COZ-$planAd.html" *> (Join-Path $logDir 'builder.log')
  Get-Content (Join-Path $logDir 'builder.log') | Select-String -Pattern 'yazildi|ÖZ-SINAV|Exception|Cannot' | ForEach-Object { $_.Line }
}
$etk=($satirlar | ForEach-Object { $_.etiket }) -join ','
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'soru-karnesi.ps1') -Etiketler $etk -Cikti "KARNE-$planAd.html" *> (Join-Path $logDir 'karne.log')
Get-Content (Join-Path $logDir 'karne.log') | Select-String -Pattern 'ZORLUK|KARNE:' | ForEach-Object { $_.Line }
"BEDEL (ders ders, ≈USD): $(($ozetTum | ForEach-Object { "$($_.etiket)=$($_.bedel)" }) -join ' · ')"
"[$(Get-Date -Format HH:mm)] TAMAM · sure $([int]((Get-Date)-$t0).TotalMinutes) dk"
