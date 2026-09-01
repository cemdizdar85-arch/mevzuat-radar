# ============================================================================
#  SPL CIKMIS SINAV ARSIVI - KARNE ("yarim yutmadik" kapisi)
#
#  Cem: "hepsini yuttugumuza emin olalim, yarim yutmayalim."
#  Bu betik o cumlenin OLCUM karsiligidir. Tek soruyu sorar ve zinciri
#  ADIM ADIM gosterir - hangi adimda kac belge dustugu gorulmeden
#  "tamam" denmez:
#
#     SPL'nin kendi sayfasinda LISTELENEN
#       -> arsivde KAYDI OLAN
#         -> INEN (dort kapiyi gecen)
#           -> METNI CIKAN
#             -> AYRISTIRILAN (soru uretilen)
#
#  Her adimda dusen belgeler ADIYLA yazilir. "Sessiz daraltma yok" kurali:
#  bir belge elendiyse hangi adimda ve neden elendigi bu karnede durur.
#
#  ONEMLI: bu karne "eksik yok" DEMEZ. Yalnizca SPL'nin listesiyle elimizdekini
#  kiyaslar. SPL listesi de eksik olabilir (19-20 Aralik 2014 ve sonrasi icin
#  SPL soru/cevap YAYIMLAMIYOR) - o sinir ayrica yazilir.
#
#  KULLANIM: pwsh -File motor/spl-cikmis-karne.ps1
# ============================================================================
param([switch]$Sessiz)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
function Yaz($m, $renk='Gray'){ if(-not $Sessiz){ Write-Host $m -ForegroundColor $renk } }

function OkuJson([string]$yol){
  $t = Join-Path $kok $yol
  if(-not (Test-Path $t)){ return $null }
  return (Get-Content $t -Raw -Encoding UTF8 | ConvertFrom-Json)
}

$kesif   = OkuJson 'veri/spl-cikmis-envanteri.json'
$indirme = OkuJson 'veri/spl-cikmis-indirme.json'
$ayrisma = OkuJson 'veri/cikmis-soru-ayrisma.json'
if(-not $kesif){ throw 'veri/spl-cikmis-envanteri.json yok - once motor/spl-cikmis-kesif.ps1' }

# --- DONEM/DERS COZUMU ------------------------------------------------------
# SPL'nin arsiv sayfasinda dosya adi GUID'dir; anlam sayfadaki BAGLAMDA durur:
#   "... 31 MAYIS - 1 HAZIRAN 2014 ... Temel Duzey ... A KITAPCIGI"
# Bu yuzden donem ve ders, baglantinin ONUNDEKI metinden okunur. Okunamazsa
# UYDURULMAZ - "?" yazilir ve karnede ayri satirda sayilir.
$AYLAR = 'ocak|subat|şubat|mart|nisan|mayis|mayıs|haziran|temmuz|agustos|ağustos|eylul|eylül|ekim|kasim|kasım|aralik|aralık'
$AYLAR_SADE = 'ocak|subat|mart|nisan|mayis|haziran|temmuz|agustos|eylul|ekim|kasim|aralik'
function DonemCoz([string]$ipucu, [string]$metin){
  if($ipucu){ return $ipucu }
  if(-not $metin){ return '?' }
  $m = [regex]::Match($metin, "(?i)($AYLAR)\s+(\d{4})")
  if($m.Success){ return ('{0} {1}' -f $m.Groups[1].Value, $m.Groups[2].Value) }
  $m = [regex]::Match($metin, '(?<!\d)(20\d{2})(?!\d)')
  if($m.Success){ return $m.Groups[1].Value }
  return '?'
}
function GrupCoz([string]$etiket){
  $e = TrSade $etiket
  if($e -match 'a-b'){ return 'A-B' }
  if($e -match '^\s*a\b'){ return 'A' }
  if($e -match '^\s*b\b'){ return 'B' }
  return '?'
}
# Sayfanin gercek dizilisi (31.08 olculdu):
#     ... Turev Araclar Cumartesi 1.Oturum [A KITAPCIGI] - [B KITAPCIGI]
#         Gayrimenkul Degerleme Uzmanligi Pazar 1.Oturum [A KITAPCIGI] - ...
# Yani DERS, baglantidan onceki SON "KITAPCIGI" isaretinden SONRA baslar.
# B baglantisi icin son isaret hemen onundeki "A KITAPCIGI"dir; o durumda bir
# onceki isaret alinir. Sabit uzunlukta kuyruk almak (ilk denemem) bir onceki
# satirin dersini icine cekiyordu - olculdu, o yuzden boyle yazildi.
# NOT: TrSade tek karakteri tek karakterle degistirdigi icin sade metnin
# indeksleri orijinalle BIREBIR ortusur; kesme orijinal metinde yapilir.
function DersCoz([string]$metin, [string]$donem){
  if(-not $metin){ return '?' }
  $sade = TrSade $metin
  # Bir donemin ILK satirinda onunde hic "KITAPCIGI" isareti yoktur - onunde
  # BASLIK vardir ("... Lisanslama Sinavi Soru Kitapciklari"). O durumda
  # basligin kuyrugu ders adina yapisiyordu; basliklar da kesme noktasi sayilir.
  $isaret = [regex]::Matches($sade, 'kitapcigi|anahtari|kitapciklari|sinavlari|sinavi')
  $t = $metin
  if($isaret.Count -gt 0){
    $son = $isaret[$isaret.Count - 1]
    $kuyruk = $sade.Length - ($son.Index + $son.Length)
    if($kuyruk -le 8 -and $isaret.Count -ge 2){ $son = $isaret[$isaret.Count - 2] }
    $t = $metin.Substring($son.Index + $son.Length)
  }
  # bastaki ayirici ve sondaki "A KITAPCIGI -" kuyrugu temizlenir
  $t = $t -replace '^[\s\-–—:·]+', ''
  $ts = TrSade $t
  $kes = [regex]::Match($ts, '\s*(a-b|a|b)\s*kitapcigi\s*[-–—]*\s*$')
  if($kes.Success){ $t = $t.Substring(0, $kes.Index) }
  if($donem -ne '?'){ $t = $t -replace [regex]::Escape($donem), ' ' }
  $t = ($t -replace '\s+', ' ').Trim()
  if(-not $t){ return '?' }
  if($t.Length -gt 70){ $t = $t.Substring($t.Length - 70).Trim() }
  return $t
}

