# ============================================================================
#  SPL CIKMIS SINAV ARSIVI - INDIRICI (31.08.2026)
#
#  KAYNAK KARARI - ve neden ev kuralinin DISINDA degil:
#  Ev kurali "ucuncu taraf ayna kullanilmaz" (motor/spl-resmi-indir.ps1).
#  Burada OLCULDU ki resmi kopya ARTIK YOK:
#     https://spl.com.tr/Images/Uploads/Files/Sinav_Temel_Duzey_Agustos_2011_A.pdf -> 404
#     https://www.spl.com.tr/... (ayni dosya)                                      -> 404
#     https://spl.com.tr/PDF/15-16_Aral_k_2012_Sinav_Kilavuzu...                   -> 404
#     http://oep.spl.com.tr/pdf/31.05-01.06_2014_Lisanslama/2014_1_Sinav_A_Cevap.pdf
#         -> HTTP 200 AMA content-type text/html, 553 bayt = YUMUSAK 404
#            ("200 geldi" yetmez dersi; imza bakilmasaydi bu dosya "indi" sayilacakti)
#  Yani ayna ALTERNATIF degil, TEK KOPYA. Bu betik her dosyada once RESMI
#  adresi dener, ancak oradan gecerli PDF gelmezse arsiv kopyasini alir ve
#  kaynagi ("resmi" / "ayna") envantere TEK TEK yazar.
#
#  TELIF: SPL sinav sorularinin FSEK 5846 kapsaminda korundugunu yaziyor.
#  Bu yuzden (a) PDF'ler DEPOYA GIRMEZ, (b) sorular soru kasasina (satilan
#  urune) OTOMATIK GIRMEZ - ambara arsiv/referans olarak yutulur, yayin karari
#  Cem'dedir. Ayni kural KGK/TESMER arsivinde de boyle isliyor.
#
#  DORT KAPI (spl-resmi-indir.ps1 ile ayni): yarim inme · asgari boyut ·
#  %PDF imzasi · metin cikiyor mu. Ucunu gecip metni olmayan gorsel PDF
#  "KOR"dur, "EKSIK" DEGILDIR (olcemedigine kusur deme).
#
#  KULLANIM (GitHub Actions runner'inda kosar - arsiv TR agindan engelli):
#    pwsh -File motor/spl-cikmis-indir.ps1 -Tavan 8      # deneme: ilk 8 dosya
#    pwsh -File motor/spl-cikmis-indir.ps1               # tamami
# ============================================================================
param([switch]$Sessiz, [int]$Tavan = 0, [string]$Hedef = '', [switch]$Zorla)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $Hedef){ $Hedef = Join-Path $kok '_kaynak/spl-cikmis' }
if(-not (Test-Path $Hedef)){ New-Item -ItemType Directory -Path $Hedef -Force | Out-Null }

$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$ASGARI_BAYT = 15000

$curl = (Get-Command curl.exe -ErrorAction SilentlyContinue)
if(-not $curl){ $curl = Get-Command curl -ErrorAction SilentlyContinue }
if(-not $curl){ throw 'curl bulunamadi' }
$curl = $curl.Source
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue

function Yaz($m, $renk='Gray'){ if(-not $Sessiz){ Write-Host $m -ForegroundColor $renk } }

# --- ENVANTERI OKU ----------------------------------------------------------
$envYol = Join-Path $kok 'veri/spl-cikmis-envanteri.json'
if(-not (Test-Path $envYol)){ throw "Kesif envanteri yok: $envYol (once motor/spl-cikmis-kesif.ps1)" }
$kesif = Get-Content $envYol -Raw -Encoding UTF8 | ConvertFrom-Json

