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
. (Join-Path $here 'kimlik-ayikla.ps1')   # 11.09: kimlik ayiklama TEK kaynaktan
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

# --- HAKEM2 KAPISI ------------------------------------------------------------
# 11.09.2026: sade turu sirasinda 2 soru IKINCI HAKEMDEN HAYIR aldi
# (sgs-issgk-p30/kp-03, sgs-ticaret-p30/kp-03). Bunlar secim dosyalarina
# girdiginde hakem2 HENUZ KOSMAMISTI; tamamlama turunda kostu ve reddetti
# (ornek gerekce: "ABC A.S. yer tutucu unvan"). Secim dosyasinda olmalari
# onayli olduklari anlamina gelmez - kapiyi SONRADAN gectiler ve dustuler.
# Cem'in kurali: kaliteden odun yok. Cozme yuzeyine cikmazlar.
#
# 11.09 EK KAPI — Cem "hakem olmadan soru basmiyorduk niye bastik":
# Hakem DORT hukum verir. Ilk basimda yalnizca hakem2'ye baktim; hakemin
# `konu_uyum` / `ders_uyum` / `tek_anlam` damgalarini SORMADIM. Olculdu:
# basilan 648 sorunun 12'sinde konu_uyum=KONU-DISI ve hakem gerekcesini de
# yazmis (ornek kp-72: "soru ... Vergi Usul Kanunu fatura nizami kurallarini
# olcmektedir"). Kok neden motor/kalip-kosucu.ps1'de (secim kapisi) duzeltildi;
# burasi ikinci savunma hatti - secim dosyasi nereden gelirse gelsin elenir.
# Hesap kalibi bir kez okunur; anahtar katlanmis "ders|konu".
$script:HK=$null
function HesapKalibiAl([string]$ders,[string]$konu){
  if($null -eq $script:HK){
    $script:HK=@{}
    $hy=Join-Path $depoKok 'veri\hesap-kalibi.json'
    if(Test-Path $hy){
      try{
        $hj=Get-Content $hy -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($s in @($hj.satirlar)){ $script:HK[(Katla "$($s.ders)|$($s.konu)")]=$s }
      }catch{}
    }
  }
  $a=Katla "$ders|$konu"
  if($script:HK.ContainsKey($a)){ return $script:HK[$a] }
  return $null
}

