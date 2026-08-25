# ============================================================================
#  BIRLESIK YENIDEN YAZIM - OLCUM PARTISI   (10.08.2026)
#
#  CEM 10.08: "siteye sorunsuz ve yuzde yuz dogru, cikmis sinav sorulariyla
#  uyumlu ve ondan daha zor, turkce kelimeler, hesap kodlari dogru, yanlis
#  hesap kodu ve isim vermeyen ... ne gerekiyorsa para harcama dahil yap"
#
#  BU BETIK PARA HARCAR ama YALNIZ 20 SORULUK. Amaci tam kasa kosusundan
#  ONCE soru basina GERCEK jetonu olcmek. Tahmin yok: sayilar API cevabindan
#  birebir okunur. Kasaya HICBIR SEY YAZMAZ.
#
#  NEDEN OPUS 5: Cem butce kisitini kaldirdi ve "%100 dogru" istedi. Dun
#  Haiku/Sonnet 4.5 karsilastirmasi PARAYI KISMAK icindi; o kisit yok artik.
#  Model secimi artik dogruluk uzerinden yapilir.
#
#  TASARIM SARTI (hafizadaki en pahali ders): model HAFIZADAN yazmaz.
#  Ambardaki kaynak metin onune konur; kaynak yoksa "KAYNAK YOK" der ve o
#  soru yeniden yazilmaz. Kaynaksiz yazim = uydurma.
#
#  KATMAN 3'un SEKIZ ISI TEK CAGRIDA (metne dokunan her is 5'ten once biter):
#    1 her yanlis sikta TUZAK adi + "Dogrusu:"
#    2 tablo / yevmiye kaydi - borc ve alacak AYRI sutun
#    3 hesapli soruda FORMUL yazilir, adim adim cozulur
#    4 veri noktasi 3,39 -> 5,63 (sinav olcusu)
#    5 cok ciktili ("sirasiyla") %0,4 -> %6,7
#    6 olumsuz kok %2,5 -> %17-30
#    7 hesap kodu <-> THP resmi adi; kanun kopyasi dili yok; arkaik kelime yok
#    8 ders etiketi icerige gore
#
#  Cikti: veri/birlesik-yazim-olcum.json  (+ ekrana ornekler)
#  "Raporu degil SORULARI oku" - cikti dosyasinda tam metinler durur.
# ============================================================================
param(
  [int]$adet = 20,
  [string]$model = 'claude-opus-5',
  [string]$caba = 'high',        # low | medium | high | xhigh | max
  # 10.08 batch sinamasi: bir cevap 8.000 tavanina carpti (stop=max_tokens) ve
  # kayboldu; gorulen en yuksek cikti 7.508 jetondu. max_tokens OTPM hiz
  # sinirina SAYILMAZ, yani tavani yukseltmenin maliyeti yok - yalniz
  # gercekten uretilen jeton faturalanir. Dar tutmak ise soruyu kaybettirir.
  [int]$enCokJeton = 12000,
  [string]$ciktiYolu = '',        # bos ise veri/birlesik-yazim-olcum.json
  [switch]$kuru,                  # API'ye dokunmaz, yalniz istem uzunlugunu olcer
  # --- 10.08: TAM KOSU ICIN EKLENDI ----------------------------------------
  [switch]$batch,                 # Batch API (paralel + %50 ucuz). 3.540 soru
                                  # tek tek gonderilirse ~60-90 SAAT surer.
  [string]$idler = '',            # kimlik listesi (yayin-kapisi-temiz-idler.json)
  [int]$partiBoyu = 400           # tek batch'te kac soru
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path $PSScriptRoot -Parent
# 12.08: CIFT HAT - hedef (anthropic | aws) api-hedef.ps1'den gelir.
# AWS uclusu ortamda tamsa kendiliginden aws'e gecer; MEVZUAT_API_HEDEF ile elle secilir.
. (Join-Path $PSScriptRoot 'api-hedef.ps1')
$HEDEF = $null
try { $HEDEF = Get-ApiHedef } catch { if(-not $kuru){ Write-Host $_.Exception.Message; exit 1 } }
$apiAnahtar = if($HEDEF){ $HEDEF.anahtar } else { $null }
$API_TABAN  = if($HEDEF){ $HEDEF.taban } else { 'https://api.anthropic.com' }
if($HEDEF){ Write-Host ("API hedefi: {0} ({1})" -f $HEDEF.ad, $API_TABAN) }
$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $apiAnahtar -and -not $kuru){ Write-Host 'API anahtari yok (ne ANTHROPIC_API_KEY ne AWS uclusu).'; exit 1 }
if(-not $sbAnahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }

$SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
Add-Type -AssemblyName System.Net.Http
$sbIstemci = New-Object System.Net.Http.HttpClient
$sbIstemci.Timeout = [TimeSpan]::FromSeconds(180)
$sbIstemci.DefaultRequestHeaders.Add('apikey',$sbAnahtar)
$sbIstemci.DefaultRequestHeaders.Add('Authorization',('Bearer '+$sbAnahtar))
$sbIstemci.DefaultRequestHeaders.Add('User-Agent','mevzuat-radar-robot/1.0')

$api = New-Object System.Net.Http.HttpClient
$api.Timeout = [TimeSpan]::FromSeconds(900)   # Opus 5 + yuksek caba uzun surer
if($HEDEF){ Add-ApiBasliklar $api $HEDEF }    # x-api-key + version (+ aws'de workspace-id)

# --- SORULARI CEK -----------------------------------------------------------
# -idler verilirse O KIMLIKLER cekilir (tam kosu); yoksa kasa boyunca esit
# aralikli ornek (olcum kosusu). Ornek kosusunda bas taraftan almak yanlis
# olurdu - tek ders gelir.
$ALANLAR = 'id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no'
$secilen = New-Object System.Collections.Generic.List[object]

if($idler -ne ''){
  if(-not (Test-Path $idler)){ Write-Host "KIRMIZI: kimlik dosyasi yok - $idler"; exit 1 }
  $hamK = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($idler,[Text.Encoding]::UTF8))
  $dizK = if($null -ne $hamK.idler){ @($hamK.idler) } else { @($hamK) }
  $kimlikler = New-Object System.Collections.Generic.List[string]
  foreach($x in $dizK){
    $a = if($null -ne $x.id){ "$($x.id)" } else { "$x" }
    if($a.Trim().Length -gt 0){ $kimlikler.Add($a) }
  }
  if($kimlikler.Count -eq 0){ Write-Host 'KIRMIZI: kimlik cikarilamadi.'; exit 1 }
  Write-Host ("Kimlik listesi: {0} soru cekiliyor..." -f $kimlikler.Count)
  for($i=0; $i -lt $kimlikler.Count; $i += 100){
    $parcaK = @($kimlikler | Select-Object -Skip $i -First 100)
    $gK = $null
    for($d=1; $d -le 4; $d++){
      try{ $gK = $sbIstemci.GetStringAsync($SB+'/soru_havuzu?select='+$ALANLAR+'&id=in.('+($parcaK -join ',')+')').GetAwaiter().GetResult(); break }
      catch{ if($d -eq 4){ throw }; Start-Sleep -Seconds (2*$d) }
    }
    $cK = ConvertFrom-Json -InputObject $gK   # IKI ADIM - tek satirda coker
    foreach($x in @($cK)){ $secilen.Add($x) }
    if(($i % 1000) -eq 0 -and $i -gt 0){ Write-Host ("  ...{0}" -f $secilen.Count) }
  }
  Write-Host ("  cekilen: {0}" -f $secilen.Count)
  if($secilen.Count -ne $kimlikler.Count){
    Write-Host ("KIRMIZI: {0} kimlik istendi, {1} geldi - eksik var, durduruldu." -f $kimlikler.Count,$secilen.Count); exit 1
  }
  if($adet -gt 0 -and $secilen.Count -gt $adet -and $adet -lt $kimlikler.Count){
    $secilen = [System.Collections.Generic.List[object]]@($secilen | Select-Object -First $adet)
    Write-Host ("  -adet siniri: {0}" -f $secilen.Count)
  }
}
else {
Write-Host 'Kasadan ornek cekiliyor...'
$havuz = New-Object System.Collections.Generic.List[object]
foreach($off in 2000,10000,18000,26000){
  $g = $null
  for($d=1; $d -le 3; $d++){
    try{ $g = $sbIstemci.GetStringAsync($SB+'/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no&order=id&limit=200&offset='+$off).GetAwaiter().GetResult(); break }
    catch{ if($d -eq 3){ throw }; Start-Sleep -Seconds (2*$d) }
  }
  $c = ConvertFrom-Json -InputObject $g   # IKI ADIM - tek satirda coker
  foreach($x in @($c)){ $havuz.Add($x) }
}
Write-Host ("  havuz: {0}" -f $havuz.Count)
$atlama = [math]::Max(1,[math]::Floor($havuz.Count/$adet))
for($i=0; $i -lt $adet -and ($i*$atlama) -lt $havuz.Count; $i++){ $secilen.Add($havuz[$i*$atlama]) }
Write-Host ("  olculecek: {0} soru" -f $secilen.Count)
}

# --- KAYNAK METIN (hakem-olcum.ps1'den, dogrulugu 18/20'de kanitli) ---------
function Getir([string]$desen,[int]$sinir){
  $kod = [Uri]::EscapeDataString($desen)
  try{
    $r = $sbIstemci.GetStringAsync($SB+'/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+$kod+'&limit='+$sinir).GetAwaiter().GetResult()
    $rc = ConvertFrom-Json -InputObject $r
    return @($rc)
  } catch { return @() }
}
function KaynakMetin($soru){
  $kanun = "$($soru.kanun_no)".Trim()
  $madde = "$($soru.madde_no)".Trim()
  $bulunan = @()
  if($kanun -ne '' -and $madde -ne ''){
    $bulunan = Getir ('*'+$kanun+'*m.'+$madde) 2
    if($bulunan.Count -eq 0){ $bulunan = Getir ('*'+$kanun+'*'+$madde+'*') 2 }
  }
  if($bulunan.Count -eq 0 -and $kanun -ne ''){ $bulunan = Getir ('*'+$kanun+'*') 3 }
  if($bulunan.Count -eq 0){
    $ad = "$($soru.kaynak)"
    if($ad.Trim().Length -ge 4){
      $ilk = ($ad -split '[-()]')[0].Trim()
      if($ilk.Length -ge 4){ $bulunan = Getir ('*'+$ilk+'*') 3 }
    }
  }
  $b = ''
  foreach($x in $bulunan){ $b += "[$($x.kaynak_ad)]`n$($x.metin)`n`n" }
  if($b.Length -gt 6000){ $b = $b.Substring(0,6000) }
  return $b
}
# THP: hesap kodu gecen sorularda resmi hesap adi da onune konur (Cem: "yanlis
# hesap kodu ve isim vermeyen"). Kod dogrulugu ancak resmi liste onundeyken
# denetlenebilir - hafizadan degil.
function ThpMetin([string]$govde){
  $kodlar = @()
  foreach($m in [regex]::Matches($govde,'\b(\d{3})\b')){
    $k = $m.Groups[1].Value
    if([int]$k -ge 100 -and [int]$k -le 999){ if($kodlar -notcontains $k){ $kodlar += $k } }
  }
  if($kodlar.Count -eq 0){ return '' }
  $b = ''
  foreach($k in ($kodlar | Select-Object -First 8)){
    $bul = Getir ('*THP '+$k+'*') 1
    foreach($x in $bul){
      $mt = "$($x.metin)"
      if($mt.Length -gt 400){ $mt = $mt.Substring(0,400) }
      $b += "[$($x.kaynak_ad)] $mt`n"
    }
  }
  return $b
}

$SISTEM = @'
Sen Turkiye SMMM/KGK sinavlarina soru yazan kidemli bir mali musavir ve
soru yazarisin. Isin, elindeki sorunun DOGRULUGUNU koruyarak onu cikmis
sinav sorulari ayarina - ve bir tik ustune - tasimak.

PAZARLIKSIZ KURALLAR:
1. HAFIZANDAN HUKUM VERME. Sana verilen KAYNAK METIN disinda bir madde
   numarasi, hesap kodu veya hesap adi YAZMA. Kaynak metin bir seyi
   dogrulamiyorsa o iddiayi soruya KOYMA.
2. Emin olmadigin hicbir sayi, kod, ad veya tarih yazma. Emin degilsen
   o unsuru soruda kullanma - uydurmak yerine cikar.
3. Butun metin TEMIZ TURKCE olacak. Turkce karakterler (c g i o s u ve
   buyukleri) dogru yazilacak. Arkaik/Osmanlica kelime kullanma
   (ornegin: "mezkur", "isbu", "bermucib", "tahtinda").
4. Kanun metnini KOPYALAMA. Hukmu kendi cumlenle, senaryo icinde anlat.
5. Yapay zeka kokusu olmayacak: kalip cumleler, "Bu baglamda", "Sonuc
   olarak", asiri simetrik siklar, hep ayni uzunlukta secenekler yok.
   Sik uzunluklari ve cumle kuruluslari dogal olarak degisecek.
'@

# --- DERS LISTESI: model YENI ders adi UYDURAMAZ ---------------------------
# 10.08 BULGU: ilk kosuda model "Vergi Mevzuati ve Uygulamasi (VUK - Degerleme)"
# gibi serbest metin ders adlari uretti. Boyle giderse ders etiketi duzelmez,
# DAGILIR. Ad kumesi kasadaki gercek adlarla sinirlanir.
# Adlar betige GOMULMEZ - Turkce karakter tasiyorlar ve BOM'suz .ps1 onlari
# bozar (daha once ayni tuzak yasandi). Ayri UTF-8 dosyadan okunur.
$dersYolu = Join-Path $kok 'veri\ders-listesi.json'
if(-not (Test-Path $dersYolu)){ Write-Host "DERS LISTESI YOK: $dersYolu"; exit 1 }
$DERSLER = @((ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($dersYolu,[Text.Encoding]::UTF8))).dersler)
if($DERSLER.Count -lt 5){ Write-Host 'DERS LISTESI BOS/BOZUK.'; exit 1 }
Write-Host ("Ders kumesi: {0} ad (model bunlarin disina cikamaz)" -f $DERSLER.Count)