# --- ADAY SECIMI ------------------------------------------------------------
#  KURAL: "sessiz daraltma yok". Dar suzgecle 20 dosya indirip "hepsi bu" demek
#  en buyuk risk. Bu yuzden suzgec GENIS tutulur (adinda sinav/soru/cevap/
#  anahtar/kitapcik gecen HER PDF girer) ve ELENENLER de sayilip envantere
#  yazilir - neyin neden disarida kaldigi gorulebilsin.
$GENIS = '(?i)(sinav|soru|cevap|anahtar|kitapc)'
# Bunlar sinav SORUSU degil, sinav COMLEGIDIR (kilavuz/tablo/form). Indirilir
# ama "sinav-evraki" olarak isaretlenir; ayristiriciya GIRMEZ.
$EVRAK = '(?i)(kilavuz|kılavuz|oturum|tablo|itiraz|form|konulari|konular|aciklama|basvuru|takvim|duyuru|ucret|sonuc)'

$havuz = New-Object System.Collections.ArrayList
foreach($d in @($kesif.domain_pdf)){
  $ad = [uri]::UnescapeDataString((($d.url -split '\?')[0] -split '/')[-1])
  if($ad -notmatch '(?i)\.pdf$'){ continue }
  $sinif = if($ad -match $EVRAK){ 'sinav-evraki' } elseif($ad -match $GENIS){ 'sinav-belgesi' } else { 'ilgisiz' }
  [void]$havuz.Add([pscustomobject]@{ url=$d.url; damga=$d.damga; ad=$ad; sinif=$sinif; etiket='' })
}
# 31.08 KUSUR (ilk deneme kosusunda yakalandi - tam da Cem'in "yarim yutma"
# uyarisi): SPL'nin resmi arsiv sayfasindaki 334 kitapcik GUID adiyla duruyor
# (docs/other/fa0b822b-40b0-45.pdf). Dosya adinda "sinav/soru/cevap" GECMIYOR,
# yani ada bakan $GENIS suzgeci bu 334 dosyanin HEPSINI sessizce eliyordu.
# Sayfadan gelen kayitlarda karar ADA DEGIL ETIKETE gore verilir:
# "A KITAPCIGI" / "B KITAPCIGI" / "A-B KITAPCIGI" / "... CEVAP ANAHTARI".
#
# 31.08 IKINCI KUSUR - YUKARIDAKI DUZELTMENIN KENDISI TUTMADI (olculdu: 334
# yerine 4 eslesme). Sebep TURKCE BUYUK I: etiket "A KITAPCIGI" degil
# "A KİTAPÇIĞI"dir. .NET'in IgnoreCase'i INVARIANT kultur kullanir ve
# 'İ' (U+0130) ile 'i' (U+0069) ORADA AYNI HARF DEGILDIR - desen sessizce
# tutmaz. Ders: Turkce metinde `-match '(?i)...'` tek basina yeterli degil;
# once ASCII'ye katlanir, sonra eslestirilir.
# 31.08 UCUNCU KUSUR - DUZELTMENIN DUZELTMESI. Yukaridaki TrSade'nin ILK hali
# de tutmadi, iki ayri sebeple; ikisi de bu makinede OLCULDU:
#   (a) PowerShell'de `-replace` VARSAYILAN OLARAK HARF AYIRMAZ. Yani
#       `-replace 'ç','c'` buyuk 'Ç'yi de yakalar ve yerine KUCUK 'c' koyar:
#       "KİTAPÇIĞI" -> "KITAPcIgI". Harf ayirmak icin `-creplace` gerekir.
#   (b) Kultur tr-TR oldugunda .NET Regex'in `(?i)` bayragi 'I' harfini
#       NOKTASIZ 'ı'ya katlar. Yani "ANAHTARI" ile 'anahtari' deseni
#       TR makinede ESLESMEZ. (Runner en-US oldugu icin orada eslesir -
#       yani kusur yerelde gorunur, CI'da gorunmez: en sinsi tur.)
# Cozum: harf ayrimini hic isin icine sokma. Turkce harflerin BUYUK VE KUCUK
# hallerini tek tek ASCII karsiligina katla, sonra InvariantCulture ile
# kucult; desenler de kucuk harf yazilir, `(?i)` KULLANILMAZ.
function TrSade([string]$s){
  if(-not $s){ return '' }
  $s = $s -replace '[İIıi]','i' -replace '[Şş]','s' -replace '[Ğğ]','g'
  $s = $s -replace '[Üü]','u'   -replace '[Öö]','o' -replace '[Çç]','c'
  return $s.ToLowerInvariant()
}
$ETIKET_BELGE = '(kitapcigi|cevap\s*anahtari)'
foreach($p in @($kesif.sayfadan_pdf)){
  $ad = [uri]::UnescapeDataString((($p.url -split '\?')[0] -split '/')[-1])
  if($ad -notmatch '(?i)\.pdf$'){ continue }
  $et = "$($p.etiket)"
  $sinif = if((TrSade $et) -match $ETIKET_BELGE){ 'sinav-belgesi' }
           elseif($ad -match $EVRAK){ 'sinav-evraki' }
           elseif($ad -match $GENIS){ 'sinav-belgesi' }
           else { 'ilgisiz' }
  $var = @($havuz | Where-Object { $_.url -eq $p.url })
  if($var.Count){
    # Ayni adres domain taramasindan da gelmisse ETIKET KAZANIR (daha guvenilir).
    if($sinif -eq 'sinav-belgesi'){ $var[0].sinif = 'sinav-belgesi' }
    if(-not $var[0].etiket){ $var[0] | Add-Member -NotePropertyName etiket -NotePropertyValue $et -Force }
    continue
  }
  [void]$havuz.Add([pscustomobject]@{ url=$p.url; damga=$p.ilk_goruldu; ad=$ad; sinif=$sinif; etiket=$et
                                      donem_ipucu="$($p.donem_ipucu)"; onceki_metin="$($p.onceki_metin)" })
}

