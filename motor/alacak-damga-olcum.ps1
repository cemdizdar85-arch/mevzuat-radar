# ============================================================================
#  ALACAK DAMGA OLCUMU - SALT OKUMA  (29.08.2026)
#
#  NEDEN VAR: 2026-08-29-alacak-ret-iflas-metinden.sql goçünün BOYUTUNU basmadan
#  once bilmek gerekiyordu. Supabase SQL editorune erisimim yok - ama ayni olcum
#  service_role ile kasadan yapilabilir. Cem hakli olarak sordu: "iki sayim
#  sorgusunu sen kosamiyor musun?" Kosabiliyorum; SQL editoru degil, PostgREST.
#
#  BU BETIK HICBIR SEY DEGISTIRMEZ. Yalniz okur ve iki sayiyi verir:
#    A) karar_durumu='ret_iflas'   ama METINDE iflas karari YOK  -> cikacak
#    B) karar_durumu='ret_kaldirma' ama METINDE iflas karari VAR -> girecek
#  Ayrica her iki kumeden ORNEK basliklar + karar cumlesi basar ki gozle
#  bakilabilsin (damga degistiren her isin on sarti - 29.08 kurali).
#
#  TURKCE HARF TUZAGI: PowerShell/.NET regex'te /i bayragi I<->i eslemez ve
#  dosya kodlamasi bozulursa desen sessizce kayar. Bu yuzden metin ONCE saf
#  ASCII'ye indirgenir (Sadelestir), desenler de ASCII yazilir. Boylece
#  "IFLASINA" / "iflasina" / "Iflasina" hepsi ayni deseni tutturur.
#
#  Env: SUPABASE_SERVICE_KEY (sart)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$URL = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'https://bjrleanjpyujtajmazxn.supabase.co' }
$KEY = $env:SUPABASE_SERVICE_KEY
if (-not $KEY) { Write-Host "KOR: SUPABASE_SERVICE_KEY yok - olcum YAPILAMADI (sifir sonuc degil)."; exit 0 }

$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')

function Cek([string]$durum) {
  $hepsi = @(); $ofset = 0; $adim = 500
  while ($true) {
    $u = "$URL/rest/v1/alacak_ilan?select=ilan_no,il,baslik,metin,karar_durumu,tarih" +
         "&tarih=gte.$bas&karar_durumu=eq.$durum&metin=not.is.null" +
         "&order=tarih.desc&limit=$adim&offset=$ofset"
    $ham  = Invoke-WebRequest -Method Get -Uri $u -Headers $H -TimeoutSec 120
    $rows = @($ham.Content | ConvertFrom-Json)
    if (-not $rows.Count) { break }
    $hepsi += $rows
    if ($rows.Count -lt $adim) { break }
    $ofset += $adim
  }
  return $hepsi
}

# Turkce -> ASCII (desenler ASCII yazilsin diye)
$MAP = @{ [char]0x0131='i'; [char]0x0130='i'; [char]0x015F='s'; [char]0x015E='s'
          [char]0x011F='g'; [char]0x011E='g'; [char]0x00E7='c'; [char]0x00C7='c'
          [char]0x00F6='o'; [char]0x00D6='o'; [char]0x00FC='u'; [char]0x00DC='u' }
function Sadelestir([string]$s) {
  if (-not $s) { return '' }
  $sb = New-Object Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) {
    if ($MAP.ContainsKey($ch)) { [void]$sb.Append($MAP[$ch]) } else { [void]$sb.Append($ch) }
  }
  return $sb.ToString().ToLowerInvariant()
}

# 29.08 ILK DESEN KIRLI CIKTI - GOZLE BAKINCA YAKALANDI. Eski desen 169 aday
# buluyordu ama orneklerin yarisi TERS anlamliydi:
#   "iflas sartlari olusmadigindan iflas karari VERILMESINE YER OLMADIGINA"
#   "borca batik OLMAMASI nedeniyle iflasina karar VERILMESINE YER OLMADIGINA"
# Yani mahkeme iflas karari VERMEMIS. Eski desen 'verilmesine' kismini yakalayip
# 'yer olmadigina'yi gormuyordu; ayrica '292' tek basina cok genisti
# ("IIK 292 uyarinca iflas sartlari olusmadigindan..." da tutuyordu).
# YENI KURAL: once KESIN kalip aranir, sonra eslesmenin KOMSULUGUNDA olumsuzlama
# var mi diye bakilir. Desen degil, BAGLAM karar verir.
$IFLAS_KARARI = 'itibariyle\s+iflasina|iflasina\s+karar\s+veril(di|mis|mistir|erek)|iflasinin\s+acilmasina|iflas(inin)?\s+acilmasina\s+karar'
# Eslesmenin +-90 karakter komsulugunda bunlardan biri varsa KARAR YOKTUR:
$OLUMSUZ = 'yer\s+olmadig|olusmadig|gerek\s+olmadig|verilebilec|verilmesini\s+iste|talep\s+edebilec|kaldirilmasina\s+karar'
$TERS_TUZAK = 'iflasin\s+kaldirilmas'

