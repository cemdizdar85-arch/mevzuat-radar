# ============================================================================
#  RG TARAMA (CI surumu) - GitHub Actions uzerinde her sabah calisir.
#  Gorevi: bugunun RG fihristini cek, kategorile, radar.html'i uret.
#  Yerel kardesi: motor/rg-tarayici.ps1 (arsiv + rapor da uretir).
# ============================================================================
$ErrorActionPreference = "Stop"

# --- Turkiye saatiyle bugunun tarihi (CI sunucusu UTC calisir) ---------------
$tz = $null
foreach($id in @("Europe/Istanbul","Turkey Standard Time")){
  try { $tz = [TimeZoneInfo]::FindSystemTimeZoneById($id); break } catch {}
}
$simdi = if($tz){ [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz) } else { Get-Date }
$Tarih = $simdi.ToString("dd.MM.yyyy")

function Norm([string]$s){
  if($null -eq $s){ return "" }
  $s = $s.Replace([string][char]0x130,"i").Replace("I","i")
  return $s.ToLowerInvariant()
}

$KATEGORILER = [ordered]@{
  "Gözetim / Damping / Korunma" = @("gözetim","damping","haksız rekabet","korunma önlem","ek mali yükümlülük")
  "Ürün Güvenliği / Denetim"    = @("ürün güvenliği","denetimi tebliğ","standardizasyon","tareks","ce işaret")
  "Gümrük / İthalat-İhracat"    = @("gümrük","ithalat","ihracat","tarife kontenjan","kota","menşe","serbest bölge","dahilde işleme","hariçte işleme")
  "Kambiyo / Finans"            = @("kambiyo","ihracat bedel","döviz","sermaye hareket")
  "Vergi"                       = @("katma değer vergisi","kdv","özel tüketim","ötv","gelir vergisi","kurumlar vergisi","vergi usul","damga vergisi","kkdf")
  "Teşvik / Destek"             = @("teşvik","destek","hibe","yatırımlarda devlet yardım")
  "Çalışma / SGK"               = @("sosyal güvenlik","sgk","iş kanunu","asgari ücret","istihdam")
}

$url = "https://www.resmigazete.gov.tr/$Tarih"
Write-Host "Fihrist: $url"
try {
  $resp = Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (MevzuatRadar-CI)" -TimeoutSec 60 -UseBasicParsing
  $html = $resp.Content
} catch {
  Write-Host "Sayfa alinamadi ($Tarih) - bugun sayi henuz yok olabilir. Cikiliyor (hata degil)."
  exit 0
}

