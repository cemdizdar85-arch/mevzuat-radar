#requires -Version 5.1
# ============================================================================
#  BULUTTA ŞU AN KOŞAN PARTİLER (16.09.2026, Cem "1.2.3 üçünü de yap")
#
#  NEDEN: bulut-uretim.yml bir partiyi iş başında ambardan indirir, iş sonunda TAMAMINI geri yükler. Arada başka bir araç
#  (kaynak bağı taşıma, paket tazeleme, elle düzeltme) aynı partiyi ambara yazarsa ya o yazım ezilir ya da okuma-yazma
#  yarışında bulutun sonucu kaybolur. 16.09'da TFRS 18 bağ taşıması 17 SGS partisinin 13'ü koşarken bu yüzden ertelendi.
#
#  NE YAPAR: koşan / sırada bekleyen bulut-uretim işlerinin planlarını koşu adından okur ("Bulut Uretim | <plan> | halka n"),
#  plan dosyalarındaki etiketleri döndürür. Koşu adı plan taşımayan (16.09 öncesi başlatılmış) iş varsa ADINI UYARIR —
#  o işin partileri bilinemez, -Kati verilirse araç hata verir (yazan araç durmalı).
#  0 USD. gh girişi gerekir.
#
#  Kullanım (başka betikten):
#     $kosan = & (Join-Path $depoKok 'arac\bulut-kosan-etiketler.ps1') -Kati
#     if($kosan -contains $etiket){ "atlandı: bulutta koşuyor" ; continue }
# ============================================================================
param([switch]$Kati)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$ham = (gh run list --repo cemdizdar85-arch/mevzuat-radar --workflow=bulut-uretim.yml --limit 60 --json databaseId,status,displayTitle) -join ''
$kosular = @(foreach ($grup in (ConvertFrom-Json $ham)) { foreach ($k in $grup) { if ($k.status -in 'in_progress', 'queued', 'waiting', 'pending', 'requested') { $k } } })
$etiketler = New-Object System.Collections.Generic.HashSet[string]
$bilinmeyen = @()
foreach ($k in $kosular) {
  $m = [regex]::Match("$($k.displayTitle)", 'Bulut Uretim \| (\S+) \| halka')
  if (-not $m.Success) { $bilinmeyen += "$($k.databaseId)"; continue }
  $planYolu = Join-Path $depoKok ($m.Groups[1].Value -replace '/', '\')
  if (-not (Test-Path $planYolu)) { $bilinmeyen += "$($k.databaseId) (plan yerelde yok: $($m.Groups[1].Value))"; continue }
  foreach ($satir in @((Get-Content $planYolu -Raw -Encoding UTF8 | ConvertFrom-Json))) { foreach ($s in $satir) { if ("$($s.etiket)") { [void]$etiketler.Add("$($s.etiket)") } } }
}
if ($bilinmeyen.Count) {
  $mesaj = "Planı okunamayan koşan bulut işi: $($bilinmeyen -join ', ') — bu işlerin partileri bilinmiyor."
  if ($Kati) { throw "$mesaj Ambara parti yazan iş bu işler bitene kadar beklemeli." }
  Write-Warning $mesaj
}
@($etiketler)
