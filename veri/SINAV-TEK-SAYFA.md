# SINAV TEK SAYFA — üç sınavın tek doğru sayfası

> Üretim: **26.09.2026 20:45** (makine; elle düzenlenmez — motor/sinav-tek-sayfa.ps1, günlük robot). Makine hâli: veri/sinav-tek-sayfa.json
> **KURAL:** Sınavla ilgili "var mı / kaç tane / eksik ne" sorusunun TEK cevabı bu sayfadır. Başında **⚠** olan satırın girdisi bayat (> 7 gün) ya da kırıktır: o sayı **ölçülmedi** sayılır, önce girdisi tazelenir (bölüm 5).
> Bu sayfa hiçbir şeyi kendisi ölçmez; ölçüm robotlarının çıktılarını birleştirir ve her sayının yanına kaynağını + tarihini yazar.

| Cem'in sorusu | Bölüm |
|---|---|
| Hangi sınavda hangi dersler var, her dersten kaç soru çıkıyor? | 1 |
| Çıkmış sınav soruları ders ders / konu konu ne diyor? | 2 |
| Bastığımız sorular yeterli mi? | 3 |
| İndirdiğimiz mevzuat ne durumda? | 4 |
| "İndirdik mi indirmedik mi" karmaşası nasıl biter? — girdi sağlığı | 5 |
| Çıkmış sorulara göre yutmadığımız mevzuat var mı? | 6 |
| Basmamız gereken sorular neler? | 7 |

## 1 · SINAVLAR VE DERSLER (resmî liste × kasadaki sorumuz × onaylı kota)

Kaynak: ders listesi = veri/ders-profili.json (TESMER Yönergesi m.6.2 / KGK ilanı / SPL) · **sitede** = kilitli kasa paket_soru (siteye giden soru) · eski havuz = soru_havuzu (Cem kararı: sayılmaz) · ikisi de veri/kasa-sayim.json (26.09.2026 13:45) · kota = üç kota dosyası (bölüm 5).

### STAJA BAŞLAMA (SGS) — 15 ders · **sitede 4.771** · kota 1.885 · eksik 83 (kapsama: hedef − sitede, konu konu)
Eski havuz (soru_havuzu — **kullanılmaz, Cem kararı**; sitede yok): 15.827 soru

| Ders | Bölüm | Sınavda soru | **Sitede** | Eski havuz | Kota | Eksik (kota − eski havuz) | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---:|---|
| Turkce | Genel Kultur ve Yetenek | 7 | 154 | 928 | 104 | 9 | %91 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Matematik | Genel Kultur ve Yetenek | 8 | 449 | 211 | 141 | 16 | %89 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Ataturk Ilkeleri ve Inkilap Tarihi | Genel Kultur ve Yetenek | 5 | 164 | 114 | 48 | 6 | %88 | ONAYLI (Cem 01.09) |
| Yabanci Dil | Yabanci Dil | 10 | 329 | 1.531 | 261 | 5 | %98 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Finansal Muhasebe | Alan Bilgisi | 26 | 1.099 | 4.309 | 416 | 7 | %98 | ONAYLI (Cem 01.09) |
| Maliyet Muhasebesi | Alan Bilgisi | 8 | 379 | 2.570 | 120 | 4 | %97 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Mali Tablolar Analizi | Alan Bilgisi | 8 | 210 | 1.373 | 94 | 2 | %98 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Denetim | Alan Bilgisi | 16 | 686 | 859 | 198 | 9 | %95 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Ekonomi | Alan Bilgisi | 6 | 158 | 235 | 52 | 3 | %94 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Maliye | Alan Bilgisi | 6 | 136 | 281 | 40 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Meslek Hukuku | Alan Bilgisi | 6 | 180 | 353 | 81 | 10 | %88 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Is ve Sosyal Guvenlik Hukuku | Alan Bilgisi | 6 | 191 | 489 | 101 | 6 | %94 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Vergi Hukuku | Alan Bilgisi | 6 | 164 | 1.232 | 32 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Ticaret Hukuku | Alan Bilgisi | 6 | 235 | 1.034 | 97 | 2 | %98 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Borclar Hukuku | Alan Bilgisi | 6 | 237 | 308 | 100 | 4 | %96 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |

### STAJ BİTİRME / YETERLİLİK (SMMM) — 8 ders · **sitede 3.534** · kota 8.080 · eksik 1.603 (kota − eski havuz)
Eski havuz (soru_havuzu — **kullanılmaz, Cem kararı**; sitede yok): 12.576 soru

