# SINAV TEK SAYFA — üç sınavın tek doğru sayfası

> Üretim: **02.09.2026 20:23** (makine; elle düzenlenmez — motor/sinav-tek-sayfa.ps1, günlük robot). Makine hâli: veri/sinav-tek-sayfa.json
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

Kaynak: ders listesi = veri/ders-profili.json (TESMER Yönergesi m.6.2 / KGK ilanı / SPL) · bizim soru = veri/kasa-sayim.json (02.09.2026 05:03) · kota = üç kota dosyası (bölüm 5).

### STAJA BAŞLAMA (SGS) — 15 ders · kasada 15.827 soru · kota 14.603 · eksik 4.529

| Ders | Bölüm | Sınavda soru | Bizim soru | Kota | Eksik | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---|
| Turkce | Genel Kultur ve Yetenek | 7 | 928 | 656 | 0 | %100 | ONAYLI (Cem 01.09) |
| Matematik | Genel Kultur ve Yetenek | 8 | 211 | 750 | 539 | %28 | ONAYLI (Cem 01.09) |
| Ataturk Ilkeleri ve Inkilap Tarihi | Genel Kultur ve Yetenek | 5 | 114 | 469 | 355 | %24 | ONAYLI (Cem 01.09) |
| Yabanci Dil | Yabanci Dil | 10 | 1.531 | 938 | 0 | %100 | ONAYLI (Cem 01.09) |
| Finansal Muhasebe | Alan Bilgisi | 26 | 4.309 | 1.500 | 0 | %100 | ONAYLI (Cem 01.09) |
| Maliyet Muhasebesi | Alan Bilgisi | 8 | 2.570 | 1.040 | 0 | %100 | ONAYLI (Cem 01.09) |
| Mali Tablolar Analizi | Alan Bilgisi | 8 | 1.373 | 1.050 | 0 | %100 | ONAYLI (Cem 01.09) |
| Denetim | Alan Bilgisi | 16 | 859 | 1.050 | 191 | %82 | ONAYLI (Cem 01.09) |
| Ekonomi | Alan Bilgisi | 6 | 235 | 1.030 | 795 | %23 | ONAYLI (Cem 01.09) |
| Maliye | Alan Bilgisi | 6 | 281 | 1.020 | 739 | %28 | ONAYLI (Cem 01.09) |
| Meslek Hukuku | Alan Bilgisi | 6 | 353 | 1.020 | 667 | %35 | ONAYLI (Cem 01.09) |
| Is ve Sosyal Guvenlik Hukuku | Alan Bilgisi | 6 | 489 | 1.020 | 531 | %48 | ONAYLI (Cem 01.09) |
| Vergi Hukuku | Alan Bilgisi | 6 | 1.232 | 1.020 | 0 | %100 | ONAYLI (Cem 01.09) |
| Ticaret Hukuku | Alan Bilgisi | 6 | 1.034 | 1.020 | 0 | %100 | ONAYLI (Cem 01.09) |
| Borclar Hukuku | Alan Bilgisi | 6 | 308 | 1.020 | 712 | %30 | ONAYLI (Cem 01.09) |

### STAJ BİTİRME / YETERLİLİK (SMMM) — 8 ders · kasada 12.576 soru · kota 8.080 · eksik 1.603

| Ders | Bölüm | Sınavda soru | Bizim soru | Kota | Eksik | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---|
| Finansal Muhasebe | Yeterlilik | — | 2.896 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Finansal Tablolar ve Analizi | Yeterlilik | — | 1.355 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Maliyet Muhasebesi | Yeterlilik | — | 1.946 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Muhasebe Denetimi | Yeterlilik | — | 133 | 1.010 | 877 | %13 | ONAYLI (Cem 01.09) |
| Vergi Mevzuatı ve Uygulaması | Yeterlilik | — | 1.650 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) | Yeterlilik | — | 3.247 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Muhasebecilik ve Mali Müşavirlik Meslek Hukuku | Yeterlilik | — | 1.065 | 1.010 | 0 | %100 | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | Yeterlilik | — | 284 | 1.010 | 726 | %28 | ONAYLI (Cem 01.09) |

