# SGS SON 20 GÜN — HER KURAL ÖLÇÜLÜR (B30 + B31, Cem 30.10) · ölçü tablosu v1 · 31.10.2026

> Sözleşme B31: yazar/oturum "uydum" diyemez; her soru için ÖLÇÜ SATIRI gösterilir. Ölçü aracı çalışmazsa soru "ÖLÇÜLMEDİ" bekler.
> Bitirme karşılığı: `BITIRME-SORU-STANDARDI.md` bölüm 7. Araç kökü `<S20>` = C:\TETIKTE-CALISMA\sgs-s20-arac.

| Kural | Nasıl ölçülür (araç / kim) | Geçme şartı | Durum |
|---|---|---|---|
| Kanıt cümlesi (D2, Cem "cevap + kural cümleleri") | `<S20>\alinti-kapi.js` (dayanak ambarda aynen) + CIKMIS-DENETIMI kaynak bölümü (denetçi, ambar-oku.js) | dayanak ambarda; doğru cevap/şık/kural cümlesi kaynakta yazılı | ÖLÇÜLÜYOR |
| Çıkmış soruya benzerlik / kopya | CIKMIS-DENETIMI.md (denetçi, cikmis-ara.js) + KAPI-CB (bulut) | aynı bilgi, sınavın sorduğu biçim; ≥2 cümle kopya yok | ÖLÇÜLÜYOR |
| İki kör çözücü (D3) | iki ayrı ajan, yalnız kök + şık (anahtar/açıklama/tablo/adım YOK), cevaplar anahtarla karşılaştırılır | ikisi de anahtarı bulur, "iki şık / kök eksik" notu yok | KURULUYOR (seçimden sonra 7 denemenin tamamı) |
| Kalıp (K4) | `ayir-sgs.js` = ortak kalip-ayirici.js + SGS katmanı | o derste gerçek SGS'de bulunan kalıp | ⚠ **17 kalıp GÜVENİLMEZ** (aşağı bak); kaba grup kısmen |
| Konu içi karışım (B30) | `olcum-2910/konu-kalip-sgs.js` (sgs-konu-okuma.json etiketiyle) + seçimde ders kalıp payı (kalip-ders-pay.json) | ≥5 sorulu konuda tek kalıp ≤%60 (MTA/Maliyet hesap gerçek orana göre ≤%80); "doğrudur" payı ≤ gerçek+10 | ÖLÇÜLÜYOR (seçim kısıtı kuruluyor) |
| Kök uzunluğu (K3) | `profil-kapi.js --hedef kisa` + seçimde KAPI-BENZERLIK (kök medyanı ±%25) | ders gerçek medyanı ±%25 | ÖLÇÜLÜYOR |
| Olumsuz / öncül oranı | KAPI-BENZERLIK (s20-ara.js) | gerçek ±10 puan | ÖLÇÜLÜYOR |
| Şık türü (Ş3) | şıklar sayı / terim / cümle sınıfı (olcu-satiri.js) | beşi aynı tür | ÖLÇÜLÜYOR (satırda) |
| Ş8 sayısal şık sırası · Ş9 hepsi/hiçbiri · D5 398/yuvarlama · K7 ikiz | `olcum-2910/standart-tara.js` | bulgu yok | ÖLÇÜLÜYOR |
| Şık harfi (Ö5; site şıkları karıştırır) | `olcum-2910/harf-tum.js` (görünür alanlar) | bulgu yok | ÖLÇÜLÜYOR |
| Olumsuz kökte ters "Doğrusu:" | `olcum-2910/dogrusu-ters.js` | bulgu yok | ÖLÇÜLÜYOR |
| Kalite kapısı | `arac/hazir-soru-denetle.ps1` + `cizim-kapi.js` + bulut hakem/kör/hakem2 | KUSUR yok | ÖLÇÜLÜYOR |
| Yıl (D7) | `yil-kapi-esdeger.js` + standart-tara D7 | 2026 yıllık gelir/tutar yok | ÖLÇÜLÜYOR |
| Zorluk karışımı | KAPI-BENZERLIK 25/50/25 ±1 | ders başına | ÖLÇÜLÜYOR |
| Cem okuması (D4) | kalite raporu: ders başına örnek sorular, yanında en yakın gerçek SGS sorusu | Cem "sınav sorusu" der | BEKLİYOR |
| Öğrenci verisi (D6/Ş10) | cevap_kayit (≥30 çözüm) | — | açılıştan sonra |

## Kalıp ayırıcının SGS elle etikete uyumu (31.10, B31-1: %90 altı → güvenilmez yazılır)
Elle etiket: `sgs-kalip-elle.json` (139 soru, 2022/1–2026/2, soru 11…119) · `sgs-kalip-elle-2.json` (253 soru, 2019/1–2026/2, soru 5…125) — iki ayrı okuyucu, ayırıcıya bakmadan.
| Ölçü | Örneklem 1 | Örneklem 2 (bağımsız, katman ona göre AYARLANMADI) | Karar |
|---|---|---|---|
| Ortak ayırıcı, 17 kalıp | 113/139 %81 | 186/253 %74 | GÜVENİLMEZ |
| SGS katmanlı, 17 kalıp | 135/139 %97 (katman bu örneklemle yazıldı) | 209/253 **%83** | **GÜVENİLMEZ** (%90 altı) |
| SGS katmanlı, kaba 5 grup | %98 | **%87** | kısmen |
| — olumsuz (B+C) | kesinlik 100 · duyarlılık 100 | kesinlik **99** · duyarlılık **92** | GÜVENİLİR |
| — "doğrudur" (A) | 93 · 93 | kesinlik **100** · duyarlılık 71 | GÜVENİLİR (eksik sayar → fazlalık bulgusu alt sınır) |
| — doğrudan "hangisidir" (M+U+N+O+P) | 100 · 95 | 82 · 88 | güvenilmez |
| — sayısal (F+G+L) | 97 · 100 | 65 · 77 | güvenilmez |
Sonuç: B30 bulgusunun "doğrudur fazla / olumsuz eksik" kısmı geçerli; "doğrudan ↔ hesap" payına dayanan sayılar (MTA hesap açığı, Atatürk/Matematik doğrudan açığı) kuşkulu — kalite raporunda ayrıca işaretlenir.

**Soru başı ölçü satırı** (B31-2): kalite raporunda 910 sorunun her biri için
`id · ders · kalıp ölçülen/ders hedefi · kök kr/hedef · şık türü · kör1/kör2/anahtar · kanıt (alıntı kapısı) · çıkmış denetimi · kalite kapısı · yıl · şık harfi`
— `olcum-2910/olcu-satiri.js` (seçimden sonra). Satırı eksik soru yüklenmez.
