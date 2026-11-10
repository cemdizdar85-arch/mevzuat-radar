# BASIM ÖNCESİ ÖLÇÜM — 10.11.2026 (0 USD)

> Yöntem: yalnız depodaki kod ve dosyalar okundu. Ambar (canlı veri) sorgulanmadı, soru okunmadı, ücretli çağrı yapılmadı.
> Bağlı belgeler: [`BASIM-ONCESI-DUZEN-TASLAK.md`](../../BASIM-ONCESI-DUZEN-TASLAK.md) · [`CEM-ISTEK-LISTESI-1011.md`](CEM-ISTEK-LISTESI-1011.md).
> **Bu ölçümün görmediği:** her alanın bankada kaç soruda dolu olduğu · alanların içeriğinin doğruluğu · SGS ve KGK yayın yolları
> (yalnız `motor/kaydir-coz.ps1` okundu) · kanun maddesi düzeyinde kart–ambar eşleşmesi (yalnız standartlar kaynak adıyla eşlendi).

---

## 1. Ekrana basılan alanlar ve denetim durumu

Kaynak: `motor/kaydir-coz.ps1` satır 535 (ekran nesnesi, 31 alan) ile `arac/aciklama-hakemi-cekirdek.ps1` `AciklamaHakemIs` (hakeme giden alanlar).

