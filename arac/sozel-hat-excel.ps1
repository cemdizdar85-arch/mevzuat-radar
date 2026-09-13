#requires -Version 5.1
<#
================================================================================
  SOZEL HAT KARNESI — EXCEL   "park ettigimiz dersler ne durumda"

  13.09.2026, Cem: "sonra biraktigimiz dersler yok muydu - ekonomi turkce
  ingilizce - liste sende var, exceli son halinle at bakalim, olmadi onlari"

  NE YAPAR: park edilmis SOZEL hattin (Yabanci Dil · Turkce/Genel Kultur ·
  Matematik · Inkilap Tarihi) karnesini cikarir:
    sinavda kac soru cikiyor · biz kac soru URETTIK · kaci kapilari GECTI ·
    kaci HAVUZDA (siteye cikan) · eksik ne

  ⛔ NIYE AYRI BIR KARNE: bu dersler havuza HIC girmiyor. Sebep kalite degil,
     DERS ESLESTIRMESI: arac/havuz-kur.ps1 soruyu ders adina gore dagitiyor ve
     'yd' / 'mat' / 'turkce' / 'inkilap' etiketlerinin DERS_TABLO'da karsiligi
     YOK. Yani sorular uretildi, parasi odendi, kapilari gecti - ve rafta duruyor.
     Ana konu karnesi (arac/konu-karnesi-excel.ps1) havuzdan okudugu icin bu
     hatti HIC gostermiyor; bu dosya o koru kapatir.

  KAYNAKLAR
    veri/sgs-analiz.json        cikmis sinav (donem donem ders/konu sayimi)
    veri/fabrika/kalip-parti-*  uretilen sorular (yerel onbellek)
    veri/sinav/kaydir-secim/sgs-650-secim.json   havuz (siteye cikan)

  KULLANIM  powershell -NoProfile -File arac/sozel-hat-excel.ps1
  BEDEL 0.
================================================================================
#>
param([string]$Hedef = '')
$ErrorActionPreference='Stop'
$BU_DIZIN=Split-Path -Parent $MyInvocation.MyCommand.Path
$DEPO_KOK=Split-Path -Parent $BU_DIZIN
. (Join-Path $BU_DIZIN 'xlsx-yaz.ps1')

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant().Trim()
}

# --- park edilmis hattin ders eslestirmesi ------------------------------------
# Sol: cikmis arsivdeki DERS GRUBU · Sag: bizim etiket parcasi
$HAT=@(
  @{ ad='Yabanci Dil';                arsiv='Yabanci Dil';                etiket='yd' }
  @{ ad='Turkce / Genel Kultur';      arsiv='Genel Kultur-Genel Yetenek'; etiket='turkce|inkilap' }
  @{ ad='Matematik-Istatistik';       arsiv='Matematik-Istatistik';       etiket='mat' }
)

