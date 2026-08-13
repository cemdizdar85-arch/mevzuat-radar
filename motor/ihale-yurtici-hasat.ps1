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
# 13.08 OLCUM (ihale-slug-kesif.ps1, 600 ilan): duzeltme ve iptal ilanlari AYRI ilan
# olarak dusuyor ve simdiye kadar acik ihale gibi listeleniyordu. Iyi haber: bu
# ilanlarin BASLIGINDA duzelttikleri/iptal ettikleri ilanin numarasi yaziyor:
#   "Duzeltme ilani ILN02527595 ihale"  ·  "Ihale iptal ilani ( ILN02523833 ihale)"
# Birlestirme kimligi bu numaradir - uydurmaya gerek yok, kaynakta yaziyor.
function IlanDurumu([string]$baslik, [string]$slug){
  $h = "$baslik $slug"
  if($h -imatch 'iptal'){ return 'iptal' }
  if($h -imatch 'd[uü]zeltme|tashih'){ return 'duzeltme' }
  return 'asil'
}
function AsilIlanNo([string]$baslik, [string]$kendiNo){
  # Baslikta kendi numarasi disinda bir ILN varsa, o duzeltilen/iptal edilen ilandir.
  foreach($m in ([regex]'ILN\d{6,}').Matches("$baslik")){
    if("$($m.Value)" -ne "$kendiNo"){ return $m.Value }
  }
  return ""
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

# ============================================================================
#  14.08 Cem: "burada hap bilgi versek ihale bedeli vs gibi sence"
#  OLCULDU: ilan.gov.tr'nin DETAY ucu (AdDetail/GetAdDetail?id=) ilanin tam
#  metnini veriyor. Icinden cikan karar bilgileri: son teklif tarihi/saati, IKN,
#  ihale usulu, gecici teminat orani, yerli istekli sarti, is deneyimi orani,
#  teklif gecerlilik suresi, isin suresi, sinir deger katsayisi.
#  DIKKAT - YAKLASIK MALIYET YOK: 4734'te yaklasik maliyet ilanla aciklanmaz,
#  API'de de attrEstimatedPrice bos gelir. "Ihale bedeli" GOSTERILMEZ; olcmedigimiz
#  rakami yazmayiz. Gosterilenler yalniz ilan metninde YAZAN seylerdir.
#  Detay yalniz YENI ilanlar icin cekilir (havuzdakiler tekrar cekilmez).
# ============================================================================
function DetayCek([string]$id){
  try {
    $d = Invoke-RestMethod -Uri "https://www.ilan.gov.tr/api/api/services/app/AdDetail/GetAdDetail?id=$id" `
         -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } -TimeoutSec 60
  } catch { return $null }
  $h = "$($d.result.content)"
  if(-not $h){ return $null }
  # HTML tablodan duz metin (etiketler sokulur, bosluklar sadelesir)
  $m = ($h -replace '<[^>]+>',' ') -replace '&nbsp;',' ' -replace '&amp;','&' -replace '\s+',' '
  $al = {
    param($desen)
    $r = [regex]::Match($m, $desen)
    if($r.Success){ return ($r.Groups[1].Value.Trim() -replace '\s{2,}',' ') }
    return ""
  }
  [ordered]@{
    ikn        = (& $al 'İhale Kayıt Numarası \(İKN\)\s*:\s*(\d{4}/\d+)')
    sonTeklif  = (& $al '2\.1\.\s*Tarih ve Saati\s*:\s*([\d.]+\s*-\s*[\d:]+)')
    usul       = (& $al '(4734 sayılı Kamu İhale Kanununun \d+ [^.]{0,40}maddesine göre [^.]{0,45}usul[üu])')
    teminat    = (& $al '(teklif ettikleri bedelin\s*%\s*\d+\S{0,2}[^.]{0,60}geçici teminat)')
    yerliSart  = (& $al '(İhaleye sadece yerli istekliler katılabilecektir)')
    isDeneyimi = (& $al 'teklif edilen bedelin\s*%\s*(\d+)\s*oranından az olmamak')
    gecerlilik = (& $al 'tekliflerin geçerlilik süresi, ihale tarihinden itibaren\s*(\d+\s*\([^)]*\))')
    isSuresi   = (& $al '3\.4\.\s*Süresi/teslim tarihi\s*:\s*([^:]{5,90}?)\s*3\.5')
    sinirN     = (& $al 'Sınır Değer Katsayısı \(N\)\s*:\s*([\d,]+)')
  }
}

# Havuzda detayi ZATEN olan ilanlari tekrar cekmemek icin once eskiyi oku
$eskiDetay = @{}
$yolOn = Join-Path $kok "veri\ihale-yurtici.json"
if(Test-Path $yolOn){
  try {
    $on = Get-Content $yolOn -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($e in @($on.ilanlar)){ if($e.detay){ $eskiDetay["$($e.ilanNo)"] = $e.detay } }
  } catch {}
}

$ilanlar = @()
$detayCekilen = 0
foreach($a in $hamAds){
  $tarih = ""
  if($a.publishStartDate){ try { $tarih = ([datetime]$a.publishStartDate).ToString("dd.MM.yyyy") } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
  $detay = $null
  if($eskiDetay.ContainsKey("$($a.adNo)")){ $detay = $eskiDetay["$($a.adNo)"] }
  elseif((SlugTur "$($a.slugifyTitle)") -ne 'diger'){
    # yalniz gercek ihale ilanlari icin detay cekilir; kaynaga nazik olmak icin bekleme
    $detay = DetayCek "$($a.id)"
    $detayCekilen++
    Start-Sleep -Milliseconds 350
  }
  $ilanlar += [ordered]@{
    ilanNo = $a.adNo
    baslik = $a.title
    kurum  = $a.advertiserName
    il     = $a.addressCityName
    ilce   = $a.addressCountyName
    tarih  = $tarih
    tur    = (SlugTur "$($a.slugifyTitle)")
    durum  = (IlanDurumu "$($a.title)" "$($a.slugifyTitle)")
    asilNo = (AsilIlanNo "$($a.title)" "$($a.adNo)")
    detay  = $detay
    url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
  }
}
Write-Host ("Detay cekilen yeni ilan: {0} (havuzdan gelen detay: {1})" -f $detayCekilen, $eskiDetay.Count)
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
      # eski havuz kayitlarina da durum/asilNo hesaplanir (yeni alanlar geriye donuk dolar)
      $eskiler += [ordered]@{ ilanNo=$e.ilanNo; baslik=$e.baslik; kurum=$e.kurum; il=$e.il; ilce=$e.ilce; tarih=$e.tarih;
        tur=(SlugTur $eskiSlug); durum=(IlanDurumu "$($e.baslik)" $eskiSlug); asilNo=(AsilIlanNo "$($e.baslik)" "$($e.ilanNo)");
        detay=$e.detay; url=$e.url }
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
