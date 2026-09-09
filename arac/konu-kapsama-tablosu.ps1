# KONU KAPSAMA TABLOSU (10.09.2026, Cem: "ders, o dersin konusu, sınavda çıkmış soru sayısı ve
# yanına bizim şu an oluşturduğumuz soru — kaç soru yazmışız") — 0 USD, hiçbir model çağrısı yok.
#
# Ne yapar: her ders ve konu için üç sayıyı yan yana koyar.
#   1) ÇIKTIĞI DÖNEM  : son 7 dönemlik pencerede konunun kaç sınavda çıktığı (huni ölçümü)
#   2) HAVUZDAKİ SORU : soru_havuzu'nda o konuya yazılmış toplam soru
#   3) YAYINDA        : bunların kaçı yayin=true
#
# NAMUS NOTU: "çıkmış soru sayısı" diye bir alan ambarda YOK. Ölçülen şey konunun kaç DÖNEM
# çıktığıdır (eski-sgs-huni-*.json → etiketDonemSay). Sütun adı bu yüzden "çıktığı dönem".
# Uydurma yapılmaz; olmayan sayı tabloda boş kalır.
#
# Kullanım:
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1 -Ders "Mali Tablolar"
#
# Çıktı: veri/fabrika/konu-kapsama.csv (Excel'de açılır) + ekrana ders özeti.
#
# TUZAK KAYDI (bu betikte yaşandı, tekrar etmesin):
#   - Supabase gizli anahtarı TARAYICI User-Agent'ını reddeder ("Forbidden use of secret API key
#     in browser"). Invoke-WebRequest'e -UserAgent 'tetikte-olcum/1.0' verilir.
#   - PS 5.1'de @(ConvertFrom-Json ...) 800 satırlık diziyi 1 sayar. Doğrusu:
#     @((ConvertFrom-Json -InputObject $m) | ForEach-Object { $_ })
#   - order'sız sayfalama kararsızdır; her sorguda &order=id verilir.

param([string]$Ders='', [string]$Sinav='SGS', [switch]$Sessiz, [switch]$YalnizPencere)
$ErrorActionPreference='Stop'
$kok = Split-Path $PSScriptRoot -Parent

if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - olculemez, cikildi." -ForegroundColor Red; exit 1 }
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$U  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$UA = 'tetikte-olcum/1.0'

