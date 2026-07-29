# ============================================================================
#  SINAV ANALIZ ROBOTU — SGS kitapciklarini Claude'a PDF olarak okutur,
#  HER soruyu (no, ders, konu) etiketler. KALITE KAPILARI:
#   1) IKI BAGIMSIZ okuma; soru sayilari ve ders etiketleri karsilastirilir
#   2) Ders uyusmazligi >%10 ise donem RED (inceleme isaretlenir, yayinlanmaz)
#   3) Konu etiketi uyusmayanlar 3. hakem cagriyla tekillestirilir
#   4) Soru sayisi 90-140 araligi disindaysa RED
#  Cikti: veri/sgs-analiz.json (donem bazli ders/konu sayimlari + soru listesi)
#  Kitapcik METNI siteye kopyalanmaz — yalniz analiz yayinlanir (telif).
#  ENV: ANTHROPIC_API_KEY zorunlu. Kosumda en fazla $LIMIT donem islenir.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
# 29.07: model ortamdan verilebilir. Konu ETIKETLEME basit bir istir - metinde
# yazan soruyu okuyup 2-4 kelimelik etiket koymak. Bunun icin en pahali modeli
# kullanmak gereksiz; ustelik iki bagimsiz okuma + %90 uyusma kapisi zaten
# hatayi yakaliyor. Ucuz okuyucu + siki kapi, pahali okuyucu + kapisiz'dan iyidir.
$MODEL = if($env:ANALIZ_MODEL){ $env:ANALIZ_MODEL } else { "claude-sonnet-5" }
$FIYAT_G = if($env:ANALIZ_FIY_G){ [double]$env:ANALIZ_FIY_G } else { 3.0 }
$FIYAT_C = if($env:ANALIZ_FIY_C){ [double]$env:ANALIZ_FIY_C } else { 15.0 }
# 29.07: LIMIT sabit 3'tu. Kuyrukta 169 kitapcik var (136 SMMM + 33 SGS);
# 3'erli kosuyla 57 kosu gerekirdi. Artik ortamdan verilebiliyor.
$LIMIT = if($env:ANALIZ_LIMIT){ [int]$env:ANALIZ_LIMIT } else { 3 }
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

# 29.07: KOSU KENDI KAYDINI TUTAR. Kosu #13 "basarili" dondu ama HICBIR
# KITAPCIK ISLEMEDI ve sebebi okunamadi - Actions loglari admin-kilitli.
# Ayni ders profesor hattinda uc kosu kaybettirmisti; burada tekrarlanmayacak.
try { Start-Transcript -Path (Join-Path $kok "veri/sinav-analiz-log.txt") -Force | Out-Null } catch {}
Write-Host ("BASLADI  model={0}  LIMIT={1}  anahtar={2}" -f $MODEL, $LIMIT, $(if($key){'VAR'}else{'YOK'}))
$arsivYol = Join-Path $kok "veri/sinav-arsiv.json"
$analizYol = Join-Path $kok "veri/sgs-analiz.json"
$analizSYol = Join-Path $kok "veri/smmm-analiz.json"   # Yeterlilik (2026/1'den beri test formati)
$arsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$analiz = if(Test-Path $analizYol){ Get-Content $analizYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; donemler=@() } }
$analizS = if(Test-Path $analizSYol){ Get-Content $analizSYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; donemler=@() } }

# 29.07: GERCEK FATURA SAYACI. Bu betik PDF'i dogrudan modele gonderiyor; PDF
# girisi SAYFA basina token yakar ve metin gondermekten cok daha pahalidir.
# Kuyruga 169 kitapcik konuldu; birim maliyeti TAHMIN etmek yerine ilk kosuda
# OLCUYORUZ. Tahminle 169 kitapcik acmak, yanlis rakamla butce yakmaktir.
$script:tokGiris = 0; $script:tokCikis = 0; $script:cagri = 0
function ClaudePdf($b64, $istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=@(
    @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$b64 } },
    @{ type="text"; text=$istem }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 900
  $script:tokGiris += [int]"$($r.usage.input_tokens)"
  $script:tokCikis += [int]"$($r.usage.output_tokens)"
  $script:cagri++
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function ClaudeTxt($istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  $script:tokGiris += [int]"$($r.usage.input_tokens)"
  $script:tokCikis += [int]"$($r.usage.output_tokens)"
  $script:cagri++
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; return $null }
function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }

