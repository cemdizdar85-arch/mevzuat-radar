# ============================================================================
#  DERS KARNESI — Konu-Kaynak Karnesi'ni RESMI SINAV DERSLERINE baglar
#
#  SORUN: konu-kaynak-karnesi.ps1 cikmis sinav konularini ESKI ders adlariyla
#  (Muhasebe / Hukuk / Ekonomi / Maliye / Genel Kultur / Yabanci Dil)
#  gruplar. Oysa resmi yapi (TESMER Uygulama Yonergesi 2024, SGS m.6.2)
#  11 ALAN DERSI + Genel Kultur (3 ders) + Yabanci Dil seklindedir ve her
#  dersin SINAVDAKI SORU SAYISI farklidir. "Muhasebe %74 hazir" cumlesi
#  karar aldirmaz; "Denetim 16 soru, %X hazir" cumlesi aldirir.
#
#  NE YAPAR: konu adindaki anahtar kelimelerden resmi dersi tahmin eder ve
#  ders bazinda HAZIRLIK KARNESI cikarir: sinavdaki agirlik x kaynak durumu.
#  Cikti: veri/ders-karnesi.json + ekrana oncelik tablosu.
#
#  KULLANIM: paralı parti kosmadan ONCE bakilir. Fabrika yalnizca "ACIK"
#  isaretli derslerde calisir. API PARASI YEMEZ - dosya okur, ag istegi yok.
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$karneYol = Join-Path $kok "veri\konu-kaynak-karnesi.json"
$yapiYol  = Join-Path $kok "veri\sgs-sinav-yapisi.json"
if(-not (Test-Path $karneYol)){ Write-Host "konu-kaynak-karnesi.json yok - once motor/konu-kaynak-karnesi.ps1 kosulmali."; exit 1 }

$karne = Get-Content $karneYol -Raw -Encoding UTF8 | ConvertFrom-Json
$yapi  = Get-Content $yapiYol  -Raw -Encoding UTF8 | ConvertFrom-Json

# --- resmi ders -> sinavdaki soru sayisi (sgs-sinav-yapisi.json'dan) ---
$soruSayisi = @{}
foreach($b in @($yapi.sgs.bolumler)){ foreach($d in @($b.dersler)){ $soruSayisi["$($d.ders)"] = [int]$d.soru } }

# --- konu -> resmi ders esleyici ---
# Not: desenler UZUNDAN KISAYA denenir; ilk eslesen kazanir.
$DENETIM  = 'denetim|denetci|bds |kanit|calisma kagid|mutabakat|orneklem|ic kontrol|bagimsizlik|gorus|rapor|hile|surekliligi|yazili beyan|onemlilik seviyesi|kontrol testi|maddi dogrulama|gkgd|fiziki inceleme|fiziki stok|tesbit|denetim riski'
$MALIYET  = 'maliyet|sapma|dagitim yontemi|dagitim anahtar|siparis|safha|standart|yari mamul|genel uretim|direkt ilk madde|direkt iscilik|esdeger|birlesik urun|yan urun|gider yeri|donusturme|basabas|katki payi|degisken maliyet|kapasite'
$ANALIZ   = 'analiz|devir hizi|rasyo|likidite|karlilik oran|kar marji|kâr marji|nakit akim|fon akim|trend|isletme sermayesi|dupont|asit|cari oran|kaldirac|dikey yuzde|yatay|stok bagimlilik|kredi kapasitesi|borc odeme|mali tablo'
$VERGI    = 'vergi|vuk|beyanname|matrah|amortisman|tarhiyat|kdv|otv|gelir vergisi|kurumlar|stopaj|tevkifat|mukellef|zamanasimi|uzlasma|pismanlik|takdir|deger artis|menkul sermaye iradi|gayrimenkul sermaye|serbest meslek|asgari gecim'
$ISSGK    = 'is kanunu|isci|isveren|kidem|ihbar|fesih|sendika|toplu is|sgk|sosyal guvenlik|prim|emekli|sigortali|is kazasi|meslek hastalig|yillik izin|fazla calisma|asgari ucret|isyeri bildirge|is sozlesmesi|iss?izlik sigorta'
$TICARET  = 'ticaret hukuku|ttk|sirket|anonim|limited|kollektif|komandit|kooperatif|tacir|ticari isletme|kambiyo|bono|police|cek |cek$|marka|haksiz rekabet|birlesme|bolunme|genel kurul|yonetim kurulu|pay senedi|tasfiye|ticaret unvani|yedek akce'
$MESLEK   = 'meslek hukuku|3568|smmm|ymm|etik|mesleki deger|oda |turmob|ruhsat|staj|disiplin|serbest muhasebeci|meslek mensubu'
$BORCLAR  = 'borclar|tbk|sozlesme|tazminat|sebepsiz zenginle|haksiz fiil|temerrut|ifa|zamanasimi (borc)|kefalet|vekalet|satim|kira|hukumsuzluk|irade|muteselsil|alacagin devri|takas'