### BAĞIMSIZ DENETÇİLİK (KGK) — 8 ders · kasada 2.166 soru · kota 5.871 · eksik 3.705

| Ders | Bölüm | Sınavda soru | Bizim soru | Kota | Eksik | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---|
| a) Türkiye Muhasebe Standartları | temel alan (SMMM+YMM) | — | 1.079 | 1.391 | 312 | %78 | ONAYLI (Cem 01.09) |
| b) Türkiye Denetim Standartları | temel alan (SMMM+YMM) | — | 966 | 1.360 | 394 | %71 | ONAYLI (Cem 01.09) |
| c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim | temel alan (yalnız SMMM) | — | 118 | 1.440 | 1.322 | %8 | ONAYLI (Cem 01.09) |
| ç) Sermaye Piyasası Mevzuatı | ek alan — sermaye piyasası | — | 0 | 360 | 360 | %0 | ONAYLI (Cem 01.09) |
| d) Bankacılık Mevzuatı | ek alan — bankacılık | — | 0 | 360 | 360 | %0 | ONAYLI (Cem 01.09) |
| e) Sigortacılık ve Özel Emeklilik Mevzuatı | ek alan — sigortacılık ve özel emeklilik | — | 0 | 360 | 360 | %0 | ONAYLI (Cem 01.09) |
| f) Kurumsal Sürdürülebilirlik Raporlaması | ek alan — sürdürülebilirlik | — | 3 | 300 | 297 | %1 | ONAYLI (Cem 01.09) |
| g) Sürdürülebilirlik Denetimi | ek alan — sürdürülebilirlik | — | 0 | 300 | 300 | %0 | ONAYLI (Cem 01.09) |

### SPK LİSANSLAMA (SPL) — 23 ders

| Ders | Bölüm | Sınavda soru | Bizim soru | Kota | Eksik | Doluluk | Onay |
|---|---|---:|---:|---:|---:|---:|---|
| Dar Kapsamlı Sermaye Piyasası Mevzuatı ve Meslek Kuralları  [1001] | Bilgi Sistemleri Bağımsız Denetim | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Araçları 1  [1003] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Yatırım Kuruluşları  [1005] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Takas, Saklama ve Operasyon İşlemleri  [1012] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Geniş Kapsamlı Sermaye Piyasası Mevzuatı ve Meslek Kuralları  [1002] | Kredi Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Sermaye Piyasası Araçları 2  [1004] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Finansal Piyasalar  [1006] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Finansal Yönetim ve Mali Analiz  [1007] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Ticaret Hukuku  [1010] | Kredi Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Muhasebe ve Finansal Raporlama  [1016] | Kredi Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Genel Ekonomi  [1008] | Düzey 3 (Sermaye Piyasası Faaliyetleri Düzey 3) | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Temel Finans Matematiği ve Değerleme Yöntemleri  [1009] | Kredi Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kurumlarda ve Sermaye Piyasasında Vergilendirme  [1013] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Türev Araçlar, Piyasalar ve Risk Yönetimi  [1011] | Türev Araçlar | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kurumsal Yönetim  [1018] | Kurumsal Yönetim Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Kredi Derecelendirmesi  [1017] | Kredi Derecelendirme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Gayrimenkul Değerleme Esasları  [1014] | Gayrimenkul Değerleme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| İnşaat ve Gayrimenkul Muhasebesi  [1015] | Gayrimenkul Değerleme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Gayrimenkul Mevzuatı  [1019] | Gayrimenkul Değerleme | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Yönetimi ve Denetimi  [1020] | Bilgi Sistemleri Bağımsız Denetim | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Geliştirilmesi ve Uygulanması  [1021] | Bilgi Sistemleri Bağımsız Denetim | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri İşletimi  [1022] | Bilgi Sistemleri Bağımsız Denetim | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |
| Bilgi Sistemleri Güvenliği  [1023] | Bilgi Sistemleri Bağımsız Denetim | — | 0 | kota yok | — | — | ONAYLI (Cem 01.09) |

