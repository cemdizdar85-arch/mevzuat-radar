# MUSLUK PROTOKOLÜ — paralı üretim ne zaman, nasıl, ne kadar

> **Neden var:** 27.07'de Cem'in tespiti — *"musluk boşa para akıttı; Matematik'te mevzuat yok, soru çıkmadı; yanlış çıkan soru var. Musluğu açacağız ama boşa atmayacak."*
> Bu belge, o "boşa atmama"nın somut kuralıdır. **Paralı hiçbir parti bu protokole uymadan koşmaz.**

---

## 0. Musluğun geçmişte neden boşa aktığı — ölçülmüş üç sebep

| # | Sebep | Kanıt | Durum |
|---|---|---|---|
| 1 | Kaynağı olmayan derste üretim denendi | Matematik'in mevzuatı yok; üretilen soruların **tamamı** teyit kapısında elendi, kasada 0 Matematik kaldı | ✅ Karne kapısı kuruldu |
| 2 | Ambar eksikti | **3.162 kayıt** hiç yüklenmemiş, **1.730 madde** 1800 karakterde kesikti | ✅ Düzeltildi (28.07) |
| 3 | Denetçi kendi çıktısını kesiyordu | K2'de `max_tokens=400`, Haiku'nun JSON'u ortadan biçiliyordu; **parası ödenmiş** 2.079 iş "hata" sayıldı | ✅ Düzeltildi |

**Üçü de kapatıldı.** Musluk şimdi açılsa aynı şekilde akmaz.

---

## 1. AÇILMA ŞARTLARI — dördü birden sağlanmadan parti koşmaz

1. **Karne yeşil.** `motor/ders-karnesi.ps1` çıktısında ders **"AÇIK"** olacak (hazırlık ≥ %70).
2. **Konu bazında kaynak var.** `veri/konu-kaynak-karnesi.json`'da o konu **ÜRET** olacak. `KAYNAK YOK` ve `MEVZUAT-DIŞI` satırlarına fabrika **girmez**.
3. **Kasa sayımı bilinir.** O derste kaç soru olduğu ölçülmüş olacak — hedef, boşluğa göre konur.
4. **Maliyet önceden bildirilmiş.** Cem'e tutar söylenmeden paralı parti başlamaz.

### Fabrikanın ASLA girmeyeceği yer

| Ders | Soru | Neden |
|---|---|---|
| Türkçe | 7 | Mevzuatı yok |
| Matematik | 8 | Mevzuatı yok |
| İnkılap Tarihi | 5 | Mevzuatı yok |
| Yabancı Dil | 10 | Mevzuatı yok |
| **Toplam** | **30 (%23)** | **Elle yazılır** |

---

## 2. PİLOT — ilk paralı koşu

**İlke: önce küçük, ölç, sonra büyüt.**

- **Ders:** Vergi Hukuku *(karnede en hazır ders — %91)*
- **Hacim:** 50 soru
- **Yöntem:** Batch API (%50 indirim). İndirimsiz koşu yapılmaz.
- **Ölçülecekler:** toplam maliyet · soru başına maliyet · teyit kapısından geçme oranı · K2 denetçi onay oranı · GM okumasında düzeltme gerektiren soru oranı
- **Rapor:** Cem'e rakamla bildirilir. **Onay gelmeden ikinci parti koşmaz.**

### Pilot başarı eşiği
Teyit + denetçi süzgecinden geçen soru oranı **%70'in altındaysa** musluk kapatılır, sebep aranır. Çünkü elenen her soru **ödenmiş** paradır.

---

## 3. SIRA — sınav ağırlığına göre

| Sıra | Ders | Soru | Karne |
|---|---|---|---|
| 1 | **Finansal Muhasebe** | 26 | AÇIK |
| 2 | **Denetim** | 16 | AÇIK |
| 3 | Hukuk grubu (5 ders) | 30 | AÇIK |
| 4 | Maliyet Muhasebesi | 8 | AÇIK |
| 5 | Mali Tablolar Analizi | 8 | şarta bağlı |
| 6 | Ekonomi + Maliye | 12 | AÇIK |
| ❌ | GK + YD + Matematik | 30 | **açılmaz** |

---

## 4. KOŞU SONRASI ZORUNLU KONTROL

Bugün öğrenilen ders: **"yeşil koşu ≠ tam veri."**

- [ ] Üretilen soru sayısı ile kasaya giren sayı **karşılaştırılır**
- [ ] Fark varsa iş **kırmızı** sayılır, sebep bulunmadan devam edilmez
- [ ] Karantinaya düşen sorular **GM tarafından okunur** — otomatik silinmez
- [ ] Maliyet, tahminle karşılaştırılıp sapma bildirilir

---

## 5. DEĞİŞMEZ KURALLAR

- Kaynağı olmayan konuya fabrika **girmez**
- İndirimsiz (Batch dışı) paralı koşu **yapılmaz**
- Maliyet **önceden** söylenir, sonradan değil
- Hiçbir soru **kaynağı doğrulanmadan** kasaya girmez
- Karantina **otomatik silinmez**
- Rakam **uydurulmaz** — ölçülmemişse "ölçülmedi" denir

---

*Son güncelleme: 28.07.2026 — Konu-Kaynak Karnesi ve Ders Karnesi araçları kurulduktan sonra.*
