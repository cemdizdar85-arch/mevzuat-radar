# kgk-arsiv-indir.ps1 - 06.08.2026 gece
# KGK cikmis-soru arsivinin tamamini YERELE indirir ve metne cevirir.
# Girdi : veri/kgk-arsiv/pdf-links.tsv  (donemId <TAB> etiket <TAB> URL; envanter 06.08)
# Cikti : veri/kgk-arsiv/pdf/<donemId>_<dosya>.pdf + veri/kgk-arsiv/txt/<ayni>.txt
# NOT   : klasor .gitignore'da - kitapciklar TELIF uyarili, PUBLIC repoya GIRMEZ.
#         Amac konu-SIKLIK sayimi (Cem: "hangi soru cok cikiyorsa ondan cok");
#         sorular hicbir yerde yeniden yayimlanmaz.
$ErrorActionPreference = 'Continue'
$kok = Split-Path -Parent $PSScriptRoot
$ars = Join-Path $kok 'veri\kgk-arsiv'
New-Item -ItemType Directory -Force (Join-Path $ars 'pdf') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $ars 'txt') | Out-Null
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
$ok=0; $hata=0; $atlanan=0; $bosMetin=0
$satirlar = Get-Content (Join-Path $ars 'pdf-links.tsv') -Encoding UTF8 | Where-Object { $_.Trim() }
foreach($sat in $satirlar){
  $p = $sat -split "`t"
  if($p.Count -lt 3){ continue }
  $id = $p[0].Trim([char]0xFEFF).Trim(); $url = $p[2].Trim()
  if($url -notmatch '^https?://'){ $hata++; Add-Content (Join-Path $ars 'indirme-log.txt') "BOZUK-URL: $sat"; continue }
  $ad = [uri]::UnescapeDataString(($url -split '/')[-1]) -replace '[^\w\.\-]','_'
  $pdf = Join-Path $ars ("pdf\{0}_{1}" -f $id, $ad)
  if(-not ($pdf -match '\.pdf$')){ $pdf += '.pdf' }
  $txt = ($pdf -replace '\\pdf\\','\txt\') -replace '\.pdf$','.txt'
  if((Test-Path $txt) -and (Get-Item $txt).Length -gt 3000){ $atlanan++; continue }
  try {
    Invoke-WebRequest -Uri $url -OutFile $pdf -UserAgent $UA -TimeoutSec 120 -UseBasicParsing
    $imza = [IO.File]::ReadAllBytes($pdf)[0..3]
    if(-not ([Text.Encoding]::ASCII.GetString($imza) -eq '%PDF')){ $hata++; Add-Content (Join-Path $ars 'indirme-log.txt') "PDF-DEGIL: $url"; Remove-Item $pdf -Force; continue }
    & pdftotext -enc UTF-8 -layout $pdf $txt 2>$null
    if((Test-Path $txt) -and (Get-Item $txt).Length -gt 3000){ $ok++ }
    else { $bosMetin++; Add-Content (Join-Path $ars 'indirme-log.txt') "METIN-BOS (taranmis olabilir): $url" }
  } catch {
    $hata++; Add-Content (Join-Path $ars 'indirme-log.txt') "INDIRME-HATASI: $url :: $($_.Exception.Message)"
  }
  Start-Sleep -Milliseconds 400   # KGK sunucusunu bogma
}
$ozet = "OZET: metin-ok=$ok atlanan=$atlanan bos-metin=$bosMetin hata=$hata / toplam $($satirlar.Count) link"
Write-Host $ozet
Add-Content (Join-Path $ars 'indirme-log.txt') ("{0} {1}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm'), $ozet)
