# ============================================================================
#  STANDART ONARICISI - "kiyimdan sonra ambari damgaya geri getir"
#
#  NEDEN VAR (30.08.2026): yukle.yml'in push tetigi SIL-YAZ robotunu uyandirdi,
#  kosu SILME ile GERI YAZMA arasinda kesildi ve standart-madde 8.643 -> 4.449
#  dustu. AYNI SINIF kiyim 27.08'de de yasandi. Iki kez yasanan bir kayip icin
#  "elle 50 komut yaz" bir onarim yolu degildir.
#
#  OLCER -> ONARIR -> GERI OKUR. Uc adim da ayni kosuda.
#
#  NEYE GORE "eksik" der: veri/standart-damga.json. O dosya, ambara NE
#  YAZILDIGININ kaydidir (belge adi -> icerik parmak izi). Hafizadan ya da
#  YUTMA-LISTESI anlatisindan degil, damgadan okur.
#
#  UC SONUC:
#    YESIL     : eksik kalmadi
#    KIRMIZI   : onarimdan sonra hala eksik var
#    OLCULEMEDI: ambar okunamadi / anahtar yok - kusur SAYILMAZ
#
#  Varsayilan KURU PROVA. Yazmak icin -uygula gerekir.
#  0 USD, model yok.
#
#  ! OLCUM NOTU (30.08, bedeli odendi): ambar sayimi PostgREST'te
#    "select=kaynak_ad&limit=1000&offset=N" ile SAYFALANARAK yapilamaz.
#    ORDER yoksa sayfalama kararsizdir: ayni kosuda BDS 315 bir olcumde 64,
#    digerinde 0 cikti. Bu betik sayfalamaz - standart basina Content-Range
#    ile BIREBIR sayar. Yavas ama tekrarlanabilir.
# ============================================================================
param(
  [switch]$uygula,
  [string]$yalniz = '',      # tek standardi onar: -yalniz 'TFRS 16'
  [int]$enFazla = 0          # 0 = sinirsiz; deneme kosusu icin ust sinir
)

$ErrorActionPreference = 'Stop'
$here    = if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$depoKok = Split-Path -Parent $here
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$damgaYol = Join-Path $depoKok 'veri\standart-damga.json'
$raporYol = Join-Path $depoKok 'veri\standart-onarim-raporu.json'
$gunlukYol= Join-Path $depoKok 'veri\standart-onarim-log.txt'

function Yaz($m,$r='Gray'){ Write-Host $m -ForegroundColor $r }

# --- anahtar ---------------------------------------------------------------
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){
  Yaz 'OLCULEMEDI: SUPABASE_SERVICE_KEY yok - ambar okunamadi, kusur sayilmaz.' 'Yellow'
  exit 0
}
$anahtar   = '' + $env:SUPABASE_SERVICE_KEY
$basliklar = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot'; Prefer='count=exact' }
$ambarUcu  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# --- standardin kok adi ----------------------------------------------------
# "TMS 34 p.9 - Ara donem..." -> "TMS 34"   ·  "SBDS 2400 - on bolum" -> "SBDS 2400"
function SO_Kok([string]$s){
  if($s -match '^([A-ZCGIOSU]+\s*\d+[A-Z]?)'){ return ($Matches[1] -replace '\s+',' ') }
  if($s -match '^([A-ZÇĞİÖŞÜ]+\s*\d+[A-Z]?)'){ return ($Matches[1] -replace '\s+',' ') }
  return 'DIGER'
}

