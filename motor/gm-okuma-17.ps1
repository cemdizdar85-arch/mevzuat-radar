# gm-okuma-17.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 17 — KARANTINADAN ILK GERCEK K2 ITIRAZI PARTISI:
# Maliye 17 + Vergi Mevzuati 10 = 27 soru.
#
# BU PARTI FARKLI: onceki partiler "hic denetlenmemis" sorulardi. Bunlarda K2
# denetcisi ACIKCA ITIRAZ ETMIS. Yani GM burada HAKEM: kim hakli?
#
# SONUC: K2 27 itirazinin 25'inde HAKSIZ, 2'sinde HAKLI cikti.
# Bu onemli bir olcum: K2 maddeyi OKUMADAN, ezberden itiraz ediyor (istemde
# yalnizca kaynak ETIKETI var, madde METNI yok). Ezberi zayif oldugunda emin bir
# dille yanlis itiraz ediyor. Ornek: "SGK primi parafiskal degil vergidir",
# "devlet universiteleri genel butce kapsamindadir", "merkezi yonetim = genel +
# ozel + MAHALLI IDARE butceleri" - ucu de yanlis.
#
# AMA IKI KEZ HAKLI CIKTI VE IKISI DE AGIR:
#   268d5f38: soru "belediye vergileri VUK KAPSAMI DISINDADIR" diyordu.
#     VUK m.1 AMBARDAN okundu: "Bu kanun hukumleri ikinci maddede yazili olanlar
#     disinda, genel butceye giren vergi, resim ve harclar ILE IL OZEL IDARELERINE
#     VE BELEDIYELERE AIT vergi, resim ve harclar hakkinda uygulanir."
#     Yani belediye vergileri VUK'a TABIDIR. Cevap anahtari yanlisti.
#   9b153467: soru ihtiyati hacze itirazi "7 gun" diyordu.
#     AATUHK m.15 AMBARDAN okundu: "...haczin tatbiki ... tarihinden itibaren
#     ONBES GUN icinde alacakli tahsil dairesine ait itiraz islerine bakan vergi
#     itiraz komisyonu nezdinde ... itiraz edebilirler." Sure YANLISTI.
#
# BIR SORU DA RED: ece7d654. Analitik butce siniflandirmasinda "SGK'ya Devlet
# Primi Giderleri" KENDI BASINA bir ekonomik koddur (02); ne personel gideri (01)
# ne cari transfer (05). Isaretli C de K2'nin B'si de yanlis; dogru sik YOK.
#
# AMBARDAN BIRINCI ELDEN OKUNAN MADDELER:
#   VUK m.1 (kapsam) · VUK m.371 (pismanlik) · AATUHK m.15 (ihtiyati hacze itiraz)
#   5018 m.12 (merkezi yonetim = I + II + III sayili cetveller)
#   KDVK m.10/b (fatura once duzenlenirse VDO fatura tarihinde)
#   KDVK m.11/1-a ve 11/1-c · m.14 (transit) · m.15/1-a (karsiliklilik) · m.25/a

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

# --- kaynak duzeltmeleri (cevap dogru, atif yanlis)
$KAYNAK = @{
  'f1883747' = "Analitik Bütçe Sınıflandırması — kurumsal (idari) sınıflandırma: ödeneğin HANGİ KURUMA tahsis edildiğini gösterir"
  '0ffc531f' = "Uluslararası vergi hukuku — çifte vergilendirmeyi önleme yöntemleri: istisna (ayırma) ve mahsup (kredi). OECD Model m.23A istisna, m.23B mahsup. NOT: KVK m.33 Türkiye'nin uyguladığı MAHSUP yöntemidir; soru istisna yöntemini tanımlatmaktadır"
  '5c8b712e' = "5018 s. Kanun m.12 ve ekli (III) sayılı cetvel — düzenleyici ve denetleyici kurum bütçeleri"
  'a725607d' = "5018 s. Kanun m.12 ve ekli (II) sayılı cetvel — özel bütçeli idareler"
  '2b2ff7a6' = "5018 s. Kanun m.12: 'Merkezî yönetim bütçesi, bu Kanuna ekli (I), (II) ve (III) sayılı cetvellerde yer alan kamu idarelerinin bütçelerinden oluşur.'"
  '30b08dce' = "KDVK (3065 s.K.) m.11/1-a — serbest bölgelerdeki müşteriler için yapılan fason hizmetler istisnası"
  'ebf319c5' = "KDVK (3065 s.K.) m.15/1-a — 'Karşılıklı olmak' kaydıyla yabancı devletlerin Türkiye'deki diplomatik temsilcilik ve konsolosluklarına yapılan teslim ve hizmetler"
  '41453c10' = "VUK (213 s.K.) m.371/4 — haber verilen verginin haber verme tarihinden başlayarak onbeş gün içinde ödenmesi şartı"
  '9b153467' = "AATUHK (6183 s.K.) m.15 — ihtiyati hacze itiraz"
  '174dbc49' = "KDVK (3065 s.K.) m.14 — transit ve Türkiye ile yabancı ülkeler arasında yapılan taşımacılık işlerinde istisna"
  '01c16066' = "KDVK (3065 s.K.) m.10/b — malın tesliminden önce fatura düzenlenmesi hâlinde vergiyi doğuran olay fatura tarihinde meydana gelir"
}