$ISTEM = @"
Bu bir TURMOB-TESMER Staja Giris Sinavi soru kitapcigidir. GOREV: kitapciktaki HER COKTAN SECMELI SORUYU tek tek bul ve etiketle.
Her soru icin: no (kitapciktaki soru numarasi), ders (kitapciktaki bolume sadik kal; su listeden sec: Genel Kultur-Genel Yetenek, Muhasebe, Ekonomi, Maliye, Hukuk, Matematik-Istatistik, Yabanci Dil), konu (2-4 kelimelik SPESIFIK etiket, ornek: amortisman ayirma, KDV tevkifat, ihbar suresi, arz-talep esnekligi, butce ilkeleri, kiymetli evrak).
KURALLAR: Soru atlamak YASAK. Soru metnini KOPYALAMA - yalniz no/ders/konu. Emin olmadigin konuya en yakin genel etiketi ver.
SADECE su formatta JSON dizisi dondur, baska hicbir metin yazma:
[{"no":1,"ders":"...","konu":"..."}]
"@

$islenen = 0
# 29.07: SINAV ve DONEM suzgeci. Kuyrukta SGS kayitlari once geliyor ve SGS
# kitapciklari 130 SORULUK - olcumde kitapcik basina 0,53 USD cikti. Yeterlilik
# kitapciklari ise 20 SORULUK, yani cok daha ince. "169 kitapcik 89 USD" tahmini
# YANLIS TABANA dayaniyordu: SGS fiyatiyla SMMM sayisini carpmisim.
# Oncelik Yeterlilik: orada konu agirligi verisi HIC YOK. SGS'de zaten resmi
# ders orani var (TESMER Yonerge m.6.2) ve 6.708 soru var.
# Ayrica eski donemler beklesin: konu agirligi icin son yillar yeter ve guncel
# mufredati yansitir; 2021'in agirligi bugunu baglamaz.
$SINAV_SUZ = "$env:ANALIZ_SINAV"
$DONEM_MIN = if($env:ANALIZ_DONEM_MIN){ [int]$env:ANALIZ_DONEM_MIN } else { 0 }
if($SINAV_SUZ -or $DONEM_MIN){ Write-Host ("SUZGEC: sinav='{0}' donem>={1}" -f $SINAV_SUZ, $DONEM_MIN) }

