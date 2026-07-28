# gm-okuma-05b.ps1 - 28.07.2026
# gm-okuma-05.ps1'in TAMAMLANAMAYAN kismi: uydurma kisi isnadinin metinden cikarilmasi.
#
# NEDEN AYRI DOSYA: gm-okuma-05.ps1 BOM'suz UTF-8 olarak yazilmisti; PowerShell 5.1
# BOM'suz .ps1'i ANSI kabul edip icindeki Turkce harfleri bozuyor, bu yuzden
# -replace desenleri hicbir seye eslesmedi ve sayac 2 yazdigi halde metin degismedi.
# Bu dosya BOM ile kaydedilir. DERS: Turkce karakter iceren .ps1 daima BOM'lu olmali,
# ya da desen ASCII tutulmali.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$ist = [ordered]@{ duzeltildi = 0; kontrolTemiz = 0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"

    if($id -eq '4f1c4be1'){
      $eski = "$($s.soru)"
      $s.soru = $eski -replace 'ünlü fizyolog Prof\. Dr\. Ahmet Kaya bir röportajında', 'bu alanda çalışan bir fizyolog bir röportajında'
      if("$($s.soru)" -ne $eski){ $ist.duzeltildi++; $degisti = $true }
      $s.aciklama.C = "Doğru. İkinci cümlede yazar kendi savını desteklemek için alanın bir uzmanının sözünü aktarıyor; bu, düşünceyi geliştirme yollarından TANIK GÖSTERME'dir. Örnekleme olsaydı somut bir vaka verilirdi, karşılaştırma olsaydı iki unsur karşı karşıya konurdu."
      $degisti = $true
    }

    if($id -eq 'cce9e789'){
      $eski = "$($s.soru)"
      $s.soru = $eski -replace "Uzman barista Ahmet Kaya'nın da söylediği gibi", 'Alanında deneyimli bir baristanın da söylediği gibi'
      if("$($s.soru)" -ne $eski){ $ist.duzeltildi++; $degisti = $true }
    }
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

# --- YAZMA SONRASI DOGRULAMA (sayac degil, METIN kontrol edilir)
$kalan = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.soru)" -match 'Ahmet Kaya' -or "$($s.soru)" -match 'Prof\. Dr\.'){ $kalan++; Write-Host ("  KALDI: {0}" -f $s.id) }
  }
}
$ist.kontrolTemiz = $kalan

Write-Host "======== UYDURMA KISI ISNADI TEMIZLIGI ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $ist[$k]) }
if($kalan -gt 0){ Write-Host "KIRMIZI: hala uydurma isim var"; exit 1 }
Write-Host "  temiz."
