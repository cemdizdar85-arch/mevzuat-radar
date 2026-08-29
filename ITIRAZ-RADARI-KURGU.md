# İtiraz Radarı — Sprint 2 kurgusu

**29.08.2026 · Cem "3 yap" · Marka ailesinin son eksik ayağı**

---

## 1. Hangi boşluğu kapatıyor

Marka ailesinde dört ayak duruyor: **portföy** (unvandan sicil taraması), **yenileme**
(m.23 takvimi), **benzer başvuru** (`marka-izleme.html`), **lisans/devir**. İtiraz
tarafı ise yarım:

| Bugün var olan | Eksik olan |
|---|---|
| `marka-itiraz.html` — kullanıcı iki markayı **elle** girer, benzerlik + sınıf çakışması hesaplanır | Kimse ona "**şu başvuru yayımlandı, senin markana benziyor, süren şu gün doluyor**" demiyor |
| `marka-izleme.html` — yeni başvuruları tarar | O başvurular **"Başvuru" aşamasında**: henüz yayımlanmadıkları için itiraz süresi başlamamıştır |

Yani elimizde **eşleştirme motoru var, yem yok**. İtiraz süresi yayımdan iki aydır
(SMK m.18) ve kaçan süre geri gelmez — ürünün bütün vaadi bu cümlede.

## 2. Kaynak kararı: bülten PDF'i değil, TMview

Marka Bülteni PDF'i **576 MB ve gövdesi font-şifreli** (harfler Sezar-3 kaymış).
Kırılabilir ama gerçek mühendislik ister ve her iki haftada bir yeniden yapılır.

**Gerek yok.** TMview'in `fCOpposable` süzgeci bültenin API karşılığıdır.
**29.08.2026 ölçümü (tarayıcıdan, kimliksiz, CAPTCHA yok):**

```
POST https://www.tmdn.org/tmview/api/search/results?translate=true
{ "fOffices":["TR"], "fCOpposable":true, ... }
→ HTTP 200 · totalResults = 17.660
```

Dönen alanlar: `tmName`, `applicationNumber`, `applicationDate`, `tradeMarkStatus`,
`niceClass`, `applicantName`, `ST13`, **`oppositionPeriodStart`**, `oppositionPeriodEnd`,
`oppositionDeadLine`.

`oppositionPeriodStart` = **gerçek bülten yayım tarihi**. Aradığımız çapa budur.

## 3. 🔴 Ölçülen tuzak — bu kurgunun en önemli maddesi

**TMview'in kendi bitiş tarihi TÜRKİYE İÇİN YANLIŞ ve bizi yalancı çıkarır.**

100 kayıtlık örneklem (en yeni başvurular, 29.08.2026):

| Ölçüm | Sonuç |
|---|---|
| `oppositionPeriodEnd − Start` | **99 kayıtta tam 92 gün** (≈3 ay) |
| SMK m.18'in gerçek süresi | **2 ay** |
| Aynı 100 kaydın SMK'ya göre durumu | **7 tanesinin süresi ZATEN DOLMUŞ**, 93'ü açık |
| Sağlıksız kayıt | 1 tanesinin penceresi **9.315 gün** (2012 tarihli, "Tescilli") |

Yani `fCOpposable` listesini olduğu gibi gösterirsek, süresi dolmuş bir başvuru için
kullanıcıya **"hâlâ vaktin var"** demiş oluruz. Ürünün vaadinin tam tersi, ve hukuken
sonuç doğuran bir yanlış.

**Kural:** TMview'in `oppositionPeriodEnd` / `oppositionDeadLine` alanları
**KULLANILMAZ**. Son gün her zaman:

```
son_gun = oppositionPeriodStart + 2 ay        (SMK m.18)
```

**İkinci kural:** `tradeMarkStatus` "Tescilli" olan ve penceresi 92 günden uzun olan
kayıtlar **elenir** — bunlar kaynağın çöpü.

## 4. Veri hattı

TMview **CORS'a kapalı** (OPTIONS 403) → tarayıcı doğrudan çağıramaz. İhale/alacak
deseni aynen kullanılır: **robot çeker → statik JSON → istemci eşler.**

```
motor/marka-itiraz-hasat.ps1        (yeni)
  ├─ TMview fCOpposable=true, oppositionPeriodStart'a göre sıralı
  ├─ 10.000 SERT TAVAN (ES max_result_window) → gün-gün pencereleme
  ├─ ayıklama: Tescilli ele, pencere>92 gün ele
  ├─ son_gun = start + 2 ay  (bizim hesabımız)
  └─ veri/marka-itiraz-acik.json   (kompakt dizi + kolon başlığı)
```

**Neden kompakt dizi:** `marka-yeni-basvurular.json`'da ölçülmüştü — nesne dizisi
5,2 MB, kompakt dizi 0,88 MB. Aynı biçim kullanılır.
⚠️ **PS 5.1 tuzağı:** `ConvertTo-Json` iç dizileri `{value,Count}` içine sarar;
gövde elle kurulur (mevcut hasatçıdaki `JStr`+join deseni).

**Retensiyon:** bir kayıt `son_gun`'den 15 gün sonra düşer (geçmişi göstermeye gerek
yok, dosya şişmesin).