| Ders | Bölüm | Sınavda soru | **Sitede** | Eski havuz | Kota | Eksik (kota − eski havuz) | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---:|---|
| Finansal Muhasebe | Yeterlilik | — | 998 | 2.896 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Finansal Tablolar ve Analizi | Yeterlilik | — | 381 | 1.355 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Maliyet Muhasebesi | Yeterlilik | — | 462 | 1.946 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Muhasebe Denetimi | Yeterlilik | — | 357 | 133 | 1.010 | 877 | %13 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Vergi Mevzuatı ve Uygulaması | Yeterlilik | — | 363 | 1.650 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) | Yeterlilik | — | 424 | 3.247 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Muhasebecilik ve Mali Müşavirlik Meslek Hukuku | Yeterlilik | — | 343 | 1.065 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | Yeterlilik | — | 206 | 284 | 1.010 | 726 | %28 | ONAYLI (Cem 01.09) |

### BAĞIMSIZ DENETÇİLİK (KGK) — 8 ders · sitede sayfa yok · kota 4.229 · eksik 4.229 (kapsama: hedef − sitede, konu konu)
Eski havuz (soru_havuzu — **kullanılmaz, Cem kararı**; sitede yok): 2.166 soru

| Ders | Bölüm | Sınavda soru | **Sitede** | Eski havuz | Kota | Eksik (kota − eski havuz) | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---:|---|
| a) Türkiye Muhasebe Standartları | temel alan (SMMM+YMM) | — | sayfa yok | 1.079 | 852 | 852 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| b) Türkiye Denetim Standartları | temel alan (SMMM+YMM) | — | sayfa yok | 966 | 830 | 830 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim | temel alan (yalnız SMMM) | — | sayfa yok | 118 | 890 | 890 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| ç) Sermaye Piyasası Mevzuatı | ek alan — sermaye piyasası | — | sayfa yok | 0 | 484 | 484 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| d) Bankacılık Mevzuatı | ek alan — bankacılık | — | sayfa yok | 0 | 465 | 465 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| e) Sigortacılık ve Özel Emeklilik Mevzuatı | ek alan — sigortacılık ve özel emeklilik | — | sayfa yok | 0 | 421 | 421 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| f) Kurumsal Sürdürülebilirlik Raporlaması | ek alan — sürdürülebilirlik | — | sayfa yok | 3 | 226 | 226 | %0 | ONAYLI (Cem 01.09) · tipik konular 03.09 düzeltildi |
| g) Sürdürülebilirlik Denetimi | ek alan — sürdürülebilirlik | — | sayfa yok | 0 | 61 | 61 | %0 | ONAYLI (Cem 01.09) |

### SPK LİSANSLAMA (SPL) — 23 ders

| Ders | Bölüm | Sınavda soru | **Sitede** | Eski havuz | Kota | Eksik (kota − eski havuz) | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---:|---|
| Dar Kapsamlı Sermaye Piyasası Mevzuatı ve Meslek Kuralları  [1001] | Bilgi Sistemleri Bağımsız Denetim | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Araçları 1  [1003] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Yatırım Kuruluşları  [1005] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Takas, Saklama ve Operasyon İşlemleri  [1012] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Geniş Kapsamlı Sermaye Piyasası Mevzuatı ve Meslek Kuralları  [1002] | Kredi Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Araçları 2  [1004] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Finansal Piyasalar  [1006] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Finansal Yönetim ve Mali Analiz  [1007] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Ticaret Hukuku  [1010] | Kredi Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Muhasebe ve Finansal Raporlama  [1016] | Kredi Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Genel Ekonomi  [1008] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Temel Finans Matematiği ve Değerleme Yöntemleri  [1009] | Kredi Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kurumlarda ve Sermaye Piyasasında Vergilendirme  [1013] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Türev Araçlar, Piyasalar ve Risk Yönetimi  [1011] | Türev Araçlar | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kurumsal Yönetim  [1018] | Kurumsal Yönetim Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kredi Derecelendirmesi  [1017] | Kredi Derecelendirme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Gayrimenkul Değerleme Esasları  [1014] | Gayrimenkul Değerleme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| İnşaat ve Gayrimenkul Muhasebesi  [1015] | Gayrimenkul Değerleme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Gayrimenkul Mevzuatı  [1019] | Gayrimenkul Değerleme | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Yönetimi ve Denetimi  [1020] | Bilgi Sistemleri Bağımsız Denetim | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Geliştirilmesi ve Uygulanması  [1021] | Bilgi Sistemleri Bağımsız Denetim | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri İşletimi  [1022] | Bilgi Sistemleri Bağımsız Denetim | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Güvenliği  [1023] | Bilgi Sistemleri Bağımsız Denetim | — | sayfa yok | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |

