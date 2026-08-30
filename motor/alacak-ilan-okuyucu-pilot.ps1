# ============================================================================
#  ALACAK ILANI OKUYUCU - PILOT  (29.08.2026)
#
#  CEM'IN TESHISI (28.08 gecesi): "bu yazanlari tek tek okusak daha dogru karar
#  vermez miyiz - boyle parcali parcali bakiyorsun ve olmuyor."
#  HAKLI VE KANITI VAR: o gun regex hatti ALTI kez curudu, altisi da ayni
#  kokten - ilanin ANLAMINI kelime kalibindan cikarmaya calismak.
#    "kaldirilmasi + iflas"  -> iki ZIT olayi birden esledi
#    "reddini isteyebilecek" -> muhlet ilanini ret sandi (20.08'de de ayni)
#    Bursa yaziyor, Istanbul yazmiyor -> ayni olay iki ayri kovada
#  Bir insan bu basliklari okusa bir saniyede ayirir.
#
#  BU BETIK NE YAPAR: 4 tartismali kovadan ornek ilan alir, MODELE OKUTUR ve
#  regex damgasiyla KARSILASTIRIR. Amac etiketlemek degil, "okuma regex'ten
#  iyi mi, ne kadar iyi" sorusunu OLCMEK. Iyi cikarsa yon degisir; kotu
#  cikarsa bunu da olcmus oluruz ve regex'e serhle devam ederiz.
#
#  UC TASARIM KARARI:
#   1) DAR SORU. "Etiketle" demiyoruz; 6 secenekli tek soru soruyoruz.
#   2) ZORUNLU ALINTI. Model kararin gectigi cumleyi AYNEN yazmali. Kaynagini
#      gosteremeyen cevap SAYILMAZ - regex'i de ayni sinavdan gecirdik.
#   3) KISISEL VERI MASKESI. Ilan metni TCKN icerir. Dis servise gitmeden ONCE
#      11 haneli sayilar maskelenir. Bkz [[guvenlik-17-07-2026]]
#
#  HAT: once GEMINI (bedava kota, 0 maliyet) -> hata/kota olursa HAIKU.
#  Boylece pilot ANTHROPIC TAVANINA dokunmadan kosar (bkz api-tavan-engeli).
#
#  Env: SUPABASE_SERVICE_KEY (sart) · GEMINI_API_KEY ve/veya ANTHROPIC_API_KEY
#  Ayar: ADET (varsayilan 100)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$URL  = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'https://bjrleanjpyujtajmazxn.supabase.co' }
$KEY  = $env:SUPABASE_SERVICE_KEY
$ADET = if ($env:ADET) { [int]$env:ADET } else { 100 }

if (-not $KEY) { Write-Host "KOR: SUPABASE_SERVICE_KEY yok - pilot KOSULAMADI (sifir sonuc degil)."; exit 0 }
if (-not $env:GEMINI_API_KEY -and -not $env:ANTHROPIC_API_KEY) {
  Write-Host "KOR: ne GEMINI_API_KEY ne ANTHROPIC_API_KEY var - okuma hatti yok."; exit 0
}

