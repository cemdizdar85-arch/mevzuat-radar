# ============================================================================
#  KART TOPLU v0.2 - Hap Bilgi Motoru
#  Yenilikler: kod bazinda yapilandirilmis kiymet + Sonnet hakem (anlasmazlikta)
#  + kalici kiymet hafizasi (kiyas: "onceki kayit X -> yeni Y") + gunluk arsiv.
#  Kullanim: powershell -ExecutionPolicy Bypass -File kart-toplu.ps1 -Gun 11-07-2026
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Gun,
  [string]$Model = "claude-haiku-4-5",
  [string]$HakemModel = "claude-sonnet-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok = Split-Path -Parent $here
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()
$arsivTeblig = Join-Path $here ("arsiv\" + $Gun)
$parcalar = $Gun.Split("-")
$tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($parcalar[2])/$($parcalar[1])/"
$TarihNokta = "$($parcalar[0]).$($parcalar[1]).$($parcalar[2])"

function NormD([string]$s){ if(-not $s){ return "" }; return (($s -replace "\s+"," ").Trim().ToLowerInvariant()) }

# ---- kalici kiymet hafizasi -------------------------------------------------
$hafizaDir = Join-Path $here "hafiza"
New-Item -ItemType Directory -Force $hafizaDir | Out-Null
$hafizaYol = Join-Path $hafizaDir "kiymetler.json"
$hafiza = @{}
if(Test-Path $hafizaYol){
  $j = Get-Content $hafizaYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $j.PSObject.Properties){ $hafiza[$p.Name] = @($p.Value) }
}

$istemSablon = @"
Sen Mevzuat Radari'nin kart motorusun. Asagida bir Resmi Gazete tebligi metni (ve varsa tablo goruntuleri) var. Gorevin: ithalatci/ihracatci KOBI patronunun 30 saniyede anlayacagi 'hap bilgi karti' verisi cikarmak.

