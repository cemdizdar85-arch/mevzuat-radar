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

# ---- cift tikla acilan HTML rapor ------------------------------------------
$h = New-Object System.Text.StringBuilder
[void]$h.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$h.AppendLine("<title>RG Taramasi - $Tarih</title><style>")
[void]$h.AppendLine('body{margin:0;background:#06090f;color:#eef2f7;font-family:"Segoe UI",system-ui,Arial,sans-serif;line-height:1.6}')
[void]$h.AppendLine('.wrap{max-width:860px;margin:0 auto;padding:28px 18px 60px} h1{font-size:24px;letter-spacing:-.6px;margin:0 0 4px}')
[void]$h.AppendLine('.alt{color:#93a1b3;font-size:13px;margin-bottom:22px} h2{font-size:15px;color:#26d0fe;text-transform:uppercase;letter-spacing:1.2px;margin:26px 0 10px;border-bottom:1px solid rgba(255,255,255,.09);padding-bottom:6px}')
[void]$h.AppendLine('.m{background:#0d141e;border:1px solid rgba(255,255,255,.1);border-left:4px solid #ff6b5e;border-radius:11px;padding:12px 15px;margin-bottom:8px;font-size:14px}')
[void]$h.AppendLine('.m.gri{border-left-color:#5d6b7c;opacity:.75} .m a{color:#eef2f7;text-decoration:none} .m a:hover{color:#26d0fe}')
[void]$h.AppendLine('</style></head><body><div class="wrap">')
[void]$h.AppendLine("<h1>Resmi Gazete Taramasi</h1><div class='alt'>$Tarih | Toplam $($madde.Count) madde | Ilgili: $ilgiliToplam | <a href='$url' style='color:#26d0fe'>Kaynak sayi</a></div>")
foreach($k in $sonuc.Keys){
  $grup = $sonuc[$k]; if(-not $grup.Count){ continue }
  [void]$h.AppendLine("<h2>$k ($($grup.Count))</h2>")
  foreach($md in $grup){ [void]$h.AppendLine("<div class='m'><a href='$($md.url)' target='_blank'>$($md.baslik)</a></div>") }
}
[void]$h.AppendLine("<h2>Kategorisiz kalan ($($digerIlgili.Count)) - goz at</h2>")
foreach($md in $digerIlgili){ [void]$h.AppendLine("<div class='m gri'><a href='$($md.url)' target='_blank'>$($md.baslik)</a></div>") }
[void]$h.AppendLine('</div></body></html>')
$htmlYol = Join-Path $ciktiDir ("rapor-" + $gunKlas + ".html")
[System.IO.File]::WriteAllText($htmlYol, $h.ToString(), (New-Object System.Text.UTF8Encoding($true)))

# ---- SITEYE KONACAK SAYFA: radar.html (proje kokune yazilir) ----------------
# Not: Bu otomatik ON TARAMADIR - hap kart degildir; dogrulama iddiasi TASIMAZ.
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Bugün RG'de - $Tarih | Mevzuat Radarı</title>")
[void]$s.AppendLine('<meta name="description" content="Resmî Gazete otomatik radar taraması: bugün işletmeleri ilgilendiren gümrük, gözetim, vergi ve teşvik düzenlemeleri.">')
[void]$s.AppendLine('<style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%);--red:#ff6b5e}')
[void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}')
[void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px}')
[void]$s.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}.top a:hover{color:var(--ink)}')
[void]$s.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$s.AppendLine('h1{font-size:clamp(24px,4.5vw,32px);letter-spacing:-.9px;margin:4px 0 4px;font-weight:800}')
[void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:8px}')
[void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 24px}')
[void]$s.AppendLine('h2{font-size:13px;color:var(--accent2);text-transform:uppercase;letter-spacing:1.3px;margin:26px 0 10px;border-bottom:1px solid var(--line);padding-bottom:7px;font-weight:800}')
[void]$s.AppendLine('.m{background:var(--panel);border:1px solid var(--line);border-left:4px solid var(--red);border-radius:12px;padding:13px 16px;margin-bottom:9px;font-size:14px}')
[void]$s.AppendLine('.m a{color:var(--ink);text-decoration:none}.m a:hover{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(47,123,255,.16),rgba(38,208,254,.07)),var(--panel);border:1px solid rgba(62,155,255,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px;letter-spacing:-.4px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(46,140,255,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">MR</span><a href="index.html">Mevzuat Radarı</a> · Bugün RG''de</div>')
[void]$s.AppendLine("<h1>Bugün Resmî Gazete'de ne var?</h1>")
[void]$s.AppendLine("<div class='alt'>$Tarih tarihli sayının radar taraması — $($madde.Count) maddeden <b style='color:var(--ink)'>$ilgiliToplam</b> tanesi işletmeleri ilgilendiriyor.</div>")
[void]$s.AppendLine('<div class="uyari">Bu liste otomatik ön taramadır; başlıklar Resmî Gazete fihristinden alınır ve tıklandığında kaynağa gider. Hangi maddenin SENİ etkilediğini söyleyen kişisel radar (hap kartlar) yakında.</div>')
foreach($k in $sonuc.Keys){
  $grup = $sonuc[$k]; if(-not $grup.Count){ continue }
  [void]$s.AppendLine("<h2>$k ($($grup.Count))</h2>")
  foreach($md in $grup){ [void]$s.AppendLine("<div class='m'><a href='$($md.url)' target='_blank' rel='noopener'>$($md.baslik)</a></div>") }
}
[void]$s.AppendLine('<div class="cta"><h3>Bunlardan hangisi SENİ etkiliyor?</h3>')
[void]$s.AppendLine('<p>Listeye her gün bakmak yerine firmanı tanıt; tabi olduğun yükümlülükleri 3 dakikada gör. Ücretsiz, kayıtsız.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Kaynak: <a href='$url' target='_blank' rel='noopener'>Resmî Gazete, $Tarih</a> · Mevzuat Radarı otomatik taraması · Bilgilendirme amaçlıdır.</div>")
[void]$s.AppendLine('</div></body></html>')
$radarYol = Join-Path (Split-Path -Parent $here) "radar.html"
[System.IO.File]::WriteAllText($radarYol, $s.ToString(), (New-Object System.Text.UTF8Encoding($true)))
Write-Host ("Site sayfasi uretildi: " + $radarYol) -ForegroundColor Cyan

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