# Ayni sinav sayfada uc farkli yazimla gecebiliyor ("28-29 Aralik 2013",
# "28– 29 Aralik 2013", "29 Aralik 2013"). Karne bunlari AYRI DONEM sayarsa
# kapsama tablosu yalan soyler. Donem AY+YIL'a indirgenir - SPL'nin sinav
# takviminde ayni ay icinde iki ayri sinav yok.
function DonemNormal([string]$d){
  if(-not $d -or $d -eq '?'){ return '?' }
  $s = TrSade $d
  $m = [regex]::Match($s, "($AYLAR_SADE)\s+((?:19|20)\d{2})")
  if($m.Success){ return ('{0} {1}' -f $m.Groups[1].Value, $m.Groups[2].Value) }
  return $d
}

# --- 1) LISTELENEN ----------------------------------------------------------
# TURKCE BUYUK I TUZAGI (31.08 olculdu): .NET IgnoreCase invariant kulturdur,
# 'İ' ile 'i' orada AYNI HARF DEGILDIR. "A KİTAPÇIĞI" etiketi `(?i)kitapcigi`
# desenine TUTMAZ. Once ASCII'ye katlanir, sonra eslestirilir.
# IKI KATMANLI TUZAK, ikisi de olculdu:
#  (a) PS'de `-replace` harf ayirmaz -> 'Ç' de kucuk 'c' olur, ad bozulur.
#  (b) tr-TR kulturunde Regex `(?i)` 'I'yi NOKTASIZ 'ı'ya katlar -> "ANAHTARI"
#      ile 'anahtari' TR makinede eslesmez (runner en-US oldugu icin orada
#      eslesir: kusur yerelde gorunur, CI'da gorunmez).
# Cozum: buyuk/kucuk TUM Turkce harfleri tek tek katla, InvariantCulture ile
# kucult, desenleri kucuk harf yaz, `(?i)` KULLANMA.
function TrSade([string]$s){
  if(-not $s){ return '' }
  $s = $s -replace '[İIıi]','i' -replace '[Şş]','s' -replace '[Ğğ]','g'
  $s = $s -replace '[Üü]','u'   -replace '[Öö]','o' -replace '[Çç]','c'
  return $s.ToLowerInvariant()
}
$ETIKET_BELGE = '(kitapcigi|cevap\s*anahtari)'
$listelenen = New-Object System.Collections.ArrayList
foreach($p in @($kesif.sayfadan_pdf)){
  if((TrSade "$($p.etiket)") -notmatch $ETIKET_BELGE){ continue }
  $ad = [uri]::UnescapeDataString((($p.url -split '\?')[0] -split '/')[-1])
  $don = DonemCoz "$($p.donem_ipucu)" "$($p.onceki_metin)"
  [void]$listelenen.Add([pscustomobject]@{
    ad     = $ad
    dosya  = ($ad -replace '[^\w\.\-]', '_')
    url    = $p.url
    etiket = "$($p.etiket)"
    grup   = GrupCoz "$($p.etiket)"
    donem  = DonemNormal $don
    donem_ham = $don
    ders   = DersCoz "$($p.onceki_metin)" $don
    tur    = if((TrSade "$($p.etiket)") -match 'cevap'){ 'cevap-anahtari' } else { 'soru-kitapcigi' }
  })
}
# 31.08 KUSUR (olculdu): sayfa her kitapcigi IKI KEZ veriyor - bir kez
# spl.com.tr, bir kez www.spl.com.tr adresiyle. Ham sayim 334 diyordu;
# tekil dosya 167. Tekillestirilmeseydi karne "334 listelendi / 166 arsivde"
# yani %50 gibi YANLIS bir kapsama gosterecekti. Gercek oran 166/167.
# Ayni dosyanin iki adresi de saklanir (biri inmezse oteki denenir).
$tekilAd = [ordered]@{}
foreach($l in $listelenen){
  if($tekilAd.Contains($l.ad)){
    $tekilAd[$l.ad].adresler += $l.url
  } else {
    $l | Add-Member -NotePropertyName adresler -NotePropertyValue @($l.url) -Force
    $tekilAd[$l.ad] = $l
  }
}
$listelenen = @($tekilAd.Values)

