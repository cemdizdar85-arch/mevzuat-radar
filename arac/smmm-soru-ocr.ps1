# ============================================================================
#  SMMM YETERLİLİK 2019–2025 SORU SAYFASI OKUMA HATTI (yerel, API yok)   16.09.2026
#  Cem "1 VE 2 YAP". Girdi: veri/smmm-cevap-tamlik.json (arac/smmm-cevap-tamlik.ps1) — soru görüntü sayfaları.
#  Çalışma klasörü (git dışı): veri/smmm-arsiv/soru-ocr/<YYYY_D>/
#
#  -Kip Hazirla : sayfaları 300 dpi'ya çevirir, İKİ BAĞIMSIZ OCR koşar (Tesseract tur + Windows.Media.Ocr tr),
#                 sayfayı okunur yatay şeritlere böler (<ad>-seritNN.png). Görsel okuma bu şeritlerden yapılır
#                 ve <ad>.son.txt olarak yazılır (ajan/insan).
#  -Kip Denetle : her <ad>.son.txt belirtecini iki OCR'a ayrı ayrı hizalar (LCS). Rapor:
#                 DESTEKSİZ = hiçbir motorun desteklemediği belirteç; TEK MOTOR SAYI = rakamı yalnız bir motor destekliyor.
#                 İkisi de görüntüden ikinci kez kontrol edilmeden metin ambara yazılmaz.
#  Bilinen OCR hataları (16.09 ölçüldü): ₺ → £ $ # b ; % → 96 W ; tablolar satır karışır → OCR tek başına KULLANILMAZ.
#  Kullanım: powershell -NoProfile -File arac/smmm-soru-ocr.ps1 -Donem 2019_2 -Kip Hazirla|Denetle
# ============================================================================
param([Parameter(Mandatory)][string]$Donem, [ValidateSet('Hazirla','Denetle')][string]$Kip = 'Hazirla')
$ErrorActionPreference = 'Continue'
$depoKok = Split-Path -Parent $PSScriptRoot
$arsiv = Join-Path (Join-Path $depoKok 'veri') 'smmm-arsiv'
$calisma = Join-Path (Join-Path $arsiv 'soru-ocr') $Donem
[void](New-Item -ItemType Directory -Force $calisma)

function Belirtec([string]$s){ @(($s -replace '\|',' ' -replace '[\u201C\u201D]','"' -replace '[\u2018\u2019]',"'" -replace '(\d)(TL|\u20BA)','$1 $2') -split '\s+' | Where-Object { $_ -and $_ -notmatch '^[-:|]+$' }) }
function Anahtar([string]$s){ ($s -replace '[\u20BA£$#%|*]','' -replace '^[\(\["]+|[\)\]".,;:!?]+$','').Trim() }
function Destek($a, $b){
  $ka = @($a | ForEach-Object { Anahtar $_ }); $kb = @($b | ForEach-Object { Anahtar $_ })
  $n = $ka.Count; $m = $kb.Count; $w = $m + 1
  $tablo = New-Object int[] (($n+1)*$w)
  for($i = $n-1; $i -ge 0; $i--){ for($j = $m-1; $j -ge 0; $j--){ if($ka[$i] -ceq $kb[$j]){ $tablo[$i*$w+$j] = $tablo[($i+1)*$w+$j+1] + 1 } else { $x1 = $tablo[($i+1)*$w+$j]; $x2 = $tablo[$i*$w+$j+1]; $tablo[$i*$w+$j] = [Math]::Max($x1,$x2) } } }
  $var = New-Object bool[] $n; $i = 0; $j = 0
  while($i -lt $n -and $j -lt $m){ if($ka[$i] -ceq $kb[$j]){ $var[$i] = $true; $i++; $j++ } elseif($tablo[($i+1)*$w+$j] -ge $tablo[$i*$w+$j+1]){ $i++ } else { $j++ } }
  return ,$var
}

