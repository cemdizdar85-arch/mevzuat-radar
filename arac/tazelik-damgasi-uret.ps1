# ============================================================================
#  TAZELIK DAMGASI URETICI  (25.08.2026)
#
#  CEM: "bir daha site okunmayan eskide kalmayacak" + "son guncellenme
#  damgasini siteye koy."
#
#  NEDEN. Bugune kadar verinin tazeligini YALNIZ BIZ goruyorduk (tazelik
#  nobetcisi, veri kapisi). Ziyaretci bakmakta oldugu rakamin ne zamanki
#  veriden geldigini BILMIYORDU. Ciddi hukuk yayincilarinin hepsinde bu damga
#  vardir; bizde yoktu. Ve bir yan faydasi var: bayat veriyi BIZ gormesek de
#  musteri gorur - yani ikinci bir goz.
#
#  NE URETIR: veri/tazelik-damgasi.json
#     { uretim, sayfalar: { "gtip.html": { son, en_eski, dosya, bayat } } }
#  Her sayfa icin, O SAYFANIN cektigi veri/*.json dosyalarinin tazeligi.
#
#  OLCU: dosyanin SON GIT COMMIT'I. Dosyanin ICINDEKI tarih DEGIL.
#  (25.08 dersi: nice-siniflar.json icindeki "30.12.2016" kaynak tebligin RG
#   tarihiydi, bayatlik damgasi degil; o yuzden "22 dosya bayat" alarmi
#   sismisti. Taze verinin GELDIGI an dogru olcudur.)
#
#  NE GOSTERIR: "son" = en YENI veri dosyasinin tarihi -> "bu sayfadaki veri
#  en son ne zaman degisti". "en_eski" ise ipucu metnine (title) konur; tek
#  rakam gosterip digerini saklamak yerine ikisi de erisilebilir olsun.
#  "bayat" = sozlesmedeki azami_yas_saat asilmis mi (yalniz tanimli olanlarda).
#
#  KULLANIM: pwsh arac/tazelik-damgasi-uret.ps1
#  Gunluk nobette kosar; menu.js damgayi footer'a basar.
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

$soz = $null
$sozYol = Join-Path $kok 'veri/_sozlesme.json'
if (Test-Path $sozYol) { try { $soz = Get-Content $sozYol -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }

# sayfa -> cektigi veri dosyalari
$sayfaVeri = @{}
foreach ($h in Get-ChildItem -Filter *.html -File) {
  $t = Get-Content $h.FullName -Raw -Encoding UTF8
  $d = @()
  foreach ($m in [regex]::Matches($t, "veri/([A-Za-z0-9_\-\.]+\.json)")) { $d += "veri/" + $m.Groups[1].Value }
  $d = @($d | Select-Object -Unique | Where-Object { Test-Path $_ })
  if ($d.Count -gt 0) { $sayfaVeri[$h.Name] = $d }
}

# dosya -> son git commit tarihi (bir kez hesapla, sayfalar paylasir)
$dosyaTarih = @{}
foreach ($d in ($sayfaVeri.Values | ForEach-Object { $_ } | Select-Object -Unique)) {
  $ts = $null
  try { $ts = (git log -1 --format=%ct -- $d 2>$null | Select-Object -First 1) } catch {}
  if ($ts) { $dosyaTarih[$d] = ([DateTimeOffset]::FromUnixTimeSeconds([int]$ts)).LocalDateTime }
}

$cikti = [ordered]@{
  uretim = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  olcu = "dosyanin son git commit'i (icerikteki tarihler kaynak atfi olabilir, guncellik gostergesi degil)"
  sayfalar = [ordered]@{}
}
foreach ($s in ($sayfaVeri.Keys | Sort-Object)) {
  $tarihler = @()
  $bayat = $false
  foreach ($d in $sayfaVeri[$s]) {
    if (-not $dosyaTarih.ContainsKey($d)) { continue }
    $tarihler += $dosyaTarih[$d]
    if ($soz -and $soz.dosyalar.$d) {
      $az = $soz.dosyalar.$d.azami_yas_saat
      if ($null -ne $az -and "$az" -ne 'elle') {
        $yas = ((Get-Date) - $dosyaTarih[$d]).TotalHours
        if ($yas -gt [double]$az) { $bayat = $true }
      }
    }
  }
  if ($tarihler.Count -eq 0) { continue }
  $enYeni = ($tarihler | Sort-Object -Descending | Select-Object -First 1)
  $enEski = ($tarihler | Sort-Object | Select-Object -First 1)
  $cikti.sayfalar[$s] = [ordered]@{
    son      = $enYeni.ToString('yyyy-MM-dd')
    en_eski  = $enEski.ToString('yyyy-MM-dd')
    dosya    = $sayfaVeri[$s].Count
    bayat    = $bayat
  }
}

[IO.File]::WriteAllText((Join-Path $kok 'veri/tazelik-damgasi.json'), ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
$bayatSayi = @($cikti.sayfalar.Values | Where-Object { $_.bayat }).Count
Write-Host ("TAZELIK DAMGASI: {0} sayfa damgalandi | bayat isaretli: {1}" -f $cikti.sayfalar.Count, $bayatSayi)
Write-Host "-> veri/tazelik-damgasi.json"
exit 0
