# gm-okuma-02.ps1 - 28.07.2026
# GM OKUMASI, PARTI 2: Vergi Mevzuati - binek otomobil gider kisitlamasi.
#
# KAYNAK: GVK m.40 (ambardan), 311 Seri No.lu GVK Genel Tebligi ve GIB "Binek
# Otomobillerin Giderleri ve Amortismanlarinin Vergi Matrahindan Indirimi" Rehberi
# (2025) birinci elden okundu. Rehberin SAYISAL ORNEKLERI konuyu kesin cozdu:
#   Ornek 2: aylik 60.000 TL kira -> 37.000 gider, 23.000 KKEG  (%70 UYGULANMAMIS)
#   Ornek 5: gunluk kiralama 200.000 -> 24.666,66 gider, 175.333,34 KKEG (%70 YOK)
#   Ornek 8: %70'e tabi giderler tek tek sayilmis: akaryakit, sigorta, tamir-bakim,
#            kopru/otoyol, kasko, otopark, MTV, kredi faizi. KIRA BU LISTEDE YOK.
# SONUC: kira bedeline tavan uygulanir, kalan kisma AYRICA %70 uygulanmaz.
# K2'nin "kira %70 uygulamasi supheli" itirazi HAKLIYDI.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$ist = [ordered]@{ onarildi=0; bekletildi=0; bulunamadi=0 }
$islenen = @{}

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"

    # --- 99036e87: kiralik binek oto, sinir asan kisim + %70 iddiasi
    if($id -eq '99036e87'){
      $s.siklar.D = "Sinira kadarki kisim gider yazilir, siniri asan kisim KKEG'dir; kira bedeline ayrica %70 kisitlamasi UYGULANMAZ"
      $s.aciklama.D = "Dogru. Kiralama yoluyla edinilen binek otomobilde aylik kira bedelinin o yil icin belirlenen tutara kadarki kismi gider yazilir, asan kisim KKEG olur (GVK m.40/1-1; 311 Seri No.lu GVK GT m.13). GIB Binek Oto Rehberi Ornek 2 bunu sayiyla gosterir: aylik 60.000 TL kira odeyen banka 37.000 TL'yi gider yazmis, 23.000 TL'yi KKEG yapmistir - kalan tutara %70 uygulanmamistir. %70 kisitlamasi ise GVK m.40/1-5 ve ayni Rehberin Ornek 8'i uyarinca taşitlarin tamir, bakim, yakit, sigorta, kasko, otopark, kopru-otoyol, MTV ve kredi faizi gibi CARI giderlerine uygulanir; kira bedeli bu listede yer almaz."
      $s.aciklama.A = "Yanlis. Kira gideri maliyete eklenip amortismana tabi tutulmaz; kiralamada aracin mulkiyeti isletmeye gecmez. Maliyete ekleme ve amortisman, satin alinan binek otomobiller icin gecerlidir (GVK m.40/1-7)."
      $s.kaynak = "GVK m.40/1-1 ve m.40/1-5; 311 Seri No.lu GVK Genel Tebligi m.13-14; GIB Binek Otomobil Rehberi Ornek 2, 5, 8"
      $s.hap = "Kiralik binek otomobilde IKI AYRI kural vardir, karistirilmamalidir. (1) KIRA BEDELI: her arac icin AYLIK tavan uygulanir (2025: 37.000 TL, 2026: 46.000 TL, KDV haric); asan kisim KKEG'dir, tavan icinde kalan kismin TAMAMI gider yazilir. (2) %70 KISITLAMASI: yalniz tamir, bakim, yakit, sigorta, kasko, otopark, kopru-otoyol, MTV ve kredi faizi gibi CARI giderlere uygulanir - arac kiralik da olsa isletmeye kayitli da olsa fark etmez. TUZAK: tavani uyguladiktan sonra kalan kiraya bir de %70 uygulamak; GIB'in Ornek 2 ve Ornek 5'i bunu yapmaz. Ayrica FINANSAL kiralamada aylik kira tavani hic uygulanmaz."
      $s.durum = 'gm-onay'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu. K2'nin itirazi HAKLI cikti: D sikkindaki '%70' iddiasi yanlisti, GIB Rehberi Ornek 2/5/8 ile duzeltildi. Kaynak alani ve hap birincil metne gore yeniden yazildi." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.onarildi++; $islenen[$id]=$true; $degisti=$true
      continue
    }

    # --- 843782a8: KKEG amortismanin satista duzeltilip duzeltilmeyecegi
    if($id -eq '843782a8'){
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM BEKLETTI (28.07): binek otomobil satisinda, onceki donemlerde KKEG yazilan amortismanin satis kazancindan indirilip indirilmeyecegi kanun metninden cikmiyor; GIB Binek Oto Rehberinde de sayisal ornegi yok. Bu konuda GIB ozelgesi ambara yutulmadan karar verilmeyecek. Kaynak gelene kadar karantinada kalir." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $s | Add-Member -NotePropertyName gerekenKaynak -NotePropertyValue "GIB ozelgesi: binek otomobil satisinda KKEG yazilan amortismanin durumu" -Force
      $ist.bekletildi++; $islenen[$id]=$true; $degisti=$true
      continue
    }
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

foreach($id in @('99036e87','843782a8')){ if(-not $islenen.ContainsKey($id)){ Write-Host ("BULUNAMADI: {0}" -f $id); $ist.bulunamadi++ } }
Write-Host "======== GM OKUMASI PARTI 2 ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ist[$k]) }
if($ist.bulunamadi -gt 0){ exit 1 }