## 2 · ÇIKMIŞ SINAV SORULARI (arşiv, ders/konu kırılımı)

⚠ **Arşiv dökümü** — kaynak veri/cikmis-soru-karnesi.json (16.09.2026 22:30). EVREN = resmî keşif, DİSKTE = indirilen, AMBARDA = yutulan kitapçık; SORU = ayrıştırılan soru.

| Sınav | Yıl sayısı | Evren | Diskte | Ambarda | Çıkarılan soru |
|---|---:|---:|---:|---:|---:|
| KGK | 1 | 112 | 112 | 112 | 12.131 |
| SGS | 22 | 249 | 249 | 129 | 8.400 |
| SMMM | 19 | 419 | 419 | 419 | 320 |

**SGS sıklık künyesi** — 35 dönem, 3.248 tekil konu (veri/siklik-kunyesi.json). En çok çıkan 12 konu:

| Ders › konu | Dönem | Soru |
|---|---:|---:|
| Yabanci Dil/cumle tamamlama | 18 | 51 |
| Genel Kultur-Genel Yetenek/yazim kurallari | 16 | 17 |
| Genel Kultur-Genel Yetenek/noktalama isaretleri | 15 | 16 |
| Genel Kultur-Genel Yetenek/anlatim bozuklugu | 15 | 15 |
| Muhasebe/ortak maliyet dagitimi | 13 | 13 |
| Muhasebe/dikey yuzde analizi | 11 | 12 |
| Hukuk/disiplin cezalari | 11 | 11 |
| Muhasebe/muhasebe bilgi sistemi | 10 | 10 |
| Yabanci Dil/kelime bilgisi | 9 | 14 |
| Muhasebe/denetim kaniti yeterliligi | 9 | 11 |
| Hukuk/genel islem kosullari | 9 | 9 |
| Hukuk/meslek etik ilkeleri | 9 | 9 |

**KGK arşivi** — 30 dönem, 6.320 soru, tamamı etiketli (veri/kgk-analiz.json).

**KGK sıklık künyesi** — 29 dönem, 4.973 tekil konu, eşlenmeyen kayıt 63 (veri/siklik-kunyesi-kgk.json). En çok çıkan 12 konu:

| Ders › konu | Dönem | Soru |
|---|---:|---:|
| Kurumsal Yonetim/yonetim kurulu komiteleri | 15 | 15 |
| Sermaye Piyasasi Mevzuati/kayitli sermaye sistemi | 10 | 10 |
| Sermaye Piyasasi Mevzuati/sermaye piyasasi kurumlari | 10 | 10 |
| Sermaye Piyasasi Mevzuati/sermaye piyasasi suclari | 10 | 10 |
| Muhasebe Standartlari/net isletme sermayesi | 9 | 11 |
| Denetim Standartlari/tespit edememe riski | 9 | 9 |
| Denetim Standartlari/ic kontrol bilesenleri | 8 | 8 |
| Kurumsal Yonetim/faaliyet raporu icerigi | 7 | 7 |
| Finansal Yonetim/sistematik olmayan risk | 7 | 7 |
| Genel Hukuk Mevzuati/ticari isletme unsurlari | 7 | 7 |
| Finansal Yonetim/bilesik faiz hesabi | 7 | 7 |
| Denetim Standartlari/bds 600 topluluk denetimi | 7 | 7 |

**Konu köprüsü** (bizim konu adları ↔ çıkmış arşiv etiketleri; veri/konu-koprusu-ozet.json — V2: sayılar canlı kasadan + arşiv analizlerinden, çıkmış dayanağı 31.08 sözlüğünden; sözlükte olmayan konu 'dayanak ölçülmedi'):

- YALNIZ BIZDE: 12.469 konu
- BOSLUK - cikmisda var, bizde YOK: 9.811 konu
- IKISI DE VAR: 1.628 konu

**Arşiv dersi → bizim ders köprüsü:** 32 arşiv ders etiketi; **12 tanesinin bizim tarafta karşılığı yok** (köprüsüz ders = o dersin çıkmış soruları hiçbir ölçüme girmiyor).

| Sınav | Arşiv dersi (köprüsüz) | Konu |
|---|---|---:|
| KGK | Kurumsal Yönetim İlkeleri ve Finansal Yönetim | 831 |
| KGK | Genel Hukuk Mevzuatı | 595 |
| KGK | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı | 591 |
| KGK | Kurumsal Sürdürülebilirlik Raporlaması ve Denetimi | 247 |
| KGK | Sigortacılık ve Özel Emeklilik Mevzuatı | 224 |
| KGK | Bankacılık Mevzuatı | 222 |
| KGK | Sermaye Piyasası Mevzuatı | 207 |
| KGK | Bankacılık | 40 |
| KGK | kurumsal yonetim ve finansal yonetim | 40 |
| KGK | Sermaye Piyasası | 40 |
| KGK | sermaye piyasasi bankacilik sigortacilik | 40 |
| KGK | Sigortacılık ve Özel Emeklilik | 40 |

## 3 · BASTIĞIMIZ SORULAR YETERLİ Mİ? (kota × kasa)

Kota = Cem'in onayladığı ders başına hedef (SGS 31.07 · SMMM 31.07 · KGK 01.08). Kasa = canlı soru_havuzu sayımı. Ders ders tablo bölüm 1'de, sıralı eksik listesi bölüm 7'de.

| Sınav | Ders | Kasada | Kota toplamı | Eksik | Kotasız ders |
|---|---:|---:|---:|---:|---:|
| SGS | 15 | 15.827 | 1.885 | 83 | 0 |
| SMMM | 8 | 12.576 | 8.080 | 1.603 | 0 |
| KGK | 8 | 2.166 | 4.229 | 4.229 | 0 |

**SGS ders kararı** (veri/ders-karnesi.json — çıkmış konuların ambarda kaynağı var mı; %100 = her çıkmış konunun kaynağı ambarda):

| Ders | Hazırlık | Karar |
|---|---:|---|
| Finansal Muhasebe | %100 | ACIK - musluk acilabilir |
| Denetim | %100 | ACIK - musluk acilabilir |
| Yabanci Dil | %0 | FABRIKA GIRMEZ (elle yazilir) |
| Maliyet Muhasebesi | %100 | ACIK - musluk acilabilir |
| Matematik | %0 | FABRIKA GIRMEZ (elle yazilir) |
| Mali Tablolar Analizi | %100 | ACIK - musluk acilabilir |
| Turkce | %0 | FABRIKA GIRMEZ (elle yazilir) |
| Borclar Hukuku | %100 | ACIK - musluk acilabilir |
| Ekonomi | %99 | ACIK - musluk acilabilir |
| Maliye | %100 | ACIK - musluk acilabilir |
| Vergi Hukuku | %100 | ACIK - musluk acilabilir |
| Ticaret Hukuku | %100 | ACIK - musluk acilabilir |
| Is ve Sosyal Guvenlik Hukuku | %100 | ACIK - musluk acilabilir |
| Meslek Hukuku | %100 | ACIK - musluk acilabilir |
| Ataturk Ilkeleri ve Inkilap Tarihi | %0 | FABRIKA GIRMEZ (elle yazilir) |

## 4 · İNDİRDİĞİMİZ MEVZUAT (ambar)

Ambarın kaynak kaynak dökümü **veri/AMBAR-ENVANTERI.md**'dedir (VAR MI / TAM MI / GÜNCEL Mİ). Burada yalnız özet:

- ÖZET: 50060 parça · 2714 tekil kaynak / Bütünlük ölçülen: 2714 (delikli: 360; son ölçüm: 26.09.2026) / Sürüm ölçülen: 43 (sorunlu: 1; son ölçüm: 26.09.2026 12:55)
- Bütünlük kapısı (26.09.2026 12:57): **KIRMIZI** · 50.060 belge · temiz kaynak 2.330 · sorunlu kaynak 384 · kesik belge 742 · öksüz belge 265 (veri/butunluk-raporu.json)
- Yutma günlüğü (ne zaman ne yutuldu): YUTMA-LISTESI.md (kök).

## 5 · KAYNAK SAĞLIĞI — "indirdik mi, indirmedik mi" karmaşasının bittiği yer

Bu sayfanın her girdisi aşağıda. **TAZE** = ≤ 7 gün · **BAYAT** = daha eski (o bölüm ⚠ alır) · **KIRIK** = dosya okunamıyor ya da HATA yazıyor. Robot sütunu 'yok' ise dosya elle koşulmadıkça tazelenmez — karmaşanın kaynağı budur; hedef her satırda bir robot olması.

