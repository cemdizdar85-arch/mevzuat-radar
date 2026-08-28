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
#
#  29.08.2026 OLCUM: eski surum 'adFilterAttributes' gonderiyordu - API bunu
#  YOK SAYIYOR. Sitenin kendi istegi yakalandi, dogru alan 'keys.txv':
#    txv 12 = Iflas Hukuku Davalari (49 = konkordato, 50 = iflas/tasfiye)
#  Sonuc: genel listeyi tarayip slug'la eleme bitti. Eskiden 40 tur x 20 = 800
#  ilan taranip ~45 tanesi tutuluyordu; kapsama penceresi sitenin GUNLUK TOPLAM
#  hacmine bagliydi (~333 ilan/gun -> ~2,4 gun). Hacim iki katina ciksa pencere
#  sessizce yariya duserdi. Artik kategori dogrudan isteniyor: 10 istek = ~200
#  ilan = ~10 gunluk pencere (kategori gunluk ~19 ilan basiyor).
# ============================================================================
param([int]$Adet = 200)
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

# sayfali cekim: kategori DOGRUDAN isteniyor (keys.txv=12). Sayfa boyutu sunucuda
# 20'de sabit - 50/100/500 istense de 20 doner, o yuzden 20 gonderilir.
$hamAds = @()
$donen  = 0          # oz-sinav: API'nin dondurdugu TOPLAM kayit (suzgecten once)
$atla = 0; $tur = 0
while($hamAds.Count -lt $Adet -and $tur -lt 40){
  $govde = '{"keys":{"txv":[12]},"sorting":"publish_time desc","skipCount":' + $atla + ',"maxResultCount":20}'
  $r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
    -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-AlacakRobotu)" } `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90
  $sayfa = @($r.result.ads)
  if(-not $sayfa.Count){ break }
  $donen += $sayfa.Count
  # slug suzgeci ARTIK YEDEK KEMER: kategori dogru geldiyse hepsi gecer.
  $hamAds += @($sayfa | Where-Object { "$($_.slugifyTitle)" -match '^iflas-hukuku' })
  $atla += $sayfa.Count
  $tur++
  Start-Sleep -Milliseconds 400
}

# --- OZ-SINAV: txv suzgeci hala calisiyor mu? ---
# Kaynak kategori kimligini degistirirse API sessizce GENEL listeyi doner; o zaman
# slug suzgeci cogunu eler ve biz "az ilan var" saniriz. Bu sessiz kaymayi yakala.
if($donen -gt 0){
  $oran = [math]::Round(100 * $hamAds.Count / $donen, 1)
  if($oran -lt 80){
    Write-Host ("UYARI: txv=12 suzgeci kaymis olabilir - donen {0} kaydin yalniz %{1}'i iflas-hukuku. " -f $donen, $oran)
    Write-Host "       ilan.gov.tr kategori kimligini degistirmis olabilir; kategori sayfasindan txv teyit edilmeli."
  } else {
    Write-Host ("oz-sinav: {0} kayit donen, %{1} iflas-hukuku (kategori suzgeci saglam)" -f $donen, $oran)
  }
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
# 29.08 KUSUR: 'Out-File -Encoding utf8' PS 5.1'de BOM YAZAR, pwsh'te YAZMAZ.
# Yani ciktinin bicimi betigi KIMIN kostuguna gore degisiyordu (CI'da BOM'suz,
# yerelde BOM'lu). BOM'lu dosyayi JSON.parse REDDEDER. Kardes betikteki
# (alacak-arsiv-tara.ps1) guvenli yazimla hizalandi: her yerde BOM'suz UTF-8.
[System.IO.File]::WriteAllText($yol, ($cikti | ConvertTo-Json -Depth 5), (New-Object System.Text.UTF8Encoding $false))
Write-Host ("ALACAK ILAN: {0} ilan ({1} havuzdan) -> veri/alacak-ilan-canli.json" -f $ilanlar.Count, $eskiler.Count)
