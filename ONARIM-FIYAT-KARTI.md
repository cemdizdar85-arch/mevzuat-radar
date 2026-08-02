# ONARIM FİYAT KARTI — 02.08.2026

> ## 🔴 DÜZELTME 2 (02.08 gece geç) — "ÖNCE ELEME, PARALI İŞ KÜÇÜLÜR" GEREKÇESİ ÇÜRÜDÜ
>
> Bu kartın her yerinde şu gerekçe vardı: *"3.821 mükerrer soru elenirse Doğrusu/tablo
> maliyeti de düşer, o yüzden önce bedava eleme."* **Bu gerekçe geçersiz.**
>
> Eleme motoru koşturuldu, uygulamadan önce örnekler gözle okundu: **gerçek birebir
> mükerrer sayısı 0.** Tarama parmak izini *"kaynak + doğru şıkkın rakamsızlaştırılmış
> ilk 80 karakteri"* diye kuruyor — yani **soruyu değil cevabı** ölçüyor ve **rakamları
> siliyor.** Aynı maddeye dayanan, aynı cevabı olan ama bambaşka senaryolu sorular kopya
> sanılmış. (Kanıt ve örnekler: `MUKERRER-BULGUSU.md`.)
>
> | Sanılan | Gerçek |
> |---|---|
> | 2.969 soru elenecek, paralı iş küçülecek | **0 soru elendi, paralı iş tam boyunda** |
> | Kasa 27.478 → ~24.500 | Kasa **27.478** olarak kalıyor |
>
> **Bunun fiyata etkisi:** aşağıdaki paketlerin **kapsamı küçülmüyor.** Paket C hâlâ tüm
> 27.478 soruyu kapsıyor. (Yine de C'nin fiyatı 168 değil ~60-70 USD — o düzeltmenin
> sebebi ayrı, bir alttaki blokta.)
>
> **Gerçek sorun eleme değil KONU YIĞILMASI:** VUK m.275'te 186 soru var. Bu mükerrerlik
> değil dağılım bozukluğu; ilacı silmek değil **kota**. Ayrı iş olarak defterde.

> ## 🔴 DÜZELTME 1 (02.08 gece) — TAHMİNİM 3,5 KAT YÜKSEKMİŞ
> Aşağıdaki tabloları yazarken "Doğrusu" kalemini **81 USD** diye tahmin etmiştim (katsayı uydurmuştum).
> Meğer `motor/dogrusu-ekle.ps1` **bu sabah 07:50'de ölçüm yapmış** ve gerçek birim maliyeti hesaplamış:
>
> | Ölçülen | Değer |
> |---|---|
> | Kasa | 26.992 soru |
> | "Doğrusu:" cümlesi **olan** | **0** — hiçbirinde yok |
> | Eksik | 26.991 |
> | **TÜM KASAYA "Doğrusu" eklemenin maliyeti** | **22,94 USD** *(ölçülmüş birim: ~3.000 giriş + ~250 çıkış token/soru, Haiku batch fiyatı)* |
> | Hesap sorusu | 11.984 |
> | Hesap sorusu olup tablo/yevmiye verisi **olmayan** | **10.350** |
> | Yevmiye verisi olan / tablo verisi olan | 994 / 2.426 |
>
> **Sonuç: Paket C (tam kasa) 168 USD değil.** ~~~60-70 USD bandında~~ → bu bant da eksikti;
> yalnız "Doğrusu" kalemini düzeltmiş, tablo ve hakem kalemlerini eski uydurma katsayıda bırakmıştım.
> **Hepsi ölçülmüş birime çekilmiş hâli: ≈88 USD** — 3. bölümdeki C tablosuna işlendi.
> **Ders:** kendi katsayımı uydurmuşum; scriptin ölçülmüş birimi varmış. Rakam disiplini burada da geçerli —
> tahmin yapmadan önce "bunu ölçen bir şey var mı" diye bak.


**Cem'in kuralı:** "Paralı işlemi bir kez çalıştırıp bırakalım." · "Paralıdan önce tüm yutma."
**Bu kart ne için:** Tek paralı koşuya girmeden önce **ne kadar iş var, ne kadar tutar** — rakamla.

---

## 1. ÖLÇÜM — kasada ne var (tahmin değil, sayım)

