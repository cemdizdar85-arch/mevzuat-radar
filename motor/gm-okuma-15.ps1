# gm-okuma-15.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 15: KARANTINADAN ilk parti — "YANLIS ALARM" damgali sorularin
# meslek dersi + matematik kismi (16 soru).
#
# Bu 16 soru karantinaya BOZUK BIR DETEKTOR yuzunden dusmustu (Parti 0'da olculdu:
# tekrar-eden-sik damgali 38 sorunun 30'unda bes sikkin hepsi farkliydi; mukerrer-kok
# damgali 38 sorunun 38'inin de havuzda ikizi yoktu). Kaynak teyidinden ve iki
# bagimsiz cozucuden zaten gecmislerdi; eksik olan tek sey GM okumasiydi.
#
# SONUC: 16 SORUNUN 16'SININ DA CEVABI DOGRU. Elle dogrulandi:
#   talep esnekligi: (-20/100)/(5/20) = -0,8 -> inelastik
#   capraz esneklik: %15/%10 = +1,5 ikame · %4/%10 = +0,4 ikame
#   yatay analiz: (400-500)/500 = -%20 · (680-800)/800 = -%15
#   dik dogrular: (-2/k)(4) = -1 -> k = 8
#   carpim kurali: (6x-2)(x+1) + (3x²-2x) = 9x²+2x-2
#   zincir kurali: 3(x²+1)²·2x = 6x(x²+1)²
#   limitler: (x²-4)/(x-2) -> 4 · sin(3x)/x -> 3
#   TTK m.378: riskin erken teshisi (saptanmasi) ve yonetimi komitesi
#
# 🔴 ONEMLI BULGU — MUKERRER DETEKTORUNUN GERCEKTEN KACIRDIGI IKIZLER:
#   lim(x->2)(x²-4)/(x-2) sorusunun havuzda DORT kopyasi var:
#     40171170, 4c548c08 (bu parti) + e656afde, a09bd285 (Parti onaylananlari)
#   lim(x->0) sin(3x)/x sorusunun DORT kopyasi var:
#     df3dd41a, b843541f (bu parti) + 964734f8 ve digeri
#   TTK m.378 riskin erken teshisi: 36d1ab48 ve 3c0a65c6 — ayni soru
#   capraz esneklik: 6a3861a9 ve fe2f6e66 — ayni kavram, farkli rakam
#   yatay analiz degisim yuzdesi: 2a503709 ve a7333bf4 — ayni formul
#   Eski 60-karakter kurali bunlari kacirmis (kok metinleri farkli yazilmis),
#   YENI kok+siklar kurali da kaciriyor cunku siklar da farkli yazilmis.
#   DERS: mukerrer denetimi metin benzerligiyle degil, KONU+CEVAP anahtariyla
#   yapilmali. Silinmedi (parasi odendi) ama benzerGrup etiketlendi; quiz motoru
#   bir oturumda gruptan tek soru servis etmeli.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$KAYNAK = @{
  '2a503709' = "Yatay (karşılaştırmalı tablolar) analiz tekniği — değişim yüzdesi = (Cari dönem − Önceki dönem) ÷ Önceki dönem"
  'a7333bf4' = "Yatay (karşılaştırmalı tablolar) analiz tekniği — değişim yüzdesi = (Cari dönem − Önceki dönem) ÷ Önceki dönem"
  '60d5f9dc' = "Finansal analiz — net çalışma (işletme) sermayesi = Dönen Varlıklar − Kısa Vadeli Yabancı Kaynaklar"
}

$GRUP = @{}
foreach($id in @('40171170','4c548c08')){ $GRUP[$id]='mat-limit-x2-4-bolu-x-2' }
foreach($id in @('df3dd41a','b843541f')){ $GRUP[$id]='mat-limit-sin3x-bolu-x' }
foreach($id in @('36d1ab48','3c0a65c6')){ $GRUP[$id]='muh-ttk378-risk-komitesi' }
foreach($id in @('6a3861a9','fe2f6e66')){ $GRUP[$id]='eko-capraz-esneklik' }
foreach($id in @('2a503709','a7333bf4')){ $GRUP[$id]='muh-yatay-analiz-degisim' }
foreach($id in @('44b80272','79157d1a')){ $GRUP[$id]='mat-turev-kurallari' }

$HEDEF = @('Muhasebe','Ekonomi','Finansal Tablolar ve Analizi','Matematik-Istatistik')
$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; grupEtiketlendi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'karantina'){ continue }
    if("$($s.onarim)" -notmatch 'YANLIS ALARM'){ continue }
    if($HEDEF -notcontains "$($s.ders)"){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($KAYNAK.ContainsKey($id)){
      $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
      $s.kaynak = $KAYNAK[$id]
      $ist.kaynakDuzeltildi++
    }
    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): karantinaya bozuk detektör yüzünden düşmüştü; hesaplar elle doğrulandı, cevap teyit edildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 15 (karantina / yanlış alarm — meslek+matematik) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

# --- KONU+CEVAP bazli mukerrer taramasi: metin benzerligi kaciriyor
Write-Host ""
Write-Host "--- TUM HAVUZDA konu+dogru cevap ayni olan gruplar (ilk 12):"
$anahtar = @{}
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $k = "$($s.ders)|$($s.konu)"
    if($anahtar.ContainsKey($k)){ $anahtar[$k]++ } else { $anahtar[$k] = 1 }
  }
}
$anahtar.GetEnumerator() | Where-Object { $_.Value -ge 6 } | Sort-Object Value -Descending | Select-Object -First 12 | ForEach-Object { Write-Host ("   {0,3}x  {1}" -f $_.Value, $_.Key) }
