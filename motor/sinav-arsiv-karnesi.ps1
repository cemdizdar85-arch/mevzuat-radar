# ============================================================================
#  CIKMIS SINAV ARSIVI KARNESI  - 23.08.2026
#
#  Eskisi (cikmis-soru-karnesi.ps1) $env:TEMP\cikmis-soru klasorunu olcuyordu;
#  TEMP silinince karne bos kaldi ve 08.08'den beri bayatti. Bu surum UC
#  KAYNAGI birden sayar ve uclusunu yan yana koyar:
#    (1) EVREN   veri/sinav-arsiv-kesif.json  - TESMER'de gercekten ne var
#    (2) DISK    veri/{sgs,smmm}-arsiv/txt, veri/kgk-arsiv/txt
#    (3) AMBAR   Supabase dokumanlar (tur='cikmis-soru' ve 'cikmis-komisyon-cevabi')
#  Boylece "indirdik ama ambara girmemis" ile "hic yok" ayirt edilebilir.
#
#  Cikti: veri/cikmis-soru-karnesi.json + ekrana tablo.  BEDAVA (yalniz okuma).
# ============================================================================
$ErrorActionPreference='Continue'
$kok = Split-Path -Parent $PSScriptRoot
# UYARI: PowerShell degisken adlarinda BUYUK-kucuk harf AYIRMAZ. Bu dosyada
# once $AMBAR (url) ve $ambar (kayit listesi) kullanildi; ikisi AYNI degiskendi
# ve liste url'i ezdi -> "Cannot convert Object[] to Uri". Sabitlere uzun ad ver.
$AMBAR_URL = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$h = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization=('Bearer '+$env:SUPABASE_SERVICE_KEY) }

# --- (1) EVREN ---
$evren = @()
$ky = Join-Path $kok 'veri\sinav-arsiv-kesif.json'
if(Test-Path $ky){ $evren = @((Get-Content $ky -Raw -Encoding UTF8 | ConvertFrom-Json).satirlar) }

# --- (2) DISK ---
function DiskSay([string]$yol, [string]$desen){
  if(-not (Test-Path $yol)){ return @() }
  @(Get-ChildItem -LiteralPath $yol -Filter $desen -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 800 })
}
$diskSGS  = DiskSay (Join-Path $kok 'veri\sgs-arsiv\txt')  'sgs_*.txt'
$diskSMMM = DiskSay (Join-Path $kok 'veri\smmm-arsiv\txt') 'smmm_*.txt'
$diskKGK  = DiskSay (Join-Path $kok 'veri\kgk-arsiv\txt')  '*.txt'

# --- (3) AMBAR ---
$ambarKayit = @()
foreach($tur in 'cikmis-soru','cikmis-komisyon-cevabi'){
  try {
    $r = Invoke-RestMethod -Uri ($AMBAR_URL + '?select=kaynak_ad,baslik,tur&tur=eq.' + $tur + '&limit=5000') -Headers $h -UserAgent 'mevzuat-radar-robot/1.0'
    $ambarKayit += @($r)
  } catch { Write-Host ("UYARI: ambar okunamadi ({0}) - {1}" -f $tur, $_.Exception.Message) }
}
function SoruSay($b){ $m=[regex]::Match("$b",'-\s*(\d+)\s*soru\s*$'); if($m.Success){ [int]$m.Groups[1].Value } else { 0 } }

# --- SINAV x YIL tablosu ---
$satir = New-Object System.Collections.Generic.List[object]
foreach($sv in 'SGS','SMMM','KGK'){
  $yillar = @()
  if($sv -eq 'KGK'){
    # KGK evreni ayri dosyada (pdf-links.tsv); yil bilgisi dosya adinda yok,
    # bu yuzden KGK icin yalniz DISK ve AMBAR sayilir - evren = disk.
    $yillar = @('(tum)')
  } else {
    $yillar = @($evren | Where-Object { $_.sinav -eq $sv } | ForEach-Object { ("$($_.donem)" -split '/')[0] } | Sort-Object -Unique)
  }
  foreach($y in $yillar){
    if($sv -eq 'KGK'){
      $e = $diskKGK.Count
      $d = $diskKGK.Count
      $a = @($ambarKayit | Where-Object { $_.tur -eq 'cikmis-soru' -and $_.kaynak_ad -notmatch '\((sgs|smmm)_' })
    } else {
      $e = @($evren | Where-Object { $_.sinav -eq $sv -and "$($_.donem)" -like "$y/*" }).Count
      $onek = $sv.ToLowerInvariant() + '_' + $y + '_'
      $d = @($(if($sv -eq 'SGS'){$diskSGS}else{$diskSMMM}) | Where-Object { $_.Name -like ($onek + '*') }).Count
      $a = @($ambarKayit | Where-Object { $_.kaynak_ad -match ('\(' + $onek) })
    }
    $satir.Add([pscustomobject]@{
      sinav=$sv; yil=$y; evren=$e; diskte=$d; ambarda=$a.Count
      soru=(@($a) | ForEach-Object { SoruSay $_.baslik } | Measure-Object -Sum).Sum
    })
  }
}

Write-Host ("{0,-6} {1,-8} {2,7} {3,8} {4,9} {5,8}" -f 'SINAV','YIL','EVREN','DISKTE','AMBARDA','SORU')
foreach($s in $satir){
  $isaret = if($s.ambarda -eq 0 -and $s.evren -gt 0){ '  <-- AMBARDA YOK' } else { '' }
  Write-Host (("{0,-6} {1,-8} {2,7} {3,8} {4,9} {5,8}" -f $s.sinav,$s.yil,$s.evren,$s.diskte,$s.ambarda,$s.soru) + $isaret)
}
$klasik = @($ambarKayit | Where-Object { $_.tur -eq 'cikmis-komisyon-cevabi' })
Write-Host ("`nKOMISYON CEVABI (klasik donem yeterlilik): ambarda {0} belge" -f $klasik.Count)
Write-Host ("TOPLAM cikmis soru (ambar): {0}" -f ((@($ambarKayit | Where-Object { $_.tur -eq 'cikmis-soru' }) | ForEach-Object { SoruSay $_.baslik } | Measure-Object -Sum).Sum))

[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-soru-karnesi.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
     tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
     aciklama='Cikmis sinav arsivi karnesi. EVREN=TESMER kesfi, DISKTE=yerel txt (>800 bayt), AMBARDA=Supabase dokumanlar. Uc sutun ayni degilse aradaki fark GERCEK ISTIR.'
     komisyonCevabiBelgesi=$klasik.Count
     satirlar=$satir.ToArray() }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host 'Kanit: veri/cikmis-soru-karnesi.json'