# --- ORAN DAGITIMI: modele BIRAKILMAZ, betikten atanir --------------------
# 10.08 OLCUM BULGUSU: "uygunsa cok ciktili yap" denince model sorularin
# %85,7'sine "sirasiyla" ekledi (sinav olcusu %6,7). Tek tek bakinca sorular
# dogal duruyor - ama 30.569 sorunun %86'si ayni kaliba girerse ortaya
# TEKDUZELIK cikar, ve tekduzelik yapay zeka izini hatadan cok ele verir.
# Olumsuz kok ise tersine az uygulandi: %7,1 (hedef %17-30).
# Cozum: her soruya kendi kimliginden turetilen SABIT bir kova atanir; hedef
# oran korpus duzeyinde tutar, ayni soru her kosuda ayni biçimi alir.
# Turkce ozel harfler - makine kapisi bunlari sayar. Karakterler tek tek
# eklenir; duz dize olarak yazilirsa BOM'suz .ps1'de bozulma riski var.
$TR_OZEL = New-Object System.Collections.Generic.HashSet[char]
foreach($kod in 0x00E7,0x00C7,0x011F,0x011E,0x0131,0x0130,0x00F6,0x00D6,0x015F,0x015E,0x00FC,0x00DC){
  [void]$TR_OZEL.Add([char]$kod)   # c C g G i I o O s S u U (Turkce hallleri)
}

function Kova([string]$kimlik){
  $t = 0
  foreach($c in $kimlik.ToCharArray()){ $t = ($t * 31 + [int]$c) % 100000 }
  return ($t % 100)
}
$HEDEF_COKCIKTI = 12   # %12: sinav olcusu %6,7 - biraz ustunde tutulur (Cem: "ondan daha zor")
$HEDEF_OLUMSUZ  = 22   # %22: sinav araligi %17-30'un icinde

# --- KOK CESITLILIGI: yapay zeka izinin ASIL kaynagi ------------------------
# 10.08 OLCUMU (kok-tekduzelik-olcum.ps1, 4.000 soru):
#   "Kocaeli'de faaliyet gosteren" TEK BASINA %13 - olcut %10 ustu TEKDUZE.
#   Ilk 13 sehir acilisi toplam ~%38,7. "Mehmet" 264 kez. 39 tekil kisi adi.
# Bu kusur SORUDA degil KORPUSTA: her soru tek tek dogru olsa bile aday uc
# soru okuyunca kalibi gorur. Mercek sayisi bunu cozmez; dagitim cozer.
# Listeler ayri UTF-8 dosyada - Turkce adlar betige gomulurse BOM'suz .ps1
# onlari bozar (bugun kok-tekduzelik betiginde tam bu tuzak yasandi).
$cesitYolu = Join-Path $kok 'veri\kok-cesitlilik.json'
if(-not (Test-Path $cesitYolu)){ Write-Host "CESITLILIK DOSYASI YOK: $cesitYolu"; exit 1 }
$CES = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($cesitYolu,[Text.Encoding]::UTF8))
$ACILIS   = @($CES.acilis_bicimleri); $SEHIR = @($CES.sehirler)
$SEKTOR   = @($CES.sektorler);        $ADLAR = @($CES.kisi_adlari)
$YASAK    = @($CES.yasak_kaliplar)
# --- TUZAK SOZLUGU: ad serbest birakilmaz -----------------------------------
# 10.08 olcumu: ad serbest birakilinca 39 tuzak adinin 38'i TEKIL cikti,
# yalniz biri tekrarladi. Tekrar olmadan "bu hafta 4 soruda su tuzaga
# dustun" denemez - yani fikir calismaz. Sozluk tekrari zorlar.
$tuzakYolu = Join-Path $kok 'veri\tuzak-sozlugu.json'
if(-not (Test-Path $tuzakYolu)){ Write-Host "TUZAK SOZLUGU YOK: $tuzakYolu"; exit 1 }
$TSZ = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($tuzakYolu,[Text.Encoding]::UTF8))
$TUZAKLAR = New-Object System.Collections.Generic.List[string]
foreach($alan in $TSZ.PSObject.Properties){
  if($alan.Value -is [array]){ foreach($t in $alan.Value){ if("$t".Trim().Length -gt 3){ $TUZAKLAR.Add("$t") } } }
}
if($TUZAKLAR.Count -lt 20){ Write-Host 'TUZAK SOZLUGU EKSIK.'; exit 1 }
$TUZAK_METNI = ($TUZAKLAR | ForEach-Object { '  - ' + $_ }) -join "`n"
Write-Host ("Tuzak sozlugu: {0} ad" -f $TUZAKLAR.Count)

# ASCII katlama: "gecmise etkiyi atlama" ile "gecmise etkiyi atlama" ayni
# anahtara duser, boylece modelin ASCII yazimi SOZLUKTEKI dogru yazimla
# degistirilebilir. 10.08 dersi: "ozel harf yoksa ASCII'ye dusmustur" olcutu
# YANLIS - "zorunlu ambalaj bedelini atlama" kusursuz Turkce oldugu halde
# ozel harf tasimaz. Iyi ciktiyi reddedip para yakti. Dogru olcut sozlukle
# karsilastirmak, ve ret degil ONARIM yapmak.
$ASCII_CEVIRI = @{}
foreach($c in @(@(0x00E7,'c'),@(0x00C7,'c'),@(0x011F,'g'),@(0x011E,'g'),
                @(0x0131,'i'),@(0x0130,'i'),@(0x00F6,'o'),@(0x00D6,'o'),
                @(0x015F,'s'),@(0x015E,'s'),@(0x00FC,'u'),@(0x00DC,'u'))){
  $ASCII_CEVIRI[[char]$c[0]] = $c[1]
}
function AsciiKatla([string]$t){
  $sb = New-Object Text.StringBuilder
  foreach($ch in $t.ToCharArray()){
    if($ASCII_CEVIRI.ContainsKey($ch)){ [void]$sb.Append($ASCII_CEVIRI[$ch]) }
    else { [void]$sb.Append([char]::ToLowerInvariant($ch)) }
  }
  return ($sb.ToString() -replace '\s+',' ').Trim()
}
$TUZAK_ASCII = @{}
foreach($t in $TUZAKLAR){ $TUZAK_ASCII[(AsciiKatla $t)] = $t }

# Sistem istemi + sozluk = onbelleklenecek SABIT blok. Sozluk buraya tasindi
# (once her sorunun isteminde tekrarlaniyordu ve onbeleklenemiyordu).
$SISTEM_TAM = $SISTEM + @"

TUZAK SOZLUGU - yanlis sikkin "tuzak" alanini doldururken ONCE BURADA ARA.
Uygun ad varsa BIREBIR onu kullan (es anlamli yazma, kelimesini degistirme).
Hicbiri uymuyorsa yeni ad oner: 2-5 kelime, kucuk harfle, kusursuz Turkce,
sirket/sehir/tarih/rakam GECMEDEN.
$TUZAK_METNI
"@

$ACIKBICIM = @($CES.aciklama_bicimleri)
if($ACIKBICIM.Count -lt 3){ Write-Host 'ACIKLAMA BICIMLERI EKSIK.'; exit 1 }
$KURAL_TR = "$($CES.kurallar_tr)"
if($KURAL_TR.Trim().Length -lt 40){ Write-Host 'DIL KURALI (kurallar_tr) EKSIK.'; exit 1 }
if($ACILIS.Count -lt 4 -or $SEHIR.Count -lt 10){ Write-Host 'CESITLILIK DOSYASI EKSIK.'; exit 1 }
Write-Host ("Cesitlilik: {0} acilis bicimi | {1} sehir | {2} sektor | {3} ad" -f $ACILIS.Count,$SEHIR.Count,$SEKTOR.Count,$ADLAR.Count)

$sonuc = New-Object System.Collections.Generic.List[object]
$toplamGirdi = 0; $toplamCikti = 0; $basarisiz = 0; $kaynaksiz = 0
$istemUzunluk = 0
# Tuzak sozlugu benimseme sayaclari - fikrin isleyip islemedigini bunlar soyler
$script:tuzakSozluktenAd = 0; $script:tuzakYeniAd = 0; $script:tuzakHizalanan = 0
$script:onbellekOkuma = 0; $script:onbellekYazma = 0
$script:yeniTuzakAdlari = New-Object System.Collections.Generic.List[string]