# --- ambarda bir standardin parca sayisi (BIREBIR, sayfalamasiz) -----------
# Donus: sayi, ya da -1 (olculemedi). Uc deneme; hepsi duserse -1.
function SO_AmbarSay([string]$kok){
  $desen = [uri]::EscapeDataString($kok + ' *')
  # 30.08 OLCULEN: bu sorgu YUK ALTINDA duser. Sunucu govdesi acikca soyluyor:
  #   {"code":"57014","message":"canceling statement due to statement timeout"}
  # kaynak_ad uzerinde onek taramasi indekssiz; ~10 sn'lik ifade tavanina
  # takiliyor. Ayni sorgu bos anda 2 sn'de donuyor. Yani "olculemedi" cogu
  # zaman GECICI - uc hizli deneme yetmiyor, sabir gerekiyor. BDS 200 bu
  # yuzden iki kez atlandi.
  for($i=1; $i -le 5; $i++){
    try {
      $y = Invoke-WebRequest -UseBasicParsing -Method Get -Headers $basliklar `
           -Uri "$ambarUcu`?select=id&tur=eq.standart-madde&kaynak_ad=like.$desen&limit=1" -TimeoutSec 150
      $cr = ($y.Headers['Content-Range'] -join '')
      if($cr -match '/(\d+)$'){ return [int]$Matches[1] }
      return -1
    } catch { Start-Sleep -Seconds ($i * 3) }   # 3-6-9-12 sn: yuk gecsin diye
  }
  return -1
}

# --- 1/3 · OLC -------------------------------------------------------------
if(-not (Test-Path $damgaYol)){ Yaz "OLCULEMEDI: damga dosyasi yok ($damgaYol)" 'Yellow'; exit 0 }
$damga = Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json
$beklenen = @{}
foreach($ad in $damga.PSObject.Properties.Name){
  $k = SO_Kok $ad
  if($k -eq 'DIGER'){ continue }
  if($beklenen.ContainsKey($k)){ $beklenen[$k]++ } else { $beklenen[$k] = 1 }
}
Yaz "`n=== 1/3 · OLCUM ===" 'Cyan'
Yaz ("  damgada standart: {0}" -f $beklenen.Count)

$oncesi = @{}; $eksikler = @(); $olculemeyen = @()
foreach($k in ($beklenen.Keys | Sort-Object)){
  if($yalniz -ne '' -and $k -ne $yalniz){ continue }
  $n = SO_AmbarSay $k
  $oncesi[$k] = $n
  if($n -lt 0){ $olculemeyen += $k; continue }
  if($n -lt $beklenen[$k]){ $eksikler += [pscustomobject]@{ std=$k; damga=$beklenen[$k]; ambar=$n; eksik=($beklenen[$k]-$n) } }
}
$eksikler = @($eksikler | Sort-Object eksik -Descending)
Yaz ("  eksik standart: {0} · eksik parca: {1} · olculemeyen: {2}" -f `
     $eksikler.Count, (($eksikler | Measure-Object eksik -Sum).Sum), $olculemeyen.Count)
foreach($e in $eksikler){ Yaz ("    {0,-12} damga {1,4} -> ambar {2,4}  EKSIK {3,4}" -f $e.std,$e.damga,$e.ambar,$e.eksik) 'DarkGray' }

if($olculemeyen.Count -gt 0){
  Yaz ("  OLCULEMEYEN: {0}" -f ($olculemeyen -join ', ')) 'Yellow'
}

# ⚠ 30.08 KENDI KUSURUM: burada yalniz $eksikler.Count'a bakiyordum ve
# "eksik standart: 0 · olculemeyen: 1" durumunda ekrana YESIL basiyordum.
# BDS 200 tam bu yuzden iki kez atlandi: sayimi yuk yuzunden dustu, betik
# onu "sorun yok" sandi. Oysa deponun kurali acik: OLCULMEMIS HUCRE
# "saglam" DEGILDIR, ucuncu sonuctur. Olculemeyen varken YESIL yazilmaz.
if($eksikler.Count -eq 0){
  if($olculemeyen.Count -gt 0){
    Yaz ("`nOLCULEMEDI: {0} standardin sayimi alinamadi - 'eksik yok' DENEMEZ." -f $olculemeyen.Count) 'Yellow'
    Yaz "  Ambar yuk altindayken tekrar dene." 'Yellow'
    exit 2
  }
  Yaz "`nYESIL: eksik yok." 'Green'
  exit 0
}
if(-not $uygula){
  Yaz "`nKURU PROVA - hicbir sey yazilmadi. Yazmak icin: -uygula" 'Yellow'
  exit 0
}

# --- 2/3 · ONAR -----------------------------------------------------------
Yaz "`n=== 2/3 · ONARIM ===" 'Cyan'
$yutucu = Join-Path $here 'standart-yut.ps1'
if(-not (Test-Path $yutucu)){ Yaz "KIRMIZI: yutucu bulunamadi ($yutucu)" 'Red'; exit 1 }

