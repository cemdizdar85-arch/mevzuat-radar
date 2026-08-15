# ============================================================================
#  MARKA LOGO HASH (15.08.2026) - Cem "#6 logo/gorsel benzerlik".
#
#  NE: Son basvurular indeksindeki (marka-yeni-basvurular.json) kayitlarin
#  TMview kucuk gorselini indirip ALGISAL HASH (dHash 64-bit) hesaplar, kayda
#  'logo' kolonu olarak ekler. Istemci (marka-izleme.html) kullanicinin
#  yukledigi logonun dHash'ini bununla Hamming mesafesiyle karsilastirir ->
#  benzer LOGOLU basvurular. Tam ML degil; dHash pratik/standart yoldur.
#
#  DHASH: gorseli 9x8 gri kucult, her satirda komsu pikselleri karsilastir
#  (sol<sag -> 1 bit), 8x8=64 bit -> 16 hane hex. Isik/olcek/sikistirmaya dayanikli.
#
#  NEDEN AYRI BETIK + IMAGEMAGICK: harvester ubuntu-latest'te kosar, System.Drawing
#  Linux'ta yok; ImageMagick ('convert') Actions ubuntu'da KURULU. 'convert' yoksa
#  (yerel Windows testi) kendini ATLAR. Incremental: yalniz 'logo'su olmayan
#  kayitlari, TAVANLI ($Adet) isler (TMview'e nazik + hizli).
#  ENV/gereksinim: ImageMagick. Cikti: ayni veri/marka-yeni-basvurular.json (logo eklenir).
# ============================================================================
param([int]$Adet = 400, [int]$BeklemeMs = 120)
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$yol  = Join-Path $kok "veri\marka-yeni-basvurular.json"
if(-not (Test-Path $yol)){ Write-Host "indeks yok"; exit 0 }
$cv = (Get-Command convert -ErrorAction SilentlyContinue)
# Windows'ta 'convert' NTFS aracidir; ImageMagick'i 'magick' ya da -version ile ayirt et
$magick = (Get-Command magick -ErrorAction SilentlyContinue)
$imBin = if($magick){ "magick" } elseif($cv -and ((& convert -version 2>$null) -match 'ImageMagick')){ "convert" } else { $null }
if(-not $imBin){ Write-Host "ImageMagick yok (yerel Windows) - logo hash ATLANDI, Actions'ta kosar."; exit 0 }

$obj = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$kol = @($obj.kolon)
if($kol -notcontains 'logo'){ $kol += 'logo' }
$iNo = $kol.IndexOf('no'); $iSt = $kol.IndexOf('st13'); $iLogo = $kol.IndexOf('logo')
$satirlar = @($obj.basvurular)
$h = @{ "User-Agent"="Mozilla/5.0 (MevzuatRadar-Marka)"; "Referer"="https://www.tmdn.org/tmview/" }
$tmp = Join-Path ([IO.Path]::GetTempPath()) "mrlogo.jpg"

function DHash($jpgYol){
  # 9x8 gri pixel degerlerini txt: ile al
  $out = & $imBin $jpgYol -resize "9x8!" -colorspace Gray -depth 8 txt:- 2>$null
  $pix = @{}
  foreach($ln in $out){ $m=[regex]::Match($ln,'^(\d+),(\d+):\s*\(\s*(\d+)'); if($m.Success){ $pix["$($m.Groups[1].Value),$($m.Groups[2].Value)"]=[int]$m.Groups[3].Value } }
  if($pix.Count -lt 72){ return $null }
  $bits = ""
  for($y=0;$y -lt 8;$y++){ for($x=0;$x -lt 8;$x++){ $l=$pix["$x,$y"]; $r=$pix["$([int]($x+1)),$y"]; $bits += $(if($l -lt $r){"1"}else{"0"}) } }
  # 64 bit -> 16 hane hex
  $hex=""; for($i=0;$i -lt 64;$i+=4){ $nib=[Convert]::ToInt32($bits.Substring($i,4),2); $hex += ("{0:x}" -f $nib) }
  return $hex
}

$islenen=0; $basarili=0
foreach($s in $satirlar){
  if($islenen -ge $Adet){ break }
  $arr = @($s)
  # logo zaten var mi
  $mevcutLogo = if($iLogo -lt $arr.Count){ "$($arr[$iLogo])" } else { "" }
  if($mevcutLogo){ continue }
  $st13 = "$($arr[$iSt])"; if(-not $st13){ continue }
  try{
    Invoke-WebRequest -Uri "https://www.tmdn.org/tmview/api/trademark/thumbnail/$st13" -Headers $h -OutFile $tmp -TimeoutSec 30 -UseBasicParsing
    $hash = DHash $tmp
  }catch{ $hash = $null }
  # kaydi logo kolonuyla guncelle (dizi uzunlugunu iLogo'ya tamamla)
  while($arr.Count -le $iLogo){ $arr += "" }
  $arr[$iLogo] = if($hash){ $hash } else { "-" }   # "-" = denendi, gorsel yok/bozuk (tekrar deneme)
  # geri yaz (referans dizi degisti; obj.basvurular'i sonra yeniden kuracagiz)
  $s2 = $arr
  # not: PS dizileri deger tipli degil; asagida tam listeyi yeniden kuruyoruz
  $islenen++; if($hash){ $basarili++ }
  # gecici olarak isaretle
  $s | Add-Member -NotePropertyName __yeni -NotePropertyValue $arr -Force
  Start-Sleep -Milliseconds $BeklemeMs
}
Write-Host ("Logo hash: {0} denendi, {1} basarili" -f $islenen, $basarili)

# yeniden kur (kompakt, elle JSON - {value,Count} tuzagi)
function JStr($s){ if($null -eq $s){ return '""' }; return (ConvertTo-Json ([string]$s) -Compress) }
$yeniSatirlar = foreach($s in $satirlar){
  $arr = if($s.PSObject.Properties['__yeni']){ @($s.__yeni) } else { @($s) }
  while($arr.Count -le $iLogo){ $arr += "" }
  '['+((@($arr) | ForEach-Object { JStr $_ }) -join ',')+']'
}
$basStr = '['+($yeniSatirlar -join ',')+']'
$bas = [ordered]@{ guncelleme=$obj.guncelleme; not=$obj.not; pencereGun=$obj.pencereGun; kolon=$kol; sayi=$satirlar.Count }
$basJson = ($bas | ConvertTo-Json -Compress)
$tam = $basJson.Substring(0,$basJson.Length-1) + ',"basvurular":' + $basStr + '}'
$tam | Out-File $yol -Encoding utf8
$geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
$logolu = @($geri.basvurular | Where-Object { $_[$iLogo] -and $_[$iLogo] -ne '-' }).Count
Write-Host ("-> {0} - kolon: {1} - logo hash'li kayit: {2}" -f $yol, ($kol -join ','), $logolu)
