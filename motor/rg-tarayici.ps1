# ============================================================================
#  RG TARAYICI v0 — Mevzuat Radarı motor dairesi, ilk taş
#  Ne yapar: verilen tarihin Resmî Gazete fihristini çeker, başlıkları
#  kategorilere süzer, rapor (md+json) üretir, ilgili tebliğ HTML'lerini
#  arşivler.
#  Çalıştırma:
#    powershell -ExecutionPolicy Bypass -File rg-tarayici.ps1
#    powershell -ExecutionPolicy Bypass -File rg-tarayici.ps1 -Tarih 11.07.2026
#  Not: Bu klasör (motor/) SİTEYE YÜKLENMEZ — iç araçtır.
# ============================================================================
param(
  [string]$Tarih = (Get-Date).ToString("dd.MM.yyyy")
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- yardımcı: Türkçe-normalize (büyük İ/I sorunu için) --------------------
function Norm([string]$s){
  if($null -eq $s){ return "" }
  $s = $s.Replace([string][char]0x130,"i").Replace("I","i")  # İ -> i, I -> i
  return $s.ToLowerInvariant()
}

# ---- kategori tanımları (plan: tek işleme dokunan 10 alan) -----------------
$KATEGORILER = [ordered]@{
  "Gözetim / Damping / Korunma" = @("gözetim","damping","haksız rekabet","korunma önlem","ek mali yükümlülük")
  "Ürün Güvenliği / Denetim"    = @("ürün güvenliği","denetimi tebliğ","standardizasyon","tareks","ce işaret")
  "Gümrük / İthalat-İhracat"    = @("gümrük","ithalat","ihracat","tarife kontenjan","kota","menşe","serbest bölge","dahilde işleme","hariçte işleme")
  "Kambiyo / Finans"            = @("kambiyo","ihracat bedel","döviz","sermaye hareket")
  "Vergi"                       = @("katma değer vergisi","kdv","özel tüketim","ötv","gelir vergisi","kurumlar vergisi","vergi usul","damga vergisi","kkdf")
  "Teşvik / Destek"             = @("teşvik","destek","hibe","yatırımlarda devlet yardım")
  "Çalışma / SGK"               = @("sosyal güvenlik","sgk","iş kanunu","asgari ücret","istihdam")
}

# ---- fihristi indir ---------------------------------------------------------
$url = "https://www.resmigazete.gov.tr/$Tarih"
Write-Host "Fihrist cekiliyor: $url"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-v0)")
try {
  $bytes = $wc.DownloadData($url)
} catch {
  Write-Host "HATA: sayfa indirilemedi ($Tarih). O tarihte sayi olmayabilir." -ForegroundColor Red
  exit 1
}
$html = [System.Text.Encoding]::UTF8.GetString($bytes)