# --- 1) huni: konu -> ders + kac donem cikti ---
$huniYol = (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
if(-not $huniYol){ Write-Host "huni dosyasi bulunamadi (veri/fabrika/eski-sgs-huni-*.json) - cikildi." -ForegroundColor Red; exit 1 }
$h = ConvertFrom-Json -InputObject (Get-Content $huniYol.FullName -Raw -Encoding UTF8)
$donem = @{}; $konuDers = @{}
foreach($p in $h.etiketDonemSay.PSObject.Properties){
  $ad = "$($p.Name)"
  $donem[$ad] = [int]$p.Value
  $konuDers[$ad] = ("$($h.etiketDers.$ad)" -replace '\*$','')
}
$pencereAd = (@($h.pencere) -join ' ')
if(-not $Sessiz){ Write-Host ("huni: {0} | pencere: {1} | pencere konusu: {2}" -f $huniYol.Name, $pencereAd, $donem.Count) }

# --- 2) havuz: ders+konu bazinda toplam ve yayindaki soru ---
$toplam = @{}; $yayinda = @{}
$off = 0; $sayfa = 0
while($true){
  $adres = "$U`?select=ders,konu,yayin&sinav=eq." + [uri]::EscapeDataString($Sinav) + "&order=id&limit=1000&offset=$off"
  $ham = Invoke-WebRequest -Uri $adres -Headers $SB -UseBasicParsing -UserAgent $UA -TimeoutSec 180
  $metin = [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray())
  $r = @((ConvertFrom-Json -InputObject $metin) | ForEach-Object { $_ })
  $sayfa++
  if($r.Count -eq 0){ break }
  foreach($x in $r){
    $d = "$($x.ders)"; $k = "$($x.konu)"
    if(-not $d -or -not $k){ continue }
    $anahtar = "$d`t$k"
    if(-not $toplam.ContainsKey($anahtar)){ $toplam[$anahtar]=0; $yayinda[$anahtar]=0 }
    $toplam[$anahtar]++
    if([bool]$x.yayin){ $yayinda[$anahtar]++ }
  }
  $off += 1000
  if($r.Count -lt 1000){ break }
}
if(-not $Sessiz){ Write-Host ("havuz: {0} sayfa · {1} ders-konu ciftinde soru var" -f $sayfa, $toplam.Count) }

# --- 3) birlestir: hem huniden gelen konular hem havuzda soru yazilmis konular ---
$satirlar = New-Object System.Collections.Generic.List[object]
$gorulen = @{}

foreach($anahtar in $toplam.Keys){
  $parca = $anahtar -split "`t",2
  $d = $parca[0]; $k = $parca[1]
  if($Ders -and $d -notmatch $Ders){ continue }
  # -YalnizPencere: havuzda 9.698 farklı konu adı var ama sınavda son 7 dönemde çıkan konu 779.
  # Cem'in tablosu için anlamlı olan pencere konularıdır; gerisi serbest metin varyantı.
  if($YalnizPencere -and -not $donem.ContainsKey($k)){ continue }
  $gorulen[$k] = $true
  $satirlar.Add([pscustomobject]@{
    ders          = $d
    konu          = $k
    ciktigi_donem = $(if($donem.ContainsKey($k)){ $donem[$k] } else { '' })
    havuzda_soru  = $toplam[$anahtar]
    yayinda_soru  = $yayinda[$anahtar]
  })
}

# huniden gelip havuzda hic sorusu olmayan konular (asil bosluk bunlar)
foreach($k in $donem.Keys){
  if($gorulen.ContainsKey($k)){ continue }
  $d = $konuDers[$k]
  if(-not $d){ continue }
  if($Ders -and $d -notmatch $Ders){ continue }
  $satirlar.Add([pscustomobject]@{
    ders          = $d
    konu          = $k
    ciktigi_donem = $donem[$k]
    havuzda_soru  = 0
    yayinda_soru  = 0
  })
}

$sirali = @($satirlar | Sort-Object ders, @{ Expression='ciktigi_donem'; Descending=$true }, konu)

# --- 4) CSV ---
$csv = Join-Path $kok 'veri\fabrika\konu-kapsama.csv'
$sirali | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("CSV yazildi: {0} ({1} satir)" -f $csv, $sirali.Count) -ForegroundColor Green

# --- 5) ders ozeti ---
Write-Host ""
Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,8}" -f 'DERS','konu','donem','havuz','yayin','sorusuz')
Write-Host ("-" * 78)
foreach($g in ($sirali | Group-Object ders | Sort-Object { -($_.Group | Measure-Object -Property havuzda_soru -Sum).Sum })){
  $kn = $g.Count
  $dn = ($g.Group | Where-Object { "$($_.ciktigi_donem)" -ne '' } | Measure-Object -Property ciktigi_donem -Sum).Sum
  $hv = ($g.Group | Measure-Object -Property havuzda_soru -Sum).Sum
  $yy = ($g.Group | Measure-Object -Property yayinda_soru -Sum).Sum
  $sz = @($g.Group | Where-Object { $_.havuzda_soru -eq 0 }).Count
  Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,8}" -f $g.Name, $kn, $dn, $hv, $yy, $sz)
}
Write-Host ("-" * 78)
$tKn = $sirali.Count
$tHv = ($sirali | Measure-Object -Property havuzda_soru -Sum).Sum
$tYy = ($sirali | Measure-Object -Property yayinda_soru -Sum).Sum
$tSz = @($sirali | Where-Object { $_.havuzda_soru -eq 0 }).Count
Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,8}" -f 'TOPLAM', $tKn, '', $tHv, $tYy, $tSz)