# ============================================================================
#  KAPI VE KAYIT - senkron ve batch AYNI kapilardan gecer
#  10.08: batch yolu eklenirken kapilar ikizlenmesin diye fonksiyona alindi.
#  Iki kopya olsaydi biri duzeltilip oteki unutulurdu; o zaman 3.540 sorunun
#  bir kismi denetimsiz gecerdi ve bunu kimse fark etmezdi.
# ============================================================================
# ---------------------------------------------------------------------------
#  SIK KARISTIRICI - sartname 11 (dogru sik harf dagilimi dengeli)
#  10.08: bu isi modele yaptirmak istem jetonu yakiyordu. Permutasyon
#  deterministik: dogru sikkin gidecegi harf kimlikten turetilir, sik metinleri
#  ve TUZAK ADLARI birlikte tasinir (tuzak yanlis sikka bagli - ayri tasinirsa
#  aciklama bir sikka, tuzak baskasina gider ve aday YANLIS ogrenir).
#  Aciklamalar da ayni haritayla tasinir.
# ---------------------------------------------------------------------------
function SiklariKaristir($yeni, [string]$kimlik){
  $harfler = @('A','B','C','D','E')
  $dolu = @($harfler | Where-Object { "$($yeni.siklar.$_)".Trim().Length -gt 0 })
  if($dolu.Count -lt 2){ return $hedefHarf }
  $eskiDogru = "$($yeni.dogru)".Trim().ToUpperInvariant()
  if($dolu -notcontains $eskiDogru){ return $eskiDogru }   # bozuk - dokunma

  $yeniDogru = $dolu[(Kova ($kimlik + 'h')) % $dolu.Count]
  if($yeniDogru -eq $eskiDogru){ return $eskiDogru }        # zaten yerinde

  # Yer degistirme: dogru sik ile hedef harftekini takas et
  foreach($alan in 'siklar','aciklama','tuzak'){
    $nesne = $yeni.$alan
    if($null -eq $nesne){ continue }
    $a = "$($nesne.$eskiDogru)"; $b = "$($nesne.$yeniDogru)"
    $nesne.$eskiDogru = $b
    $nesne.$yeniDogru = $a
  }
  $yeni.dogru = $yeniDogru
  return $yeniDogru
}

# --- KOD-AD CIFTI KAPISI icin resmi THP sozlugu (10.08, Cem onayi) ----------
# 269 resmi hesap adi ambardan cikarilmis halde duruyor. Yoksa kapi SESSIZCE
# atlanir - olmayan sozlukle soru elemek 03.08'deki ASCII kapisi hatasi olur.
$THP_ADLARI = @{}
$thpYol = Join-Path $kok 'veri\thp-resmi-adlar.json'
if(Test-Path $thpYol){
  $thpJs = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($thpYol,[Text.Encoding]::UTF8))
  foreach($pr in $thpJs.PSObject.Properties){ $THP_ADLARI[$pr.Name] = "$($pr.Value)" }
}
$THP_CEV = @{}
foreach($cc in @(@(0x00E7,'c'),@(0x00C7,'c'),@(0x011F,'g'),@(0x011E,'g'),
                 @(0x0131,'i'),@(0x0130,'i'),@(0x00F6,'o'),@(0x00D6,'o'),
                 @(0x015F,'s'),@(0x015E,'s'),@(0x00FC,'u'),@(0x00DC,'u'))){ $THP_CEV[[char]$cc[0]] = $cc[1] }
$THP_GURULTU = @('hesabina','hesabinin','hesabi','hesap','hesaba','borc','alacak','kaydedilir',
                 'yazilir','tutari','tutarinda','olan','icin','ile','bir','tarihinde','tarihli','nolu')
function ThpKelime([string]$t){
  if([string]::IsNullOrEmpty($t)){ return @() }
  $sbT = New-Object Text.StringBuilder
  foreach($ch in $t.ToCharArray()){
    if($THP_CEV.ContainsKey($ch)){ [void]$sbT.Append($THP_CEV[$ch]) }
    elseif([char]::IsLetterOrDigit($ch)){ [void]$sbT.Append([char]::ToLowerInvariant($ch)) }
    else { [void]$sbT.Append(' ') }
  }
  return @(($sbT.ToString() -split '\s+') | Where-Object { $_.Length -ge 3 -and $THP_GURULTU -notcontains $_ })
}
$THP_KELIME = @{}
foreach($kk in $THP_ADLARI.Keys){ $THP_KELIME[$kk] = @(ThpKelime $THP_ADLARI[$kk]) }
function ThpOrtusme([string[]]$hedef,[string[]]$yazilan){
  if($hedef.Count -eq 0 -or $yazilan.Count -eq 0){ return 0.0 }
  $es = 0
  foreach($r in $hedef){
    foreach($y in $yazilan){
      if($y -eq $r -or ($y.Length -ge 4 -and $r.StartsWith($y)) -or ($r.Length -ge 4 -and $y.StartsWith($r))){ $es++; break }
    }
  }
  return ([double]$es / $hedef.Count)
}
$CIFT_DESEN = [regex]("(?<kod>\b[1-7]\d{2}\b)\s*[-–—\.:]?\s*(?<ad>[\p{Lu}][\p{L}\.\(\)\-]{2,}(?:\s+[\p{L}\.\(\)\-]{2,}){0,5})")
if($THP_ADLARI.Count -gt 0){ Write-Host ("Kod-ad cifti kapisi: {0} resmi THP adi yuklendi" -f $THP_ADLARI.Count) }
else { Write-Host 'Kod-ad cifti kapisi KAPALI - veri/thp-resmi-adlar.json yok' }