# --- 4 tartismali kovadan dengeli ornek ------------------------------------
# 29.08 OLCULDU: 4 kovada metinli ilan 746, ortalama 1.227 karakter, toplam
# 916 bin karakter (~305 bin token girdi). Gemini bedava kotasiyla 0 TL, Haiku'ya
# duserse 1 dolardan az. Yani MALIYET KARAR VERICI DEGIL - orneklemi kucuk
# tutmanin bir sebebi yok. HEPSI=1 ile 4 kovanin TAMAMI okunur.
# 29.08: ret_kaldirma ayristirilinca iki kova daha dogdu (feragat 145,
# muhlet_kaldirma 21). Pilot onlari OKUMUYORDU - yani yeni ayrimin dogru olup
# olmadigi hic olculmemis oluyordu.
$KOVALAR = @('ret_kaldirma','ret_iflas','tasdik','iflas_kaldirma','feragat','muhlet_kaldirma')
# 29.08 - TUM ARSIV MODU. Bugune kadar yalniz 6 "tartismali" kova okundu (743
# ilan = arsivin %13'u). Kalan ~5.170 ilanin damgasi hala YALNIZ regex'ten
# geliyor ve ayni gun regex 99 ayrismanin 70'inde yanildi. KOVALAR env ile
# ozel liste verilebilir (virgullu); TUM=1 ise butun karar durumlari okunur.
if ($env:KOVALAR) {
  $KOVALAR = @($env:KOVALAR -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  Write-Host ("KOVA LISTESI env'den: {0}" -f ($KOVALAR -join ', '))
} elseif ($env:TUM -eq '1') {
  $KOVALAR = @('kesin_muhlet','gecici_muhlet','uzatma','ret_kaldirma','diger','alacak_cagrisi',
               'durusma','iflas_tasfiye','feragat','ret_iflas','muhlet','tasdik',
               'muhlet_kaldirma','iflas_kaldirma')
  Write-Host "TUM ARSIV MODU: 14 karar durumu okunacak (~5.900 ilan)."
}
$perKova = if ($env:HEPSI -eq '1') { 1000 } else { [Math]::Max(1, [int]($ADET / $KOVALAR.Count)) }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')

$ilanlar = @()
foreach ($k in $KOVALAR) {
  $u = "$URL/rest/v1/alacak_ilan?select=ilan_no,baslik,il,tur,karar_durumu,metin,tarih" +
       "&tarih=gte.$bas&karar_durumu=eq.$k&metin=not.is.null&order=tarih.desc&limit=$perKova"
  # 29.08 KUSUR: burada Invoke-RestMethod kullaniliyordu ve donen JSON dizisi
  # DUZLESMIYORDU - her kova TEK nesneye sarilip alanlari dizi oluyordu
  # ("Orneklem: 4 ilan", regex_damgasi = 644 elemanli dizi). Sonuc: modele 644
  # ilanin metni BIRLESIK gitti ve karsilastirma dizi-ile-metin kiyasi yapip
  # uyumu %0 gosterdi. Invoke-WebRequest + ConvertFrom-Json + @() ile garanti
  # altina alindi; ayrica kova basina KAC satir geldigi BASILIR (sessiz
  # kucultme bir daha fark edilmeden gecmesin).
  # 29.08 SESSIZ KESILME: tum arsiv kosusunda kesin_muhlet 1000, gecici_muhlet
  # 1000 geldi - gercekte 1.349 ve 1.104. PostgREST tavani sayfalamayi 1.000'de
  # kesti ve rapor bunu SESSIZCE gecti (kova basina satir basiliyordu ama
  # BEKLENEN sayiyla karsilastirilmiyordu). 453 ilan hic okunmadi.
  # Cozum: Range header ile sayfala + her kova icin cekilen sayiyi BEKLENENLE
  # karsilastir; eksikse ACIKCA uyar.
  # 29.08 IKI DENEME, IKI KUSUR:
  #  (1) limit/offset -> PostgREST 1.000'de SESSIZCE kesti (kesin_muhlet 1.349
  #      yerine 1.000 geldi, 453 ilan hic okunmadi).
  #  (2) Range header -> .NET "The format of value '0-199' is invalid" dedi ve
  #      14 kovanin HEPSI cekilemedi (kosu 0 ilanla bitti; oz-sinav durdurdu,
  #      sessiz gecmedi).
  # COZUM: KEYSET sayfalama - ilan_no'ya gore sirala, her turda "son gorulen
  # ilan_no'dan buyuk olanlar"i iste. Tavan yok, offset yok, ozel header yok.
  try {
    $onceki = $ilanlar.Count
    $son = ''; $adim = 200; $tur = 0
    while ($true) {
      $uu = "$URL/rest/v1/alacak_ilan?select=ilan_no,baslik,il,tur,karar_durumu,metin,tarih" +
            "&tarih=gte.$bas&karar_durumu=eq.$k&metin=not.is.null" +
            "&order=ilan_no.asc&limit=$adim"
      if ($son) { $uu += "&ilan_no=gt.$son" }
      $ham  = Invoke-WebRequest -Method Get -Uri $uu -Headers $H -TimeoutSec 300
      $rows = @($ham.Content | ConvertFrom-Json)
      if (-not $rows.Count) { break }
      foreach ($row in $rows) { $ilanlar += $row }
      $son = "$($rows[-1].ilan_no)"
      $tur++
      if ($rows.Count -lt $adim) { break }
      if ($tur -gt 100) { Write-Host "  UYARI: 100 sayfa freni devreye girdi"; break }
    }
    Write-Host ("  {0,-16} {1,4} ilan" -f $k, ($ilanlar.Count - $onceki))
  }
  catch { Write-Host ("  '{0}' kovasi cekilemedi: {1}" -f $k, $_.Exception.Message) }
}
if (-not $ilanlar.Count) { Write-Host "KOR: 0 ilan cekildi - olcum guvenilmez."; exit 0 }
Write-Host ("Orneklem: {0} ilan ({1} kova)" -f $ilanlar.Count, $KOVALAR.Count)

# --- KISISEL VERI MASKESI (dis servise gitmeden once) -----------------------
# 11 haneli sayi = TCKN adayi. VKN 10 hanedir, o KALIR (tuzel kisi, kamuya acik).
function Maskele([string]$m) {
  if (-not $m) { return '' }
  $m = [regex]::Replace($m, '(?<!\d)\d{11}(?!\d)', '[TCKN]')
  if ($m.Length -gt 6000) { $m = $m.Substring(0, 6000) }   # jeton freni
  return $m
}

$SORU = @'
Asagida Turkiye'de bir mahkeme/daire tarafindan yayimlanmis resmi ilanin metni var.
TEK SORU: Bu ilanda mahkeme NE KARAR VERDI?

Cevabini asagidaki ETIKETLERDEN BIRINI AYNEN yazarak ver.

MUHLET AILESI (konkordato sureci DEVAM EDIYOR):
  GECICI_MUHLET    - GECICI muhlet verdi (ilk muhlet - IIK m.287; genelde 3+2 ay)
  KESIN_MUHLET     - KESIN muhlet verdi (IIK m.289; genelde 1 yil)
  UZATMA           - mevcut muhletin SURESINI uzatti (gecici ya da kesin)
  MUHLET_BELIRSIZ  - muhlet verdi ama metinde GECICI mi KESIN mi yazmiyor

SUREC BITTI:
  TASDIK           - konkordatoyu TASDIK etti (basarili sonuclandi)
  RET              - konkordato talebini REDDETTI - iflas karari YOK
  RET_IFLAS        - talebi reddetti VE borclunun IFLASINA karar verdi
                     (IIK m.292 ile kesin muhlet icinde iflas da buraya girer)
  FERAGAT          - borclu davadan FERAGAT etti (KENDI vazgecti); mahkeme
                     konkordatoyu incelemedi, dava feragatle sona erdi
  MUHLET_KALDIRMA  - konkordato MUHLETINI kaldirdi/sonlandirdi - ret de iflas
                     da tasdik de DEGIL
  IFLAS_KALDIRMA   - daha once verilmis IFLASI KALDIRDI, borclu iflastan
                     CIKIYOR (IIK m.182)

USUL ILANLARI (mahkeme yeni bir esas karar vermiyor, duyuru yapiyor):
  ALACAK_CAGRISI   - alacaklilardan alacaklarini bildirmesi/kaydettirmesi
                     isteniyor (IIK m.299 ya da m.219)
  DURUSMA          - DURUSMA/TOPLANTI GUNU bildiriliyor
  IFLAS_TASFIYE    - sira cetveli, tasfiyenin tatili, masa islemi, iflasin
                     kapanmasi - devam eden bir iflas surecinin islem ilani

  HICBIRI          - yukaridakilerden hicbiri

DIKKAT - MUHLET ILANLARINDA EN SIK HATA (30.08 olcumu):
Bir konkordato ilani genelde SURECIN TAMAMINI anlatir:
  "...once 3 AY GECICI MUHLET verilmisti, ... simdi 1 YIL KESIN MUHLET
   verilmesine karar verilmistir."
Sen ILANIN DUYURDUGU ASIL/SON karari sec - metinde gecen ILK karari DEGIL.
Baslik da ipucu verir ama tek basina yeterli degildir; metindeki EN SON
hukum cumlesine bak. ALINTI da o karari gostermeli.

ETIKET ILE ALINTI AYNI SEYI SOYLEMELI (30.08 olcumu - 222 ilanda bozuldu):
Alintiladigin cumlede "KESIN muhlet" yaziyorsa etiket KESIN_MUHLET olur;
"GECICI muhlet" yaziyorsa GECICI_MUHLET olur. Once alintiyi sec, sonra o
alintinin soyledigi etiketi yaz. Alinti bir sey, etiket baska sey OLAMAZ.

DIKKAT - en sik karistirilan UC ayrim:
1) MUHLET_KALDIRMA ile IFLAS_KALDIRMA AYNI SEY DEGILDIR. Muhlet konkordato
   surecine aittir; iflasin kaldirilmasi ayri bir hukumdur.
2) Muhlet kaldirilmasinin SEBEBI tasdik ise cevap TASDIK'tir.
3) "FERAGAT NEDENIYLE reddine" cevabi FERAGAT'tir, RET DEGILDIR: karari
   mahkeme degil BORCLU verdi.

Yalniz su iki satiri yaz, baska hicbir sey yazma:
KARAR: <etiket>
ALINTI: <karari gecen cumleyi metinden AYNEN kopyala>

ALINTI ZORUNLUDUR. Metinde karari acikca soyleyen bir cumle BULAMIYORSAN
etiket olarak HICBIRI yaz ve ALINTI satirina YOK yaz. Kararini metne
dayandiramadigin bir etiket SECME.