if($Kip -eq 'Hazirla'){
  $poppler = 'C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin'
  $tesseract = 'C:\Program Files\Tesseract-OCR\tesseract.exe'
  if(-not (Test-Path $tesseract) -or -not (Test-Path "$poppler\pdftoppm.exe")){ Write-Host 'KÖR: Tesseract ya da poppler yok.'; exit 2 }
  Add-Type -AssemblyName System.Drawing
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $null = [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
  $null = [Windows.Media.Ocr.OcrEngine,Windows.Foundation,ContentType=WindowsRuntime]
  $null = [Windows.Graphics.Imaging.BitmapDecoder,Windows.Foundation,ContentType=WindowsRuntime]
  $null = [Windows.Globalization.Language,Windows.Globalization,ContentType=WindowsRuntime]
  $gorevAc = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  function Bekle($islem, [Type]$tip){ $gorev = $gorevAc.MakeGenericMethod($tip).Invoke($null, @($islem)); $gorev.Wait(-1) | Out-Null; $gorev.Result }
  $ocrMotoru = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('tr'))
  if(-not $ocrMotoru){ Write-Host 'KÖR: Windows OCR (tr) açılamadı.'; exit 2 }
  $tamlik = Get-Content (Join-Path $depoKok 'veri\smmm-cevap-tamlik.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($kitap in $tamlik.kitapciklar){
    if($kitap.kok -notlike "smmm_$Donem`_*"){ continue }
    $sayfalar = @($kitap.goruntu_sayfasi | Where-Object { $kitap.cevap_sayfasi -eq 0 -or $_ -lt $kitap.cevap_sayfasi })
    foreach($s in $sayfalar){
      $ad = "$($kitap.kok)-s$s"; $png = Join-Path $calisma "$ad.png"
      if(-not (Test-Path $png)){ & "$poppler\pdftoppm.exe" -r 300 -gray -png -singlefile -f $s -l $s (Join-Path $arsiv "pdf\$($kitap.kok).pdf") (Join-Path $calisma $ad) 2>$null }
      if(-not (Test-Path (Join-Path $calisma "$ad.tes.txt"))){ & $tesseract $png (Join-Path $calisma "$ad.tes") -l tur --psm 4 2>$null | Out-Null }
      if(-not (Test-Path (Join-Path $calisma "$ad.win.txt"))){
        $dosyaNesnesi = Bekle ([Windows.Storage.StorageFile]::GetFileFromPathAsync($png)) ([Windows.Storage.StorageFile])
        $akis = Bekle ($dosyaNesnesi.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $cozucu = Bekle ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($akis)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitEslem = Bekle ($cozucu.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $sonuc = Bekle ($ocrMotoru.RecognizeAsync($bitEslem)) ([Windows.Media.Ocr.OcrResult])
        [IO.File]::WriteAllText((Join-Path $calisma "$ad.win.txt"), (($sonuc.Lines | ForEach-Object { $_.Text }) -join "`n"), (New-Object Text.UTF8Encoding($false)))
        $akis.Dispose()
      }
      if(-not (Test-Path (Join-Path $calisma "$ad-serit01.png"))){
        $resim = [Drawing.Bitmap]::new($png); $W = $resim.Width; $H = $resim.Height
        $kilit = $resim.LockBits([Drawing.Rectangle]::new(0,0,$W,$H), 'ReadOnly', 'Format24bppRgb')
        $adim = $kilit.Stride; $piksel = New-Object byte[] ($adim*$H); [Runtime.InteropServices.Marshal]::Copy($kilit.Scan0,$piksel,0,$piksel.Length); $resim.UnlockBits($kilit)
        $koyuluk = New-Object int[] $H
        for($y=0;$y -lt $H;$y++){ $toplam=0; $o=$y*$adim; for($x=0;$x -lt $W;$x+=3){ if($piksel[$o+$x*3] -lt 140){ $toplam++ } }; $koyuluk[$y]=$toplam }
        $bas = 0; $no = 0
        while($bas -lt $H){
          $son = [Math]::Min($H, $bas + 700)
          if($son -lt $H){ $kesim = $son; for($y=$son; $y -gt $bas + 350; $y--){ if($koyuluk[$y] -eq 0){ $kesim = $y; break } }; $son = $kesim }
          $bos = $true; for($y=$bas;$y -lt $son;$y++){ if($koyuluk[$y] -gt 3){ $bos = $false; break } }
          if(-not $bos){
            $no++
            $parca = $resim.Clone([Drawing.Rectangle]::new(0,$bas,$W,$son-$bas), $resim.PixelFormat)
            $kucuk = [Drawing.Bitmap]::new([int]($W*0.6), [int](($son-$bas)*0.6)); $cizim = [Drawing.Graphics]::FromImage($kucuk); $cizim.InterpolationMode='HighQualityBicubic'; $cizim.DrawImage($parca,0,0,$kucuk.Width,$kucuk.Height); $cizim.Dispose()
            $kucuk.Save((Join-Path $calisma ('{0}-serit{1:D2}.png' -f $ad,$no))); $kucuk.Dispose(); $parca.Dispose()
          }
          $bas = $son
        }
        $resim.Dispose()
      }
      Write-Host ("{0}: şerit {1}" -f $ad, @(Get-ChildItem $calisma -Filter "$ad-serit*.png").Count)
    }
  }
  exit 0
}

# --- Denetle
$toplamDesteksiz = 0; $toplamTek = 0; $eksik = 0
foreach($tes in (Get-ChildItem $calisma -Filter '*.tes.txt' | Sort-Object Name)){
  $ad = $tes.Name -replace '\.tes\.txt$',''
  $sonYolu = Join-Path $calisma "$ad.son.txt"
  if(-not (Test-Path $sonYolu)){ Write-Host "$ad`: GÖRSEL OKUMA YOK"; $eksik++; continue }
  $sonMetin = [IO.File]::ReadAllText($sonYolu,[Text.Encoding]::UTF8)
  $son = Belirtec $sonMetin
  $tb = Belirtec ([IO.File]::ReadAllText($tes.FullName,[Text.Encoding]::UTF8))
  $wb = Belirtec ([IO.File]::ReadAllText((Join-Path $calisma "$ad.win.txt"),[Text.Encoding]::UTF8))
  $dt = Destek $son $tb; $dw = Destek $son $wb
  $desteksiz = New-Object System.Collections.Generic.List[string]; $tekSayi = New-Object System.Collections.Generic.List[string]
  for($i = 0; $i -lt $son.Count; $i++){
    $baglam = ($son[([Math]::Max(0,$i-3))..([Math]::Min($son.Count-1,$i+3))] -join ' ')
    if($dt[$i] -and $dw[$i]){ continue }
    if($dt[$i] -or $dw[$i]){ if($son[$i] -match '\d'){ $tekSayi.Add("[$($son[$i])] ($(if($dt[$i]){'yalnız T'}else{'yalnız W'})) … $baglam") }; continue }
    if(-not (Anahtar $son[$i])){ continue }
    $desteksiz.Add("[$($son[$i])] … $baglam")
  }
  $toplamDesteksiz += $desteksiz.Count; $toplamTek += $tekSayi.Count
  $okunamadi = ([regex]::Matches($sonMetin,'\[OKUNAMADI\]')).Count
  Write-Host ("{0}: belirteç {1} · DESTEKSİZ {2} · TEK MOTOR SAYI {3} · OKUNAMADI {4}" -f $ad,$son.Count,$desteksiz.Count,$tekSayi.Count,$okunamadi)
  foreach($x in $desteksiz){ Write-Host "    desteksiz: $x" }
  foreach($x in $tekSayi){ Write-Host "    tek-motor: $x" }
}
Write-Host "ÖZET $Donem`: desteksiz $toplamDesteksiz · tek motor sayı $toplamTek · görsel okuması eksik sayfa $eksik"