# --- 2) ARSIVDE KAYDI OLAN --------------------------------------------------
# 01.09 - ADRES NORMALIZASYONU (bkz motor/spl-cikmis-indir.ps1 aciklamasi):
# arsiv "http://spl.com.tr:80/..." yaziyor, sayfa "https://www.spl.com.tr/...".
# Ham kiyas ISKALIYOR ve karne "arsivde kaydi olan: 0" diyordu.
function UrlAnahtar([string]$u){
  $x = "$u".Trim()
  $x = $x -replace '^https?://', ''
  $x = $x -replace '^www\.', ''
  $x = $x -replace ':(80|443)/', '/'
  return $x.ToLowerInvariant()
}
$arsivde = @{}
foreach($d in @($kesif.domain_pdf)){ $arsivde[(UrlAnahtar $d.url)] = $d.damga }
foreach($l in $listelenen){
  $var = $false
  foreach($u in @($l.adresler)){ if($arsivde.ContainsKey((UrlAnahtar $u))){ $var = $true } }
  $l | Add-Member -NotePropertyName arsiv_kaydi -NotePropertyValue $var -Force
}

# --- 3/4) INEN + METNI CIKAN ------------------------------------------------
# Eslestirme ADLA DEGIL ADRESLE yapilir: indirici GUID adini anlamli adla
# degistiriyor (spk-2010_kasim-temel_duzey_a_soru.pdf), ada bakan eslestirme
# hepsini "INDIRILMEDI" gosterirdi.
$inen = @{}
if($indirme){ foreach($f in @($indirme.dosyalar)){ $inen[(UrlAnahtar $f.url)] = $f } }
foreach($l in $listelenen){
  $f = $null
  foreach($u in @($l.adresler)){ if(-not $f){ $f = $inen[(UrlAnahtar $u)] } }
  if($f){ $l | Add-Member -NotePropertyName dosya -NotePropertyValue "$($f.dosya)" -Force }
  $l | Add-Member -NotePropertyName indi      -NotePropertyValue ($null -ne $f -and $f.durum -ne 'KIRMIZI') -Force
  $l | Add-Member -NotePropertyName metin_krk -NotePropertyValue $(if($f){ [int]$f.metin_krk } else { 0 }) -Force
  $l | Add-Member -NotePropertyName durum     -NotePropertyValue $(if($f){ "$($f.durum)" } else { 'INDIRILMEDI' }) -Force
}

