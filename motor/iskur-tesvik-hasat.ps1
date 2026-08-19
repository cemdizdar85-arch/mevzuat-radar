# ============================================================================
#  ISKUR TESVIK HASAT - ISKUR'un isveren tesvik ve programlarini kurumun kendi
#  menusunden ceker. (19.08 Cem: "iskur tesvikleri ekle".) KGF deseninin aynisi:
#  kurum liste degistirince (yeni program/tesvik sayfasi acilinca) bizim liste
#  kendiliginden guncellenir - 4447 gec.35 imalat programlari 2026-2028 doneminde
#  yeni sayfalar beklenir, robot yakalar.
#  Cikti: veri/iskur-tesvik.json - destekler.html "ISKUR" grubu okur.
#
#  Kaynak kesfi 19.08 OLCULDU: iskur.gov.tr ana sayfa menusu /isveren/ agacini
#  tasiyor (17 link); hizmet sayfalari (eleman arama, kayit, cizelge, danismanlik,
#  yurtdisi istihdam) DISLANIR, tesvik + program sayfalari kalir.
#  NOT: SGK prim tesvikleri (5510 m.81, 4447 gecici maddeler) ISKUR listesinde
#  DEGILDIR - UI notu ayri dunyaya isaret eder, RAKAM YAZILMAZ (7566 dersi:
#  "5 puan" 2 puana indi, hafizadan oran yazmak yasak).
#  Kor kalma: <5 kayit ya da tesvik kategorisi bos -> dosyaya DOKUNULMAZ, exit 1.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Web
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\iskur-tesvik.json"
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }

$anaDosya = Join-Path ([IO.Path]::GetTempPath()) "iskur-ana.html"
& $curlKomut -sSL -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $anaDosya "https://www.iskur.gov.tr"
if(-not (Test-Path $anaDosya)){ Write-Host "HATA: iskur.gov.tr cekilemedi"; exit 1 }
$anaHtml = Get-Content $anaDosya -Raw -Encoding UTF8

# hizmet sayfalari (tesvik/program degil) - bilincli dislama listesi
$dislanan = @('eleman-arama','kayit','isgucu-cizelgesi','isveren-danismanligi','yurtdisi-istihdam')

$kayitlar = @()
$gorulen = @{}
foreach($m in [regex]::Matches($anaHtml, '<a[^>]*href="(/isveren/[^"#]+)"[^>]*>([^<]{3,200})')){
  $yol = $m.Groups[1].Value
  $ad = [System.Web.HttpUtility]::HtmlDecode((($m.Groups[2].Value -replace '\s+',' ').Trim()))
  if(-not $ad){ continue }
  $govde = ($yol -replace '^/isveren/','').Trim('/')
  if(-not $govde){ continue }
  $ilkSegment = ($govde -split '/')[0]
  if($dislanan -contains $ilkSegment){ continue }
  # kisa calisma gibi alt sayfali konularda TEK kayit: ilk segmente indirgenir
  $anahtar = $ilkSegment
  if($anahtar -eq 'tesvikler'){
    $anahtar = $govde   # tesvikler/xxx her biri ayri kayit; ciplak /tesvikler/ atlanir
    if($anahtar -eq 'tesvikler'){ continue }
  }
  if($gorulen.ContainsKey($anahtar)){ continue }
  $gorulen[$anahtar] = 1
  # ad: alt sayfa basligi yerine konu adi (kisa calisma alt sayfasinda "Genel Bilgiler" yazar)
  if($ilkSegment -eq 'kisa-calisma-odenegi'){ $ad = 'Kısa Çalışma Ödeneği' }
  # tesviklerde url TAM alt yolu tasir; programlarda konu koku (alt sayfalar tekil kayit)
  $urlYolu = if($govde -match '^tesvikler/'){ $govde.Trim('/') } else { $ilkSegment }
  $kayitlar += [ordered]@{
    ad = $ad
    kategori = (&{ if($govde -match '^tesvikler/'){ 'Teşvik' } else { 'Program' } })
    url = ('https://www.iskur.gov.tr/isveren/' + $urlYolu + '/')
  }
}

$tesvikAdet = @($kayitlar | Where-Object { $_.kategori -eq 'Teşvik' }).Count
if(@($kayitlar).Count -lt 5 -or $tesvikAdet -lt 1){
  Write-Host ("HATA: beklenmedik veri ({0} kayit, tesvik {1}) - dosyaya DOKUNULMADI (menu yapisi degismis olabilir)" -f @($kayitlar).Count, $tesvikAdet)
  exit 1
}

$cikti = [ordered]@{
  guncelleme = "Kaynak: ISKUR isveren menusu (iskur.gov.tr, kurumun kendi listesi). Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = "https://www.iskur.gov.tr/isveren/"
  not = "SGK prim tesvikleri (5510 ve 4447 gecici maddeler) bu listede DEGILDIR; guncel oran ve sartlari icin SGK/muhasebecinle teyitles. Basvurular E-Sube ya da il mudurlugu uzerinden."
  kayitlar = $kayitlar
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("ISKUR: {0} kayit (tesvik {1}) -> veri/iskur-tesvik.json [geri okuma: {2}]" -f @($kayitlar).Count, $tesvikAdet, @($geriOkuma.kayitlar).Count)
if(@($geriOkuma.kayitlar).Count -ne @($kayitlar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