| Girdi | Dosya | Durum | Ölçüm damgası | Dosya tarihi | Üretici | Robot |
|---|---|---|---|---|---|---|
| ders-profili | veri/ders-profili.json | **SABİT (karar dosyası)** |  | 26.09.2026 20:45 | motor/ders-profili-kur.ps1 | yok (resmî liste; Cem onayıyla değişir) |
| kasa-sayim | veri/kasa-sayim.json | TAZE | 26.09.2026 13:45 | 26.09.2026 20:45 | motor/kasa-sayim.ps1 | kasa-sayim.yml · her gün 03:41 TR |
| kota-smmm | veri/uretim-kotasi.json | **SABİT (karar dosyası)** | 31.07.2026 10:30 (Cem onayi: her ders 1.010) | 26.09.2026 20:45 | motor/kota-kur.ps1 | yok (Cem kararı; tarih anlamsız) |
| kota-sgs | veri/sgs-uretim-kotasi.json | **SABİT (karar dosyası)** | 31.07.2026 10:4x (Cem ders-ders tablosu) | 26.09.2026 20:45 | motor/sgs-kota-kur.ps1 | yok (Cem kararı; tarih anlamsız) |
| kota-kgk | veri/kgk-uretim-kotasi.json | **SABİT (karar dosyası)** | 01.08.2026 (Cem plan onayi ayni gun: 'ONAY VERIYORUM') | 26.09.2026 20:45 | elle — Cem onayı 01.08 (kota-kur.ps1 bu dosyayı ÜRETMEZ; 16.09 denetimi) | yok (Cem kararı; tarih anlamsız) |
| kapsama-sgs | veri/sinav/sgs-kapsama-ozet.json | **SABİT (karar dosyası)** |  | 26.09.2026 20:45 | arac/sgs-konu-kapsama.js | sinav-tek-sayfa.yml · her gün 08:30 TR |
| kapsama-kgk | veri/sinav/kgk-kapsama-ozet.json | **SABİT (karar dosyası)** |  | 26.09.2026 20:45 | arac/kgk-konu-kapsama.js | sinav-tek-sayfa.yml · her gün 08:30 TR |
| konu-koprusu | veri/konu-koprusu-ozet.json | TAZE | 26.09.2026 09:32 | 26.09.2026 20:45 | motor/konu-koprusu-kur.ps1 (V2 canlı) | konu-koprusu.yml · her gün 07:40 TR |
| ambar-envanteri | veri/AMBAR-ENVANTERI.md | TAZE | 26.09.2026 12:57 | 26.09.2026 20:45 | motor/ambar-envanteri.ps1 | ambar-kapilari.yml · her gün 11:00 TR |
| butunluk-raporu | veri/butunluk-raporu.json | TAZE | 26.09.2026 12:57 | 26.09.2026 20:45 | motor/butunluk-kapisi.ps1 | ambar-kapilari.yml · her gün 11:00 TR |
| cikmis-karnesi | veri/cikmis-soru-karnesi.json | **BAYAT (10 gün)** | 16.09.2026 22:30 | 26.09.2026 20:45 | motor/sinav-arsiv-karnesi.ps1 (evren·disk·ambar; eski cikmis-soru-karnesi.ps1 AYNI dosyayı başka biçimle yazar, korumalı) | yok (KGK evreni için haberci: kgk-sinav-nobeti.yml) |
| siklik-kunyesi | veri/siklik-kunyesi.json | TAZE | 19.09.2026 07:06 | 26.09.2026 20:45 | motor/siklik-kunyesi.ps1 | konu-eslesme.yml · yalnız push |
| siklik-kunyesi-kgk | veri/siklik-kunyesi-kgk.json | TAZE | 19.09.2026 07:06 | 26.09.2026 20:45 | motor/siklik-kunyesi.ps1 -Sinav KGK | konu-eslesme.yml · yalnız push |
| kgk-analiz | veri/kgk-analiz.json | TAZE | 19.09.2026 (etiketten donem eklendi: 11 Kasım 2018) · nöbet YEŞİL 19.09.2026 08:16 | 26.09.2026 20:45 | elle etiket (19.08 TAM ARŞİV; kgk-siklik-derle.ps1 bu biçimi ÜRETMEZ) | yok — yeni sınavda tazelenir; haberci: kgk-sinav-nobeti.yml |
| ders-karnesi | veri/ders-karnesi.json | TAZE | 2026-09-21 12:24 | 26.09.2026 20:45 | motor/ders-karnesi.ps1 | karne.yml · SGS karnesinden sonra (pazar 03:00 TR + analiz push) |
| karne-sgs | veri/konu-kaynak-karnesi.json | TAZE | 2026-09-21 12:24 | 26.09.2026 20:45 | motor/konu-kaynak-karnesi.ps1 | karne.yml · pazar 03:00 TR + sgs-analiz push |
| karne-smmm | veri/konu-kaynak-karnesi-smmm.json | TAZE | 2026-09-21 14:31 | 26.09.2026 20:45 | motor/konu-kaynak-karnesi.ps1 | karne.yml |
| karne-kgk | veri/konu-kaynak-karnesi-kgk.json | TAZE | 2026-09-21 17:25 | 26.09.2026 20:45 | motor/konu-kaynak-karnesi.ps1 | karne.yml |
| dayanak-metinsiz | veri/dayanak-metinsiz-raporu.json | TAZE |  | 26.09.2026 20:45 | arac/dayanak-metinsiz-tarama.ps1 | yok |
| dayanak-kara-liste | veri/dayanak-kara-liste.json | TAZE |  | 26.09.2026 20:45 | arac/dayanak-kara-liste.ps1 | yok |
| bekleyen-partiler | veri/bekleyen-partiler.json | TAZE |  | 26.09.2026 20:45 | motor/api-hedef.ps1 (Invoke-ClaudeToplu yazar; parti-hasat.ps1 temizler) | yan ürün: bulut-uretim.yml / soru-uret-v2.yml (parti-liste.yml bu dosyayı yazmaz; 16.09 denetimi) |
| sinav-ders-envanteri | veri/sinav-ders-envanteri.json | TAZE |  | 26.09.2026 20:45 | motor/sinav-ders-envanteri.ps1 | sinav-ders-envanteri.yml · yalnız push |
| kasa-site | veri/kasa-sayim.json › site | TAZE | 26.09.2026 13:45 | 26.09.2026 20:45 | motor/kasa-sayim.ps1 (paket_soru sayımı) | kasa-sayim.yml · her gün 03:41 TR |

