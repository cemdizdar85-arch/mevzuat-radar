# ============================================================================
#  RG INDIR - gunun Resmi Gazete fihristinden isletmeyi ilgilendiren tebligleri
#  bulup HAM .htm olarak motor/arsiv/<gun>/ altina indirir (windows-1254 bozulmadan,
#  bytes olarak). Kart motoru (kart-toplu.ps1) bu klasoru bekler.
#  Kullanim: -Gun 13-07-2026   (dd-MM-yyyy)
#  Cikti kodu her zaman 0 (sayi yok / ilgili teblig yok = hata degil).
# ============================================================================
param([Parameter(Mandatory=$true)][string]$Gun)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = $Gun.Split("-"); $Tarih = "$($p[0]).$($p[1]).$($p[2])"
$UA = "Mozilla/5.0 (MevzuatRadar-KartMotoru)"

function Norm([string]$s){
  if($null -eq $s){ return "" }
  $s = $s.Replace([string][char]0x130,"i").Replace("I","i")
  return $s.ToLowerInvariant()
}

# Isletmeyi ilgilendiren konu anahtarlari (rg-tarama kategorileriyle uyumlu; genis ama alakasiz
# atama/ilan gurultusunu almaz). Yeni konu gerekirse buraya eklenir.
$ANAHTARLAR = @(
  "gözetim","damping","korunma önlem","ek mali yükümlülük","haksız rekabet",
  "ithalat","ihracat","gümrük","tarife kontenjan","kota","menşe","dahilde işleme","hariçte işleme",
  "katma değer vergisi","kdv","özel tüketim","ötv","gelir vergisi","kurumlar vergisi","vergi usul","damga vergisi","harçlar",
  "sosyal güvenlik","sgk","asgari ücret","prime esas",
  "ürün güvenliği","denetimi tebliğ","tareks","ce işaret",
  "teşvik","destek","yatırımlarda devlet yardım",
  "sınai mülkiyet","kamu ihale","ihale tebliğ","kambiyo","ihracat bedel"
)

$url = "https://www.resmigazete.gov.tr/$Tarih"
Write-Host "Fihrist: $url"
try {
  $html = (Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 60 -UseBasicParsing).Content
} catch {
  Write-Host "Fihrist alinamadi ($Tarih) - bugun sayi yok olabilir. Cikiliyor."
  exit 0
}

$rx = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/(?<d>\d{8}-\d+)\.htm)"[^>]*>(?<t>.*?)</a>'
$secilen = @()
foreach($m in $rx.Matches($html)){
  $t = ($m.Groups["t"].Value -replace "<[^>]+>"," " -replace "\s+"," ").Trim()
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  if($t.Length -lt 15){ continue }
  $n = Norm $t
  $vur = $false
  foreach($a in $ANAHTARLAR){ if($n.Contains((Norm $a))){ $vur = $true; break } }
  if(-not $vur){ continue }
  $u = $m.Groups["u"].Value
  if($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
  if($secilen | Where-Object { $_.url -eq $u }){ continue }
  $secilen += [pscustomobject]@{ url = $u; dosya = ($m.Groups["d"].Value + ".htm"); baslik = $t }
}

if(-not $secilen.Count){ Write-Host "Ilgili teblig bulunamadi ($Tarih). Cikiliyor."; exit 0 }

$hedef = Join-Path $here ("arsiv\" + $Gun)
New-Item -ItemType Directory -Force $hedef | Out-Null
$ok = 0
$wc = New-Object System.Net.WebClient
foreach($s in $secilen){
  try {
    # HAM byte indir - windows-1254 kodlamasi bozulmadan diske yazilir
    # NOT: WebClient header'lari HER istekten sonra sifirlar -> UA dongu icinde eklenir
    $wc.Headers.Add("User-Agent",$UA)
    $b = $wc.DownloadData($s.url)
    [System.IO.File]::WriteAllBytes((Join-Path $hedef $s.dosya), $b)
    $ok++
    Write-Host ("  indirildi: {0}  ({1})" -f $s.dosya, $s.baslik.Substring(0,[Math]::Min(70,$s.baslik.Length)))
  } catch { Write-Host ("  INDIRILEMEDI: " + $s.url) -ForegroundColor Yellow }
  Start-Sleep -Milliseconds 400
}
Write-Host ("TOPLAM: {0}/{1} teblig -> {2}" -f $ok, $secilen.Count, $hedef)
exit 0
