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
  # 30.07 (#63): FIRSAT en basta taranir ki "vergi" gibi genel gruplara
  # kacmasin. Maddeler veri/firsat-guncel.json'a da yazilir; uyari robotu
  # tum uyelere duyurur (af/yapilandirma penceresi profil istemez).
  "Fırsat: Yapılandırma / Af"   = @("yeniden yapıland","yapılandırılması","matrah artırım","vergi aff","prim aff","borç aff","taksitlendir","alacakların yapıland")
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

# ---- FIRSAT BESLEMESI (#63): yapilandirma/af maddeleri uyari robotuna ------
$firsatGrup = @($sonuc["Fırsat: Yapılandırma / Af"])
$firsatYol = Join-Path (Split-Path -Parent $PSScriptRoot) "veri/firsat-guncel.json"
$fj = [ordered]@{
  tarih = $Tarih
  maddeler = @($firsatGrup | ForEach-Object { [ordered]@{ baslik = $_.baslik; url = $_.url } })
}
[IO.File]::WriteAllText($firsatYol, (ConvertTo-Json -InputObject $fj -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> veri/firsat-guncel.json ({0} firsat maddesi)" -f $firsatGrup.Count)


# ---- DESTEK CAGRI NOBETCISI (19.08 Cem: "KKYDP'yi RG deseniyle baglayalim") --
# KKYDP (Kirsal Kalkinma Yatirimlarinin Desteklenmesi) basvuru donemleri
# kurumun portalindan degil RG'de TEBLIG ile acilir (portal 502 veriyordu,
# bakanlik sayfasi SharePoint/JS). Bu blok RG fihristinde destek/hibe programi
# acan tebligleri yakalar ve BIRIKIMLI dosyaya yazar; cagri-hasat.ps1 bu dosyayi
# okuyup Destek Radari'na "RG tebligi" kaynagi olarak dusurur.
# Ek istek YOK: fihrist zaten yukarida cekildi.
# DIKKAT: bu dosyanin Norm() fonksiyonu TURKCE HARFLERI KORUR (yalniz I/i + kucuk harf).
# Kaliplar bu yuzden TURKCE yazilir; ASCII yazilirsa (kirsal) HICBIR ZAMAN eslesmez ve
# robot sessizce 0 bulur - 19.08 tohum taramasi bu kusuru yakaladi (KOSGEB kanal vakasi gibi).
$destekKaliplar = @(
  "kırsal kalkınma destekleri", "kırsal kalkınma yatırımlarının desteklenmesi",
  "kırsal kalkınmada uzman eller", "kırsal kalkınma programı",
  "tarıma dayalı ekonomik yatırım", "kırsal ekonomik altyapı"
)
$destekVuran = @()
foreach($md in $madde){
  $n = Norm $md.baslik
  foreach($kalip in $destekKaliplar){
    if($n.Contains((Norm $kalip))){ $destekVuran += [ordered]@{ baslik=$md.baslik; url=$md.url; yayim=$Tarih }; break }
  }
}
$destekYol = Join-Path (Split-Path -Parent $PSScriptRoot) "veri/rg-destek-cagri.json"
$eskiKayitlar = @()
if(Test-Path $destekYol){
  try {
    $eskiDosya = Get-Content $destekYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $eskiKayitlar = @($eskiDosya.tebligler | ForEach-Object { [ordered]@{ baslik=$_.baslik; url=$_.url; yayim=$_.yayim } })
  } catch {}
}
# birikimli havuz: mukerrer URL ayiklanir, 400 gunden eski teblig duser
$havuz = @{}; $birikim = @()
foreach($k in @($destekVuran + $eskiKayitlar)){
  if(-not $k.url -or $havuz.ContainsKey("$($k.url)")){ continue }
  $yeterinceTaze = $true
  try { $yeterinceTaze = ([datetime]::ParseExact("$($k.yayim)","dd.MM.yyyy",$null) -ge (Get-Date).AddDays(-400)) } catch {}
  if(-not $yeterinceTaze){ continue }
  $havuz["$($k.url)"] = 1
  $birikim += $k
}
$dj = [ordered]@{
  guncelleme = "RG fihristinden destek/hibe programi acan tebligler (birikimli). Son tarama: $Tarih."
  tebligler = $birikim
}
[IO.File]::WriteAllText($destekYol, (ConvertTo-Json -InputObject $dj -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> veri/rg-destek-cagri.json ({0} teblig havuzda, bugun {1} yeni)" -f $birikim.Count, $destekVuran.Count)
# ---- SABIT NOBETCISI: sitedeki vergi/sermaye sabitlerini degistiren teblig ----
# cikinca Cem'e mail atar (veri/vergi-sabitleri.json elle guncellenir - guven kurali)
$nobetKaliplar = @("gelir vergisi genel tebli", "kurumlar vergisi genel tebli", "yeniden değerleme oran", "asgari ücret", "harçlar kanunu genel tebli", "vergi usul kanunu genel tebli", "ihracı kayda bağlı", "ihracı yasak", "ön izne bağlı", "kıdem tazminatı", "geri kazanım katılım payı", "ithalat rejimi", "ilave gümrük vergisi", "katma değer vergisi oranlar", "özel tüketim vergisi", "kaynak kullanımını destekleme", "çifte vergilendirme", "gecikme zammı", "damga vergisi", "sınai mülkiyet", "prime esas kazanç", "sosyal sigortalar ve genel sağlık", "asgari sermaye", "türk ticaret kanununda değişiklik", "tevkifat oran", "kâr payı", "kar payı dağıt")
$nobetVuran = @()
foreach($md in $madde){
  $n = Norm $md.baslik
  foreach($kalip in $nobetKaliplar){ if($n.Contains((Norm $kalip))){ $nobetVuran += $md; break } }
}
if($nobetVuran.Count -gt 0){
  Write-Host ("NOBETCI: {0} sabit-tebligi yakalandi, mail gonderiliyor" -f $nobetVuran.Count)
  $liste = ($nobetVuran | ForEach-Object { "- " + $_.baslik + " => " + $_.url }) -join "`n"
  $mailGovde = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = "SABIT NOBETCISI: vergi-sabitleri.json guncellenmeli ($Tarih)"
    from_name  = "Mevzuat Radari Robotu"
    email      = "cemdizdar85@hotmail.com"
    "Yakalanan tebligler" = $liste
    "Yapilacak" = "Claude'a 'sabitleri guncelle' de - tebligden yeni degerleri okuyup veri/vergi-sabitleri.json'u birlikte guncelleyin. Site otomatik beslenir."
  } | ConvertTo-Json
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([System.Text.Encoding]::UTF8.GetBytes($mailGovde)) -ContentType "application/json" -TimeoutSec 30 | Out-Null
    Write-Host "NOBETCI: mail gonderildi"
  } catch { Write-Host ("NOBETCI: mail gonderilemedi - " + $_.Exception.Message) }
}

# --- radar.html uret (repo koku) ---------------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
# 30.07 REBRAND KACAGI KAPANDI: bu CI kalibi hala "Mevzuat Radarı" + MAVI
# yaziyordu - her sabah radar.html'i eski markaya geri boyayacakti. Ayrica
# "Bugün RG'de - <tarih>" basligi sayfa eskiyince yalan soyluyordu.
[void]$s.AppendLine("<title>RG Taraması — $Tarih | Tetikte</title>")
[void]$s.AppendLine('<meta name="description" content="Resmî Gazete otomatik radar taraması: bugün işletmeleri ilgilendiren gümrük, gözetim, vergi ve teşvik düzenlemeleri.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg">')
[void]$s.AppendLine('<style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#ffc24b;--grad:linear-gradient(135deg,#f5a524 0%,#ffc24b 100%);--red:#ff6b5e}')
[void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}')
[void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px}')
[void]$s.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}.top a:hover{color:var(--ink)}')
[void]$s.AppendLine('.logo{width:14px;height:14px;border-radius:50%;background:#f5a524;box-shadow:0 0 0 5px rgba(245,165,36,.16),0 0 18px rgba(245,165,36,.55);font-size:0;color:transparent;display:inline-block;flex:none}')
[void]$s.AppendLine('h1{font-size:clamp(24px,4.5vw,32px);letter-spacing:-.9px;margin:4px 0 4px;font-weight:800}')
[void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:8px}')
[void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 24px}')
[void]$s.AppendLine('h2{font-size:13px;color:var(--accent2);text-transform:uppercase;letter-spacing:1.3px;margin:26px 0 10px;border-bottom:1px solid var(--line);padding-bottom:7px;font-weight:800}')
[void]$s.AppendLine('.m{background:var(--panel);border:1px solid var(--line);border-left:4px solid var(--red);border-radius:12px;padding:13px 16px;margin-bottom:9px;font-size:14px}')
[void]$s.AppendLine('.m a{color:var(--ink);text-decoration:none}.m a:hover{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(245,165,36,.16),rgba(255,194,75,.07)),var(--panel);border:1px solid rgba(255,194,75,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px;letter-spacing:-.4px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(245,165,36,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">T</span><a href="index.html">Tetikte</a> · <a href="gtip.html">GTİP Kontrolü</a> · <a href="destekler.html">Destek Radarı</a> · Bugün RG''de</div>')
[void]$s.AppendLine("<h1>Bugün Resmî Gazete'de ne var?</h1>")
[void]$s.AppendLine("<div class='alt'>$Tarih tarihli sayının radar taraması — $($madde.Count) maddeden <b style='color:var(--ink)'>$ilgiliToplam</b> tanesi işletmeleri ilgilendiriyor.</div>")
# tazelik rozeti (#62): robotun son nobeti kart-durum.json'dan canli okunur
[void]$s.AppendLine('<div id="tazelik" style="display:inline-flex;align-items:center;gap:7px;font-size:11.5px;color:var(--dim);border:1px solid var(--line);border-radius:999px;padding:5px 12px;margin:4px 0 4px"><span style="width:7px;height:7px;border-radius:50%;background:#3ddc97;display:inline-block"></span><span id="tazelikM">Nöbet damgası yükleniyor…</span></div>')
[void]$s.AppendLine('<script>fetch("veri/kart-durum.json?c="+Date.now()).then(function(r){return r.json()}).then(function(d){var e=document.getElementById("tazelikM");if(d&&d.sonTarama){e.textContent="Robotun son RG nöbeti: "+d.sonTarama;}else{e.textContent="Nöbet damgası okunamadı";}}).catch(function(){document.getElementById("tazelik").style.display="none";});</script>')
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
[void]$s.AppendLine("<div class='dip'>Kaynak: <a href='$url' target='_blank' rel='noopener'>Resmî Gazete, $Tarih</a> · Tetikte otomatik taraması · Bilgilendirme amaçlıdır.</div>")
[void]$s.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script><script src="menu.js" defer></script></div></body></html>')

$kok = Split-Path -Parent $PSScriptRoot   # arac/ klasorunun ustu = repo koku
$hedef = Join-Path $kok "radar.html"
[System.IO.File]::WriteAllText($hedef, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "radar.html uretildi: $hedef"
