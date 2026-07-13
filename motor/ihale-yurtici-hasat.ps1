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

$govde = @{ adFilterAttributes = @(@{ attributeId = 2; attributeValueIds = @(45984) }); maxResultCount = $Adet; skipCount = 0 } | ConvertTo-Json -Depth 5
$r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
  -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } `
  -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90

$ilanlar = @()
foreach($a in @($r.result.ads)){
  $tarih = ""
  if($a.publishStartDate){ try { $tarih = ([datetime]$a.publishStartDate).ToString("dd.MM.yyyy") } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
  $ilanlar += [ordered]@{
    ilanNo = $a.adNo
    baslik = $a.title
    kurum  = $a.advertiserName
    il     = $a.addressCityName
    ilce   = $a.addressCountyName
    tarih  = $tarih
    url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
  }
}
if(-not $ilanlar.Count){ Write-Host "UYARI: API bos dondu - json GUNCELLENMEDI (eski veri korunur)"; exit 0 }

$cikti = [ordered]@{
  guncelleme = "Kaynak: Basın İlan Kurumu (195 s. Kanun'la kurulu kamu kurumu) Resmî İlan Portalı — ilan.gov.tr. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynak = "ilan.gov.tr"
  ilanlar = $ilanlar
}
$yol = Join-Path $kok "veri\ihale-yurtici.json"
($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
Write-Host ("YURTICI IHALE: {0} ilan -> veri/ihale-yurtici.json" -f $ilanlar.Count)
