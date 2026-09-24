#requires -Version 5.1
# ASCII-only (PS 5.1 BOM trap). Turkish text lives in metin.json (UTF-8).
# Instagram seviye testi videosu - SES. B1 recetesi (09.09 H7 / 13.09 B2 dersleri):
#   text-to-dialogue, eleven_v3, stability 0.3, maskot Mustafa + aday G03 AYNI istekte,
#   sonra silenceremove 0.28 + atempo 1.14.
param([int]$Alis = 1, [string]$Kasa = "", [string]$MetinDosya = 'metin.json', [string]$Etiket = 'IG')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ff = 'C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0-full_build\bin\ffmpeg.exe'
if (-not (Test-Path $ff)) { $ff = 'ffmpeg' }
$fp = if ($ff -eq 'ffmpeg') { 'ffprobe' } else { $ff -replace 'ffmpeg\.exe$','ffprobe.exe' }
# 24.09.2026 DEPOYA TASINDI (arac\video\ses-uret.ps1). Kasa varsayilani: depo ustundeki _yerel-veri-kasasi.
$kasa = if ($Kasa) { $Kasa } else { Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) '_yerel-veri-kasasi' }
if (-not (Test-Path $kasa)) { throw ("kasa yolu yok: " + $kasa) }
$anahtar = (Get-Content (Join-Path $kasa 'elevenlabs.key') -Raw).Trim()
$B = Join-Path $kasa 'instagram-seviye'
$metin = [IO.File]::ReadAllText((Join-Path $B $MetinDosya), [Text.Encoding]::UTF8) | ConvertFrom-Json

$S1 = 'fg8pljYEn5ahwjyOQaro'   # maskot - Mustafa Silici (kilitli ses kimligi)
$G03 = 'dDcfsSsiSzmphdMGCECb'  # aday - G03 Umit Dogan Energetic (kilitli)
$H = @{ 'xi-api-key' = $anahtar; 'Content-Type' = 'application/json'; 'Accept' = 'audio/mpeg' }
New-Item -ItemType Directory -Force (Join-Path $B 'diyalog') | Out-Null

$girdiler = New-Object System.Collections.ArrayList
foreach ($r in $metin.replikler) {
  if ($r.blok -ne 'diyalog') { continue }
  $vid = if ($r.kim -eq 'soru') { $S1 } else { $G03 }
  $t = if ($r.etiket) { $r.etiket + ' ' + $r.tts } else { $r.tts }
  [void]$girdiler.Add(@{ text = $t; voice_id = $vid })
}
Write-Host ("girdi sayisi=" + $girdiler.Count)

$ham = Join-Path $B ("diyalog\$Etiket-diyalog-alis" + $Alis + ".mp3")
$sik = Join-Path $B ("diyalog\$Etiket-diyalog-alis" + $Alis + "-sikisik.mp3")
if (-not (Test-Path $ham)) {
  $govde = @{ inputs = $girdiler.ToArray(); model_id = 'eleven_v3'; language_code = 'tr'; settings = @{ stability = 0.3; use_speaker_boost = $true } } | ConvertTo-Json -Depth 5
  Invoke-WebRequest -Uri 'https://api.elevenlabs.io/v1/text-to-dialogue?output_format=mp3_44100_128' -Method Post -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -OutFile $ham -UseBasicParsing | Out-Null
  Write-Host "ham indi"
} else { Write-Host "ham zaten var" }

& $ff -nostdin -y -v error -i $ham -af 'silenceremove=stop_periods=-1:stop_duration=0.28:stop_threshold=-38dB:stop_silence=0.28,atempo=1.14' -c:a libmp3lame -b:a 128k $sik
$sureHam = [double](& $fp -v error -show_entries format=duration -of default=nw=1:nk=1 $ham)
$sureSik = [double](& $fp -v error -show_entries format=duration -of default=nw=1:nk=1 $sik)
Write-Host ("ham=" + [math]::Round($sureHam,2) + " sn -> sikisik=" + [math]::Round($sureSik,2) + " sn")
Write-Host ("dosya=" + $sik)

# ---- SES ASAMASI CUMLE DENETIMI (24.09.2026 Cem: "ayni kurali ses asamasinda uygula") ----
# Klip PARALI, ses bedava: dusen cumle / kekeleme / yanlis okuma ses asamasinda yakalanirsa para harcanmaz.
# (24.09 kanit: bir kelime uc alista yanlis okundu - elle yakalandi, klip basilmadan kelime degisti.)
# KIRMIZI -> exit 2: bu ALIS Cem'e dinletilmez, yeni alis uretilir. SARI -> yakin esleme listesi Cem'in kulagina.
$denetciYolu = Join-Path $PSScriptRoot 'klip-denetim.js'
& node $denetciYolu $sik (Join-Path $B $MetinDosya)
$sesDenetimKodu = $LASTEXITCODE
$sesDenetim = switch ($sesDenetimKodu) { 0 { 'YESIL' } 1 { 'SARI' } 2 { 'KIRMIZI' } default { 'CALISMADI' } }
Write-Host ("SES DENETIMI=" + $sesDenetim)
if ($sesDenetim -eq 'KIRMIZI' -or $sesDenetim -eq 'CALISMADI') {
  Write-Host "!!! SES KIRMIZI/DENETLENEMEDI - bu alis kullanilmaz. Yeni alis: -Alis <n+1>"
  exit 2
}
