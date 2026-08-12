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
  "gözetim","damping","korunma önlem","ek mali yükümlülük","haksız rekabet","ilave gümrük","ithalat rejimi","askıya alma",
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

# ---------------------------------------------------------------------------
# GTIP VERI SINYALI (13.08 Cem: "haber beklemeden... acik noktalari kapat").
# Bugunku basliklar gtip.html'i besleyen VERIYI etkileyebilecek turdense
# (gozetim/damping/IGV/rejim/askiya/OTV/KDV) Cem'e ayni gun mail duser -
# kart uretiminden BAGIMSIZ ve anahtarsiz/bedava. 11.07 revalorizasyonu
# 3 gun fark edilmemisti; bu sinyalle ayni gun ogrenilir.
# ---------------------------------------------------------------------------
$GTIP_ETKI = @("gözetim","damping","ilave gümrük","ithalat rejimi","askıya alma","korunma önlem","ek mali yükümlülük","özel tüketim","katma değer vergisi")
$vuranlar = @($secilen | Where-Object { $t = Norm $_.baslik; ($GTIP_ETKI | Where-Object { $t.Contains((Norm $_)) }).Count -gt 0 })
if($vuranlar.Count -gt 0){
  $liste = ($vuranlar | ForEach-Object { "- " + $_.baslik }) -join "`n"
  Write-Host ("GTIP SINYALI: {0} baslik veriyi etkileyebilir - mail gonderiliyor." -f $vuranlar.Count)
  $mb = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = "TETIKTE GTIP SINYALI - bugunku RG'de veriyi etkileyebilecek teblig var ($Gun)"
    from_name  = "Tetikte RG Nobetcisi"
    email      = "cemdizdar85@hotmail.com"
    message    = "Bugunku RG'de gtip.html verilerini (gozetim/damping/IGV/rejim/askiya/OTV/KDV) etkileyebilecek basliklar:`n$liste`n`nYapilacak: ilgili tabloyu iki bagimsiz okumayla (parser + gorsel) teyit edip gtip veri dosyasini guncelle - 13.08 revalorizasyon yamasi ornektir."
  } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Uri "https://api.web3forms.com/submit" -Method Post -ContentType "application/json" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 30 | Out-Null; Write-Host "Sinyal maili gitti." } catch { Write-Host ("Sinyal maili gitmedi: " + $_.Exception.Message) }
}
exit 0
