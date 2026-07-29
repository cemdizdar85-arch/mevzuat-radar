# ============================================================================
#  TEBLİĞ DAMGASI — gözetim tebliğleri değişti mi?   (PARA HARCAMAZ)
#
#  Cem (29.07): "bunu zaten biz sistemde yok mu, Resmî Gazete her gün iniyor,
#  indirebildiklerimizi indirip kontrol sağlayabiliriz."
#  Haklıydı — mekanizma zaten vardı, EKSİK OLAN KAPSAMDI. `mevzuat-yut.ps1`
#  her gün mevzuat.gov.tr'den konsolide PDF indirip hash'liyor; ama listesinde
#  yalnız KANUNLAR var. GTİP aracının kalbi olan 43 gözetim TEBLİĞİ o listeye
#  hiç girmemişti — bu yüzden 11.07'den beri değişip değişmediklerini kimse
#  bilmiyordu.
#
#  İKİ İŞİ AYIRIYORUM (önemli):
#    TESPİT   — tebliğ değişti mi?  → hash, BEDAVA, bu betik
#    AYRIŞTIRMA — tablodaki GTİP/kıymet → API gerekir (tablo-hasat.ps1)
#  Tespit her gün koşar; ayrıştırma yalnız değişiklik varsa ve API açıkken.
#  Böylece "veri eskidi ama kimse bilmiyor" hâli biter.
#
#  TEBLİĞ LİSTESİ UYDURULMUYOR: veri/gtip-durum.json'un kendi kayıtlarındaki
#  kaynak adreslerinden (MevzuatNo=NNNNN) okunur. Yani izlenen küme, aracın
#  fiilen dayandığı kümeyle BİREBİR aynı — biri diğerinden sapamaz.
#
#  Çıktı: veri/teblig-damga.json (hash tablosu) + değişen varsa exit 1
#  NOT: mevzuat.gov.tr çıplak curl'e 403 veriyor, tarayıcı User-Agent şart.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/teblig-damga-log.txt') -Force | Out-Null } catch {}

$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
$durumYol = Join-Path $kok 'veri/gtip-durum.json'
$damgaYol = Join-Path $kok 'veri/teblig-damga.json'

if(-not (Test-Path $durumYol)){ Write-Host "gtip-durum.json yok - atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

# --- izlenecek teblig kumesi: ARACIN KENDI VERISINDEN
$ham = [IO.File]::ReadAllText($durumYol, [Text.Encoding]::UTF8)
$noSet = @{}
foreach($m in [regex]::Matches($ham, 'MevzuatNo=(\d+)')){ $noSet[$m.Groups[1].Value] = 1 }
$tebSet = @{}
foreach($m in [regex]::Matches($ham, '"teblig":\s*"([^"]+)"')){ $tebSet[$m.Groups[1].Value] = 1 }
$nolar = @($noSet.Keys | Sort-Object { [int]$_ })
Write-Host ("Izlenecek teblig: {0} mevzuatNo  ({1} teblig no)" -f $nolar.Count, $tebSet.Count)
if($nolar.Count -eq 0){ Write-Host "Kaynak adresi bulunamadi - atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

$eski = @{}
$ilkKurulum = -not (Test-Path $damgaYol)
if(-not $ilkKurulum){
  try {
    $e = Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($p in $e.tebligler.PSObject.Properties){ $eski[$p.Name] = $p.Value }
  } catch { $ilkKurulum = $true }
}

function Damga([byte[]]$b){
  $sha = [Security.Cryptography.SHA256]::Create()
  return (($sha.ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0,16)
}

$yeniTablo = [ordered]@{}
$degisen = New-Object System.Collections.Generic.List[object]
$inemeyen = New-Object System.Collections.Generic.List[string]
$sayac = 0
foreach($no in $nolar){
  $sayac++
  $url = "https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.$no.pdf"
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri $url -UserAgent $UA -TimeoutSec 60
    $bayt = if($r.Content -is [byte[]]){ $r.Content } else { [Text.Encoding]::UTF8.GetBytes("$($r.Content)") }
    if($bayt.Length -lt 2000){ $inemeyen.Add("$no (govde cok kucuk: $($bayt.Length) bayt)"); continue }
    $d = Damga $bayt
    $yeniTablo[$no] = [ordered]@{ damga=$d; boyut=$bayt.Length; kontrol=(Get-Date -Format 'dd.MM.yyyy HH:mm') }
    if(-not $ilkKurulum -and $eski.ContainsKey($no) -and "$($eski[$no].damga)" -ne $d){
      $degisen.Add([ordered]@{ mevzuatNo=$no; eski="$($eski[$no].damga)"; yeni=$d
                               eski_boyut=[int]"$($eski[$no].boyut)"; yeni_boyut=$bayt.Length; url=$url })
    }
  } catch {
    $inemeyen.Add("$no ($($_.Exception.Message))")
  }
  if($sayac % 10 -eq 0){ Write-Host ("  ...{0}/{1}" -f $sayac, $nolar.Count) }
}

Write-Host ("  indirilen : {0}" -f $yeniTablo.Count)
Write-Host ("  inemeyen  : {0}" -f $inemeyen.Count)
foreach($x in ($inemeyen | Select-Object -First 8)){ Write-Host ("     {0}" -f $x) }

$cikti = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Gozetim tebliglerinin konsolide PDF parmak izi. Degisen teblig = veri/gtip-durum.json ESKIMIS demektir; tablo-hasat.ps1 yeniden kosmali (API gerekir)."
  ilk_kurulum = $ilkKurulum
  izlenen = $yeniTablo.Count
  inemeyen = $inemeyen
  degisen = $degisen
  tebligler = $yeniTablo
}
[IO.File]::WriteAllText($damgaYol, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> veri/teblig-damga.json" )

if($ilkKurulum){
  Write-Host ""
  Write-Host ("ILK KURULUM: {0} teblig damgalandi. Karsilastirma bir sonraki kosudan itibaren." -f $yeniTablo.Count)
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}
if($degisen.Count -eq 0){
  Write-Host ""
  Write-Host "TEMIZ: izlenen tebliglerin hicbiri degismemis - gtip-durum.json guncel."
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

Write-Host ""
Write-Host "======================================================================"
Write-Host ("  {0} GOZETIM TEBLIGI DEGISTI - veri/gtip-durum.json ESKIDI" -f $degisen.Count)
Write-Host "======================================================================"
foreach($d in $degisen){
  Write-Host ("  mevzuatNo {0}  ({1} -> {2} bayt)" -f $d.mevzuatNo, $d.eski_boyut, $d.yeni_boyut)
  Write-Host ("     {0}" -f $d.url)
}
Write-Host ""
Write-Host "  YAPILACAK: tablo-hasat.ps1 yeniden kosmali (API gerekir - tablolari"
Write-Host "  modele okutuyor). O kosana kadar GTIP aracindaki gozetim verisi"
Write-Host "  ESKIDIR; arac zaten hasat tarihini ekranda gosteriyor."
Write-Host "  KOSU BILEREK KIRMIZI: sessiz rapor okunmaz."
try{Stop-Transcript|Out-Null}catch{}
exit 1
