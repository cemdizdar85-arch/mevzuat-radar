# gm-okuma-16.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 16: karantinadaki "YANLIS ALARM" damgalilarin dil kismi —
# Yabanci Dil 23 + Genel Kultur 29 = 52 soru. Bununla YANLIS ALARM yigini BITER.
#
# SONUC: 52 SORUNUN 52'SININ DE CEVABI DOGRU.
#   YD: past simple vs present perfect · tall enough · five-year-old / two-year /
#       two-week / three-layer / three-hour (bilesik sifatta tekil) · where (yer) ·
#       lend vs borrow · unless · must be sent/paid (edilgen) · third conditional ·
#       was + -ing (kesintiye ugrayan eylem) · well-known · sifat sirasi
#       (important long / detailed financial) · state-of-the-art
#   GK: gereksiz sozcuk (ortaklasa birlikte / hem-hem de aynı zamanda) · ortak
#       nesne hali hatasi ("ekibi tesekkur etti") · virgul · kesme isareti
#       (TBMM'nin, Kayalar'a, Anadolu Universitesi'nden, Sevr Antlasmasi'nin) ·
#       buyuk harf (Basbakan, teyzem, Sevr antlasmasi) · kisa cizgi (3-5, koş-uyor,
#       1934-1940) · sestes "yuz" (sayi) vs "yuz" (surat) · durum zarfi ·
#       mecaz "tatli" · sayilarin ayri yazimi (iki bin yirmi dort)
#
# 🔴 TEKDUZELIK — bu partide en keskin haliyle gorundu:
#   "yuz" sestesligi        : 5 soru (19490149, d1eccc30, 28160830, 6144bde2, e3ace047)
#   zarf/sifat ayrimi       : 5 soru (5e8cb4be, 6cb0a752, 67c07a38, 8d9e1baa, f9d825f7)
#   kesme isareti           : 4 soru
#   kisa cizgi / buyuk harf / virgul / gereksiz sozcuk : 3'er soru
#   YD tarafinda 6 CIFT ikiz: lend/borrow · unless · must be sent/paid ·
#     well-known · was delivering/carrying · third conditional
#   Yani 52 sorunun buyuk kismi ~12 ayri kurali olcuyor. Ogrenci icin deger
#   soru sayisinda degil KURAL sayisinda. Silinmedi (parasi odendi), etiketlendi.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{}
foreach($id in @('19490149','d1eccc30','28160830','6144bde2','e3ace047')){ $GRUP[$id]='gk-sestes-yuz' }
foreach($id in @('5e8cb4be','6cb0a752','67c07a38','8d9e1baa','f9d825f7')){ $GRUP[$id]='gk-zarf-sifat-ayrimi' }
foreach($id in @('6dc1c183','bee10564','dc8ac76a','6bd62f52')){ $GRUP[$id]='gk-kesme-isareti' }
foreach($id in @('f716ab41','e7ac546a','7602eeac')){ $GRUP[$id]='gk-kisa-cizgi' }
foreach($id in @('a19001b5','2bb23962','6228b81e')){ $GRUP[$id]='gk-buyuk-harf' }
foreach($id in @('9746b8f4','95964893','511358d1')){ $GRUP[$id]='gk-virgul' }
foreach($id in @('8fe87729','8dc67445','97160263')){ $GRUP[$id]='gk-gereksiz-sozcuk' }
foreach($id in @('ea0e72f4','9cd0624b')){ $GRUP[$id]='gk-mecaz-tatli' }
foreach($id in @('8d77b3f6','d0dd6735')){ $GRUP[$id]='yd-lend-borrow' }
foreach($id in @('3ed39549','0021f87f')){ $GRUP[$id]='yd-unless' }
foreach($id in @('42e84923','809cdbf5')){ $GRUP[$id]='yd-passive-must' }
foreach($id in @('781002d7','431736d0')){ $GRUP[$id]='yd-well-known' }
foreach($id in @('af48374e','4a287a0c')){ $GRUP[$id]='yd-past-continuous' }
foreach($id in @('216b456c','467cab6d')){ $GRUP[$id]='yd-third-conditional' }
foreach($id in @('086be991','ea063d0a','40a147aa','607e9bf4','409263ba')){ $GRUP[$id]='yd-bilesik-sifat-tekil' }
foreach($id in @('87f6762e','27424c06')){ $GRUP[$id]='yd-sifat-sirasi' }

$DIL = @('Yabanci Dil','Genel Kultur-Genel Yetenek')
$ist = [ordered]@{ onay=0; grupEtiketlendi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'karantina'){ continue }
    if("$($s.onarim)" -notmatch 'YANLIS ALARM'){ continue }
    if($DIL -notcontains "$($s.ders)"){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): karantinaya bozuk detektör yüzünden düşmüştü; dil kuralı tek tek doğrulandı, cevap teyit edildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 16 (karantina / yanlış alarm — dil) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

# --- YANLIS ALARM yigini tamamen bitti mi?
Write-Host ""
$kalan = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.durum)" -eq 'karantina' -and "$($s.onarim)" -match 'YANLIS ALARM'){ $kalan++ }
  }
}
Write-Host ("  karantinada kalan YANLIS ALARM: {0}" -f $kalan)
if($kalan -eq 0){ Write-Host "  ✅ yanlış alarm yığını tamamen boşaldı" }
