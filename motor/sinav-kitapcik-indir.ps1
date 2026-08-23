# ============================================================================
#  TESMER KITAPCIK INDIRICI  - 23.08.2026
#
#  ESKI KUSUR (cikmis-soru-yut.ps1): kitapciklari $env:TEMP\cikmis-soru altina
#  indiriyordu. 08.08'de 193 kitapcik indi, TEMP silinince HEPSI GITTI -
#  23.08 olcumunde diskte yalniz 2021-2022 SMMM kaldigi gorulduc. Ayrica dosya
#  adinda sira numarasi (-$i) vardi; envanter degisince ad kayiyor, "zaten var"
#  denetimi tutmuyordu.
#
#  BU BETIK: kalici klasore, DETERMINISTIK adla indirir.
#    SGS  -> veri/sgs-arsiv/{pdf,txt}     (gitignore'da)
#    SMMM -> veri/smmm-arsiv/{pdf,txt}    (gitignore'da)
#
#  TUZAK 1: TESMER olmayan dosyada 404 degil 200 + HTML donuyor.
#           -> ilk 4 bayt '%PDF' degilse dosya SILINIR, HTML-SAHTE yazilir.
#  TUZAK 2: pdftotext stderr'e uyari basinca ErrorActionPreference='Stop'
#           altinda tum kosu oluyor -> cagri kendi kapsamina alindi.
#
#  Girdi : veri/sinav-arsiv-kesif.json (motor/sinav-arsiv-kesif.ps1 uretir)
#  Cikti : veri/sinav-indirme-raporu.json
#  BEDAVA.
# ============================================================================
param(
  [string]$Sinav = '',          # SGS | SMMM | '' (hepsi)
  [int]$IlkYil = 0,
  [int]$SonYil = 0,
  [string]$Dil = '',            # ingilizce | almanca | fransizca | '-' | '' (hepsi)
  [int]$Tavan = 0,
  [int]$Bekleme = 700
)
$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$kok = Split-Path -Parent $PSScriptRoot
$UA  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

$kesifYol = Join-Path $kok 'veri\sinav-arsiv-kesif.json'
if(-not (Test-Path $kesifYol)){ Write-Host 'HATA: veri/sinav-arsiv-kesif.json yok - once motor/sinav-arsiv-kesif.ps1 kosun'; exit 1 }
$kesif = Get-Content $kesifYol -Raw -Encoding UTF8 | ConvertFrom-Json
$hepsi = @($kesif.satirlar)

if($Sinav -ne ''){ $hepsi = @($hepsi | Where-Object { $_.sinav -eq $Sinav }) }
if($Dil   -ne ''){ $hepsi = @($hepsi | Where-Object { $_.dil   -eq $Dil   }) }
if($IlkYil -gt 0){ $hepsi = @($hepsi | Where-Object { [int](("$($_.donem)" -split '/')[0]) -ge $IlkYil }) }
if($SonYil -gt 0){ $hepsi = @($hepsi | Where-Object { [int](("$($_.donem)" -split '/')[0]) -le $SonYil }) }
if($Tavan  -gt 0){ $hepsi = @($hepsi | Select-Object -First $Tavan) }
Write-Host ("Indirilecek kitapcik: {0}" -f $hepsi.Count)
if($hepsi.Count -eq 0){ exit 0 }

$md5 = [Security.Cryptography.MD5]::Create()
$rapor = New-Object System.Collections.Generic.List[object]
$ok=0; $atla=0; $sahte=0; $hata=0; $kisa=0; $i=0

foreach($k in $hepsi){
  $i++
  $sv = "$($k.sinav)"
  $yil,$don = ("$($k.donem)" -split '/')
  if($sv -eq 'SGS'){
    $klas = Join-Path $kok 'veri\sgs-arsiv'
    $grupKisa = ("$($k.grup)" -replace '_grubu$','')          # lisans_a
    $dilEk = if("$($k.dil)" -eq '-'){ '' } else { '_' + $k.dil }
    $ad = "sgs_${yil}_${don}_${grupKisa}${dilEk}"
  } else {
    $klas = Join-Path $kok 'veri\smmm-arsiv'
    $ad = "smmm_${yil}_${don}_$($k.grup)"
  }
  New-Item -ItemType Directory -Force (Join-Path $klas 'pdf') | Out-Null
  New-Item -ItemType Directory -Force (Join-Path $klas 'txt') | Out-Null
  $pdf = Join-Path $klas ('pdf\' + $ad + '.pdf')
  $txt = Join-Path $klas ('txt\' + $ad + '.txt')

  if((Test-Path $txt) -and (Get-Item $txt).Length -gt 8000){ $atla++; continue }

  try { Invoke-WebRequest -Uri "$($k.url)" -OutFile $pdf -UserAgent $UA -TimeoutSec 120 -UseBasicParsing }
  catch { $hata++; $rapor.Add([pscustomobject]@{ ad=$ad; durum='INDIRILEMEDI'; not="$($_.Exception.Message)" }); continue }

  # TUZAK 1: gercekten PDF mi?
  $imza = [Text.Encoding]::ASCII.GetString(([IO.File]::ReadAllBytes($pdf))[0..3])
  if($imza -ne '%PDF'){
    $sahte++; Remove-Item $pdf -Force -ErrorAction SilentlyContinue
    $rapor.Add([pscustomobject]@{ ad=$ad; durum='HTML-SAHTE'; not=$k.url }); continue
  }
  $h = [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($pdf))).Replace('-','').ToLower()

  # TUZAK 2: pdftotext stderr'i kosuyu oldurmesin
  $eski = $ErrorActionPreference; $ErrorActionPreference='Continue'
  try { & pdftotext -enc UTF-8 -layout $pdf $txt 2>&1 | Out-Null } catch {}
  $ErrorActionPreference = $eski

  $boy = if(Test-Path $txt){ (Get-Item $txt).Length } else { 0 }
  if($boy -lt 8000){
    # metin katmani yok/bozuk olabilir - PDF DURUR, OCR'a aday
    $kisa++; $rapor.Add([pscustomobject]@{ ad=$ad; durum='METIN-KISA-OCR-ADAYI'; not=("$boy bayt"); md5=$h }); continue
  }
  $ok++
  $rapor.Add([pscustomobject]@{ ad=$ad; durum='OK'; not=("$boy bayt"); md5=$h })
  if($ok % 20 -eq 0){ Write-Host ("  ... {0}/{1} indi" -f $i,$hepsi.Count) }
  Start-Sleep -Milliseconds $Bekleme
}

Write-Host ("`nOK {0} | ZATEN VARDI {1} | HTML-SAHTE {2} | METIN-KISA(OCR adayi) {3} | HATA {4}" -f $ok,$atla,$sahte,$kisa,$hata)
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav-indirme-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ok=$ok; zatenVardi=$atla; htmlSahte=$sahte; metinKisa=$kisa; hata=$hata
    kayitlar=$rapor.ToArray() }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host 'Rapor: veri/sinav-indirme-raporu.json'
