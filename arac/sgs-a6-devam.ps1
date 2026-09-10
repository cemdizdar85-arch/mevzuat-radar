# SGS-A6 DEVAM (10.09.2026 06:50): API kredisi bitince (400 "credit balance is too low") butun kosular durduruldu.
# Kredi yuklenince bu betik TEK KOMUTLA her seyi kaldigi yerden baslatir:
#   - 4 fabrika grup yoneticisi (bitmis etiketleri atlar, ayni etiket iki kez kosmaz)
#   - Meslek 3 seviye (sgs-a6e-meslek-*)
# Kullanim: powershell -NoProfile -ExecutionPolicy Bypass -File arac/sgs-a6-devam.ps1
# Once kredi testi yapar: 1 kucuk cagri (Haiku, 16 jeton) basarisizsa HICBIR SEY baslatmaz.
$ErrorActionPreference = 'Continue'
$kok = Split-Path $PSScriptRoot -Parent
Set-Location $kok
$AK = "$env:ANTHROPIC_API_KEY".Trim(); if (-not $AK) { $AK = "$([Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User'))".Trim() }
$HDR = @{ 'x-api-key' = $AK; 'anthropic-version' = '2023-06-01' }
$govde = @{ model = 'claude-haiku-4-5-20251001'; max_tokens = 8; messages = @(@{ role = 'user'; content = 'OK' }) } | ConvertTo-Json -Depth 6
try {
  $null = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $HDR -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 60
  "KREDI TESTI: OK - baslatiliyor"
} catch {
  $b = ''; try { $b = $_.ErrorDetails.Message } catch {}
  "KREDI TESTI BASARISIZ: $($_.Exception.Message) :: $b"; "Hicbir sey baslatilmadi. Once Plans & Billing'den kredi yukle."; exit 1
}
# calisan varsa yeniden baslatma
if (@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'sgs-a6-grup\.ps1' -and $_.CommandLine -notmatch '-Command' }).Count) { "grup yoneticileri zaten calisiyor, cikiliyor"; exit 0 }
$gruplar = @(
  @{ g = 'Finansal Muhasebe,Muhasebe'; t = 420; ad = 'muhasebe-A' },
  @{ g = 'Maliyet Muhasebesi,Mali Tablolar Analizi,Denetim'; t = 230; ad = 'muhasebe-B' },
  @{ g = 'Hukuk,Meslek Hukuku,Is ve Sosyal Guvenlik Hukuku,Ticaret Hukuku,Borclar Hukuku,Vergi Hukuku'; t = 330; ad = 'hukuk' },
  @{ g = 'Ekonomi,Maliye'; t = 90; ad = 'ekonomi-maliye' }
)
foreach ($x in $gruplar) {
  $log = Join-Path $kok ("veri\fabrika\kosucu-log\a6-GRUP-{0}.log" -f $x.ad)
  Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $kok 'arac\sgs-a6-grup.ps1'), '-Grup', ('"' + $x.g + '"'), '-ButceTavan', "$($x.t)", '-GlobalTavan', '1200') -RedirectStandardOutput $log -RedirectStandardError ($log -replace '\.log$', '.err.log') -WindowStyle Hidden
  "baslatildi: grup $($x.ad) (tavan $($x.t))"
}
# Meslek 3 seviye (GM yazimi, hazir dosyadan; bitmis olan uretici tarafindan atlanir)
$meslek = @(@{ s = 'kolay'; a = 17 }, @{ s = 'zor'; a = 22 }, @{ s = 'cokzor'; a = 21 })
foreach ($m in $meslek) {
  $et = "sgs-a6e-meslek-$($m.s)"
  if (Test-Path (Join-Path $kok ("veri\fabrika\kalip-parti-{0}.html" -f $et))) { "atlandi (bitmis): $et"; continue }
  $arg = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $kok 'motor\kalip-parti-uret.ps1'), '-Sinav', 'SGS', '-DersRegex', '"Meslek Hukuku"', '-Adet', "$($m.a)", '-Etiket', $et, '-UzunlukTavan', '300', '-Verilenler', '-KonuGiris', '-Simulasyon', '-SimModel', 'claude-sonnet-5', '-DonemPencere', '7', '-Zorluk', $m.s, '-KonuDosya', "veri/sinav/konu/sgs-t2b-meslek-$($m.s).json", '-HazirSoru', "veri/fabrika/hazir-sgs-t2b-meslek-$($m.s).json", '-Toplu')
  $env:MEVZUAT_TOPLU = '1'; $env:MEVZUAT_TOPLU_BEKLE_DK = '20'; $env:MEVZUAT_TOPLU_PARCA = '30'; $env:MEVZUAT_CLAIM = '0'
  $log = Join-Path $kok ("veri\fabrika\kosucu-log\a6e-meslek-{0}.log" -f $m.s)
  Start-Process -FilePath 'powershell.exe' -ArgumentList $arg -RedirectStandardOutput $log -RedirectStandardError ($log -replace '\.log$', '.err.log') -WindowStyle Hidden
  "baslatildi: $et"
}
"TAMAM - loglar veri/fabrika/kosucu-log/a6-GRUP-*.log ve a6e-meslek-*.log"