$madde = @()
$rx = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/\d{8}-\d+\.htm)"[^>]*>(?<t>.*?)</a>'
foreach($m in $rx.Matches($html)){
  $u = $m.Groups["u"].Value
  if($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
  $t = ($m.Groups["t"].Value -replace "<[^>]+>"," " -replace "\s+"," ").Trim()
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = $t.TrimStart([char]0x2013,[char]0x2014,[char]0x2015,'-',' ')
  if($t.Length -lt 15){ continue }
  if($madde | Where-Object { $_.url -eq $u }){ continue }
  $madde += [pscustomobject]@{ baslik=$t; url=$u }
}
if(-not $madde.Count){ Write-Host "Fihrist maddesi bulunamadi - sayfa yapisi degismis olabilir. Cikiliyor."; exit 0 }
Write-Host ("Asil madde: {0}" -f $madde.Count)

# ---- MUKERRER SAYILAR (yilbasi kabusu: onemli setler mukerrerde cikar) ----
$gg,$aa,$yyyy = $Tarih.Split(".")
$iso = "$yyyy-$aa-$gg"
$mukNolar = [regex]::Matches($html, [regex]::Escape("tarih=$iso") + "[^""']*?mukerrer=(\d+)") | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Unique
$mukToplam = 0
foreach($mk in $mukNolar){
  $mf = $null
  foreach($deneme in 1..3){
    try { $mf = (Invoke-WebRequest -Uri "https://www.resmigazete.gov.tr/fihrist?tarih=$iso&mukerrer=$mk" -UserAgent "Mozilla/5.0 (MevzuatRadar-CI)" -TimeoutSec 45 -UseBasicParsing).Content; break }
    catch { Start-Sleep -Seconds 3 }
  }
  if(-not $mf){ continue }
  $mrx = [regex]('(?is)<a[^>]+href="([^"]*eskiler/\d{4}/\d{2}/\d{8}M' + $mk + '(?:-\d+)?\.pdf)"[^>]*>(.*?)</a>')
  foreach($m in $mrx.Matches($mf)){
    $u = $m.Groups[1].Value
    if($u -match "^//"){ $u = "https:" + $u } elseif($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
    $t = ($m.Groups[2].Value -replace "<[^>]+>"," " -replace "\s+"," ").Trim()
    $t = [System.Net.WebUtility]::HtmlDecode($t).TrimStart([char]0x2013,[char]0x2014,[char]0x2015,'-',' ')
    if($t.Length -lt 15){ continue }
    if($madde | Where-Object { $_.url -eq $u }){ continue }
    $madde += [pscustomobject]@{ baslik=("[$mk. Mükerrer] " + $t); url=$u }
    $mukToplam++
  }
  Start-Sleep -Milliseconds 800
}
Write-Host ("Toplam madde: {0} (mukerrer: {1})" -f $madde.Count, $mukToplam)

$sonuc = [ordered]@{}
foreach($k in $KATEGORILER.Keys){ $sonuc[$k] = @() }
$ilgiliToplam = 0
foreach($md in $madde){
  $n = Norm $md.baslik
  foreach($k in $KATEGORILER.Keys){
    $vur = $false
    foreach($a in $KATEGORILER[$k]){ if($n.Contains((Norm $a))){ $vur = $true; break } }
    if($vur){ $sonuc[$k] += $md; $ilgiliToplam++; break }
  }
}
Write-Host ("Ilgili: {0}" -f $ilgiliToplam)

# --- radar.html uret (repo koku) ---------------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Bugün RG'de - $Tarih | Mevzuat Radarı</title>")
[void]$s.AppendLine('<meta name="description" content="Resmî Gazete otomatik radar taraması: bugün işletmeleri ilgilendiren gümrük, gözetim, vergi ve teşvik düzenlemeleri.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg">')
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
[void]$s.AppendLine('<div class="top"><span class="logo">MR</span><a href="index.html">Mevzuat Radarı</a> · <a href="gtip.html">GTİP Kontrolü</a> · <a href="destekler.html">Destek Radarı</a> · Bugün RG''de</div>')
[void]$s.AppendLine("<h1>Bugün Resmî Gazete'de ne var?</h1>")
[void]$s.AppendLine("<div class='alt'>$Tarih tarihli sayının radar taraması — $($madde.Count) maddeden <b style='color:var(--ink)'>$ilgiliToplam</b> tanesi işletmeleri ilgilendiriyor.</div>")
[void]$s.AppendLine('<div class="uyari">Bu liste otomatik ön taramadır; başlıklar Resmî Gazete fihristinden alınır ve tıklandığında kaynağa gider. Bu maddelerin sade Türkçe özetleri için: <a href="kartlar.html">Günün Hap Kartları →</a></div>')
if($ilgiliToplam -eq 0){
  [void]$s.AppendLine('<div class="m" style="border-left-color:#3ddc97"><b>Bugün işletmeleri doğrudan ilgilendiren düzenleme tespit edilmedi.</b> Sakin bir gün — yarın yine buradayız.</div>')
} else {
  foreach($k in $sonuc.Keys){
    $grup = $sonuc[$k]; if(-not $grup.Count){ continue }
    [void]$s.AppendLine("<h2>$k ($($grup.Count))</h2>")
    foreach($md in $grup){ [void]$s.AppendLine("<div class='m'><a href='$($md.url)' target='_blank' rel='noopener'>$($md.baslik)</a></div>") }
  }
}
[void]$s.AppendLine('<div class="cta"><h3>Bunlardan hangisi SENİ etkiliyor?</h3>')
[void]$s.AppendLine('<p>Listeye her gün bakmak yerine firmanı tanıt; tabi olduğun yükümlülükleri 3 dakikada gör. Ücretsiz, kayıtsız.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Kaynak: <a href='$url' target='_blank' rel='noopener'>Resmî Gazete, $Tarih</a> · Mevzuat Radarı otomatik taraması · Bilgilendirme amaçlıdır.</div>")
[void]$s.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script></div></body></html>')

$kok = Split-Path -Parent $PSScriptRoot   # arac/ klasorunun ustu = repo koku
$hedef = Join-Path $kok "radar.html"
[System.IO.File]::WriteAllText($hedef, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "radar.html uretildi: $hedef"