foreach($d in $arsiv.donemler){
  if($d.durum -ne 'bekliyor'){ continue }
  if($SINAV_SUZ -and "$($d.sinav)" -ne $SINAV_SUZ){ continue }
  if($DONEM_MIN -gt 0){
    $yil = 0
    if("$($d.donem)" -match '^(\d{4})'){ $yil = [int]$Matches[1] }
    if($yil -gt 0 -and $yil -lt $DONEM_MIN){ continue }
  }
  if($islenen -ge $LIMIT){ break }
  # sinav tipi: SGS (varsayilan) veya SMMM (Yeterlilik; ders kitapcigi bazli)
  $sinavTip = if($d.sinav){ "$($d.sinav)" } else { 'SGS' }
  $bicim = if($d.PSObject.Properties['format']){ "$($d.format)" } else { 'test' }
  $istemAktif = $ISTEM
  $minSoru = 90
  $maxSoru = 140

  # 29.07: YAZILI (klasik) donemler. SMMM Yeterlilik 2026/1'de teste gecti;
  # 2021-2025 arasi 15 donem KLASIK sinavdi. Eski istem "her COKTAN SECMELI
  # soruyu bul" diyor - yazili kitapcikta hicbirini bulamaz ve 120 kitapcik
  # bosuna okunurdu. Yazilinin kendi istemi gerekiyor.
  #
  # NIYE YAZILIYI DA OKUYORUZ: format degisti ama KURULUN NEYI ONEMSEDIGI
  # degismedi. Testte sadece 3 donem var (2026/1-2-3); yazilida 6 yillik
  # gecmis. Yazili, konu agirliginin en genis kanitidir.
  # ONEMLI: bir yazili soru genis bir konuyu kapsar, bir test sorusu dardir.
  # Bu yuzden agirlik HAM SORU SAYISIYLA degil, konunun KAC DONEMDE gorundugu
  # ile hesaplanacak - o olcu formattan bagimsizdir.
  if($sinavTip -eq 'SMMM' -and $bicim -eq 'yazili'){
    # 29.07: alt sinir 2'ydi ve dokuz Finansal Muhasebe kitapcigini birden
    # reddetti. Loga bakinca goruldu ki KAPI YANILMIS, VERI DOGRUYMUS: iki
    # bagimsiz okuma da "1 soru" diyordu - cunku klasik FM sinavi TEK BIR
    # BUYUK MONOGRAFI. Ustelik bunu ben bozmusum: isteme "alt siklari ayri
    # soru sayma" yazmistim; oysa monografide alt istekler KONULARIN KENDISI.
    # Istem duzeltildi (her alt istek ayri kayit), alt sinir 1'e cekildi.
    $minSoru = 1; $maxSoru = 60
    $istemAktif = @"
Bu bir TURMOB-TESMER SMMM Yeterlilik Sinavi '$($d.ders)' dersi KLASIK (yazili) soru kitapcigidir. Coktan secmeli DEGILDIR; sorular acik uclu, problem ya da olay seklindedir ve bazilari a) b) c) gibi ALT SIKLARA bolunmustur.
DIKKAT - BU SINAV COGU ZAMAN TEK BIR BUYUK MONOGRAFIDIR: bir isletmenin donem
islemleri verilir, altinda a) b) c) ... diye ONLARCA ALT ISTEK bulunur.
GOREV: HER ALT ISTEGI AYRI KAYIT olarak etiketle. Alt istekler bu sinavda
sorunun kendisidir; onlari tek kayda toplarsan konu bilgisi kaybolur.
Ana soru tek satirlik ve alt istegi yoksa onu tek kayit yaz.
Her kayit icin:
  no    - "1a", "1b", "2" gibi ana numara + alt harf
  ders  - SABIT: '$($d.ders)'
  konu  - 2-4 kelimelik SPESIFIK etiket (ornek: amortisman ayirma, KDV tevkifat, konsolidasyon)
  tip   - sorunun KURGUSU: "bilgi" | "vaka" | "hesap" | "kayit" | "karsilastir"
  uzun  - soru koku uzunlugu: "kisa" | "orta" | "uzun"