## 2 · ÇIKMIŞ SINAV SORULARI (arşiv, ders/konu kırılımı)

⚠ **Arşiv dökümü** — kaynak veri/cikmis-soru-karnesi.json (24.08.2026 00:05). EVREN = resmî keşif, DİSKTE = indirilen, AMBARDA = yutulan kitapçık; SORU = ayrıştırılan soru.

| Sınav | Yıl sayısı | Evren | Diskte | Ambarda | Çıkarılan soru |
|---|---:|---:|---:|---:|---:|
| KGK | 1 | 112 | 112 | 108 | 12.131 |
| SGS | 22 | 249 | 185 | 129 | 8.400 |
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

⚠ **KGK arşivi** — 29 dönem, 6.080 soru, tamamı etiketli (veri/kgk-analiz.json).

**Konu köprüsü** (bizim konu adları ↔ çıkmış arşiv etiketleri; veri/konu-koprusu-ozet.json — V2: sayılar canlı kasadan + arşiv analizlerinden, çıkmış dayanağı 31.08 sözlüğünden; sözlükte olmayan konu 'dayanak ölçülmedi'):

- YALNIZ BIZDE: 12.503 konu
- BOSLUK - cikmisda var, bizde YOK: 7.253 konu
- IKISI DE VAR: 1.594 konu

**Arşiv dersi → bizim ders köprüsü:** 32 arşiv ders etiketi; **12 tanesinin bizim tarafta karşılığı yok** (köprüsüz ders = o dersin çıkmış soruları hiçbir ölçüme girmiyor).

| Sınav | Arşiv dersi (köprüsüz) | Konu |
|---|---|---:|
| KGK | Kurumsal Yönetim İlkeleri ve Finansal Yönetim | 776 |
| KGK | Genel Hukuk Mevzuatı | 563 |
| KGK | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı | 540 |
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
| SGS | 15 | 15.827 | 14.603 | 4.529 | 0 |
| SMMM | 8 | 12.576 | 8.080 | 1.603 | 0 |
| KGK | 8 | 2.166 | 5.871 | 3.705 | 0 |

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
| Ekonomi | %100 | ACIK - musluk acilabilir |
| Maliye | %100 | ACIK - musluk acilabilir |
| Vergi Hukuku | %100 | ACIK - musluk acilabilir |
| Ticaret Hukuku | %100 | ACIK - musluk acilabilir |
| Is ve Sosyal Guvenlik Hukuku | %100 | ACIK - musluk acilabilir |
| Meslek Hukuku | %100 | ACIK - musluk acilabilir |
| Ataturk Ilkeleri ve Inkilap Tarihi | %0 | FABRIKA GIRMEZ (elle yazilir) |

## 4 · İNDİRDİĞİMİZ MEVZUAT (ambar)

Ambarın kaynak kaynak dökümü **veri/AMBAR-ENVANTERI.md**'dedir (VAR MI / TAM MI / GÜNCEL Mİ). Burada yalnız özet:

- ÖZET: 44300 parça · 2401 tekil kaynak / Bütünlük ölçülen: 2401 (delikli: 329; son ölçüm: 02.09.2026) / Sürüm ölçülen: 41 (sorunlu: 0; son ölçüm: 30.08.2026 06:47)
- Bütünlük kapısı (02.09.2026 14:53): **KIRMIZI** · 44.300 belge · temiz kaynak 2.041 · sorunlu kaynak 360 · kesik belge 771 · öksüz belge 244 (veri/butunluk-raporu.json)
- Yutma günlüğü (ne zaman ne yutuldu): YUTMA-LISTESI.md (kök).

## 5 · KAYNAK SAĞLIĞI — "indirdik mi, indirmedik mi" karmaşasının bittiği yer