function IflasKarariVar([string]$metin) {
  $m = Sadelestir $metin
  if ($m -match $TERS_TUZAK) { return $false }
  foreach ($mm in [regex]::Matches($m, $IFLAS_KARARI)) {
    $bas = [Math]::Max(0, $mm.Index - 90)
    $son = [Math]::Min($m.Length, $mm.Index + $mm.Length + 90)
    $pencere = $m.Substring($bas, $son - $bas)
    if ($pencere -notmatch $OLUMSUZ) { return $true }   # bir tane temiz eslesme yeter
  }
  return $false
}
function KararCumlesi([string]$metin) {
  $m = Sadelestir $metin
  # Yalniz OLUMSUZLANMAMIS eslesmenin cevresini basar - gozle bakan kisi
  # elenmis olani degil, KABUL EDILEN kalibi gormeli.
  foreach ($mm in [regex]::Matches($m, $IFLAS_KARARI)) {
    $bas = [Math]::Max(0, $mm.Index - 90)
    $son = [Math]::Min($m.Length, $mm.Index + $mm.Length + 90)
    $pencere = $m.Substring($bas, $son - $bas)
    if ($pencere -notmatch $OLUMSUZ) { return ($pencere -replace '\s+', ' ') }
  }
  return '-'
}

Write-Host "Kasadan cekiliyor (salt okuma)..."
$retIflas    = Cek 'ret_iflas'
$retKaldirma = Cek 'ret_kaldirma'
Write-Host ("  ret_iflas    : {0} metinli ilan" -f $retIflas.Count)
Write-Host ("  ret_kaldirma : {0} metinli ilan" -f $retKaldirma.Count)
if (-not $retIflas.Count -and -not $retKaldirma.Count) { Write-Host "KOR: 0 satir geldi, olcum guvenilmez."; exit 0 }

$A = @($retIflas    | Where-Object { -not (IflasKarariVar $_.metin) })   # cikacak
$B = @($retKaldirma | Where-Object {      (IflasKarariVar $_.metin)  })  # girecek

