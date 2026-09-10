# YUTULMAYACAK MEVZUAT — kara liste

> **10.09.2026.** Çıkmış sınavda geçen ama **bugün soru üretilemeyecek** mevzuat.
> Bu dosya bir "eksik listesi" DEĞİL, tam tersi: eksik SANILIP yanlışlıkla
> yutulmasın diye tutulur.
>
> **KURAL:** Eksik kaynak denetimi yapan her araç bu listeyi okur. Buradaki bir
> kalem "ambarda yok" diye raporlanırsa **doğru** raporlanmıştır — yutulmaz.

<!--
  MAKİNE OKUMASI — aşağıdaki `KARA:` satırları araçlar tarafından okunur.
  ⚠️ Serbest metinden regex ile kimlik çıkarmak DENENDİ ve YANLIŞ ÇALIŞTI
  (10.09): desen, "Halefi" sütunundaki TFRS 15 / TFRS 16'yı da yakaladı ve
  onları kara listeye aldı — yani YUTULMASI GEREKEN iki standart "bilerek
  yutulmadı" diye işaretlendi. Gerçeğin tam tersi.
  Bu yüzden liste artık TAHMİN EDİLMEZ, AÇIKÇA YAZILIR. Yeni kalem eklerken
  hem aşağıdaki tabloya hem buraya bir `KARA:` satırı ekle.

  KARA: TMS 18
  KARA: TMS 17
  KARA: TMS 11
  KARA: TMS 39
  KARA: TFRS 4
  KARA: KKS 1
  KARA: BDS 110
  KARA: 6111
  KARA: 6326
  KARA: 3713
  KARA: 956
  KARA: 13033
-->


---

## Neden bu liste gerekli

Çıkmış sınav külliyatı 2005'ten bugüne uzanıyor. Bir kanun 2012'de sorulmuş
olabilir ve bugün yürürlükte olmayabilir. Ölçüm aracı "sınavda 40 atıf var,
ambarda yok" der ve **haklı görünür** — ama yutmak yanlış olur, çünkü motor o
metinden bugün geçerli olmayan soru üretmeye başlar.

**"Sınavda geçiyor" ≠ "bugün geçerli".**

---

## 1 · MÜLGA MUHASEBE STANDARTLARI

Üçü de yürürlükten kalktı; halefleri ambarda mevcut.

| Standart | Sınav atfı | Durum | Halefi (ambarda) |
|---|---:|---|---|
| **TMS 18** Hasılat | 40 | mülga | **TFRS 15** ✅ (94 atıf) |
| **TMS 17** Kiralamalar | 35 | mülga | **TFRS 16** ✅ (68 atıf) |
| **TMS 11** İnşaat Sözleşmeleri | 32 | mülga | **TFRS 15** ✅ |
| **TMS 39** Finansal Araçlar | 16 | mülga | **TFRS 9** ✅ (120 atıf) |
| **TFRS 4** Sigorta Sözleşmeleri | 22 | mülga | **TFRS 17** ✅ (52 atıf) |

*(TMS 39 ve TFRS 4, 10.09'da `arac/sinav-atif-taramasi.ps1` ile bulundu — elle
yaptığım ilk tarama standartlarda ≥4 atıf eşiği kullandığı için ikisini de
kaçırmıştı. Araç eşiği 3'e indirince çıktılar.)*

### KKS 1 — mülga değil, ADI DEĞİŞTİ

| Standart | Sınav atfı | Durum | Ambardaki karşılığı |
|---|---:|---|---|
| **KKS 1** Kalite Kontrol Standardı | 16 | ad değişti | **KYS 1** ✅ (`KYS1`) |

Kalite Kontrol Standardı (KKS), yeni çerçevede **Kalite Yönetimi Standardı
(KYS)** oldu. Eksik değil; denetim aracı eski adı arıyor, ambar yeni adı
taşıyor. **Bu bir yutma işi değil, bir ad köprüsü işidir.**

### Yanlış yakalamalar (mevzuat kimliği değil)

| Yakalanan | Atıf | Ne |
|---|---:|---|
| `BDS 110` | 3 | BDS numaraları 200'den başlar — böyle bir standart yok |
| `956` | 8 | sayı deseni; kanun numarası değil |
| `13033` | 3 | kanun numarası değil |

Eski kitapçıklarda geçiyorlar çünkü o dönem yürürlükteydiler. Bugün bu
standartlardan soru üretmek **yanlış öğretmek** olur.

---

## 2 · SÜRESİ DOLMUŞ YAPILANDIRMA KANUNLARI

### 6111 sayılı Kanun (2011) — 8 sınav atfı

**Ölçüldü (10.09):** 8 atıfın tamamı **2012–2014 SMMM yeterlilik** sınavlarından
ve hepsi iki geçici hükme:

- `m.10/1` — *"bildirimde bulunulan kıymetler için amortisman ayrılmayacağından"*
- `m.6/9` — *"matrah artırımında bulunulan yıllara ilişkin zararların %50'si mahsup edilemez"*

Bunlar 2011 yapılandırmasının **başvuru dönemine bağlı** hükümleridir; o dönem
kapandı. Bugünün adayına bu soru sorulmaz.

**Halefleri ambarda:** `yapilandirma6736` (2016) · `yapilandirma7143` (2018) ·
`yapilandirma7326` (2021) · `yapilandirma7440` (2023)

---

## 3 · KENAR ATIFLAR — mevzuat değil, yan referans

Sınav metninde geçiyor ama sınav konusu değil; genellikle bir başka hükmün
içinde atıf olarak duruyor.

| No | Atıf | Not |
|---|---:|---|
| 6326 Petrol K. | 5 | yan atıf |
| 3713 Terörle Mücadele K. | 3 | yan atıf |
| 956 | 8 | sayı deseni yanlış yakalamış olabilir — ölçülemedi |
| 13033 | 3 | kanun numarası değil |

Bunlar için karar: **yutulmaz**, ama "ölçülemedi" olarak açık kalır. Biri
gerçekten sınav konusu çıkarsa ayrı ele alınır.

---

## Bu listeye ekleme kuralı

Bir mevzuat buraya ancak **bağlamı okunduktan sonra** eklenir. "Atıf sayısı az"
tek başına yeterli değil — atıfın **nerede ve hangi hükme** yapıldığı görülür.
6111 kararı bu şekilde verildi: 8 atıfın tamamı açılıp okundu, ikisinin de
süreye bağlı geçici hüküm olduğu görüldü.
