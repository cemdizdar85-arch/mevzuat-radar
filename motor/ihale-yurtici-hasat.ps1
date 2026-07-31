# ============================================================================
#  IHALE YURTICI HASAT - ilan.gov.tr (Basin Ilan Kurumu resmi portali) acik
#  listeleme API'sinden gunun kamu ihale ilanlarini ceker -> veri/ihale-yurtici.json
#  API: POST /api/api/services/app/Ad/AdsByFilter  (Ilan Turu attr=2, IHALE deger=45984)
#  Robot gunluk kosar (kaynak.yml); UI: ihale-radari.html Yurt Ici sekmesi.
# ============================================================================
param([int]$Adet = 40)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# 31.07 OLCUM: API'nin attributeId filtresi GUVENILMEZ - akademik/emlak/tebligat da
# donduruyor. Tek saglam kimlik slugifyTitle'daki resmi kategori yolu:
# 'ihale-duyurulari-<tur>-...' (mal-alim / hizmet-alim / yapim-ve-insaat).
# Sayfalanir, YALNIZ ihale-duyurulari alinir, tur cikarilir.
function SlugTur([string]$slug){
  if($slug -match 'mal-alim'){ return 'mal' }
  if($slug -match 'hizmet-alim'){ return 'hizmet' }
  if($slug -match 'yapim'){ return 'yapim' }
  return 'diger'
}
$hamAds = @()
$atla = 0; $tur = 0
while($hamAds.Count -lt $Adet -and $tur -lt 25){
  $govde = @{ adFilterAttributes = @(@{ attributeId = 2; attributeValueIds = @(45984) }); maxResultCount = 20; skipCount = $atla } | ConvertTo-Json -Depth 5
  $r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
    -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90
  $sayfa = @($r.result.ads)
  if(-not $sayfa.Count){ break }
  $hamAds += @($sayfa | Where-Object { "$($_.slugifyTitle)" -match '^ihale-duyurulari' })
  $atla += $sayfa.Count
  $tur++
  Start-Sleep -Milliseconds 400
}

$ilanlar = @()
foreach($a in $hamAds){
  $tarih = ""
  if($a.publishStartDate){ try { $tarih = ([datetime]$a.publishStartDate).ToString("dd.MM.yyyy") } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
  $ilanlar += [ordered]@{
    ilanNo = $a.adNo
    baslik = $a.title
    kurum  = $a.advertiserName
    il     = $a.addressCityName
    ilce   = $a.addressCountyName
    tarih  = $tarih
    tur    = (SlugTur "$($a.slugifyTitle)")
    url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
  }
}
if(-not $ilanlar.Count){ Write-Host "UYARI: API bos dondu - json GUNCELLENMEDI (eski veri korunur)"; exit 0 }

# 31.07: BIRIKIMLI HAVUZ - her cekim dosyayi sifirlamasin; il suzgecinde derinlik
# olsun diye eski ilanlar korunur (mukerrer ilanNo ayiklanir, 14 gunden eski duser,
# tavan 250). Ihale ilanlari zaten teklif tarihinden gunler once yayinlanir.
$yol = Join-Path $kok "veri\ihale-yurtici.json"
$eskiler = @()
if(Test-Path $yol){
  try {
    $mevcut = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $yeniNolar = @($ilanlar | ForEach-Object { "$($_.ilanNo)" })
    $sinirTarih = (Get-Date).AddDays(-14)
    foreach($e in @($mevcut.ilanlar)){
      if($yeniNolar -contains "$($e.ilanNo)"){ continue }
      $eskiSlug = ("$($e.url)" -split '/')[-1]
      if($eskiSlug -notmatch '^ihale-duyurulari'){ continue }  # eski cop (emlak/tebligat/personel) havuzdan dusurulur
      $t = $null; try { $t = [datetime]::ParseExact("$($e.tarih)","dd.MM.yyyy",$null) } catch {}
      if($t -and $t -lt $sinirTarih){ continue }
      $eskiler += [ordered]@{ ilanNo=$e.ilanNo; baslik=$e.baslik; kurum=$e.kurum; il=$e.il; ilce=$e.ilce; tarih=$e.tarih; tur=(SlugTur $eskiSlug); url=$e.url }
    }
  } catch { Write-Host "NOT: eski json okunamadi, sifirdan yazilir" }
}
$ilanlar = @($ilanlar + $eskiler) | Select-Object -First 250

$cikti = [ordered]@{
  guncelleme = "Kaynak: Basın İlan Kurumu (195 s. Kanun'la kurulu kamu kurumu) Resmî İlan Portalı — ilan.gov.tr. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynak = "ilan.gov.tr"
  ilanlar = $ilanlar
}
($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
Write-Host ("YURTICI IHALE: {0} ilan ({1} yeni cekim + {2} havuzdan) -> veri/ihale-yurtici.json" -f $ilanlar.Count, ($ilanlar.Count - $eskiler.Count), $eskiler.Count)