Write-Host ''
Write-Host ('=' * 74)
Write-Host ("A) ret_iflas AMA metninde iflas karari YOK  -> CIKACAK : {0} / {1}" -f $A.Count, $retIflas.Count)
Write-Host ("B) ret_kaldirma AMA metninde iflas karari VAR -> GIRECEK: {0} / {1}" -f $B.Count, $retKaldirma.Count)
Write-Host ("   Goç sonrasi beklenen ret_iflas = {0} - {1} + {2} = {3}" -f `
  $retIflas.Count, $A.Count, $B.Count, ($retIflas.Count - $A.Count + $B.Count))
Write-Host ''
Write-Host 'A KUMESI - IL DAGILIMI (Bursa kalibi burada gorunmeli):'
$A | Group-Object il | Sort-Object Count -Descending | Select-Object -First 8 |
  ForEach-Object { Write-Host ("  {0,-16} {1,3}" -f $_.Name, $_.Count) }
Write-Host ''
Write-Host 'A KUMESI - ORNEK 6 (basligi iflas diyor, metni demiyor):'
$A | Select-Object -First 6 | ForEach-Object {
  Write-Host ("  [{0}] {1}" -f $_.il, $_.baslik.Substring(0, [Math]::Min(58, $_.baslik.Length)))
  $ilk = (Sadelestir $_.metin); $ilk = ($ilk -replace '\s+', ' ')
  Write-Host ("     metin: {0}" -f $ilk.Substring(0, [Math]::Min(120, $ilk.Length)))
}
Write-Host ''
Write-Host 'B KUMESI - IL DAGILIMI (Istanbul burada gorunmeli):'
$B | Group-Object il | Sort-Object Count -Descending | Select-Object -First 8 |
  ForEach-Object { Write-Host ("  {0,-16} {1,3}" -f $_.Name, $_.Count) }
Write-Host ''
Write-Host 'B KUMESI - ORNEK 8 (metni iflas diyor, damgasi demiyor) - GOZLE BAK:'
$B | Select-Object -First 8 | ForEach-Object {
  Write-Host ("  [{0}] {1}" -f $_.il, $_.baslik.Substring(0, [Math]::Min(56, $_.baslik.Length)))
  Write-Host ("     karar: {0}" -f (KararCumlesi $_.metin))
}

# ============================================================================
#  YAZMA MODU  (YAZ=1)  - varsayilan KAPALI
#  Ayri bir "onarim betigi" YAZILMADI bilerek: desen mantigi TEK YERDE dursun.
#  Iki dosyada ayni regex'i tasimak, birini duzeltip digerini unutmak demektir -
#  bugun tam bunu SQL goçünde yasadik (169 vs 46).
#  Geri alinabilir: degistirilen her satirin ESKI damgasi once yedege yazilir.
# ============================================================================
if ($env:YAZ -ne '1') {
  Write-Host ''
  Write-Host 'KURU KOSU: hicbir sey degistirilmedi. Gercek onarim icin YAZ=1 ile kos.'
  exit 0
}

Write-Host ''
Write-Host ('=' * 74)
Write-Host 'YAZMA MODU ACIK - damgalar guncellenecek.'

$degisecek = @()
$A | ForEach-Object { $degisecek += [pscustomobject]@{ ilan_no=$_.ilan_no; eski='ret_iflas';    yeni='ret_kaldirma' } }
$B | ForEach-Object { $degisecek += [pscustomobject]@{ ilan_no=$_.ilan_no; eski='ret_kaldirma'; yeni='ret_iflas'    } }
if (-not $degisecek.Count) { Write-Host 'Degisecek kayit yok.'; exit 0 }

# 1) YEDEK ONCE (geri donus yolu acik olmadan yazma yapilmaz)
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$yedekYol = Join-Path $kok 'veri\alacak-damga-yedek.json'
$yedek = [ordered]@{
  olcum   = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama= 'Damga onarimindan ONCEKI degerler. Geri almak icin her ilan_no eski degerine set edilir.'
  adet    = $degisecek.Count
  kayitlar= $degisecek
}
[IO.File]::WriteAllText($yedekYol, ($yedek | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
Write-Host ("Yedek yazildi: {0} kayit -> {1}" -f $degisecek.Count, $yedekYol)

# 2) PATCH - gruplar halinde (URL uzunluk sinirina takilmamak icin)
$PH = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'Content-Type' = 'application/json'; Prefer = 'return=minimal' }
$yazilan = 0; $hata = 0
foreach ($hedefDurum in @('ret_kaldirma','ret_iflas')) {
  $liste = @($degisecek | Where-Object { $_.yeni -eq $hedefDurum } | ForEach-Object { $_.ilan_no })
  for ($i = 0; $i -lt $liste.Count; $i += 20) {
    $parca = $liste[$i..([Math]::Min($i + 19, $liste.Count - 1))]
    $inList = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
    $u = "$URL/rest/v1/alacak_ilan?ilan_no=in.($inList)"
    $govde = @{ karar_durumu = $hedefDurum } | ConvertTo-Json -Compress
    try {
      Invoke-RestMethod -Method Patch -Uri $u -Headers $PH -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 90 | Out-Null
      $yazilan += $parca.Count
    } catch {
      $hata += $parca.Count
      Write-Host ("  PATCH hatasi ({0}, {1} kayit): {2}" -f $hedefDurum, $parca.Count, $_.Exception.Message)
    }
    Start-Sleep -Milliseconds 200
  }
}
Write-Host ("Yazilan: {0} · hata: {1}" -f $yazilan, $hata)

# 3) YAZ -> GERI OKU -> KARSILASTIR  (yukleyici-sessiz-kayip dersi)
Write-Host ''
Write-Host 'GERI OKUMA...'
$yeniIflas    = Cek 'ret_iflas'
$yeniKaldirma = Cek 'ret_kaldirma'
$beklenen = $retIflas.Count - $A.Count + $B.Count
Write-Host ("  ret_iflas    : {0}  (beklenen {1})" -f $yeniIflas.Count, $beklenen)
Write-Host ("  ret_kaldirma : {0}  (beklenen {1})" -f $yeniKaldirma.Count, ($retKaldirma.Count + $A.Count - $B.Count))
Write-Host ("  TOPLAM       : {0}  (once {1}) <- KORUNMALI" -f `
  ($yeniIflas.Count + $yeniKaldirma.Count), ($retIflas.Count + $retKaldirma.Count))
$kalanKirli = @($yeniIflas | Where-Object { -not (IflasKarariVar $_.metin) }).Count
Write-Host ("  ret_iflas icinde metninde iflas karari OLMAYAN: {0} (0 olmali)" -f $kalanKirli)
if ($yeniIflas.Count -ne $beklenen -or $kalanKirli -ne 0 -or
    ($yeniIflas.Count + $yeniKaldirma.Count) -ne ($retIflas.Count + $retKaldirma.Count)) {
  Write-Host 'KIRMIZI: geri okuma beklenenle TUTMADI. Yedek: veri/alacak-damga-yedek.json'
  exit 1
}
Write-Host 'YESIL: damga onarildi, sayilar tutuyor.'