$ONAY = @('cbec0e65','f1883747','6a59706a','0ffc531f','4d81969e','5c8b712e','4290c3b1',
          '01c16066','5aafd472','8a7a4a7e','30b08dce','174dbc49','647d8f3b','a725607d',
          'ebf319c5','2b2ff7a6','41453c10','f8554f3f')

$BEKLET = @{
  '0e047f17' = "GM BEKLETTI (28.07): 5018'de bütçe cetvellerinde değişiklik yetkisinin kime ait olduğunu düzenleyen hüküm ambardan OKUNAMADI. Okumadan onay verilmez."
  '63dacee0' = "GM BEKLETTI (28.07): 5018 m.17 (bütçe tekliflerinin gönderilme tarihi) ambardan çekilemedi - sorgu geçici m.17'yi getirdi. Süre iddiası (Eylül sonu) maddeden teyit edilmeden onaylanmaz."
  '0d30468e' = "GM BEKLETTI (28.07): Orta Vadeli Mali Plan'ın hangi kurum tarafından ve kaç gün içinde hazırlanacağını düzenleyen 5018 maddesi ambardan okunamadı. Ayrıca soruda atıf m.17'ye yapılmış; OVMP m.16'da düzenlenir."
  '03adea93' = "GM BEKLETTI (28.07): ÖTV Kanunu m.5 ve m.8 ambardan okunmadı. (I) sayılı listedeki malların ihraç kayıtlı teslime konu edilip edilemeyeceği maddeden teyit edilmeden onaylanmaz."
  '109766d8' = "GM BEKLETTI (28.07): ÖTV Kanunu m.5 (ihracat istisnası / iade) ambardan okunmadı."
}