Kaynak: `veri/onarim-tarama.json` (02.08.2026 12:49, taranan **26.992** soru; kasa o günden beri 27.478'e çıktı).

| Kod | Sorun | Adet | Nasıl düzelir |
|---|---|---|---|
| T1 | ~~Mükerrer soru (852 grup)~~ **YANLIŞ ÖLÇÜM** | ~~3.821~~ → **0** | **İŞ YOK** — ölçüldü, birebir mükerrer çıkmadı; 2.969'u kasada kalıyor (`MUKERRER-BULGUSU.md`) |
| T2 | Ders/konu etiketi yanlış | **1.414** | **BEDAVA** — sözlük tabanlı remap robotu var |
| T3 | Konu etiketi ilgisiz | **4.087** | Yarı bedava — kalanı paralı |
| T5 | ASCII bozuk metin | **165** | **BEDAVA** — deterministik |
| T6 | İstem artığı | **2** | **BEDAVA** |
| T7 | Mülga rejim (götürü usul vb.) | **44** | Paralı — yeniden yazım |
| T8 | Homoglif | **13** | **BEDAVA** — 98'i zaten düzeltildi |
| T9 | Hesap/tablo gerektirip tablosu boş | **8.877** | **Paralı** — tablo + yevmiye üretimi |
| T10 | Yasaklı/küçümseyen dil | **72** | Paralı — yeniden yazım |
| T11 | "Doğrusu:" cümlesi eksik | **26.991** soru / **108.354** açıklama | **Paralı — en büyük kalem** |

**Ayrıca insan okumasından:**
- 500-okuma: **11 kesin yanlış** + **12 riskli** + **104 düzeltilir** (hepsi yayından çekildi)
- **TTK 482 / ıskat kümesi: 448 soru** — üretici sistematik hata yapmış, m.482+483 birlikte verilerek yeniden üretilmeli
- Dayanak çözülemeyen: kasanın **%11,5'i** (dayanak-kapsam v2: %88,5 çözülüyor)

---

## 2. MALİYET TABANI — nereden hesaplıyorum

**Tek gerçek ölçümümüz:** 27.07'de K2 (Karşıt-Profesör) koşusu **1.400 soruyu** Haiku ile yargıladı, fatura **≈1,5-2 USD** → **soru başına ≈0,0011-0,0014 USD** (yargı tipi çağrı, kısa çıktı).

Yazma işleri daha uzun çıktı üretir. Tahmin katsayıları (**TAHMİN — ölçülmedi, işaretli**):
- Yargı/etiket tipi çağrı: **~0,0013 USD/soru** *(ölçüldü)*
- Kısa yazma (Doğrusu cümlesi, dil düzeltme): **~0,003 USD/soru** *(TAHMİN, 2× katsayı)*
- Uzun yazma (tablo + yevmiye, yeniden üretim): **~0,005 USD/soru** *(TAHMİN, 4× katsayı)*

> Bu katsayılar tahmindir. İlk 200 soruluk pilot koşuda gerçek fatura ölçülüp kart güncellenecek — böylece büyük parti gerçek rakamla basılır.

---

## 3. ÜÇ PAKET — sen birini seç

### 🟢 PAKET A — "Önce kanı durdur" *(ÖNERİM)*
Sadece **yanlış olan** ve **yayına engel** olanlar.

| Kalem | Adet | Tahmini |
|---|---|---|
| 500-okuma kesin yanlış + riskli + düzeltilir | ~127 | 0,4 USD |
| TTK 482 kümesi yeniden üretim | 448 | 2,2 USD |
| T10 yasaklı dil + T7 mülga rejim | 116 | 0,4 USD |
| Hakem yeniden yargılama (onarılanlar) | ~700 | 0,9 USD |
| **TOPLAM** | **~1.400 soru** | **≈ 4 USD** |

**Sonuç:** bildiğimiz her yanlış kapanır. Yayına açılabilir temiz çekirdek doğar.

### 🟡 PAKET B — "İlk yayın partisi" *(A + ilk 5.000 sorunun cilası)*

| Kalem | Adet | Tahmini |
|---|---|---|
| Paket A | ~1.400 | 4 USD |
| "Doğrusu" cümlesi — ilk 5.000 soru | 5.000 | 15 USD |
| Tablo backfill — hesap sorularının ilki | 3.000 | 15 USD |
| Hakem yeniden yargılama | 8.000 | 10 USD |
| **TOPLAM** | **~8.000 soru** | **≈ 44 USD** |

**Sonuç:** 5-8 bin soruluk, dört dörtlük, satılabilir bir banka.

### 🔴 PAKET C — "Tam kasa"

**Ölçülmüş birime göre yeniden hesaplandı** (eski 168 USD, uydurma katsayıyla yazılmıştı):

| Kalem | Adet | Tutar | Dayanağı |
|---|---|---|---|
| Paket A | ~1.400 | 4 USD | tahmin |
| "Doğrusu" — tüm kasa | 27.478 | **23,4 USD** | **ÖLÇÜLDÜ** — 0,00085 USD/soru (`dogrusu-ekle.ps1`, 02.08 07:50) |
| Tablo + yevmiye backfill | 8.877 | ~22 USD | tahmin — ölçülen birimin 3 katı (çıktı daha uzun) |
| T3 konu etiketi (kalan) | ~2.000 | 3 USD | tahmin |
| Hakem yeniden yargılama | 27.478 | 36 USD | **ÖLÇÜLDÜ** — 0,0013 USD/soru (K2 koşusu, 27.07) |
| **TOPLAM** | **~27.500 soru** | **≈ 88 USD** | |

> **Düzeltme 1'deki "~60-70 USD" bandı da düşük kalmış.** Orada yalnız "Doğrusu" kalemini
> düzeltmiş, tablo ve hakem kalemlerini eski uydurma katsayıyla bırakmıştım. Hepsi ölçülmüş
> birime çekilince gerçek rakam **≈88 USD**. İki kalem hâlâ tahmin — pilot faturası gelince kesinleşir.

---

## 4. BENİM ÖNERİM: A → ölç → B

**Neden C değil:** ~~mükerrer eleme sonrası kasa zaten küçülecek~~ — **bu gerekçe çöktü, kasa küçülmüyor** (yukarıdaki Düzeltme 2). Geriye kalan iki gerekçe hâlâ ayakta ve tek başlarına yeterli:

1. **Konu yığılması.** VUK m.275'te 186, TTK 482 kümesinde 448 soru var. Bir maddeye 186 soru cilalamak parayı öğrenciye değil tekrara harcamaktır. Önce kota konsun, sonra kalanı cilalansın.
2. **Sıra.** A'nın gerçek faturası görülmeden C'nin tahmini rakamına 60-70 USD basmak, ölçmeden harcamaktır — Düzeltme 1'de tam bu yüzden 3,5 kat sapmıştım.

**Neden A ile başla:** 4 dolara bildiğimiz bütün yanlışlar kapanır. Bu, "sıfır yanlış" iddiasının bedeli — ve çok ucuz.

**Sonra:** A'nın gerçek faturası görülünce tahmin katsayıları gerçek rakamla değişir; B'yi o zaman **kesin fiyatla** basarız.

---

## 5. ÖNCE BİTMESİ GEREKENLER (paralıdan önce)

- [x] Yutma duvarı — **açıldı** (ambar 21.860 belge, +2.363)
- [ ] Manifest başındaki 5 kaynak (4 yapılandırma kanunu + Bağımsız Denetim Yönetmeliği) — koşuda
- [x] Şık dağılımı dengelendi (19.862 soru)
- [x] Kirli sorular yayından çekildi (466)
- [x] ~~T1 mükerrer eleme~~ — **ölçüldü, iş çıkmadı** (gerçek mükerrer 0; motor kurulu ve rakam kapısı takılı, ileride gerçek kopya çıkarsa hazır)
- [x] **Dayanak kapısı düzeltildi** — kuru koşu 8.098 soruyu haksız atlıyordu: Yabancı Dil/Türkçe sorularının mevzuat dayanağı yok, olamaz da. Artık dayanak aranmadan geçiyorlar ama istem "hiçbir kanun/madde/oran atfı yapamazsın" diyor. İkinci kusur: etiketin tamamıyla arama ("TMS 1 … m.38" ambarda birebir yok) → artık etiketten çıkarılan kod aranıyor. **Bu, paralı partinin kapsamını BÜYÜTÜR** — daha az soru dayanaksız diye çöpe gider.
- [ ] **Kalan bedava onarımlar:** T2 etiket remap (1.414) + T5 ASCII (165) + T6 istem artığı (2) + T8 homoglif (13)

> **Sıra düzeltildi:** ~~"önce eleme, çünkü eleyeceğimiz soruya para vermeyelim"~~ — elenecek soru yok.
> Yeni gerekçe: **önce bedava düzeltmeler, çünkü aynı soruyu iki kez satın almayalım.** Etiketi yanlış
> veya metni bozuk bir soruya paralı açıklama yazdırırsak, etiket sonradan düzelince o parayı
> ikinci kez ödemek gerekir. Bedava iş 0 USD ve birkaç dakika; bekletmenin bedeli yok.

---

## 6. CEM'İN KARARI

- [ ] **A** — 4 USD, bildiğimiz yanlışlar kapansın
- [ ] **B** — 44 USD, satılabilir banka
- [ ] **C** — ~~168~~ **≈88 USD**, tam kasa
- [ ] Önce **pilot**: 200 soruluk gerçek fatura ölçümü (≈0,6 USD), sonra karar

*Rakamlar KDV/kur dalgalanmasına göre değişebilir; tahmin işaretli kalemler pilot sonrası güncellenecek.*