Bu sayfanın her girdisi aşağıda. **TAZE** = ≤ 7 gün · **BAYAT** = daha eski (o bölüm ⚠ alır) · **KIRIK** = dosya okunamıyor ya da HATA yazıyor. Robot sütunu 'yok' ise dosya elle koşulmadıkça tazelenmez — karmaşanın kaynağı budur; hedef her satırda bir robot olması.

| Girdi | Dosya | Durum | Ölçüm damgası | Dosya tarihi | Üretici | Robot |
|---|---|---|---|---|---|---|
| ders-profili | veri/ders-profili.json | **SABİT (karar dosyası)** |  | 02.09.2026 20:23 | motor/ders-profili-kur.ps1 | yok (resmî liste; Cem onayıyla değişir) |
| kasa-sayim | veri/kasa-sayim.json | TAZE | 02.09.2026 05:03 | 02.09.2026 20:23 | motor/kasa-sayim.ps1 | kasa-sayim.yml · her gün 03:41 TR |
| kota-smmm | veri/uretim-kotasi.json | **SABİT (karar dosyası)** | 31.07.2026 10:30 (Cem onayi: her ders 1.010) | 02.09.2026 20:23 | motor/kota-kur.ps1 | yok (Cem kararı; tarih anlamsız) |
| kota-sgs | veri/sgs-uretim-kotasi.json | **SABİT (karar dosyası)** | 31.07.2026 10:4x (Cem ders-ders tablosu) | 02.09.2026 20:23 | motor/sgs-kota-kur.ps1 | yok (Cem kararı; tarih anlamsız) |
| kota-kgk | veri/kgk-uretim-kotasi.json | **SABİT (karar dosyası)** | 01.08.2026 (Cem plan onayi ayni gun: 'ONAY VERIYORUM') | 02.09.2026 20:23 | motor/kota-kur.ps1 (elle) | yok (Cem kararı; tarih anlamsız) |
| konu-koprusu | veri/konu-koprusu-ozet.json | TAZE | 02.09.2026 23:22 | 02.09.2026 20:23 | motor/konu-koprusu-kur.ps1 (V2 canlı) | konu-koprusu.yml · her gün 07:40 TR |
| ambar-envanteri | veri/AMBAR-ENVANTERI.md | TAZE | 02.09.2026 17:57 | 02.09.2026 20:23 | motor/ambar-envanteri.ps1 | ambar-kapilari.yml · her gün 11:00 TR |
| butunluk-raporu | veri/butunluk-raporu.json | TAZE | 02.09.2026 14:53 | 02.09.2026 20:23 | motor/butunluk-kapisi.ps1 | ambar-kapilari.yml · her gün 11:00 TR |
| cikmis-karnesi | veri/cikmis-soru-karnesi.json | **BAYAT (9 gün)** | 24.08.2026 00:05 | 02.09.2026 20:23 | motor/cikmis-soru-karnesi.ps1 | yok |
| siklik-kunyesi | veri/siklik-kunyesi.json | TAZE | 30.08.2026 08:43 | 02.09.2026 20:23 | motor/siklik-kunyesi.ps1 | konu-eslesme.yml · yalnız push |
| kgk-analiz | veri/kgk-analiz.json | **BAYAT (14 gün)** | 19.08.2026 (TAM ARSIV) | 02.09.2026 20:23 | motor/kgk-siklik-derle.ps1 | yok |
| ders-karnesi | veri/ders-karnesi.json | TAZE | 2026-08-26 00:11 | 02.09.2026 20:23 | motor/ders-karnesi.ps1 | dogrula.yml |
| karne-sgs | veri/konu-kaynak-karnesi.json | TAZE | 2026-08-27 14:09 | 02.09.2026 20:23 | motor/konu-kaynak-karnesi.ps1 | karne.yml · sgs-analiz push tetikli |
| karne-smmm | veri/konu-kaynak-karnesi-smmm.json | TAZE | 2026-08-26 00:51 | 02.09.2026 20:23 | motor/konu-kaynak-karnesi.ps1 | karne.yml |
| karne-kgk | veri/konu-kaynak-karnesi-kgk.json | TAZE | 2026-08-26 03:00 | 02.09.2026 20:23 | motor/konu-kaynak-karnesi.ps1 | karne.yml |
| dayanak-metinsiz | veri/dayanak-metinsiz-raporu.json | TAZE |  | 02.09.2026 20:23 | arac/dayanak-metinsiz-tarama.ps1 | yok |
| dayanak-kara-liste | veri/dayanak-kara-liste.json | TAZE |  | 02.09.2026 20:23 | arac/dayanak-kara-liste.ps1 | yok |
| bekleyen-partiler | veri/bekleyen-partiler.json | TAZE |  | 02.09.2026 20:23 | motor/parti-hasat.ps1 | parti-liste.yml · her gün 03:26 TR |
| sinav-ders-envanteri | veri/sinav-ders-envanteri.json | TAZE |  | 02.09.2026 20:23 | motor/sinav-ders-envanteri.ps1 | sinav-ders-envanteri.yml · yalnız push |