--- ILAN BASLIGI ---
{BASLIK}
--- ILAN METNI ---
{METIN}
'@

$script:gkey = $env:GEMINI_API_KEY
$script:sayacGemini = 0; $script:sayacHaiku = 0; $script:sayacHata = 0; $script:geminiGecici = 0
$script:geminiSebep = $(if ($env:GEMINI_API_KEY) { '' } else { 'GEMINI_API_KEY tanimli degil' })

# 29.08 OLCULDU: 'gemini-2.0-flash' uc noktasi HTTP 404 doner - model adi artik
# gecerli degil. Ayni URL motor/toplu-uret.ps1 ve motor/gece-ajani.ps1 icinde de
# duruyor; oralarda da sessizce Haiku'ya dusuyor ve bedava kota kullanilmiyor.
# Model adini SABIT yazmak yerine ADAYLARI SIRAYLA SINAYIP calisani kilitliyoruz:
# uc nokta bir daha degistiginde hat kendini onarir ve hangi modeli kullandigini
# ACIKCA raporlar. (Bkz. bugunku "sessiz dusus" dersi.)
$GEMINI_ADAYLAR = @('gemini-2.0-flash','gemini-2.5-flash','gemini-flash-latest',
                    'gemini-2.0-flash-001','gemini-1.5-flash')
