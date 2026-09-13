# ============================================================================
#  ANALIZ KUYRUGUNA AL - 13.09.2026   (BEDAVA; parayi harcayan emir dosyasidir)
#
#  NEDEN: veri/sinav-arsiv.json'daki 'kesif' satirlari analiz robotuna girmez
#  (motor/sinav-analiz.ps1 yalniz durum='bekliyor' isler). SMMM 2008-2020
#  kesif satirlarinda 'format' alani da YOK; robot alan yoksa 'test' istemini
#  kullanir -> klasik kitapcikta "coktan secmeli soru bul" der, okuma parasi
#  yanar ve soru sayisi kapisinda RED olur. Bu arac satiri kuyruga alirken
#  format='yazili' yazar (2008-2025 SMMM klasik; 2026+ test).
#
#  Bicim korunur: JSON yeniden serilestirilmez, yalniz ilgili satirin
#  "url" + "durum" cifti degistirilir (robot sonra kendi yazar).
#  -Anahtar "2013/2|01" gibi (donem|ders kodu) liste; -Tumu tum SMMM kesif.
#  -Uygula yoksa KURU.
# ============================================================================
param([string[]]$Anahtar = @(), [switch]$Tumu, [switch]$Uygula)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$arsivYolu = Join-Path $depoKok 'veri\sinav-arsiv.json'
$arsivNesne = [IO.File]::ReadAllText($arsivYolu, [Text.Encoding]::UTF8) | ConvertFrom-Json
$arsivMetin = [IO.File]::ReadAllText($arsivYolu, [Text.Encoding]::UTF8)

$secilen = New-Object System.Collections.Generic.List[object]
foreach($r in @($arsivNesne.donemler)){
  if("$($r.sinav)" -ne 'SMMM' -or "$($r.durum)" -ne 'kesif'){ continue }
  $kod = [regex]::Match("$($r.url)", '_(\d{2})\.pdf$').Groups[1].Value
  $anh = "$($r.donem)|$kod"
  if($Tumu -or ($Anahtar -contains $anh)){ $secilen.Add([pscustomobject]@{ anahtar = $anh; ders = "$($r.ders)"; adres = "$($r.url)"; yil = [int](("$($r.donem)" -split '/')[0]) }) }
}
if(-not $Tumu){
  $bulunan = @($secilen | ForEach-Object { $_.anahtar })
  foreach($x in $Anahtar){ if($bulunan -notcontains $x){ Write-Host "UYARI: '$x' kesif durumunda SMMM satiri degil - atlandi" } }
}
Write-Host ("Kuyruga alinacak: {0}" -f $secilen.Count)
$degisen = 0
foreach($s in $secilen){
  $bicimAdi = if($s.yil -ge 2026){ 'test' } else { 'yazili' }
  $desen = '("url"\s*:\s*"' + [regex]::Escape($s.adres) + '",)(\s*)"durum"\s*:\s*"kesif"'
  $esles = [regex]::Matches($arsivMetin, $desen).Count
  if($esles -ne 1){ Write-Host ("  ATLA {0}: {1} eslesme" -f $s.anahtar, $esles); continue }
  $arsivMetin = [regex]::Replace($arsivMetin, $desen, ('$1$2"format": "' + $bicimAdi + '",$2"durum": "bekliyor"'))
  $degisen++
  Write-Host ("  {0} {1} -> bekliyor ({2})" -f $s.anahtar, $s.ders, $bicimAdi)
}
if(-not $Uygula){ Write-Host "KURU KOSU - yazilmadi ($degisen satir degisecekti). Yazmak icin -Uygula."; exit 0 }
[IO.File]::WriteAllText($arsivYolu, $arsivMetin, (New-Object Text.UTF8Encoding($true)))
$kontrol = [IO.File]::ReadAllText($arsivYolu, [Text.Encoding]::UTF8) | ConvertFrom-Json
$bekleyen = @($kontrol.donemler | Where-Object { $_.sinav -eq 'SMMM' -and $_.durum -eq 'bekliyor' }).Count
Write-Host ("yazildi: {0} satir. JSON gecerli, SMMM bekliyor = {1}" -f $degisen, $bekleyen)
