# ============================================================================
#  TARANMIS KITAPCIK OCR -> AMBAR   13.09.2026 (BEDAVA: yerel tesseract + Supabase)
#
#  NEDEN (Cem 13.09 "1.2.3"): 13 SMMM kitapcigi taranmis PDF - metin katmani yok,
#  ambardaki metinleri 360-2.000 karakter (bulutta "var ama bos"). Analiz robotu
#  (motor/sinav-analiz.ps1) pdftotext bos donunce metni AMBARDAN okur; bu arac
#  ambara OCR metnini yazar.
#  OCR: motor/pdf-ocr.ps1 -TekSutun (varsayilan iki sutun kirpmasi satirlarin sag
#  yarisini kesiyordu - 13.09 olculdu). Cikti veri/smmm-arsiv/pdf/<ad>.ocr.txt.
#
#  KURAL: ambar satiri yalniz OCR bosluksuz metni eskinin >= 1,5 kati ise degisir.
#  Eski metin once _yerel-veri-kasasi/ocr-yedek/ altina yedeklenir (telif: repoya
#  girmez). Yazdiktan sonra GERI OKUNUR ve karakter sayisi karsilastirilir.
#  -Uygula yoksa KURU. Rapor (yalniz sayilar): veri/taranmis-ocr-rapor.json
# ============================================================================
param([string[]]$Kitapcik = @(), [switch]$Uygula)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$anahtarSb = $env:SUPABASE_SERVICE_KEY
if(-not $anahtarSb){ $anahtarSb = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $anahtarSb){ throw 'SUPABASE_SERVICE_KEY yok' }
$basliklar = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\ocr-yedek'
if($Uygula){ New-Item -ItemType Directory -Force $yedekKlasor | Out-Null }
if($Kitapcik.Count -eq 0){ $Kitapcik = @(Get-ChildItem (Join-Path $depoKok 'veri\smmm-arsiv\pdf') -Filter 'smmm_*.ocr.txt' | ForEach-Object { $_.Name -replace '\.ocr\.txt$','' }) }

Add-Type -AssemblyName System.Net.Http
$istemci = New-Object System.Net.Http.HttpClient
$istemci.Timeout = [TimeSpan]::FromSeconds(180)
foreach($k in $basliklar.Keys){ $istemci.DefaultRequestHeaders.TryAddWithoutValidation($k, $basliklar[$k]) | Out-Null }

$satirlar = New-Object System.Collections.Generic.List[object]
foreach($ad in $Kitapcik){
  $ocrYol = Join-Path $depoKok "veri\smmm-arsiv\pdf\$ad.ocr.txt"
  if(-not (Test-Path $ocrYol)){ $satirlar.Add([ordered]@{ kitapcik = $ad; karar = 'OCR-YOK' }); continue }
  $ocrMetin = [IO.File]::ReadAllText($ocrYol, [Text.Encoding]::UTF8)
  $ocrMetin = ($ocrMetin -replace "`f", "`n") -replace '[ \t]{3,}', '  '
  $yanit = Invoke-WebRequest -UseBasicParsing -Uri "$tabloAdr`?select=id,kaynak_ad,metin&kaynak_ad=ilike.*$ad*&tur=eq.cikmis-komisyon-cevabi" -Headers $basliklar -TimeoutSec 120
  $bulunan = @(ConvertFrom-Json -InputObject $yanit.Content)
  if($bulunan.Count -ne 1){ $satirlar.Add([ordered]@{ kitapcik = $ad; karar = "AMBAR-SATIRI-$($bulunan.Count)" }); continue }
  $eskiMetin = "$($bulunan[0].metin)"
  $eskiBoy = ($eskiMetin -replace '\s','').Length
  $yeniBoy = ($ocrMetin -replace '\s','').Length
  $karar = if($yeniBoy -ge 1.5 * $eskiBoy){ 'YAZILACAK' } else { 'ATLA-OCR-YETERSIZ' }
  $satir = [ordered]@{ kitapcik = $ad; ambar_id = "$($bulunan[0].id)"; eski_kr = $eskiBoy; ocr_kr = $yeniBoy; karar = $karar }
  if($Uygula -and $karar -eq 'YAZILACAK'){
    [IO.File]::WriteAllText((Join-Path $yedekKlasor "$ad.ambar-eski.txt"), $eskiMetin, (New-Object Text.UTF8Encoding($false)))
    $govdeJson = ConvertTo-Json -InputObject ([ordered]@{ metin = $ocrMetin }) -Compress
    $istek = New-Object System.Net.Http.HttpRequestMessage ((New-Object System.Net.Http.HttpMethod 'PATCH'), "$tabloAdr`?id=eq.$($bulunan[0].id)")
    $istek.Content = New-Object System.Net.Http.StringContent ($govdeJson, [Text.Encoding]::UTF8, 'application/json')
    $istek.Headers.Add('Prefer', 'return=minimal')
    $cevap = $istemci.SendAsync($istek).GetAwaiter().GetResult()
    $kod = [int]$cevap.StatusCode
    $cevap.Dispose(); $istek.Dispose()
    $geri = @(ConvertFrom-Json -InputObject (Invoke-WebRequest -UseBasicParsing -Uri "$tabloAdr`?select=metin&id=eq.$($bulunan[0].id)" -Headers $basliklar -TimeoutSec 120).Content)
    $geriBoy = ("$($geri[0].metin)" -replace '\s','').Length
    $satir.http = $kod; $satir.geri_okunan_kr = $geriBoy
    $satir.karar = if(($kod -eq 204 -or $kod -eq 200) -and $geriBoy -eq $yeniBoy){ 'YAZILDI-DOGRULANDI' } else { 'YAZMA-HATASI' }
  }
  $satirlar.Add($satir)
  Write-Host ("  {0}: eski {1} kr -> ocr {2} kr : {3}" -f $ad, $eskiBoy, $yeniBoy, $satir.karar)
}
if(-not $Uygula){ Write-Host 'KURU KOSU - ambara yazilmadi. Yazmak icin -Uygula.'; exit 0 }
$null = RaporYaz -Hedef (Join-Path $depoKok 'veri\taranmis-ocr-rapor.json') -Nesne ([ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  aciklama = 'Taranmis SMMM kitapciklarinin OCR metni ambara (dokumanlar.metin) yazildi. Yalniz sayilar; metin telif nedeniyle repoda yok, eski metin yedegi _yerel-veri-kasasi/ocr-yedek.'
  kitapciklar = $satirlar.ToArray() }) -Derinlik 4
