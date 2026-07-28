# gm-okuma-14.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 14 (SON katman1-temiz partisi): Muhasebe teknik blogu, 61 soru.
# MSUGT/Tekduzen Hesap Plani 31 · BDS 20 · TMS 5 · mali analiz 4-5
#
# SONUC: 61 SORUNUN 61'ININ DE CEVABI DOGRU. Hesaplar elle dogrulandi, ornek:
#   cari oran: (800+100)/(400+100) = 1,80
#   nakit oran: (80+40)/200 = 0,60 · net isletme sermayesi: 350-400 = -50.000
#   net satislar: 500-20-15-5 = 460.000 · 500-20-30 = 450.000
#   tedarikcilere odenen nakit: alislar (500+100-80=520) - borc artisi (90-60=30) = 490.000
#   donem net kari: 500.000 - %25 = 375.000 -> 690 borc / 692 alacak
#   dikey yuzde: 120/1.000 = %12 · 450/0,30 = 1.500.000 · %100-%35-%20=%45 -> 900.000
# Tekduzen Hesap Plani kullanimi bastan sona dogru: 610/611/612, 601, 630, 631,
#   642, 644, 646, 671, 679, 690/691/692, 710/711, 720/721, 730/731, 151/152, 101.
# BDS 240/320/500/505/700/705 yorumlari da dogru.
#
# IKI YAPISAL KUSUR DUZELTILDI (cevap hatasi degil, SORU KURGUSU hatasi):
#   ec0ccaf0: "Bu giderler hangi hesapta izlenir?" diye soruyor ve hem 750 hem 630
#             siklarda var. 7/A'da Ar-Ge giderleri once 750'de IZLENIR, 751 yansitma
#             ile 630'a aktarilir; yani IKI SIK DA savunulabilir. Kok, gelir tablosu
#             sunumunu soracak sekilde netlestirildi -> 630 tek dogru olur.
#   4e9f0c18: D sikki, dogru cevap olan B ile AYNI yevmiye kaydini veriyor; sadece
#             alacak satirlarini once yazmis. Iki dogru sik demektir. D, tutarlari
#             yer degistirilmis GERCEK bir celdiriciye cevrildi.
#
# HAVUZ TEKDUZELIGI: cok sayida yakin-ikiz var (ayni kavram, kozmetik farkla).
# Ornek: yangin sigorta tazminati -> 679 iki kez; duran varlik satis kari -> 679
# iki kez; direkt iscilik tahakkuku -> 720 iki kez. Silinmedi, benzerGrup etiketlendi.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{}
foreach($id in @('cf067fee','996d2978')){ $GRUP[$id]='muh-direkt-iscilik-tahakkuk' }
foreach($id in @('81035bbb','27f8a912')){ $GRUP[$id]='muh-yangin-sigorta-679' }
foreach($id in @('9cdd328c','c1a1acdd')){ $GRUP[$id]='muh-duran-varlik-satis-679' }
foreach($id in @('afbdc0fb','5acc1508')){ $GRUP[$id]='muh-644-karsilik-iptali' }
foreach($id in @('0338f30a','254e3a14')){ $GRUP[$id]='muh-671-onceki-donem' }
foreach($id in @('7ca71acc','e0c1c145','67fa63a7','2ffc14e8')){ $GRUP[$id]='muh-dikey-yuzde' }
foreach($id in @('bcadce90','7cc51f25')){ $GRUP[$id]='muh-net-satislar' }
foreach($id in @('213e00dc','1684156a','8221c448','e62e36fb','fdf09a49')){ $GRUP[$id]='muh-bds240-hile' }
foreach($id in @('64fb8400','50405125','f4fab7af','1890ad5f','a5736506')){ $GRUP[$id]='muh-bds320-onemlilik' }
foreach($id in @('700af8d7','cc9ad16e','1d7e34d1','fce48010','610d3356','07df295a')){ $GRUP[$id]='muh-bds500-kanit' }
foreach($id in @('01945797','5a22999f','a741b4d5','71a85ca0','f586cb40','1553a5a8')){ $GRUP[$id]='muh-bds700-gorus' }
foreach($id in @('c82b200e','4e9f0c18','a6c60d30','15c1a81e')){ $GRUP[$id]='muh-7a-yansitma' }
foreach($id in @('e085cfd3','5bb8117c','2cb356cd','0c898320')){ $GRUP[$id]='muh-temel-kavramlar' }
foreach($id in @('6cd70ef2','febb7a64','c656ad94')){ $GRUP[$id]='muh-likidite-oranlari' }

$ist = [ordered]@{ onay=0; kurguDuzeltildi=0; grupEtiketlendi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Muhasebe'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($id -eq 'ec0ccaf0'){
      $s.soru = "Bir oyun şirketi, mevcut ürünlerinden ayrı olarak yeni bir oyun motoru geliştirmek için özel bir mühendislik ekibi kurmuş ve bu ekibin maaş, lisans ve donanım giderlerini kayıtlarına almıştır. İşletme 7/A seçeneğini uygulamaktadır. Bu giderler dönem sonunda GELİR TABLOSUNDA hangi hesapta gösterilir?"
      $s.aciklama.D = "Doğru. 7/A seçeneğinde araştırma ve geliştirme giderleri dönem içinde 750 Araştırma ve Geliştirme Giderleri hesabında toplanır, 751 yansıtma hesabıyla aktarılarak gelir tablosunda 630 Araştırma ve Geliştirme Giderleri hesabında gösterilir. Gelir tablosunda görünen hesap 630'dur."
      $s.aciklama.A = "Yanlış. 750, dönem içinde giderin toplandığı MALİYET hesabıdır; gelir tablosunda yer almaz, 751 yansıtma ile 630'a aktarılır."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Kök netleştirildi: eski hâli 'hangi hesapta izlenir' diye soruyordu ve 7/A'da hem 750 hem 630 savunulabilir olduğundan iki doğru şık vardı." -Force
      $ist.kurguDuzeltildi++
    }

    if($id -eq '4e9f0c18'){
      $s.siklar.D = "151 Yarı Mamuller-Üretim Borç 60.000 / 711 Alacak 20.000, 721 Alacak 30.000, 731 Alacak 10.000"
      $s.aciklama.D = "Yanlış. Tutarlar yer değiştirilmiştir: 711 Direkt İlkmadde ve Malzeme Yansıtma 30.000 TL, 721 Direkt İşçilik Yansıtma ise 20.000 TL'dir."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Şık düzeltildi: eski D şıkkı doğru cevap olan B ile AYNI yevmiye kaydını veriyordu (yalnızca alacak satırlarını önce yazmıştı), yani iki doğru şık vardı." -Force
      $ist.kurguDuzeltildi++
    }

    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): hesaplar elle doğrulandı, Tekdüzen Hesap Planı ve BDS 240/320/500/505/700/705 ile karşılaştırıldı. Cevap doğrulandı." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 14 (Muhasebe teknik — SON katman1 partisi) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.id)" -eq 'ec0ccaf0' -and "$($s.soru)" -notmatch 'GELİR TABLOSUNDA'){ $hata++; Write-Host "  KOK DUZELMEDI: ec0ccaf0" }
    if("$($s.id)" -eq '4e9f0c18' -and "$($s.siklar.D)" -notmatch '711 Alacak 20\.000'){ $hata++; Write-Host "  SIK DUZELMEDI: 4e9f0c18" }
  }
}
if($hata -eq 0){ Write-Host "   temiz — kurgu düzeltmeleri metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
