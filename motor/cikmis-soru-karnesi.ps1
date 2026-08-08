# ============================================================================
#  CIKMIS SINAV KARNESI - YIL YIL, SINAV SINAV - 08.08.2026
#
#  CEM: "3 sinavimizin eski sinavda cikmis konularini hepsini yut ve ezberle,
#        hangi yila kadar yuttugunu yil yil tablo yap, ben de artik kontrol
#        edecegim sana guvenmeyecegim."
#
#  BU DOSYA BIR KANIT TABLOSUDUR. Benim sozume degil buna bakilir. Her satir
#  BIR DONEM ve dort sutun tasir:
#    ARSIVDE  - veri/sinav-arsiv.json'da adresi var mi
#    INDI     - PDF fiilen indirildi mi (dosya diskte mi)
#    METIN    - pdftotext ile metne dondu mu, kac bayt
#    SORU     - kac soru AYRISTIRILABILDI (130 beklenir; dusukse ayristirici kaybediyor)
#  Eksik olan satir GIZLENMEZ, "YOK" yazar. Karne tam olmadan "yuttuk" denmez.
#
#  Cikti: veri/cikmis-soru-karnesi.json  +  ekrana tablo
#  BEDAVA.
# ============================================================================
param([string]$klasor = '')
$ErrorActionPreference='Continue'
if($klasor -eq ''){ $klasor = Join-Path $env:TEMP 'cikmis-soru' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function SorulariCikar([string]$metin){
  $liste = New-Object System.Collections.Generic.List[object]
  foreach($p in [regex]::Split($metin, '(?m)^(?=\s{0,4}\d{1,3}\.\s)')){
    if($p.Trim().Length -lt 50){ continue }
    $no = [regex]::Match($p, '^\s*(\d{1,3})\.')
    if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value
    if($n -lt 1 -or $n -gt 130){ continue }
    $sk = 0
    foreach($h in 'A','B','C','D','E'){ if($p -match ('(?m)^\s*' + $h + '\)')){ $sk++ } }
    if($sk -lt 4){ continue }
    $liste.Add($n)
  }
  return $liste
}

$ars = Get-Content (Join-Path $kok 'veri\sinav-arsiv.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($ars.donemler)
$satirlar = New-Object System.Collections.Generic.List[object]
$i = 0
foreach($k in $kayitlar){
  $i++
  $sv = "$($k.sinav)"; $don = "$($k.donem)"
  $yil = ($don -split '/')[0]
  $adresVar = ("$($k.url)" -match '^https?://')
  $ad = ($sv + '-' + ($don -replace '[^0-9A-Za-z]','_') + '-' + $i)
  $pdf = Join-Path $klasor ($ad + '.pdf')
  $txt = Join-Path $klasor ($ad + '.txt')
  $indi = Test-Path $pdf
  $metinBayt = 0
  if(Test-Path $txt){ $metinBayt = (Get-Item $txt).Length }
  $soruAdet = 0
  if($metinBayt -gt 0){
    $sol = Join-Path $klasor ($ad + '.sol.txt'); $sag = Join-Path $klasor ($ad + '.sag.txt')
    if(-not (Test-Path $sol)){ try { & pdftotext -q -enc UTF-8 -marginr 300 $pdf $sol 2>&1 | Out-Null } catch {} }
    if(-not (Test-Path $sag)){ try { & pdftotext -q -enc UTF-8 -marginl 295 $pdf $sag 2>&1 | Out-Null } catch {} }
    $nolar = @{}
    foreach($t in @($sol,$sag)){
      if(-not (Test-Path $t)){ continue }
      foreach($n in (SorulariCikar (Get-Content $t -Raw -Encoding UTF8))){ $nolar[$n]=1 }
    }
    $soruAdet = $nolar.Count
  }
  $satirlar.Add([pscustomobject]@{
    sinav=$sv; yil=$yil; donem=$don; ders="$($k.ders)"
    arsivde=$(if($adresVar){'VAR'}else{'YOK'})
    indi=$(if($indi){'EVET'}else{'HAYIR'})
    metinBayt=$metinBayt
    soru=$soruAdet
  })
}

# ---- YIL YIL TABLO ----
Write-Host "`n================ CIKMIS SINAV KARNESI - YIL YIL ================"
Write-Host ("{0,-7} {1,-6} {2,8} {3,8} {4,8} {5,9} {6,10}" -f 'SINAV','YIL','KITAPCIK','ADRESLI','INDI','METIN OK','SORU')
$ozet = [ordered]@{}
foreach($sv in ($satirlar.sinav | Sort-Object -Unique)){
  foreach($yil in (@($satirlar | Where-Object { $_.sinav -eq $sv }).yil | Sort-Object -Unique)){
    $g = @($satirlar | Where-Object { $_.sinav -eq $sv -and $_.yil -eq $yil })
    $adresli = @($g | Where-Object { $_.arsivde -eq 'VAR' }).Count
    $indi    = @($g | Where-Object { $_.indi -eq 'EVET' }).Count
    $metin   = @($g | Where-Object { $_.metinBayt -gt 8000 }).Count
    $soru    = ($g | Measure-Object -Property soru -Sum).Sum
    $damga = ''
    if($indi -lt $adresli){ $damga = ('  <-- ' + ($adresli-$indi) + ' KITAPCIK INMEDI') }
    elseif($metin -lt $indi){ $damga = '  <-- METIN CIKMADI' }
    Write-Host ("{0,-7} {1,-6} {2,8} {3,8} {4,8} {5,9} {6,10}{7}" -f $sv,$yil,$g.Count,$adresli,$indi,$metin,$soru,$damga)
    $ozet[($sv + ' ' + $yil)] = [ordered]@{ kitapcik=$g.Count; adresli=$adresli; indi=$indi; metinOk=$metin; soru=$soru }
  }
}
Write-Host "`n---------------- SINAV TOPLAMI ----------------"
Write-Host ("{0,-7} {1,9} {2,9} {3,9} {4,10} {5,12}" -f 'SINAV','KITAPCIK','ADRESLI','INDI','METIN OK','AYRISAN SORU')
foreach($sv in ($satirlar.sinav | Sort-Object -Unique)){
  $g = @($satirlar | Where-Object { $_.sinav -eq $sv })
  Write-Host ("{0,-7} {1,9} {2,9} {3,9} {4,10} {5,12}" -f $sv,$g.Count,
    @($g | Where-Object { $_.arsivde -eq 'VAR' }).Count,
    @($g | Where-Object { $_.indi -eq 'EVET' }).Count,
    @($g | Where-Object { $_.metinBayt -gt 8000 }).Count,
    ($g | Measure-Object -Property soru -Sum).Sum)
}
$eksikSinav = @('SGS','SMMM','KGK') | Where-Object { $_ -notin @($satirlar.sinav | Sort-Object -Unique) }
foreach($e in $eksikSinav){ Write-Host ("`n!! {0} ARSIVDE HIC YOK - kaynak adresi bulunmali" -f $e) }

[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-soru-karnesi.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
    aciklama='Cikmis sinav kitapciklarinin YIL YIL durumu. Cem bu dosyadan denetler. Eksik satir gizlenmez.'
    yilOzeti=$ozet
    satirlar=$satirlar.ToArray()
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host "`nKanit dosyasi: veri/cikmis-soru-karnesi.json"
