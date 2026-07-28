# gm-okuma-05.ps1 - 28.07.2026
# GM OKUMASI, PARTI 5: Genel Kultur-Genel Yetenek, 'katman1-temiz' 105 soru.
#
# YONTEM: her soru elle okundu. Turkce/paragraf sorularinda dogrulama tamdir
# (kural ya dogrudur ya degildir); tarih hesabi sorulari elle hesaplandi.
# SONUC: 105 sorunun 105'inin de CEVABI DOGRU. Sifir cevap hatasi.
#   (Kumulatif: Matematik 51/51, Yabanci Dil 34/34, Genel Kultur 105/105 = 190 soru,
#    sifir hata. Mevzuat sorularinda ise 17 okumada 4 hata.)
#
# UC KUSUR BULUNDU:
#  1) UYDURMA KISIYE UYDURMA SOZ ISNADI (2 soru) - DUZELTILDI:
#     4f1c4be1: "unlu fizyolog Prof. Dr. Ahmet Kaya bir roportajinda ... demistir"
#     cce9e789: "Uzman barista Ahmet Kaya'nin da soyledigi gibi ..."
#     Turkiye'de bu adda gercek kisiler var; var olmayan bir alintiyi adi konmus
#     birine isnat etmek bizim kuralimiza aykiri. "Tanik gosterme" anlatim yolu
#     isimsiz uzmanla da kurulur; metin ona gore duzeltildi.
#  2) SUPHELI SORU (1) - BEKLETILDI:
#     d5fd60af: "...musteriyi memnun etti ve ... yeni bir teklif hazirliyor" cumlesini
#     zaman/kip uyumsuzlugu sayiyor. Oysa iki yuklem GERCEKTEN farkli zamanlardaki
#     iki olayi anlatiyor; cumle duzgun Turkce. Sallantili bir kurali ogretmektense
#     soru bekletildi.
#  3) HAVUZ TEKDUZELIGI - benzerGrup etiketi eklendi (silinmedi, parasi odendi).

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$GRUP = @{}
foreach($id in @('247ca306','df7c78a0','14beb73c','068bcb41','3a9ff106','de7d2639','29bb3525','645bfe4e','0ab4692d','b9e6f69e','ab6df096','51ffef62')){ $GRUP[$id]='gk-anlatim-bicimi' }
foreach($id in @('ad712f0b','4f1c4be1','c2d3fac5','04ea3a03','cce9e789','e308efc4')){ $GRUP[$id]='gk-dusunce-gelistirme' }
foreach($id in @('6fb7f7c7','a9e668e6','4f79b5aa','9611ad7d','4a2d6255','0c2e2fed','6fa5b45d','8cd49fb7','44e4f5fc','96ded1d9','ac8862a1','e00570ef')){ $GRUP[$id]='gk-akis-bozan-cumle' }
foreach($id in @('4645e559','e1deb6f1','5ac791b8','328f6772','c29dcfe5','ba6973d3','6d7d1cdb','73b3a0f2','86dea294','d3ed357e','1343895d','b0eaf0b9','8cd7afb5','ee2ef9a2')){ $GRUP[$id]='gk-paragraf-tamamlama' }
foreach($id in @('0ae77431','c0ce8c24','90ae95e1','bfaa2077','6cc4ba01','0c234bbd')){ $GRUP[$id]='gk-nesnel-oznel' }
foreach($id in @('b1663d70','531bf174')){ $GRUP[$id]='gk-cokanlamli-bas' }
foreach($id in @('97abb9b0','5a4fe1ca','1b17642a')){ $GRUP[$id]='gk-savas-tarih-hesabi' }

$ist = [ordered]@{ onaylandi=0; icerikDuzeltildi=0; bekletildi=0; grupEtiketlendi=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"
    if("$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Genel Kultur-Genel Yetenek'){
      if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++; $degisti=$true }
      continue
    }

    # --- (2) supheli: beklet
    if($id -eq 'd5fd60af'){
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM BEKLETTI (28.07): soru, 've' ile baglanan iki yuklem arasindaki zaman farkini anlatim bozuklugu sayiyor. Oysa 'memnun etti' ile 'teklif hazirliyor' gercekten farkli zamanlardaki iki olayi anlatiyor; cumle duzgun Turkce. Sallantili bir kurali ogretmemek icin yayina alinmadi." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.bekletildi++; $degisti=$true
      continue
    }

    # --- (1) uydurma kisi isnadi: duzelt
    if($id -eq '4f1c4be1'){
      $s.soru = $s.soru -replace "ünlü fizyolog Prof\. Dr\. Ahmet Kaya bir röportajında", "bu alanda çalışan bir fizyolog bir röportajında"
      $s.aciklama.C = "Doğru. İkinci cümlede yazar kendi savını desteklemek için alanın bir uzmanının sözünü aktarıyor; bu, düşünceyi geliştirme yollarından TANIK GÖSTERME'dir. Örnekleme olsaydı somut bir durum/vaka verilirdi, karşılaştırma olsaydı iki unsur karşı karşıya konurdu."
      $ist.icerikDuzeltildi++
    }
    if($id -eq 'cce9e789'){
      $s.soru = $s.soru -replace "Uzman barista Ahmet Kaya'nın da söylediği gibi", "Alanında deneyimli bir baristanın da söylediği gibi"
      $ist.icerikDuzeltildi++
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM elle okudu, cevap dogrulandi (28.07). Turkce/paragraf sorusunda kaynak mevzuat maddesi degil, dil kuralinin kendisidir." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.onaylandi++
    if($GRUP.ContainsKey($id)){ $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $GRUP[$id] -Force; $ist.grupEtiketlendi++ }
    $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 5 (Genel Kultur) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }
