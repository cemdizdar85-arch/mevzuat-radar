#requires -Version 5.1
<#
================================================================================
  SGS 650 BASIMI — onaydan gecmis sorulari Kaydir-Coz sayfasina bas (11.09.2026)
  Cem: "sade olsun eve 650 soruyu basalim"

  BEDEL 0 — hicbir model cagrilmaz. Yalnizca onbellekteki (veri/fabrika/
  kalip-parti-*.json) hazir sorular HTML'e cizilir.

  NE YAPAR
    1) veri/sinav/kaydir-secim/yayin-sgs-*.json dosyalarini birlestirir (650 soru)
    2) DERS ADINI HIZALAR - iki kusuru duzeltir:
         a) alan "Ticaret Hukuku|Ticaret ve Borclar" gibi BILESIK geliyordu
            (resmi ad | siniflandiricinin ham adi). Ekranda boru isaretiyle
            gorunuyordu; resmi ad alinir.
         b) ad ASCII idi ("Borclar", "Is ve Sosyal Guvenlik"). Cem'in 2. kurali
            geregi urun Turkce yazar: ad veri/ders-sozlugu.json'daki `ekran_ad`
            uzerinden gecirilir. Eslesme `anahtar` (katlanmis) ile yapilir.
       Olculen etki: 11 ders karti -> 9 gercek ders.
    3) birlesik secim dosyasini yazar ve motor/kaydir-yayin.ps1'i cagirir
       (ders ders sayfa + dizin sayfasi)
    4) eski uzun-adli sayfalari (borclar-hukuku-ticaret-ve-borclar.html gibi)
       ARSIVE tasir - silmez.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sgs-650-bas.ps1
================================================================================
#>
param([switch]$Kuru)   # -Kuru: yalnizca ne basilacagini yazar, dosyaya dokunmaz
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$secimDir=Join-Path $depoKok 'veri\sinav\kaydir-secim'

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}

# --- ders sozlugu: anahtar -> ekran adi ---------------------------------------
$sozluk=@{}
foreach($d in @((Get-Content (Join-Path $depoKok 'veri\ders-sozlugu.json') -Raw -Encoding UTF8 | ConvertFrom-Json).dersler)){
  if("$($d.sinav)" -notlike '*SGS*'){ continue }
  $sozluk[[string]$d.anahtar] = "$($d.ekran_ad)"
  foreach($t in @($d.takma_adlar)){ if($t -and $t.ad){ $sozluk[(Katla $t.ad)] = "$($d.ekran_ad)" } }
}

# --- 650 soruyu birlestir ------------------------------------------------------
# ⚠ PS 5.1: `ConvertFrom-Json` diziyi BORUDA tek nesne olarak verir; once
# degiskene alinmazsa @(...) diziyi tek eleman sanar (bugun bir kez dustu).
$hep=New-Object System.Collections.Generic.List[object]
foreach($f in (Get-ChildItem (Join-Path $secimDir 'yayin-sgs-*.json'))){
  $arr = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($x in @($arr)){ $hep.Add($x) }
}

$cozulmeyen=@{}
$cikti=New-Object System.Collections.Generic.List[object]
$gorulen=@{}
foreach($r in $hep){
  $anahtarSoru = "$($r.etiket)|$($r.id)"
  if($gorulen.ContainsKey($anahtarSoru)){ continue }   # ayni soru iki secim dosyasindaysa bir kez
  $gorulen[$anahtarSoru]=$true
  $ham="$($r.ders)"
  $resmi=($ham -split '\|')[0].Trim()                   # bilesik adin sol yarisi
  $ekran=$sozluk[(Katla $resmi)]
  if(-not $ekran){ $ekran=$resmi; $cozulmeyen[$resmi]=$true }
  $cikti.Add([pscustomobject]@{ etiket=$r.etiket; id=$r.id; ders=$ekran; konu=$r.konu; donem=$r.donem; kurtarma=$r.kurtarma })
}

Write-Host ("BIRLESTI: {0} kayit -> {1} benzersiz soru" -f $hep.Count, $cikti.Count) -ForegroundColor Cyan
$cikti | Group-Object ders | Sort-Object Count -Descending | ForEach-Object { Write-Host ("  {0,4}  {1}" -f $_.Count,$_.Name) }
Write-Host ("DERS SAYISI: {0}" -f (@($cikti | Group-Object ders)).Count)
if($cozulmeyen.Count){ Write-Host ("⚠ SOZLUKTE COZULEMEYEN DERS ADI: {0}" -f (($cozulmeyen.Keys) -join ' · ')) -ForegroundColor Yellow }

# --- sade nabzi: ekranda gorunecek mi ------------------------------------------
$sadeVar=0; $sadeYok=0; $onb=@{}
foreach($r in $cikti){
  if(-not $onb.ContainsKey($r.etiket)){
    $cf=Join-Path $depoKok "veri\fabrika\kalip-parti-$($r.etiket).json"
    $onb[$r.etiket] = if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
  }
  $v=$onb[$r.etiket]; if($v){ $v=$v.($r.id) }
  if($v -and $v.PSObject.Properties['sade'] -and $v.sade -and $v.sade.dogru){ $sadeVar++ } else { $sadeYok++ }
}
Write-Host ("SADE NABZI: {0}/{1} soruda Sade Dogrusu var ({2:N1}%)" -f $sadeVar,$cikti.Count,(100*$sadeVar/$cikti.Count)) -ForegroundColor Cyan
if($sadeYok){ Write-Host ("  eksik {0} soru - bu sorularda panelin 2. ve 5. parcasi bos cizilir" -f $sadeYok) -ForegroundColor Yellow }

if($Kuru){ Write-Host "`nKURU KOSU - dosyaya dokunulmadi." -ForegroundColor Yellow; return }

# --- birlesik secim dosyasi + basim -------------------------------------------
$masterAd='sgs-650-secim.json'
[IO.File]::WriteAllText((Join-Path $secimDir $masterAd),(ConvertTo-Json -InputObject @($cikti) -Depth 3),[Text.UTF8Encoding]::new($false))
Write-Host ("`nyazildi: veri/sinav/kaydir-secim/{0}" -f $masterAd)

# Eski uzun-adli sayfalar arsive (SILINMEZ - 30.08 kurali)
$arsiv=Join-Path $depoKok 'kaydir\_arsiv'
foreach($eski in @('borclar-hukuku-ticaret-ve-borclar','ticaret-hukuku-ticaret-ve-borclar','is-ve-sosyal-guvenlik-hukuku-is-ve-sosyal-guvenlik')){
  $yol=Join-Path $depoKok "kaydir\sgs\$eski.html"
  if(Test-Path $yol){
    New-Item -ItemType Directory -Force $arsiv | Out-Null
    Move-Item $yol (Join-Path $arsiv "$eski-$(Get-Date -Format yyyyMMdd-HHmm).html") -Force
    Write-Host "  arsive tasindi: $eski.html"
  }
}

Write-Host "`nBASIM BASLIYOR (bedel 0 - yalniz onbellekten cizim)..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $depoKok 'motor\kaydir-yayin.ps1') `
    -Sinav sgs -SecimDosya $masterAd -Baslik 'Staja Başlama (SGS) · Kaydır-Çöz'
