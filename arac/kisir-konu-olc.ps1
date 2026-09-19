#requires -Version 5.1
<#
================================================================================
  KISIR KONU ÖLÇÜMÜ — "parayı yiyip soru vermeyen konu" listesi   18.09.2026
  Bedel 0 (yalnız yerel parti dosyaları + ret kütüğü okunur).

  NİYE VAR (Cem 17.09, para harcayan soru basımı kuralı md. 5: "ilgi hakeminden
  geçmemiş konu basılmaz"): kural YAZILIYDI, mekanik karşılığı YOKTU. 18.09'da
  ölçüldü — bitirmede 3.176 üretilen taslağın 1.929'u yayına girdi (%60,7), ama
  32 konuda en az 3 soru denendi ve HİÇBİRİ yayına girmedi (180 taslak,
  üretilenin %5,7; üretilen soru başı 0,077 USD ile ≈14 USD). Bu konular her
  turda yeniden plana giriyor ve aynı parayı yeniden yakıyor.

  ⚠ NE DEĞİL: bu bir kalite kısıtı değil. Listeye giren konudan bugüne kadar
  TEK soru çıkmadı; yani kapı yayına giren hiçbir soruyu düşürmez. Konunun
  kaynağı ambara yutulduğunda liste yeniden ölçülür ve konu kendiliğinden
  geri döner (dosya türetilmiştir, elle düzenlenmez).

  ⚠ ÖLÇÜM SMMM'YE ÖZEL: geçme ölçütü arac/smmm-yayin-sarti.ps1. SGS/KGK için
  kendi yayın şartlarıyla ayrı ölçüm gerekir; dosya yoksa kapı çalışmaz.

  KULLANIM
    powershell -NoProfile -File arac/kisir-konu-olc.ps1            # ölç + yaz
    powershell -NoProfile -File arac/kisir-konu-olc.ps1 -EnAzDeneme 5
================================================================================
#>
param(
  [int]$EnAzDeneme = 3,          # bu kadar soru denenmiş olmalı (altı "ölçülmedi")
  [string]$Sinav = 'SMMM'
)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
if ($Sinav -ne 'SMMM') { throw "Bu ölçüm bugün yalnız SMMM için var (yayın şartı SMMM'ye özel). İstenen: $Sinav" }
. (Join-Path $depoKok 'arac\smmm-yayin-sarti.ps1')

$durum = @{}
$dosyaSay = 0
foreach ($f in (Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json' -ErrorAction SilentlyContinue)) {
  $dosyaSay++
  $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($p in $j.PSObject.Properties) {
    $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $k = "$($v.konu)".Trim().ToLowerInvariant(); if (-not $k) { continue }
    if (-not $durum.ContainsKey($k)) { $durum[$k] = [pscustomobject]@{ konu = $k; denenen = 0; gecen = 0; ke = 0 } }
    $durum[$k].denenen++
    if ((SmmmYayinSarti "$($f.Name)/$($p.Name)" $v @{}).gecer) { $durum[$k].gecen++ }
  }
}
if ($dosyaSay -lt 50) { throw "parti dosyası az ($dosyaSay) — ambardan indirilmemiş olabilir; ölçüm yazılmadı (arac/parti-senkron.ps1 -Indir -Yaz -Sinav SMMM -OnEk 'smmm-')" }

$retYol = Join-Path $depoKok 'veri\ret-kutugu.json'
if (Test-Path $retYol) {
  foreach ($kay in @((Get-Content $retYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar | ForEach-Object { $_ })) {
    if ("$($kay.etiket)" -notlike 'smmm-*' -or "$($kay.sinif)" -ne 'KAYNAK-EKSIK') { continue }
    $k = "$($kay.konu)".Trim().ToLowerInvariant()
    if ($k -and $durum.ContainsKey($k)) { $durum[$k].ke++ }
  }
}

$hepsi = @($durum.Values)
$toplamD = ($hepsi | Measure-Object denenen -Sum).Sum
$toplamG = ($hepsi | Measure-Object gecen -Sum).Sum
$kisir = @($hepsi | Where-Object { $_.denenen -ge $EnAzDeneme -and $_.gecen -eq 0 } | Sort-Object denenen -Descending)
$kisirD = ($kisir | Measure-Object denenen -Sum).Sum

Write-Host ("konu {0:N0} · denenen taslak {1:N0} · yayına giren {2:N0} (%{3})" -f $hepsi.Count, $toplamD, $toplamG, [math]::Round(100 * $toplamG / [double][math]::Max(1, $toplamD), 1)) -ForegroundColor Cyan
Write-Host ("KISIR konu {0} · boşa giden taslak {1} (üretilenin %{2}) · KAYNAK-EKSIK reti {3}" -f `
    $kisir.Count, $kisirD, [math]::Round(100 * $kisirD / [double][math]::Max(1, $toplamD), 1), ($kisir | Measure-Object ke -Sum).Sum) -ForegroundColor Yellow
foreach ($x in ($kisir | Select-Object -First 12)) { Write-Host ("  {0,-46} denendi {1,3} · KAYNAK-EKSIK {2,2}" -f $x.konu.Substring(0, [math]::Min(46, $x.konu.Length)), $x.denenen, $x.ke) }
if ($kisir.Count -gt 12) { Write-Host ("  ... ve {0} konu daha" -f ($kisir.Count - 12)) }

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\sinav\kisir-konu-smmm.json') -Nesne ([ordered]@{
    olcum       = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    aciklama    = "En az $EnAzDeneme soru denenmiş, HİÇBİRİ yayın şartını geçmemiş konular. motor/plandan-parti-kur.ps1 bu konuları plana almaz. Türetilmiştir - elle düzenlenmez; kaynağı yutulan konu yeniden ölçümde listeden düşer."
    kural       = "denenen >= $EnAzDeneme ve yayına giren = 0"
    olculen     = [ordered]@{ konu = $hepsi.Count; denenen = $toplamD; gecen = $toplamG; partiDosyasi = $dosyaSay }
    kisirKonu   = $kisir.Count
    kisirTaslak = $kisirD
    konular     = @($kisir | ForEach-Object { [ordered]@{ konu = $_.konu; denenen = $_.denenen; kaynakEksik = $_.ke } })
  })
Write-Host "yazildi: veri/sinav/kisir-konu-smmm.json" -ForegroundColor Green