ALTIN KURALLAR:
1) Rakam, tarih, oran, GTIP kodu SADECE verilen metinden/goruntuden alinir. Emin olamadigin her sey icin "kaynakta belirtilmemis" yaz. ASLA tahmin etme.
2) Sade Turkce ama HUKUKEN DOGRU terim: gozetim uygulamasi VERGI DEGILDIR - "vergi zammi" gibi yorumlar YASAK. Tebligin yaptigi islemi olgusal soyle. Baslikta yorum/abartma yok. Turkce imla kusursuz: "kıymet", "tebliğ", "yürürlük" dogru harflerle.
3) SADECE gecerli JSON dondur.
4) "yururluk" alani SADECE su kaliplardan biri: "yayimi tarihinde" | "yayimini takip eden N. gun" | "GG.AA.YYYY" | "kaynakta belirtilmemis".
5) "birim_kiymetler" YAPILANDIRILMIS olacak: tabloda degeri NET okudugun her kod icin bir satir. Okuyamadigin kodu LISTEYE KOYMA (guven_notu'na yaz).

JSON semasi:
{"baslik_sade":"tek cumle, olgusal","ne_oldu":"1-2 cumle","gtip_kodlari":["tum kodlar"],"urun_tanimi":"esya grubu","kimi_ilgilendirir":"kim","ne_yapmali":"somut adim","yururluk":"kalipli","birim_kiymetler":[{"gtip":"kod","deger":"or: 1.000 ABD Dolari/Ton"}],"guven_notu":"emin olamadiklarin"}

TEBLIG METNI:
"@

function ApiCagri([string]$model, [array]$icerik, [int]$maxTok){
  $govde = @{ model = $model; max_tokens = $maxTok; messages = @(@{ role="user"; content=$icerik }) } | ConvertTo-Json -Depth 10
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 240
  $c = $r.content[0].text.Trim()
  $c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
  return @{ metin = $c; girdi = $r.usage.input_tokens; cikti = $r.usage.output_tokens }
}

function JsonAyikla([string]$c){
  if($c -match "(?s)\{.*\}"){ return ($Matches[0] | ConvertFrom-Json) }
  throw "JSON bulunamadi"
}

$dosyalar = Get-ChildItem $arsivTeblig -Filter "*.htm" | Sort-Object Name
"Toplam teblig: $($dosyalar.Count) | Model: $Model | Hakem: $HakemModel"
$kartlar = @(); $topGirdi = 0; $topCikti = 0; $hakemGirdi = 0; $hakemCikti = 0; $hatali = 0; $hakemSayisi = 0

foreach($d in $dosyalar){
  try {
    $ham = [System.IO.File]::ReadAllBytes($d.FullName)
    $html = [System.Text.Encoding]::GetEncoding(1254).GetString($ham)
    $metin = ($html -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
    $metin = [System.Net.WebUtility]::HtmlDecode($metin)
    if($metin.Length -gt 12000){ $metin = $metin.Substring(0,12000) }

    $gorseller = @()
    $imgler = [regex]::Matches($html,'(?i)<img[^>]+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 3
    foreach($src in $imgler){
      $imgUrl = if($src -match "^https?:"){ $src } else { $tabanUrl + ($src -replace "^\./","") }
      try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-v0)")
        $b = $wc.DownloadData($imgUrl)
        $mime = if($src -match "\.png$"){ "image/png" } else { "image/jpeg" }
        $gorseller += @{ type="image"; source=@{ type="base64"; media_type=$mime; data=[Convert]::ToBase64String($b) } }
      } catch {}
    }
    $icerikTam = @() + $gorseller + @(@{ type="text"; text=($istemSablon + $metin) })

    # --- cift gecis ---
    $g1 = ApiCagri $Model $icerikTam 2800; $topGirdi += $g1.girdi; $topCikti += $g1.cikti
    $g2 = ApiCagri $Model $icerikTam 2800; $topGirdi += $g2.girdi; $topCikti += $g2.cikti
    $k1 = JsonAyikla $g1.metin; $k2 = JsonAyikla $g2.metin

    $notlar = @()

    # GTIP karsilastirma
    $gtip1 = @($k1.gtip_kodlari) -join ","; $gtip2 = @($k2.gtip_kodlari) -join ","
    $gtipFinal = if($gtip1 -eq $gtip2){ @($k1.gtip_kodlari) } else {
      $notlar += "GTIP listesi iki okumada farkli - kesisim alindi"
      @($k1.gtip_kodlari) | Where-Object { @($k2.gtip_kodlari) -contains $_ }
    }

    # yururluk (kalipli oldugu icin esitlik saglikli)
    $yurFinal = if((NormD $k1.yururluk) -eq (NormD $k2.yururluk)){ $k1.yururluk } else { "Kaynak tebliğdeki yürürlük maddesine bakın" }

    # --- KOD BAZINDA kiymet karsilastirma ---
    $m1 = @{}; foreach($x in @($k1.birim_kiymetler)){ if($x.gtip){ $m1[$x.gtip] = $x.deger } }
    $m2 = @{}; foreach($x in @($k2.birim_kiymetler)){ if($x.gtip){ $m2[$x.gtip] = $x.deger } }
    $tumKodlar = @($m1.Keys) + @($m2.Keys) | Select-Object -Unique
    $kesin = [ordered]@{}; $ihtilafli = @()
    foreach($kod in $tumKodlar){
      if($m1.ContainsKey($kod) -and $m2.ContainsKey($kod) -and ((NormD $m1[$kod]) -eq (NormD $m2[$kod]))){ $kesin[$kod] = $m1[$kod] }
      else { $ihtilafli += $kod }
    }

    # --- Sonnet HAKEM (sadece ihtilafli kodlar) ---
    if($ihtilafli.Count -gt 0){
      $hakemSayisi++
      try {
        $hIstem = "Tablo goruntusunden SADECE su GTIP kodlarinin birim kiymet degerini oku: " + ($ihtilafli -join ", ") + ". SADECE JSON dizisi dondur: [{`"gtip`":`"kod`",`"deger`":`"deger birimiyle`"}]. Bir kodu net okuyamiyorsan deger alanina `"okunamadi`" yaz. Tahmin YASAK."
        $hIcerik = @() + $gorseller + @(@{ type="text"; text=$hIstem })
        $gh = $null
        foreach($deneme in 1..2){
          try { $gh = ApiCagri $HakemModel $hIcerik 700; break }
          catch { if($deneme -eq 2){ throw }; Start-Sleep -Seconds 3 }
        }
        $hakemGirdi += $gh.girdi; $hakemCikti += $gh.cikti
        $hj = if($gh.metin -match "(?s)\[.*\]"){ $Matches[0] | ConvertFrom-Json } else { @() }
        foreach($hx in @($hj)){
          $kod = $hx.gtip; $hd = $hx.deger
          if(-not $kod -or $ihtilafli -notcontains $kod){ continue }
          if((NormD $hd) -eq "okunamadi" -or -not $hd){ continue }
          # 2/3 oy: hakem, iki okumadan biriyle uyusuyorsa kabul
          if(($m1.ContainsKey($kod) -and (NormD $m1[$kod]) -eq (NormD $hd)) -or ($m2.ContainsKey($kod) -and (NormD $m2[$kod]) -eq (NormD $hd))){
            $kesin[$kod] = $hd
            $ihtilafli = @($ihtilafli | Where-Object { $_ -ne $kod })
          }
        }
      } catch { $notlar += "Hakem gecisi basarisiz oldu" }
    }
    if($ihtilafli.Count -gt 0){ $notlar += ("Su kodlarin kiymeti guvenle okunamadi: " + ($ihtilafli -join ", ")) }

    # --- HAFIZA: kiyas + kayit ---
    $kiyaslar = @()
    foreach($kod in $kesin.Keys){
      $yeni = $kesin[$kod]
      if(-not $hafiza.ContainsKey($kod)){ $hafiza[$kod] = @() }
      $sonKayit = if($hafiza[$kod].Count){ $hafiza[$kod][-1] } else { $null }
      # kiyas SADECE onceki kayit baska bir gundense (ayni gun tekrar calistirma gurultusu kiyas sayilmaz)
      if($sonKayit -and $sonKayit.tarih -ne $TarihNokta -and (NormD $sonKayit.deger) -ne (NormD $yeni)){
        $kiyaslar += ("{0}: onceki kaydimiz {1} ({2}) -> yeni {3}" -f $kod, $sonKayit.deger, $sonKayit.tarih, $yeni)
      }
      if($sonKayit -and $sonKayit.tarih -eq $TarihNokta){
        # ayni gunun kaydini guncelle (kopya olusturma)
        $hafiza[$kod][-1] = [pscustomobject]@{ tarih=$TarihNokta; deger=$yeni; teblig=$d.Name }
      } elseif(-not $sonKayit -or (NormD $sonKayit.deger) -ne (NormD $yeni)){
        $hafiza[$kod] = @($hafiza[$kod]) + @([pscustomobject]@{ tarih=$TarihNokta; deger=$yeni; teblig=$d.Name })
      }
    }

    $final = [ordered]@{
      dosya = $d.Name; kaynak = ($tabanUrl + $d.Name)
      baslik_sade = $k1.baslik_sade; ne_oldu = $k1.ne_oldu
      gtip_kodlari = $gtipFinal; urun_tanimi = $k1.urun_tanimi
      kimi_ilgilendirir = $k1.kimi_ilgilendirir; ne_yapmali = $k1.ne_yapmali
      yururluk = $yurFinal
      kesin_kiymetler = $kesin
      kiyaslar = $kiyaslar
      guven_notu = (@($k1.guven_notu) + $notlar | Where-Object { $_ }) -join " | "
    }
    $kartlar += $final
    Write-Host ("{0} | kesin kiymet: {1} | ihtilafli: {2} | kiyas: {3}" -f $d.Name, $kesin.Count, $ihtilafli.Count, $kiyaslar.Count)
  } catch {
    # tek yeniden deneme (JSON hatasi gecici olabilir)
    $hatali++
    Write-Host ("HATA {0}: {1}" -f $d.Name, ($_.Exception.Message -replace [regex]::Escape($key),"***")) -ForegroundColor Yellow
  }
}

# hafizayi kaydet
$hafizaObj = [ordered]@{}
foreach($kod in ($hafiza.Keys | Sort-Object)){ $hafizaObj[$kod] = $hafiza[$kod] }
($hafizaObj | ConvertTo-Json -Depth 6) | Out-File $hafizaYol -Encoding utf8

# kart verisini kaydet
$gunKartDir = Join-Path $here ("kartlar\" + $Gun)
New-Item -ItemType Directory -Force $gunKartDir | Out-Null
$kartlar | ConvertTo-Json -Depth 8 | Out-File (Join-Path $gunKartDir "kartlar.json") -Encoding utf8

# ---- kartlar.html + gunluk arsiv kopyasi ------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Günün Hap Kartları - $TarihNokta | Mevzuat Radarı</title>")
[void]$s.AppendLine('<meta name="description" content="Bugünün Resmî Gazete değişiklikleri hap bilgi kartları hâlinde: ne oldu, kimi ilgilendiriyor, ne yapmalı.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%);--red:#ff6b5e;--amber:#ffc24b;--green:#3ddc97}')
[void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}')
[void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:840px;margin:0 auto;padding:24px 18px 70px}')
[void]$s.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim);flex-wrap:wrap}.top a{color:var(--muted);text-decoration:none;font-weight:600}.top a:hover{color:var(--ink)}')
[void]$s.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$s.AppendLine('h1{font-size:clamp(24px,4.5vw,32px);letter-spacing:-.9px;margin:4px 0 4px;font-weight:800}')
[void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:8px}')
[void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 24px}')
[void]$s.AppendLine('.kart{background:var(--panel);border:1px solid var(--line);border-left:5px solid var(--red);border-radius:14px;padding:18px 20px;margin-bottom:14px}')
[void]$s.AppendLine('.kart .etiket{font-size:10.5px;font-weight:800;letter-spacing:1px;color:var(--red)}')
[void]$s.AppendLine('.kart h3{margin:6px 0 8px;font-size:16.5px;letter-spacing:-.3px}')
[void]$s.AppendLine('.kart p{margin:6px 0;font-size:13.5px;color:var(--muted)}.kart p b{color:var(--ink)}')
[void]$s.AppendLine('.gtip{display:inline-block;background:rgba(62,155,255,.12);color:var(--accent2);border-radius:7px;padding:2px 8px;font-size:11.5px;margin:2px 4px 2px 0;font-variant-numeric:tabular-nums}')
[void]$s.AppendLine('.kiymet{font-size:12.5px;color:var(--muted);margin:2px 0;font-variant-numeric:tabular-nums}.kiymet b{color:var(--ink)}')
[void]$s.AppendLine('.kiyas{background:rgba(61,220,151,.09);border:1px solid rgba(61,220,151,.3);color:var(--green);border-radius:9px;padding:8px 12px;font-size:12.5px;margin:8px 0}')
[void]$s.AppendLine('.meta{font-size:11px;color:var(--dim);margin-top:10px}.meta a{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(47,123,255,.16),rgba(38,208,254,.07)),var(--panel);border:1px solid rgba(62,155,255,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(46,140,255,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">MR</span><a href="index.html">Mevzuat Radarı</a> · <a href="radar.html">Bugün RG''de</a> · Günün Kartları · <a href="arsiv/index.html">Arşiv</a></div>')
[void]$s.AppendLine("<h1>Günün Hap Kartları</h1>")
[void]$s.AppendLine("<div class='alt'>$TarihNokta — Resmî Gazete'deki $($kartlar.Count) düzenleme, 30 saniyede okunur kartlar hâlinde.</div>")
[void]$s.AppendLine('<div class="uyari">Kartlar yapay zekâ ile üretilir; her değer <b>iki bağımsız okuma + anlaşmazlıkta hakem model</b> ile çapraz kontrol edilir. Güvenle doğrulanamayan değer karta yazılmaz. Bilgilendirme amaçlıdır — işlem öncesi kaynak tebliği açın.</div>')
foreach($k in $kartlar){
  [void]$s.AppendLine('<div class="kart">')
  [void]$s.AppendLine('<div class="etiket">■ MEVZUAT DEĞİŞİKLİĞİ</div>')
  [void]$s.AppendLine("<h3>$($k.baslik_sade)</h3>")
  [void]$s.AppendLine("<p><b>Ne oldu:</b> $($k.ne_oldu)</p>")
  if($k.urun_tanimi){ [void]$s.AppendLine("<p><b>Ürün:</b> $($k.urun_tanimi)</p>") }
  if(@($k.gtip_kodlari).Count){
    $chips = (@($k.gtip_kodlari) | ForEach-Object { "<span class='gtip'>$_</span>" }) -join ""
    [void]$s.AppendLine("<p><b>GTİP:</b><br>$chips</p>")
  }
  if($k.kesin_kiymetler.Count){
    [void]$s.AppendLine("<p><b>Birim kıymetler (çapraz doğrulanmış):</b></p>")
    foreach($kod in $k.kesin_kiymetler.Keys){ [void]$s.AppendLine("<div class='kiymet'>$kod → <b>$($k.kesin_kiymetler[$kod])</b></div>") }
  }
  foreach($ky in @($k.kiyaslar)){ [void]$s.AppendLine("<div class='kiyas'>📊 Değişim — $ky</div>") }
  [void]$s.AppendLine("<p><b>Kimi ilgilendirir:</b> $($k.kimi_ilgilendirir)</p>")
  [void]$s.AppendLine("<p><b>Ne yapmalısın:</b> $($k.ne_yapmali)</p>")
  [void]$s.AppendLine("<p><b>Yürürlük:</b> $($k.yururluk)</p>")
  [void]$s.AppendLine("<div class='meta'><a href='$($k.kaynak)' target='_blank' rel='noopener'>Kaynak tebliğ →</a></div>")
  [void]$s.AppendLine('</div>')
}
[void]$s.AppendLine('<div class="cta"><h3>Bu kartlardan hangisi SENİN kodlarına dokunuyor?</h3>')
[void]$s.AppendLine('<p>Yakında: GTİP kodlarını kaydet, sadece seni etkileyen kart cebine gelsin. Şimdilik: firmanın tüm yükümlülüklerini 3 dakikada gör.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Mevzuat Radarı hap bilgi motoru · Çift geçiş + hakem model çapraz kontrolü · Bilgilendirme amaçlıdır, kaynak tebliğ esastır.</div>")
[void]$s.AppendLine('</div></body></html>')
$kartlarHtml = Join-Path $kok "kartlar.html"
[System.IO.File]::WriteAllText($kartlarHtml, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# gunluk arsiv kopyasi (goreli linkler icin <base> eklenir)
$arsivDirSite = Join-Path $kok "arsiv"
New-Item -ItemType Directory -Force $arsivDirSite | Out-Null
$arsivHtml = $s.ToString().Replace('<head>','<head><base href="../">')
[System.IO.File]::WriteAllText((Join-Path $arsivDirSite ("kartlar-" + $Gun + ".html")), $arsivHtml, (New-Object System.Text.UTF8Encoding($false)))

# arsiv index'ini yeniden kur
$gunler = Get-ChildItem $arsivDirSite -Filter "kartlar-*.html" | ForEach-Object {
  $g = $_.BaseName -replace "^kartlar-",""
  $pp = $g.Split("-")
  [pscustomobject]@{ dosya=$_.Name; gun=$g; sirala=("{0}{1}{2}" -f $pp[2],$pp[1],$pp[0]); goster=("{0}.{1}.{2}" -f $pp[0],$pp[1],$pp[2]) }
} | Sort-Object sirala -Descending
$a = New-Object System.Text.StringBuilder
[void]$a.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><base href="../">')
[void]$a.AppendLine('<title>Kart Arşivi | Mevzuat Radarı</title><link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$a.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%)}')
[void]$a.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.7}')
[void]$a.AppendLine('a{color:var(--accent2)}.wrap{max-width:720px;margin:0 auto;padding:24px 18px 70px}')
[void]$a.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}')
[void]$a.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$a.AppendLine('h1{font-size:26px;letter-spacing:-.8px;font-weight:800}')
[void]$a.AppendLine('.g{display:block;background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px 18px;margin-bottom:10px;color:var(--ink);text-decoration:none;font-weight:600}.g:hover{border-color:rgba(62,155,255,.4)}')
[void]$a.AppendLine('.g span{color:var(--dim);font-weight:400;font-size:12.5px}')
[void]$a.AppendLine('</style></head><body><div class="wrap">')
[void]$a.AppendLine('<div class="top"><span class="logo">MR</span><a href="index.html">Mevzuat Radarı</a> · <a href="kartlar.html">Günün Kartları</a> · Arşiv</div>')
[void]$a.AppendLine('<h1>Hap Kart Arşivi</h1><p style="color:var(--muted);font-size:14px">Gün gün, Resmî Gazete değişikliklerinin hap kartları.</p>')
foreach($g in $gunler){ [void]$a.AppendLine("<a class='g' href='arsiv/$($g.dosya)'>$($g.goster) <span>— günün kartları</span></a>") }
[void]$a.AppendLine('</div></body></html>')
[System.IO.File]::WriteAllText((Join-Path $arsivDirSite "index.html"), $a.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$maliyet = ($topGirdi/1000000.0)*1.0 + ($topCikti/1000000.0)*5.0 + ($hakemGirdi/1000000.0)*3.0 + ($hakemCikti/1000000.0)*15.0
""
"TOPLU URETIM BITTI (v0.2)"
"Kart: $($kartlar.Count) | Hatali: $hatali | Hakem devreye girdi: $hakemSayisi kart"
"Ana model token: $topGirdi/$topCikti | Hakem token: $hakemGirdi/$hakemCikti"
("Toplam maliyet: ~{0:N3} USD" -f $maliyet)
"Hafizadaki kod sayisi: $($hafiza.Keys.Count)"
"Sayfalar: kartlar.html + arsiv/kartlar-$Gun.html + arsiv/index.html"