$script:gmodel = $null
function GeminiCagir([string]$model, [string]$istem) {
  $b = @{ contents = @(@{ parts = @(@{ text = $istem }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -TimeoutSec 90 `
       -Uri ("https://generativelanguage.googleapis.com/v1beta/models/$model" + ":generateContent?key=" + $script:gkey) `
       -Body ([Text.Encoding]::UTF8.GetBytes($b)) -ContentType 'application/json'
  return (@($r.candidates[0].content.parts) | ForEach-Object { $_.text }) -join ''
}
function Sor([string]$istem) {
  if ($script:gkey) {
    try {
      if (-not $script:gmodel) {
        # ILK CAGRI = SINAMA. Adaylar sirayla denenir, calisan kilitlenir.
        # 29.08 IKINCI KUSUR: sinama dongusu 503'u "model gecersiz" sayip adayi
        # ELIYORDU. Oysa 'gemini-flash-latest' 30 dk once CALISMISTI - model
        # dogruydu, servis mesguldu. Sonuc: bes aday da elendi, hat kapandi,
        # 743 istek Haiku'ya gitti. Gecici hatada aday ELENMEZ, kisa bekleyip
        # UC KEZ denenir; ancak KALICI hata (404/400/401/403) adayi eler.
        foreach ($aday in $GEMINI_ADAYLAR) {
          $elendi = $false
          for ($deneme = 1; $deneme -le 3 -and -not $elendi; $deneme++) {
            try {
              $t = GeminiCagir $aday $istem
              $script:gmodel = $aday
              Write-Host ("  GEMINI MODELI SECILDI: {0}" -f $aday)
              $script:sayacGemini++
              return $t
            } catch {
              $mm = "$($_.Exception.Message)"
              $kisa = $mm.Substring(0, [Math]::Min(70, $mm.Length))
              if ($mm -match '\b(503|429|500|502|504|timed out|timeout)\b') {
                Write-Host ("  gemini '{0}' gecici hata (deneme {1}/3): {2}" -f $aday, $deneme, $kisa)
                Start-Sleep -Seconds (3 * $deneme)
              } else {
                Write-Host ("  gemini adayi '{0}' ELENDI (kalici): {1}" -f $aday, $kisa)
                $elendi = $true
              }
            }
          }
        }
        throw "hicbir gemini model adayi calismadi"
      }
      $t = GeminiCagir $script:gmodel $istem
      $script:sayacGemini++
      $script:geminiGecici = 0   # basarili cagri gecici hata sayacini sifirlar
      return $t
    } catch {
      # 29.08 KUSUR: eski kod YALNIZ 429'da mesaj basiyordu; baska hatada Gemini
      # SESSIZCE dusuyordu. Ilk kosuda "gemini 0 · haiku 746" cikti ve NEDEN
      # oldugunu bilemedik - kendi kor kalma kuralimi kendi betigimde ihlal
      # etmisim. Artik hata NE OLURSA OLSUN bir kez ACIKCA basilir ve sebebi
      # ozette de tekrarlanir.
      $m = "$($_.Exception.Message)"
      $script:geminiSebep = $m.Substring(0, [Math]::Min(160, $m.Length))
      # 29.08 OLCULDU: model secildikten SONRA 503 (Service Unavailable) geldi ve
      # eski kod hatti TAMAMEN kapatti. 503/429/500 GECICIDIR - kalici kapatmak
      # bedava kotayi bir tek sarsintiya kurban eder. Gecicide sayac artar,
      # esik asilirsa kapatilir; 404/401/403 gibi KALICI hatada aninda kapanir.
      if ($m -match '\b(503|429|500|502|504|timed out|timeout)\b') {
        $script:geminiGecici++
        Write-Host ("  gemini gecici hata ({0}/5): {1}" -f $script:geminiGecici, $script:geminiSebep)
        if ($script:geminiGecici -ge 5) {
          Write-Host "  gemini 5 kez ust uste gecici hata verdi -> Haiku'ya donuluyor."
          $script:gkey = $null
        }
      } else {
        Write-Host ("  GEMINI KALICI HATA -> Haiku'ya donuluyor. Sebep: {0}" -f $script:geminiSebep)
        $script:gkey = $null
      }
    }
  }
  if ($env:ANTHROPIC_API_KEY) {
    try {
      $AH = @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' }
      $b = @{ model = 'claude-haiku-4-5-20251001'; max_tokens = 300
              messages = @(@{ role = 'user'; content = $istem }) } | ConvertTo-Json -Depth 6 -Compress
      $r = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $AH `
           -Body ([Text.Encoding]::UTF8.GetBytes($b)) -ContentType 'application/json' -TimeoutSec 90
      $script:sayacHaiku++
      return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ''
    } catch { $script:sayacHata++ }
  }
  return $null
}

# Regex damgasi ile okuma cevabinin KARSILIGI
# 30.08 MUHLET AILESI BOLUNDU. Tum arsiv turunda 163 ilan "belirsiz hedef"
# diye ATLANDI cunku (a) tek secenekti ve DORT kovaya birden isaret ediyordu -
# okuma "muhlet verdi" diyordu ama hangisi oldugunu soyleyemiyordu, damga
# yazilamiyordu. Simdi her mühlet turu KENDI secenegini tasiyor; (n) de var:
# metinde gercekten belirsizse model onu secer ve 'muhlet' kovasinda kalir -
# "emin degilsen yazma" kurali secenegin KENDISINE gomuldu.
# Ayrica (g) tek hedefe indirildi: model "muhleti kaldirdi" diyorsa ve ret
# demiyorsa hedef muhlet_kaldirma'dir; ret varsa zaten (b) der.
#
# 30.08 UCUNCU OLCUM - HARF KODLAMASI KALDIRILDI. Ikinci muhlet olcumunde
# kesin_muhlet uyumu %71'de CAKILI KALDI. Sebebi "ilk karar/son karar" tuzagi
# SANDIM, istem uyarisi ekledim, HICBIR SEY DEGISMEDI (%71 -> %71). Artefakti
# acip alinti ile cevabi karsilastirinca gercek sebep cikti:
#     alinti "1 YILLIK KESIN MUHLET VERILMESINE" · cevap (a) gecici muhlet
#     alinti "kesin muhlet kararinin kaldirilmasina" · cevap (d) iflas kaldirma
# 152 kesin_muhlet + 70 gecici_muhlet = 222 ilanda model DOGRU cumleyi
# aliniyor, sonra YANLIS HARFI isaretliyordu. Bu okuma hatasi degil; 14
# secenegi a-n harflerine dagitan LISTENIN kusuru. Kovalar 8'den 14'e
# cikarken yeni secenekler (l)(m)(n) listenin SONUNA eklenmisti; "kesin
# muhlet" 12. harfte, "gecici muhlet" 1. harfte kaldi.
# COZUM: harf araciligi tamamen kaldirildi - model artik etiketin KENDISINI
# yaziyor (KESIN_MUHLET). Bir de kapi kondu: etiket ile alinti celisirse
# cevap OLCUME GIRMEZ (bkz. CelisikMi).
# DERS: bir modele "sec" dedigin listede secenegin ADI ile KODU arasinda
# ceviri varsa, olctugun sey anlama degil ceviriye sadakattir.
$ESLESME = @{ 'GECICI_MUHLET' = @('gecici_muhlet')
              'KESIN_MUHLET' = @('kesin_muhlet')
              'UZATMA' = @('uzatma')
              'MUHLET_BELIRSIZ' = @('muhlet')
              'RET' = @('ret_kaldirma'); 'RET_IFLAS' = @('ret_iflas')
              'IFLAS_KALDIRMA' = @('iflas_kaldirma'); 'TASDIK' = @('tasdik')
              # 29.08: (g) muhletin kaldirilmasi. Ilk kosuda okuma bunu UC KEZ
              # (d) iflasin kaldirilmasi sandi - iki ayri hukum. Kendi secenegi
              # verildi. Damga tarafinda artik AYRI kova var (muhlet_kaldirma),
              # ama ret ile BIRLIKTE gecen ilanlar ret_kaldirma'da kalir -
              # ikisi de kabul edilir.
              'MUHLET_KALDIRMA' = @('muhlet_kaldirma')
              # 29.08: (h) feragat - borclu KENDI vazgecti. Onceki kosularda bu
              # secenek YOKTU ve model feragat ilanlarini (b) ret ya da (f)
              # hicbiri diyordu; yani yeni ayrim olculemiyordu.
              # 29.08 UCUNCU KEZ AYNI HATA: kovalar genisletildi (14'e), SORU
              # genisletilmedi. Tum arsiv kosusunda dort kova %0 uyum verdi -
              # alacak_cagrisi 0/507, diger 0/301, durusma 0/245,
              # iflas_tasfiye 0/48 - cunku model dogru cevabi VEREMIYORDU,
              # secenek yoktu. 1.101 ilan olculemez bir soruyla sinandi.
              'FERAGAT' = @('feragat')
              'ALACAK_CAGRISI' = @('alacak_cagrisi')
              'DURUSMA' = @('durusma')
              'IFLAS_TASFIYE' = @('iflas_tasfiye')
              'HICBIRI' = @('diger') }

# --- ETIKET ile ALINTI CELISIYOR MU? (30.08 - 222 ilanlik kusurun kapisi) ----
# Model dogru cumleyi alinip yanlis etiketi yazabiliyor. Alintida "KESIN
# MUHLET" gecerken etiket GECICI_MUHLET ise bu cevap bir OLCUM DEGIL, gurultu.
# Kapi yalniz METINDE ACIKCA AYRISAN durumlarda konusur (kesin/gecici/uzatma);
# emin olamadigi yerde SUSAR - yanlis pozitif uretmez.
function CelisikMi([string]$etiket, [string]$alinti) {
  if (-not $alinti) { return $false }
  # 30.08 OZ-SINAVDA YAKALANDI: ToLower() MAKINENIN KULTURUNE bagli. tr-TR
  # makinede "KESIN" -> "kesın" (noktasiz i) olur ve 'kesin' arayan regex
  # ISKALAR - kapi sessizce hicbir sey yakalamaz. Runner en-US oldugu icin
  # canlida calisirdi, yerelde calismazdi; boyle bir kapiya guvenilmez.
  # Once ASCII'ye katla, SONRA kulturden bagimsiz kucult.
  $a = $alinti.Replace('İ','I').Replace('ı','i').Replace('Ş','S').Replace('ş','s').
       Replace('Ğ','G').Replace('ğ','g').Replace('Ü','U').Replace('ü','u').
       Replace('Ö','O').Replace('ö','o').Replace('Ç','C').Replace('ç','c').ToLowerInvariant()
  # OZ-SINAVDA YAKALANDI: "once 3 ay gecici sonra 1 yil kesin muhlet verilen
  # borclunun alacaklilari..." cumlesinde iki kelime de var ama yalniz 'kesin'
  # muhlete bitisik - kapi bunu celiski sandi ve MESRU bir ALACAK_CAGRISI
  # cevabini olcumden atacakti. Kapinin isi kusuru yakalamak, olcum tabanini
  # eritmek degil: HER IKI kelime de geciyorsa cumle sureci ANLATIYOR demektir,
  # kapi susar ve karari hakeme birakir.
  if (($a -match 'kesin') -and ($a -match 'gecici')) { return $false }
  $kesin  = [bool]($a -match 'kesin\s+(konkordato\s+)?(muhlet|mehil|mehli)')
  $gecici = [bool]($a -match 'gecici\s+(konkordato\s+)?(muhlet|mehil|mehli)')
  if ($kesin -and -not $gecici -and $etiket -ne 'KESIN_MUHLET'  -and $etiket -ne 'UZATMA' -and
      $etiket -ne 'MUHLET_KALDIRMA') { return $true }
  if ($gecici -and -not $kesin -and $etiket -ne 'GECICI_MUHLET' -and $etiket -ne 'UZATMA' -and
      $etiket -ne 'MUHLET_KALDIRMA') { return $true }
  return $false
}

# --- CELISKI KAPISININ OZ-SINAVI (93 kapi kurali: karar veren betik kendini
# sinar). Vakalar 30.08 olcumunden GERCEK alintilardir. Kapi bozulursa kosu
# BASLAMAZ - bozuk kapi sessizce yanlis olcum uretmesin.
$KAPI_SINAVI = @(
  @{e='GECICI_MUHLET'; a='11/09/2025 tarihinden baslamak uzere 1 YILLIK KESIN MUHLET VERILMESINE'; b=$true },
  @{e='GECICI_MUHLET'; a='"1 YILLIK KESIN MUHLET VERILMISTIR"';                                    b=$true },
  @{e='IFLAS_KALDIRMA';a='Verilen kesin muhlet kararinin kaldirilmasina';                          b=$true },
  @{e='KESIN_MUHLET';  a='17.07.2025 tarihinden baslamak uzere 1 yillik kesin muhlet verilmis';    b=$false},
  @{e='GECICI_MUHLET'; a='UC (3) AYLIK GECICI KONKORDATO MEHLI VERILMISTIR.';                      b=$false},
  @{e='UZATMA';        a='verilen 1 yillik kesin muhletin 6 ay UZATILMASINA';                      b=$false},
  @{e='MUHLET_KALDIRMA';a='Verilen kesin muhlet kararinin kaldirilmasina';                         b=$false},
  @{e='TASDIK';        a='konkordato projesinin TASDIKINE karar verilmistir';                      b=$false},
  @{e='ALACAK_CAGRISI';a='once 3 ay gecici sonra 1 yil kesin muhlet verilen borclunun alacaklilari';b=$false}
)
$kapiKotu = @($KAPI_SINAVI | Where-Object { (CelisikMi $_.e $_.a) -ne $_.b })
if ($kapiKotu.Count) {
  Write-Host ("HATA: celiski kapisi oz-sinavda {0}/{1} vakada BOZUK - kosu baslamiyor." -f `
    $kapiKotu.Count, $KAPI_SINAVI.Count)
  $kapiKotu | ForEach-Object { Write-Host ("  [{0}] beklenen {1} <- {2}" -f $_.e, $_.b, $_.a) }
  exit 1
}
Write-Host ("Celiski kapisi oz-sinavi: {0}/{0} gecti" -f $KAPI_SINAVI.Count)

$sonuc = @(); $uyum = 0; $uyumsuz = 0; $alintisiz = 0; $cevapsiz = 0; $celisik = 0
$i = 0
foreach ($x in $ilanlar) {
  $i++
  $istem = $SORU.Replace('{BASLIK}', "$($x.baslik)").Replace('{METIN}', (Maskele "$($x.metin)"))
  $c = Sor $istem
  if (-not $c) { $cevapsiz++; continue }
  $harf = ''; $alinti = ''
  # 30.08: harf yerine ETIKET okunuyor. Etiket listesi $ESLESME'nin anahtarlari
  # oldugu icin ikisi ASLA ayrisamaz - eski harf listesindeki gibi bir secenek
  # eklenip esleme unutulamaz.
  if ($c -match '(?im)^\s*KARAR\s*:\s*[\(\[]?\s*([A-Z_]{3,})') {
    $aday = $Matches[1].ToUpper().Trim('_')
    if ($ESLESME.ContainsKey($aday)) { $harf = $aday }
  }
  if ($c -match '(?im)^\s*ALINTI\s*:\s*(.+)$')     { $alinti = $Matches[1].Trim() }
  if (-not $harf) { $cevapsiz++; continue }
  # 29.08 ASIL KUSUR: "alinti zorunlu" dedim ama ZORLAMADIM - ilk kosuda 290/746
  # (%39) cevap alintisiz geldi ve ben onlari yine de uyum oranina KATTIM.
  # Yani %72,8 olculmus bir sayi degildi. Artik alintisiz cevap AYRI tutulur ve
  # OLCULEBILIR UYUM yalniz alintililardan hesaplanir. Kaynagini gosteremeyen
  # cevap sayilmaz - regex'e uyguladigim kurali okumaya da uyguluyorum.
  $alintiVar = [bool]($alinti -and $alinti -notmatch '^\s*YOK\s*\.?\s*$' -and $alinti.Length -ge 12)
  if (-not $alintiVar) { $alintisiz++ }

  # 30.08 CELISKI KAPISI: alinti ile etiket ayni seyi soylemiyorsa bu cevap
  # olcume GIRMEZ. Alintisiz cevaba uyguladigim kuralin ayni bu - "kaynagini
  # gosteremeyen cevap sayilmaz"in devami: kaynagi kendi cevabini YALANLAYAN
  # cevap da sayilmaz. Kayit atilmaz, isaretlenir; hakem turunda tekrar okunur.
  # NOT: alinti_var'a DOKUNULMAZ - celisik kayit hakem turuna GIRMELI, orada
  # iki yorum onune konunca cozuluyor. Kapi yalniz UYUM ORANINDAN dusurur.
  $celiskiVar = $false
  if ($alintiVar -and (CelisikMi $harf $alinti)) { $celiskiVar = $true; $celisik++ }

  # ÖZ-SINAV (29.08 kusurundan sonra eklendi): karsilastirilan sey TEK bir damga
  # olmali. Dizi geldiyse cekim bozulmus demektir - sessizce %0 uyum uretmek
  # yerine ACIKCA durup soyler. "Supheli sifiri guvenilir sifira cevirme" kurali.
  $damga = "$($x.karar_durumu)"
  if ($damga -match '\s') {
    Write-Host "HATA: karar_durumu tek deger degil, DIZI geldi - cekim bozuk, olcum durduruldu."
    Write-Host ("  ornek: {0}" -f $damga.Substring(0, [Math]::Min(60, $damga.Length)))
    exit 1
  }
  $beklenen = $ESLESME[$harf]
  $tutuyor = ($beklenen -and ($beklenen -contains $damga))
  if ($tutuyor) { $uyum++ } else { $uyumsuz++ }

  $sonuc += [pscustomobject]@{
    ilan_no = $x.ilan_no; tarih = $x.tarih; il = $x.il
    baslik = "$($x.baslik)"; regex_damgasi = $damga
    okuma_karari = $harf; okuma_alintisi = $alinti; alinti_var = $alintiVar
    alinti_celisiyor = $celiskiVar; uyuyor = $tutuyor
  }
  if ($i % 10 -eq 0) { Write-Host ("  {0}/{1} okundu (uyum {2} · uyumsuz {3})" -f $i, $ilanlar.Count, $uyum, $uyumsuz) }
  Start-Sleep -Milliseconds 350
}

# ============================================================================
#  HAKEM TURU (29.08, Cem: "100'u niye dogrulayamiyoruz, BIREBIR OKU")
#
#  %86 uyum "okuma %14 yaniliyor" DEMEK DEGIL - iki yontemin ANLASMADIGI oran.
#  Bugun elle bakilan her uyusmazlikta cogunlukla OKUMA hakli cikti (18 tasdik,
#  feragat dilekcesi, m.177/4 - hepsini okuma buldu, regex kacirdi). Asil kusur
#  kurgudaydi: regex ANA damga, okuma "ikinci gorus" yapilmisti.
#
#  Hakem turu ayrisan ilanlari IKINCI KEZ okutur - bu sefer iki yorumu ONUNE
#  koyarak. Model kendi ilk cevabini da sorgular. Sonucta her ilan uc kutudan
#  birinde olur: IKI YONTEM ONAYLADI · HAKEM COZDU · ELLE BAKILACAK.
#  "Olculmedi" kutusu KALMAZ.
# ============================================================================
$DURUM_ACIK = @{
  'gecici_muhlet'='gecici muhlet verildi'; 'kesin_muhlet'='kesin muhlet verildi'
  'uzatma'='muhlet uzatildi'; 'muhlet'='muhlet verildi (turu belirsiz)'
  'ret_kaldirma'='konkordato talebi REDDEDILDI (iflas karari yok)'
  'ret_iflas'='talep reddedildi VE IFLASA karar verildi'
  'tasdik'='konkordato TASDIK edildi'; 'iflas_kaldirma'='daha once verilmis IFLAS KALDIRILDI'
  'feragat'='borclu davadan FERAGAT etti (kendi vazgecti)'
  'muhlet_kaldirma'='konkordato MUHLETI kaldirildi/sonlandirildi'
  'alacak_cagrisi'='ALACAKLILARA CAGRI (alacaklarin bildirilmesi/kaydi isteniyor)'
  'durusma'='DURUSMA GUNU bildiriliyor'
  'iflas_tasfiye'='IFLAS TASFIYE ISLEMI (sira cetveli / tasfiye / masa / kapanma)'
  'diger'='yukaridakilerden hicbiri'
}
$HAKEM = @'
Asagida bir resmi ilanin metni var. Bu ilanin hangi karari tasidigi konusunda
IKI FARKLI yorum var. Metne bak ve HANGISININ DOGRU oldugunu soyle.

YORUM A: {A}
YORUM B: {B}

Ikisi de yanlissa (C) de. Yalniz su iki satiri yaz:
HAKEM: <A ya da B ya da C>
ALINTI: <karari gecen cumleyi metinden AYNEN kopyala; yoksa YOK yaz>

Kararini metne dayandiramiyorsan (C) yaz. Tahmin etme.

--- ILAN BASLIGI ---
{BASLIK}
--- ILAN METNI ---
{METIN}
'@

if ($env:HAKEM -eq '1') {
  $ayrisan = @($sonuc | Where-Object { -not $_.uyuyor -and $_.alinti_var })
  Write-Host ''
  Write-Host ('=' * 74)
  Write-Host ("HAKEM TURU: {0} ayrisan ilan ikinci kez okunuyor" -f $ayrisan.Count)
  $okumaKazandi = 0; $regexKazandi = 0; $ikisiDe = 0; $hakemsiz = 0
  $j = 0
  foreach ($a in $ayrisan) {
    $j++
    $ilan = $ilanlar | Where-Object { "$($_.ilan_no)" -eq "$($a.ilan_no)" } | Select-Object -First 1
    if (-not $ilan) { $hakemsiz++; continue }
    # A = OKUMANIN dedigi, B = REGEX damgasinin dedigi
    $okumaDurum = @($ESLESME[$a.okuma_karari])[0]
    $aMetin = if ($okumaDurum -and $DURUM_ACIK[$okumaDurum]) { $DURUM_ACIK[$okumaDurum] } else { 'yukaridakilerden hicbiri' }
    $bMetin = if ($DURUM_ACIK[$a.regex_damgasi]) { $DURUM_ACIK[$a.regex_damgasi] } else { $a.regex_damgasi }
    $istem = $HAKEM.Replace('{A}', $aMetin).Replace('{B}', $bMetin).
             Replace('{BASLIK}', "$($ilan.baslik)").Replace('{METIN}', (Maskele "$($ilan.metin)"))
    $c = Sor $istem
    $kar = ''; $al = ''
    if ($c -and $c -match '(?im)^\s*HAKEM\s*:\s*\(?([ABC])') { $kar = $Matches[1].ToUpper() }
    if ($c -and $c -match '(?im)^\s*ALINTI\s*:\s*(.+)$')      { $al  = $Matches[1].Trim() }
    switch ($kar) {
      'A' { $okumaKazandi++ } 'B' { $regexKazandi++ } 'C' { $ikisiDe++ } default { $hakemsiz++ }
    }
    $a | Add-Member -NotePropertyName hakem        -NotePropertyValue $kar   -Force
    $a | Add-Member -NotePropertyName hakem_alinti -NotePropertyValue $al    -Force
    if ($j % 10 -eq 0) { Write-Host ("  {0}/{1} hakem (okuma {2} · regex {3} · ikisi de degil {4})" -f $j, $ayrisan.Count, $okumaKazandi, $regexKazandi, $ikisiDe) }
    Start-Sleep -Milliseconds 350
  }
  Write-Host ''
  Write-Host 'HAKEM SONUCU:'
  Write-Host ("  OKUMA hakli   : {0}" -f $okumaKazandi)
  Write-Host ("  REGEX hakli   : {0}" -f $regexKazandi)
  Write-Host ("  IKISI DE degil: {0}  <- ELLE BAKILACAK" -f $ikisiDe)
  Write-Host ("  hakem cevapsiz: {0}  <- ELLE BAKILACAK" -f $hakemsiz)
  $kesin = $sonuc.Count - $ikisiDe - $hakemsiz
  Write-Host ''
  Write-Host ("KAPSAMA: {0}/{1} ilan KESINLESTI (%{2:N1}) · elle bakilacak {3}" -f `
    $kesin, $sonuc.Count, (100.0 * $kesin / $sonuc.Count), ($ikisiDe + $hakemsiz))

  # --------------------------------------------------------------------------
  #  HAKEM KARARINI DAMGAYA YAZ (HAKEM_YAZ=1)
  #  Yalniz hakem "A" (OKUMA hakli) dediklerini yazar - "B" zaten mevcut damga.
  #  TEK HEDEFI OLMAYAN etiket ATLANIR: HICBIRI hangi kovaya gidecegini
  #  oldugunu soylemiyor, (f) hicbiri demek. Bunlar elle listeye duser -
  #  "emin degilsen yazma" kurali damgalamada da gecerli.
  # --------------------------------------------------------------------------
  if ($env:HAKEM_YAZ -eq '1') {
    Write-Host ''
    Write-Host 'HAKEM KARARLARI DAMGAYA YAZILIYOR...'
    $yazilacak = @(); $atlanan = @()
    foreach ($a in ($ayrisan | Where-Object { $_.hakem -eq 'A' })) {
      # 30.08: hakeme sunulan "YORUM A" okumanin ETIKETIDIR. Etiket alintiyla
      # celisiyorsa hakem YANLIS yorumu onaylamis olabilir - hakem metni gorse
      # bile onune konan iki secenekten biri bastan bozuktu. Bu kayitlar
      # YAZILMAZ, elle listeye duser.
      if ($a.alinti_celisiyor) {
        $atlanan += [pscustomobject]@{ ilan_no=$a.ilan_no; il=$a.il; baslik=$a.baslik
          eski=$a.regex_damgasi; okuma=$a.okuma_karari
          sebep='alinti etiketi yalanliyor - hakeme bozuk yorum sunuldu' }
        continue
      }
      $hedefler = @($ESLESME[$a.okuma_karari])
      if ($hedefler.Count -ne 1) {
        $atlanan += [pscustomobject]@{ ilan_no=$a.ilan_no; il=$a.il; baslik=$a.baslik
          eski=$a.regex_damgasi; okuma=$a.okuma_karari
          sebep=$(if ($hedefler.Count -eq 0) { "HICBIRI - hedef kova yok" } else { "etiket ($($a.okuma_karari)) $($hedefler.Count) kovaya isaret ediyor, hangisi belirsiz" }) }
        continue
      }
      $yazilacak += [pscustomobject]@{ ilan_no=$a.ilan_no; eski=$a.regex_damgasi; yeni=$hedefler[0]
                                       okuma=$a.okuma_karari; alinti=$a.hakem_alinti }
    }
    Write-Host ("  yazilacak: {0} · atlanan (belirsiz hedef): {1}" -f $yazilacak.Count, $atlanan.Count)
    if ($atlanan.Count) {
      Write-Host '  ATLANANLAR - ELLE BAKILACAK:'
      $atlanan | Select-Object -First 10 | ForEach-Object {
        Write-Host ("    [{0}] {1}" -f $_.il, $_.baslik.Substring(0, [Math]::Min(52, $_.baslik.Length)))
        Write-Host ("       {0} · {1}" -f $_.eski, $_.sebep)
      }
    }
    if ($yazilacak.Count) {
      # YEDEK ONCE - geri donus yolu acik olmadan yazma yapilmaz
      $hy = Join-Path $kok 'veri\alacak-hakem-yedek.json'
      [IO.File]::WriteAllText($hy, ([ordered]@{
        olcum=(Get-Date).ToString('dd.MM.yyyy HH:mm')
        aciklama='Hakem turundan ONCEKI damgalar. Geri almak icin her ilan_no eski degerine set edilir.'
        adet=$yazilacak.Count; kayitlar=$yazilacak } | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
      Write-Host ("  yedek: {0}" -f $hy)

      $PH = @{ apikey=$KEY; Authorization="Bearer $KEY"; 'Content-Type'='application/json'; Prefer='return=minimal' }
      $yaz = 0; $hataY = 0
      foreach ($grup in ($yazilacak | Group-Object yeni)) {
        $liste = @($grup.Group | ForEach-Object { $_.ilan_no })
        for ($k = 0; $k -lt $liste.Count; $k += 20) {
          $parca = $liste[$k..([Math]::Min($k + 19, $liste.Count - 1))]
          $inL = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
          try {
            Invoke-RestMethod -Method Patch -Uri "$URL/rest/v1/alacak_ilan?ilan_no=in.($inL)" -Headers $PH `
              -Body ([Text.Encoding]::UTF8.GetBytes((@{ karar_durumu = $grup.Name } | ConvertTo-Json -Compress))) -TimeoutSec 90 | Out-Null
            $yaz += $parca.Count
          } catch { $hataY += $parca.Count; Write-Host ("    PATCH hatasi ({0}): {1}" -f $grup.Name, $_.Exception.Message) }
          Start-Sleep -Milliseconds 200
        }
      }
      Write-Host ("  YAZILDI: {0} · hata: {1}" -f $yaz, $hataY)
      Write-Host '  GECIS DAGILIMI:'
      $yazilacak | Group-Object { $_.eski + ' -> ' + $_.yeni } | Sort-Object Count -Descending |
        ForEach-Object { Write-Host ("    {0,4}  {1}" -f $_.Count, $_.Name) }
      if ($hataY -gt 0) { Write-Host 'KIRMIZI: bazi PATCH istekleri basarisiz. Yedek: veri/alacak-hakem-yedek.json'; exit 1 }
    }
  }
}

$hedef = Join-Path $kok 'veri\alacak-okuma-pilot.json'
$cikti = [ordered]@{
  olcum      = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  orneklem   = $ilanlar.Count
  okunan     = $sonuc.Count
  uyum_ham          = $uyum
  alintili_adet     = @($sonuc | Where-Object { $_.alinti_var }).Count
  uyum_olculebilir  = @($sonuc | Where-Object { $_.alinti_var -and $_.uyuyor }).Count
  gemini_sebep      = $script:geminiSebep
  uyum       = $uyum
  uyumsuz    = $uyumsuz
  alintisiz  = $alintisiz
  cevapsiz   = $cevapsiz
  hat        = @{ gemini = $script:sayacGemini; haiku = $script:sayacHaiku; hata = $script:sayacHata }
  kayitlar   = $sonuc
}
[IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))

