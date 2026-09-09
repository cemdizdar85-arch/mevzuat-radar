# VİTRİN BASIMI (09.09.2026) — ana sayfadaki Nöbetçi kartı için tek sayfa: kaydir/vitrin/<sinav>.html
# 1) motor/vitrin-soru-sec.js ölçütle seçer (veri/sinav/kaydir-secim/vitrin-<sinav>-secim.json)
# 2) motor/kaydir-coz.ps1 o seçimi Kaydır-Çöz sayfası olarak basar (açık tema; ?vitrin=1 ile gömülür)
# Kullanım: powershell -NoProfile -File motor/vitrin-bas.ps1 -Sinav sgs [-Adet 10]
# Not: kaydir-coz.ps1 önbelleği (veri/fabrika/, git dışı) bu makinede olmalı; Actions'ta koşmaz.
param([string]$Sinav='sgs',[int]$Adet=10)
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
& node (Join-Path $PSScriptRoot 'vitrin-soru-sec.js') $Sinav $Adet
if($LASTEXITCODE -ne 0){ throw "seçim düştü ($LASTEXITCODE)" }
New-Item -ItemType Directory -Force (Join-Path $kok 'kaydir\vitrin') | Out-Null
$cikti="..\kaydir\vitrin\$Sinav.html"
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'kaydir-coz.ps1') -SecimDosya "vitrin-$Sinav-secim.json" -Cikti $cikti *>&1 |
  Where-Object { "$_" -match 'secim dosyasi|yazildi|YOK:|Exception|Cannot' } | ForEach-Object { "  $_" }
$y=Join-Path $kok "kaydir\vitrin\$Sinav.html"
if(-not (Test-Path $y)){ throw "vitrin sayfası yazılmadı: $y" }
"vitrin: $y ($([math]::Round((Get-Item $y).Length/1KB)) KB)"
