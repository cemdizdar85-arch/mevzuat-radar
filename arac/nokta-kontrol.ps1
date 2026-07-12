# ============================================================================
#  NOKTA-KONTROL — bilinen kod -> doğru cevap regresyon testi
#  Amac: 8480/8517 turu ESLESTIRME (4-hane cokertme) hatalarini yakalamak.
#  veri/nokta-kontrol.json vakalarini site verisine (gtip-kdv/otv/ekvergi.json)
#  karsi sinar. Bir vaka patlarsa -> exit 1 (CI commit'i durur, Cem'e alert).
#  Karttaki eslestirme mantigi (gtip.html) BIREBIR portlanmistir.
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veri = Join-Path $kok "veri"

$vakalar = (Get-Content (Join-Path $veri "nokta-kontrol.json") -Raw -Encoding UTF8 | ConvertFrom-Json).vakalar
$KDV = Get-Content (Join-Path $veri "gtip-kdv.json")     -Raw -Encoding UTF8 | ConvertFrom-Json
$OTV = Get-Content (Join-Path $veri "gtip-otv.json")     -Raw -Encoding UTF8 | ConvertFrom-Json
$EK  = Get-Content (Join-Path $veri "gtip-ekvergi.json") -Raw -Encoding UTF8 | ConvertFrom-Json

function D([string]$kod){ return ($kod -replace '[^\d]','') }

# --- KDV: kdvKart 'uygular' predikati (tumF | poz(4h) | spesifik kod) ---
function Test-Kdv([string]$kod){
  $d = D $kod; $f = $d.Substring(0,2); $poz = $d.Substring(0,4)
  $rec = $KDV.fasil.$f
  if(-not $rec){ return 'genel' }
  $hukumler = @(); if($rec.o1){ $hukumler += $rec.o1 }; if($rec.o10){ $hukumler += $rec.o10 }
  foreach($h in $hukumler){
    if($h.kosul -eq $true){ continue }   # kosula bagli hukum (yalniz kullanilmis vb.) tek basina indirimli SAYILMAZ
    if($h.tumF -eq $true){ return 'indirimli' }
    if($h.poz -and (@($h.poz) -contains $poz)){ return 'indirimli' }
    if($h.kod){ foreach($k in $h.kod){ $k = "$k"; if($d.StartsWith($k) -or $k.StartsWith($d)){ return 'indirimli' } } }
  }
  return 'genel'
}

# --- OTV: otvKart (poz 4h/2h; rec.kod beyaz-listesi varsa alt-kod eslesmesi) ---
function Test-Otv([string]$kod){
  $d = D $kod
  $rec = $OTV.pozisyon.($d.Substring(0,4))
  if(-not $rec){ $rec = $OTV.pozisyon.($d.Substring(0,2)) }
  if(-not $rec){ return 'yok' }
  if($rec.kod){
    $m = $false
    foreach($k in $rec.kod){ $k = "$k"; if($d.StartsWith($k) -or $k.StartsWith($d)){ $m = $true; break } }
    if(-not $m){ return 'yok' }
  }
  return 'var'
}

# --- GEKAP: gekapKart (poz 4h; koşullu girdi = ör. 2710 yağlama yağı, benzin hariç) ---
function Test-Gekap([string]$kod){
  $d = D $kod; $poz = $d.Substring(0,4)
  $u = $EK.gekap.pozisyon.$poz
  if(-not $u){ return 'yok' }
  if($u.kosul -eq $true){
    foreach($h in $u.haricKod){ $h = "$h"; if($d.StartsWith($h)){ return 'yok' } }
    return 'kosullu'
  }
  return 'var'
}

# --- DFIF: ihracatKart (6-hane alt kod, yoksa 4-hane poz) ---
function Test-Dfif([string]$kod){
  $d = D $kod; $k6 = $d.Substring(0,6); $k4 = $d.Substring(0,4)
  $P = $EK.dfif.pozisyon
  if($P.$k6 -or $P.$k4){ return 'var' } else { return 'yok' }
}

$gecen = 0; $kalan = @()
foreach($v in $vakalar){
  $sonuc = switch($v.katman){
    'kdv'   { Test-Kdv   $v.kod }
    'otv'   { Test-Otv   $v.kod }
    'gekap' { Test-Gekap $v.kod }
    'dfif'  { Test-Dfif  $v.kod }
    default { "BILINMEYEN-KATMAN($($v.katman))" }
  }
  if($sonuc -eq $v.bekle){
    $gecen++
    Write-Host ("  OK   [{0,-5}] {1,-20} -> {2}" -f $v.katman, $v.kod, $sonuc)
  } else {
    $kalan += "$($v.katman) $($v.kod): beklenen '$($v.bekle)' geldi '$sonuc'  |  $($v.kaynak)"
    Write-Host ("  HATA [{0,-5}] {1,-20} -> beklenen '{2}', gelen '{3}'" -f $v.katman, $v.kod, $v.bekle, $sonuc) -ForegroundColor Red
  }
}

""
"NOKTA-KONTROL: $gecen/$($vakalar.Count) gecti."
if($kalan.Count -gt 0){
  ""
  "!!! $($kalan.Count) VAKA PATLADI — veri regresyonu:"
  $kalan | ForEach-Object { "   - $_" }
  exit 1
}
"Tum vakalar temiz."
