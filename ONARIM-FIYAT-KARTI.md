# ONARIM FİYAT KARTI — 02.08.2026

> ## 🔴 DÜZELTME (02.08 gece) — TAHMİNİM 3,5 KAT YÜKSEKMİŞ
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
> **Sonuç: Paket C (tam kasa) 168 USD değil, ~60-70 USD bandında.** Aşağıdaki C rakamı yukarı sapmalıdır.
> **Ders:** kendi katsayımı uydurmuşum; scriptin ölçülmüş birimi varmış. Rakam disiplini burada da geçerli —
> tahmin yapmadan önce "bunu ölçen bir şey var mı" diye bak.


**Cem'in kuralı:** "Paralı işlemi bir kez çalıştırıp bırakalım." · "Paralıdan önce tüm yutma."
**Bu kart ne için:** Tek paralı koşuya girmeden önce **ne kadar iş var, ne kadar tutar** — rakamla.

---

## 1. ÖLÇÜM — kasada ne var (tahmin değil, sayım)

Kaynak: `veri/onarim-tarama.json` (02.08.2026 12:49, taranan **26.992** soru; kasa o günden beri 27.478'e çıktı).

| Kod | Sorun | Adet | Nasıl düzelir |
|---|---|---|---|
| T1 | Mükerrer soru (852 grup) | **3.821** soru | **BEDAVA** — grup başına en iyisi kalır, kural belli |
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

| Kalem | Adet | Tahmini |
|---|---|---|
| Paket A | ~1.400 | 4 USD |
| "Doğrusu" — tüm kasa | 26.991 | 81 USD |
| Tablo backfill — tamamı | 8.877 | 44 USD |
| T3 konu etiketi (kalan) | ~2.000 | 3 USD |
| Hakem yeniden yargılama — tamamı | 27.478 | 36 USD |
| **TOPLAM** | **~27.500 soru** | **≈ 168 USD** |

---

## 4. BENİM ÖNERİM: A → ölç → B

**Neden C değil:** 27.478 sorunun tamamını cilalamak 168 USD ve **bunların çoğu asla öğrenciye gitmeyecek** — mükerrer eleme sonrası kasa zaten küçülecek (852 gruptan 2.969 soru düşecek), üstelik SGS bankası bazı derslerde zaten eksik. Kullanılmayacak soruya para vermeyelim.

**Neden A ile başla:** 4 dolara bildiğimiz bütün yanlışlar kapanır. Bu, "sıfır yanlış" iddiasının bedeli — ve çok ucuz.

**Sonra:** A'nın gerçek faturası görülünce tahmin katsayıları gerçek rakamla değişir; B'yi o zaman **kesin fiyatla** basarız.

---

## 5. ÖNCE BİTMESİ GEREKENLER (paralıdan önce)

- [x] Yutma duvarı — **açıldı** (ambar 21.860 belge, +2.363)
- [ ] Manifest başındaki 5 kaynak (4 yapılandırma kanunu + Bağımsız Denetim Yönetmeliği) — koşuda
- [x] Şık dağılımı dengelendi (19.862 soru)
- [x] Kirli sorular yayından çekildi (466)
- [ ] **BEDAVA onarımlar önce:** T1 mükerrer eleme + T2 etiket remap + T5 ASCII + T6 + T8 — bunlar paralı koşunun iş yükünü **düşürür** (3.821 mükerrer elenirse Doğrusu/tablo maliyeti de düşer)

> **Sıra önemli:** önce bedava eleme, sonra paralı yazım. Tersi yapılırsa eleyeceğimiz soruya para vermiş oluruz.

---

## 6. CEM'İN KARARI

- [ ] **A** — 4 USD, bildiğimiz yanlışlar kapansın
- [ ] **B** — 44 USD, satılabilir banka
- [ ] **C** — 168 USD, tam kasa
- [ ] Önce **pilot**: 200 soruluk gerçek fatura ölçümü (≈0,6 USD), sonra karar

*Rakamlar KDV/kur dalgalanmasına göre değişebilir; tahmin işaretli kalemler pilot sonrası güncellenecek.*