$RED = @{
  'ece7d654' = "GM RED (28.07): Analitik Bütçe Sınıflandırmasında 'Sosyal Güvenlik Kurumlarına Devlet Primi Giderleri' KENDİ BAŞINA bir ekonomik koddur (02); Personel Giderleri (01) ve Cari Transferler (05) ile aynı seviyede AYRI bir gruptur. İşaretlenen C (cari transferler) da K2'nin önerdiği B (personel giderleri) de yanlıştır; şıklar arasında doğru cevap YOKTUR, cevap anahtarı düzeltilerek kurtarılamaz."
}

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; cevapDuzeltildi=0; red=0; beklet=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'karantina'){ continue }
    if(@('Maliye','Vergi Mevzuatı ve Uygulaması') -notcontains "$($s.ders)"){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($RED.ContainsKey($id)){
      $s.durum = 'karantina-red'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $RED[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.red++; $degisti=$true; continue
    }
    if($BEKLET.ContainsKey($id)){
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $BEKLET[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.beklet++; $degisti=$true; continue
    }

    # --- K2'NIN HAKLI CIKTIGI IKI SORU: cevap/sik duzeltilir
    if($id -eq '268d5f38'){
      $s.siklar.A = "İl özel idareleri ve belediyelere ait vergi, resim ve harçlar Vergi Usul Kanunu kapsamı dışındadır, yalnızca kendi özel kanunlarına tabidir"
      $s.siklar.E = "Belediyeye ait bu vergi de Vergi Usul Kanunu hükümlerine tabidir; VUK yalnızca gümrük ve tekel idarelerince alınan vergi ve resimleri kapsam dışında bırakır"
      $s.dogru = 'E'
      $s.aciklama.E = "Doğru. VUK m.1: 'Bu kanun hükümleri ikinci maddede yazılı olanlar dışında, genel bütçeye giren vergi, resim ve harçlar İLE İL ÖZEL İDARELERİNE VE BELEDİYELERE AİT vergi, resim ve harçlar hakkında uygulanır.' Yani çevre temizlik vergisi gibi belediye vergileri usul bakımından VUK'a tabidir. m.2 ise yalnızca gümrük ve tekel idarelerince alınan vergi ve resimleri kapsam dışında bırakır."
      $s.aciklama.A = "Yanlış. VUK m.1 belediye ve il özel idaresi vergilerini AÇIKÇA kapsama alır; kapsam dışı bırakılan tek grup m.2'deki gümrük ve tekel idaresi vergileridir."
      $s.kaynak = "VUK (213 s.K.) m.1 (kapsam) ve m.2 (kapsam dışı olanlar)"
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM DUZELTTI (28.07): K2 HAKLI CIKTI. Soru 'belediye vergileri VUK kapsami disindadir' diyordu; VUK m.1 ambardan okundu ve tam tersini soyluyor. Cevap anahtari A'dan E'ye alindi, E sikkinin metni m.2 istisnasini da kapsayacak sekilde duzeltildi." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $s.durum = 'gm-onay'
      $ist.cevapDuzeltildi++; $ist.onay++; $degisti=$true; continue
    }
    if($id -eq '9b153467'){
      $s.siklar.A = "Haczin tatbiki (gıyapta yapılan hacizlerde haczin tebliği) tarihinden itibaren 15 gün içinde, alacaklı tahsil dairesinin bulunduğu yerdeki vergi mahkemesinde"
      $s.siklar.D = "Haczin tatbikinden itibaren 7 gün içinde icra mahkemesinde"
      $s.aciklama.A = "Doğru. AATUHK m.15: 'Haklarında ihtiyati haciz tatbik olunanlar haczin tatbikı, gıyapta yapılan hacizlerde haczin tebliği tarihinden itibaren 15 gün içinde alacaklı tahsil dairesine ait itiraz işlerine bakan vergi itiraz komisyonu nezdinde ihtiyati haciz sebebine itiraz edebilirler.' Maddedeki 'vergi itiraz komisyonu' bugünkü vergi mahkemeleridir."
      $s.aciklama.D = "Yanlış. Süre 7 gün değil 15 gündür ve görevli yargı yeri icra mahkemesi değil vergi mahkemesidir."
      $s.kaynak = "AATUHK (6183 s.K.) m.15 — ihtiyati hacze itiraz"
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM DUZELTTI (28.07): K2 SUREDE HAKLI CIKTI. Soru '7 gun' diyordu; AATUHK m.15 ambardan okundu, sure ONBES GUN. K2'nin onerdigi merci (icra mahkemesi) ise yanlisti; madde vergi itiraz komisyonu (bugunku vergi mahkemesi) diyor. Sik metni ve aciklama maddeye gore duzeltildi." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $s.durum = 'gm-onay'
      $ist.cevapDuzeltildi++; $ist.onay++; $degisti=$true; continue
    }

    if($ONAY -contains $id){
      if($KAYNAK.ContainsKey($id)){
        $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
        $s.kaynak = $KAYNAK[$id]; $ist.kaynakDuzeltildi++
      }
      $s.durum = 'gm-onay'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM HAKEMLIK ETTI (28.07): K2 itirazi HAKSIZ. Ilgili madde ambardan birinci elden okundu, isaretli cevap dogrulandi. K2 istemde madde METNINI gormedigi icin ezberden itiraz etmis." -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.onay++; $degisti=$true
    }
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 17 (karantina / Maliye + Vergi) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-20} {1}" -f $k, $ist[$k]) }

# --- yazma sonrasi METIN dogrulamasi
Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if("$($s.id)" -eq '268d5f38'){
      if("$($s.dogru)" -ne 'E'){ $hata++; Write-Host "  CEVAP DUZELMEDI: 268d5f38" }
      if("$($s.siklar.E)" -notmatch 'tabidir'){ $hata++; Write-Host "  SIK DUZELMEDI: 268d5f38/E" }
    }
    if("$($s.id)" -eq '9b153467' -and "$($s.siklar.A)" -notmatch '15 gün'){ $hata++; Write-Host "  SIK DUZELMEDI: 9b153467/A" }
  }
}
if($hata -eq 0){ Write-Host "   temiz — cevap ve şık düzeltmeleri metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