function KapiVeKayit($s, $yeni, $kisaId, $durak, $girdiJ, $ciktiJ, $kv, $hedefHarf, $hedefYil, $cokCiktiIste, $olumsuzIste){
  # Once siklari karistir - kapilar KARISTIRILMIS hali denetlesin
  $null = SiklariKaristir $yeni "$($s.id)"
  # --- MAKINE KAPILARI: modelin sozune degil URETTIGI METNE bakilir
  # 10.08 vakasi: bir cevap tam ASCII geldi ("...hesap donemine ait yonetim
  # kurulu yillik..."). Model "temiz Turkce yazdim" dese de metin yalanliyordu.
  $tumYeni = "$($yeni.soru)"
  foreach($h in 'A','B','C','D','E'){ $tumYeni += " $($yeni.siklar.$h) $($yeni.aciklama.$h)" }
  $ozelSayi = 0
  foreach($c in $tumYeni.ToCharArray()){ if($TR_OZEL.Contains($c)){ $ozelSayi++ } }
  $trYogunluk = 0.0
  if($tumYeni.Length -gt 0){ $trYogunluk = [math]::Round(1000.0*$ozelSayi/$tumYeni.Length,1) }
  $trGecti = ($trYogunluk -ge 8.0)

  $kalipIhlali = @()
  foreach($yk in $YASAK){ if($tumYeni -match [regex]::Escape($yk)){ $kalipIhlali += $yk } }

  # SARTNAME 12: dogru sik en uzun olamaz. Sayisal siklarda hepsi ~ayni
  # uzunluktadir; esik ikinciden %15 uzun.
  $sikUzun = @{}
  foreach($h in 'A','B','C','D','E'){ $sikUzun[$h] = "$($yeni.siklar.$h)".Trim().Length }
  $siraliUz = @($sikUzun.Values | Where-Object { $_ -gt 0 } | Sort-Object -Descending)
  $dogruHarf = "$($yeni.dogru)".Trim().ToUpperInvariant()
  $dogruUz = 0
  if($sikUzun.ContainsKey($dogruHarf)){ $dogruUz = $sikUzun[$dogruHarf] }
  $enUzunIhlal = $false
  if($siraliUz.Count -ge 2 -and $siraliUz[1] -gt 0){
    if($dogruUz -eq $siraliUz[0] -and $dogruUz -gt ($siraliUz[1] * 1.15)){ $enUzunIhlal = $true }
  }
  $harfTuttu = ($dogruHarf -eq $hedefHarf)

  # TUZAK ALANI: dogru sikta tuzak olmaz; ad sozlukteki yazimla hizalanir
  $tuzakIhlal = @()
  foreach($h in 'A','B','C','D','E'){
    $tz = "$($yeni.tuzak.$h)".Trim()
    $sikDolu = ("$($yeni.siklar.$h)".Trim().Length -gt 0)
    if($h -eq $dogruHarf){
      if($tz -ne ''){ $tuzakIhlal += ("dogru sik ({0}) tuzak alani dolu" -f $h) }
      continue
    }
    if($sikDolu -and $tz -eq ''){ $tuzakIhlal += ("{0} sikkinin tuzak adi bos" -f $h); continue }
    if($tz -eq ''){ continue }
    $katli = AsciiKatla $tz
    if($TUZAK_ASCII.ContainsKey($katli)){
      $dogruYazim = $TUZAK_ASCII[$katli]
      if($tz -cne $dogruYazim){ $yeni.tuzak.$h = $dogruYazim; $script:tuzakHizalanan++ }
      $script:tuzakSozluktenAd++
    } else {
      $script:tuzakYeniAd++
      $script:yeniTuzakAdlari.Add($tz)
    }
  }

  # KOD-AD CIFTI KAPISI (10.08 eklendi - Cem onayi)
  # Istem 7b'yi MAKINE ile denetler. Istem tavsiye eder, kapi zorlar.
  # Olcut: yazilan ad kendi koduyla ortusmuyor ama BASKA bir kodun resmi
  # adiyla ortusuyorsa -> uydurma cift. Konum AYIRT ETMEZ: yanlis sikta da
  # olsa aday yanlis cifti ogrenir (Cem karari 10.08).
  # Kisaltmalar serbest: "129 Supheli Tic. Al. Kars." gecerli sayilir.
  if($THP_ADLARI.Count -gt 0){
    $ciftIhlal = @()
    $ciftMetin = "$($yeni.soru) $($yeni.hap)"
    foreach($h in 'A','B','C','D','E'){ $ciftMetin += ' ' + $yeni.siklar.$h + ' ' + $yeni.aciklama.$h }
    foreach($m in $CIFT_DESEN.Matches($ciftMetin)){
      $kd = $m.Groups['kod'].Value
      $ad = $m.Groups['ad'].Value.Trim()
      if($m.Index -gt 0){
        $onceki = $ciftMetin[$m.Index-1]
        if([char]::IsDigit($onceki) -or $onceki -eq '.' -or $onceki -eq ',' -or $onceki -eq '%'){ continue }
      }
      $kes = [regex]::Match($ad,'[\.\)\]]\s+\p{Lu}')
      if($kes.Success){ $ad = $ad.Substring(0,$kes.Index).Trim() }
      $adK = @(ThpKelime $ad)
      if($adK.Count -lt 2){ continue }
      if(-not $THP_ADLARI.ContainsKey($kd)){ continue }   # kod THP'de yok -> ayri kapi
      if((ThpOrtusme $THP_KELIME[$kd] $adK) -ge 0.34){ continue }   # kendi adiyla uyuyor
      $enIyi=''; $enOran=0.0
      foreach($k2 in $THP_KELIME.Keys){
        if($k2 -eq $kd){ continue }
        $o = ThpOrtusme $THP_KELIME[$k2] $adK
        if($o -gt $enOran){ $enOran=$o; $enIyi=$k2 }
      }
      if($enOran -ge 0.67){ $ciftIhlal += ("{0} '{1}' -> bu ad {2} hesabinin" -f $kd,$ad,$enIyi) }
    }
    if($ciftIhlal.Count -gt 0){
      $script:basarisiz++
      Write-Host ("  {0} | KAPIDA RED | kod-ad cifti: {1}" -f $kisaId, ($ciftIhlal -join ' | '))
      $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='KAPIDA RED - KOD AD CIFTI'; ihlal=($ciftIhlal -join ' | ') })
      return
    }
  }

  # "DOGRUSU" KAPISI KALDIRILDI (11.08 - Cem karari: B secenegi).
  # Kelime kapisi eklenmisti, sonra KALDIRILDI: birebir "Dogrusu:" aramak
  # bes sikkin aciklamasini yine ayni ritme sokar ve 291 USD verip kirdigimiz
  # tekduzeligi geri getirir. Karar: OZ zorunlu, KALIP serbest.
  #   OZ  = dogrusunun ne oldugu ACIKCA yazilacak (istemde 1. madde, zorunlu)
  #   KALIP = nasil yazilacagi serbest ("Dogrusu:" etiketi SART DEGIL)
  # Denetim MERCEK C'ye birakildi: "aciklama ogretiyor mu, adayin nerede
  # koptugunu ve DOGRUSUNUN NE OLDUGUNU gosteriyor mu" diye sorar.
  # Makine bu ozu goremez; goremedigine kapi kurulmaz.
  # ACIKLAMA KAPISI (10.08 eklendi - Cem karari)
  # BULGU: ilk 3.540'lik kosuda 27 soruda DOGRU SIKKIN aciklamasi bombostu.
  # Aday dogru cevabi isaretliyor ve hicbir sey ogrenmiyordu; sitenin butun
  # vaadi orada kiriliyor. Eski kapi "en az 4 aciklama var mi" diye bakiyordu,
  # "DOGRU sikkin aciklamasi var mi" diye bakmiyordu.
  # ESIK OLCUMLE SECILDI, tahminle degil: 16.785 aciklamanin uzunluk dagiliminda
  # 27 tanesi 0 karakter, sonraki en kisa 150 karakter. 100 esigi tam o 27'yi
  # yakalar, saglam tek soruyu elemez (ortalama 478, ortanca 425 karakter).
  $ACIKLAMA_ESIGI = 100
  $aciklamaIhlal = @()
  foreach($h in 'A','B','C','D','E'){
    if("$($yeni.siklar.$h)".Trim().Length -eq 0){ continue }   # bos sik sayilmaz
    $ac = "$($yeni.aciklama.$h)".Trim()
    if($ac.Length -lt $ACIKLAMA_ESIGI){
      if($h -eq $dogruHarf){ $aciklamaIhlal += ("DOGRU sik ({0}) aciklamasi {1} karakter" -f $h,$ac.Length) }
      else                 { $aciklamaIhlal += ("{0} sikkinin aciklamasi {1} karakter" -f $h,$ac.Length) }
    }
  }
  if($aciklamaIhlal.Count -gt 0){
    $script:basarisiz++
    Write-Host ("  {0} | KAPIDA RED | aciklama: {1}" -f $kisaId, ($aciklamaIhlal -join ' | '))
    $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='KAPIDA RED - ACIKLAMA BOS'; ihlal=($aciklamaIhlal -join ' | ') })
    return
  }

  # ============================================================================
  # BOZULMA KAPISI (11.08 eklendi - Cem karari: "kapiya ekle")
  #
  # BULGU: GM okumasi sirasinda tesadufen goruldu. Uretim ciktisinin KUYRUGUNDA
  # uc ayri bozulma imzasi var; hicbir kapi bunlari gormuyordu:
  #   1) TEKRAR DONGUSU  -> "...yansitilamaz.impaypayi payi payi."
  #   2) DUZELTME NOTU   -> "...gozden kacar.gerekir.gerekir yerine: kacar."
  #      (model son kelimeden supheleniyor ve DUZELTME NOTUNU metinde birakiyor)
  #   3) YAPISIK CUMLE   -> "...tahsilatlara aittir.muhasebe mantigi..."
  # Olcum: 3.357 yazilmis soruda 33 gercek bulgu / 31 soru (%0,92).
  #
  # YANLIS ALARM ELEMESI - ikisi de OLCULEREK secildi, tahminle degil:
  #   - "798 no.lu hesap" kalibi YAPISIK sanildi -> 14 yanlis alarm, elendi
  #   - "ayri ayri" (247), "adim adim", "bent bent" gibi TURKCE IKILEMELER
  #     TEKRAR sanildi -> 318 yanlis alarm, beyaz listeyle elendi
  #   Elemeden once 373 bulgu vardi, elemeden sonra 33. Kapi bu haliyle kurulu.
  #
  # TURKCE HARF NOTU: kaynak koda Turkce harf GOMULMEZ (BOM tuzagi, PS 5.1
  # BOM'suz .ps1'i ANSI okuyup regex'i sessizce bozuyor). Kucuk harf sinifi
  # \uXXXX kacisiyla yazildi, beyaz liste ise ASCII katlamayla karsilastiriliyor.
  # ============================================================================
  $BOZ_YAPISIK = [regex]"\p{L}[\.\?\!][a-z\u00E7\u011F\u0131\u00F6\u015F\u00FC]"
  $BOZ_NOLU    = [regex]"(?i)\bno\.[a-z\u0131]"
  $BOZ_NOT     = [regex]"\p{L}+\s+yerine\s*:"
  # 11.08 aksam eki: eot/etiket sizintisi ailesi (ogrenci alanlarinda da yakalanir)
  $BOZ_EOT     = [regex]"(?i)(<[/]?eot_response>|<[/]?eos>|<\|eot\|>|</assistant>)"
  $BOZ_TEKRAR  = [regex]"\b(\p{L}{4,})\b\s+\1\b"
  # Turkce mesru ikilemeler - kusur DEGIL (ASCII katlanmis halleriyle)
  $BOZ_MESRU = @('ayri','olsa','kalem','parca','zaman','adim','satir','donem',
                 'bolum','kademe','birer','tikir','hemen','tekrar','dilim','uzun',
                 'isim','saat','kisi','grup','yavas','sira','tutar','bent',
                 'kategori','organ','bilesen','karsilik')
  function BozAscii([string]$k){
    $k = $k.ToLower()
    $k = $k.Replace([char]0x00E7,'c').Replace([char]0x011F,'g').Replace([char]0x0131,'i')
    $k = $k.Replace([char]0x00F6,'o').Replace([char]0x015F,'s').Replace([char]0x00FC,'u')
    $k.Replace([char]0x00E2,'a')
  }
  $bozIhlal = @()
  $bozAlan = [ordered]@{ 'soru'="$($yeni.soru)"; 'hap'="$($yeni.hap)" }
  foreach($h in 'A','B','C','D','E'){
    $bozAlan["sik$h"]  = "$($yeni.siklar.$h)"
    $bozAlan["acik$h"] = "$($yeni.aciklama.$h)"
  }
  foreach($ad in $bozAlan.Keys){
    $mt = $bozAlan[$ad]
    if($mt.Length -eq 0){ continue }
    foreach($x in $BOZ_YAPISIK.Matches($mt)){
      $b=[Math]::Max(0,$x.Index-3)
      if($BOZ_NOLU.IsMatch($mt.Substring($b,[Math]::Min($mt.Length-$b,8)))){ continue }   # "no.lu" degil
      $bozIhlal += ("{0}: yapisik cumle '{1}'" -f $ad,$x.Value)
    }
    foreach($x in $BOZ_EOT.Matches($mt)){
      $bozIhlal += ("{0}: etiket sizintisi '{1}'" -f $ad,$x.Value)
    }
    foreach($x in $BOZ_NOT.Matches($mt)){
      $bozIhlal += ("{0}: duzeltme notu sizmis '{1}'" -f $ad,$x.Value)
    }
    foreach($x in $BOZ_TEKRAR.Matches($mt)){
      if($BOZ_MESRU -contains (BozAscii $x.Groups[1].Value)){ continue }                  # mesru ikileme
      $bozIhlal += ("{0}: tekrar dongusu '{1}'" -f $ad,$x.Value)
    }
  }
  if($bozIhlal.Count -gt 0){
    $script:basarisiz++
    Write-Host ("  {0} | KAPIDA RED | bozulma: {1}" -f $kisaId, ($bozIhlal -join ' | '))
    $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='KAPIDA RED - BOZULMA'; ihlal=($bozIhlal -join ' | ') })
    return
  }

  if($tuzakIhlal.Count -gt 0){
    $script:basarisiz++
    Write-Host ("  {0} | KAPIDA RED | tuzak: {1}" -f $kisaId, ($tuzakIhlal -join ' | '))
    $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='KAPIDA RED - TUZAK ALANI'; ihlal=($tuzakIhlal -join ' | ') })
    return
  }
  if($enUzunIhlal){
    $script:basarisiz++
    Write-Host ("  {0} | KAPIDA RED | dogru sik EN UZUN ({1} krk, ikinci {2} krk)" -f $kisaId,$dogruUz,$siraliUz[1])
    $sonuc.Add([pscustomobject]@{
      id="$($s.id)"; durum='KAPIDA RED - DOGRU SIK EN UZUN'
      dogruUzunluk=$dogruUz; ikinciUzunluk=$siraliUz[1]; yeniSoru="$($yeni.soru)" })
    return
  }
  if(-not $trGecti -or $kalipIhlali.Count -gt 0){
    $script:basarisiz++
    $kalipYazi = if($kalipIhlali.Count -gt 0){ $kalipIhlali -join ', ' } else { 'yok' }
    Write-Host ("  {0} | KAPIDA RED | TR yogunluk {1} (esik 8) | yasak kalip: {2}" -f $kisaId,$trYogunluk,$kalipYazi)
    $sonuc.Add([pscustomobject]@{
      id="$($s.id)"; durum='KAPIDA RED'; trYogunluk=$trYogunluk
      yasakKalip=($kalipIhlali -join ', '); yeniSoru="$($yeni.soru)" })
    return
  }

  $vn = 0; [void][int]::TryParse("$($yeni.veri_noktasi)",[ref]$vn)
  Write-Host ("  {0} | {1,-24} | veri {2,2} | tablo {3,-5} formul {4,-5} | jeton {5}+{6} | {7}" -f `
    $kisaId,"$($yeni.ders)",$vn,"$($yeni.tablo_var)","$($yeni.formul_var)",$girdiJ,$ciktiJ,$durak)

  $sonuc.Add([pscustomobject]@{
    id="$($s.id)"; durum='YAZILDI'; stop=$durak
    eskiDers="$($s.ders)"; yeniDers="$($yeni.ders)"
    girdiJeton=[int]$girdiJ; ciktiJeton=[int]$ciktiJ
    veriNoktasi=$vn; cokCiktili=$yeni.cok_ciktili; olumsuzKok=$yeni.olumsuz_kok
    kova=$kv; istenenCokCikti=$cokCiktiIste; istenenOlumsuz=$olumsuzIste
    hedefHarf=$hedefHarf; harfTuttu=$harfTuttu; hedefYil=$hedefYil
    dogruUzunluk=$dogruUz; enUzunSik=$(if($siraliUz.Count -gt 0){ $siraliUz[0] } else { 0 })
    tabloVar=$yeni.tablo_var; formulVar=$yeni.formul_var
    kullanilanKaynak="$($yeni.kullanilan_kaynak)"
    uygulanmadi="$($yeni.uygulanmadi_gerekce)"
    eskiSoru="$($s.soru)"; yeniSoru="$($yeni.soru)"
    yeniSiklar=$yeni.siklar; yeniDogru="$($yeni.dogru)"
    yeniAciklama=$yeni.aciklama; yeniTuzak=$yeni.tuzak; yeniHap="$($yeni.hap)"
    zorluk="$($yeni.zorluk)"
  })
}

# Batch modunda istekler once biriktirilir, sonra toplu gonderilir
$batchIsler = New-Object System.Collections.Generic.List[object]

foreach($s in $secilen){
  $kisaId = "$($s.id)"; if($kisaId.Length -gt 8){ $kisaId = $kisaId.Substring(0,8) }
  $siklarMetin = ''
  foreach($h in 'A','B','C','D','E'){
    try{ if($s.siklar -and $s.siklar.PSObject.Properties[$h]){ $siklarMetin += "$h) $($s.siklar.$h)`n" } }catch{}
  }
  $aciklamaMetin = ''
  foreach($h in 'A','B','C','D','E'){
    # ${h} SART: PowerShell "$h:" ifadesini surucu niteleyicisi sanar ve
    # betik ayristirma hatasiyla hic calismaz.
    try{ if($s.aciklama -and $s.aciklama.PSObject.Properties[$h]){ $aciklamaMetin += "${h}: $($s.aciklama.$h)`n" } }catch{}
  }
  $kaynak = KaynakMetin $s
  $thp = ThpMetin ("$($s.soru) $siklarMetin")

  if($kaynak.Trim() -eq '' -and $thp.Trim() -eq ''){
    $kaynaksiz++
    Write-Host ("  {0} | KAYNAK YOK - yeniden yazilmadi (uydurma olurdu)" -f $kisaId)
    $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='KAYNAK YOK'; ders="$($s.ders)" })
    continue
  }

  # Bicim kovalari CAKISMASIN diye ayri araliklar: 0-11 cok ciktili,
  # 50-71 olumsuz kok. Geri kalan sorular duz bicimde kalir.
  $kv = Kova "$($s.id)"
  $cokCiktiIste = ($kv -lt $HEDEF_COKCIKTI)
  $olumsuzIste  = ($kv -ge 50 -and $kv -lt (50 + $HEDEF_OLUMSUZ))
  $bicimTalimati = if($cokCiktiIste){
@'
5. BU SORUYU COK CIKTILI YAP: birden fazla degeri ayni anda sor
   ("... sirasiyla asagidakilerden hangisidir?") ve siklarda ikili/uclu demet ver.
6. Olumsuz kok KULLANMA - bu soru duz (olumlu) kok tasiyacak.
'@
  } elseif($olumsuzIste){
@'
5. Cok ciktili bicim KULLANMA - bu soru tek bir sey soracak.
6. BU SORUDA OLUMSUZ KOK KULLAN: "... asagidakilerden hangisi YANLISTIR?" ya da
   "... hangisi SOYLENEMEZ?" bicimi. Olumsuz kelimeyi BUYUK harfle vurgula.
'@
  } else {
@'
5. Cok ciktili bicim KULLANMA.
6. Olumsuz kok KULLANMA. Bu soru duz, tek cevapli, olumlu kokle sorulacak.
'@
  }

  # Cesitlilik atamalari - kimlikten turetilir, kosular arasi degismez.
  # Ayri carpanlarla farkli listelerde farkli yerlere dusulur.
  $kimlik = "$($s.id)"
  # 10.08 IKINCI TUR BULGUSU: "sehir GEREKIYORSA" denince model bunu istege
  # bagli okudu ve orijinal soruda gecen sehri (Kocaeli/Bursa - zaten asiri
  # temsil edilen ikisi) korudu; 12 sorunun 2'si de "faaliyet gosteren"
  # kalibini surdurdu. Talimat artik ZORUNLU ve DEGISTIR emri veriyor.
  $cesitTalimati = ("CESITLILIK - BU SORUYA OZEL VE ZORUNLU (istege bagli degil):`n" +
    "  * ACILIS BICIMI: " + $ACILIS[(Kova ($kimlik + 'a')) % $ACILIS.Count] + "`n" +
    "  * SEHIR: orijinal soruda hangi sehir gecerse gecsin, yerine " + $SEHIR[(Kova ($kimlik + 'b')) % $SEHIR.Count] + " kullan.`n" +
    "  * FAALIYET KONUSU: " + $SEKTOR[(Kova ($kimlik + 'c')) % $SEKTOR.Count] + " (orijinalinden farkli olacak)`n" +
    "  * KISI ADI (soruda kisi geciyorsa): " + $ADLAR[(Kova ($kimlik + 'd')) % $ADLAR.Count] + "`n" +
    "  * SIRKET ADINI DEGISTIR: yukaridaki sehir ve sektore uygun, orijinalden`n" +
    "    FARKLI, ozgun bir unvan kur.`n" +
    "  * SU KALIPLAR YASAK (hicbiri gecmeyecek): " + ($YASAK -join ' / ') + "`n" +
    "  * Siklarin uzunlugu birbirinden FARKLI olsun - hepsini ayni boya getirme.`n" +
    "  Sebep: kasadaki sorularin %13'u tek bir cumleyle ('...de faaliyet gosteren')`n" +
    "  basliyor, ilk 13 sehir kalibi toplam %38,7 ve tek bir kisi adi 264 kez`n" +
    "  geciyor. Her soru dogru olsa bile bu tekduzelik metni yapay gosterir.`n`n" +
    "DIL KURALI (bu satir bilerek gercek Turkce ile yazildi):`n" + $KURAL_TR)

  # --- SARTNAME 11, 12, 18-ek: betikten DAGITILIR, modele birakilmaz --------
  # 10.08 olcumu (onay partisi, 10 soru):
  #   madde 11 dogru sik dagilimi  A:4 B:3 C:2 D:1 E:0  -> dengesiz
  #   madde 12 dogru sik en uzun   6/10                 -> aday okumadan bilir
  #   madde 18-ek senaryo tarihi   8/10 soru 2023-2024  -> standart 2025-2026
  # Ucu de "rica" ile duzelmez; oranlar gibi kimlikten atanir.
  $SIK_HARFLERI = @('A','B','C','D','E')
  $hedefHarf = $SIK_HARFLERI[(Kova ($kimlik + 'f')) % 5]
  $hedefYil  = if(((Kova ($kimlik + 'g')) % 2) -eq 0){ '2025' } else { '2026' }
  # 10.08: HARF TALIMATI ISTEMDEN CIKARILDI. Dogru cevabi belli bir harfe
  # koydurmak istem jetonu yakiyor ve modeli kisitliyordu; oysa bu is SAF
  # PERMUTASYON - model serbestce yazsin, siklari SONRA betikle karistiralim.
  # Modele sorunca 10/10 tutuyordu; betikle 3.540/3.540 tutar ve bedava.
  $sartnameTalimati = ("SARTNAME - BU SORUYA OZEL, ZORUNLU:`n" +
    "  * DOGRU SIK EN UZUN SIK OLMAYACAK. Aday sinavda 'en uzunu isaretle'`n" +
    "    kestirmesini kullanir; dogru sik belirgin sekilde uzunsa soru`n" +
    "    okunmadan bilinir. Gerekirse dogru siki kisalt ya da bir celdiriciyi`n" +
    "    daha ayrintili yaz. Bu kural MAKINEYLE denetlenir, ihlal reddedilir.`n" +
    "  * SENARYO TARIHI " + $hedefYil + " YILINDA gececek. Olay tarihlerini bu yila`n" +
    "    tasi. Sebep: bu sorular Kasim 2026 sinavina hazirlanan adaya gidiyor;`n" +
    "    2023 senaryosu ona eski gorunur.")

  $istem = @"