**Şu an TAZE olmayan girdi: 7 / 23.**

## 6 · ÇIKMIŞ SORULARA GÖRE YUTMADIĞIMIZ MEVZUAT

**Dayanak ↔ ambar taraması** (veri/dayanak-metinsiz-raporu.json): köprüdeki 4.377 tekil dayanaktan 2.826 ambarda bulundu, **83 bulunamadı (%1.9)**; etkilenen köprü kaydı 89. Bulunamayan dayanak = hakem doğrulayamaz, üretici kaynak çekemez → o konuda soru üretilmez (çöp değil, kaynak eksiği).

En çok kaydı etkileyen bulunamayan dayanaklar:

- Mali Analiz Teknikleri – Dikey Yüzde (Yüzde) Yöntemi -> 4 kayit
- Mali Analiz Teknikleri - Dikey Yüzdeler (Yüzde Yöntemiyle Analiz) -> 3 kayit
- Maliye Politikası Teorisi - Stagflasyon Kavramı -> 2 kayit
- Mali Tablolar Analizi - faaliyet oranları (alacak devir hızı = kredili satış / ortalama alacak; tahsil süresi = 360 / hız) -> 1 kayit
- TCMB Para Politikası Çerçevesi - Parasal Aktarım Mekanizması -> 1 kayit
- IS-LM Modeli - Para Talebinin Faiz Esnekliği ve Politika Etkinliği -> 1 kayit
- MSUGT Tekduzen Hesap Plani - 650 -> 1 kayit
- J-Eğrisi Modeli (Esneklikler Yaklaşımı) -> 1 kayit
- TÜİK Ulusal Hesaplar Sistemi - Reel GSYH Hesaplama Yöntemi -> 1 kayit
- Mikroiktisat Teorisi - Talep Esnekliğinin Belirleyicileri (Zaman Faktörü) -> 1 kayit
- J-Eğrisi Modeli (Esneklikler Yaklaşımı, Ödemeler Bilançosu Teorisi) -> 1 kayit
- Maliye Politikası Teorisi - Arz Yönlü Şoklar ve Stagflasyon Analizi -> 1 kayit
- Maliye Politikası Teorisi - Talep Yönetiminin Stagflasyonda Yetersizliği -> 1 kayit
- MSUGT Tekduzen Hesap Plani - 486 -> 1 kayit
- İki tarih arasındaki gün farkını hesaplama kuralı (takvim ay-gün sayıları) -> 1 kayit

**Konu-kaynak karnesi** (her çıkmış konu için ambarda kaynak var mı; veri/konu-kaynak-karnesi*.json):

| Sınav | ÜRET (kaynağı var) | KAYNAK YOK | MEVZUAT DIŞI | Ölçülemedi |
|---|---:|---:|---:|---:|
| SGS | 2.625 | **1** | 637 | 1 |
| SMMM | 3.292 | **23** | 0 | 0 |
| KGK | 5.397 | **9** | 0 | 0 |

