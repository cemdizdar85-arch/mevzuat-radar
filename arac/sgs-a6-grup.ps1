# SGS-A6 GRUP YONETICISI (10.09.2026): bir grubun 1. dalgasini (tur 1-6) ve arkasindan 2. dalgasini (tur 7+)
# sirayla kosar. Baslamadan once bu grubun etiketlerinden herhangi biri baska surecte kosuyorsa (eski kosucunun
# bitmemis cocugu) onun bitmesini bekler - cift basim, cift bedel olmasin.
# Kullanim: powershell -NoProfile -ExecutionPolicy Bypass -File arac/sgs-a6-grup.ps1 -Grup "Ekonomi,Maliye" -ButceTavan 90
param([Parameter(Mandatory)][string]$Grup, [double]$ButceTavan = 150.0, [double]$GlobalTavan = 1200.0, [switch]$Anlik)
$ErrorActionPreference = 'Continue'
$kok = Split-Path $PSScriptRoot -Parent
Set-Location $kok
$gruplar = @($Grup -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$tum = @((ConvertFrom-Json -InputObject (Get-Content (Join-Path $kok 'veri\sinav\plan-sgs-a6.json') -Raw -Encoding UTF8)) | ForEach-Object { $_ })
$etiketler = @($tum | Where-Object { $gruplar -contains "$($_.dersAd)" } | ForEach-Object { "$($_.etiket)" })
# 10.09 TUZAK: 'return $s' tek elemanli diziyi ACAR, cagiran tarafta .Count null olur ve "kosan yok" sanilir
# (ilk kosuda dort grup da beklemeden basladi; kosucunun kendi cift-basim korumasi acigi kapatti). Cagiran @() ile sarar.
function KosanVar {
  $s = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $cl = $_.CommandLine; ($cl -match 'kalip-parti-uret') -and (@($etiketler | Where-Object { $cl -match ('-Etiket\s+' + [regex]::Escape($_) + '(\s|$)') }).Count -gt 0) })
  return , $s
}
$bekle = 0
while ($true) {
  $k = @(KosanVar | ForEach-Object { $_ })
  if (-not $k.Count) { break }
  if ($bekle -eq 0) { "[$(Get-Date -Format 'HH:mm')] bu grubun $($k.Count) etiketi baska surecte kosuyor, bitmesi bekleniyor: $((($k | ForEach-Object { if($_.CommandLine -match '-Etiket\s+(\S+)'){ $matches[1] } }) -join ', '))" }
  Start-Sleep -Seconds 60; $bekle++
  if ($bekle -gt 180) { "!! 3 saat bekledi, hala kosuyor - devam ediliyor (kosucu ayni etiketi kendisi atlar)"; break }
}
$ek = @(); if ($Anlik) { $ek += '-Anlik' }
"[$(Get-Date -Format 'HH:mm')] 1. DALGA basliyor (tur 1-6)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kok 'arac\sgs-a6-kos.ps1') -Grup $Grup -ButceTavan $ButceTavan -GlobalTavan $GlobalTavan -TurMin 1 -TurMax 6 @ek
"[$(Get-Date -Format 'HH:mm')] 2. DALGA basliyor (tur 7+)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kok 'arac\sgs-a6-kos.ps1') -Grup $Grup -ButceTavan $ButceTavan -GlobalTavan $GlobalTavan -TurMin 7 -TurMax 99 @ek
"[$(Get-Date -Format 'HH:mm')] GRUP [$Grup] TAMAM"