ASAGIDAKI SORUYU YENIDEN YAZ.

--- MEVCUT SORU ---
DERS ETIKETI: $($s.ders)
KONU: $($s.konu)
SORU: $($s.soru)

SIKLAR:
$siklarMetin
ISARETLI DOGRU CEVAP: $($s.dogru)

MEVCUT ACIKLAMA:
$aciklamaMetin

--- KAYNAK METIN (tek dayanagin budur) ---
$kaynak

--- RESMI HESAP PLANI KAYITLARI ---
$thp

$cesitTalimati

$sartnameTalimati

--- HER SORUDA SAGLANACAK SARTLAR (Cem onayli sartnameden) ---
* TEK DOGRU SIK: diger dordu KESIN yanlis olacak. Iki sik birden dogru
  okunabiliyorsa soruyu yeniden kur. (Vaka: uc sikta da 730 hesabi dogruydu.)
* CELDIRICI TURETILEBILIR OLACAK: her yanlis rakam GERCEK bir hata yolundan
  cikmali - atlanan kalem, ters bolme, yanlis oran, maliyete katilmamasi
  gereken kalemi katma gibi. Hicbir hesaptan cikmayan rakam celdirici degil,
  gurultudur.
* GUNCEL MEVZUAT: mulga hukme dayanma. Oranlari ve hadleri guncel kullan
  (KDV %10/%20 gibi). Emin olmadigin bir oran/haddi soruya KOYMA.
* TABLO ILE METIN BIREBIR TUTACAK: tabloya yazdigin her tutar soru kokundeki
  tutarla ayni olacak. (Vaka: tabloda 60.000, metinde 68.000 yaziyordu.)

--- YAPILACAK SEKIZ IS ---
1. HER YANLIS SIK icin adayin nerede yanildigini OGRET; dogru sik icin neden
   dogru oldugunu yaz. Bu soruda kullanacagin anlatim bicimi SUDUR:
      $($ACIKBICIM[(Kova ($kimlik + 'e')) % $ACIKBICIM.Count])
   Bes sikkin acikkmasi ayni ritimde ve ayni uzunlukta OLMASIN.
   OGRETME OZU HER SORUDA BULUNACAK - dort unsur:
     (a) ne soruluyor  (b) dayanak kural  (c) bu olayda nasil isliyor
     (d) adayin akilda tutacagi cikarim
   AMA bunlari BASLIK olarak yazma ("Ne soruluyor:", "Kural:", "Akilda kalsin:"
   gibi sabit basliklar KULLANILMAYACAK) ve "Akilda kalsin" cumlesi metne
   gomulmeyecek - o cikarim zaten ayri `hap` alaninda veriliyor.
   Dort unsur akici bir anlatinin icinde gececek.
   ZORUNLU OZ - UC PARCA (Cem 11.08, guncellendi): her YANLIS sikkin
   aciklamasi UC seyi birden tasiyacak:
     (1) NEDEN YANLIS  - adayin nerede koptugu
     (2) DOGRUSU NE    - dogru tutar / dogru hesap / dogru kural
     (3) AYIRT EDICI KURAL - bu ikisini birbirinden AYIRAN olcut
   UCUNCUSU EN ONEMLISI ve en cok atlanan. "X'e yazilir, Y'ye degil" demek
   BILGIDIR, OGRETME DEGILDIR; aday ezberler, benzer soruda yine sasirir.
     ZAYIF : "Bu tutar 645 hesaba yazilir, 640'a degil."
     DOGRU : "640 Istiraklerden Temettu Gelirleri yalniz istirakten DAGITILAN
              kar payini izler; burada dagitilan kar payi yok, elden cikarilan
              kiymetten dogan FIYAT FARKI var. Satis degeri ile maliyet
              arasindaki olumlu farkin kendi hesabi 645'tir."
   Ikincisi adaya OLCUTU veriyor (dagitilan kar payi mi, satistan dogan fark
   mi) - bunu ogrenen aday ayni aileden butun sorulari cozer.
   Sayisal sorularda ayirt edici kural genellikle FORMULUN kendisidir:
   hangi taban, hangi sure, hangi oran - ve NEDEN o.

   ZORUNLU OZ - PAZARLIKSIZ (Cem 11.08): her YANLIS sikkin aciklamasi
   adayin nerede yanildigini soylemekle YETINMEZ; O OLAYDA DOGRUSUNUN NE
   OLDUGUNU acikca yazar (dogru tutar, dogru hesap, dogru kural). Aday o
   sikki isaretleyip aciklamayi okudugunda dogruyu OGRENMIS olmali.
   AMA bunu "Dogrusu:" gibi sabit bir etiketle yazma - etiket serbest,
   OZ zorunlu. Ornek dogru yazim: "Dogru fark 520.800 - 486.300 = 34.500
   TL'dir." Etiket yok, oz var.
   Olculdu (11.08): onceki kosuda bu oz sikklarin yalnizca %16,3'unde
   teslim edildi - cunku asagidaki SEBEP fikrasi kalibi yasaklarken ozu de
   birlikte goturmustu. Kalip yasagi gecerli, OZ ZORUNLULUGU ONUN USTUNDE.

   SEBEP: mevcut kasada butun aciklamalar tek kalipla ("TUZAK: ... Dogrusu: ...")
   yazilmis ve denetci bunu "yapay zeka kokusu" olarak isaretledi. Ogretmek
   sart, hep AYNI AGIZDAN ogretmek degil: OZ korunur, KALIP kirilir.

   AYRICA "tuzak" ALANINI DOLDUR: her YANLIS sik icin o yanilginin KISA ADI.
   ONCE ASAGIDAKI SOZLUKTE ARA. Uygun bir ad varsa BIREBIR ONU KULLAN
   (kelimesini degistirme, es anlamli yazma). Hicbiri uymuyorsa yeni ad
   oner: 2-5 kelime, kucuk harfle, kusursuz Turkce.
   Sirket adi, sehir, tarih, rakam GECMEYECEK - ad soruya degil YANILGIYA ait.
   DOGRU SIKKIN tuzak alani BOS birakilacak (dogru cevabin tuzagi olmaz).

   (Tuzak sozlugu SISTEM ISTEMINDE - oradan sec. Sozluge girmeyen bir yanilgi
   varsa yeni ad oner.)

   NEDEN SOZLUK: adaya "bu hafta 4 soruda ayni tuzaga dustun" diyebilmek icin
   ayni yanilginin her soruda AYNI adla anilmasi gerekir. Serbest birakilan
   adlarda 39 addan 38'i tekil cikti ve sayilamaz hale geldi.
