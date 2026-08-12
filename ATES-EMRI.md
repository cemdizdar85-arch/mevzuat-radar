# ATEŞ EMRİ — API açıldığı GÜN koşulacak sıra

**Yazım:** 11.08.2026 · **Cem kararı:** *"Eylül'e bırakamayız; limit açılırsa
yarın burdayız, açmazsa taşınacağız. Bir hafta içinde sorular bitecek."*

Bu belge, tavan hangi kanaldan açılırsa açılsın (Anthropic limit artışı **veya**
Claude Platform on AWS) **aynı gün** koşulacak sırayı tutar. Karar bekleyen
hiçbir adım yok — istek listeleri yazıldı, kapılar kuruldu, hepsi sınandı.

---

## 0. AÇILIŞ KONTROLÜ (5 dakika)

**AWS yolu (12.08 HAZIRLANDI — betik uyarlaması BİTTİ, anahtar bekleniyor):**
1. Cem üç ortam değişkenini girer: `ANTHROPIC_AWS_API_KEY` (AWS Konsolu →
   Claude Platform on AWS → API keys), `AWS_REGION` (workspace'in bölgesi),
   `ANTHROPIC_AWS_WORKSPACE_ID` (`wrkspc_...`)
2. `motor/aws-on-kontrol.ps1` → 4 adım: değişkenler · bekleyen parti ·
   1-jetonluk istek · Batch API. Hepsi yeşilse ateş serbest.
3. Hedef seçimi otomatik (`motor/api-hedef.ps1`): AWS üçlüsü ortamda varsa
   AWS, yoksa Anthropic; `MEVZUAT_API_HEDEF` ile elle seçilir. 7 betik bağlı:
   birlesik-yazim-olcum · profesor-v2 (Mercek A) · mercek-bc · parti-hasat ·
   parti-liste · onbellek-olcum (+ api-hedef). 12.08 sınandı: seçim mantığı
   5/5 test, Anthropic hattından 370 parti listelendi.
   **DİKKAT:** parti kimliği hedefler arası taşınmaz — hedef değiştirmeden
   önce bekleyen partiler ESKİ hedeften hasat edilir (ön-kontrol bunu denetler).

**Anthropic yolu (tavan açılırsa):** değişiklik yok, betikler eskisi gibi.

```
motor/onbellek-olcum.ps1          -> API cevap veriyor mu, onbellek çalışıyor mu
```

## 1. ÖLÇÜM PARTİSİ — 20 soru (~1 USD)

Birleşik yazım istemiyle (11 maddeli güncel istem) 20 soru. Amaç: gerçek
jeton/soru maliyeti. **Rakam Cem'e gider, parti tavanlarını o onaylar.**

## 2. ÜÇ MERCEK — mevcut 3.357'nin denetimi (~167 USD)

Sıra: **önce C** (46) → sonuç okunur → **B** (75) → **A** (46).
Her mercekten sonra en az 10 soru elle okunur. Kırmızı çoksa dur, Cem'e sor.

## 3. YENİDEN YAZIM — fazlalık taşıma + çeşitlilik

Hazır istek listeleri (doygunluk kapısından geçirilmiş):

| Liste | İçerik | Soru |
|---|---|---|
| `veri/ISTEK-parti1-hukuk.csv` | 218 boş madde (TTK 150 · TBK 120 · VUK 100 · AATUHK 40 · KVK 20 hedefli) | **430** |
| `veri/ISTEK-parti2-standart.csv` | 62 standart (önce hiç sorusu olmayan 22'si) | **816** |
| `veri/bos-konu-TEMIZ-LISTE.csv` (durum=BOS-*) | 616 doğrulanmış boş konu | ~1.100 |

**Kaynak malzemesi:** 609 fazlalık soru (VUK m.275 ×196, TBK m.82 ×83…)
silinmez — bu istek listelerindeki yeni hedeflere **yeniden yazdırılır**.
Fazlalıktan karşılanamayan kısım sıfırdan üretilir.

**Zorunlu koşu kuralları (hepsi kurulu):**
1. İstek listesi önce `motor/kaynak-doygunluk-kapisi.ps1 -liste X` süzgecinden geçer
2. Üretim istemi = `birlesik-yazim-olcum.ps1` içindeki **11 maddeli** istem
   (9: temiz bitiş · 10: kök ele vermez · 11: kaynak kotası)
3. Parti kimliği gönderilir gönderilmez `veri/bekleyen-partiler.json`'a yazılır
4. Her partide kabul kapıları: bozulma · kod-ad çifti · TR yoğunluk · benzer_grup
5. Her partiden **en az 10 soru elle okunur** — rapor değil soru

## 4. BASIM

Kapılardan geçen + mercek onaylı sorular `yayin=true`. Geçmeyen basılmaz.

---

## HAZIR OLANLAR (bugün bitirildi — hiçbiri API beklemiyor)

- ✅ İstem 11 maddeli (bozulma, kök-ele-verme, kaynak kotası dahil)
- ✅ Doygunluk kapısı: kanun 2.671 madde + standart 80, sınandı
- ✅ `benzer_grup` dolu (2.352), motor kuralı canlı
- ✅ İstek listeleri: P1 (430) + P2 (816) + boş konu (616 konu)
- ✅ Boş madde önceliği çıkmış-sınav eşleşmesiyle sıralı
- ✅ 59 kök-ele-verme + 31 bozulma onarımı yapılmış, kapıları kurulu
- ✅ Yutma durumu ölçüldü: TSRS 1-2 yutulu (253 KB), 80 standardın hepsi
  ≥3K karakter, kanunlar tam. **Üretim ambar metniyle beslendiği için ambar
  dışına çıkamaz** (BDS 330 ve TFRS 9'da ölçüldü: 84/84 soru ambar içinde).

## BİLİNÇLİ EKSİK — dürüst liste (12.08 güncellendi)

- ~~TFRS 9 6.x ambarda yok~~ → **YUTULDU** (263 parça tam standart, 6.x dahil).
  Ayrıca 12.08: **TFRS 16 tam** (122 parça %99,82) + **BDS 300 tam** (38 parça
  %100) + **BDS 330 tam** (96 parça %100) — itiraf sınıflandırmasının çıkardığı
  üç ince ambar kapatıldı.
- Standart kapasiteleri (`veri/standart-kapasite.csv`) hâlâ ESKİ ince ambara
  göre ölçülü — TFRS 16 / BDS 300 / BDS 330 kapasiteleri artık OLDUĞUNDAN
  DÜŞÜK. Üretimden önce kapasite tablosu bu üçü için yeniden ölçülmeli, yoksa
  doygunluk kapısı bu kaynaklara haksız RED verir.
- Beceri dersleri (P6) için istek listesi henüz yazılmadı — beceri-tabanlı
  ölçüm (#3 bekleyen iş) önkoşul.
- 3 TEORİ-ŞÜPHELİ Ekonomi konusu (Stolper-Samuelson, para çarpanı, tekel
  MR=MC) için öğreti notu ambarda doğrulanmadı — teori notu hattı ayrı iş.
