# ============================================================================
#  KASA ORNEKLEM OKUYUCUSU (06.08.2026) — 0 USD, YENI AI CAGRISI YOK
#
#  Cem'in okuma turu icin: kasadan SINAV bazli, ders-orantili ORNEKLEM ceker
#  ve tek okunur HTML uretip ozel kovaya koyar ("once Staja Giris ver, sonra
#  Bitirme"). taslak-goster.ps1'den farki: pilot dosyasi degil, dogrudan
#  kasanin kendisi; her kartta yayin durumu ve uretim damgasi da gorunur.
#
#  ENV: SUPABASE_SERVICE_KEY · Param: -sinav SGS -adet 200
# ============================================================================
param([string]$sinav = 'SGS', [int]$adet = 200)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/kasa-ornek-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 4
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
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

# --- 1) hafif liste: id + ders (sinav filtresiyle, sayfali) ---
$hafif = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $r = @((Metin "$U`?select=id,ders,yayin&sinav=eq.$sinav&order=id&limit=1000&offset=$bas" $SK) | ConvertFrom-Json)
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($x){ $hafif.Add($x) } }
  if($r.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("{0} kasasi: {1} soru" -f $sinav, $hafif.Count)
if($hafif.Count -eq 0){ RaporYaz @{ durum='KIRMIZI'; sebep='sinav icin soru yok' }; exit 1 }

# --- 2) ders-orantili orneklem ---
$gruplar = $hafif | Group-Object ders
$secilen = New-Object System.Collections.Generic.List[object]
foreach($g in $gruplar){
  $pay = [Math]::Max(1, [Math]::Round($adet * $g.Count / [double]$hafif.Count))
  $al = @($g.Group | Get-Random -Count ([Math]::Min($pay, $g.Count)))
  foreach($x in $al){ $secilen.Add($x) }
}
$secilen = @($secilen | Get-Random -Count ([Math]::Min($adet, $secilen.Count)))
Write-Host ("Orneklem: {0} soru / {1} ders" -f $secilen.Count, $gruplar.Count)

# --- 3) tam satirlari cek ---
$asil = @{}
$idler = @($secilen | ForEach-Object { "$($_.id)" })
for($b=0; $b -lt $idler.Count; $b+=50){
  $dilim = $idler[$b..([Math]::Min($b+49, $idler.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  $sat = @((Metin "$U`?select=id,sinav,ders,konu,kaynak,soru,siklar,dogru,aciklama,tablo,yevmiye,hap,yayin,uretim&id=in.($liste)" $SK) | ConvertFrom-Json)
  foreach($s in $sat){ if($null -ne $s){ $asil["$($s.id)"] = $s } }
}
Write-Host ("Tam satir: {0}" -f $asil.Count)

function K([string]$t){ if($null -eq $t){ return '' }; return ($t -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;') }
function TabloHtml($t){
  if($null -eq $t){ return '' }
  $sb2 = New-Object Text.StringBuilder
  [void]$sb2.Append('<table class="veri">')
  if($t.baslik){ [void]$sb2.Append('<caption>' + (K "$($t.baslik)") + '</caption>') }
  if($t.kolonlar){ [void]$sb2.Append('<tr>'); foreach($k in @($t.kolonlar)){ [void]$sb2.Append('<th>' + (K "$k") + '</th>') }; [void]$sb2.Append('</tr>') }
  foreach($sat in @($t.satirlar)){ [void]$sb2.Append('<tr>'); foreach($h in @($sat)){ [void]$sb2.Append('<td>' + (K "$h") + '</td>') }; [void]$sb2.Append('</tr>') }
  [void]$sb2.Append('</table>'); return $sb2.ToString()
}
function YevmiyeHtml($y){
  if($null -eq $y){ return '' }
  $sb2 = New-Object Text.StringBuilder
  [void]$sb2.Append('<table class="veri"><tr><th>Hesap</th><th>Borç</th><th>Alacak</th></tr>')
  foreach($r in @($y)){ [void]$sb2.Append('<tr><td>' + (K "$($r.hesap)") + '</td><td>' + (K "$($r.borc)") + '</td><td>' + (K "$($r.alacak)") + '</td></tr>') }
  [void]$sb2.Append('</table>'); return $sb2.ToString()
}

$tarihD = Get-Date -Format 'ddMM-HHmm'
$sb = New-Object Text.StringBuilder
[void]$sb.Append(@"
<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$sinav orneklem - $($secilen.Count) soru</title>
<style>
body{font:16px/1.6 system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#faf8f4;color:#1c1a17}
header{position:sticky;top:0;background:#1c1a17;color:#f5f0e6;padding:14px 20px;z-index:9}
header b{color:#e0a24a}
.kart{background:#fff;margin:16px 20px;border-radius:10px;box-shadow:0 1px 3px rgba(0,0,0,.1);overflow:hidden}
.ust{background:#f2ede3;padding:10px 16px;font-size:13px;color:#6b6355;display:flex;gap:14px;flex-wrap:wrap}
.ust .no{font-weight:700;color:#1c1a17}
.rozet{background:#e0a24a;color:#1c1a17;border-radius:12px;padding:1px 10px;font-weight:700}
.rozetGri{background:#d8d2c6;color:#514b40;border-radius:12px;padding:1px 10px}
.govde{padding:16px}
.soru{font-weight:600;margin-bottom:12px;white-space:pre-wrap}
.sik{padding:6px 10px;border-radius:6px;margin:3px 0;white-space:pre-wrap}
.sik.dogru{background:#e8f2e4;border-left:4px solid #4a7c40;font-weight:600}
.acik{background:#f7f4ee;border-radius:8px;padding:10px 14px;margin:8px 0;font-size:14.5px;white-space:pre-wrap}
.hap{background:#fdf0d5;border-left:4px solid #e0a24a;border-radius:8px;padding:10px 14px;margin:8px 0;font-size:14.5px;white-space:pre-wrap}
h4{margin:14px 0 4px;font-size:13px;color:#8a7f6b;letter-spacing:.4px}
table.veri{border-collapse:collapse;margin:8px 0;font-size:14px}
table.veri th,table.veri td{border:1px solid #d8d2c6;padding:5px 10px;text-align:left}
table.veri th{background:#f2ede3}
</style></head><body>
<header><b>$sinav ÖRNEKLEMİ</b> · $($secilen.Count) soru · ders dağılımına orantılı · $(Get-Date -Format 'dd.MM.yyyy HH:mm') · GİZLİ DENETİM KOPYASI — paylaşılmaz</header>
"@)

$no = 0
foreach($sid in $idler){
  $c = $asil["$sid"]; if($null -eq $c){ continue }
  $no++
  $yayinRozet = if($c.yayin){ '<span class="rozet">YAYINDA</span>' } else { '<span class="rozetGri">denetim kuyruğunda</span>' }
  [void]$sb.Append('<div class="kart"><div class="ust"><span class="no">#' + $no + '</span><span>' + (K "$($c.ders)") + '</span><span>' + (K "$($c.konu)") + '</span>' + $yayinRozet + '<span>' + (K "$($c.uretim)") + '</span></div><div class="govde">')
  [void]$sb.Append('<div class="soru">' + (K "$($c.soru)") + '</div>')
  foreach($h in 'A','B','C','D','E'){
    $sn = ''; try { $sn = "$($c.siklar.$h)" } catch {}
    $cl = if("$($c.dogru)" -eq $h){ 'sik dogru' } else { 'sik' }
    [void]$sb.Append('<div class="' + $cl + '"><b>' + $h + ')</b> ' + (K $sn) + '</div>')
  }
  if($c.tablo){ [void]$sb.Append('<h4>TABLO</h4>' + (TabloHtml $c.tablo)) }
  if($c.yevmiye){ [void]$sb.Append('<h4>YEVMİYE</h4>' + (YevmiyeHtml $c.yevmiye)) }
  # 06.08 Cem: (1) "KEHRIBAR KART" ic jargondur, ogrenci yuzunde adi KONUNUN
  # OZETI'dir (04.08 karari, deneme.html ile ayni); (2) once KONU ogretilir -
  # dogru sikkin dort-parca aciklamasi EN USTTE, tuzaklar ondan sonra gelir
  # (sitedeki 1-2-3 merdivenin aynisi; A-E duz sirasi konuyu gomuyordu).
  if($c.hap){ [void]$sb.Append('<h4>KONUNUN ÖZETİ</h4><div class="hap">' + (K "$($c.hap)") + '</div>') }
  $dh = "$($c.dogru)"
  $acD = ''; try { if($c.aciklama -and $c.aciklama.PSObject.Properties[$dh]){ $acD = "$($c.aciklama.$dh)" } } catch {}
  if($acD -ne ''){ [void]$sb.Append('<h4>KONU ANLATIMI — DOĞRU CEVAP (' + $dh + ')</h4><div class="acik">' + (K $acD) + '</div>') }
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dh){ continue }
    $ac = ''; try { if($c.aciklama -and $c.aciklama.PSObject.Properties[$h]){ $ac = "$($c.aciklama.$h)" } } catch {}
    if($ac -eq ''){ continue }
    [void]$sb.Append('<h4>ŞIK ' + $h + ' — NEDEN YANLIŞ</h4><div class="acik">' + (K $ac) + '</div>')
  }
  if($c.kaynak){ [void]$sb.Append('<h4>KAYNAK</h4><div class="acik">' + (K "$($c.kaynak)") + '</div>') }
  [void]$sb.Append('</div></div>')
}
[void]$sb.Append('</body></html>')

$htmlAd = ('ornek-' + $sinav.ToLowerInvariant() + '-' + $tarihD + '.html')
$bayt = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
Invoke-RestMethod -Uri "$STOR/object/$KOVA/$htmlAd" -Method Post `
  -Headers ($SK + @{ 'Content-Type'='text/html; charset=utf-8'; 'x-upsert'='true' }) `
  -Body $bayt -TimeoutSec 180 | Out-Null

$geri = -1
try { $geri = (Metin "$STOR/object/$KOVA/$htmlAd" $SK).Length } catch { $geri = -1 }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($geri -gt 1000){'TAMAM'}else{'KIRMIZI'})
  sinav=$sinav; orneklem=$secilen.Count; ders_sayisi=@($gruplar).Count
  uretilen=$htmlAd; html_bayt=$bayt.Length; geri_okuma_bayt=$geri
  yer="Supabase Storage / kova '$KOVA' (OZEL)"
  not='0 USD - AI cagrisi yok, kasaya yazilmadi. Orneklem ders orantılı örneklem rastgele.'
})
Write-Host ("HTML yazildi: {0} ({1} bayt) | geri okuma {2}" -f $htmlAd, $bayt.Length, $geri)
if($geri -le 1000){ exit 1 }
