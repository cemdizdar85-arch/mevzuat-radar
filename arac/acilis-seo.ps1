# arac/acilis-seo.ps1 — AÇILIŞ SEO'SU (04.10.2026, Cem "başlayalım", V2 madde 54)
#
# NEDEN: site açılışa dek arama motorlarına KAPALI (robots.txt "Disallow: /", seviye testi + soru çöz sayfalarında
#   13.09'dan kalma noindex). Açılış sabahı bunların hepsi elle, tek tek açılacaktı; biri unutulursa site Google'da
#   hiç çıkmaz ve bunu kimse görmez. Ayrıca site haritasında gizli sayfa (canli-deneme) duruyordu; hiçbir sayfada canonical yoktu.
#
# İKİ KİP:
#   -Kanonik   (açılış ÖNCESİ de zararsız): site haritasındaki her sayfaya + ana sayfaya <link rel="canonical"> ekler (yoksa).
#   -Ac        (AÇILIŞ SABAHI, tek komut): robots.txt -> Allow + Sitemap · ACILACAK listesindeki sayfalardan noindex kalkar ·
#              site haritasından menu.js GIZLI listesindeki / diskte olmayan / noindex taşıyan sayfalar çıkar.
#   Parametresiz = KURU: ne yapılacağını söyler, dosyaya dokunmaz. Her kipten sonra DENETİM satırı basılır.
# GÖRMEZ: sayfanın içeriğinin aranabilir olup olmadığı · Google Search Console kaydı (Cem) · canonical'ın sorgu parametreli adresler için yeterliliği.
param([switch]$Kanonik, [switch]$Ac)
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding $false
$ALAN = 'https://tetikte.com/'
# Açılışta noindex'i kalkacak açık sayfalar (ücretsiz katman). Paketli sayfalar (sinav-gibi, ogrenci, yanlislarim) KALIR.
$ACILACAK = @('seviye-testi.html', 'sorular.html')

function Oku($ad) { [IO.File]::ReadAllText((Join-Path $kok $ad), [Text.Encoding]::UTF8) }
function Yaz($ad, $metin) { [IO.File]::WriteAllText((Join-Path $kok $ad), $metin, $utf8) }

$gizliDesen = [regex]::Match((Oku 'menu.js'), 'GIZLI\s*=\s*/(.+?)/[a-z]*;').Groups[1].Value
if (-not $gizliDesen) { throw 'menu.js GIZLI deseni okunamadi' }
$gizli = New-Object System.Text.RegularExpressions.Regex($gizliDesen)

$harita = Oku 'sitemap.xml'
$adresler = [regex]::Matches($harita, '<loc>https://tetikte\.com/([^<]*)</loc>') | ForEach-Object { $_.Groups[1].Value }
$sayfalar = @($adresler | ForEach-Object { if ($_ -eq '') { 'index.html' } else { $_ } })
$noindexDesen = '<meta name="robots" content="noindex[^"]*">\r?\n?'

$yap = @()
# 1) canonical
foreach ($s in $sayfalar) {
  $yol = Join-Path $kok $s
  if (-not (Test-Path $yol) -or $gizli.IsMatch($s)) { continue }   # gizli sayfa haritadan çıkacak, canonical almaz
  $t = Oku $s
  if ($t -match 'rel="canonical"') { continue }
  $hedef = if ($s -eq 'index.html') { $ALAN } else { $ALAN + $s }
  $yap += "canonical  $s -> $hedef"
  if ($Kanonik -or $Ac) {
    $t = [regex]::Replace($t, '(</title>)', "`$1`n<link rel=`"canonical`" href=`"$hedef`">", 1)
    Yaz $s $t
  }
}
# 2) açılış
$robotsYeni = "User-agent: *`nAllow: /`n`nSitemap: https://tetikte.com/sitemap.xml`n"
if ((Oku 'robots.txt') -ne $robotsYeni) { $yap += 'robots.txt -> Allow: / + Sitemap' ; if ($Ac) { Yaz 'robots.txt' $robotsYeni } }
foreach ($s in $ACILACAK) {
  $t = Oku $s
  if ($t -match $noindexDesen) { $yap += "noindex kalkar  $s"; if ($Ac) { Yaz $s ([regex]::Replace($t, $noindexDesen, '', 1)) } }
}
$cikan = @()
foreach ($a in $adresler) {
  $s = if ($a -eq '') { 'index.html' } else { $a }
  $neden = $null
  if (-not (Test-Path (Join-Path $kok $s))) { $neden = 'diskte yok' }
  elseif ($gizli.IsMatch($s)) { $neden = 'menu.js GIZLI' }
  elseif ((Oku $s) -match $noindexDesen -and -not ($ACILACAK -contains $s)) { $neden = 'noindex' }   # ACILACAK sayfalar açılışta noindex'ten çıkar
  if ($neden) { $cikan += $a; $yap += "haritadan cikar  $s ($neden)" }
}
if (($Ac -or $Kanonik) -and $cikan.Count) {   # gizli/olmayan sayfa haritadan şimdi de çıkabilir (robots kapalıyken zararsız)
  foreach ($a in $cikan) { $harita = [regex]::Replace($harita, '\s*<url><loc>https://tetikte\.com/' + [regex]::Escape($a) + '</loc></url>', '') }
  Yaz 'sitemap.xml' $harita
}

$kip = if ($Ac) { 'AC' } elseif ($Kanonik) { 'KANONIK' } else { 'KURU' }
Write-Host "ACILIS SEO [$kip]: $($yap.Count) is"
$yap | ForEach-Object { Write-Host "  $_" }

# DENETİM (her kipte): haritadaki her sayfa diskte, gizli değil, canonical taşıyor; açıldıysa noindex yok ve robots açık
$h2 = Oku 'sitemap.xml'
$sorun = @()
foreach ($m in [regex]::Matches($h2, '<loc>https://tetikte\.com/([^<]*)</loc>')) {
  $s = if ($m.Groups[1].Value -eq '') { 'index.html' } else { $m.Groups[1].Value }
  if (-not (Test-Path (Join-Path $kok $s))) { $sorun += "$s yok"; continue }
  $t = Oku $s
  if ($gizli.IsMatch($s)) { $sorun += "$s gizli"; continue }
  if (($Kanonik -or $Ac) -and $t -notmatch 'rel="canonical"') { $sorun += "$s canonical yok" }
  if ($Ac -and $t -match $noindexDesen) { $sorun += "$s noindex" }
}
if ($Ac -and (Oku 'robots.txt') -match 'Disallow:\s*/\s*$') { $sorun += 'robots hala kapali' }
if ($sorun.Count) { Write-Host "DENETIM: KIRMIZI - $($sorun -join ' · ')"; if ($Kanonik -or $Ac) { exit 1 } }
else { Write-Host "DENETIM: YESIL - haritada $(([regex]::Matches($h2, '<loc>')).Count) adres" }
