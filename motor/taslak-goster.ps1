# ============================================================================
#  TASLAK GOSTERICI (03.08.2026) — 0 USD, YENI AI CAGRISI YOK
#
#  NEDEN: Pilot ciktisi ozel kovaya JSON olarak yazildi ama (1) ham JSON gozle
#  okunmaz, (2) ciktiya SORUNUN KENDISI konmamisti - yalniz uretilen aciklama
#  var. Soruyu gormeden kaliteyi yargilayamazsin.
#
#  BU SCRIPT: kovadaki taslagi kasadaki soruyla BIRLESTIRIR ve tek bir okunur
#  HTML uretip yine ozel kovaya koyar. Cem indirir, cift tiklar, okur.
#  Yeni API cagrisi YOK - sadece elimizdeki veriyi birlestiriyor.
#
#  Her soru icin sayfada: soru + siklar + dogru cevap + ESKI aciklama + YENI
#  uretilen alanlar YAN YANA. Boylece "ise yaradi mi" bakisla gorulur.
#
#  ENV: SUPABASE_SERVICE_KEY · Parametre: -dosya pilot-0308-0644.json
# ============================================================================
param([string]$dosya = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/taslak-goster-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 4
  # Rapor SAYI tasir, metin tasimaz (03.08 sizinti dersi).
  if($j.Length -gt 8192){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }

$KOVA = 'onarim-taslak'
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$U    = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SK   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

function Metin([string]$uri, $baslik){
  $h = Invoke-WebRequest -Uri $uri -Headers $baslik -UseBasicParsing -TimeoutSec 180
  if($h.RawContentStream){ return [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) }
  return "$($h.Content)"
}

# --- en yeni pilot dosyasini bul (verilmediyse) ---
if($dosya -eq ''){
  $lgovde = ConvertTo-Json -Compress -InputObject @{ prefix=''; limit=100; sortBy=@{ column='name'; order='desc' } }
  $r = Invoke-RestMethod -Uri "$STOR/object/list/$KOVA" -Method Post -Headers ($SK + @{ 'Content-Type'='application/json' }) -Body ([Text.Encoding]::UTF8.GetBytes($lgovde)) -TimeoutSec 60
  $aday = @($r | Where-Object { "$($_.name)" -like 'pilot-*.json' } | Sort-Object name -Descending)
  if($aday.Count -eq 0){ Write-Host "Kovada pilot dosyasi yok."; RaporYaz @{ durum='KIRMIZI'; sebep='pilot dosyasi bulunamadi' }; exit 1 }
  $dosya = "$($aday[0].name)"
}
Write-Host ("Taslak dosyasi: {0}" -f $dosya)
$taslak = @((Metin "$STOR/object/$KOVA/$dosya" $SK) | ConvertFrom-Json)
Write-Host ("Taslak satiri: {0}" -f $taslak.Count)

# --- taslaktaki sorularin ASILLARINI kasadan cek (50'lik gruplar) ---
$idler = @($taslak | ForEach-Object { "$($_.soru_id)" } | Where-Object { $_ })
$asil = @{}
for($b=0; $b -lt $idler.Count; $b+=50){
  $dilim = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  $sat = @((Metin "$U`?select=id,sinav,ders,konu,kaynak,soru,siklar,dogru,aciklama,tablo,yevmiye,hap&id=in.($liste)" $SK) | ConvertFrom-Json)
  foreach($s in $sat){ if($null -ne $s){ $asil["$($s.id)"] = $s } }
}
Write-Host ("Kasadan eslesen: {0}" -f $asil.Count)

function K([string]$t){
  if($null -eq $t){ return '' }
  return ($t -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;')
}
function TabloHtml($t){
  if($null -eq $t){ return '' }
  $sb2 = New-Object Text.StringBuilder
  [void]$sb2.Append('<table class="veri">')
  if($t.baslik){ [void]$sb2.Append('<caption>' + (K "$($t.baslik)") + '</caption>') }
  if($t.kolonlar){ [void]$sb2.Append('<tr>'); foreach($k in @($t.kolonlar)){ [void]$sb2.Append('<th>' + (K "$k") + '</th>') }; [void]$sb2.Append('</tr>') }
  foreach($sat in @($t.satirlar)){ [void]$sb2.Append('<tr>'); foreach($h in @($sat)){ [void]$sb2.Append('<td>' + (K "$h") + '</td>') }; [void]$sb2.Append('</tr>') }
  [void]$sb2.Append('</table>')
  return $sb2.ToString()
}
function YevmiyeHtml($y){
  if($null -eq $y){ return '' }
  $sb2 = New-Object Text.StringBuilder
  [void]$sb2.Append('<table class="veri"><tr><th>Hesap</th><th>Borç</th><th>Alacak</th></tr>')
  foreach($r in @($y)){ [void]$sb2.Append('<tr><td>' + (K "$($r.hesap)") + '</td><td>' + (K "$($r.borc)") + '</td><td>' + (K "$($r.alacak)") + '</td></tr>') }
  [void]$sb2.Append('</table>')
  return $sb2.ToString()
}

$sb = New-Object Text.StringBuilder
[void]$sb.Append(@"
<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Onarim taslagi - $dosya</title>
<style>
body{font:16px/1.6 system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#faf8f4;color:#1c1a17}
header{position:sticky;top:0;background:#1c1a17;color:#f5f0e6;padding:14px 20px;z-index:9}
header b{color:#e0a24a}
.uyari{background:#fdf0d5;border-left:4px solid #e0a24a;padding:12px 16px;margin:16px 20px;border-radius:6px;font-size:14px}
.kart{background:#fff;margin:16px 20px;border-radius:10px;box-shadow:0 1px 3px rgba(0,0,0,.1);overflow:hidden}
.ust{background:#f2ede3;padding:10px 16px;font-size:13px;color:#6b6355;display:flex;gap:14px;flex-wrap:wrap}
.ust .no{font-weight:700;color:#1c1a17}
.govde{padding:16px}
.soru{font-weight:600;margin-bottom:12px}
.sik{padding:5px 10px;border-radius:5px;margin:3px 0;font-size:15px}
.sik.dogru{background:#e6f4ea;border-left:3px solid #2e7d32}
h4{margin:18px 0 6px;font-size:13px;text-transform:uppercase;letter-spacing:.5px;color:#8a8172}
.eski{background:#f7f5f0;padding:10px 14px;border-radius:6px;font-size:14px;color:#5a5348;white-space:pre-wrap}
.yeni{background:#eef5fb;padding:10px 14px;border-radius:6px;font-size:15px;border-left:3px solid #2f6f9f;white-space:pre-wrap}
.yeni.bos{background:#fdecea;border-left-color:#c62828;color:#8b2c22}
table.veri{border-collapse:collapse;margin:8px 0;font-size:14px;width:100%}
table.veri th,table.veri td{border:1px solid #ddd6c8;padding:6px 9px;text-align:left}
table.veri td+td,table.veri th+th{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
table.veri tr:last-child{background:#eaf5ee;font-weight:800;border-top:2px solid #2e7d32}
table.veri th{background:#f2ede3}
table.veri caption{text-align:left;font-weight:600;padding:4px 0;font-size:14px}
.hap{background:#fdf6e3;border-left:3px solid #e0a24a;padding:10px 14px;border-radius:6px;font-size:15px;font-weight:600;color:#5a4a2a}
.rozet{display:inline-block;background:#e8e2d5;border-radius:20px;padding:2px 10px;font-size:12px;margin-right:5px}
.dil{background:#f3e5f5;color:#6a1b9a}
</style></head><body>
<header><b>Onarim taslagi</b> &nbsp; $dosya &nbsp;·&nbsp; $($taslak.Count) soru &nbsp;·&nbsp; KASAYA YAZILMADI</header>
<div class="uyari"><b>Bu bir taslaktir.</b> Sitede hicbir sey degismedi. Asagida her sorunun
<b>eski</b> aciklamasi ile yapay zekanin urettigi <b>yeni</b> alanlar yan yana.
Bakilacak sey: aciklama <b>ogretiyor mu</b>, tuzaklar dogru adlandirilmis mi, dayanakta
olmayan kanun/oran/tutar uydurulmus mu. Kotu olanlarin numarasini not al, istemi ona gore duzeltirim.</div>
"@)

$n = 0
foreach($t in $taslak){
  $n++
  $s = $asil["$($t.soru_id)"]
  $ders = if($s){ "$($s.ders)" } else { "$($t.ders)" }
  $konu = if($s){ "$($s.konu)" } else { "$($t.konu)" }
  $kay  = if($s){ "$($s.kaynak)" } else { "$($t.kaynak)" }
  $dh = if($s){ "$($s.dogru)".Trim().ToUpper() } else { '' }
  [void]$sb.Append('<div class="kart"><div class="ust"><span class="no">#' + $n + '</span>')
  # 05.08 - Cem: "bu benim kontrol ettigim sinava giris deme, sen bana bitirme
  # ile ilgili ornek soru vermedin." HAKLI: okuyucu SINAV alanini hic
  # basmiyordu; Cem hangi sorunun hangi sinava ait oldugunu goremiyordu.
  # Artik her kartin basinda renkli sinav rozeti var:
  # SMMM (bitirme/yeterlilik) = yesil, SGS (staja giris) = mavi.
  $sinavAd = if($s){ "$($s.sinav)" } else { '' }
  if($sinavAd -ne ''){
    $rozetRenk = if($sinavAd -eq 'SMMM'){ 'background:#e6f4ea;color:#1b5e20;border:1px solid #a5d6a7' } else { 'background:#e3f0fb;color:#0d47a1;border:1px solid #90caf9' }
    $sinavEtiket = if($sinavAd -eq 'SMMM'){ 'SMMM YETERLILIK (bitirme)' } elseif($sinavAd -eq 'SGS'){ 'SGS (staja giris)' } else { $sinavAd }
    [void]$sb.Append('<span class="rozet" style="' + $rozetRenk + ';font-weight:700">' + (K $sinavEtiket) + '</span>')
  }
  [void]$sb.Append('<span>' + (K $ders) + ' &rsaquo; ' + (K $konu) + '</span>')
  [void]$sb.Append('<span>Kaynak: ' + (K $kay) + '</span>')
  if($t.mevzuatdisi){ [void]$sb.Append('<span class="rozet dil">dil/beceri - kanun atfi yasak</span>') }
  foreach($e in @($t.eksik)){ [void]$sb.Append('<span class="rozet">' + (K "$e") + '</span>') }
  [void]$sb.Append('</div><div class="govde">')

  if($s){
    [void]$sb.Append('<div class="soru">' + (K "$($s.soru)") + '</div>')
    foreach($h in 'A','B','C','D','E'){
      $m=''; try { if($s.siklar -and $s.siklar.PSObject.Properties[$h]){ $m="$($s.siklar.$h)" } } catch {}
      if($m -eq ''){ continue }
      $sinif = if($h -eq $dh){ 'sik dogru' } else { 'sik' }
      [void]$sb.Append('<div class="' + $sinif + '"><b>' + $h + ')</b> ' + (K $m) + '</div>')
    }
    $em=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dh]){ $em="$($s.aciklama.$dh)" } } catch {}
    # ======================================================================
    #  04.08 - OKUYUCU ARTIK SITEYLE AYNI GOSTERIYOR (Cem: "eski aciklamanin
    #  icinde akilda kalsin var, altinda akilda kalsin var")
    #
    #  Sahte tekrardi: SITEDE (deneme.html) aciklama icindeki "Akilda kalsin"
    #  zaten "KISACASI" olarak cizilir, "AKILDA KALSIN" adini yalniz kehribar
    #  kart tasir - 31.07'de Cem soylemis, sitede duzeltilmisti. AMA BU
    #  OKUYUCU ham metni oldugu gibi basiyordu, o yuzden iki kez "Akilda
    #  kalsin" gorunuyordu. Ogrenci bunu HIC gormuyor; kusur denetim
    #  ekranindaydi.
    #
    #  DORDUNCU KEZ AYNI DERS: siteye uyguladigim duzeni bu okuyucuya
    #  uygulamayi unutuyorum. (Onceki uc: tablo duzeni, hap kartinin hic
    #  cekilmemesi, kehribar kart adi.) Kural: SITEDE bir gosterim karari
    #  alindiginda taslak-goster.ps1 AYNI TURDA guncellenir.
    # ======================================================================
    $emGoster = [regex]::Replace($em, '(?i)ak[ıi]lda\s+kals[ıi]n\s*:', 'Kisacasi:')
    [void]$sb.Append('<h4>Eski aciklama (dogru sik)</h4><div class="eski">' + (K $emGoster) + '</div>')
    # 03.08 - Cem "akilda kalsin yok" dedi: SITEDE VARDI, bu okuyucuda YOKTU.
    # Kasadaki 'hap' alani sinav ekraninda kehribar kart olarak cikiyor; burada
    # hic cekilmiyordu. Cem 200 soruyu kartin bir parcasini GORMEDEN
    # degerlendiriyordu - denetim eksik kalirdi.
    if("$($s.hap)".Trim().Length -gt 3){
      [void]$sb.Append('<h4>Konunun ozeti (sinav ekraninda kehribar kart)</h4><div class="hap">' + (K "$($s.hap)") + '</div>')
    }
  } else {
    [void]$sb.Append('<div class="eski">Sorunun asli kasada bulunamadi (id ' + (K "$($t.soru_id)") + ')</div>')
  }

  $c = $t.cikti
  # 03.08 - CEM: "tablolar hala asagida gorunuyor, ABD/Ingiltere duzenini
  # yapmistin." HAKLI: o duzeni SITEDE (deneme.html) uyguladim, BU OKUYUCUDA
  # uygulamadim. Ucuncu kez ayni ayrim: site ile denetim ekranini karistirdim.
  # UWorld/Becker duzeni: hesap gorseli aciklama blogunun BASINDA durur - once
  # rakamin nasil ciktigi gorulur, sonra neden oyle oldugu okunur.
  # 04.08 - YENI kehribar kart da gosterilir. Motor artik 'hap' uretiyor
  # (D9); okuyucuda gostermezsem Cem uretilen karti GORMEDEN degerlendirir -
  # bu gece dort kez dustugum tuzak (site ile denetim ekranini ayirmak).
  if($c.hap){ [void]$sb.Append('<h4>YENI - konunun ozeti (kehribar kart)</h4><div class="hap">' + (K "$($c.hap)") + '</div>') }
  if($c.tablo){   [void]$sb.Append('<h4>YENI - tablo</h4>' + (TabloHtml $c.tablo)) }
  if($c.yevmiye){ [void]$sb.Append('<h4>YENI - yevmiye</h4>' + (YevmiyeHtml $c.yevmiye)) }
  if($c.dort_parca){ [void]$sb.Append('<h4>YENI - dort parca</h4><div class="yeni">' + (K "$($c.dort_parca)") + '</div>') }
  foreach($h in 'A','B','C','D','E'){
    $tz=''; $dg=''
    try { if($c.tuzak   -and $c.tuzak.PSObject.Properties[$h]){   $tz="$($c.tuzak.$h)" } } catch {}
    try { if($c.dogrusu -and $c.dogrusu.PSObject.Properties[$h]){ $dg="$($c.dogrusu.$h)" } } catch {}
    if($tz -eq '' -and $dg -eq ''){ continue }
    [void]$sb.Append('<h4>YENI - sik ' + $h + '</h4><div class="yeni">')
    if($tz -ne ''){ [void]$sb.Append((K $tz)) }
    if($dg -ne ''){ [void]$sb.Append("`n<b>Dogrusu:</b> " + (K $dg)) }
    [void]$sb.Append('</div>')
  }
  if(-not $t.gecerli_json){ [void]$sb.Append('<h4>YENI</h4><div class="yeni bos">Model gecerli JSON uretemedi - bu soru islenmedi.</div>') }
  [void]$sb.Append('</div></div>')
}
[void]$sb.Append('</body></html>')

$htmlAd = ($dosya -replace '\.json$','') + '.html'
$bayt = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
Invoke-RestMethod -Uri "$STOR/object/$KOVA/$htmlAd" -Method Post `
  -Headers ($SK + @{ 'Content-Type'='text/html; charset=utf-8'; 'x-upsert'='true' }) `
  -Body $bayt -TimeoutSec 180 | Out-Null

# --- GERI OKU: gercekten yazildi mi (kor kalma) ---
$geri = -1
try { $geri = (Metin "$STOR/object/$KOVA/$htmlAd" $SK).Length } catch { $geri = -1 }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($geri -gt 1000){'TAMAM'}else{'KIRMIZI'})
  kaynak_dosya=$dosya; uretilen=$htmlAd
  taslak_satiri=$taslak.Count; kasadan_eslesen=$asil.Count
  html_bayt=$bayt.Length; geri_okuma_bayt=$geri
  yer="Supabase Storage / kova '$KOVA' (OZEL)"
  not='Yeni API cagrisi YAPILMADI - 0 USD. Kasaya yazilmadi.'
})
Write-Host ("HTML yazildi: {0} ({1} bayt) | geri okuma {2}" -f $htmlAd, $bayt.Length, $geri)
if($geri -le 1000){ exit 1 }