$sira = @($eksikler)
if($enFazla -gt 0 -and $sira.Count -gt $enFazla){ $sira = $sira[0..($enFazla-1)] }

$kosanlar = @()
$i = 0
foreach($e in $sira){
  $i++
  Yaz ("  [{0}/{1}] {2} ..." -f $i,$sira.Count,$e.std) 'White'
  $cikti = ''
  try {
    # Not: alt betik kendi hatasinda exit 1 verir; burada AKISI DURDURMAZ.
    # Bir standardin PDF'i inmiyorsa digerlerinin onarimi engellenmemeli.
    $cikti = & powershell -NoProfile -ExecutionPolicy Bypass -File $yutucu -standart $e.std -uygula 2>&1 | Out-String
    $kod   = $LASTEXITCODE
  } catch {
    $cikti = "$_"; $kod = 99
  }
  $ozet = ($cikti -split "`r?`n" | Where-Object { $_ -match 'parca|PDF|KIRMIZI|HATA|yazildi|GERI OKU|indirildi' } | Select-Object -Last 3) -join ' | '
  $kosanlar += [pscustomobject]@{ std=$e.std; kod=$kod; ozet=$ozet }
  Yaz ("        kod={0}  {1}" -f $kod, $ozet) 'DarkGray'
  Add-Content -Path $gunlukYol -Value ("=== {0} · {1} · kod={2}`r`n{3}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm'), $e.std, $kod, $cikti) -Encoding UTF8
}

# --- 3/3 · GERI OKU -------------------------------------------------------
Yaz "`n=== 3/3 · GERI OKUMA ===" 'Cyan'
$kalan = @(); $duzelen = 0; $kazanilan = 0
foreach($e in $sira){
  $n = SO_AmbarSay $e.std
  if($n -lt 0){ $kalan += [pscustomobject]@{ std=$e.std; damga=$e.damga; ambar=-1; durum='OLCULEMEDI' }; continue }
  $kazanilan += [math]::Max(0, $n - $e.ambar)
  if($n -ge $e.damga){ $duzelen++ }
  else { $kalan += [pscustomobject]@{ std=$e.std; damga=$e.damga; ambar=$n; durum='EKSIK' } }
}
$halaEksik = @($kalan | Where-Object { $_.durum -eq 'EKSIK' })
Yaz ("  duzelen: {0}/{1} · kazanilan parca: {2} · hala eksik: {3}" -f $duzelen,$sira.Count,$kazanilan,$halaEksik.Count)
foreach($h in $halaEksik){ Yaz ("    {0,-12} damga {1,4} -> ambar {2,4}" -f $h.std,$h.damga,$h.ambar) 'Yellow' }

# Ucuncu sonuc: olculemeyen varken YESIL yazilmaz. Kusur da sayilmaz -
# "OLCULEMEDI" kendi basina bir sonuctur, iyimser yorumlanmaz.
$sonuc = if($halaEksik.Count -gt 0){ 'KIRMIZI' }
         elseif($olculemeyen.Count -gt 0 -or @($kalan | Where-Object { $_.durum -eq 'OLCULEMEDI' }).Count -gt 0){ 'OLCULEMEDI' }
         else { 'YESIL' }
$cikti = [ordered]@{
  olcum          = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  sonuc          = $sonuc
  bakilan        = $sira.Count
  duzelen        = $duzelen
  kazanilan_parca= $kazanilan
  hala_eksik     = @($halaEksik)
  olculemeyen    = @($olculemeyen)
  not            = 'Beklenen sayi veri/standart-damga.json"dan gelir. Ambar sayimi standart basina birebir yapilir (sayfalama kararsizdir).'
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef $raporYol -Nesne $cikti | Out-Null

Yaz ("`n{0}" -f $sonuc) $(if($sonuc -eq 'YESIL'){'Green'}elseif($sonuc -eq 'OLCULEMEDI'){'Yellow'}else{'Red'})
if($sonuc -eq 'KIRMIZI'){ exit 1 }
if($sonuc -eq 'OLCULEMEDI'){ exit 2 }
exit 0