# --- 1) CIKMIS SINAV: ders agirligi + konu sikligi ----------------------------
$analiz = Get-Content (Join-Path $DEPO_KOK 'veri\sgs-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$DERS_CIKMIS=@{}; $KONU_CIKMIS=@{}; $KONU_DONEM=@{}; $KONU_GRUP=@{}
foreach($d in @($analiz.donemler)){
  if($d.dersSayim){ foreach($p in @($d.dersSayim.PSObject.Properties)){ $DERS_CIKMIS["$($p.Name)"]=[int]$DERS_CIKMIS["$($p.Name)"]+[int]$p.Value } }
  if(-not $d.konuSayim){ continue }
  foreach($p in @($d.konuSayim.PSObject.Properties)){
    $parca=@("$($p.Name)" -split '\|')
    $k=Katla $parca[-1]; if(-not $k){ continue }
    $KONU_CIKMIS[$k]=[int]$KONU_CIKMIS[$k]+[int]$p.Value
    $KONU_GRUP[$k]=$(if($parca.Count -gt 1){ $parca[0] } else { '?' })
    if(-not $KONU_DONEM.ContainsKey($k)){ $KONU_DONEM[$k]=New-Object System.Collections.Generic.HashSet[string] }
    [void]$KONU_DONEM[$k].Add("$($d.donem)")
  }
}

# --- 2) BIZIM URETTIKLERIMIZ (yerel parti onbellegi) --------------------------
# ⛔ Yayin sarti arac/havuz-kur.ps1 ile AYNI tutulmalidir; yoksa "gecen" rakami
#   yaniltir. Burada ayni dort kapi: hakem · hakem2 · kor cozum · simulasyon.
$BIZ=@{}   # hat adi -> @{uretilen;gecen; konular=@{}}
foreach($h in $HAT){ $BIZ[$h.ad]=@{ uretilen=0; gecen=0; konular=@{} } }
foreach($f in @(Get-ChildItem (Join-Path $DEPO_KOK 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  $et=$f.BaseName -replace '^kalip-parti-',''
  # ⛔ ADI 'hat' OLAMAZ: PS harf AYIRMAZ, $hat sabit listeyi ($HAT) EZER ve liste
  #   bosalir - ilk yazimda tam bu oldu, Excel bombos cikti. Tuzak nobetcisi
  #   (K1-CAKISMA) basilmadan yakaladi: "HAT / hat · satir 73'de EZILIYOR".
  $hatAd=$null
  foreach($h in $HAT){ if($et -match ('(^|-)(' + $h.etiket + ')(-|$)')){ $hatAd=$h.ad; break } }
  if(-not $hatAd){ continue }
  $c=$null
  try{ $c=Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ continue }
  foreach($p in @($c.PSObject.Properties)){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    $BIZ[$hatAd].uretilen++
    $k=Katla "$($v.konu)"
    if($k){ if(-not $BIZ[$hatAd].konular.ContainsKey($k)){ $BIZ[$hatAd].konular[$k]=0 }; $BIZ[$hatAd].konular[$k]++ }
    if(-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')){ continue }
    if(-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    if(-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    $simOk=$true
    foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    $BIZ[$hatAd].gecen++
  }
}

# --- 3) HAVUZ (siteye cikan) --------------------------------------------------
$havuzYol=Join-Path $DEPO_KOK 'veri\sinav\kaydir-secim\sgs-650-secim.json'
$HAVUZ_DERS=@{}
if(Test-Path $havuzYol){
  $ham = Get-Content $havuzYol -Raw -Encoding UTF8 | ConvertFrom-Json   # K2: once degiskene
  foreach($x in @($ham)){ $dd="$($x.ders)"; $HAVUZ_DERS[$dd]=1+[int]$HAVUZ_DERS[$dd] }
}

# --- OZET sayfasi -------------------------------------------------------------
$ozet=New-Object System.Collections.Generic.List[object]
$ozet.Add(@('SOZEL HAT KARNESI','','','','','',''))
$ozet.Add(@("olcum: $(Get-Date -Format 'dd.MM.yyyy HH:mm')",'','','','','',''))
$ozet.Add(@('','','','','','',''))
$ozet.Add(@('Ders','Cikmis soru (35 donem)','Sinavdaki payi %','Urettigimiz','Kapilari gecen','HAVUZDA (sitede)','Durum'))
$topCik=0; foreach($v in $DERS_CIKMIS.Values){ $topCik+=$v }
$tU=0;$tG=0;$tC=0
foreach($h in $HAT){
  $cik=[int]$DERS_CIKMIS[$h.arsiv]
  $u=$BIZ[$h.ad].uretilen; $g=$BIZ[$h.ad].gecen
  $havuz=[int]$HAVUZ_DERS[$h.ad]
  $tU+=$u; $tG+=$g; $tC+=$cik
  $durum = if($havuz -eq 0 -and $g -gt 0){ "RAFTA - $g soru hazir ama havuza girmiyor (ders eslestirmesi yok)" } elseif($havuz -eq 0){ 'hic yok' } else { 'yayinda' }
  $ozet.Add(@($h.ad,$cik,[math]::Round(100*$cik/[Math]::Max(1,$topCik),1),$u,$g,$havuz,$durum))
}
$ozet.Add(@('TOPLAM',$tC,[math]::Round(100*$tC/[Math]::Max(1,$topCik),1),$tU,$tG,0,''))
$ozet.Add(@('','','','','','',''))
$ozet.Add(@('NEDEN HAVUZA GIRMIYOR','arac/havuz-kur.ps1 soruyu DERS ADINA gore dagitiyor; yd/mat/turkce/inkilap etiketlerinin DERS_TABLO karsiligi YOK.','','','','',''))
$ozet.Add(@('YAPILMASI GEREKEN','DERS_TABLO''ya dort eslestirme satiri + kaydir sayfa adlari. Yeni soru URETMEK GEREKMIYOR - sorular zaten uretildi ve odendi.','','','','',''))

# --- KONU sayfasi -------------------------------------------------------------
$konu=New-Object System.Collections.Generic.List[object]
$konu.Add(@('Ders','Konu','Cikmis soru','Kac donemde','Bizde uretilen','Durum'))
$satirSay=0
foreach($h in $HAT){
  $bizKonu=$BIZ[$h.ad].konular
  $aday=@($KONU_CIKMIS.Keys | Where-Object{ $KONU_GRUP[$_] -eq $h.arsiv })
  foreach($k in ($aday | Sort-Object { -$KONU_CIKMIS[$_] })){
    $bz=[int]$bizKonu[$k]
    $durum = if($bz -eq 0){ 'HIC BASMADIK' } else { 'urettik, rafta' }
    $konu.Add(@($h.ad,$k,$KONU_CIKMIS[$k],$KONU_DONEM[$k].Count,$bz,$durum))
    $satirSay++
  }
}

$hedefYol = $(if($Hedef){ $Hedef } else { Join-Path ([Environment]::GetFolderPath('Desktop')) ("TETIKTE-SOZEL-HAT-{0}.xlsx" -f (Get-Date -Format 'yyyyMMdd-HHmm')) })
$dosya=XlsxYaz -Hedef $hedefYol -Sayfalar @(
  @{ ad='OZET';      satirlar=$ozet.ToArray() }
  @{ ad='KONU';      satirlar=$konu.ToArray() }
) -DonukSatir 1

Write-Host ""
Write-Host ("YAZILDI: {0}" -f $dosya.FullName) -ForegroundColor Green
Write-Host ("  {0:N0} KB · OZET {1} ders · KONU {2:N0} satir" -f ($dosya.Length/1KB),$HAT.Count,$satirSay)
Write-Host ("  cikmis {0:N0} soru (sinavin %{1}'i) · urettigimiz {2:N0} · kapilari gecen {3:N0} · havuzda 0" -f $tC,[math]::Round(100*$tC/[Math]::Max(1,$topCik),1),$tU,$tG) -ForegroundColor Cyan
