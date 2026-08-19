# ============================================================================
#  ALACAK ARSIV TARAYICI (bir defalik geriye donuk tarama) — 19.08.2026
#  Cem: "arsiv turuna basla" (rakipte 19.309 kayit, bizde 19 gunluk havuz vardi)
#
#  ilan.gov.tr API'sinde KATEGORI/ARAMA FILTRESI YOK SAYILIYOR (uc varyant
#  denendi: categoryId/categoryIds/adCategoryId + searchText/keyword/filterText
#  -> hepsi genel listeyi donduruyor). Tek yol: derin sayfalama + slug suzme.
#  Olculen tavan: skipCount ~25.000 calisiyor (20.09.2025'e ulasiyor),
#  30.000 bos donuyor. Sayfa boyutu 20'de SABIT (50/100/200/500 istense de 20).
#
#  Bu betik gunluk nobette KOSMAZ (alacak-ilan-hasat.ps1 o isi yapar);
#  arsivi bir kez doldurmak icindir. Tekrar calistirilabilir (idempotent:
#  ilanNo bazli tekillestirme, mevcut kayitlar korunur).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$yol  = Join-Path $kok 'veri\alacak-ilan-canli.json'
$TAVAN = if ($env:TAVAN) { [int]$env:TAVAN } else { 28000 }

function IlanTur([string]$metin){
  $m = $metin.ToLowerInvariant()
  if($m.Contains('konkordato') -or $m.Contains('muhlet')){ return 'konkordato' }
  if($m.Contains('iflas') -or $m.Contains('müflis') -or $m.Contains('muflis')){ return 'iflas' }
  return 'diger'
}

$H = @{ 'Accept'='application/json'; 'User-Agent'='Mozilla/5.0 (MevzuatRadar-AlacakRobotu)' }
$bulunan = @{}   # ilanNo -> kayit
$atla = 0; $bosTur = 0; $istek = 0
$basla = Get-Date

while ($atla -lt $TAVAN) {
  $govde = @{ adFilterAttributes = @(); maxResultCount = 20; skipCount = $atla } | ConvertTo-Json -Depth 5
  try {
    $r = Invoke-RestMethod -Method Post -Uri 'https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter' `
      -Headers $H -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 90
    $istek++
  } catch {
    Write-Host ("  istek hatasi (skip={0}): {1} - 3 sn bekle, devam" -f $atla, $_.Exception.Message)
    Start-Sleep -Seconds 3
    $atla += 20
    continue
  }
  $sayfa = @($r.result.ads)
  if (-not $sayfa.Count) { $bosTur++; if ($bosTur -ge 3) { Write-Host ("  bos sayfa x3 (skip={0}) -> TAVAN, duruluyor" -f $atla); break } }
  else { $bosTur = 0 }

  foreach ($a in @($sayfa | Where-Object { "$($_.slugifyTitle)" -match '^iflas-hukuku' })) {
    $tarih = ''
    if ($a.publishStartDate) { try { $tarih = ([datetime]$a.publishStartDate).ToString('dd.MM.yyyy') } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
    $no = "$($a.adNo)"
    if (-not $bulunan.ContainsKey($no)) {
      $bulunan[$no] = [ordered]@{
        ilanNo = $a.adNo
        baslik = $a.title
        kurum  = $a.advertiserName
        il     = $a.addressCityName
        ilce   = $a.addressCountyName
        tarih  = $tarih
        tur    = (IlanTur "$($a.title) $($a.slugifyTitle)")
        url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
      }
    }
  }
  $atla += 20
  if ($atla % 2000 -eq 0) {
    $sonT = if ($sayfa.Count) { try { ([datetime]$sayfa[-1].publishStartDate).ToString('dd.MM.yyyy') } catch { '?' } } else { '?' }
    Write-Host ("  skip={0,6} · toplanan iflas/konkordato={1,5} · o sayfadaki tarih={2} · gecen={3:mm\:ss}" -f $atla, $bulunan.Count, $sonT, ((Get-Date) - $basla))
  }
  Start-Sleep -Milliseconds 250
}

Write-Host ("TARAMA BITTI: {0} istek, {1} iflas/konkordato ilani bulundu ({2:mm\:ss})" -f $istek, $bulunan.Count, ((Get-Date) - $basla))

# --- mevcut havuzla BIRLESTIR (mevcut kayitlar korunur: borclu/vkn zenginlestirmesi kaybolmasin) ---
$mevcut = @()
if (Test-Path $yol) {
  $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $mevcut = @($j.ilanlar)
  # yedek
  Copy-Item $yol ($yol + '.yedek') -Force
}
$eskiSayi = @($mevcut).Count
$havuz = [ordered]@{}
foreach ($e in $mevcut) { $havuz["$($e.ilanNo)"] = $e }          # once mevcut (zengin) kayitlar
foreach ($k in $bulunan.Keys) { if (-not $havuz.Contains($k)) { $havuz[$k] = $bulunan[$k] } }

# tarihe gore yeni->eski sirala
$liste = @($havuz.Values) | Sort-Object -Property @{ Expression = {
  try { [datetime]::ParseExact("$($_.tarih)", 'dd.MM.yyyy', $null) } catch { [datetime]'1900-01-01' } } } -Descending

$cikti = [ordered]@{
  guncelleme = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  kaynak     = 'Basin Ilan Kurumu Resmi Ilan Portali (ilan.gov.tr) - iflas-hukuku kategorisi'
  adet       = @($liste).Count
  ilanlar    = $liste
}
[System.IO.File]::WriteAllText($yol, ($cikti | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding $false))

# --- YAZ -> GERI OKU -> KARSILASTIR ---
$geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$yeniSayi = @($geri.ilanlar).Count
$tarihler = @($geri.ilanlar) | ForEach-Object { try { [datetime]::ParseExact("$($_.tarih)",'dd.MM.yyyy',$null) } catch {} }
$enEski = ($tarihler | Measure-Object -Minimum).Minimum
$enYeni = ($tarihler | Measure-Object -Maximum).Maximum
Write-Host ("GERI OKUMA: {0} -> {1} ilan (+{2}); tarih araligi {3:dd.MM.yyyy} .. {4:dd.MM.yyyy}" -f $eskiSayi, $yeniSayi, ($yeniSayi-$eskiSayi), $enEski, $enYeni)
if ($yeniSayi -lt $eskiSayi) { throw 'KAYIP VAR: yeni sayi eskiden kucuk - yedekten don (.yedek)' }
