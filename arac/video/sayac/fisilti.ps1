#requires -Version 5.1
# ASCII-only (PS 5.1 BOM trap). Turkish text lives in fisilti.json (UTF-8).
# Sayac reklami fisiltisi - 29.09.2026 Cem "videoyu bu metinle kurgula".
# Ses kimligi KILITLI: maskot Mustafa Silici (ses-uret.ps1 ile ayni voice_id), eleven_v3 [whispers].
# Bedel: ElevenLabs aboneligi (ek para yok). Her alis ses denetiminden gecer; KIRMIZI -> exit 2.
param([int]$Alis = 1, [string]$Kasa = "")
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kasa = if ($Kasa) { $Kasa } else { Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) '_yerel-veri-kasasi' }
if (-not (Test-Path $kasa)) { throw ("kasa yolu yok: " + $kasa) }
$anahtar = (Get-Content (Join-Path $kasa 'elevenlabs.key') -Raw).Trim()
$cikti = Join-Path $kasa 'sayac-reklami'
New-Item -ItemType Directory -Force $cikti | Out-Null
$jsonYol = Join-Path $PSScriptRoot 'fisilti.json'
$j = [IO.File]::ReadAllText($jsonYol, [Text.Encoding]::UTF8) | ConvertFrom-Json
$metin = $j.etiket + ' ' + $j.beklenen_replikler[0]

$S1 = 'fg8pljYEn5ahwjyOQaro'   # maskot - Mustafa Silici (kilitli ses kimligi)
$H = @{ 'xi-api-key' = $anahtar; 'Content-Type' = 'application/json'; 'Accept' = 'audio/mpeg' }
$mp3 = Join-Path $cikti ("fisilti-alis" + $Alis + ".mp3")
if (-not (Test-Path $mp3)) {
  $govde = @{ text = $metin; model_id = 'eleven_v3'; language_code = 'tr'; settings = @{ stability = 0.5; use_speaker_boost = $true } } | ConvertTo-Json -Depth 4
  Invoke-WebRequest -Uri ("https://api.elevenlabs.io/v1/text-to-speech/" + $S1 + "?output_format=mp3_44100_128") -Method Post -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -OutFile $mp3 -UseBasicParsing | Out-Null
  Write-Host ("indi: " + $mp3)
} else { Write-Host ("zaten var: " + $mp3) }

& node (Join-Path (Split-Path -Parent $PSScriptRoot) 'klip-denetim.js') $mp3 $jsonYol
$kod = $LASTEXITCODE
$durum = switch ($kod) { 0 { 'YESIL' } 1 { 'SARI' } 2 { 'KIRMIZI' } default { 'CALISMADI' } }
Write-Host ("SES DENETIMI=" + $durum)
if ($durum -eq 'KIRMIZI' -or $durum -eq 'CALISMADI') { Write-Host "!!! bu alis kullanilmaz. Yeni alis: -Alis <n+1>"; exit 2 }
