# BASIM ÖNCESİ DÜZEN — TASLAK (10.11.2026)

> ⚠ **TASLAK. Cem onaylamadan bağlayıcı değildir.** `SORU-URETIM-SOZLESMESI.md`'ye girmedi; hiçbir kapı, hiçbir
> betik bu dosyaya göre değişmedi. Basım freni (07.11) yerindedir.
> İstek listesi: [`veri/sinav/CEM-ISTEK-LISTESI-1011.md`](veri/sinav/CEM-ISTEK-LISTESI-1011.md).

---

## 1. Neden hâlâ hatalı soru çıkıyor

**Kural eksik değil. Her soruda çok fazla serbest metin yazdırılıyor.**

| Bulgu | Kaynak |
|---|---|
| Depoda 70'ten fazla ayrı `KAPI-…` adı ve sözleşmede B1–B35 var; hata yine çıkıyor | 10.11 depo sayımı (`git grep`), sözleşme Bölüm B |
| Aynı teşhis 03.08'de yazılmış: "kural istemde dilek, çıktı ölçülmüyor". O günden beri her şikâyete bir kapı eklendi | `KALITE-KAPILARI.md` §1–2 |
| Üretici her soru için konu özeti, terim notu, hap, taktik, ikiz, adımlar, sade, teşhis ve yevmiyeyi baştan yazdırıyor | `motor/kalip-parti-uret.ps1` |
| Anahtarlar %99'dan fazla doğru; kusur anlatım katmanında | Sözleşme B24 (03.10 okuması) |
| Yeterlilik Son 20 Gün 1. denemede 160 sorunun 140'ında kusurlu konu özeti, cevap hatası 0 | 10.11 brifi (yeniden ölçülmedi) |
| Kapı yalnız öğretildiği hata sınıfını görür; S6, S7, S8, A4 için SGS/SMMM'de ve bulutta kapı yok | Sözleşme Bölüm C |

Sonuç: aynı konu 50 soruda 50 kez yeniden anlatılıyor; her anlatım ayrı hata fırsatı. Hata yüzeyi = soru sayısı × alan sayısı.
Yeni kapı eklemek bu çarpımı küçültmez.

**Ölçülmeyen:** hangi kök nedenin kaç hata ürettiği ambardan sayılmadı. Yukarıdaki sıralama önceki oturumların notlarına dayanır.

---

## 2. Düzen — dokuz madde, her birinin ölçüsüyle (B31)

| No | Kural | Ölçü (kim, neyle, geçme şartı) |
|---|---|---|
| **D1** | **Soru başına model yalnız şunu yazar:** kök, beş şık, anahtar, her şıkkın tek cümle nedeni, hesap sorusunda adımlar. Başka alan yazdırılmaz. | Mekanik: parti dosyasında izinli alan listesi dışında alan varsa parti düşer. |
| **D2** | **Konu kartı = doğrulanmış ders notu.** Konu özeti, terim notu, madde atfı, hesap kodu, "bu konuda böyle düşürürler" satırı konu başına **bir kez** yazılır, resmî metinle karşılaştırılır, onaylanır, kilitlenir. Soru bunları karttan çeker. | Kartta `onay` (kim, tarih) ve her atıf için ambar parça kimliği. Onaysız kart = basılamaz konu. |
| **D3** | **Kaynak kapısı en başta.** Kartın dayandığı madde ambarda yoksa, kesikse, mülgaysa ya da resmî kaynaktan yutulmadıysa o konu basılmaz; "basılmadı: neden" listesine düşer. | Mekanik, 0 USD, plan kurulurken. Çıktı: basılabilir konu sayısı / toplam, basılmayanların nedeni. |
| **D4** | **Kanun değişince kart kırmızıya döner**, karta bağlı sorular yayından iner, kart yeniden onaylanınca geri gelir. | Kanun değişikliği nöbeti kartın parça kimliğine bağlanır. Bugün bağlı DEĞİL (sözleşme Bölüm C, B28 satırı). |
| **D5** | **Yıl parametresi.** Yıllık tutarı olan hesap sorusunda tutar soruya gömülmez; `yillik-tutarlar.json` anahtarıyla tutulur. Doğru cevabı ve çeldirici tutarlarını kod hesaplar. Yıl değişince tek komutla çevrilir. | Mekanik: çevrimden sonra her sorunun anahtarı yeniden hesaplanır; iki şık eşit çıkarsa soru iner. |
| **D6** | **Hakem ölçülür.** Elle doğrulanmış kusurlu ve temiz sorulardan sabit sınama seti kurulur; her hakem bu setle sınanır. | Yakalama oranı ve yanlış alarm oranı sayıyla yazılır. Oranı bilinmeyen hakem yayın şartı sayılmaz. Eşik Cem kararı. |
| **D7** | **Anlatım standardı tek sayfa.** Önce seçilen şıkkın neden yanlış olduğu tek cümle, sonra tek görselde çözüm, sonra kısa yol; kanun maddesi isteğe bağlı açılır. | Muhasebe bilmeyen bir okuyucu okur; anlamadıysa geçmez. Mekanik ölçüsü yok: "ÖLÇÜLMÜYOR — yalnız insan okuması". |
| **D8** | **Her dalga yayından önce bağımsız okunur.** Okuyan, yazan oturum değildir. | Hedef: yanlış öğreten 0 · kusurlu en çok %5 · düşen soru en çok %10. Tutmazsa dalga yayına girmez, büyütülmez. |
| **D9** | **Eski banka yeniden basılmaz, karta bağlanır.** Kök, şık, anahtar kalır; soru başına yazılmış özet ve terim notu karttakiyle değişir. | Bağlanan soru sayısı / toplam; bağlanamayan (kartı olmayan konu) ayrı listelenir. |