2. Soru muhasebe kaydi/hesaplama iceriyorsa ACIKLAMAYA TABLO koy. Yevmiye
   kaydinda BORC ve ALACAK ayri sutun olacak. Markdown tablosu kullan.
3. Hesap gerektiren soruda once FORMULU yaz, sonra sayilari yerine koyup
   adim adim coz. Sonucu dogrudan verme, yolu goster.
4. Soruyu cikmis sinav ayarina tasi: kokte en az 5-6 VERI NOKTASI (tutar,
   oran, tarih, adet) olsun. Su an ortalama 3,39; sinav olcusu 5,63.
   ANCAK: veri noktalari DEKOR OLAMAZ. Koyduğun her rakam ya cozumde
   kullanilmali ya da bir celdiricinin dayanagi olmali. Sirf sayiyi
   yukseltmek icin kullanilmayan tutar serpistirme - gercek sinavda
   rakamlar hesaba girer, serpistirilmis rakam soruyu YAPAY gosterir.
   Soru tanim/kavram soruyorsa az veriyle birak, zorla rakam ekleme.
$bicimTalimati
   (5 ve 6 icin karar SANA BIRAKILMADI - yukaridaki talimat baglayicidir.
   Sebep: korpus genelinde bicim dagilimi gercek sinavinkine benzemeli;
   her soru kendi basina dogru olsa bile hepsi ayni kaliba girerse
   TEKDUZELIK olusur. Talimat soruya hic uymuyorsa uygulama ve nedenini
   "uygulanmadi_gerekce" alanina tek cumleyle yaz.)
7. Gecen her hesap kodunun adini RESMI HESAP PLANI KAYITLARINDAKI adla
   birebir hizala. Kaynakta olmayan kodu/adi soruda KULLANMA.
7a. MULGA FIKRA KURALI (Cem 11.08 - PAZARLIKSIZ):
   Kaynak metninde "(Mülga ...)" ile isaretlenmis fikra, cumle ya da bent
   VARSA o kisma DAYANMA. O metin YURURLUKTEN KALKMISTIR; ona dayanan soru
   adaya YURURLUKTE OLMAYAN HUKUK ogretir - yanlis sorudan beterdir.
   Olculdu (11.08): ambardaki 31.350 parcanin 647'sinde (%2,06) mulga
   isareti var ve HEPSI KISMIDIR - madde yururlukte, icindeki bir fikra
   kalkmis. Ornek: AATUHK m.58 "(Mülga ucuncu fikra: 28/1/2010-5951/1 md.)"
   AYRIM: "(Degisik: ...)" MULGA DEGILDIR - o fikra yururluktedir, sadece
   sonradan degistirilmistir. Ambarda 3.163 parcada boyle isaret var ve
   bunlara dayanmak SERBESTTIR.
   Emin degilsen o fikraya hic girme, maddenin yururlukteki bolumune dayan.

7b. KOD-AD CIFTI KURALI (Cem onayi 10.08.2026 - PAZARLIKSIZ):
   Soruda gecen her "kod + hesap adi" cifti, resmi hesap planinda GERCEKTEN
   VAR OLAN bir cift olmali. Bu kural soru kokunde, DOGRU sikta, YANLIS
   sikta, aciklamalarda ve hap kartinda AYNI SEKILDE gecerlidir.
   Celdirici, MUHASEBEDE yanlis olur; ADINDA yanlis olmaz.
     DOGRU celdirici : "657 Reeskont Faiz Giderleri"  (gercek cift, ama bu
                       islemde kullanilmaz - aday bunu bilmeli)
     YASAK celdirici : "657 Karsilik Giderleri"       (657'nin adi bu degil;
                       aday yanlis bir cifti ogrenir)
     YASAK           : "105 Hisse Senetleri"          (105 diye hesap yok)
   Olculdu (10.08): kasada 1.305 soruda bu kural cignenmis; 522'sinde yanlis
   cift soru kokunde ya da DOGRU sikkin metninde/aciklamasinda geciyordu.
   Emin olmadigin kodu hic yazma; hesap adini kodsuz yaz.
8. DERS ETIKETI icerikle uyusmuyorsa dogrusunu yaz (ornegin maliyet
   hesaplamasi sorusuna "Finansal Muhasebe" denmis olabilir).
9. METIN TEMIZ BITECEK. Her alanin SON CUMLESI tam bir cumle olacak ve
   noktayla bitecek. Su uc sey KESINLIKLE olmayacak:
   (a) KENDI DUZELTME NOTUN. Yazdigin bir kelimeden supheye dusersen
       DOGRUSUNU YAZ, notunu birakma. Boyle bir sey cikti:
         "...gozden kacar.gerekir.gerekir yerine: kacar."
       Bu metin adayin onune gidiyor; duzeltme notu metnin parcasi degildir.
   (b) TEKRAR DONGUSU. Ayni kelimeyi ust uste yazma. Boyle bir sey cikti:
         "...yansitilamaz.impaypayi payi payi."
       (Turkce ikilemeler serbesttir: "ayri ayri", "adim adim", "bent bent".)
   (c) YAPISIK CUMLE. Noktadan sonra BOSLUK birak ve BUYUK harfle basla.
       Boyle bir sey cikti: "...aittir.muhasebe mantigi bu ayrimi baglar."
   Cumleyi yarim birakip yenisine baslama; bitiremeyecegin cumleyi hic baslatma.
10. KOK CEVABI ELE VERMEYECEK. Sikklari birbirinden AYIRAN kurali soru
    kokunde yazma. Kural ACIKLAMADA ogretilir, kokte degil.
    Olculdu (11.08): 11 soruda kok, dogru sikki dogrudan veriyordu. Ornek:
      Kok  : "...senetsiz ticari borc dogdugunda 320 alacaklanir, borc
              azaldiginda BORCLANIR; 191'e yapilan duzeltmeler ALACAGINA yazilir."
      Sik B: "320 SATICILAR borclandirilir, 191 INDIRILECEK KDV alacaklandirilir"
    Aday hic muhasebe bilmeden, yalnizca kokU takip ederek B yi buluyordu.
    Ayni ailede "152 alacak, 620 borc kaydedilir" diye baslayan dort soruda
    celdiricilerin yarisi kokle eleniyordu.
    KURAL: kok yalnizca OLAYI anlatir (kim, ne zaman, ne kadar, ne yapti).
    Hangi hesabin hangi yonde calistigi, hangi tanimin gecerli oldugu,
    farkin hangi tarafa yazilacagi ADAYIN BILECEGI seydir - kokte yazmazsin.
    ISTISNA: kural bir ONERME ise ve cevap yine de hesap gerektiriyorsa
    yazilabilir (ornegin "olumsuz fark borca, olumlu alacaga yazilir" deyip
    farkin isaretini adaya hesaplatmak MESRUDUR). Olcut sudur:
    kural cumlesi tek basina bir celdiriciyi olduruyor mu? Olduruyorsa YAZMA.
11. KAYNAK KOTASI - AYNI MADDEYI TEKRAR TEKRAR SORMA. Sana verilen
    kaynaktan en fazla 8 soru uretilir ve her biri FARKLI bir fikrayi ya da
    farkli bir unsuru olcer. Ayni fikranin ayni yuzunu ikinci kez sorma.
    Olculdu (11.08): TTK m.367 den 73, TBK m.82 den 85, VUK m.275 ten 201
    soru yazilmis. Daha kotusu: m.367 nin BILGILENDIRME YUKUMU dort ayri
    soru olarak yazilmis (008ee681, 06b74d9b, 0a9c58bc, 0c086659) - sehir
    adi, tutar ve pay orani disinda AYNI SORU. Ders 219 soru gorunuyor ama
    yalnizca 21 ayri kaynaktan besleniyor; adayin gordugu cesitlilik
    sayidan cok kucuk.
    Bir maddeden ikinci soruyu yaziyorsan kendine sor: "bu, oncekinin ayni
    kuralini baska bir sehirde mi soruyor?" Cevap evetse O SORUYU YAZMA.

