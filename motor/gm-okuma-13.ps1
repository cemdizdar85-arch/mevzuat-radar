# gm-okuma-13.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 13: Muhasebe dersinin VUK/GVK/TTK'ya dayanan 23 sorusu.
#
# SONUC: 23 SORUNUN 23'UNUN DE CEVABI DOGRU. Hesaplar elle dogrulandi:
#   ozkaynak = aktif - KVYK - UVYK (850-180-220=450 · 850-220-130=500 · 1.250-310-190=750)
#   donem sonu ozkaynak = donem basi + net kar - dagitilan (400+120-40=480 · 400+90-40=450)
#   duran varlik maliyeti = alis + nakliye + montaj (100+5+8=113; indirilebilir KDV ve
#     sonraki bakim sozlesmesi maliyete GIRMEZ)
#   binek oto KIST amortisman (VUK m.320/2): 1 Ekim iktisap -> 3 ay -> 300.000x%20x3/12=15.000
#   FIFO donem sonu stok: kalan 100 adet son alistan -> 100x70 = 7.000
#   mevduat faizi tahakkuku: 900.000 x %24 x 3/12 = 54.000, BRUT tutarla 181/642
#   pay getirisi = (66-60+3)/60 = %15
#
# DOGRU CIKAN ATIFLAR: VUK m.192 (bilanco/oz sermaye tanimi), m.270 (maliyet bedeli),
#   m.274 (emtia), m.283 (gelir tahakkuku), m.320 (kist amortisman), m.323 (supheli
#   alacak - TEMINATLI kisma karsilik ayrilamaz), m.183-184 (yevmiye/kebir sirasi),
#   GVK m.94 ("nakden veya hesaben" odeme aninda tevkifat), TTK m.509, m.519.
#
# UC ATIF DUZELTMESI:
#   71bb58f6: iskat ihtar usulu m.482'ye baglanmis; ihtar usulu m.483'tedir.
#             NOT: bu soru ihtar usulunu DOGRU vermis (ilan veya taahhutlu mektup) ve
#             "yalniz noter" secenegini celdirici yapmis. Ayni havuzdaki Meslek Hukuku
#             sorusu (8d8f1464) ise "noter" diyordu ve Parti 1'de duzeltilmisti -
#             fabrika ayni kuralin hem dogru hem yanlis versiyonunu uretmis.
#   ef4cc7d4: "GVK Gecici m.67" yazilmis; o madde menkul kiymet stopajini duzenler.
#             Soru bir GETIRI HESABIDIR, vergi hukmu degil.
#   b779e430: "VUK m.275" yazilmis; m.275 imal edilen emtiada maliyet bedelini duzenler,
#             ortak maliyetin net gerceklesebilir deger esasina gore dagitimini degil.
#             Bu bir MALIYET MUHASEBESI teknigidir.
#
# BIR ESKIME UYARISI:
#   6e8ca34a: isyeri kira stopaj orani %20 olarak yazili. Bu oran Cumhurbaskani
#             kararlariyla degisebilir; robot her yil teyit etmeli.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$KAYNAK = @{
  '71bb58f6' = "TTK (6102 s.K.) m.482 (temerrüt ve ıskat yetkisi) ile m.483 (ıskat usulü: ilan veya nama yazılı pay senetlerinde iadeli taahhütlü mektupla ihtar, bir aylık süre)"
  'ef4cc7d4' = "Finansal yönetim — pay senedi toplam (bileşke) getirisi = (satış/dönem sonu fiyatı − alış fiyatı + nakit kâr payı) ÷ alış fiyatı"
  'b779e430' = "Maliyet muhasebesi — ortak (müşterek) maliyetlerin net gerçekleşebilir değer esasına göre dağıtımı"
}

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; eskimeUyarisi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Muhasebe'){ continue }
    if("$($s.kaynak)" -notmatch 'VUK|213|GVK|193|TTK|6102'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($KAYNAK.ContainsKey($id)){
      $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
      $s.kaynak = $KAYNAK[$id]
      $ist.kaynakDuzeltildi++
    }

    if($id -eq '6e8ca34a'){
      $s | Add-Member -NotePropertyName eskimeUyarisi -NotePropertyValue "İşyeri kira stopaj oranı (%20) Cumhurbaşkanı kararıyla değişebilir; robot yıllık teyit etmeli. GVK m.94/5-a" -Force
      $ist.eskimeUyarisi++
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): hesaplar elle doğrulandı; VUK m.192, 270, 274, 275, 283, 320, 323, 183-184 ve GVK m.94, TTK m.482-483, 509, 519 ambardan birinci elden kontrol edildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $g = if("$($s.konu)" -match 'ozkaynak'){'muh-ozkaynak-hesabi'} elseif("$($s.konu)" -match 'stopaj'){'muh-kira-stopaji'} elseif("$($s.konu)" -match 'duran varlik'){'muh-duran-varlik'} elseif("$($s.konu)" -match 'mevduat'){'muh-mevduat-tahakkuk'} else {'muh-vergi-diger'}
    $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $g -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 13 (Muhasebe / VUK-GVK-TTK) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if($KAYNAK.ContainsKey("$($s.id)") -and "$($s.kaynak)" -ne $KAYNAK["$($s.id)"]){ $hata++; Write-Host ("  KAYNAK YAZILMADI: {0}" -f $s.id) }
  }
}
if($hata -eq 0){ Write-Host "   temiz — kaynak düzeltmeleri metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
