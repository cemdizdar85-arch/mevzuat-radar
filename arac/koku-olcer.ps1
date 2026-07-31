# ============================================================================
#  KOKU OLCER - "yapay zeka yapmis" izini SAYFA METINLERINDE olcer (31.07 Cem:
#  "kesinlikle bir yapay zeka yazilimi gibi gorunmeyelim - tum siteyi kontrol et").
#  Ilke (yapayzeka-kokusu): iz DILDE, iskelette degil; tekduzelik hatadan cok
#  ele verir. Bu arac gorunur metni cikarir ve sayar:
#    1) Ingilizce jargon (self-check, dashboard, lead, premium...)
#    2) YZ klise kaliplari (unutmayin, ozetle, kapsamli, guclu bir arac...)
#    3) Emoji yogunlugu (1000 karakterde kac emoji)
#    4) Unlem yogunlugu
#  Cikti: sayfa sayfa puan tablosu, en kotu 15 bulgu satiri.
# ============================================================================
$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $kok

$JARGON = @('self-check','check-list','checklist','dashboard','premium','deadline','online tool',
  'know-how','feedback','one-stop','all-in-one','pro tip','power user','freemium','landing')
# mesleki terim / kod istisnalari: dosya -> izinli terimler
# (know-how gumruk kiymeti mevzuatinin GERCEK terimi - Gumruk K. m.27 royalti/lisans)
$IZINLI = @{ 'hizmet.html' = @('know-how') }
$KLISE = @('unutmayın ki','unutma ki','özetle,','sonuç olarak,','kapsamlı bir','güçlü bir araç','devrim',
  'hadi başlayalım','işte bu kadar','hepsi bu kadar','sizin için derledik','keşfedin','göz atın',
  'ihtiyacınız olan her şey','tek tıkla','saniyeler içinde','kolayca yönetin','yolculuğunuz',
  'merak etmeyin','endişelenmeyin','sizin için buradayız','deneyimleyin','fark yaratın')

$sonuc = @()
$bulgular = @()
foreach($h in Get-ChildItem -Path $kok -Filter *.html -File){
  $ham = Get-Content $h.FullName -Raw -Encoding UTF8
  # script/style govdesini at, kalan etiketleri soy -> gorunur metne yaklas
  $metin = $ham -replace '(?s)<script.*?</script>','' -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' '
  # jargon/klise TUM dosyada aranir: sitenin gorunur metninin cogu JS sablonlarinda!
  $kucuk = $ham.ToLowerInvariant()

  $izin = @(); if($IZINLI.ContainsKey($h.Name)){ $izin = $IZINLI[$h.Name] }
  $jBul = @(); foreach($j in $JARGON){ if($izin -contains $j){ continue }; $n = ([regex]::Matches($kucuk, [regex]::Escape($j))).Count; if($n){ $jBul += "$j x$n" } }
  $kBul = @(); foreach($x in $KLISE){ $n = ([regex]::Matches($kucuk, [regex]::Escape($x))).Count; if($n){ $kBul += "$x x$n" } }

  # emoji: yuksek vekil cift (U+1F300+ blogu) + sik semboller (U+2600-U+27BF)
  $emoji = ([regex]::Matches($metin, '[\uD800-\uDBFF]|[☀-➿]')).Count
  $unlem = ([regex]::Matches($metin, '!')).Count
  $uzunluk = [math]::Max($metin.Length, 1)
  $emojiBin = [math]::Round($emoji * 1000.0 / $uzunluk, 1)

  $puan = ($jBul.Count * 3) + ($kBul.Count * 3) + [math]::Floor($emojiBin) + [math]::Min($unlem, 10)
  $sonuc += [pscustomobject]@{ Sayfa = $h.Name; Puan = $puan; Jargon = $jBul.Count; Klise = $kBul.Count; EmojiBin = $emojiBin; Unlem = $unlem }
  foreach($b in $jBul){ $bulgular += "$($h.Name): JARGON '$b'" }
  foreach($b in $kBul){ $bulgular += "$($h.Name): KLISE '$b'" }
}

"=== SAYFA PUANLARI (yuksek = kokulu) ==="
$sonuc | Sort-Object Puan -Descending | Format-Table -AutoSize | Out-String -Width 120
"=== BULGULAR ==="
$bulgular | ForEach-Object { "  $_" }
if(-not $bulgular.Count){ "  Jargon/klise bulgusu yok." }
# CI kapisi: izinli olmayan jargon/klise varsa KIRMIZI (emoji/unlem yalniz rapor)
if($bulgular.Count){ exit 1 }
