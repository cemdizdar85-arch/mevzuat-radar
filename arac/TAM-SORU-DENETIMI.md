# TAM SORU DENETİMİ — her soruya bütün açılardan aynı anda bakan düzen (08.11.2026, Cem "herşeye bakan sistem kur")

Neden: her eski kontrol tek bir şeye bakıyordu (hakem: anahtar · özet denetimi: konu özeti · gece onarımı: anlatım). 08.11 kaynak bağı ölçümü
ilk kez "kaynak soruyu destekliyor mu" diye sordu ve 100 sitede soruda 3 desteklemeyen + 1 anahtar şüphesi buldu. Bu düzen hepsini tek geçişte yapar.
"Hata kalmadı" denmez; her raporda ölçülmüş kaçırma oranı yazılır.

## 0 · Ücretsiz ön tarama (önce, bütün banka)
`node arac/kalip-anlatim-kapisi.js --kasa`, `node arac/terim-kim-kapisi.js --kasa`, `arac/soru-kalite-kapisi.js`, ikiz ölçüsü (`arac/ikiz-olcusu.ps1`), konu-kalıp tablosu (B30/B31).
Bulgular soru kimliğine yazılır; okuyucuya ipucu olarak VERİLMEZ (kör kalsın), yalnız sonuç birleşiminde kullanılır.

## 1 · Her soru için iki bağımsız okuyucu (birbirini görmez, metnin kim tarafından yazıldığını bilmez)
Okuyucu sırayla yapar ve HER maddeye ayrı karar yazar:
1. **Kendi çözümü:** şıklara bakmadan çöz, sonra harf. Anahtarla aynı mı? Başka şık da savunulabilir mi?
2. **Kaynak:** bağlı kaynak soruyu destekliyor mu? Desteklemiyorsa doğru maddeyi ambar `dokumanlar` tablosundan KENDİN bul. Ambarda yoksa "KAYNAK YOK". Kaynak bağına körü körüne güvenme.
3. **Güncellik:** madde yürürlükte mi, tutar ve oran sınavın sorduğu yılın değeri mi (soru yılı = sınav yılı − 1).
4. **Rakam:** her ara rakamı yeniden hesapla.
5. **Şıklar:** tek doğru, çeldiriciler kendi hatasından gelir, ikinci doğru yok (BITIRME-SORU-STANDARDI §3).
6. **Ekrandaki her alan:** konu özeti, adımlar, teşhis, açıklama, sade, verilenler, kavramlar, yevmiye, ikiz, hap, taktik, dayanak başlığı. Kurallar: SORU-URETIM-SOZLESMESI B32–B35, hakem kural 1–10 (`arac/aciklama-hakemi-cekirdek.ps1`).
7. **Sınava benzerlik:** konu kartı, kök kalıbı, uzunluk (K1–K3); konu etiketi soruya uyuyor mu.
Çıktı JSON, soru başına: `{id, cozum, anahtar_dogru, ikinci_dogru, kaynak:{destekliyor, dogru_madde}, guncel, rakam, siklar, alanlar:[{alan, kusur, agirlik}], benzerlik, konu_etiketi}`.
`agirlik`: CEVAP_YANLIS · YANLIS_OGRETIR · KAYNAK_YANLIS · ZAYIF.

## 2 · Birleştirme ve karar (mekanik)
- İki okuyucu da anahtarı doğruladı ve hiçbir CEVAP_YANLIS / YANLIS_OGRETIR yok → TEMIZ.
- Biri CEVAP_YANLIS dedi → üçüncü okuyucu + resmî metin. Kesin yanlışsa HEMEN yayından indir (elle ret), aynı kimlikte düzelt, geri getir.
- YANLIS_OGRETIR / KAYNAK_YANLIS → onarım hattı (taslak son hâlden → iki kör → açıklama hakemi → teslim → yayın → sitede ölç).
- İki okuyucu çelişiyorsa ya da kaynak yoksa → karar verme, "BELİRSİZ" listesi, Cem'e.
- ZAYIF → onarım kuyruğu, soru yayında kalır.