## 5. Eşleştirme — kopya açılmaz

Benzerlik motoru zaten üç yerde var (`marka-izleme.html` istemcide,
`marka-watch-kullanici.ps1` PowerShell'de, `marka-itiraz.html` elle giriş için):
**norm + fonetik + Levenshtein + Nice sınıf çakışması**. Dördüncüsü yazılmaz;
`marka-izleme.html`'deki işlev ortak bir dosyaya alınır ve iki sayfa onu paylaşır.

Sınıf kilidi kritik: benzer işaret ama **farklı sınıf → DÜŞÜK**. (Cem'in "bir sürü
DIZDAR var" derdi: aynı kelime farklı sınıfta yasal olarak yan yana durur.)

## 6. Kullanıcı ne görür

Kart sözleşmesi — **dört alan, fazlası yok**:

1. **Kim:** başvuru markası + sahibi + sınıfları
2. **Neye benziyor:** senin hangi markan, risk yüzdesi, sınıf çakışıyor mu
3. **Kaç günün kaldı:** `son_gun` + geri sayım (kaynağın 92 günü değil, m.18'in 2 ayı)
4. **Ne yapabilirsin:** itiraz gerekçeleri (m.6/1 karıştırılma · m.6/4-5 tanınmışlık),
   ve **karşı tarafın elindeki savunma: m.19/2 kullanmama def'i** — markan 5 yıldan
   eski tescilli ve kullanmıyorsan itirazın reddedilir. Bunu söylemeyen bir ürün
   müşteriyi boşa masrafa sokar.

Yer: `marka-itiraz.html` üstüne "**Senin markana benzeyen, itiraz süresi açık
başvurular**" bloğu + panelde (`radar-app.html`) mevcut marka uyarı bandına yeni tip.

## 7. Uyarı ve mail

Yeni tablo **açılmaz**. Mevcut `marka_uyari` tablosuna yeni tip: `tip='itiraz-suresi'`.
`marka-watch-kullanici.ps1`'in yanına ikinci mod eklenir; dedup ve Resend hattı aynen.

**Gönderim ritmi:** yayım günü bir kez + **son 15 gün kala bir kez daha**. Her gün
mail atmak alarmı gürültüye çevirir (Günlük Kanun Aynası dersi: üçüncüsünden sonra
kimse okumaz).

## 8. Kapılar (bu iş kapı olmadan bitmiş sayılmaz)

- **Tarih kapısı:** üretilen her `son_gun` için `son_gun − start == 2 ay` doğrulanır.
  Bir gün kaynağın alanına dönersek kapı kırmızı yakar.
- **Kaynak sağlığı:** TMview bot koruması **HTTP 200 döndürüp gövdede JS challenge**
  verebiliyor (20.08'de yaşandı: "bu firmanın markası yok" diye yanlış cevap
  üretecekti). Gövde JSON mu diye bakılır, 3 kez artan beklemeyle denenir, olmazsa
  **HATA** — sessiz boş liste yok.
- **Açılış kapısı** (29.08'de kuruldu) yeni sayfayı zaten denetler.

## 9. Yapmayacaklarımız — dürüst sınırlar

- ❌ **İtirazı biz dosyalamıyoruz.** Marka vekili değiliz; TÜRKPATENT'e itiraz
  başvurusunu kullanıcı ya da vekili yapar. Ürün süreyi ve gerekçeyi gösterir.
- ❌ **"Bu itirazı kazanırsın" demiyoruz.** Karıştırılma ihtimali takdiridir.
- ❌ **Yurt dışı (EM/WO) otomatik itiraz takibi yok.** TMview'de arama var ama
  otomatik takip için güvenilir uç yok — 13.07'de yazıldığı gibi, belgesiz SPA'yı
  scraping'le "otomatik takip" diye satmayız.
- ⚠️ **Şekil/logo benzerliği** bu sprintte kapsam dışı. dHash altyapısı
  (`marka-logo-hash.ps1`) var ama kapsama robot işledikçe doluyor; kelime
  benzerliğiyle başlanır.

## 10. İş sırası

| # | İş | Bağımlılık |
|---|---|---|
| 1 | `motor/marka-itiraz-hasat.ps1` + gün-gün pencereleme + ayıklama | — |
| 2 | Tarih kapısı (2 ay doğrulaması) + kaynak sağlığı freni | 1 |
| 3 | Benzerlik motorunun ortak dosyaya alınması (üç kopya → bir kaynak) | — |
| 4 | `marka-itiraz.html` üstüne "sana benzeyen açık başvurular" bloğu | 1, 3 |
| 5 | `marka_uyari` tip='itiraz-suresi' + panel bandı + mail (iki ritim) | 1 |
| 6 | `kaynak.yml`'e günlük adım | 1, 2 |

**Maliyet:** 0 USD. TMview kimliksiz ve CAPTCHA'sız; API çağrısı yok, robot
GitHub Actions'ta koşar.

---

### Karar bekleyen tek şey

Bu kurgu **ölçüme dayanıyor** (29.08 TMview turu) ama **Cem'in onayı olmadan
kodlanmaz**. Onay verilirse sıra yukarıdaki tablodur; 1–2 birlikte yapılır, çünkü
kapısız hasat "yanlış tarih üreten" bir robot demektir.
