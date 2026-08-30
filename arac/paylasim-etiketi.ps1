# ============================================================================
#  PAYLAŞIM ETİKETİ YAYICI — og: / twitter: / theme-color / apple-touch-icon
#
#  NEDEN VAR (30.08.2026): Cem logoyu paylaşıp "yeni sitede bir şey
#  değiştirmeye gerek yok deme" dedi. Ölçüldü: 64 sayfanın YALNIZ 2'sinde
#  og etiketi vardı. Yani site içi 46 paylaşılabilir sayfanın linki
#  WhatsApp/LinkedIn/X'e atıldığında çıplak adres görünüyordu — marka yok,
#  başlık yok, görsel yok.
#
#  ÖLÇÜT: her sayfa KENDİ <title> ve <meta description>'ından beslenir.
#  Sabit metin kopyalamak yanlış olurdu - 46 sayfa aynı vaadi göstermez.
#
#  DOKUNULMAYANLAR:
#   · noindex sayfalar (iç paneller) - paylaşılmaz, etiket gereksiz
#   · og:title'ı ZATEN olan sayfalar (index.html genel kart,
#     fark.html kendi kahraman kartı) - üzerine yazılmaz
#
#  -Uygula verilmezse HİÇBİR ŞEY YAZMAZ, ne yapacağını söyler (kuru koşu).
# ============================================================================
param([switch]$Uygula)

$ErrorActionPreference = 'Stop'
$KOK  = Split-Path $PSScriptRoot -Parent
$SITE = 'https://tetikte.com'

function HtmlCoz($s){
  if($null -eq $s){ return '' }
  $s = $s -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"' -replace '&#39;',"'"
  return $s.Trim()
}
function HtmlKac($s){
  return ($s -replace '&','&amp;' -replace '"','&quot;' -replace '<','&lt;' -replace '>','&gt;')
}

$sayfalar = Get-ChildItem (Join-Path $KOK '*.html') -File | Sort-Object Name
$eklendi = 0; $atlandi = 0; $kusurlu = @()

foreach($f in $sayfalar){
  $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

  if($c -match 'noindex'){ $atlandi++; continue }
  if($c -match 'og:title'){ $atlandi++; continue }

  $mt = [regex]::Match($c, '(?s)<title>(.*?)</title>')
  $md = [regex]::Match($c, '<meta\s+name="description"\s+content="([^"]*)"')
  if(-not $mt.Success -or -not $md.Success){ $kusurlu += "$($f.Name) (title/description eksik)"; continue }

  $baslik  = HtmlCoz $mt.Groups[1].Value
  $aciklama = HtmlCoz $md.Groups[1].Value

  # "… — Tetikte" / "… | Tetikte" kuyruğu og:title'da tekrar olmasın:
  # og:site_name zaten "Tetikte" diyor, iki kez yazılınca paylaşım kartında
  # "Tetikte · Falan — Tetikte" gibi görünüyor.
  $ogBaslik = ($baslik -replace '\s*[—|–-]\s*Tetikte\s*$','').Trim()
  if($ogBaslik -eq ''){ $ogBaslik = $baslik }

  $url = "$SITE/$($f.Name)"
  $ogBaslikK = HtmlKac $ogBaslik
  $aciklamaK = HtmlKac $aciklama

  $blok = @"
<!-- Paylaşım etiketleri (30.08, arac/paylasim-etiketi.ps1). Sayfanın kendi
     title/description'ından türetildi; genel kapak kullanılır. -->
<meta property="og:type" content="website">
<meta property="og:locale" content="tr_TR">
<meta property="og:site_name" content="Tetikte">
<meta property="og:url" content="$url">
<meta property="og:title" content="$ogBaslikK">
<meta property="og:description" content="$aciklamaK">
<meta property="og:image" content="$SITE/og-kapak.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$ogBaslikK">
<meta name="twitter:description" content="$aciklamaK">
<meta name="twitter:image" content="$SITE/og-kapak.png">
"@

  # theme-color ve apple-touch-icon eksikse onlar da eklenir
  $ek = ''
  if($c -notmatch 'name="theme-color"'){ $ek += "`n<meta name=`"theme-color`" content=`"#1b1a18`">" }
  if($c -notmatch 'apple-touch-icon'){ $ek += "`n<link rel=`"apple-touch-icon`" href=`"favicon.svg`">" }

  $yeni = $c.Insert($md.Index + $md.Length, "`n" + $blok.TrimEnd() + $ek)

  if($Uygula){
    [System.IO.File]::WriteAllText($f.FullName, $yeni, (New-Object System.Text.UTF8Encoding($false)))
  }
  $eklendi++
  Write-Host ("  {0,-28} {1}" -f $f.Name, $ogBaslik)
}

Write-Host ""
Write-Host ("SONUC: {0} sayfaya eklendi, {1} atlandi (noindex ya da zaten var)." -f $eklendi, $atlandi) -ForegroundColor Cyan
if($kusurlu.Count){
  Write-Host "KUSURLU (title ya da description yok - ELLE bakilmali):" -ForegroundColor Yellow
  $kusurlu | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
if(-not $Uygula){ Write-Host "KURU KOSU - hicbir dosya yazilmadi. Yazmak icin: -Uygula" -ForegroundColor Yellow }
