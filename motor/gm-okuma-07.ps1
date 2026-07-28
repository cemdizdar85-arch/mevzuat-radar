# gm-okuma-07.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 7: Maliyet Muhasebesi 14 + Muhasebe Denetimi 4 +
# Finansal Muhasebe 3 + Finansal Tablolar ve Analizi 1 = 22 soru ('katman1-temiz').
#
# YONTEM: hesap sorulari elle hesaplandi, kayit sorulari Tekduzen Hesap Plani ve
# BDS metinleriyle karsilastirildi.
# SONUC: 22 sorunun 22'sinin de CEVABI DOGRU. Sifir hata.
#
# ---- BULGUNUN ANLAMI (musluk karari icin belirleyici) ----
# Bugune kadarki tablo "mevzuat = riskli, mevzuat disi = guvenli" gorunuyordu.
# Bu parti onu KESINLESTIRDI ve daralt(t)i. Asil ayrim ders degil, SORU TIPI:
#
#   TEHLIKELI  : kanun metnindeki SPESIFIK RAKAMI hatirlamak gereken sorular
#                (madde numarasi, gun, oran, esik, tutar)
#                -> Meslek Hukuku 19 soruda 13 mudahale (%68)
#                -> Vergi (binek oto %70, 5510 m.8 istisnasi) hatali
#   GUVENLI    : teknik/hesap/kavram sorulari
#                -> Maliyet+Denetim+Fin.Muh. 22/22 dogru
#                -> Tekduzen Hesap Plani kodlari (730, 770, 760, 197, 129, 644,
#                   121, 128) tamaminda dogru
#                -> Matematik 51/51, Yabanci Dil 34/34, Genel Kultur 105/105
#
# Yani model muhasebe/denetim BILGISINI biliyor; kaybettigi yer kanun maddesinin
# NUMARASI ve icindeki SAYI. Cozucuye atif yapilan maddenin ambardaki METNINI
# vermek tam da bu bosluga denk gelir.
#
# TEK DUZELTME: fb681580'in kaynagi "TMS 1 m.38" yazilmis; TMS 1 m.38
# karsilastirmali BILGI SUNUMUNU duzenler, yatay analizde yuzde degisim hesabini
# degil. Yatay analiz bir finansal analiz teknigidir, muhasebe standardi hukmu degil.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"
$HED = @('Maliyet Muhasebesi','Muhasebe Denetimi','Finansal Muhasebe','Finansal Tablolar ve Analizi')

# 14 Maliyet sorusunun 11'i ayni konuda (GUG kapsami) - havuz dengesi icin etiket
$GUG = @('08d9a573','b4086852','e1e56fe9','9c23d93e','e08a8b4a','b8f50113','039381cd','6ddc5144','2f2b9ca0','3a4a875b','d62aa4c8')
$RISK = @('644822a6','5c73cfe8','8fceadcf')   # ucu de "tespit edememe riski"

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; grupEtiketlendi=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz'){ continue }
    if($HED -notcontains "$($s.ders)"){ continue }
    $id = "$($s.id)"

    if($id -eq 'fb681580'){
      $s.kaynak = "Yatay (karşılaştırmalı tablolar) analiz tekniği — değişim yüzdesi = (Cari dönem − Önceki dönem) ÷ Önceki dönem"
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Kaynak düzeltildi: eskiden 'TMS 1 m.38' yazıyordu; o madde karşılaştırmalı BİLGİ SUNUMUNU düzenler, yüzde değişim hesabını değil. Yatay analiz bir finansal analiz tekniğidir." -Force
      $ist.kaynakDuzeltildi++
    }

    if($GUG -contains $id){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue 'mal-gug-kapsami' -Force; $ist.grupEtiketlendi++ }
    if($RISK -contains $id){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue 'den-tespit-edememe-riski' -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): hesap soruları elle hesaplandı, kayıt soruları Tekdüzen Hesap Planı ve BDS ile karşılaştırıldı. Cevap doğrulandı." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 7 ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }
if($ist.onay -ne 22){ Write-Host ("UYARI: beklenen 22, onaylanan {0}" -f $ist.onay) }
