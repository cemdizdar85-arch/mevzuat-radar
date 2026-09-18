#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) KAYDIR-ÇÖZ DİZİNİ — kaydir/smmm/index.html   18.09.2026  (bedel 0, soru içeriği YAZMAZ)
#
#  NEDEN (Cem 18.09: "kasadaki soruları siteye bağla"): bitirme soruları kilitli kasada (paket_soru, sinav='smmm')
#  ve ders sayfaları kaydir/smmm/<slug>.html'de SORUSUZ KABUK olarak duruyor (arac/smmm-kasa-yayin.ps1 -SiteKabuk).
#  Üyenin derse ulaşacağı liste sayfası yoktu; SGS'nin kaydir/sgs/index.html eşi burada üretilir.
#  Sayfa yalnız DERS ADI ve SORU SAYISI yazar; soru metni girmez (bulut güvenliği kuralı 5).
#  Soru sayıları kasadan OKUNUR (service anahtarı, salt okuma); kasa okunamazsa betik DURUR, sayfa yazılmaz.
#  Kullanım: powershell -NoProfile -File arac/smmm-kaydir-dizin.ps1 [-Yaz]
# ============================================================================
param([switch]$Yaz)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$DERS = [ordered]@{
  'finansal-muhasebe'  = 'Finansal Muhasebe'
  'finansal-tablolar'  = 'Finansal Tablolar ve Analizi'
  'maliyet-muhasebesi' = 'Maliyet Muhasebesi'
  'muhasebe-denetimi'  = 'Muhasebe Denetimi'
  'vergi'              = 'Vergi Mevzuatı ve Uygulaması'
  'hukuk'              = 'Hukuk'
  'meslek-hukuku'      = 'Meslek Hukuku'
  'sermaye-piyasasi'   = 'Sermaye Piyasası Mevzuatı'
}
$KEY = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $KEY) { $KEY = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $KEY) { throw 'SUPABASE_SERVICE_KEY yok — kasa sayıları okunamaz, dizin yazılmaz.' }
$SB = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0'; Prefer = 'count=exact' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function HtmlK([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
$satir = New-Object System.Collections.Generic.List[object]
$toplam = 0
foreach ($slug in $DERS.Keys) {
  $u = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id&sinav=eq.smmm&sayfa=eq.kaydir/smmm/$slug.html&limit=1"
  $r = Invoke-WebRequest -UseBasicParsing $u -Headers $SB -TimeoutSec 60
  $n = [int](("$($r.Headers['Content-Range'])" -replace '.*/', ''))
  $dosya = Join-Path $depoKok "kaydir\smmm\$slug.html"
  $kabukVar = Test-Path $dosya
  $satir.Add([pscustomobject]@{ slug = $slug; ad = $DERS[$slug]; soru = $n; kabuk = $kabukVar })
  $toplam += $n
  "{0,-20} {1,5} soru · kabuk {2}" -f $slug, $n, $(if ($kabukVar) { 'var' } else { 'YOK' })
}
"TOPLAM $toplam soru · $(@($satir | Where-Object { $_.kabuk }).Count)/8 ders sayfası hazır"
$eksik = @($satir | Where-Object { -not $_.kabuk -or $_.soru -eq 0 })
if ($eksik.Count) { throw ("DİZİN YAZILMADI: şu derslerde kabuk ya da kasa satırı yok -> " + (@($eksik | ForEach-Object { $_.slug }) -join ', ')) }
$kartlar = ($satir | ForEach-Object {
    '<a class="kart" href="' + $_.slug + '.html"><div class="ad">' + (HtmlK $_.ad) + '</div><div class="sayi">' + $_.soru + ' soru</div><div class="konu">Nöbetçi çözümüyle; yanlışını anlatır.</div></a>'
  }) -join "`n"
$html = @"
<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow">
<title>SMMM Yeterlilik (staj bitirme) &#183; Kayd&#305;r-&#199;&#246;z &#183; Tetikte</title>
<link rel="stylesheet" href="../../stil.css"><link rel="stylesheet" href="../../stil-acik.css">
<style>
.kaydirDizin{max-width:960px;margin:0 auto;padding:24px 16px}
.kaydirDizin h1{font-size:1.5em;margin:0 0 6px}.kaydirDizin .alt{color:var(--dim);margin:0 0 18px}
.kaydirDizin .izgara{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:12px}
.kaydirDizin .kart{display:block;border:1px solid var(--cizgi);border-radius:14px;padding:14px 16px;text-decoration:none;color:inherit;background:var(--kart)}
.kaydirDizin .kart:hover{border-color:var(--altin)}
.kaydirDizin .ad{font-weight:700;margin-bottom:4px}.kaydirDizin .sayi{color:var(--altin);font-weight:700;margin-bottom:6px}.kaydirDizin .konu{color:var(--dim);font-size:.85em;line-height:1.4}
.kaydirDizin .not{margin-top:22px;color:var(--dim);font-size:.9em;border-top:1px solid var(--cizgi);padding-top:12px}
</style></head><body>
<main class="kaydirDizin">
<h1>SMMM Yeterlilik &#183; Kayd&#305;r-&#199;&#246;z</h1>
<p class="alt">$toplam soru &#183; sekiz ders. Soru bankas&#305; kilitli kasada; sayfa a&#231;&#305;l&#305;rken paketine g&#246;re y&#252;klenir.</p>
<div class="izgara">
$kartlar
</div>
<p class="not">Yanl&#305;&#351; yapt&#305;&#287;&#305;n soruyu N&#246;bet&#231;i ad&#305;m ad&#305;m anlat&#305;r. Soru say&#305;lar&#305; her yay&#305;nda tazelenir.</p>
</main>
<script src="../../paket-kapisi.js"></script>
</body></html>
"@
$yol = Join-Path $depoKok 'kaydir\smmm\index.html'
if ($Yaz) {
  New-Item -ItemType Directory -Force (Split-Path $yol -Parent) | Out-Null
  [IO.File]::WriteAllText($yol, $html, [Text.UTF8Encoding]::new($false))
  "yazildi: kaydir/smmm/index.html · $([math]::Round($html.Length/1024)) KB"
}
else { "KURU (yazilmadi) · sayfa $([math]::Round($html.Length/1024)) KB · -Yaz ile yazilir" }