Yalnizca su JSON'u dondur, oncesinde/sonrasinda TEK KELIME yazma:
{
  "soru": "yeniden yazilmis soru koku",
  "siklar": {"A":"","B":"","C":"","D":"","E":""},
  "dogru": "A/B/C/D/E",
  "aciklama": {"A":"","B":"","C":"","D":"","E":""},
  "tuzak": {"A":"","B":"","C":"","D":"","E":""},
  "hap": "adayin akilda tutacagi 1-2 cumlelik kural",
  "ders": "icerige gore dogru ders adi",
  "zorluk": "kolay/sinav/zor",
  "veri_noktasi": <kokteki sayi adedi>,
  "cok_ciktili": true/false,
  "olumsuz_kok": true/false,
  "tablo_var": true/false,
  "formul_var": true/false,
  "kullanilan_kaynak": "hangi madde/hesap koduna dayandin",
  "uygulanmadi_gerekce": "uygulanamayan madde varsa tek cumle, yoksa bos"
}
"@
  $istemUzunluk += $istem.Length

  if($kuru){
    Write-Host ("  {0} | {1,-28} | kaynak {2} + THP {3} karakter | istem {4}" -f $kisaId,"$($s.ders)",$kaynak.Length,$thp.Length,$istem.Length)
    continue
  }

  # Opus 5: dusunme VARSAYILAN olarak aciktir; budget_tokens 400 verir.
  # Caba `output_config.effort` icinde, ust duzeyde DEGIL.
  #
  # 10.08 KUSUR VE ONARIMI: ilk kosuda "JSON COZULEMEDI" ciktisi alindi.
  # Sebep tahmin degil yapisal: soruya MARKDOWN TABLO koydurup onu bir JSON
  # dizesinin icine yazdirinca model gercek satir sonu basiyor ve JSON
  # gecersiz oluyor. Istemi "luften kacir" diye zorlamak yerine API'ye
  # SEMA ZORUNLU kilindi (output_config.format) - boylece cevabin gecerli
  # JSON olmasi garanti, ayristirici tahminden cikar.
  $metinAlan = [ordered]@{ type='string' }
  $harfNesnesi = [ordered]@{
    type='object'
    properties=[ordered]@{ A=$metinAlan; B=$metinAlan; C=$metinAlan; D=$metinAlan; E=$metinAlan }
    required=@('A','B','C','D','E'); additionalProperties=$false
  }
  $sema = [ordered]@{
    type='object'
    properties=[ordered]@{
      soru=$metinAlan
      siklar=$harfNesnesi
      dogru=[ordered]@{ type='string'; enum=@('A','B','C','D','E') }
      aciklama=$harfNesnesi
      # 10.08: TUZAK ADI ARTIK VERI. Model tuzagin adini zaten uretiyordu ama
      # duz yazinin icine gomuyordu; makine okuyamiyordu. Ayri alana da
      # yazilinca `cevap_kaydi.secilen` ile birlestirilebiliyor ve adaya
      # KONU degil YANILGI duzeyinde teshis konabiliyor:
      #   "Bu hafta 4 soruda 'KDV'yi maliyete katma' tuzagina dustun."
      # UWorld'un teshisi ders duzeyinde kalir; bu ondan bir kademe ince.
      # Ayrica ayni tuzagi iceren BASKA sorular onerilebilir - yanilgi
      # duzeyinde tedavi. Simdi eklenince zaten odenen kosunun icinde gelir.
      tuzak=$harfNesnesi
      hap=$metinAlan
      ders=[ordered]@{ type='string'; enum=$DERSLER }
      zorluk=[ordered]@{ type='string'; enum=@('kolay','sinav','zor') }
      veri_noktasi=[ordered]@{ type='integer' }
      cok_ciktili=[ordered]@{ type='boolean' }
      olumsuz_kok=[ordered]@{ type='boolean' }
      tablo_var=[ordered]@{ type='boolean' }
      formul_var=[ordered]@{ type='boolean' }
      kullanilan_kaynak=$metinAlan
      uygulanmadi_gerekce=$metinAlan
    }
    required=@('soru','siklar','dogru','aciklama','tuzak','hap','ders','zorluk','veri_noktasi','cok_ciktili','olumsuz_kok','tablo_var','formul_var','kullanilan_kaynak','uygulanmadi_gerekce')
    additionalProperties=$false
  }
  # 10.08 ONBELLEK: sistem istemi + tuzak sozlugu HER cagrida ayni. Onbellege
  # alinirsa o kisim %10 fiyata duser. Sart: onbelleklenen blok istegin EN
  # BASINDA ve BIREBIR AYNI olmali - degisken hicbir sey icermemeli.
  # (Opus 5'te asgari onbelleklenebilir onek 512 jeton; sistem+sozluk bunu asar.)
  $govde = ConvertTo-Json -Depth 12 -InputObject ([ordered]@{
    model = $model
    max_tokens = $enCokJeton
    system = @( [ordered]@{ type='text'; text=$SISTEM_TAM; cache_control=[ordered]@{ type='ephemeral' } } )
    output_config = [ordered]@{
      effort = $caba
      format = [ordered]@{ type='json_schema'; schema=$sema }
    }
    messages = @(@{ role='user'; content=$istem })
  })

  # --- BATCH YOLU: istek simdi gonderilmez, biriktirilir --------------------
  # 3.540 soruyu tek tek gondermek ~60-90 sn/soru = 60-90 SAAT eder. Batch
  # hem paralel hem %50 ucuz. Istem ve baglam saklanir; kapilar sonuc
  # geldiginde AYNI fonksiyondan gecirilir.
  if($batch){
    $batchIsler.Add([pscustomobject]@{
      id="$($s.id)"; kisaId=$kisaId; soru=$s; govde=$govde
      kv=$kv; hedefHarf=$hedefHarf; hedefYil=$hedefYil
      cokCiktiIste=$cokCiktiIste; olumsuzIste=$olumsuzIste
    })
    continue
  }

  $kod = 0; $ham = ''
  for($d=1; $d -le 3; $d++){
    try{
      $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post),($API_TABAN + '/v1/messages')
      $istek.Content = New-Object System.Net.Http.StringContent ($govde,[Text.Encoding]::UTF8,'application/json')
      $cev = $api.SendAsync($istek).GetAwaiter().GetResult()
      $ham = $cev.Content.ReadAsStringAsync().GetAwaiter().GetResult()
      $kod = [int]$cev.StatusCode
      $cev.Dispose(); $istek.Dispose()
      if($kod -lt 300 -or $kod -eq 400){ break }
      if($d -lt 3){ Start-Sleep -Seconds (3*$d) }
    }catch{
      $ham = $_.Exception.Message
      if($d -eq 3){ $kod = 599 } else { Start-Sleep -Seconds (3*$d) }
    }
  }
  if($kod -ge 300){
    $basarisiz++
    $kisa = $ham; if($kisa.Length -gt 200){ $kisa = $kisa.Substring(0,200) }
    Write-Host ("  {0} | HTTP {1} {2}" -f $kisaId,$kod,$kisa)
    continue
  }

  $y = ConvertFrom-Json -InputObject $ham
  $toplamGirdi += [int]$y.usage.input_tokens
  $toplamCikti += [int]$y.usage.output_tokens

  # Dusunme acikken content[0] THINKING blogudur - text blogu ARANIR.
  # content[0].text almak sessizce bos doner; 09.08 tipi sessiz kayip.
  $metin = ''
  foreach($blok in @($y.content)){ if("$($blok.type)" -eq 'text'){ $metin += "$($blok.text)" } }

  $m = [regex]::Match($metin,'(?s)\{.*\}')
  $yeni = $null
  if($m.Success){ try{ $yeni = ConvertFrom-Json -InputObject $m.Value }catch{} }

  $durak = "$($y.stop_reason)"
  if($null -eq $yeni){
    $basarisiz++
    Write-Host ("  {0} | JSON COZULEMEDI (stop={1}, {2} jeton cikti)" -f $kisaId,$durak,$y.usage.output_tokens)
    $sonuc.Add([pscustomobject]@{ id="$($s.id)"; durum='JSON COZULEMEDI'; stop=$durak; hamMetin=$metin })
    continue
  }

  KapiVeKayit $s $yeni $kisaId $durak $y.usage.input_tokens $y.usage.output_tokens $kv $hedefHarf $hedefYil $cokCiktiIste $olumsuzIste
}

# Eski satir ici kapi blogu KapiVeKayit fonksiyonuna tasindi (10.08).
# Asagisi ARTIK CALISMAZ - fonksiyona tasinan kod tekrar etmesin diye
# bilerek erisilemez bir blogun icinde birakilmadi, silindi.

# ============================================================================
#  BATCH ASAMASI - istekler biriktirildi, simdi toplu gonderilir
#  Guvenlik dersleri (profesor-v2'den, ikisi de ~39 USD'ye ogrenildi):
#   * custom_id = SORUNUN KIMLIGI. Sira numarasi kullanmak odenmis partiyi
#     cope attirmisti.
#   * Parti kimligi GONDERILIR GONDERILMEZ bekleyen-partiler.json'a yazilir;
#     kosu duserse sonuc yeniden gonderilmeden hasat edilebilir.
#   * Sonuc govdesi BYTE DIZISI gelebilir; string sanip bolunce her bayt ayri
#     "satir" olur ve odenmis parti cope gider.
# ============================================================================
if($batch -and $batchIsler.Count -gt 0){
  $HDR = $HEDEF.basliklar    # 12.08: hedefe gore x-api-key + version (+ aws'de workspace-id)
  Write-Host ''
  Write-Host ("BATCH: {0} istek, {1}'lik partiler" -f $batchIsler.Count,$partiBoyu)

  # ON KONTROL: anahtar+model tek satirlik istekle sinanir. Parti gonderip
  # 400 yemekten iyidir - birkac jetona mal olur.
  try{
    $dene = @{ model=$model; max_tokens=1; messages=@(@{ role='user'; content='tamam' }) } | ConvertTo-Json -Depth 5
    $ok = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($dene)) -TimeoutSec 60
    Write-Host ("  on kontrol TAMAM - model {0}" -f $ok.model)
  }catch{
    Write-Host ("  ON KONTROL DUSTU: {0}" -f $_.Exception.Message)
    Write-Host '  Parti GONDERILMEDI - para harcanmadi.'
    exit 1
  }

  function BekleyenYaz([string]$bid){
    try{
      $byol = Join-Path $kok 'veri\bekleyen-partiler.json'
      $bek = @()
      if(Test-Path $byol){ foreach($x in (ConvertFrom-Json ([IO.File]::ReadAllText($byol,[Text.Encoding]::UTF8)))){ $bek += "$x" } }
      if($bek -notcontains $bid){ $bek += $bid }
      [IO.File]::WriteAllText($byol, (ConvertTo-Json -InputObject ([object[]]$bek) -Depth 3), (New-Object Text.UTF8Encoding($false)))
    }catch{ Write-Host ("  bekleyen parti yazilamadi: {0}" -f $_.Exception.Message) }
  }

  $cevaplar = @{}
  $partiSayisi = [math]::Ceiling($batchIsler.Count / $partiBoyu)
  for($p=0; $p -lt $partiSayisi; $p++){
    $dilim = @($batchIsler | Select-Object -Skip ($p*$partiBoyu) -First $partiBoyu)
    $istekler = @()
    foreach($i in $dilim){
      # govde zaten tam istek JSON'u; custom_id ile sarmalanir
      $istekler += @{ custom_id = "$($i.id)"; params = (ConvertFrom-Json -InputObject $i.govde) }
    }
    $govdeB = @{ requests = $istekler } | ConvertTo-Json -Depth 20
    Write-Host ("PARTI {0}/{1}: {2} soru ({3:N0} KB)" -f ($p+1),$partiSayisi,$dilim.Count,($govdeB.Length/1024))
    try{
      $b = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages/batches') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govdeB)) -TimeoutSec 600
    }catch{
      Write-Host ("  GONDERIM DUSTU: {0}" -f $_.Exception.Message)
      try{ Write-Host ((New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd()) }catch{}
      throw
    }
    $bid = $b.id
    Write-Host ("  batch id: {0}" -f $bid)
    BekleyenYaz $bid    # ONCE YAZ, SONRA BEKLE

    $tur = 0; $zamanAsimi = $false
    while($true){
      Start-Sleep -Seconds 20
      $tur++
      $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$bid" -Headers $HDR -TimeoutSec 120
      if($tur % 9 -eq 0 -or $st.processing_status -eq 'ended'){ Write-Host ("  durum: {0} ({1} dk)" -f $st.processing_status,[math]::Round($tur/3)) }
      if($st.processing_status -eq 'ended'){ break }
      if($tur -ge 720){ Write-Host ("  ZAMAN ASIMI (4 saat). Kurtarma: bekleyen-partiler.json -> {0}" -f $bid); $zamanAsimi = $true; break }
    }
    if($zamanAsimi){ continue }

    $adres = if($st.results_url){ "$($st.results_url)" } else { "$API_TABAN/v1/messages/batches/$bid/results" }
    $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 900
    $metinB = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
    $satirlar = $metinB -split "`r?`n"
    Write-Host ("  sonuc: {0} satir, {1:N0} KB" -f $satirlar.Count,($metinB.Length/1024))
    foreach($sat in $satirlar){
      if("$sat".Trim().Length -eq 0){ continue }
      try{ $r = $sat | ConvertFrom-Json }catch{ continue }
      $cid = "$($r.custom_id)"
      if($cid.Length -eq 0){ continue }
      $cevaplar[$cid] = $r
    }
  }

  # --- SONUCLARI AYNI KAPILARDAN GECIR --------------------------------------
  Write-Host ''
  Write-Host 'Kapilardan geciriliyor...'
  foreach($i in $batchIsler){
    $r = $cevaplar["$($i.id)"]
    if(-not $r){ $basarisiz++; Write-Host ("  {0} | SONUC GELMEDI" -f $i.kisaId); continue }
    if("$($r.result.type)" -ne 'succeeded'){
      $basarisiz++
      Write-Host ("  {0} | BATCH HATASI: {1}" -f $i.kisaId,"$($r.result.type)")
      $sonuc.Add([pscustomobject]@{ id=$i.id; durum='BATCH HATASI'; tur="$($r.result.type)" })
      continue
    }
    $msj = $r.result.message
    # 10.08: onbellek acildiktan sonra input_tokens YALNIZ onbelleklenmeyen
    # kismi gosterir. cache_read (%10 fiyat) ve cache_creation (%125) ayri
    # alanlarda; saymazsak fatura oldugundan DUSUK gorunur.
    $toplamGirdi += [int]$msj.usage.input_tokens
    $toplamCikti += [int]$msj.usage.output_tokens
    $script:onbellekOkuma += [int]$msj.usage.cache_read_input_tokens
    $script:onbellekYazma += [int]$msj.usage.cache_creation_input_tokens
    # Dusunme acikken content[0] THINKING blogudur - text blogu ARANIR
    $metinY = ''
    foreach($blok in @($msj.content)){ if("$($blok.type)" -eq 'text'){ $metinY += "$($blok.text)" } }
    $mm = [regex]::Match($metinY,'(?s)\{.*\}')
    $yeniY = $null
    if($mm.Success){ try{ $yeniY = ConvertFrom-Json -InputObject $mm.Value }catch{} }
    if($null -eq $yeniY){
      $basarisiz++
      Write-Host ("  {0} | JSON COZULEMEDI (stop={1})" -f $i.kisaId,"$($msj.stop_reason)")
      $sonuc.Add([pscustomobject]@{ id=$i.id; durum='JSON COZULEMEDI'; stop="$($msj.stop_reason)"; hamMetin=$metinY })
      continue
    }
    KapiVeKayit $i.soru $yeniY $i.kisaId "$($msj.stop_reason)" $msj.usage.input_tokens $msj.usage.output_tokens $i.kv $i.hedefHarf $i.hedefYil $i.cokCiktiIste $i.olumsuzIste
  }
}

