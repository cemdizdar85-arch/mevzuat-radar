#requires -Version 5.1
<#
================================================================================
  HAVUZ KUR — kapilardan gecmis HER soruyu yayin secimine alir  (11.09.2026)
  Cem: "havuzu kur"

  SORUN: 11.09 aksami fabrikada 1.780 soru tum kapilardan gecmisti ama yayinda
  yalnizca 627 vardi. Aradaki 1.153 soru URETILDI, PARASI ODENDI, KAPILARDAN
  GECTI - ama ogrenci goremiyordu. Sebep: yayin secim dosyalari
  (veri/sinav/kaydir-secim/yayin-sgs-*.json) her uretim turunda ELLE ya da
  kosucunun kendi plan adiyla yaziliyordu; toplu hasat sonrasi kimse onlari
  tazelemedi.

  NE YAPAR: butun parti dosyalarini tarar, YAYIN SARTINI saglayan her soruyu
  dersine gore yayin-sgs-<ders>.json dosyasina yazar. Sonra arac/sgs-650-bas.ps1
  bunlari birlestirip havuzu ve sayfalari kurar.

  YAYIN SARTI (SORU-BASMA-KURALLARI 8.1 ile ayni):
    hakem EVET · hesap_uyum != HESAP-YANLIS · kor cozum dogru ·
    hakem2 EVET · simulasyon yanlis DEGIL
  Not: ikiz suzgeci (KAPI-IK) ve kodsuz hesap adi (KAPI-KH) sgs-650-bas.ps1'de
  ikinci savunma hatti olarak calisir; burasi onlari TEKRARLAMAZ.

  ⛔ SORU SILMEZ, YENIDEN URETMEZ. Yalniz secim dosyasi yazar. BEDEL 0.
