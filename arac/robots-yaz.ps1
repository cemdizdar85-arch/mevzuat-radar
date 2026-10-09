# arac/robots-yaz.ps1 — AÇILIŞ robots.txt METNİ TEK KAYNAKTAN (08.10.2026, site kolu, açılış öncesi denetim)
#
# NEDEN: GitHub Pages deponun TAMAMINI yayınlıyor (08.10 ölçüldü: /CLAUDE.md, /motor/gong.ps1, /radar-app/sql/UYGULANDI.md,
#   motor/cikti/ altında 354 HTML → 200). Açılışta robots "Allow: /" olunca bunlar ve menu.js GIZLI sayfaları Google'a açılırdı.
#   Gizli sayfaların 37'sinde noindex yoktu; çoğunu robotlar her gün yeniden ürettiği için (kartlar, radar, kaydir/kgk…)
#   elle eklenen etiket ilk koşuda silinir. robots.txt ise yalnız açılışta yazılır → koruma burada tek yerde durur.
#   gong.ps1 ve arac/acilis-seo.ps1 ikisi de robots.txt yazıyordu (iki ayrı metin) → ikisi de bu fonksiyonu çağırır.
#
# KULLANIM: . arac/robots-yaz.ps1 ; RobotsMetni $kok      (metni döndürür, dosyaya dokunmaz)
#           powershell -NoProfile -File arac/robots-yaz.ps1          (KURU: metni basar)
#           powershell -NoProfile -File arac/robots-yaz.ps1 -Yaz     (robots.txt'yi yazar — AÇILIŞTAN ÖNCE KOŞMA, siteyi açar)
#           powershell -NoProfile -File arac/robots-yaz.ps1 -Sinav   (öz-sınav)
# menu.js GIZLI listesi değişince (sayfa açılınca/gizlenince) açılış sonrası -Yaz yeniden koşulur.
# 🚫 GÖRMEZ: dosyalara erişimi KAPATMAZ (robots yalnız uyumlu arama motorlarına ricadır; adresi bilen yine açar) ·
#    deponun site dışı dosyalarının yayından çıkması ayrı iş (yalnız site dosyalarını yayınlamak).
param([switch]$Yaz, [switch]$Sinav)

# Herkese açık sayfaların KULLANMADIĞI klasörler (08.10 ölçüldü: index/fiyat/satin-al/ogrenci/seviye/sorular/deneme/
# kaydir/vitrin… src/href/fetch içinde 0 eşleşme). veri/ ve kutuphane/ BİLEREK yok: sayfalar oradan okuyor.
$script:ROBOTS_KAPALI_KLASOR = @('motor', 'arac', 'radar-app', 'sql', 'sql-yerel', 'arsiv', 'sayfalar', 'kaydir/kgk',
  'bulten', 'kaynak-ozetleri', 'kaynak-pdf', 'video', 'pazarlama', 'tasarim', 'mobil', 'gelen', 'evrak-app', 'rag-motor', 'kapsam')
# menu.js yüklemeyen, GIZLI listesinde olmayan sahipsiz sayfalar (08.10: fark.html ölçülmemiş iddia taşıyor)
$script:ROBOTS_KAPALI_SAYFA = @('fark.html')

function GizliSayfalar([string]$kok) {
  $menu = [IO.File]::ReadAllText((Join-Path $kok 'menu.js'), [Text.Encoding]::UTF8)
  $m = [regex]::Match($menu, 'var GIZLI = /\(\^\|\\/\)\(([^)]*)\)\\\.html')
  if (-not $m.Success) { throw 'robots-yaz: menu.js GIZLI deseni okunamadi' }
  return @($m.Groups[1].Value.Split('|') | Where-Object { $_ } | ForEach-Object { "$_.html" })
}

function RobotsMetni([string]$kok) {
  $s = New-Object System.Collections.Generic.List[string]
  $s.Add('# tetikte.com - arac/robots-yaz.ps1 uretir (gong.ps1 / acilis-seo.ps1 -Ac). Elle duzenleme; menu.js GIZLI degisince -Yaz.')
  $s.Add('User-agent: *')
  $s.Add('Allow: /')
  foreach ($k in $script:ROBOTS_KAPALI_KLASOR) { $s.Add("Disallow: /$k/") }
  $s.Add('Disallow: /*.md$')
  foreach ($p in ($script:ROBOTS_KAPALI_SAYFA + (GizliSayfalar $kok))) { $s.Add("Disallow: /$p") }
  $s.Add('')
  $s.Add('Sitemap: https://tetikte.com/sitemap.xml')
  return (($s -join "`n") + "`n")
}

if ($MyInvocation.InvocationName -ne '.') {
  $kok = Split-Path -Parent $PSScriptRoot
  if ($Sinav) {
    $t = RobotsMetni $kok
    $hata = @()
    if ($t -notmatch "(?m)^Allow: /$") { $hata += 'Allow: / yok' }
    if ($t -match "(?m)^Disallow: /$") { $hata += 'site tumden kapali' }
    foreach ($z in @('Disallow: /motor/', 'Disallow: /*.md$', 'Disallow: /fark.html', 'Disallow: /gtip.html', 'Disallow: /karsilastirma.html', 'Sitemap: https://tetikte.com/sitemap.xml')) {
      if (-not $t.Contains($z)) { $hata += "eksik: $z" }
    }
    # yanlış alarm yönü: haritadaki açık sayfalar kapatılmamalı
    $harita = [IO.File]::ReadAllText((Join-Path $kok 'sitemap.xml'), [Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($harita, '<loc>https://tetikte\.com/([^<]+)</loc>')) {
      $a = $m.Groups[1].Value
      if ($t.Contains("Disallow: /$a`n")) { $hata += "haritadaki sayfa kapali: $a" }
      foreach ($k in $script:ROBOTS_KAPALI_KLASOR) { if ($a.StartsWith("$k/")) { $hata += "haritadaki sayfa kapali klasorde: $a" } }
    }
    if ($hata.Count) { Write-Host "ROBOTS-YAZ SINAV: KIRMIZI - $($hata -join ' · ')"; exit 1 }
    Write-Host "ROBOTS-YAZ SINAV: YESIL ($(([regex]::Matches($t, 'Disallow')).Count) Disallow satiri, harita sayfalari acik)"
    exit 0
  }
  $metin = RobotsMetni $kok
  if ($Yaz) {
    [IO.File]::WriteAllText((Join-Path $kok 'robots.txt'), $metin, (New-Object Text.UTF8Encoding($false)))
    Write-Host 'robots.txt yazildi (robots-yaz).'
  } else { Write-Host $metin }
}