function ResmiDers([string]$eskiDers, [string]$konu){
  $k = "$konu".ToLower()
  switch -Regex ($eskiDers) {
    'Genel Kultur' {
      if($k -imatch 'matematik|sayi|denklem|oran-oranti|olasilik|kume|problem|geometri|islem|carpan|bolen'){ return 'Matematik' }
      if($k -imatch 'inkilap|ataturk|kurtulus|savas|antlasma|cumhuriyet|osmanli|devrim|tarih'){ return 'Ataturk Ilkeleri ve Inkilap Tarihi' }
      return 'Turkce'
    }
    # 28.07: eski taksonomide 'Matematik-Istatistik' ayri bir ders adiydi;
    # resmi SGS yapisinda Genel Kultur bolumundeki 'Matematik' dersine denk
    # gelir. Ilk kosuda 110 konu '(eslesmedi)' cikmisti, eklendi.
    'Matematik'   { return 'Matematik' }
    'Yabanci Dil' { return 'Yabanci Dil' }
    'Ekonomi'     { return 'Ekonomi' }
    'Maliye'      { return 'Maliye' }
    'Muhasebe' {
      if($k -imatch $DENETIM){ return 'Denetim' }
      if($k -imatch $MALIYET){ return 'Maliyet Muhasebesi' }
      if($k -imatch $ANALIZ) { return 'Mali Tablolar Analizi' }
      return 'Finansal Muhasebe'
    }
    'Hukuk' {
      if($k -imatch $MESLEK) { return 'Meslek Hukuku' }
      if($k -imatch $ISSGK)  { return 'Is ve Sosyal Guvenlik Hukuku' }
      if($k -imatch $VERGI)  { return 'Vergi Hukuku' }
      if($k -imatch $TICARET){ return 'Ticaret Hukuku' }
      return 'Borclar Hukuku'
    }
  }
  return "(eslesmedi) $eskiDers"
}

# --- esle ve topla ---
$tablo = @{}
foreach($k in @($karne.konular)){
  $rd = ResmiDers "$($k.ders)" "$($k.konu)"
  if(-not $tablo.ContainsKey($rd)){ $tablo[$rd] = [ordered]@{ ders=$rd; sinavSoru=$(if($soruSayisi.ContainsKey($rd)){$soruSayisi[$rd]}else{0}); konu=0; uret=0; kaynakYok=0; mevzuatDisi=0; cikmisSoru=0 } }
  $t = $tablo[$rd]
  $t.konu++; $t.cikmisSoru += [int]$k.cikmisSoru
  switch("$($k.karar)"){ 'URET'{$t.uret++} 'KAYNAK YOK'{$t.kaynakYok++} 'MEVZUAT-DISI'{$t.mevzuatDisi++} }
}

# --- karar ver ---
$satirlar = @()
foreach($rd in $tablo.Keys){
  $t = $tablo[$rd]
  $olculebilir = $t.uret + $t.kaynakYok          # mevzuat-disi zaten fabrikaya kapali
  $oran = if($olculebilir -gt 0){ [Math]::Round(100 * $t.uret / $olculebilir) } else { 0 }
  $karar = if($t.mevzuatDisi -gt 0 -and $olculebilir -eq 0){ 'FABRIKA GIRMEZ (elle yazilir)' }
           elseif($oran -ge 70){ 'ACIK - musluk acilabilir' }
           elseif($oran -ge 40){ 'SARTLI - once eksik konular tamamlanmali' }
           else { 'KAPALI - kaynak yetersiz' }
  $satirlar += [pscustomobject]@{ ders=$rd; sinavSoru=$t.sinavSoru; konu=$t.konu; uret=$t.uret; kaynakYok=$t.kaynakYok; mevzuatDisi=$t.mevzuatDisi; hazirlikYuzde=$oran; karar=$karar }
}
$satirlar = @($satirlar | Sort-Object { -$_.sinavSoru }, { -$_.konu })

# --- yaz ---
$cikti = [ordered]@{
  guncelleme = (Get-Date).ToString('yyyy-MM-dd HH:mm')
  kaynak     = "konu-kaynak-karnesi.json + sgs-sinav-yapisi.json (TESMER Uygulama Yonergesi 2024, SGS m.6.2)"
  aciklama   = "Cikmis sinav konularinin RESMI SGS derslerine baglanmis hazirlik karnesi. 'hazirlikYuzde' = kaynagi olan konu / (kaynagi olan + kaynagi olmayan); mevzuat-disi konular paydaya alinmaz cunku fabrika onlara zaten girmez. Parali parti kosmadan ONCE bakilir."
  dersler    = $satirlar
}
[IO.File]::WriteAllText((Join-Path $kok "veri\ders-karnesi.json"), ($cikti | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "======== DERS KARNESI (resmi SGS dersleri) ========"
Write-Host ("{0,-34} {1,5} {2,5} {3,5} {4,5} {5,6}  {6}" -f 'DERS','SINAV','KONU','URET','YOK','HAZIR','KARAR')
foreach($s in $satirlar){
  Write-Host ("{0,-34} {1,5} {2,5} {3,5} {4,5} {5,5}%  {6}" -f $s.ders, $s.sinavSoru, $s.konu, $s.uret, $s.kaynakYok, $s.hazirlikYuzde, $s.karar)
}
Write-Host ""
Write-Host "-> veri/ders-karnesi.json"
exit 0