**Şu an TAZE olmayan girdi: 6 / 19.**

## 6 · ÇIKMIŞ SORULARA GÖRE YUTMADIĞIMIZ MEVZUAT

**Dayanak ↔ ambar taraması** (veri/dayanak-metinsiz-raporu.json): köprüdeki 4.667 tekil dayanaktan 1.049 ambarda bulundu, **148 bulunamadı (%12.4)**; etkilenen köprü kaydı 455. Bulunamayan dayanak = hakem doğrulayamaz, üretici kaynak çekemez → o konuda soru üretilmez (çöp değil, kaynak eksiği).

En çok kaydı etkileyen bulunamayan dayanaklar:

- MSUGT Tekduzen Hesap Plani -> 53 kayit
- KKS 1  ⚠ ambarda YOK -> 16 kayit
- 5510 sayılı Kanun m.18 -> 9 kayit
- TDK mecaz anlam kuralı -> 9 kayit
- 5510 sayılı Kanun m.34 -> 7 kayit
- BDS 720 p.11/11T - AMACLAR (uluslararasi 4 amac / Turkiye 5 amac + AYRI RAPOR) -> 7 kayit
- 3568 s. SMMM K. m.25/son fıkra -> 7 kayit
- Third Conditional (Type 3) kullanım kuralı -> 6 kayit
- 3568 sayili Kanun m.48 (disiplin cezalari) ve Disiplin Yonetmeligi -> 6 kayit
- TMS 18  ⚠ ambarda YOK -> 5 kayit
- TDK çok anlamlılık kuralı -> 5 kayit
- TDK terim anlam kuralı -> 5 kayit
- TMS 11  ⚠ ambarda YOK -> 5 kayit
- TFRS 4  ⚠ ambarda YOK -> 5 kayit
- Causative Form (have something done) kullanım kuralı -> 4 kayit

**Konu-kaynak karnesi** (her çıkmış konu için ambarda kaynak var mı; veri/konu-kaynak-karnesi*.json):

| Sınav | ÜRET (kaynağı var) | KAYNAK YOK | MEVZUAT DIŞI | Ölçülemedi |
|---|---:|---:|---:|---:|
| SGS | 2.625 | **1** | 637 | 1 |
| SMMM | 1.004 | **6** | 0 | 0 |
| KGK | 5.082 | **65** | 0 | 0 |

KAYNAK YOK örnekleri (SGS):
- Ekonomi › tuketici tercih aksiyomlari (1 çıkmış)