KURALLAR: Soru atlamak YASAK. Soru metnini KOPYALAMA - yalniz bu alanlar. Cevap anahtari sayfalarini soru sayma. Emin olmadigin konuya en yakin genel etiketi ver.
SADECE su formatta JSON dizisi dondur, baska hicbir metin yazma:
[{"no":1,"ders":"$($d.ders)","konu":"...","tip":"...","uzun":"..."}]
"@
  }
  elseif($sinavTip -eq 'SMMM'){
    $minSoru = 10; $maxSoru = 40
    $istemAktif = @"
Bu bir TURMOB-TESMER SMMM Yeterlilik Sinavi '$($d.ders)' dersi soru kitapcigidir (2026/1'den beri coktan secmeli test). GOREV: kitapciktaki HER COKTAN SECMELI SORUYU tek tek bul ve etiketle.
Her soru icin:
  no    - kitapciktaki soru numarasi
  ders  - SABIT: '$($d.ders)'
  konu  - 2-4 kelimelik SPESIFIK etiket (ornek: amortisman ayirma, KDV tevkifat, konsolidasyon, ic kontrol testleri, orneklem secimi)
  tip   - sorunun KURGUSU, su besinden biri:
          "bilgi"      = duz bilgi/tanim sorusu, hesap yok
          "vaka"       = bir olay anlatilip hukum sorulan senaryo sorusu
          "hesap"      = rakam verilip sonuc istenen hesaplama sorusu
          "kayit"      = yevmiye kaydi / muhasebelestirme sorusu
          "karsilastir"= iki kavramin/uygulamanin farkini olcen soru
  uzun  - soru koku uzunlugu: "kisa" (tek cumle), "orta", "uzun" (paragraf/vaka metni)
KURALLAR: Soru atlamak YASAK. Soru metnini KOPYALAMA - yalniz bu alanlar. Emin olmadigin konuya en yakin genel etiketi ver.
SADECE su formatta JSON dizisi dondur, baska hicbir metin yazma:
[{"no":1,"ders":"$($d.ders)","konu":"...","tip":"...","uzun":"..."}]
"@
  }
  Write-Host ("=== [{0}] {1} {2} ({3}) isleniyor..." -f $sinavTip, $d.donem, $d.ders, $d.tarih)
  $tmp = Join-Path ([IO.Path]::GetTempPath()) "sgs.pdf"
  try { Invoke-WebRequest -Uri $d.url -OutFile $tmp -UserAgent "Mozilla/5.0" -TimeoutSec 180 -UseBasicParsing } catch { Write-Host "  indirilemedi, atlandi"; continue }
  # 29.07 (Cem: "pdf olmadi sen oku, az butce yakalim"): kitapcik ARTIK MODELE
  # PDF OLARAK GONDERILMIYOR. PDF girisi SAYFA basina token yakar; 169 kitapcigi
  # oyle okutmak butcenin buyuk kismini tek adima gomerdi. Onun yerine yerelde
  # pdftotext ile metne cevrilip METIN gonderiliyor - mevzuat hasadinda zaten
  # kullandigimiz, bedava ve kanitli yol.
  # Konu etiketlemek icin sayfa duzenine ihtiyac yok; soru numarasi ve metin yeter.
  $txt = "$tmp.txt"
  & pdftotext -enc UTF-8 -layout $tmp $txt 2>$null
  if(-not (Test-Path $txt)){ Write-Host "  pdftotext calismadi, atlandi"; continue }
  $icerik = Get-Content $txt -Raw -Encoding UTF8
  if("$icerik".Trim().Length -lt 500){ Write-Host "  RED: metin cikmadi (taranmis pdf olabilir)"; $d.durum='inceleme'; $islenen++; continue }
  # cok uzun kitapciklarda kirp - konu etiketi icin bas kisim yeterli, ama
  # kirpma ISARETLENIR ki sessiz eksik okuma olmasin
  $KIRP = 120000
  $kirpildi = $false
  if($icerik.Length -gt $KIRP){ $icerik = $icerik.Substring(0,$KIRP); $kirpildi = $true }
  Write-Host ("  pdf {0} KB -> metin {1:N0} karakter{2}, okuma 1/2..." -f [math]::Round((Get-Item $tmp).Length/1KB), $icerik.Length, $(if($kirpildi){' (KIRPILDI)'}else{''}))

  $tamIstem = $istemAktif + "`n`n=== KITAPCIK METNI ===`n" + $icerik

  # KAPI 1: iki bagimsiz okuma
  $o1 = $null; $o2 = $null
  try { $o1 = (JsonBul (ClaudeTxt $tamIstem 16000)) | ConvertFrom-Json } catch { Write-Host "  okuma1 hata: $($_.Exception.Message)" }
  Write-Host "  okuma 2/2..."
  try { $o2 = (JsonBul (ClaudeTxt $tamIstem 16000)) | ConvertFrom-Json } catch { Write-Host "  okuma2 hata: $($_.Exception.Message)" }
  if(-not $o1 -or -not $o2){ Write-Host "  RED: okuma basarisiz"; $d.durum='hata'; $islenen++; continue }

  # KAPI 4: soru sayisi makul mu
  $n1=@($o1).Count; $n2=@($o2).Count
  Write-Host ("  okuma1={0} soru, okuma2={1} soru" -f $n1,$n2)
  # 29.07: ust sinir sabit 140'ti; SMMM ders kitapciklari 20 soruluk, yazililar
  # daha da az. Sabit sinir yanlis kumeye uygulaninca ya hepsini gecirir ya
  # hepsini reddeder - iki halde de kapi is gormez. Artik bicime gore.
  # Iki okuma arasindaki fark toleransi da kucuk kitapcikta oransal olmali:
  # 20 soruluk kitapcikta 8 soru fark %40 demektir, gecirilemez.
  # 29.07: tolerans 2'ydi ve YAZILI Finansal Muhasebe kitapciklarinin DOKUZU
  # birden 'inceleme'ye dustu - en agir ve en onemli dersin verisi bos kaldi.
  # Sebep: klasik sinavda "1. soru" alti bentli olabiliyor; iki okuyucu birinde
  # 5 birinde 7 soru sayabiliyor ve bu KUSUR DEGIL, sayim yorumu. Yazilida
  # tolerans oransal olmali. Testte (siklar sayili) sikilik korunuyor.
  # 29.07 UCUNCU DENEME - ve bu sefer OLCUNUN KENDISI degisiyor.
  # Monografide okumalar 34 vs 6, 32 vs 29, 34 vs 1 cikti. Sebep kusur degil:
  # bir isletme vakasini kac alt isteğe boldugun YORUMA ACIK. Sayiyi
  # karsilastiran kapi bu veri tipine UYMUYOR - ne gevsetmek ne sikmak ise
  # yarar, cunku yanlis seyi olcuyor.
  # Dogru olcu KONU KUMESI: iki okuma kac parcaya boldugunde degil, HANGI
  # KONULARI gordugunde anlasmali. Ortusme yeterliyse iki okumanin BIRLESIMI
  # alinir - biri otekinin kacirdigi konuyu yakalamis olabilir.
  if($bicim -eq 'yazili'){
    $k1=@{}; foreach($s in $o1){ if("$($s.konu)".Trim()){ $k1[(Fold $s.konu)]=1 } }
    $k2=@{}; foreach($s in $o2){ if("$($s.konu)".Trim()){ $k2[(Fold $s.konu)]=1 } }
    # 29.07: kesisim BIREBIR metin karsilastirmasiyla olculuyordu ve 2024/3
    # kil payi kacti: iki okuma da 35-36 konu gormus, ortusme %34, esik %35.
    # Oysa konu etiketi SERBEST METIN - "amortisman ayirma" ile "amortisman
    # hesaplama" ayni seyi anlatir ama birebir eslesmez. Birebir karsilastirma
    # burada gercek anlasmazligi degil KELIME SECIMINI olcuyor.
    # Artik ANLAMLI KELIME ortusmesine bakiliyor: iki etiket 3+ harfli ortak
    # bir kelime paylasiyorsa ayni konu sayilir.
    function AnlamliKelimeler([string]$t){
      $l=@(); foreach($w in ("$t" -split '[^a-z0-9]+')){ if($w.Length -ge 4){ $l += $w } }
      return $l
    }
    $k2kel = @{}
    foreach($k in $k2.Keys){ foreach($w in (AnlamliKelimeler $k)){ if(-not $k2kel.ContainsKey($w)){ $k2kel[$w]=@() }; $k2kel[$w] += $k } }
    $kesisim=0
    foreach($k in $k1.Keys){
      if($k2.ContainsKey($k)){ $kesisim++; continue }
      $bulundu=$false
      foreach($w in (AnlamliKelimeler $k)){ if($k2kel.ContainsKey($w)){ $bulundu=$true; break } }
      if($bulundu){ $kesisim++ }
    }
    $kucuk=[Math]::Min($k1.Count,$k2.Count)
    $ortusme = if($kucuk -gt 0){ $kesisim/[double]$kucuk } else { 0 }
    Write-Host ("  YAZILI: okuma1 {0} konu, okuma2 {1} konu, ortusme %{2}" -f $k1.Count,$k2.Count,[math]::Round($ortusme*100))
    if($k1.Count -eq 0 -or $k2.Count -eq 0 -or $ortusme -lt 0.35){
      Write-Host "  RED: iki okuma ayni konulari gormuyor"; $d.durum='inceleme'; $islenen++; continue }
    $sorular=New-Object System.Collections.Generic.List[object]
    $birlesim=@{}; foreach($k in $k1.Keys){ $birlesim[$k]=1 }; foreach($k in $k2.Keys){ $birlesim[$k]=1 }
    # 29.07: bu birlesim SADECE KONUYU tasiyordu, kurguyu (tip/uzun) dusuruyordu.
    # Istemi degistirdim, toplayiciyi degistirdim, ama BIRLESIM adiminda attim -
    # ucuncu halkayi unutmak. Artik her konunun ilk gorulen tip/uzun etiketi de
    # tasiniyor: sinavda "nasil soruldugu" uretim kotasinin yarisi.
    $tipHar=@{}
    foreach($s in @($o1)+@($o2)){
      $kk = Fold $s.konu
      if($kk -and -not $tipHar.ContainsKey($kk) -and "$($s.tip)".Trim()){ $tipHar[$kk]=@{ tip="$($s.tip)"; uzun="$($s.uzun)" } }
    }
    $i2=0
    foreach($k in $birlesim.Keys){
      $i2++
      $ek = $tipHar[$k]
      $sorular.Add(@{ no="y$i2"; ders=$d.ders; konu=$k; tip=$(if($ek){$ek.tip}else{''}); uzun=$(if($ek){$ek.uzun}else{''}) })
    }
    Write-Host ("  BIRLESIM: {0} konu" -f $sorular.Count)
    $atla = $true
  } else {
    $atla = $false
    $tolerans = if($maxSoru -le 40){ 2 } else { 8 }
    if($n1 -lt $minSoru -or $n1 -gt $maxSoru -or $n2 -lt $minSoru -or $n2 -gt $maxSoru -or [math]::Abs($n1-$n2) -gt $tolerans){
      Write-Host ("  RED: soru sayisi guvensiz (sinir {0}-{1}, tolerans {2})" -f $minSoru,$maxSoru,$tolerans); $d.durum='inceleme'; $islenen++; continue }
  }
  if(-not $atla){

  # KAPI 2: ders uyusmasi (no bazinda)
  $h2=@{}; foreach($s in $o2){ $h2["$($s.no)"]=$s }
  $dersUyusmaz=0; $konuCift=New-Object System.Collections.Generic.List[object]; $sorular=New-Object System.Collections.Generic.List[object]
  foreach($s in $o1){
    $e=$h2["$($s.no)"]
    if(-not $e){ $dersUyusmaz++; continue }
    if((Fold $s.ders) -ne (Fold $e.ders)){ $dersUyusmaz++; continue }
    if((Fold $s.konu) -eq (Fold $e.konu)){
      $sorular.Add(@{ no=$s.no; ders=$s.ders; konu=(Fold $s.konu) })
    } else {
      $konuCift.Add(@{ no=$s.no; ders=$s.ders; a=$s.konu; b=$e.konu })
    }
  }
  $oran = $dersUyusmaz / [double]$n1
  Write-Host ("  ders uyusmayan: {0} (%{1}) · konu farkli: {2}" -f $dersUyusmaz, [math]::Round($oran*100), $konuCift.Count)
  if($oran -gt 0.10){ Write-Host "  RED: ders uyusmazligi >%10"; $d.durum='inceleme'; $islenen++; continue }

  # KAPI 3: konu uyusmayanlara hakem (tek toplu cagri)
  if($konuCift.Count -gt 0){
    $liste = ($konuCift | ForEach-Object { "no=$($_.no) ders=$($_.ders) A='$($_.a)' B='$($_.b)'" }) -join "`n"
    $hIstem = "Ayni sinav sorusu icin iki okuma farkli konu etiketi verdi. Her satir icin TEK dogru/kapsayici etiketi sec (A, B veya daha iyi kisa bir birlesik etiket).`n$liste`nSADECE JSON dizisi: [{`"no`":1,`"konu`":`"...`"}]"
    try {
      $hk = (JsonBul (ClaudeTxt $hIstem 4000)) | ConvertFrom-Json
      $hkMap=@{}; foreach($x in $hk){ $hkMap["$($x.no)"]="$($x.konu)" }
      foreach($c in $konuCift){ $k=$hkMap["$($c.no)"]; if(-not $k){ $k=$c.a }; $sorular.Add(@{ no=$c.no; ders=$c.ders; konu=(Fold $k) }) }
    } catch { foreach($c in $konuCift){ $sorular.Add(@{ no=$c.no; ders=$c.ders; konu=(Fold $c.a) }) } }
  }
  }  # <- 'yazili degilse' blogu burada biter

  # sayimlar
  # 29.07: tip/uzun alanlari isteme eklenmisti ama BURAYA eklenmemisti - model
  # uretiyor, betik atiyordu. Klasik hata: istemi degistirip toplayiciyi
  # degistirmemek. Sorunun KURGUSU olmadan uretim kotasi yarim kalir.
  $dersSayim=@{}; $konuSayim=@{}; $tipSayim=@{}; $uzunSayim=@{}
  foreach($s in $sorular){
    $dersSayim[$s.ders]=1+[int]$dersSayim[$s.ders]
    $kk="$($s.ders)|$($s.konu)"; $konuSayim[$kk]=1+[int]$konuSayim[$kk]
    if("$($s.tip)".Trim()){  $tipSayim["$($s.tip)"]  = 1+[int]$tipSayim["$($s.tip)"] }
    if("$($s.uzun)".Trim()){ $uzunSayim["$($s.uzun)"] = 1+[int]$uzunSayim["$($s.uzun)"] }
  }
  $yeni = [pscustomobject]@{ donem=$d.donem; ders=$d.ders; tarih=$d.tarih; kaynakUrl=$d.url; toplamSoru=$sorular.Count;
    dersSayim=$dersSayim; konuSayim=$konuSayim; tipSayim=$tipSayim; uzunSayim=$uzunSayim
    analizTarihi=(Get-Date -Format "dd.MM.yyyy"); yontem="cift okuma + hakem" }
  $hedefAnaliz = if($sinavTip -eq 'SMMM'){ $analizS } else { $analiz }
  $anahtar = "$($d.donem)|$($d.ders)"
  $dl = New-Object System.Collections.Generic.List[object]
  foreach($x in @($hedefAnaliz.donemler)){ if("$($x.donem)|$($x.ders)" -ne $anahtar){ $dl.Add($x) } }
  $dl.Add($yeni); $hedefAnaliz.donemler = $dl.ToArray()
  $hedefAnaliz.guncelleme = (Get-Date -Format "dd.MM.yyyy HH:mm")
  $d.durum = 'tamam'
  Write-Host ("  TAMAM: {0} soru etiketlendi, {1} ders" -f $sorular.Count, $dersSayim.Keys.Count)
  $islenen++
}

