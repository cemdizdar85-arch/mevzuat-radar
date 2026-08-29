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

# KARAR deseni: mahkemenin VERDIGI iflas hukmu.
$IFLAS_KARARI = 'iflasinin\s+acilmas|iflasina\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflasina|292'
# ELENECEK: uyari cumlesi (IIK m.288 standart metni) ve TERS anlamli m.182
$UYARI_TUZAK  = 'iflasina\s+karar\s+veril(ebilec|mesini\s+iste)'
$TERS_TUZAK   = 'iflasin\s+kaldirilmas'

function IflasKarariVar([string]$metin) {
  $m = Sadelestir $metin
  if ($m -match $UYARI_TUZAK) { return $false }
  if ($m -match $TERS_TUZAK)  { return $false }
  return [bool]($m -match $IFLAS_KARARI)
}
function KararCumlesi([string]$metin) {
  $m = Sadelestir $metin
  $mm = [regex]::Match($m, '.{0,70}(' + $IFLAS_KARARI + ').{0,80}')
  if ($mm.Success) { return ($mm.Value -replace '\s+', ' ') }
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
Write-Host ''
Write-Host 'NOT: Bu betik HICBIR SEY DEGISTIRMEDI. Sayilar makulse goç basilir:'
Write-Host '     radar-app/sql/2026-08-29-alacak-ret-iflas-metinden.sql'
