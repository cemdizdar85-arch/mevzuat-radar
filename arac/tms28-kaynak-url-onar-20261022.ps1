#requires -Version 5.1
# ============================================================================
#  TMS 28 DEĞİŞİKLİKLERİ (RG 31.07.2026-33326) — kaynak_url düzeltmesi   22.10.2026 · BEDEL 0
#  NEDEN: bolum 1-3 kayıtlarının kaynak_url alanı anlamsız "https://www.mevzuat.gov.tr/mevzuatmetin/HAZIR.pdf" idi;
#    resmî kaynak RG 31.07.2026 sayı 33326 PDF'i yazılır (depo + ambar).
#  YÖNTEM: tms28-degisiklik-onar-20261022.ps1 ile aynı (ön kontrol, "zaten yazılı" atlaması, geri okuma). -Uygula yoksa KURU.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$depoDosya = Join-Path $depoKok 'veri\mevzuat\kgk-tms28-degisiklik-2026.json'
$adKok = 'TMS 28 Degisiklikleri - Istiraklerde Gercege Uygun Deger Secenegi (RG 31.07.2026-33326) bolum '
$eskiUrl = 'https://www.mevzuat.gov.tr/mevzuatmetin/HAZIR.pdf'
$yeniUrl = 'https://www.resmigazete.gov.tr/eskiler/2026/07/20260731-12.pdf'

# 1) ÖN KONTROL
$depo = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = New-Object System.Collections.Generic.List[object]
foreach ($no in 1..3) {
  $ad = "$adKok$no"
  $kayit = @($depo.belgeler | Where-Object { $_.kaynak_ad -eq $ad })
  $satir = @((Invoke-RestMethod -Uri "$tabloAdr`?select=id,kaynak_url&kaynak_ad=eq.$([uri]::EscapeDataString($ad))" -Headers $basliklarSb -TimeoutSec 120) | ForEach-Object { $_ })
  $durumDepo = $(if ($kayit.Count -ne 1) { "kayıt $($kayit.Count)" } elseif ($kayit[0].kaynak_url -ceq $yeniUrl) { 'yeni' } elseif ($kayit[0].kaynak_url -ceq $eskiUrl) { 'eski' } else { 'FARKLI' })
  $durumAmbar = $(if ($satir.Count -ne 1) { "satır $($satir.Count)" } elseif ("$($satir[0].kaynak_url)" -ceq $yeniUrl) { 'yeni' } elseif ("$($satir[0].kaynak_url)" -ceq $eskiUrl) { 'eski' } else { 'FARKLI' })
  Write-Host "  bolum $no | depo $durumDepo · ambar $durumAmbar"
  if ($durumDepo -eq 'yeni' -and $durumAmbar -eq 'yeni') { Write-Host "    zaten yazılı (depo + ambar) — atlandı"; continue }
  if ($durumDepo -notin @('eski', 'yeni') -or $durumAmbar -notin @('eski', 'yeni')) { throw "ÖN KONTROL TUTMADI: $ad — hiçbir şey yazılmadı" }
  $plan.Add([pscustomobject]@{ ad = $ad; id = "$($satir[0].id)"; ambarYaz = ($durumAmbar -eq 'eski'); depoYaz = ($durumDepo -eq 'eski') })
}
if (-not $Uygula) { "KURU: $($plan.Count) kayıt hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ + geri okuma
foreach ($p in $plan) {
  if ($p.ambarYaz) {
    $govde = ConvertTo-Json -InputObject @{ kaynak_url = $yeniUrl } -Compress
    Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
    $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=kaynak_url&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].kaynak_url)"
    if ($geri -cne $yeniUrl) { throw "GERİ OKUMA TUTMADI: $($p.ad)" }
    Write-Host "  AMBAR YAZILDI + geri okundu: $($p.ad)"
  }
  if ($p.depoYaz) { ($depo.belgeler | Where-Object { $_.kaynak_ad -eq $p.ad }).kaynak_url = $yeniUrl }
}
[IO.File]::WriteAllText($depoDosya, (ConvertTo-Json -InputObject $depo -Depth 5), (New-Object Text.UTF8Encoding $false))
$depoGeri = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($no in 1..3) { if (@($depoGeri.belgeler | Where-Object { $_.kaynak_ad -eq "$adKok$no" -and $_.kaynak_url -ceq $yeniUrl }).Count -ne 1) { throw "DEPO GERİ OKUMA TUTMADI: bolum $no" } }
"UYGULANDI: $($plan.Count) kayıt (depo + ambar), depo dosyası geri okundu"