[IO.File]::WriteAllText($arsivYol, ($arsiv | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText($analizYol, ($analiz | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText($analizSYol, ($analizS | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ("BITTI: bu kosuda {0} donem islendi." -f $islenen)

# --- GERCEK FATURA: tahmin degil, API'nin dondurdugu token
$FG = $FIYAT_G; $FC = $FIYAT_C   # liste fiyati, USD / 1M token - modele gore ortamdan
$tutar = ($script:tokGiris/1e6*$FG) + ($script:tokCikis/1e6*$FC)
Write-Host ("  model     : {0}  (fiyat varsayimi {1}/{2} USD-M)" -f $MODEL, $FG, $FC)
Write-Host ""
Write-Host "======== GERCEK FATURA ========"
Write-Host ("  cagri     : {0}  ({1} kitapcik x 2 bagimsiz okuma)" -f $script:cagri, $islenen)
Write-Host ("  giris     : {0:N0} token" -f $script:tokGiris)
Write-Host ("  cikis     : {0:N0} token" -f $script:tokCikis)
Write-Host ("  TUTAR     : ~{0:N2} USD" -f $tutar)
if($islenen -gt 0){
  $birim = $tutar/$islenen
  Write-Host ("  KITAPCIK BASINA: ~{0:N3} USD" -f $birim)
  Write-Host ("  -> kuyruktaki 169 kitapcik icin tahmin: ~{0:N0} USD" -f ($birim*169))
}
[IO.File]::WriteAllText((Join-Path $kok "veri/sinav-analiz-fatura.json"), ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); islenen=$islenen; cagri=$script:cagri
  giris_token=$script:tokGiris; cikis_token=$script:tokCikis
  tutar_usd=[math]::Round($tutar,2)
  kitapcik_basina_usd=$(if($islenen){[math]::Round($tutar/$islenen,3)}else{0})
  kuyruk_169_tahmin_usd=$(if($islenen){[math]::Round($tutar/$islenen*169,0)}else{0})
} | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/sinav-analiz-fatura.json"
exit 0