# --- ANLAMLI DOSYA ADI ------------------------------------------------------
#  GUID adiyla inen kitapcik ayristiriciya "donemi okunamayan belge" olarak
#  girer - ambarda hangi sinava ait oldugu KAYBOLUR. Ayristirici donemi dosya
#  adindan okuyor (desen: <sinav>-<donem>-<geri kalani>), o yuzden ad sayfadaki
#  baglamdan YENIDEN KURULUR: spk-2010_kasim-temel_duzey_a.pdf
#  Baglam okunamazsa AD UYDURULMAZ; GUID korunur ve karnede "donem ?" sayilir.
$AYLAR_TR = @{ 'ocak'='ocak'; 'subat'='subat'; 'şubat'='subat'; 'mart'='mart'; 'nisan'='nisan'
               'mayis'='mayis'; 'mayıs'='mayis'; 'haziran'='haziran'; 'temmuz'='temmuz'
               'agustos'='agustos'; 'ağustos'='agustos'; 'eylul'='eylul'; 'eylül'='eylul'
               'ekim'='ekim'; 'kasim'='kasim'; 'kasım'='kasim'; 'aralik'='aralik'; 'aralık'='aralik' }
function AnlamliAd($h){
  if(-not $h.donem_ipucu){ return $null }
  $ip = TrSade "$($h.donem_ipucu)"
  $ay = ''; $yil = ''
  foreach($k in $AYLAR_TR.Keys){ if($ip -match [regex]::Escape((TrSade $k))){ $ay = $AYLAR_TR[$k]; break } }
  $my = [regex]::Match($ip, '(20\d{2}|19\d{2})'); if($my.Success){ $yil = $my.Groups[1].Value }
  if(-not $ay -or -not $yil){ return $null }

  # ders: baglantinin onundeki metnin kuyrugu ("... temel duzey cumartesi 1.oturum")
  $t = TrSade "$($h.onceki_metin)"
  $t = $t -replace '<[^>]*>', ' '
  $t = $t -replace '(a-b|a|b)\s*kitapcigi', ' '
  $t = $t -replace 'cevap\s*anahtari', ' '
  $t = ($t -replace '[^a-z0-9\. ]', ' ') -replace '\s+', ' '
  $t = $t.Trim()
  if($t.Length -gt 60){ $t = $t.Substring($t.Length - 60).Trim() }
  $ders = ($t -replace '\s+', '_')
  if(-not $ders){ $ders = 'bilinmeyen' }

  $et = TrSade "$($h.etiket)"
  $grup = if($et -match 'a-b'){ 'ab' } elseif($et -match '^\s*a\b'){ 'a' } elseif($et -match '^\s*b\b'){ 'b' } else { 'x' }
  $tur  = if($et -match 'cevap'){ 'cevap' } else { 'soru' }
  $ad = ('spk-{0}_{1}-{2}_{3}_{4}.pdf' -f $yil, $ay, $ders, $grup, $tur)
  return ($ad -replace '[^\w\.\-]', '_')
}

