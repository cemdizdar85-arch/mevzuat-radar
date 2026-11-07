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

## 4 · Rapor (her dalga)
Okunan · TEMIZ · indirilen · onarılan · sitede ölçülen · BELİRSİZ · sağlama yakalama oranı · hak/USD (ayrı).

## Sıra
Bitirme (sitede açık, çok çözülen önce) → Yeterlilik Son 20 Gün → SGS → KGK. Basım freni bu düzen bitene kadar kapalı (Cem 07.11).
🚫 GÖRMEZ: iki okuyucunun aynı yanılgıya düşmesi (sağlama ölçer, sıfırlamaz) · ambarda olmayan kaynak · site dışı yüzeyler (ses, video, çizim).
