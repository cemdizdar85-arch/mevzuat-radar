# MUSLUK PROTOKOLÜ — paralı üretim ne zaman, nasıl, ne kadar

> **Neden var:** 27.07'de Cem'in tespiti — *"musluk boşa para akıttı; Matematik'te mevzuat yok, soru çıkmadı; yanlış çıkan soru var. Musluğu açacağız ama boşa atmayacak."*
> Bu belge, o "boşa atmama"nın somut kuralıdır. **Paralı hiçbir parti bu protokole uymadan koşmaz.**

---

## 0. Musluğun geçmişte neden boşa aktığı — ölçülmüş üç sebep

| # | Sebep | Kanıt | Durum |
|---|---|---|---|
| 1 | ~~Kaynağı olmayan derste üretim denendi~~ **Matematiğe YANLIŞ KAPI uygulandı** | Üretilen sorular teyit kapısında elendi, kasada 0 Matematik kaldı — **ama 28.07'de o soruların 51'i elle çözüldü ve 51'i de doğru çıktı.** Sorunlu olan sorular değil, onlara uygulanan kaynak-teyidi kapısıydı | ✅ Kapı derse göre seçiliyor |
| 2 | Ambar eksikti | **3.162 kayıt** hiç yüklenmemiş, **1.730 madde** 1800 karakterde kesikti | ✅ Düzeltildi (28.07) |
| 3 | Denetçi kendi çıktısını kesiyordu | K2'de `max_tokens=400`, Haiku'nun JSON'u ortadan biçiliyordu; **parası ödenmiş** 2.079 iş "hata" sayıldı | ✅ Düzeltildi |

| 4 | **Mükerrer kontrolü kökün ilk 60 karakterine bakıyordu** | *"Aşağıdaki cümlelerin hangisinde bir yazım yanlışı vardır?"* 54 karakter — o kalıbı kullanan ikinci soru, farklı bir cümleyi sorsa bile parası ödendikten sonra siliniyordu. Ölçüldü: `mukerrer-kok` damgalı 38 sorunun 38'inin de havuzda ikizi yok | ✅ Düzeltildi (28.07): ortak `KokAnahtar()` = tam kök + şıklar |
| 5 | **Hiçbir kapı "madde gerçekten bunu mu diyor" diye sormuyor** | GM okumasında 17 mevzuat sorusunda **4 hata** (%24). Üçü de kaynak teyidinden **ve** iki çözücünün mutabakatından geçmişti: 5510 m.8 istisnayı başka gruba tanıyor · TTK'da "sermaye azaltılır" hükmü yok · ıskat ihtarı noterle değil · kira bedeline %70 uygulanmıyor | 🔴 **AÇIK** — önerilen çözüm: çözücüye atıf yapılan maddenin ambardaki METNİ de verilsin |

**1–4 kapatıldı. 5 duruyor ve musluk kararının asıl konusu odur.**

---

## 0b. 248 SORU OKUNDU — riskin nerede olduğu artık ölçüldü

Sorun "mevzuat dersi" değil, **soru tipi**. Ölçüm (28.07 GM okuması):

| soru tipi | okunan | hata | musluk |
|---|---|---|---|
| Matematik | 51 | 0 | ✅ açık |
| Genel Kültür / Türkçe | 105 | 0 | ✅ açık |
| Yabancı Dil | 34 | 0 | ✅ açık |
| Teknik/hesap/kavram (Maliyet, Denetim, Fin.Muh.) | 22 | 0 | ✅ açık |
| **Kanun metnindeki spesifik RAKAM** (madde no, gün, oran, eşik) | 36 | **%33–68** | 🔴 **kapalı** |

Model muhasebe ve denetim **bilgisini** biliyor — Tekdüzen Hesap Planı kodlarının (730, 770, 760, 197, 129, 644, 121, 128) hepsini doğru kullandı. Kaybettiği tek yer kanun maddesinin **numarası ve içindeki sayı**: Meslek Hukuku'nda aynı havuza hem "15 gün" hem "30 gün" koydu (doğrusu 3568 m.25: **otuz gün**), sır saklamayı m.45'e bağladı (doğrusu **m.43**), Birlik gelirlerini m.51'e bağladı (o madde *"Bu Kanun yayımı tarihinde yürürlüğe girer"* diyor).

**Operasyonel sonuç:** madde numarası / süre / oran / eşik soran soru üretilecekse, çözücüye o maddenin ambardaki **metni verilmeden** parti koşulmaz. Bu tek değişiklik ölçülen hata sınıfının tamamına denk gelir.

---

## 1. AÇILMA ŞARTLARI — dördü birden sağlanmadan parti koşmaz

1. **Karne yeşil.** `motor/ders-karnesi.ps1` çıktısında ders **"AÇIK"** olacak (hazırlık ≥ %70).
2. **Konu bazında kaynak var.** `veri/konu-kaynak-karnesi.json`'da o konu **ÜRET** olacak. `KAYNAK YOK` ve `MEVZUAT-DIŞI` satırlarına fabrika **girmez**.
3. **Kasa sayımı bilinir.** O derste kaç soru olduğu ölçülmüş olacak — hedef, boşluğa göre konur.
4. **Maliyet önceden bildirilmiş.** Cem'e tutar söylenmeden paralı parti başlamaz.

### Mevzuatı olmayan dersler — 28.07 ÖLÇÜMÜYLE DÜZELTİLDİ

**Eski kural yanlıştı.** "Mevzuatı yok → fabrika girmez" demiştik. 28.07'de GM okuması bu varsayımı ölçtü ve çürüttü:

> **Matematik-İstatistik, 51 soru elle çözüldü: 51'inin de cevabı DOĞRU.** Sıfır hata.
> Aynı gün mevzuat sorularında 17 okumada 4 hata çıktı (%24).

Sebep: bu derslerin sorunu **kaynak değil, doğrulama yöntemi**. Fabrika Matematik'te başarısız olmuyordu; **kaynak teyidi kapısı** (ambarda madde ara) matematiğe yanlış uygulanıyordu. Matematiğin doğru kapısı bellidir ve %100 kesindir: **soruyu çöz, işaretli cevapla karşılaştır.**

| Ders | Soru | Doğru kapı | Karar |
|---|---|---|---|
| **Matematik** | 8 | Çöz–karşılaştır (kesin) | ✅ **AÇIK** — ölçüldü, 51/51 |
| Türkçe | 7 | Dil bilgisi kuralı adı = kaynak | şartlı (ölçülmedi) |
| Yabancı Dil | 10 | Gramer kuralı adı = kaynak | şartlı (ölçülmedi) |
| İnkılap Tarihi | 5 | Tarih/olay teyidi gerekir | ❌ kapalı (kaynak yok) |

**Matematik için zorunlu ek şart — konu tavanı.** Aynı 51 soruda **12'si tek bir konudaydı ("sabit fonksiyon", %24)**. Bu bir cevap hatası değil, **üretim planı hatası**. Bundan sonra matematik partisinde **hiçbir konu partinin %15'ini geçemez**; görev listesi buna göre kurulur.

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