| Ekran alanı | Ambar kaydındaki kaynağı | Açıklama hakemi görüyor mu | Not |
|---|---|---|---|
| soru · şıklar · doğru | `soru` `siklar` `dogru` | Evet (ayrıca hakem, hakem2, kör, simülasyon) | En çok denetlenen katman |
| konu özeti (`konuGiris`: nedir, sınavda, yöntemler, örnek, panel örneği, harita, desen) | `konu_giris` | Evet (06.11'den beri) | Yakalama oranı ÖLÇÜLMEDİ |
| terim notu (`konuGiris.terimler`) | `konu_giris.terimler` | Evet (07.11'den beri) | Yakalama oranı ÖLÇÜLMEDİ |
| hap · taktik | `hap` `sinav_taktigi` | Evet | |
| şık açıklamaları → ekranda `tuzak` `kural` `olay` | `aciklama` | Ham hâlini görüyor | Ekrandaki hâli yayın anında düzenli ifadeyle `aciklama`'dan AYRIŞTIRILIYOR; ayrıştırılmış hâli kimse görmüyor |
| sade (doğru, sınav, şıklar, kavramlar) | `sade` | Evet (07.11'de tamamlandı) | |
| verilenler | `verilenler` | Evet (07.11'den beri) | |
| teşhis · çeldirici yolu | `teshis` `celdirici_yol` | Evet | |
| adımlar | `adimlar` | **Kısmen:** yalnız `anlatim` ve `formul` | `doldur`, `sik`, `karar` hakeme gitmiyor (`karar` için mekanik KAPI-KARNE var) |
| **çözüm tablosu (`tablo`)** | `cozum_tablo` | **HAYIR** | Hakem istemindeki alan listesinde yok. Ekran çizicisi `tablo`'yu 52 yerde okuyor |
| yevmiye kaydı (`kayit`, `kayitlar`, `kayitBaslik`) | `ky`, `kyAll` | Belirsiz | Hakem `sema` alanını (türü yevmiye ise) görüyor; `ky` ile aynı içerik mi ÖLÇÜLMEDİ |
| ikiz soru (`oyun`, tür ikiz/tablo) | `ikiz` | **Kısmen:** `ikiz_soru`, `tablo`, `hedef_cumle` | `ikiz.verilen`, `ikiz.bosluk` ve ikiz yevmiye öğeleri gitmiyor |
| **ölçekli tekrar (`oyun` tür olcek, `oyunBonus`)** | Yok: yayın anında kod, sorunun tutarlarını değiştirerek üretiyor | **HAYIR** | Hiçbir hakem ve kapı görmüyor; kodun ürettiği sorunun doğruluğu ÖLÇÜLMEDİ |
| hesap tanımları (`hesaplar`) | Ambardaki hesap planı, kodla | Hayır (model yazmıyor) | Kaynak doğruysa doğru |
| dayanak | `dayanak` | Evet (kural 10) | |
| konu · ders · dönem · tip · ölçüm | Etiket ve sayaçlar | Hayır | Ders/konu etiketi ayrı denetimde |

### İki yapısal bulgu

1. **Hakemden sonra metin değişiyor.** `TurkceOnar` yayın betiğinde 59 yerde çağrılıyor ve öğrencinin gördüğü hemen her metin alanını
   yayın anında yeniden yazıyor. Hakem ambar kaydını okur; öğrenci dönüştürülmüş hâli görür. "katip → katıp", "BES → BEŞ" bozulmaları
   (brif, 09.11) bu adımdan. Öğrencinin gördüğü son metni denetleyen bir adım yok.
2. **Yayın anında içerik üretiliyor.** Ölçekli tekrar sorusu, türetilmiş "Adım / İçerik" ve "Şık / Kaynak / Karar" tabloları yayın
   betiğinde ya da tarayıcıda kodla kuruluyor. Bunlar ambarda durmadığı için basım tarafındaki hiçbir kapıdan geçmiyor.

Sonuç: "ekrandaki her alan hakeme gider" kuralı (B34) bugün en az üç alanda tutmuyor: çözüm tablosu, ölçekli tekrar, yayın anı dönüştürmesi.

---

## 2. Konu kartları bugün ne taşıyor

| | Bitirme (`bitirme-konu-kartlari.json`) | KGK (`kgk-konu-kartlari.json`) | SGS |
|---|---|---|---|
| Kart sayısı | 309 | 1.814 | Kart dosyası bulunamadı |
| Kalıp, kök uzunluğu, şık türü, "ne sorar", çeldirici | Var | Var | — |
| Dayanak | 309/309 dolu (serbest metin) | 1.814/1.814 dolu | — |
| Konu özeti | 0 | 0 | — |
| Terim notu | 0 | 0 | — |
| Onay kaydı (kim, ne zaman) | 0 | 0 | — |
| Kalıbı tahmini olan kart | 124 / 309 | alan yok | — |

**Okuma:** eldeki kartlar "sınav bu konuyu nasıl sorar" kartıdır; "bu konu nasıl anlatılır" kartı değildir. Taslaktaki D2 için konu özeti,
terim notu ve onay alanları sıfırdan yazılacak. Dayanak serbest metin olduğu için ambar parçasına mekanik bağ da yok.

---

## 3. Kartların dayandığı kaynak ambarda ne durumda

Kaynak: `veri/AMBAR-ENVANTERI.md` (makine üretimi, 09.11.2026 18:39): 2.828 tekil kaynak, 2.376'sı TAM, 412'si DELİK-İNCELE.

### Bitirme kartları, ders ders

| Ders | Kart | Standart atıflı kart | Standardı TAM | Standardı delikli | Teori notuna dayanan kart |
|---|---:|---:|---:|---:|---:|
| Muhasebe Denetimi | 44 | 28 | 28 | 0 | 0 |
| Maliyet Muhasebesi | 18 | 9 | 9 | 0 | 5 |
| Finansal Muhasebe | 47 | 17 | 16 | 1 (TMS 1) | 28 |
| Finansal Tablolar ve Analizi | 22 | 8 | 4 | 4 (TMS 1) | 19 |
| Vergi Mevzuatı ve Uygulaması | 57 | 0 | — | — | 0 |
| Hukuk | 57 | 0 | — | — | 0 |
| Meslek Hukuku | 29 | 0 | — | — | 0 |
| Sermaye Piyasası Mevzuatı | 35 | 0 | — | — | 2 |

"Standart atıflı" = dayanağında BDS / TMS / TFRS / KKS numarası geçen kart. Kanuna dayanan kartlar bu sütunlarda ölçülmedi.

### Ana kanunların envanterdeki durumu

| Kanun | Parça | Durum |
|---|---:|---|
| VUK (213) | 586 | DELİK-İNCELE (par 429 · kesik 29) |
| GVK (193) | 381 | DELİK-İNCELE (par 118 · kesik 37) |
| KVK (5520) | 206 | DELİK-İNCELE (öksüz 1) |
| KDVK (3065) | 169 | DELİK-İNCELE (par 2 · kesik 4 · öksüz 1) |
| TTK (6102) | 1.596 | DELİK-İNCELE (par 20 · kesik 2 · öksüz 2) |
| TBK (6098) | 652 | DELİK-İNCELE (par 1) |
| SGK (5510) | 556 | DELİK-İNCELE (par 5 · öksüz 8) |
| Sermaye Piyasası K. (6362) | 269 | DELİK-İNCELE (par 4) |
| İş K. (4857) | 153 | DELİK-İNCELE (par 18 · kesik 1 · öksüz 2) |
| AATUHK (6183) | 163 | DELİK-İNCELE (par 2 · kesik 4) |
| Teori notları (grup) | 599 | DELİK-İNCELE (par 494 · kesik 5) |
| 3568 sayılı Kanun | — | Envanterde bu adla eşleşmedi; ÖLÇÜLMEDİ |

**Okuma:**
- Vergi, Hukuk ve Sermaye Piyasası kartlarının dayandığı ana kanunların hepsi "incele" işaretli. Hangi maddenin kesik olduğu bu ölçümde
  kart düzeyine indirilmedi.
- Finansal Muhasebe (47 kartın 28'i) ve Finansal Tablolar (22 kartın 19'u) resmî metne değil **teori notuna** dayanıyor; teori notları
  grubu da "incele" işaretli. "Yalnız resmî kaynaktan" isteği (A-05) bu iki derste bugünkü kartlarla karşılanmıyor.
- **Muhasebe Denetimi** en temiz ders: standart atıflı 28 kartın 28'inde standart TAM, teori notuna dayanan kart yok, paragraf atfı için
  mekanik kapı (KAPI-BP) kurulu. Kalan 16 kart yönetmelik maddesine dayanıyor (Bağımsız Denetim Yönetmeliği envanterde 82 parça, TAM;
  16 kartın tamamı tek tek eşlenmedi). Zayıf yanı: 44 kartın 23'ünde kalıp tahmini.

---

## 4. Öneri

1. **Kanıt dalgası dersi: Muhasebe Denetimi.** Standart atıflı 28 karttan, kalıbı tahmini olmayanlar öne alınarak 20 kart seçilir.
2. Dalgadan önce (0 USD): seçilen 20 kartın konu özeti, terim notu ve "böyle düşürürler" satırı ambardaki standart metninden yazılır;
   her atıf parça kimliğine bağlanır; kart onaya sunulur.
3. Üç yapısal açık (çözüm tablosu hakemde yok · ölçekli tekrar denetimsiz · yayın anı dönüştürmesi hakemden sonra) kanıt dalgasında
   **kapatılmadan** ölçülemez: dalga sorularında ölçekli tekrar kapalı tutulur, çözüm tablosu hakem istemine eklenir, yayın sonrası metin
   ambar metniyle karşılaştırılır. Bu üçü kod değişikliğidir; ayrı onayla yapılır.
4. Vergi ve Hukuk için basım, ana kanunlardaki "incele" işaretleri kart düzeyine indirilip kapatılmadan açılmamalı.