$onbGate=@{}
function Kayit([string]$etiket,[string]$id){
  if(-not $onbGate.ContainsKey($etiket)){
    $cf=Join-Path $depoKok "veri\fabrika\kalip-parti-$etiket.json"
    $onbGate[$etiket] = if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
  }
  $v=$onbGate[$etiket]; if(-not $v){ return $null }
  return $v.$id
}
# Soruyu dusuren SEBEBI dondurur; gecerse bos string.
function DusmeSebebi([string]$etiket,[string]$id){
  $v = Kayit $etiket $id
  if(-not $v){ return 'kayit yok' }
  # 11.09: en temel kontrol EKSIKTI - hakem.karar. kp-80 KAPI-HG ile HAYIR'a
  # donunce fark edildi: basim betigi hakem2'ye bakiyordu ama BIRINCI hakemin
  # kararina bakmiyordu. Secim dosyasi onu eledigi icin sorun cikmamisti;
  # yine de ikinci savunma hatti bunu KENDI sormalidir.
  # --- KAPI-HS: HESAP SETI (11.09, Cem "basmadan otomatik engelleyecek") ------
  # Dogru sikkin kullandigi HER hesap, konunun ONAYLI hesap kumesinde olmali.
  # Beyaz liste; kara liste degil. Olculdu: kp-80'de 529 tuzak listesinde yoktu
  # ve kara liste YAKALAMAZDI; beyaz liste yakaliyor (529, onayli kume
  # {242,245,521,501} icinde degil).
  # ⛔ YALNIZ MUHURLU KALIPTA DUSURUR (dogrulandi=true). Kalip su an model
  #    taslagidir ve gurultu tasidigi olculdu; muhursuz listeye karsi sert kapi
  #    DOGRU sorulari yayindan silerdi. Kapiyi acan sey Cem'in muhrudur.
  if("$($v.hakem.karar)" -eq 'HAYIR'){ return 'hakem HAYIR' }
  # --- KAPI-KH: kodsuz hesap adi (11.09) -------------------------------------
  # Sik hesabi ADIYLA aniyor ama KODUNU yazmiyorsa hicbir hesap kapisi onu
  # dogrulayamaz - denetimsiz yayina cikar. Olculdu: 635 soruda 3 vaka, yanlis
  # pozitif yok. Kural 9.3 geregi sorular ELLE duzeltilmedi; kapi kuruldu ve
  # sorular havuzdan kendiliginden dusuyor. Yeniden uretim Cem'in karari.
  $khB=@(Get-KodsuzHesapAdi "$($v.siklar.$($v.dogru))")
  if($khB.Count){ return ("KAPI-KH kodsuz hesap adi: " + ($khB -join ', ')) }
  $hsK = HesapKalibiAl "$($v.ders)" "$($v.konu)"
  if($hsK -and [bool]$hsK.dogrulandi){
    $onayli=@(@($hsK.dogru_hesaplar) | ForEach-Object { "$_" })
    if($onayli.Count){
      $mS="$($v.siklar.$($v.dogru))"
      $kul=@(Get-HesapKodu $mS)   # 11.09: TEK kaynak (arac/kimlik-ayikla.ps1)
      $dis=@($kul | Where-Object { $onayli -notcontains $_ })
      if($dis.Count){ return ("KAPI-HS onayli hesap kumesi disi: " + ($dis -join ',')) }
    }
  }
  if("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ return 'hakem HESAP-YANLIS' }
  if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2)){ return 'hakem2 YOK' }
  if("$($v.hakem2.karar)" -eq 'HAYIR'){ return 'hakem2 HAYIR' }
  if("$($v.hakem.ders_uyum)"  -eq 'DERS-DISI'){  return 'hakem DERS-DISI' }
  if("$($v.hakem.konu_uyum)"  -eq 'KONU-DISI'){  return 'hakem KONU-DISI' }
  if("$($v.hakem.tek_anlam)"  -eq 'CIFT-ANLAM'){ return 'hakem CIFT-ANLAM' }
  return ''
}

