# ============================================================================
#  ALACAK ILAN HASAT - ilan.gov.tr'den IFLAS/KONKORDATO ilanlarini ceker.
#  (31.07 Cem onayi: "evet bunu yapalim; gunde iki kere ceksinler" - ihale
#  taktiginin aynisi.) Kaynak ayni acik API; kimlik slug'dan: 'iflas-hukuku-...'
#  Cikti: veri/alacak-ilan-canli.json - alacak-radari.html canli bolumu okur.
#  NOT: veri/alacak-ilan.json (VKN'li tohum, eslestirme motoru) AYRI durur;
#  VKN'li gercek eslestirme ilan DETAYI ister -> Faz 2 (gorev #40).
#  Birikim: mukerrer ilanNo ayiklanir, 90 gunden eski duser (IIK surecleri
#  uzun - konkordato muhleti aylar surer), tavan 400. API bos donerse dosya
#  GUNCELLENMEZ (kor kalma).
# ============================================================================
param([int]$Adet = 60)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function IlanTur([string]$metin){
  $m = $metin.ToLowerInvariant()
  if($m.Contains('konkordato') -or $m.Contains('muhlet')){ return 'konkordato' }
  if($m.Contains('iflas') -or $m.Contains('müflis') -or $m.Contains('muflis')){ return 'iflas' }
  return 'diger'
}

# sayfali cekim: yalniz iflas-hukuku kategorisi (slug kimligi - filtre parametresi guvenilmez)
$hamAds = @()
$atla = 0; $tur = 0
while($hamAds.Count -lt $Adet -and $tur -lt 40){
  $govde = @{ adFilterAttributes = @(); maxResultCount = 20; skipCount = $atla } | ConvertTo-Json -Depth 5
  $r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
    -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-AlacakRobotu)" } `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90
  $sayfa = @($r.result.ads)
  if(-not $sayfa.Count){ break }
  $hamAds += @($sayfa | Where-Object { "$($_.slugifyTitle)" -match '^iflas-hukuku' })
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
    tur    = (IlanTur "$($a.title) $($a.slugifyTitle)")
    url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
  }
}
if(-not $ilanlar.Count){ Write-Host "UYARI: iflas-hukuku ilani bulunamadi - json GUNCELLENMEDI (eski veri korunur)"; exit 0 }

# birikimli havuz
$yol = Join-Path $kok "veri\alacak-ilan-canli.json"
$eskiler = @()
if(Test-Path $yol){
  try {
    $mevcut = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $yeniNolar = @($ilanlar | ForEach-Object { "$($_.ilanNo)" })
    $sinirTarih = (Get-Date).AddDays(-90)
    foreach($e in @($mevcut.ilanlar)){
      if($yeniNolar -contains "$($e.ilanNo)"){ continue }
      $t = $null; try { $t = [datetime]::ParseExact("$($e.tarih)","dd.MM.yyyy",$null) } catch {}
      if($t -and $t -lt $sinirTarih){ continue }
      $eskiler += [ordered]@{ ilanNo=$e.ilanNo; baslik=$e.baslik; kurum=$e.kurum; il=$e.il; ilce=$e.ilce; tarih=$e.tarih; tur=$e.tur; url=$e.url }
    }
  } catch { Write-Host "NOT: eski json okunamadi, sifirdan yazilir" }
}
$ilanlar = @($ilanlar + $eskiler) | Select-Object -First 400

$cikti = [ordered]@{
  guncelleme = "Kaynak: Basın İlan Kurumu Resmî İlan Portalı (ilan.gov.tr) — mahkemelerin iflas/konkordato ilanları. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynak = "ilan.gov.tr"
  ilanlar = $ilanlar
}
($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
Write-Host ("ALACAK ILAN: {0} ilan ({1} havuzdan) -> veri/alacak-ilan-canli.json" -f $ilanlar.Count, $eskiler.Count)