## 3 · Kaçırma ölçümü (her dalgada, ŞART)
Her 50 soruluk dalgaya, okuyucunun bilmediği 5 SAĞLAMA sorusu karıştırılır: bilinen kusurlu eski hâller (yedeklerden, örn. `smmm-4k-a-yvergi-kolay-r4/kp-19` eski hâli) + 2 temiz soru.
Rapor: kusurlu sağlamanın kaçını yakaladı, temizin kaçına yanlış alarm verdi. Kaçırma > %10 ise dalga geçersiz, okuyucu talimatı düzeltilir.
**Sağlama seti `veri/sinav/tam-denetim-saglama.json`'dan alınır: 5 kusurlu (≥2 CEVAP_YANLIS, ≥2 YANLIS_OGRETIR) + 2 temiz** (08.11, Cem "1.3 yap").
Dalga 1 dersi (08.11, ölçüldü): 5 sağlamanın 3'ü YANLIŞ ETİKETLİYDİ — (1) "yanlıştır" kökünde anahtarın yanlış ifadeyi taşıması
"anahtar yanlış" sanıldı (elle ret gerekçesinden alındı, kök okunmadı); (2) iki "temiz" yalnız hakem/AH kaydından seçildi, ikisi de kusurlu çıktı.
Kural: kusurlu sağlama BUGÜNKÜ kayıtta yeniden okunur (elle ret gerekçesi bayat olabilir), temiz sağlama açıklama alanlarıyla birlikte okunmuş olur.
Geçerli kusurlu sağlama 2'nin altındaysa kaçırma oranı **"ölçülmedi"** yazılır.

**Okuyucu talimatı tek yerde: `arac/TAM-DENETIM-OKUYUCU.md`** (sürüm 3: olumsuz kök + kapanış ✓/✗ kuralı, B33 `kim` / gündelik benzetme ZAYIF tavanı, yalnız ekranda görünen alan).
**Okuyucudan sonra DOĞRULAYICI (2b):** onarım adayının her iddiası ayrı bir ajana resmî metinle yargılatılır (GERCEK / YANLIS_ALARM / BELIRSIZ + onarım cümlesi); doğrulayıcıya da sağlama iddiası karıştırılır (gerçek kusur + bilinen yanlış alarm). Onarım listesine yalnız GERCEK ve ZAYIF olmayan iddia girer.

**Ölçülen (08.11, Cem "1.2.3 üçünü de yap"):**
- Dalga 1 + 2 (90 bitirme sorusu, en çok çözülen): anahtar yanlış 0 · doğrulanmış onarım 24 + 21 = 45 · okuyucu sağlaması d1 4/4 (geçerli 2 soru), d2 9/10 (kaçırma %10, sınırda) · temiz kontrolde yanlış alarm 0/8 okuma · doğrulayıcı sağlaması 8/8 + 8/8.
- **`teori_ikiz` ve `notlandirici` siteye gitmez** (`paket_soru.veri`'de yok, 3 site kaydıyla ölçüldü); hesap ikizi `ikiz` ekranda "oyun"dur. Dalga 1'in 5 "onarım"ı yalnız bu görünmeyen alandaydı → çıkarıldı.
- **Açıklama hakemi (bugünkü kural 1–10) ölçümü** (9 soru, 0,38 USD, `arac/aciklama-hakemi.ps1`): 01.11 öncesi TEMIZ almış 6 görünür-kusurlu sorunun 6'sına KUSURLU dedi (5'inde bilinen kusuru gösterdi), 3 temiz kontrolün 3'üne alarm verdi
  (gerekçe çoğunlukla B33 `kim` / 9c gündelik benzetme — hakemde KUSUR, okuyucuda ZAYIF; bu bilerek: yeni üretim katı, eski banka önceliklendirilir).
  ⚠ Hakem kaynak metnini yalnız `kaynak_metin_ozet`'ten alır; örneklemin 9 kaydının 6'sında bu alan BOŞTU → hakem kaynaksız karar verdi. Ölçümde maxTok 1600 4/9 kesti; üretim değeri 3200.
- Kusurların basım tarihi: dalga 1'in 29 adayının 20'si 16–30.09 (açıklama hakemi öncesi), 9'u 30.10–01.11 (kural 5–10'dan önce TEMIZ almış). Eski banka zorunlu yeniden taranmıyor — bu düzen o boşluk için.

## 4 · Rapor (her dalga)
Okunan · TEMIZ · indirilen · onarılan · sitede ölçülen · BELİRSİZ · sağlama yakalama oranı · hak/USD (ayrı).

## Sıra
Bitirme (sitede açık, çok çözülen önce) → Yeterlilik Son 20 Gün → SGS → KGK. Basım freni bu düzen bitene kadar kapalı (Cem 07.11).
🚫 GÖRMEZ: iki okuyucunun aynı yanılgıya düşmesi (sağlama ölçer, sıfırlamaz) · ambarda olmayan kaynak · site dışı yüzeyler (ses, video, çizim).