# --- SUPHELI DAMGA LISTESI (kalici veri, artefakt degil) --------------------
# 29.08: uyusmazliklar simdiye kadar yalniz artefaktta duruyordu ve kosu
# gecince kayboluyordu. Oysa bu liste, regex damgasinin yanildigi yeri bulmanin
# EN UCUZ yolu: 29.08 kosusunda icinden en az 3 KESIN kusur cikti (Aksaray,
# Sanliurfa, Ankara m.292 - hepsi gercek iflas karari ama sitede "ret/kaldirma"
# kovasinda). Artik depoya yazilir, her kosuda tazelenir.
# GIZLILIK: alintilar TCKN'si maskelenmis metinden gelir; VKN yazilmaz. Kalan
# alanlar (ilan no, il, baslik) ilan.gov.tr'de zaten kamuya aciktir.
$supheli = @($sonuc | Where-Object { -not $_.uyuyor -and $_.alinti_var } | ForEach-Object {
  [ordered]@{
    ilan_no = $_.ilan_no; tarih = $_.tarih; il = $_.il
    baslik = $_.baslik
    regex_damgasi = $_.regex_damgasi
    okuma_karari  = $_.okuma_karari
    alinti = $(if ($_.okuma_alintisi.Length -gt 400) { $_.okuma_alintisi.Substring(0,400) } else { $_.okuma_alintisi })
    # alinti okumanin kararini DESTEKLIYOR mu? (29.08 dersi: alintinin varligi
    # yetmiyor, %21'inde alinti karari dogrulamiyordu)
    alinti_karari_destekliyor = $(
      switch ($_.okuma_karari) {
        'RET_IFLAS'       { [bool]($_.okuma_alintisi -match 'iflas') }
        'TASDIK'          { [bool]($_.okuma_alintisi -match 'tasdik|onay') }
        'IFLAS_KALDIRMA'  { [bool]($_.okuma_alintisi -match 'iflas[ıi]n\s*kald') }
        'MUHLET_KALDIRMA' { [bool]($_.okuma_alintisi -match 'm[üu]hlet') }
        'FERAGAT'         { [bool]($_.okuma_alintisi -match 'feragat') }
        'ALACAK_CAGRISI'  { [bool]($_.okuma_alintisi -match 'alacak|bildir|kayd|kayıt') }
        'DURUSMA'         { [bool]($_.okuma_alintisi -match 'duruşma|durusma|gün|toplantı') }
        'KESIN_MUHLET'    { [bool]($_.okuma_alintisi -match 'kesin\s*m[üu]hlet') }
        'UZATMA'          { [bool]($_.okuma_alintisi -match 'uzat') }
        'MUHLET_BELIRSIZ' { [bool]($_.okuma_alintisi -match 'm[üu]hlet') }
        'IFLAS_TASFIYE'   { [bool]($_.okuma_alintisi -match 'sıra cetvel|tasfiye|masa|kapan') }
        'GECICI_MUHLET'   { [bool]($_.okuma_alintisi -match 'ge[çc]ici\s*m[üu]hlet|m[üu]hlet') }
        'RET'             { [bool]($_.okuma_alintisi -match 'red|ret\b') }
        default { $false }
      })
    alinti_celisiyor = [bool]$_.alinti_celisiyor
  }
})
$sHedef = Join-Path $kok 'veri\alacak-supheli-damga.json'
$sCikti = [ordered]@{
  olcum      = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama   = 'Regex damgasi ile OKUMA sonucunun ayristigi ilanlar. Uyumsuzluk "okuma hakli" DEMEK DEGILDIR - elle bakilir. alinti_karari_destekliyor=false olanlar once elenmelidir.'
  kaynak     = 'motor/alacak-ilan-okuyucu-pilot.ps1'
  taranan    = $sonuc.Count
  supheli    = $supheli.Count
  destekli   = @($supheli | Where-Object { $_.alinti_karari_destekliyor }).Count
  kayitlar   = $supheli
}
[IO.File]::WriteAllText($sHedef, ($sCikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
Write-Host ("Supheli damga listesi: {0} kayit -> {1}" -f $supheli.Count, $sHedef)

Write-Host ''
Write-Host ('=' * 72)
if ($sonuc.Count) {
  # OLCULEBILIR UYUM = yalniz ALINTILI cevaplar. Alintisiz cevap "okuma bildi"
  # sayilmaz; kaynagini gosteremeyen cevap olcume girmez.
  # 30.08: alintisi kendi etiketini YALANLAYAN cevaplar da olcume girmez.
  $alintili     = @($sonuc | Where-Object { $_.alinti_var -and -not $_.alinti_celisiyor })
  $uyumAlintili = @($alintili | Where-Object { $_.uyuyor }).Count
  Write-Host ("OKUNAN: {0} · cevapsiz: {1}" -f $sonuc.Count, $cevapsiz)
  Write-Host ("HAM UYUM (alintisizlar dahil - GUVENILMEZ): {0}/{1} (%{2:N1})" -f `
    $uyum, $sonuc.Count, (100.0 * $uyum / $sonuc.Count))
  if ($alintili.Count) {
    Write-Host ("OLCULEBILIR UYUM (yalniz alintili): {0}/{1} (%{2:N1})  <-- KARAR BU SAYIYA GORE VERILIR" -f `
      $uyumAlintili, $alintili.Count, (100.0 * $uyumAlintili / $alintili.Count))
  } else {
    Write-Host 'OLCULEBILIR UYUM: KOR - hicbir cevap alinti tasimiyor, olcum yapilamaz.'
  }
  Write-Host ("ALINTISIZ (olcume GIRMEDI): {0} (%{1:N1})" -f $alintisiz, (100.0 * $alintisiz / $sonuc.Count))
  Write-Host ("ALINTI-ETIKET CELISKISI (olcume GIRMEDI, hakeme gitti): {0} (%{1:N1})" -f `
    $celisik, (100.0 * $celisik / $sonuc.Count))
  if ($celisik -gt (0.05 * $sonuc.Count)) {
    Write-Host "  DIKKAT: celiski orani %5'in ustunde - istemdeki secenek listesi yine"
    Write-Host "  karistiriyor olabilir. Once bunu duzelt, yazma turunu KOSMA."
  }
  Write-Host ("HAT: gemini {0} ({1}) · haiku {2} · hata {3}{4}" -f $script:sayacGemini,
    $(if ($script:gmodel) { $script:gmodel } else { '-' }), $script:sayacHaiku, $script:sayacHata,
    $(if ($script:geminiSebep) { " · GEMINI KULLANILMADI: $($script:geminiSebep)" } else { '' }))
  if ($script:gmodel) {
    Write-Host ("  >> CALISAN GEMINI MODELI: '{0}'" -f $script:gmodel)
    if ($script:gmodel -ne 'gemini-flash-latest') {
      Write-Host "     DIKKAT: uretim hatlari (motor/toplu-uret.ps1, motor/gece-ajani.ps1)"
      Write-Host "     'gemini-flash-latest' kullaniyor. Uc nokta yine degismis olabilir -"
      Write-Host "     yukaridaki adi oraya da tasi."
    }
  }
  Write-Host ''
  Write-Host 'KOVA BAZLI OLCULEBILIR UYUM (alintili cevaplar):'
  $alintili | Group-Object regex_damgasi | Sort-Object Name | ForEach-Object {
    $t = @($_.Group | Where-Object { $_.uyuyor }).Count
    Write-Host ("  {0,-16} {1,3}/{2,-3} (%{3:N0})" -f $_.Name, $t, $_.Count, (100.0 * $t / $_.Count))
  }
  Write-Host ''
  Write-Host 'ILK 12 UYUSMAZLIK - YALNIZ ALINTILI (ELLE BAKILACAK: regex mi okuma mi hakli?):'
  $alintili | Where-Object { -not $_.uyuyor } | Select-Object -First 12 | ForEach-Object {
    Write-Host ("  [{0}] regex={1} · okuma={2}" -f $_.il, $_.regex_damgasi, $_.okuma_karari)
    Write-Host ("     baslik : {0}" -f $_.baslik.Substring(0, [Math]::Min(66, $_.baslik.Length)))
    Write-Host ("     alinti : {0}" -f $(if ($_.okuma_alintisi) { $_.okuma_alintisi.Substring(0, [Math]::Min(90, $_.okuma_alintisi.Length)) } else { '-' }))
  }
} else {
  Write-Host 'KOR: hicbir ilan okunamadi.'
}
Write-Host ''
Write-Host ("Rapor: {0}" -f $hedef)
Write-Host 'UYARI: uyumsuzluk "okuma yanildi" DEMEK DEGILDIR. 28.08''de regex alti kez'
Write-Host 'yanildi. Her uyusmazliga ELLE bakilir; hangisinin hakli oldugu ORADA belli olur.'