# --- 5) AYRISTIRILAN --------------------------------------------------------
# Ayrisma raporunun alan adlari surumden surume degisebiliyor; bu yuzden
# dosya adini TASIYAN alan aranir, varsayilmaz.
$soruSayisi = @{}
if($ayrisma){
  foreach($k in @($ayrisma.PSObject.Properties)){
    if($k.Value -is [array]){
      foreach($x in $k.Value){
        $adAlani = @($x.PSObject.Properties | Where-Object { "$($_.Value)" -match '(?i)\.pdf$' -or "$($_.Name)" -match '(?i)dosya|kitapcik' }) | Select-Object -First 1
        if(-not $adAlani){ continue }
        $sayiAlani = @($x.PSObject.Properties | Where-Object { "$($_.Name)" -match '(?i)^soru|sayi|adet|yazilan|bulunan' -and $_.Value -is [int] }) | Select-Object -First 1
        if(-not $sayiAlani){ continue }
        $ad = ("$($adAlani.Value)" -split '[\\/]')[-1]
        $soruSayisi[$ad] = [int]$sayiAlani.Value
      }
    }
  }
}
foreach($l in $listelenen){
  $s = 0
  foreach($k in $soruSayisi.Keys){ if($k -eq $l.dosya -or $k -eq $l.ad){ $s = $soruSayisi[$k]; break } }
  $l | Add-Member -NotePropertyName soru -NotePropertyValue $s -Force
}

# --- HUKUM ------------------------------------------------------------------
$kitapcik = @($listelenen | Where-Object { $_.tur -eq 'soru-kitapcigi' })
$zincir = [ordered]@{
  listelenen_toplam   = $listelenen.Count
  soru_kitapcigi      = $kitapcik.Count
  cevap_anahtari      = @($listelenen | Where-Object { $_.tur -eq 'cevap-anahtari' }).Count
  arsivde_kaydi_olan  = @($listelenen | Where-Object { $_.arsiv_kaydi }).Count
  inen                = @($listelenen | Where-Object { $_.indi }).Count
  metni_cikan         = @($listelenen | Where-Object { $_.metin_krk -ge 500 }).Count
  soru_uretilen_belge = @($listelenen | Where-Object { $_.soru -gt 0 }).Count
  toplam_soru         = (@($listelenen | Measure-Object soru -Sum).Sum)
  donemi_okunamayan   = @($listelenen | Where-Object { $_.donem -eq '?' }).Count
}

$rapor = [ordered]@{
  olcum   = (Get-Date).ToString('s')
  kaynak  = 'SPL resmi arsiv sayfasinin arsivlenmis kopyasi (sayfa canli sitede 404)'
  sinir   = '19-20 Aralik 2014 ve SONRASI kagit sinavlar icin SPL soru/cevap YAYIMLAMIYOR; elektronik sinavlar hic yayimlanmadi. Bu karne yalniz SPL"nin yayimladigi donemleri kapsar.'
  zincir  = $zincir
  belgeler = @($listelenen | Sort-Object donem, ders, grup)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/spl-cikmis-karne.json'),
  (ConvertTo-Json -InputObject $rapor -Depth 6), [Text.UTF8Encoding]::new($false))

# --- MD ---------------------------------------------------------------------
$md = New-Object System.Collections.ArrayList
[void]$md.Add('# SPL CIKMIS SINAV ARSIVI - KARNE')
[void]$md.Add('')
[void]$md.Add(('> Olcum: **{0}** · MAKINE CIKTISI (motor/spl-cikmis-karne.ps1) - elle duzenlenmez.' -f $rapor.olcum))
[void]$md.Add('>')
[void]$md.Add(('> {0}' -f $rapor.sinir))
[void]$md.Add('')
[void]$md.Add('## Zincir - hangi adimda kac belge dustu')
[void]$md.Add('')
[void]$md.Add('| Adim | Belge |')
[void]$md.Add('|---|---:|')
foreach($k in $zincir.Keys){ [void]$md.Add(('| {0} | {1} |' -f ($k -replace '_',' '), $zincir[$k])) }
[void]$md.Add('')
[void]$md.Add('## Donem x ders dokumu')
[void]$md.Add('')
[void]$md.Add('| Donem | Ders | Grup | Tur | Durum | Metin (krk) | Soru |')
[void]$md.Add('|---|---|---|---|---|---:|---:|')
foreach($l in ($listelenen | Sort-Object donem, ders, grup)){
  [void]$md.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $l.donem, $l.ders, $l.grup, $l.tur, $l.durum, $l.metin_krk, $l.soru))
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/SPL-CIKMIS-KARNE.md'), (($md -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))

Yaz ''
foreach($k in $zincir.Keys){ Yaz ("  {0,-22} {1}" -f $k, $zincir[$k]) }
Yaz '  -> veri/SPL-CIKMIS-KARNE.md · veri/spl-cikmis-karne.json'
exit 0