KAYNAK YOK örnekleri (SGS):
- Ekonomi › tuketici tercih aksiyomlari (1 çıkmış)

KAYNAK YOK örnekleri (SMMM):
- Finansal Muhasebe › senet kirdirma iskonto (2 çıkmış)
- Vergi Mevzuatı ve Uygulaması › mirascilara sure eklenmesi (1 çıkmış)
- Vergi Mevzuatı ve Uygulaması › kolektif sirket vergi tarhiyati (1 çıkmış)
- Muhasebe Denetimi › zayi olan mal kaydi (1 çıkmış)
- Muh. ve Mali Müş. Meslek Hukuku › birlik disiplin kurulu uye vasiflari (1 çıkmış)
- Maliyet Muhasebesi › dimmg sapmalari (1 çıkmış)
- Finansal Tablolar ve Analizi › alikonan hisse basina kar (1 çıkmış)
- Finansal Muhasebe › tasit tamirat aktiflestirme (1 çıkmış)

KAYNAK YOK örnekleri (KGK):
- Genel Hukuk Mevzuati › idarenin anayasal ilkeleri (1 çıkmış)
- Genel Hukuk Mevzuati › odeme emrine itiraz sayilmama (1 çıkmış)
- Genel Hukuk Mevzuatı › anonim sirkete sermaye olarak getirilebilecekler (1 çıkmış)
- Genel Hukuk Mevzuatı › istimval (1 çıkmış)
- Genel Hukuk Mevzuatı › zilyetlikte hukmen teslim (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › finansal basarisizlikta mali yapi iyilestirme (1 çıkmış)
- Muhasebe › dovizli mevduat donem sonu kaydi (1 çıkmış)
- Muhasebe › faiz geliri dogmayan islem (1 çıkmış)

**Dayanak kara listesi** (hakemle ölçüldü, yanlış oranı > %50; üretici yok sayar — veri/dayanak-kara-liste.json):

- TTK (6102 s.K.) m.720
- SMMM K. (3568 s.K.) m.29
- VUK (213 s.K.) m.278 - Kıymeti düşen mallar
- Teori Notu - oran analizi likidite
- Teori Notu - isletme sermayesi yonetimi

## 7 · BASMAMIZ GEREKEN SORULAR

**Ders eksikleri** (kota − kasa, büyükten küçüğe):

| Sınav | Ders | Kota | Bizim | Eksik | Doluluk |
|---|---|---:|---:|---:|---:|
| KGK | c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim | 890 | 118 | **890** | %0 |
| SMMM | Muhasebe Denetimi | 1.010 | 133 | **877** | %13 |
| KGK | a) Türkiye Muhasebe Standartları | 852 | 1.079 | **852** | %0 |
| KGK | b) Türkiye Denetim Standartları | 830 | 966 | **830** | %0 |
| SMMM | Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | 1.010 | 284 | **726** | %28 |
| KGK | ç) Sermaye Piyasası Mevzuatı | 484 | 0 | **484** | %0 |
| KGK | d) Bankacılık Mevzuatı | 465 | 0 | **465** | %0 |
| KGK | e) Sigortacılık ve Özel Emeklilik Mevzuatı | 421 | 0 | **421** | %0 |
| KGK | f) Kurumsal Sürdürülebilirlik Raporlaması | 226 | 3 | **226** | %0 |
| KGK | g) Sürdürülebilirlik Denetimi | 61 | 0 | **61** | %0 |
| SGS | Matematik | 141 | 211 | **16** | %89 |
| SGS | Meslek Hukuku | 81 | 353 | **10** | %88 |
| SGS | Turkce | 104 | 928 | **9** | %91 |
| SGS | Denetim | 198 | 859 | **9** | %95 |
| SGS | Finansal Muhasebe | 416 | 4.309 | **7** | %98 |
| SGS | Is ve Sosyal Guvenlik Hukuku | 101 | 489 | **6** | %94 |
| SGS | Ataturk Ilkeleri ve Inkilap Tarihi | 48 | 114 | **6** | %88 |
| SGS | Yabanci Dil | 261 | 1.531 | **5** | %98 |
| SGS | Maliyet Muhasebesi | 120 | 2.570 | **4** | %97 |
| SGS | Borclar Hukuku | 100 | 308 | **4** | %96 |
| SGS | Ekonomi | 52 | 235 | **3** | %94 |
| SGS | Mali Tablolar Analizi | 94 | 1.373 | **2** | %98 |
| SGS | Ticaret Hukuku | 97 | 1.034 | **2** | %98 |