# Ayni dosya birden fazla host altinda arsivlenmis olabilir
# (spl.com.tr / www.spl.com.tr). Dosya ADINA gore tekillestirilir.
$tekil = @{}
foreach($h in $havuz){
  $a = $h.ad.ToLower()
  if(-not $tekil.ContainsKey($a)){ $tekil[$a] = $h }
}
$adaylar = @($tekil.Values | Where-Object { $_.sinif -eq 'sinav-belgesi' } | Sort-Object ad)
$evrak   = @($tekil.Values | Where-Object { $_.sinif -eq 'sinav-evraki' })
$ilgisiz = @($tekil.Values | Where-Object { $_.sinif -eq 'ilgisiz' })

Yaz ("`nHAVUZ: {0} tekil PDF · sinav-belgesi {1} · sinav-evraki {2} · ilgisiz {3}" -f `
      $tekil.Count, $adaylar.Count, $evrak.Count, $ilgisiz.Count) 'Cyan'
if($Tavan -gt 0 -and $adaylar.Count -gt $Tavan){
  Yaz ("  TAVAN: {0} adaydan yalniz ilk {1} indirilecek (DENEME KOSUSU - tam kosu degil)" -f $adaylar.Count, $Tavan) 'Yellow'
  $adaylar = @($adaylar | Select-Object -First $Tavan)
}

# --- INDIRME ----------------------------------------------------------------
function GecerliPdfMi([string]$yol){
  if(-not (Test-Path $yol)){ return $false }
  if((Get-Item $yol).Length -lt 1024){ return $false }
  $b = [IO.File]::ReadAllBytes($yol)
  return ($b[0] -eq 0x25 -and $b[1] -eq 0x50 -and $b[2] -eq 0x44 -and $b[3] -eq 0x46)
}

# --- RESMI ADRES CANLI MI? (dosya basina degil, BIR KEZ olculur) ------------
# 31.08 KUSUR: her dosya icin once resmi adres deneniyordu. 500 dosya x bir
# istek = 500 bosa istek; ustelik arsiv istekleri 3 deneme x 240 sn tavanla
# yapiliyordu ve ilk tam kosu 120 dakikalik is tavanini asti, HICBIR rapor
# yazilamadi (is tavana carpinca `if: always()` adimlari da kosmaz).
# Dogrusu: resmi adresin olu olup olmadigi ORNEKLE olculur, sonuc yazilir.
$ornekler = @($adaylar | Select-Object -First 3)
$resmiCanli = $false
foreach($o in $ornekler){
  $u = $o.url -replace '^http://', 'https://' -replace ':80/', '/'
  $t = [IO.Path]::GetTempFileName()
  & $curl -sS -m 45 -A $UA -L -o $t $u 2>$null | Out-Null
  if(GecerliPdfMi $t){ $resmiCanli = $true }
  Remove-Item $t -Force -ErrorAction SilentlyContinue
  if($resmiCanli){ break }
}
Yaz ("RESMI ADRES: {0}" -f $(if($resmiCanli){'CANLI - once oradan denenecek'}else{'OLU (ornek 3 adres gecerli PDF vermedi) - dogrudan arsiv kopyasi'})) `
    $(if($resmiCanli){'Green'}else{'Yellow'})

# --- ARSIV DAMGASI HARITASI -------------------------------------------------
# Sayfadan gelen kayitlarin damgasi SAYFANIN damgasidir, dosyanin degil.
# Dosyanin kendi damgasi varsa o kullanilir; yoksa "arsivde kaydi yok" hukmu
# TEK denemeyle verilir - 12 dakikalik zaman asimi zinciri kurulmaz.
$arsivDamga = @{}
foreach($d in @($kesif.domain_pdf)){ $arsivDamga[$d.url.ToLower()] = $d.damga }

$kayit = New-Object System.Collections.ArrayList
$kullanilanAd = @{}
$i = 0
foreach($a in $adaylar){
  $i++
  # Dosya adi diske guvenli hale getirilir (arsivde %20, parantez vb. var).
  # Sayfa baglami okunabildiyse GUID yerine anlamli ad kullanilir.
  $guvenli = AnlamliAd $a
  if(-not $guvenli){ $guvenli = ($a.ad -replace '[^\w\.\-]', '_') }
  if($kullanilanAd.ContainsKey($guvenli)){
    $kullanilanAd[$guvenli]++
    $guvenli = ($guvenli -replace '\.pdf$', ('_{0}.pdf' -f $kullanilanAd[$guvenli]))
  } else { $kullanilanAd[$guvenli] = 1 }
  $yol = Join-Path $Hedef $guvenli
  $s = [ordered]@{ dosya=$guvenli; ad=$a.ad; etiket="$($a.etiket)"; url=$a.url; kaynak=''; durum='KIRMIZI'; sebep=''
                   bayt=0; sayfa=0; metin_krk=0; hash=$null }

  # Dosyanin KENDI arsiv damgasi varsa o kullanilir; yoksa sayfanin damgasi
  # (arsiv en yakin kopyaya yonlendirir, ama kayit hic yoksa 404 doner).
  $kendiDamga = $arsivDamga[$a.url.ToLower()]
  $damgaVar = [bool]$kendiDamga
  if(-not $kendiDamga){ $kendiDamga = $a.damga }
  $s.arsiv_kaydi = $damgaVar

  if((Test-Path $yol) -and -not $Zorla -and (GecerliPdfMi $yol)){
    $s.kaynak = 'diskte'
  } else {
    if($resmiCanli){
      $resmi = $a.url -replace '^http://', 'https://' -replace ':80/', '/'
      & $curl -sS -m 60 -A $UA -L -o $yol $resmi 2>$null | Out-Null
      if(GecerliPdfMi $yol){ $s.kaynak = 'resmi' }
    }
    if(-not $s.kaynak){
      # ARSIV KOPYASI ("id_" = arsivin kendi basligi eklenmemis HAM bayt).
      # Kaydi olan dosyaya 2 deneme; kaydi olmayana TEK deneme - yoksa yok.
      Remove-Item $yol -Force -ErrorAction SilentlyContinue
      $ayna = "https://web.archive.org/web/{0}id_/{1}" -f $kendiDamga, $a.url
      $kacDeneme = if($damgaVar){ 2 } else { 1 }
      for($d = 1; $d -le $kacDeneme; $d++){
        & $curl -sS -m 90 -A $UA -L -o $yol $ayna 2>$null | Out-Null
        if(GecerliPdfMi $yol){ break }
        if($d -lt $kacDeneme){ Start-Sleep -Seconds 4 }
      }
      if(GecerliPdfMi $yol){ $s.kaynak = 'ayna' }
    }
  }

  if(-not $s.kaynak){
    $s.sebep = if($damgaVar){ 'arsivde kaydi VAR ama gecerli PDF inmedi' } else { 'ARSIVDE KAYDI YOK - SPL listeledi, arsiv taramamis' }
    [void]$kayit.Add([pscustomobject]$s)
    Yaz ("  [{0}/{1}] [KIRMIZI] {2} · {3}" -f $i, $adaylar.Count, $guvenli, $s.sebep) 'Red'
    continue
  }

  $s.bayt = (Get-Item $yol).Length
  if($s.bayt -lt $ASGARI_BAYT){
    $s.sebep = ("COK KUCUK: {0} bayt" -f $s.bayt)
    [void]$kayit.Add([pscustomobject]$s)
    Yaz ("  [{0}/{1}] [KIRMIZI] {2} · {3}" -f $i, $adaylar.Count, $guvenli, $s.sebep) 'Red'
    continue
  }

  if($pdftotext){
    $tmp = [IO.Path]::GetTempFileName()
    try {
      & pdftotext -enc UTF-8 -q $yol $tmp 2>$null
      $metin = if(Test-Path $tmp){ [IO.File]::ReadAllText($tmp, [Text.Encoding]::UTF8) } else { '' }
      $s.metin_krk = "$metin".Trim().Length
      $s.sayfa = ([regex]::Matches("$metin", "`f")).Count + 1
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    if($s.metin_krk -lt 500){
      $s.durum = 'KOR'
      $s.sebep = ("metin katmani yok/zayif ({0} krk) - dosya TAM, okunmasi OCR ister" -f $s.metin_krk)
    } else { $s.durum = 'YESIL' }
  } else {
    $s.durum = 'KOR'; $s.sebep = 'pdftotext yok - metin kapisi OLCULEMEDI'
  }
  $s.hash = (Get-FileHash -Path $yol -Algorithm SHA256).Hash.Substring(0,16)
  [void]$kayit.Add([pscustomobject]$s)
  $renk = switch($s.durum){ 'YESIL'{'Green'} 'KOR'{'Yellow'} default{'Red'} }
  Yaz ("  [{0}/{1}] [{2}] {3} ({4} bayt · {5} sayfa · kaynak={6})" -f `
        $i, $adaylar.Count, $s.durum, $guvenli, $s.bayt, $s.sayfa, $s.kaynak) $renk
}

# --- RAPOR ------------------------------------------------------------------
$yesil = @($kayit | Where-Object { $_.durum -eq 'YESIL' })
$kor   = @($kayit | Where-Object { $_.durum -eq 'KOR' })
$kirmizi = @($kayit | Where-Object { $_.durum -eq 'KIRMIZI' })
$hukum = if($kirmizi.Count){ 'KIRMIZI' } elseif($kor.Count){ 'SARI' } else { 'YESIL' }

$rapor = [ordered]@{
  olcum      = (Get-Date).ToString('s')
  kosum_yeri = if($env:GITHUB_ACTIONS){ 'github-actions' } else { 'yerel' }
  hedef      = $Hedef
  tavan      = $Tavan
  tam_kosu   = ($Tavan -eq 0)
  havuz_tekil = $tekil.Count
  aday_sinav_belgesi = @($tekil.Values | Where-Object { $_.sinif -eq 'sinav-belgesi' }).Count
  denenen    = $adaylar.Count
  tam        = $yesil.Count
  olculemeyen = $kor.Count
  eksik      = $kirmizi.Count
  arsivde_kaydi_yok = @($kayit | Where-Object { -not $_.arsiv_kaydi -and $_.durum -eq 'KIRMIZI' }).Count
  hukum      = $hukum
  kaynak_dagilimi = @{
    resmi  = @($kayit | Where-Object { $_.kaynak -eq 'resmi' }).Count
    ayna   = @($kayit | Where-Object { $_.kaynak -eq 'ayna' }).Count
    diskte = @($kayit | Where-Object { $_.kaynak -eq 'diskte' }).Count
  }
  elenen_sinav_evraki = @($evrak | ForEach-Object { $_.ad })
  elenen_ilgisiz_sayisi = $ilgisiz.Count
  not = 'PDF depoya GIRMEZ (public depo + FSEK 5846). Yalniz bu envanter girer. Kaynak sutunu: resmi=spl.com.tr, ayna=web.archive.org ham kopya.'
  dosyalar = @($kayit)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/spl-cikmis-indirme.json'),
  (ConvertTo-Json -InputObject $rapor -Depth 6), [Text.UTF8Encoding]::new($false))

Yaz ''
Yaz ("DENENEN {0} · TAM {1} · OLCULEMEYEN {2} · EKSIK {3} · HUKUM {4}" -f `
      $adaylar.Count, $yesil.Count, $kor.Count, $kirmizi.Count, $hukum) `
    $(if($hukum -eq 'YESIL'){'Green'}elseif($hukum -eq 'KIRMIZI'){'Red'}else{'Yellow'})
foreach($k in $kirmizi){ Yaz ("  EKSIK: {0} · {1}" -f $k.dosya, $k.sebep) 'Red' }
Yaz ("  -> veri/spl-cikmis-indirme.json · PDF: {0}" -f $Hedef)
exit 0