# --- KAPI-IK: IKIZ SORU (11.09.2026, Cem "ikiz kapisini yayin secimine bagla")
# arac/ikiz-soru.ps1 ayni konudan uretilmis sorulari kiyaslar; SORU METNI VE
# DOGRU SIK METNI birlikte esigi asan ciftte biri yayin disi kalir.
# ⚠ IKI OLCUT SART: tek olcutle (yalniz soru metni) 14 "canli ikiz" bildirilmis,
#   elle bakinca 3'u gercek cikmisti. Digerleri ayni konudan FARKLI soru -
#   4 turlu uretimden zaten istedigimiz sey.
# ⚠ Liste BAYATSA kullanilmaz: ikiz raporu, en yeni parti dosyasindan eskiyse
#   uyari basilir ve kapi ATLANIR (yanlis soruyu yayindan dusurmektense
#   kapiyi kapatmak evladir; rapor tazelenip yeniden kosulur).
$ikizDisi=@{}
$ikizYol=Join-Path $depoKok 'veri\ikiz-soru.json'
if(Test-Path $ikizYol){
  # ⚠ BAYATLIK OLCUTU DAR TUTULUR. Ilk surum "fabrikadaki EN YENI parti"ye
  #   bakiyordu; uretim kosarken her yeni parti raporu bayatlatiyor ve kapi
  #   surekli atlaniyordu (11.09 18:38'de yasandi: rapor 2 dakika eskiydi).
  #   Dogru olcut: YALNIZ HAVUZU BESLEYEN partiler. Baska bir hat yeni soru
  #   uretiyorsa bu havuzun ikiz durumu degismez.
  $besleyen=@{}
  foreach($r0 in $hep){ $besleyen["$($r0.etiket)"]=$true }
  $enYeniParti=[datetime]'2000-01-01'
  foreach($et0 in $besleyen.Keys){
    $pf=Join-Path $depoKok "veri\fabrika\kalip-parti-$et0.json"
    if(Test-Path $pf){ $lw=(Get-Item $pf).LastWriteTime; if($lw -gt $enYeniParti){ $enYeniParti=$lw } }
  }
  $ikizZaman=(Get-Item $ikizYol).LastWriteTime
  if($enYeniParti -gt $ikizZaman){
    Write-Host ("⚠ KAPI-IK ATLANDI: ikiz raporu bayat ({0:dd.MM HH:mm}), havuzu besleyen partide daha yeni degisiklik var ({1:dd.MM HH:mm}). Once: powershell -NoProfile -File arac/ikiz-soru.ps1" -f $ikizZaman,$enYeniParti) -ForegroundColor Yellow
  } else {
    $ij=Get-Content $ikizYol -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($idd in @($ij.yayin_disi_idler)){ if("$idd"){ $ikizDisi["$idd"]=$true } }
    Write-Host ("KAPI-IK: {0} soru ikiz oldugu icin yayin disi (esik soru %{1:N0} · dogru sik %{2:N0})" -f $ikizDisi.Count,(100*$ij.esik),(100*$ij.sik_esik)) -ForegroundColor Cyan
  }
} else { Write-Host '⚠ KAPI-IK: veri/ikiz-soru.json yok, ikiz suzgeci UYGULANMADI' -ForegroundColor Yellow }

$cozulmeyen=@{}
$dusen=New-Object System.Collections.Generic.List[string]
$cikti=New-Object System.Collections.Generic.List[object]
$gorulen=@{}
foreach($r in $hep){
  $anahtarSoru = "$($r.etiket)|$($r.id)"
  if($gorulen.ContainsKey($anahtarSoru)){ continue }   # ayni soru iki secim dosyasindaysa bir kez
  $gorulen[$anahtarSoru]=$true
  if($ikizDisi.ContainsKey($anahtarSoru)){ $dusen.Add("$anahtarSoru (KAPI-IK ikiz)"); continue }
  $sebep = DusmeSebebi $r.etiket $r.id
  if($sebep){ $dusen.Add("$anahtarSoru ($sebep)"); continue }
  $ham="$($r.ders)"
  $resmi=($ham -split '\|')[0].Trim()                   # bilesik adin sol yarisi
  $ekran=$sozluk[(Katla $resmi)]
  if(-not $ekran){ $ekran=$resmi; $cozulmeyen[$resmi]=$true }
  $cikti.Add([pscustomobject]@{ etiket=$r.etiket; id=$r.id; ders=$ekran; konu=$r.konu; donem=$r.donem; kurtarma=$r.kurtarma })
}

Write-Host ("BIRLESTI: {0} kayit -> {1} benzersiz soru" -f $hep.Count, $cikti.Count) -ForegroundColor Cyan
if($dusen.Count){
  Write-Host ("HAKEM KAPISI DUSURDU: {0} soru (cozme yuzeyine cikmaz)" -f $dusen.Count) -ForegroundColor Yellow
  $dusen | ForEach-Object { Write-Host "  $_" }
}
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
# ⚠ PS 5.1: Join-Path / ConvertTo-Json ciktisi bazen PSObject sarmali doner ve
# WriteAllText "Bagimsiz degisken turleri eslesmiyor" der. Ikisi de [string]'e
# ACIKCA cevrilir (11.09'da bu satir bir kez dustu).
$masterYol = [string](Join-Path $secimDir $masterAd)
$masterJson = [string](ConvertTo-Json -InputObject @($cikti.ToArray()) -Depth 3)
[IO.File]::WriteAllText($masterYol,$masterJson,[Text.UTF8Encoding]::new($false))
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