**Resmî metni olmayan konu (Cem kararı 10.11.2026):** oran analizi, dikey analiz, trend analizi gibi resmî düzenlemesi bulunmayan
konularda kaynak, **çıkmış sınav sorusu ve komisyon cevabıdır**. Kart her kuralın ve formülün yanında dayandığı çıkmış soruyu
(dönem + soru no) yazar; teori notu tek başına kaynak sayılmaz. Hiçbir çıkmış soruda geçmeyen formül ya da tanım karta girmez, o
başlığa soru basılmaz. Ölçü: kartta her kuralın karşısında çıkmış soru atfı var mı (mekanik); atıf o kuralı gerçekten taşıyor mu
(bağımsız okuma). Bugün bu durumda 16 kart var: Finansal Tablolar ve Analizi 12, Maliyet Muhasebesi 4.

**Kanunu olmayan dersler (matematik, İngilizce, Türkçe):** matematikte cevabı kod hesaplar; dil derslerinde iki bağımsız
çözücü aynı şıkkı bulmazsa soru basılmaz; kalıp yalnız çıkmış sorudan alınır.

**Kural tek yerde:** soru kuralı yalnız bu depoda yazılır. Oturum hafızasına kural yazılmaz, depodaki dosyaya işaret yazılır.
Bulgu, bulan oturumca aynı gün depoya düşülür.

---

## 3. Kanıt dalgası (Cem onayına bağlı)

| | |
|---|---|
| Kapsam | Tek ders · 20 konu kartı · 40 soru |
| Ders seçimi | Kaynağı ambarda en tam olan ders; D3 ölçümü söyler |
| Tavan | 25 USD (açıklama hakemi dahil). Beklenen bedel ölçülmedi; kaba tahmin 10–15 USD |
| Hedef | D8'deki üç sayı |
| Karşılaştırma | Aynı dersin son eski dalgası: düşen oranı, soru başı bedel, okumada kusur oranı |
| Sonuç kötüyse | Düzen büyütülmez; hangi maddenin tutmadığı yazılır |

Dalgadan önce 0 USD ölçüm: ekrana basılan alanların tam envanteri (hangi alan hangi kapıdan, hangi hakemden geçiyor) ve
seçilen dersin kartlarının kaynak durumu.

---

## 4. Verilen söz ve verilmeyen söz

**Verilmeyen:** "bir daha hiç yanlış soru çıkmaz". Hiçbir kapı ve hiçbir hakem için bu iddia kurulamaz
(`CLAUDE.md` → Kapı kurma kuralları: iddia, ölçülmüş vaka kadardır).

**Verilen:**
1. Kartı onaysız konuya soru basılmaz; basılmayan konu Cem'e listelenir.
2. Ölçülmemiş soru yayına girmez; her dalganın üç sayısı Cem'e gösterilir.
3. Hata çıkarsa tek soru değil sınıfı kapanır: soru aynı gün iner, aynı karta bağlı bütün sorular taranır.
4. Hata oranı panelde durur; "uydum" denmez, sayı gösterilir.

---

## 5. Bu taslağın görmedikleri

- Kart da yanlış yazılabilir. Kart hatası bağlı bütün soruları etkiler; bu yüzden kart onayı bu düzenin en pahalı ve en önemli adımıdır.
- Hesap sorularında adımlar hâlâ soru başına yazılır; D5 yalnız parametreli sorularda kod hesabı getirir.
- Konu özeti soruya özel olmayınca, soruya özel ipucu isteyen öğrenci için şık açıklaması tek dayanak kalır.
- Kaç konu kartı gerektiği (SGS, Yeterlilik, KGK toplamı) ÖLÇÜLMEDİ; bitirmede 309 kart var.