KAYNAK YOK örnekleri (SMMM):
- Finansal Muhasebe › finansal kiralamali monografi (1 çıkmış)
- Finansal Muhasebe › kdv hesaplasmasi kaydi (1 çıkmış)
- Finansal Muhasebe › stok fire kaydi (1 çıkmış)
- Muhasebe Denetimi › denetim ustlenememe halleri (1 çıkmış)
- Muhasebe Denetimi › sermaye azalmasinda kurul tedbirleri (1 çıkmış)
- Vergi Mevzuatı ve Uygulaması › sermaye azaltimi vergilendirmesi (1 çıkmış)

KAYNAK YOK örnekleri (KGK):
- Bankacılık Mevzuatı › bkn 5411 banka turlerine gore faaliyet yasaklari (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › kurumsal yonetim etmenleri (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › pay sahipleriyle iletisimde oncu komite (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › piyasa vade siniflamasi (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › reel faiz hesabi (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › sabit gider siniflamasi (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › temettu ilisksizlik teorisi (1 çıkmış)
- Kurumsal Yönetim İlkeleri ve Finansal Yönetim › wacc hesabi (1 çıkmış)

**Dayanak kara listesi** (hakemle ölçüldü, yanlış oranı > %50; üretici yok sayar — veri/dayanak-kara-liste.json):

- TTK (6102 s.K.) m.720
- SMMM K. (3568 s.K.) m.29
- VUK (213 s.K.) m.278 - Kıymeti düşen mallar
- Teori Notu - oran analizi likidite

## 7 · BASMAMIZ GEREKEN SORULAR

**Ders eksikleri** (kota − kasa, büyükten küçüğe):

| Sınav | Ders | Kota | Bizim | Eksik | Doluluk |
|---|---|---:|---:|---:|---:|
| KGK | c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim | 1.440 | 118 | **1.322** | %8 |
| SMMM | Muhasebe Denetimi | 1.010 | 133 | **877** | %13 |
| SGS | Ekonomi | 1.030 | 235 | **795** | %23 |
| SGS | Maliye | 1.020 | 281 | **739** | %28 |
| SMMM | Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | 1.010 | 284 | **726** | %28 |
| SGS | Borclar Hukuku | 1.020 | 308 | **712** | %30 |
| SGS | Meslek Hukuku | 1.020 | 353 | **667** | %35 |
| SGS | Matematik | 750 | 211 | **539** | %28 |
| SGS | Is ve Sosyal Guvenlik Hukuku | 1.020 | 489 | **531** | %48 |
| KGK | b) Türkiye Denetim Standartları | 1.360 | 966 | **394** | %71 |
| KGK | ç) Sermaye Piyasası Mevzuatı | 360 | 0 | **360** | %0 |
| KGK | d) Bankacılık Mevzuatı | 360 | 0 | **360** | %0 |
| KGK | e) Sigortacılık ve Özel Emeklilik Mevzuatı | 360 | 0 | **360** | %0 |
| SGS | Ataturk Ilkeleri ve Inkilap Tarihi | 469 | 114 | **355** | %24 |
| KGK | a) Türkiye Muhasebe Standartları | 1.391 | 1.079 | **312** | %78 |
| KGK | g) Sürdürülebilirlik Denetimi | 300 | 0 | **300** | %0 |
| KGK | f) Kurumsal Sürdürülebilirlik Raporlaması | 300 | 3 | **297** | %1 |
| SGS | Denetim | 1.050 | 859 | **191** | %82 |

**Ağır boşluklar** — çıkmışta ≥ 3 dönem var, bizde hiç yok: 362 konu (veri/konu-koprusu-ozet.json). En çok çıkan 25'i:

| Sınav | Konu | Dönem | Çıkmış soru | Arşiv dersi | Dayanak | Güç |
|---|---|---:|---:|---|---|---|
| KGK | yonetim kurulu komiteleri | 15 | 15 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / Kurumsal Yonetim Ilkeleri ve Finansal Yonetim | TOBB/Odalar K. (5174 s.K.) | ZAYIF |
| KGK | sermaye piyasasi suclari | 10 | 10 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasası Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / Sermaye Piyasası |  | OLCULMEDI |
| KGK | sermaye piyasasi kurumlari | 10 | 10 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasası Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / Sermaye Piyasası |  | OLCULMEDI |
| KGK | kayitli sermaye sistemi | 10 | 10 | Sermaye Piyasası Mevzuatı / Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / sermaye piyasasi bankacilik sigortacilik | TTK (6102 s.K.) m.482 | TEYITLI |
| SGS | kelime bilgisi | 9 | 14 | Yabanci Dil |  | OLCULMEDI |
| KGK | tespit edememe riski | 9 | 9 | Denetim |  | OLCULMEDI |
| KGK | net isletme sermayesi | 9 | 12 | Muhasebe / Kurumsal Yönetim İlkeleri ve Finansal Yönetim | Teori Notu - isletme sermayesi yonetimi | TEYITLI |
| SGS | sozcukte anlam | 8 | 8 | Genel Kultur-Genel Yetenek |  | OLCULMEDI |
| KGK | ic kontrol bilesenleri | 8 | 8 | Denetim | BDS 315 | ZAYIF |
| KGK | bilesik faiz hesabi | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim | SPK Tebliğ (Seri: V, No: 34) | ZAYIF |
| KGK | faaliyet raporu icerigi | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / kurumsal yonetim ve finansal yonetim | SPK Karari | ZAYIF |
| KGK | kar payi avansi | 7 | 7 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Sermaye Piyasası Mevzuatı | Kar Payi Tebligi (II-19.1) | ZAYIF |
| KGK | azalan bakiyeler amortisman | 7 | 7 | Muhasebe | VUK (213 s.K.) m.315 - Amortismana tabi tutulur. Normal amortisman | TEYITLI |
| KGK | banka kurulus sartlari | 7 | 7 | Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / sermaye piyasasi bankacilik sigortacilik / Sermaye Piyasasi, Bankacilik, Sigortacilik ve Ozel Emeklilik Mevzuati / Bankacılık Mevzuatı / Bankacılık | Bankacılık K. (5411 s.K.) | ZAYIF |
| KGK | sistematik olmayan risk | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim | TFRS 17 | ZAYIF |
| SGS | cumle tamamlama-kosul | 7 | 7 | Yabanci Dil |  | OLCULMEDI |
| SMMM | gelir tablosu duzenleme | 7 | 7 | Finansal Muhasebe | SMMM K. (3568 s.K.) m.29 | TEYITLI |
| KGK | tahvil özellikleri | 7 | 7 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı / Kurumsal Yonetim Ilkeleri ve Finansal Yonetim | SPK Karari | ZAYIF |
| KGK | ticari isletme unsurlari | 7 | 7 | Genel Hukuk Mevzuatı / Genel Hukuk Mevzuati |  | OLCULMEDI |
| KGK | bds 600 topluluk denetimi | 7 | 7 | Türkiye Denetim Standartları / Denetim | BDS 600 | GUCLU |
| KGK | bds 320 onemlilik | 6 | 6 | Denetim / Türkiye Denetim Standartları | BDS 320 | GUCLU |
| KGK | satilan mal maliyeti | 6 | 6 | Muhasebe | THP 622 | TEYITLI |
| KGK | net bugunku deger | 6 | 6 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim / kurumsal yonetim ve finansal yonetim / Kurumsal Yonetim Ilkeleri ve Finansal Yonetim | SPK Tebliğ (III-59.1) | ZAYIF |
| KGK | sermaye yapisi yaklasimlari | 6 | 6 | Kurumsal Yönetim İlkeleri ve Finansal Yönetim |  | OLCULMEDI |
| KGK | bilanco hesaplari | 6 | 6 | Muhasebe | VERGİ USUL KANUNU GENEL TEBLİĞİ (SIRA NO: 555) | ZAYIF |

Bekleyen üretim partisi: 0 (veri/bekleyen-partiler.json).

---
_Bu sayfayı elle düzenleme; girdisini düzelt, robot yeniden yazar._