# ---- fihrist maddelerini ayikla --------------------------------------------
# Kalip: <a href="...eskiler/YYYY/AA/YYYYAAGG-N.htm">BASLIK</a> (PDF'ler ilan bolumudur, alinmaz)
$madde = @()
$rx = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/\d{8}-\d+\.htm)"[^>]*>(?<t>.*?)</a>'
foreach($m in $rx.Matches($html)){
  $u = $m.Groups["u"].Value
  if($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
  $t = ($m.Groups["t"].Value -replace "<[^>]+>"," " -replace "\s+"," ").Trim()
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = $t.TrimStart([char]0x2013,[char]0x2014,[char]0x2015,'-',' ')   # fihrist "--" artigini temizle
  if($t.Length -lt 15){ continue }                     # bos/kisa linkleri at
  if($madde | Where-Object { $_.url -eq $u }){ continue }  # tekrarlari at
  $madde += [pscustomobject]@{ baslik=$t; url=$u }
}
if(-not $madde.Count){ Write-Host "Fihristte madde bulunamadi - sayfa yapisi degismis olabilir." -ForegroundColor Red; exit 1 }
Write-Host ("Fihristte {0} madde bulundu." -f $madde.Count)

# ---- kategorize et ----------------------------------------------------------
$sonuc = [ordered]@{}
foreach($k in $KATEGORILER.Keys){ $sonuc[$k] = @() }
$digerIlgili = @()
foreach($md in $madde){
  $n = Norm $md.baslik
  $eslesti = $false
  foreach($k in $KATEGORILER.Keys){
    foreach($anahtar in $KATEGORILER[$k]){
      if($n.Contains((Norm $anahtar))){ $sonuc[$k] += $md; $eslesti = $true; break }
    }
    if($eslesti){ break }
  }
  if(-not $eslesti){ $digerIlgili += $md }
}

# ---- rapor + arsiv ----------------------------------------------------------
$gunKlas = $Tarih.Replace(".","-")   # 11-07-2026
$ciktiDir = Join-Path $here "cikti"
$arsivDir = Join-Path $here ("arsiv\" + $gunKlas)
New-Item -ItemType Directory -Force $ciktiDir | Out-Null

$ilgiliToplam = 0
$mdRapor = New-Object System.Text.StringBuilder
[void]$mdRapor.AppendLine("# RG Taramasi - $Tarih")
[void]$mdRapor.AppendLine("")
[void]$mdRapor.AppendLine("Kaynak: $url | Toplam fihrist maddesi: $($madde.Count)")
[void]$mdRapor.AppendLine("")
foreach($k in $sonuc.Keys){
  $grup = $sonuc[$k]
  if(-not $grup.Count){ continue }
  $ilgiliToplam += $grup.Count
  [void]$mdRapor.AppendLine("## $k ($($grup.Count))")
  foreach($md in $grup){ [void]$mdRapor.AppendLine("- [$($md.baslik)]($($md.url))") }
  [void]$mdRapor.AppendLine("")
}
[void]$mdRapor.AppendLine("## Kategorisiz kalan ($($digerIlgili.Count)) - goz at, kacan var mi")
foreach($md in $digerIlgili | Select-Object -First 40){ [void]$mdRapor.AppendLine("- [$($md.baslik)]($($md.url))") }

$mdYol = Join-Path $ciktiDir ("rapor-" + $gunKlas + ".md")
[System.IO.File]::WriteAllText($mdYol, $mdRapor.ToString(), (New-Object System.Text.UTF8Encoding($true)))

# json (ileride kart uretim hattinin girdisi)
$jsonYol = Join-Path $ciktiDir ("veri-" + $gunKlas + ".json")
$jsonObj = [ordered]@{ tarih=$Tarih; kaynak=$url; toplam=$madde.Count; kategoriler=$sonuc; kategorisiz=$digerIlgili }
($jsonObj | ConvertTo-Json -Depth 6) | Out-File $jsonYol -Encoding utf8

# ilgili maddelerin ham HTML'ini arsivle (ileride LLM/vision isleme icin)
if($ilgiliToplam -gt 0){
  New-Item -ItemType Directory -Force $arsivDir | Out-Null
  $i = 0
  foreach($k in $sonuc.Keys){
    foreach($md in $sonuc[$k]){
      $i++
      $ad = ($md.url -split "/")[-1]
      try {
        # WebClient her istekten sonra basliklari sifirlar - her seferinde yeniden ekle
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-v0)")
        $wc.DownloadFile($md.url, (Join-Path $arsivDir $ad))
        Start-Sleep -Milliseconds 250   # kamu sunucusuna nazik davran
      } catch { Write-Host ("  arsiv hatasi: {0} ({1})" -f $md.url, $_.Exception.Message) -ForegroundColor Yellow }
    }
  }
  Write-Host ("Arsivlendi: {0} madde -> {1}" -f $i, $arsivDir)
}

Write-Host ""
Write-Host ("BITTI. Ilgili madde: {0} | Rapor: {1}" -f $ilgiliToplam, $mdYol) -ForegroundColor Green
foreach($k in $sonuc.Keys){ if($sonuc[$k].Count){ Write-Host ("  {0}: {1}" -f $k, $sonuc[$k].Count) } }
