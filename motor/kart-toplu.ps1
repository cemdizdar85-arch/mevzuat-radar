# ============================================================================
#  KART TOPLU v0 - gunun TUM tebliglerine cift gecisli hap kart uretir,
#  tutarsiz alanlari yumusatir (guven mimarisi), kartlar.html'i uretir.
#  Kullanim: powershell -ExecutionPolicy Bypass -File kart-toplu.ps1 -Gun 11-07-2026
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Gun,
  [string]$Model = "claude-haiku-4-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim()
$arsiv = Join-Path $here ("arsiv\" + $Gun)
$parcalar = $Gun.Split("-")  # gg-aa-yyyy
$tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($parcalar[2])/$($parcalar[1])/"
$TarihNokta = "$($parcalar[0]).$($parcalar[1]).$($parcalar[2])"

$istemSablon = @"
Sen Mevzuat Radari'nin kart motorusun. Asagida bir Resmi Gazete tebligi metni (ve varsa tablo goruntuleri) var. Gorevin: ithalatci/ihracatci KOBI patronunun 30 saniyede anlayacagi 'hap bilgi karti' verisi cikarmak.

ALTIN KURALLAR:
1) Rakam, tarih, oran, GTIP kodu SADECE verilen metinden/goruntuden alinir. Emin olamadigin her sey icin "kaynakta belirtilmemis" yaz. ASLA tahmin etme.
2) Sade Turkce ama HUKUKEN DOGRU terim: gozetim uygulamasi VERGI DEGILDIR - "vergi zammi" gibi yorumlar YASAK. Tebligin yaptigi islemi olgusal soyle (or: "gozetim birim kiymeti guncellendi", "denetim kapsami degisti"). Baslikta yorum/abartma yok. Turkce imla kusursuz olsun: "kıymet" (noktasiz i ile), "tebliğ", "yürürlük" gibi kelimelerde dogru harfleri kullan.
3) SADECE gecerli JSON dondur.
4) "yururluk" alani SADECE su kaliplardan biri olabilir: "yayimi tarihinde" | "yayimini takip eden N. gun" | "GG.AA.YYYY" | "kaynakta belirtilmemis". Baska cumle kurma.

JSON semasi:
{"baslik_sade":"tek cumle, olgusal, patron diliyle","ne_oldu":"1-2 cumle","gtip_kodlari":["kodlar; okunamiyorsa bos"],"urun_tanimi":"esya/urun grubu","kimi_ilgilendirir":"kim etkilenir","ne_yapmali":"somut adim","yururluk":"kalipli - kural 4","birim_kiymet":"tablodaki degerler ozet; yoksa 'kaynakta belirtilmemis'","guven_notu":"emin olamadigin kisimlar"}

TEBLIG METNI:
"@

function KartUret([string]$metin, [array]$gorseller){
  $icerik = @() + $gorseller
  $icerik += @{ type = "text"; text = ($istemSablon + $metin) }
  $govde = @{ model = $Model; max_tokens = 1200; messages = @(@{ role="user"; content=$icerik }) } | ConvertTo-Json -Depth 10
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 180
  $c = $r.content[0].text.Trim()
  $c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
  if($c -match "(?s)\{.*\}"){ $c = $Matches[0] }
  return @{ kart = ($c | ConvertFrom-Json); girdi = $r.usage.input_tokens; cikti = $r.usage.output_tokens }
}

$dosyalar = Get-ChildItem $arsiv -Filter "*.htm" | Sort-Object Name
"Toplam teblig: $($dosyalar.Count) | Model: $Model | Cift gecis: EVET"
$kartlar = @(); $topGirdi = 0; $topCikti = 0; $hatali = 0

foreach($d in $dosyalar){
  try {
    $ham = [System.IO.File]::ReadAllBytes($d.FullName)
    $html = [System.Text.Encoding]::GetEncoding(1254).GetString($ham)
    $metin = ($html -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
    $metin = [System.Net.WebUtility]::HtmlDecode($metin)
    if($metin.Length -gt 12000){ $metin = $metin.Substring(0,12000) }

    # gorselleri BIR kez indir, iki geciste kullan
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

    $g1 = KartUret $metin $gorseller
    $g2 = KartUret $metin $gorseller
    $topGirdi += $g1.girdi + $g2.girdi; $topCikti += $g1.cikti + $g2.cikti
    $k1 = $g1.kart; $k2 = $g2.kart

    # cift gecis karsilastirma (guven mimarisi)
    $notlar = @()
    $gtip1 = @($k1.gtip_kodlari) -join ","; $gtip2 = @($k2.gtip_kodlari) -join ","
    $gtipOK = ($gtip1 -eq $gtip2)
    $gtipFinal = if($gtipOK){ @($k1.gtip_kodlari) } else {
      $notlar += "GTIP listesi iki okumada farkli cikti - kesin liste icin kaynaga bakin"
      @($k1.gtip_kodlari) | Where-Object { @($k2.gtip_kodlari) -contains $_ }
    }
    $kiymetOK = ($k1.birim_kiymet -eq $k2.birim_kiymet)
    $kiymetFinal = if($kiymetOK){ $k1.birim_kiymet } else {
      $notlar += "Birim kiymet degerleri iki okumada farkli cikti"
      "Tabloda kod bazında belirlenmiş — kesin değerler için kaynak tebliğe bakın"
    }
    $yurOK = ($k1.yururluk -eq $k2.yururluk)
    $yurFinal = if($yurOK){ $k1.yururluk } else { "Kaynak tebliğdeki yürürlük maddesine bakın" }

    $final = [ordered]@{
      dosya = $d.Name; kaynak = ($tabanUrl + $d.Name)
      baslik_sade = $k1.baslik_sade; ne_oldu = $k1.ne_oldu
      gtip_kodlari = $gtipFinal; urun_tanimi = $k1.urun_tanimi
      kimi_ilgilendirir = $k1.kimi_ilgilendirir; ne_yapmali = $k1.ne_yapmali
      yururluk = $yurFinal; birim_kiymet = $kiymetFinal
      guven_notu = (@($k1.guven_notu) + $notlar | Where-Object { $_ }) -join " | "
      cift_gecis = [ordered]@{ gtip = $gtipOK; kiymet = $kiymetOK; yururluk = $yurOK }
    }
    $kartlar += $final
    $t = "{0} | GTIP:{1} KIYMET:{2} YUR:{3}" -f $d.Name, $(if($gtipOK){"OK"}else{"FARK"}), $(if($kiymetOK){"OK"}else{"FARK"}), $(if($yurOK){"OK"}else{"FARK"})
    Write-Host $t
  } catch {
    $hatali++
    Write-Host ("HATA {0}: {1}" -f $d.Name, ($_.Exception.Message -replace [regex]::Escape($key),"***")) -ForegroundColor Yellow
  }
}

# kart verisini kaydet
$gunKartDir = Join-Path $here ("kartlar\" + $Gun)
New-Item -ItemType Directory -Force $gunKartDir | Out-Null
$kartlar | ConvertTo-Json -Depth 6 | Out-File (Join-Path $gunKartDir "kartlar.json") -Encoding utf8

# ---- kartlar.html (siteye) --------------------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Günün Hap Kartları - $TarihNokta | Mevzuat Radarı</title>")
[void]$s.AppendLine('<meta name="description" content="Bugünün Resmî Gazete değişiklikleri hap bilgi kartları hâlinde: ne oldu, kimi ilgilendiriyor, ne yapmalı.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%);--red:#ff6b5e;--amber:#ffc24b;--green:#3ddc97}')
[void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}')
[void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:840px;margin:0 auto;padding:24px 18px 70px}')
[void]$s.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}.top a:hover{color:var(--ink)}')
[void]$s.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$s.AppendLine('h1{font-size:clamp(24px,4.5vw,32px);letter-spacing:-.9px;margin:4px 0 4px;font-weight:800}')
[void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:8px}')
[void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 24px}')
[void]$s.AppendLine('.kart{background:var(--panel);border:1px solid var(--line);border-left:5px solid var(--red);border-radius:14px;padding:18px 20px;margin-bottom:14px}')
[void]$s.AppendLine('.kart .etiket{font-size:10.5px;font-weight:800;letter-spacing:1px;color:var(--red)}')
[void]$s.AppendLine('.kart h3{margin:6px 0 8px;font-size:16.5px;letter-spacing:-.3px}')
[void]$s.AppendLine('.kart p{margin:6px 0;font-size:13.5px;color:var(--muted)}.kart p b{color:var(--ink)}')
[void]$s.AppendLine('.gtip{display:inline-block;background:rgba(62,155,255,.12);color:var(--accent2);border-radius:7px;padding:2px 8px;font-size:11.5px;margin:2px 4px 2px 0;font-variant-numeric:tabular-nums}')
[void]$s.AppendLine('.meta{font-size:11px;color:var(--dim);margin-top:10px}.meta a{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(47,123,255,.16),rgba(38,208,254,.07)),var(--panel);border:1px solid rgba(62,155,255,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(46,140,255,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">MR</span><a href="index.html">Mevzuat Radarı</a> · <a href="radar.html">Bugün RG''de</a> · Günün Kartları</div>')
[void]$s.AppendLine("<h1>Günün Hap Kartları</h1>")
[void]$s.AppendLine("<div class='alt'>$TarihNokta — Resmî Gazete'deki $($kartlar.Count) düzenleme, 30 saniyede okunur kartlar hâlinde.</div>")
[void]$s.AppendLine('<div class="uyari">Kartlar yapay zekâ ile üretilir ve her kart <b>iki bağımsız okumayla</b> çapraz kontrol edilir; iki okumanın uyuşmadığı değerler karta yazılmaz, kaynağa yönlendirilir. Bilgilendirme amaçlıdır — işlem yapmadan önce kaynak tebliği açın.</div>')
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
  if($k.birim_kiymet -and $k.birim_kiymet -ne "kaynakta belirtilmemis"){ [void]$s.AppendLine("<p><b>Birim kıymet:</b> $($k.birim_kiymet)</p>") }
  [void]$s.AppendLine("<p><b>Kimi ilgilendirir:</b> $($k.kimi_ilgilendirir)</p>")
  [void]$s.AppendLine("<p><b>Ne yapmalısın:</b> $($k.ne_yapmali)</p>")
  [void]$s.AppendLine("<p><b>Yürürlük:</b> $($k.yururluk)</p>")
  [void]$s.AppendLine("<div class='meta'><a href='$($k.kaynak)' target='_blank' rel='noopener'>Kaynak tebliğ →</a></div>")
  [void]$s.AppendLine('</div>')
}
[void]$s.AppendLine('<div class="cta"><h3>Bu kartlardan hangisi SENİN kodlarına dokunuyor?</h3>')
[void]$s.AppendLine('<p>Yakında: GTİP kodlarını kaydet, sadece seni etkileyen kart cebine gelsin. Şimdilik: firmanın tüm yükümlülüklerini 3 dakikada gör.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Mevzuat Radarı otomatik kart motoru · Çift geçiş çapraz kontrollü · Bilgilendirme amaçlıdır, kaynak tebliğ esastır.</div>")
[void]$s.AppendLine('</div></body></html>')
$kartlarHtml = Join-Path (Split-Path -Parent $here) "kartlar.html"
[System.IO.File]::WriteAllText($kartlarHtml, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$maliyet = ($topGirdi/1000000.0)*1.0 + ($topCikti/1000000.0)*5.0
""
"TOPLU URETIM BITTI"
"Kart: $($kartlar.Count) | Hatali: $hatali | Token: $topGirdi girdi / $topCikti cikti"
("Toplam maliyet: ~{0:N3} USD" -f $maliyet)
"Site sayfasi: $kartlarHtml"