**Ağır boşluklar** — çıkmışta ≥ 3 dönem var, bizde hiç yok: 525 konu (veri/konu-koprusu-ozet.json). En çok çıkan 25'i:

| Sınav | Konu | Dönem | Çıkmış soru | Arşiv dersi | Dayanak | Güç |
|---|---|---:|---:|---|---|---|
| SMMM | gelir tablosu duzenleme | 40 | 46 | Finansal Muhasebe / Maliyet Muhasebesi / Finansal Tablolar ve Analizi | SMMM K. (3568 s.K.) m.29 | TEYITLI |
| KGK | yonetim kurulu komiteleri | 15 | 15 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / Kurumsal Yonetim Ilkeleri ve Finansal Yonetim / KURUMSAL YÖNETİM İLKELERİ VE FİNANSAL YÖNETİM | TOBB/Odalar K. (5174 s.K.) | ZAYIF |
| SMMM | ucret tahakkuku | 13 | 13 | Finansal Muhasebe |  | OLCULMEDI |
| SMMM | nakit orani | 12 | 12 | Finansal Tablolar ve Analizi |  | OLCULMEDI |
| SMMM | supheli alacak tahsili | 11 | 11 | Finansal Muhasebe / Vergi Mevzuatı ve Uygulaması |  | OLCULMEDI |
| SMMM | satistan iade | 10 | 10 | Finansal Muhasebe |  | OLCULMEDI |
| SMMM | kapanis kaydi | 10 | 10 | Finansal Muhasebe | TTK (6102 s.K.) m.720 | TEYITLI |
| KGK | kayitli sermaye sistemi | 10 | 10 | Sermaye Piyasası Mevzuatı / Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / sermaye piyasasi bankacilik sigortacilik | TTK (6102 s.K.) m.482 | TEYITLI |
| KGK | sermaye piyasasi kurumlari | 10 | 10 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasası Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / Sermaye Piyasası |  | OLCULMEDI |
| KGK | sermaye piyasasi suclari | 10 | 10 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasası Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / Sermaye Piyasası |  | OLCULMEDI |
| SMMM | satis ve maliyet kaydi | 9 | 9 | Finansal Muhasebe | VUK (213 s.K.) m.275 - İmal edilen emtia | TEYITLI |
| SMMM | satis iadesi | 9 | 9 | Finansal Muhasebe |  | OLCULMEDI |
| SMMM | mevduat faiz tahakkuku | 9 | 9 | Finansal Muhasebe | VUK (213 s.K.) m.283 - Aktif geçici hesap kıymetleri | TEYITLI |
| KGK | tespit edememe riski | 9 | 9 | Denetim |  | OLCULMEDI |
| SGS | kelime bilgisi | 9 | 14 | Yabanci Dil |  | OLCULMEDI |
| KGK | net isletme sermayesi | 9 | 12 | Muhasebe / Kurumsal Yönetim İlkeleri ve Finansal Yönetim | Teori Notu - isletme sermayesi yonetimi | TEYITLI |
| SMMM | ticari borc odeme suresi | 8 | 8 | Finansal Tablolar ve Analizi | Bankacılık K. (5411 s.K.) | ZAYIF |
| KGK | ic kontrol bilesenleri | 8 | 8 | Denetim | BDS 315 | ZAYIF |
| SMMM | kaldirac orani | 8 | 8 | Finansal Tablolar ve Analizi | Teori Notu - finansal analiz oranlari | TEYITLI |
| SGS | sozcukte anlam | 8 | 8 | Genel Kultur-Genel Yetenek |  | OLCULMEDI |
| SMMM | verilen cek odemesi | 8 | 8 | Finansal Muhasebe | Çek K. (5941 s.K.) | ZAYIF |
| KGK | bilesik faiz hesabi | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim | SPK Tebliğ (Seri: V, No: 34) | ZAYIF |
| KGK | tahvil özellikleri | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Kurumsal Yonetim Ilkeleri ve Finansal Yonetim | SPK Karari | ZAYIF |
| SMMM | gider yansitma kaydi | 7 | 7 | Finansal Muhasebe | THP 798 | TEYITLI |
| SMMM | personel ucret tahakkuku | 7 | 7 | Finansal Muhasebe |  | OLCULMEDI |

Bekleyen üretim partisi: 8609 (veri/bekleyen-partiler.json).

---
_Bu sayfayı elle düzenleme; girdisini düzelt, robot yeniden yazar._
