# ============================================================================
#  GONG - ACILIS ANAHTARI (05.08.2026 gece kuruldu; hedef gong: 14.08.2026)
#
#  Cem "AC" dediginde TEK KOMUT kosulur:  powershell -File motor\gong.ps1
#  Iki kilidi birden cevirir ve push'lar:
#   1) PERDE: menu.js'teki PERDE-BASI/PERDE-SONU isaretli blok silinir
#      (adresi bilen herkes siteyi gorur; ?kapi anahtari geresiz kalir).
#   2) ROBOTS: robots.txt acilir (Allow: / + sitemap) - Google dizine alir.
#  sitemap.xml zaten depoda (05.08 gece, 37 sayfa).
#
#  GERI DONUS: git revert ile tek commit geri alinir; perde blogu git
#  tarihinde durur. Betik IDEMPOTENT: isaret yoksa "zaten acik" der, cikar.
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

$menu = Get-Content "$kok\menu.js" -Raw -Encoding UTF8
$deseni = '(?s)/\* ==== PERDE-BASI.*?PERDE-SONU[^\r\n]*\*/\s*'
if($menu -notmatch $deseni){
  Write-Host "Perde isareti bulunamadi - site ya ZATEN ACIK ya da menu.js elle degistirilmis. Hicbir sey yapilmadi."
} else {
  $menu = [regex]::Replace($menu, $deseni, '')
  [IO.File]::WriteAllText("$kok\menu.js", $menu, (New-Object Text.UTF8Encoding($false)))
  Write-Host "1/2 PERDE KALKTI (menu.js)."
}

# ---- 20.08 ONIZLEME SINIRSIZLIGI (Cem: "perde koduyla girene sinirsiz ver, acilista kapat")
#      ?kapi ile giren deneme cihazlari sayac tanimiyordu; perde kalkarken bu da kapanir.
$onizDeseni = '(?s)[ 	]*/* ==== ONIZLEME-SINIRSIZ-BASI.*?ONIZLEME-SINIRSIZ-SONU[^
]**/[ 	]*?
'
foreach($dosya in @('menu.js','deneme.html')){
  $yol = Join-Path $kok $dosya
  $icerik = [IO.File]::ReadAllText($yol)
  if($icerik -match $onizDeseni){
    $icerik = [regex]::Replace($icerik, $onizDeseni, '')
    [IO.File]::WriteAllText($yol, $icerik, (New-Object Text.UTF8Encoding($false)))
    Write-Host "ONIZLEME SINIRSIZLIGI KAPANDI ($dosya) - herkes normal hakka dondu."
  } else {
    Write-Host "Onizleme isareti yok ($dosya) - zaten kapali."
  }
}

$robots = @"
User-agent: *
Allow: /

Sitemap: https://tetikte.com/sitemap.xml
"@
[IO.File]::WriteAllText("$kok\robots.txt", $robots, (New-Object Text.UTF8Encoding($false)))
Write-Host "2/2 ROBOTS ACILDI (Allow: / + sitemap)."

if(-not (Test-Path "$kok\sitemap.xml")){ Write-Host "UYARI: sitemap.xml YOK - robots ona isaret ediyor!" }

git add menu.js deneme.html robots.txt
git commit -m "GONG: perde kalkti, onizleme sinirsizligi kapandi, robots acildi - tetikte.com YAYINDA"
git pull --rebase origin main
git push origin HEAD:main
Write-Host ""
Write-Host "GONG VURULDU. 1-2 dk icinde tetikte.com perdesiz servis edilir."
Write-Host "Elle kontrol listesi: (1) gizli pencerede tetikte.com ac - perde YOK mu?"
Write-Host "(2) deneme.html'de ucretsiz 15 soru geliyor mu? (3) fiyat.html acik mi?"
Write-Host "(4) Google Search Console'a sitemap bildir (opsiyonel, hizlandirir)."