# --- OZET -------------------------------------------------------------------
$yazilan = @($sonuc | Where-Object { $_.durum -eq 'YAZILDI' })
Write-Host ''
Write-Host '================ BIRLESIK YAZIM OLCUMU ================'
Write-Host ("Model            : {0}  (caba {1}, max_tokens {2})" -f $model,$caba,$enCokJeton)
Write-Host ("Denenen          : {0}" -f $secilen.Count)
Write-Host ("Yazilan          : {0}" -f $yazilan.Count)
Write-Host ("Kaynak yok       : {0}  <- bunlar yeniden yazilamaz, once kaynak eslesmesi gerekir" -f $kaynaksiz)
Write-Host ("Basarisiz        : {0}" -f $basarisiz)

if($kuru){
  Write-Host ("KURU MOD - API'ye dokunulmadi. Ortalama istem uzunlugu: {0} karakter" -f [math]::Round($istemUzunluk/[math]::Max(1,$secilen.Count)))
  exit 0
}

if($yazilan.Count -gt 0){
  $ortGirdi = [math]::Round($toplamGirdi/$yazilan.Count)
  $ortCikti = [math]::Round($toplamCikti/$yazilan.Count)
  Write-Host ''
  Write-Host ("SORU BASINA (gercek, API cevabindan): girdi {0} | cikti {1} jeton" -f $ortGirdi,$ortCikti)
  $tamGirdi = $ortGirdi*30569.0; $tamCikti = $ortCikti*30569.0
  Write-Host ("30.569 SORU ICIN     : girdi {0:N0} | cikti {1:N0} jeton" -f $tamGirdi,$tamCikti)
  # Fiyat: Opus 5 = 5 USD/M girdi, 25 USD/M cikti (referanstan, hafizadan degil)
  $usd = ($tamGirdi/1000000.0*5.0) + ($tamCikti/1000000.0*25.0)
  Write-Host ("TAM KASA TAHMINI     : {0:N0} USD   (Batch %50 ile {1:N0} USD)" -f $usd,($usd/2))
  # Onbellek: okuma %10, yazma %125 fiyatlanir. Bu satirlar olmadan fatura
  # oldugundan DUSUK gorunur - rakam disiplini.
  if(($script:onbellekOkuma + $script:onbellekYazma) -gt 0){
    $obOkuBas = $script:onbellekOkuma / [double]$yazilan.Count
    $obYazBas = $script:onbellekYazma / [double]$yazilan.Count
    $obUsd = ($obOkuBas*30569/1e6*0.5) + ($obYazBas*30569/1e6*6.25)
    Write-Host ("ONBELLEK             : soru basina okuma {0:N0} | yazma {1:N0} jeton" -f $obOkuBas,$obYazBas)
    Write-Host ("  onbellek maliyeti  : {0:N0} USD tam kasa  (Batch ile {1:N0} USD)" -f $obUsd,($obUsd/2))
    Write-Host ("  GERCEK TOPLAM      : {0:N0} USD tam kasa  (Batch ile {1:N0} USD)" -f ($usd+$obUsd),(($usd+$obUsd)/2))
    $bin = 3540.0
    Write-Host ("  3.540 SORU ICIN    : {0:N0} USD (Batch)" -f ((($usd+$obUsd)/2) * $bin / 30569.0))
  }
  Write-Host '  Not: bu YALNIZ yeniden yazim. Uc mercekli denetim AYRI kalemdir.'
  Write-Host ''
  Write-Host 'SINAV BENZERLIGI - yazilan sorularda:'
  $ortVeri = [math]::Round((($yazilan | Measure-Object veriNoktasi -Average).Average),2)
  $cc = [math]::Round(100.0*@($yazilan | Where-Object { $_.cokCiktili -eq $true }).Count/$yazilan.Count,1)
  $ok = [math]::Round(100.0*@($yazilan | Where-Object { $_.olumsuzKok -eq $true }).Count/$yazilan.Count,1)
  $tb = [math]::Round(100.0*@($yazilan | Where-Object { $_.tabloVar -eq $true }).Count/$yazilan.Count,1)
  $fm = [math]::Round(100.0*@($yazilan | Where-Object { $_.formulVar -eq $true }).Count/$yazilan.Count,1)
  Write-Host ("  veri noktasi : {0}   (onceki 3,39 | sinav 5,63)" -f $ortVeri)
  Write-Host ("  cok ciktili  : %{0}  (onceki %0,4 | sinav %6,7)" -f $cc)
  Write-Host ("  olumsuz kok  : %{0}  (onceki %2,5 | sinav %17-30)" -f $ok)
  Write-Host ("  tablo        : %{0}" -f $tb)
  Write-Host ("  formul       : %{0}" -f $fm)
  $dersDegisen = @($yazilan | Where-Object { $_.eskiDers -ne $_.yeniDers })
  Write-Host ("  ders etiketi duzeltilen: {0}/{1}" -f $dersDegisen.Count,$yazilan.Count)
  $kesik = @($yazilan | Where-Object { $_.stop -eq 'max_tokens' })
  if($kesik.Count -gt 0){ Write-Host ("  !! {0} cevap max_tokens'a takildi - enCokJeton artirilmali" -f $kesik.Count) }
  # TALIMATA UYUM: oran artik betikten dagitiliyor; model uyuyor mu?
  $ccIstendi = @($yazilan | Where-Object { $_.istenenCokCikti })
  $ccYasak   = @($yazilan | Where-Object { -not $_.istenenCokCikti })
  $okIstendi = @($yazilan | Where-Object { $_.istenenOlumsuz })
  Write-Host ''
  Write-Host 'TALIMATA UYUM (oran betikten dagitildi):'
  if($ccIstendi.Count -gt 0){ Write-Host ("  cok ciktili ISTENDI {0} -> uyan {1}" -f $ccIstendi.Count, @($ccIstendi | Where-Object { $_.cokCiktili -eq $true }).Count) }
  if($ccYasak.Count -gt 0){   Write-Host ("  cok ciktili YASAK   {0} -> yine de yapan {1}  <- sifir olmali" -f $ccYasak.Count, @($ccYasak | Where-Object { $_.cokCiktili -eq $true }).Count) }
  if($okIstendi.Count -gt 0){ Write-Host ("  olumsuz kok ISTENDI {0} -> uyan {1}" -f $okIstendi.Count, @($okIstendi | Where-Object { $_.olumsuzKok -eq $true }).Count) }
  $dersDisi = @($yazilan | Where-Object { $DERSLER -notcontains $_.yeniDers })
  Write-Host ("  ders listesi disina cikan: {0}  <- sifir olmali (sema enum'u)" -f $dersDisi.Count)
  Write-Host ''
  Write-Host 'SARTNAME 11-12-18 (betikten dagitildi):'
  Write-Host ("  hedef harfe uyan     : {0}/{1}" -f @($yazilan | Where-Object { $_.harfTuttu }).Count, $yazilan.Count)
  Write-Host '  DOGRU SIK HARF DAGILIMI:'
  foreach($hh in 'A','B','C','D','E'){
    $ad = @($yazilan | Where-Object { "$($_.yeniDogru)".Trim().ToUpperInvariant() -eq $hh }).Count
    Write-Host ("     {0}: {1}" -f $hh,$ad)
  }
  $uzunIhlal = @($yazilan | Where-Object { $_.dogruUzunluk -eq $_.enUzunSik })
  Write-Host ("  dogru sik en uzun    : {0}/{1}  (onceki olcum 6/10)" -f $uzunIhlal.Count, $yazilan.Count)
  $eskiYil = @($yazilan | Where-Object { $_.yeniSoru -match '\b202[0-4]\b' -and $_.yeniSoru -notmatch '\b202[56]\b' })
  Write-Host ("  senaryosu 2025 oncesi: {0}/{1}  (onceki olcum 8/10)" -f $eskiYil.Count, $yazilan.Count)
  Write-Host ''
  Write-Host 'TUZAK SOZLUGU BENIMSEME:'
  $tuzakTop = $script:tuzakSozluktenAd + $script:tuzakYeniAd
  $oranSoz = 0
  if($tuzakTop -gt 0){ $oranSoz = [math]::Round(100.0*$script:tuzakSozluktenAd/$tuzakTop,1) }
  Write-Host ("  sozlukten secilen : {0}/{1}  (%{2})   <- yuksek olmali" -f $script:tuzakSozluktenAd,$tuzakTop,$oranSoz)
  Write-Host ("  yeni ad onerisi   : {0}" -f $script:tuzakYeniAd)
  Write-Host ("  yazimi hizalanan  : {0}  (ASCII -> sozluk yazimi)" -f $script:tuzakHizalanan)
  if($script:yeniTuzakAdlari.Count -gt 0){
    Write-Host '  YENI ONERILER (sozluge eklenecek):'
    foreach($ya in ($script:yeniTuzakAdlari | Group-Object | Sort-Object Count -Descending)){
      Write-Host ("     {0}x  {1}" -f $ya.Count,$ya.Name)
    }
  }
}

# 10.08: onceki surumde bu yol SABITTI ve -cikti parametresi YOKTU; ikinci tur
# birinci turun metinlerini sessizce ezdi. Artik disaridan verilebiliyor.
$cikti = if($ciktiYolu -ne ''){ $ciktiYolu } else { Join-Path $kok 'veri\birlesik-yazim-olcum.json' }
$ozet = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; caba=$caba
  denenen=$secilen.Count; yazilan=$yazilan.Count; kaynakYok=$kaynaksiz; basarisiz=$basarisiz
  toplamGirdiJeton=$toplamGirdi; toplamCiktiJeton=$toplamCikti
  not='OLCUM PARTISI - kasaya yazilmadi. Jetonlar API cevabindan birebir. Tam metinler asagida: rapora degil SORULARA bakilir.'
  kayit=$sonuc
}
[IO.File]::WriteAllText($cikti, ($ozet | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("Tam metinler: {0}" -f $cikti)
Write-Host 'SIRADAKI KAPI: bu dosyadan soru OKUNACAK. Sayi yeterli degil.'
