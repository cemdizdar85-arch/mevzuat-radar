# ONARIM FİYAT KARTI — 02.08.2026 · 🆕 25.08 ÖRNEKLEM · 🏁 26.08 PİLOT SONUCU + MODEL KARARI

> ## 🏁 26.08.2026 — PİLOT 200 KOŞTU, MODEL KARARI VERİLDİ: **SONNET 5** (Cem: "hangi model karar ver")
>
> **Pilot:** aynı 100 soru (ince dersler ağırlıklı, tohum 20260826) × 2 model = 200 çağrı, 0 hata,
> hepsi birincil Anthropic hattı. Gerçek fatura: **$6,2** (Sonnet kesilen 86'nın 3.500 tavanla
> tekrarı dahil; ilk $4 tahmini aşıldı çünkü Sonnet ölçülen çıktısı ~2.800 tok/soru — tahminin 3,5 katı).
>
> **Kör kıyas (75 çift, 2 bağımsız hakem, model adları gizli, sıra çift başına rastgele):**
> SONNET 59 üstün / HAIKU 8 / eşit 8 · puan 857-753 · kritik kusur S:8 H:11.
> Haiku'yu düşüren: anlamı bozan Türkçe ("vergiden kaçınar", "duruşlama") + uydurma rakam türetimi
> — tam da 25.08 örnekleminin ana kusur sınıfları. Sonnet'in kusurları yapısal/şablon (istemle düzelir).
>
> **KARAR: Ana cila partisi SONNET 5 + batch (1 Eylül) + REVİZE İSTEM.** İstem revizyonları (pilottan):
> (1) özlülük emri — "her şık açıklaması ortalama 60-90 kelime; şişkinlik merit değil" (ölçülen 2.800 tok
> çıktıyı ~1.600-1.800'e çeker); (2) "Hangisi YANLIŞTIR/çıkarılamaz" soru tipinde şablonun TERS kurulması
> kuralı (Hakem B: no 44/71 deseni); (3) çıktı JSON şema kapısı (alan kaçağı %5-25 ölçüldü — bozuk yapı
> otomatik yeniden istenir); (4) MaxTok 3500.
>
> **GÜNCEL FİYAT (ölçülen birimlerle, Sonnet batch post-intro $1.5/$7.5):**
> | Kalem | Adet | Tutar |
> |---|---:|---:|
> | A. Cila — Sonnet batch, revize istem (giriş ~2.8k, çıkış hedef ~1.8k tok) | 12.539 | **$220-290** (özlülük emri tutarsa alt bant) |
> | B. Cevap-şüphelisi yeniden üretim | ~1.700 | $79 |
> | C. Hakem (Haiku) | 12.539 | $10 |
> | D. Havuz dışı "Doğrusu:" (Haiku batch — hakem verisi Haiku'yu tek-cümle işte yeterli gösteriyor) | 10.366 | $22 |
> | **TOPLAM ANA PARTİ** | | **≈ $330-400** |
>
> Not: Haiku-cila yolu ($104) FİYAT olarak cazipti ama kör kıyas kalitede sınıfta bıraktı (8/75) —
> ucuz yol, %70 kusuru başka kusurla değiştirmek olurdu. Karar verildi, pazarlık kapandı.
> **Pilot yan bulguları:** bir soruda mevzuatta olmayan merci şüphesi (no 62, "Yüksek Disiplin Kurulu"
> — soru-düzeyi inceleme listesine alındı) · pilot çıktıları veri/fabrika/pilot-cila-20260826.json
> (75 geçerli Sonnet cilası ana partide YENİDEN ürettirilmez, denetimden geçirilip kullanılır).

> ## 🆕 25.08.2026 GECE — "%70 KUSUR" PARTİSİNİN MALİYETİ (Cem: "maliyeti çıkar")
>
> **Dayanaklar:** birim boyutlar 50'lik örneklemden ÖLÇÜLDÜ (soru+şık+açıklama+hap
> ort. 2.687 karakter ≈ 900 token; cila girişi ≈ 3.500 token istem+madde dahil, çıkışı ≈ 800).
> Model fiyatları güncel liste: Haiku 4.5 $1/$5 · Sonnet 5 $3/$15 (⚠️ tanıtım $2/$10
> **31.08'de bitiyor**) · batch her zaman %50. Çapa ölçümler: dogrusu-ekle 02.08
> (3.000+250 token/soru) · K2 hakem 27.07 (~$0,0013/soru) · üretim planı 24.08 (1.680 soru ≈ $52).
>
> | Kalem | Adet | ŞİMDİ (OpenRouter, batch yok, tanıtım fiyatı) | 1 EYLÜL (Anthropic batch, tanıtım bitmiş) |
> |---|---:|---:|---:|
> | A. Aday havuz cilası — açıklama katmanı yeniden yazımı (4 parça + tuzak adı + Doğrusu + kendi rakamını üreten çeldirici) | 12.539 | Sonnet ≈ **$188** / Haiku ≈ $94 | Sonnet ≈ **$141** / Haiku ≈ $47 |
> | B. Cevap-şüphelisi yeniden üretim (K13 aritmetik 1.302 + kalıplı 129 + dengesiz 87 + GM kusurlu 53 + iç-monolog 104, çakışma payıyla ~1.700) | ~1.700 | ≈ **$105** | ≈ **$79** |
> | C. Hakem yeniden yargılama (onarım sonrası tüm aday havuz, Haiku) | 12.539 | ≈ $20 | ≈ **$10** |
> | D. (Opsiyonel, havuz BÜYÜTME) "Doğrusu:" ekleme — havuz DIŞI K5 ihlalliler | 10.366 | ≈ $44 | ≈ **$22** |
> | **A+B+C (Sonnet yolu — ÖNERİM)** | | **≈ $313** | **≈ $230** (+%5 aracı payı ≈ $240) |
> | A(Haiku)+B+C ucuz yolu | | ≈ $219 | ≈ $136 |
>
> **Öneri: 200 soruluk PİLOT ŞİMDİ (~$3-4, OpenRouter Sonnet) → çıktıyı okuyucular denetler,
> gerçek birim fatura ölçülür → ana parti 1 EYLÜL'de Anthropic batch ile (~$230-240).**
> 6 gün beklemenin kazancı ≈ $80. Cila modelini Haiku'ya düşürmek $94 kazandırır ama
> örneklem kusurlarının türü (uydurma türetim, kaynak teyidi) muhakeme istiyor — pilot
> iki modeli de 100'er soruyla deneyip kararı VERİYLE verdirebilir.
> *(A/B/C/D türetilmiş tahmindir — ölçülü birimlerden hesaplandı, pilot faturası kesinleştirir.)*

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