================================================================================
#>
param(
  [switch]$Yaz,
  # ⛔⭐ 12.09.2026 SINAV FILTRESI (Cem onayi). Havuz artik YALNIZ bu onekli
  #   partilerden kurulur. Niye: havuz-kur butun kalip-parti-*.json dosyalarini
  #   tariyor ve soruyu DERS ADINA gore dagitiyordu - sinav bilgisi hic bakilmiyordu.
  #   "Denetim" ve "Finansal Muhasebe" adlari SGS ile YETERLILIK'te ortak oldugu icin
  #   yeterlilik (smmm-*) ve pilot (pilot6-*) sorulari SGS havuzuna siziyordu.
  #   OLCULDU 12.09: havuzdaki 2.670 sorunun 5'i SGS DISI partidendi
  #     smmm-denetim-30/kp-21 (yeterlilik - SGS'den DAHA ZOR bir sinav)
  #     pilot6-fmuh-zor/kp-01, pilot6-fmuh-{cokzor,zor,kolay}/kp-02 (deneme partileri)
  #   Ambarda 614 sgs partisine karsi 33 SGS disi parti var (spl 14 · kgk 9 · smmm 6
  #   · pilot6 3 · devir 1); bugun yalniz 5 soru sizmisti ama mekanizma her yeni
  #   yeterlilik/KGK partisinde yeniden isleyecekti.
  #   ⚠ Ad PS'te kisa degil: bu dosyada baska `$sinav` YOK (olculdu) - carpisma yok.
  [string]$Sinav='sgs'
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

function Katla([string]$s){
  $x="$s".Trim().ToLowerInvariant()
  foreach($c in @(@('ç','c'),@('ğ','g'),@('ı','i'),@('İ','i'),@('ö','o'),@('ş','s'),@('ü','u'))){ $x=$x.Replace($c[0],$c[1]) }
  return ($x -replace '[^a-z0-9]+',' ').Trim()
}
# Ders adi: etiketten cozulur (parti kayitlarinda `ders` alani BOS - parti duzeyinde tutuluyor)
$DERS_TABLO=[ordered]@{
  'fmuh'='Finansal Muhasebe'; 'denetim'='Denetim'; 'maliyet'='Maliyet Muhasebesi'
  'mta'='Mali Tablolar Analizi'; 'ticaret'='Ticaret Hukuku'; 'borclar'='Borçlar Hukuku'
  'vergi'='Vergi Hukuku'; 'meslek'='Meslek Hukuku'; 'issgk'='İş ve Sosyal Güvenlik Hukuku'
  'ekonomi'='Ekonomi'; 'maliye'='Maliye'
  # ⛔⭐ SOZEL HAT ACILDI — 13.09.2026, Cem "1 yap" (11.09'daki "beklesin" karari KALDIRILDI).
  #   Bu dort ders havuza HIC girmiyordu; sebep kalite DEGIL, bu tablodaydi: etiket
  #   parcalarinin karsiligi yoktu, DersBul bos donuyor, soru "DERSI COZULEMEDIGI ICIN
  #   ALINMAYAN" diye atlaniyordu. OLCULDU (arac/sozel-hat-excel.ps1): bu hat sinavin
  #   %22,7'si (35 donemde 1.020 soru); uretilmis, odenmis, KAPILARI GECMIS sorular
  #   rafta duruyordu.
  #   Adlar veri/ders-sozlugu.json RESMI ekran adlariyla BIREBIR ayni (yoksa
  #   sgs-650-bas.ps1 ekran adini bulamaz). Resmi liste SINAV-TEK-SAYFA (Cem 01.09):
  #   Turkce 7 · Matematik 8 · Ataturk Ilk. ve Ink. Tarihi 5 · Yabanci Dil 10 soru/sinav.
  #   ⚠ Turkce ile Inkilap AYRI derstir, tek sayfada birlestirilmez.
  'yd'='Yabancı Dil'; 'mat'='Matematik'; 'turkce'='Türkçe'
  'inkilap'='Atatürk İlkeleri ve İnkılap Tarihi'
  # a6e serisi etiketi 'yd' degil 'yabancidil' yaziyor (sgs-a6e-yabancidil-p1b, 4 soru).
  # ⚠ sgs-kapituru-* BILEREK eslenmez: kapi deneme turu, ders degil.
  'yabancidil'='Yabancı Dil'
}
# ⛔ PS TUZAGI (11.09'da ALTINCI kez): tablonun adi $DERS idi ve asagida
#    "$ders=DersBul $et" yazdim. PS harf AYIRMAZ -> ilk atama TABLOYU string
#    ile ezdi, sonraki cagrilar bos dondu ve 1.799 sorunun HEPSI "dersi
#    cozulemedi" diye ATLANDI. Ad artik $DERS_TABLO.
#    Bu tuzak arac/olcum-kapilari.ps1'de YAZILI ve yine dustum - kural
#    "dikkat ederim" degil, AD SECIMI olmali: global sabitler UZUN ad alir.
function DersBul([string]$et){ foreach($k in $DERS_TABLO.Keys){ if($et -match "(^|-)$k(-|$)"){ return $DERS_TABLO[$k] } }; return '' }
# Dosya adi: turkce harf katlanir (mevcut dosyalar boyle adlandirilmis)
function DosyaAdi([string]$ders){
  $x=Katla $ders
  return ('yayin-sgs-' + ($x -replace '\s+','-') + '.json')
}

$sayac=@{}; $atlanan=@{}; $toplam=0; $gecen=0
$kova=@{}
$disSinav=@{}   # sinav filtresinin disarida biraktigi partiler - SESSIZ gecilmez
foreach($x in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  $et=($x.BaseName -replace '^kalip-parti-','')
  # SINAV FILTRESI (bkz. param aciklamasi): baska sinavin sorusu bu havuza girmez.
  if($et -notlike "$Sinav-*"){
    $on=if($et -match '^([a-z0-9]+)-'){ $matches[1] } else { $et }
    $disSinav[$on]=1+[int]$disSinav[$on]
    continue
  }
  # ⛔ PILOT PARTI HAVUZA GIRMEZ (13.09.2026). Sozel hat acilirken olculdu: yeni ders
  #   anahtarlari sgs-gk-pilot*-{yd,mat,turkce,inkilap}-* DENEME partilerine de vuruyordu
  #   (17 sozel pilot parti). Pilotlar hat kurulurken istemi denemek icin kosuldu; siteye
  #   cikmak icin uretilmediler. Ayni gece pilot6-* sorulari da ayni gerekceyle
  #   cikarilmisti - kural artik mekanik ve her ders icin gecerli.
  #   ⚠ YAN ETKI OLCULDU: mevcut havuzda 5 pilot soru vardi (sgs-gk-pilot 2 · pilot2 3,
  #     alan derslerine dusen pilotlardan). Bu kural onlari da cikarir - bilerek.
  if($et -match '(^|-)pilot\d*(-|$)'){
    $disSinav['pilot']=1+[int]$disSinav['pilot']
    continue
  }
  $ders=DersBul $et
  $c=$null
  foreach($d in 1..3){ try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json; break }catch{ Start-Sleep -Milliseconds 400 } }
  if(-not $c){ continue }   # kosan tur yaziyor olabilir; sessiz gecme YOK:
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    $toplam++
    if(-not ($v.hakem -and "$($v.hakem.karar)" -eq 'EVET')){ continue }
    if("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ continue }
    if("$($v.hakem.ders_uyum)" -eq 'DERS-DISI'){ continue }
    if("$($v.hakem.konu_uyum)" -eq 'KONU-DISI'){ continue }
    if("$($v.hakem.tek_anlam)" -eq 'CIFT-ANLAM'){ continue }
    if(-not ($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ continue }
    if(-not ($v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ continue }
    $simOk=$true
    foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simOk=$false } }
    if(-not $simOk){ continue }
    $gecen++
    if(-not $ders){ $atlanan[$et]=1+[int]$atlanan[$et]; continue }
    if(-not $kova.ContainsKey($ders)){ $kova[$ders]=New-Object System.Collections.Generic.List[object] }
    $kova[$ders].Add([pscustomobject]@{
      etiket=$et; id=$p.Name; ders=$ders; konu="$($v.konu)"
      donem=$(if($v.PSObject.Properties['donem']){ [int]$v.donem } else { 1 })
      kurtarma=$false })
    $sayac[$ders]=1+[int]$sayac[$ders]
  }
}
Write-Host ("taranan {0:N0} soru · YAYIN SARTINI saglayan {1:N0}" -f $toplam,$gecen) -ForegroundColor Cyan
if($disSinav.Count){
  $dn=0; foreach($v in $disSinav.Values){ $dn+=$v }
  Write-Host ("SINAV FILTRESI ('{0}-*'): {1} parti dosyasi disarida birakildi -> {2}" -f $Sinav,$dn,
    (($disSinav.GetEnumerator()|Sort-Object Value -Descending|ForEach-Object{ "$($_.Key) $($_.Value)" }) -join ' · ')) -ForegroundColor DarkGray
}
Write-Host ""
foreach($d in ($sayac.GetEnumerator()|Sort-Object Value -Descending)){ Write-Host ("  {0,-32} {1,5:N0}" -f $d.Key,$d.Value) }
$topYaz=0; foreach($d in $sayac.Keys){ $topYaz+=$sayac[$d] }
Write-Host ("  {0,-32} {1,5:N0}" -f 'TOPLAM',$topYaz) -ForegroundColor Green
if($atlanan.Count){
  Write-Host "`n  DERSI COZULEMEDIGI ICIN ALINMAYAN (sozel hat dahil):" -ForegroundColor Yellow
  foreach($a in ($atlanan.GetEnumerator()|Sort-Object Value -Descending|Select-Object -First 10)){ Write-Host ("    {0,-34} {1,4}" -f $a.Key,$a.Value) }
  $at=0; foreach($a in $atlanan.GetEnumerator()){ $at+=$a.Value }
  Write-Host ("    toplam {0} soru" -f $at) -ForegroundColor Yellow
}

if(-not $Yaz){
  Write-Host "`nKURU KOSU - dosya YAZILMADI. Yazmak icin: -Yaz" -ForegroundColor Yellow
  return
}
$secimDir=Join-Path $depoKok 'veri\sinav\kaydir-secim'
foreach($ders in $kova.Keys){
  $yol=Join-Path $secimDir (DosyaAdi $ders)
  $liste=(Dizi $kova[$ders]) | Sort-Object @{e={[int]$_.donem};Descending=$true},konu
  [IO.File]::WriteAllText($yol,(@($liste)|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))
  Write-Host ("  yazildi: {0} ({1} soru)" -f (Split-Path $yol -Leaf),@($liste).Count)
}
Write-Host "`nSIRADAKI: powershell -NoProfile -File arac/sgs-650-bas.ps1" -ForegroundColor Cyan
