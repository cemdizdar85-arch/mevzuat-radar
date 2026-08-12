# ŞARTNAME KARNESİ — koşudan **önce** bakılacak tablo

**11.08.2026** · Cem'in bugüne kadar koyduğu her şart, üç sütunla ölçülmüş hâli.

**Kural:** kırmızı satır varken **ücretli koşu başlamaz.** Bu tablo, eksikleri koşudan
sonra tek tek keşfetmeyi bitirmek için var — 10.08'de beş ayrı eksik koşudan sonra çıktı
ve her biri para yedi.

Sütunların anlamı:
- **İstem** — şart modele söyleniyor mu
- **Kapı** — makine denetliyor mu (istem tavsiye eder, kapı zorlar)
- **Teslim** — 10.08 koşusunda (3.357 soru) fiilen ölçülen sonuç

---

## A. İÇERİK — yanlış soru yayına giremez

| # | Şart | İstem | Kapı | Teslim (ölçüldü) |
|---|---|---|---|---|
| A1 | Cevap doğru olacak | ✅ | ⛔ yok | **35/35** GM okumasında doğru — Mercek B ölçecek |
| A2 | Aritmetik tutacak | ✅ | ⛔ yok | **35/35** doğru — Mercek B ölçecek |
| A3 | Hesap kodu THP'ye uyacak | ✅ | ✅ KOD AD CIFTI | **35/35** doğru; kapı 3.357'de 1 elerdi |
| A4 | Kod–ad çifti gerçek olacak (çeldiricide de) | ✅ | ✅ KOD AD CIFTI | kasada 522 ihlal, yeniden yazımda **1** |
| A5 | Hafızadan hüküm verilmeyecek, kaynak okunacak | ✅ | ⛔ yok | Mercek A ölçecek (%97,8 kapsam) |
| A6 | Madde atfı gerçek olacak | ✅ | ⛔ yok | Mercek A ölçecek |
| A7 | **Mülga fıkraya dayanılmayacak** | ✅ (11.08) | ⛔ ambarda alan yok | Mercek A ölçecek — istemde 7a, mercekte MÜLGA UYARISI |

### A7 — neden makine kapısı kurulamadı

Ölçüldü (11.08): ambarda **yapısal mülga/yürürlük alanı YOK.** Hiçbir maddede
"bu yürürlükte mi" bilgisi ayrı bir alanda tutulmuyor; bilgi yalnız metnin
içinde, Resmî Gazete yazım geleneğiyle geçiyor.

| İşaret | Adet | Anlamı |
|---|---|---|
| `(Mülga …)` | **647** (%2,06) | o fıkra/cümle **yürürlükten kalkmış** |
| `(Değişik …)` | **3.163** (%10,1) | fıkra **yürürlükte**, sonradan değişmiş — mülga DEĞİL |

**647'nin hepsi kısmî**: madde yürürlükte, içindeki bir fıkra kalkmış.
Örnek: AATUHK m.58 — *"(Mülga üçüncü fıkra: 28/1/2010-5951/1 md.)"*

Yani risk "ölü maddeye dayanmak" değil, **kalkmış fıkrayı yürürlükteymiş gibi
kullanmak.** Makine bunu göremez — sorunun hangi fıkraya dayandığını bilemez.
Bu yüzden **kapı değil mercek**: Mercek A'ya, kaynakta mülga işareti varsa
hükmün o kalkmış kısımdan gelip gelmediğine **özellikle bakması** söylendi.

**İlk ölçümüm yanlıştı:** "mülga izi" diye 7.509 saymıştım; çoğu `(Değişik …)`
idi, yani tam tersi anlam. Desen daraltılınca gerçek sayı 647 çıktı.

## B. ÖĞRETME — "her yanlış cevaba karşılık veren bir açıklama"

| # | Şart | İstem | Kapı | Teslim (ölçüldü) |
|---|---|---|---|---|
| B1 | Her yanlış şıkta **tuzak adı** | ✅ | ✅ TUZAK ALANI | **%100** (13.428/13.428) |
| B2 | Tuzak adı **o şıkka uyacak** | ✅ | ⛔ makine göremez | **%77** — 653 soruda uymuyor. Mercek C ölçecek |
| B3 | **Doğrusunun ne olduğu** açıkça yazılacak | ✅ (11.08 eklendi) | ⛔ bilerek yok | **%16,3** ⛔ — kalıp yasağı özü de götürmüştü |
| B4 | Doğru şıkkın açıklaması dolu olacak | ✅ | ✅ ACIKLAMA BOS | 27 boş bulundu, kapı kuruldu |
| B5 | **Hap kartı** (akılda kalsın) | ✅ | ⛔ yok | **%100**, ort. 226 karakter |
| B6 | Açıklamada tablo / yevmiye kaydı | ✅ | ⛔ yok | **%66,2** tablolu |
| B7 | Hesaplı soruda formülle çözüm | ✅ | ⛔ yok | **%50,7** formüllü |

## C. SINAV BENZERLİĞİ — "çıkmış sınavla uyumlu ve ondan zor"

| # | Şart | İstem | Kapı | Teslim | Sınav |
|---|---|---|---|---|---|
| C1 | Veri noktası | ✅ | ⛔ | **6,71** | 5,63 |
| C2 | Çok çıktılı soru oranı | ✅ | ✅ betikten dağıtılır | **%12** (403/403 uydu) | %6,7 |
| C3 | Olumsuz kök oranı | ✅ | ✅ betikten dağıtılır | **%22** (738/738 uydu) | %17–30 |
| C4 | Doğru şık en uzun olmayacak | ✅ | ✅ DOGRU SIK EN UZUN | 276 elendi |
| C5 | Doğru şık harf dağılımı dengeli | ✅ | ✅ betikten karıştırılır | A690 B643 C676 D660 E688 |
| C6 | **Kök cevabı ele vermeyecek** | ✅ **istem 10. madde** (11.08) | ⛔ dedektör var, kapı yok | **56 kusur → 56'sı düzeltildi → 0** ✅ |

**C6 — kökün cevabı ele vermesi (11.08).** GM okuması sırasında bulundu: bir sorunun
kökü *"...net kâr bu hesabın **alacağına**, net zarar ise borcuna yazılır"* diyordu ve
B ile D şıkları **yalnızca yönde** ayrılıyordu — aday kökü yeniden okuyarak B'yi
bedava eleyebiliyordu. Bu, "çıkmış sınavdan **daha zor**" şartını doğrudan deler.

Ölçüm iki katmanlı yapıldı (3.357 soru):

| Katman | Bulgu | Not |
|---|---|---|
| 1 — kökte kural cümlesi var | 149 (%4,4) | **Tek başına kusur değil**; kural meşru bir önerme olabilir |
| 2 — kural şıkları ayırt ediyor | 18 aday | **18'inin 18'i elle okundu** |

18 adayın hükmü: **10 ağır kusur + 1 kısmi = 11 gerçek**, 6 meşru, 1 yanlış alarm
(dedektör soru cümlesinin kendisini yakalamıştı). **Dedektör isabeti %61** — ham
sayıya güvenilseydi 7 sağlam soru haksız yere suçlanacaktı.

En ağır vaka `f3e3bb33`: kök 191 ve 320'nin çalışma yönünü baştan söylüyordu, doğru
şık B tam o cümlenin karşılığıydı; aday **hiç muhasebe bilmeden** bulabiliyordu.
Aynı ailede *"152 alacak, 620 borç kaydedilir"* diye başlayan dört soruda
çeldiricilerin yarısı kökle eleniyordu.

**Onarım:** 11 sorunun kökünden kural cümlesi çıkarıldı (`veri/kok-kesim-tablosu.json`).
Hepsinin tam kökü önce okundu — kesimden sonra 11'i de kendi başına tam ve
cevaplanabilir kaldı, bilgi kaybı yok (kural zaten açıklamada öğretiliyor).
Doğrulama: kayıt 3.357 korundu · **tam 11 soru** değişti · dedektör 18 → **7**
düştü ve kalan 7, "meşru + yanlış alarm" listesiyle **birebir aynı** · bozulma
kapısı **0**.

**Kapı hâlâ yok — bilerek.** Ölçüt ("kural cümlesi tek başına bir çeldiriciyi
öldürüyor mu") makinenin göremeyeceği bir yargı; %61 isabetli bir dedektöre
otomatik red yetkisi verilirse sağlam soru elenir. Dedektör **aday üretir**,
hükmü GM ya da Mercek C verir.

**131'İN TAMAMI OKUNDU (11.08).** Yukarıdaki "ölçülemedi" kapatıldı. Dört partide,
tek tek, elle:

| Hüküm | Sayı |
|---|---|
| **KUSUR — kök cevabı ele veriyor** | **45** |
| MEŞRU — kural önerme, cevap yine bilgi istiyor | 21 |
| **Yanlış alarm** | **62** |
| ÖLÇÜLEMEDİ — kural cümlesi kesik | 3 |

**Dedektörün isabeti %34.** Ham sayıya güvenilseydi **86 sağlam soru** haksız yere
suçlanacaktı. 62 yanlış alarmın hepsinde yakalanan cümle **sorunun kendisiydi**
(*"Bu fark hangi hesaba kaydedilir?"*) — kural değil.

En ağır vaka `cb0c7428`: kök *"…yönetim yapısına ve büyüklüğüne bakılmaksızın
uygulanır"* diyordu, doğru şık B ise **aynı cümlenin kendisiydi**. Bir de aile
tespit edildi: **BDS 260 soruları** (`1473029a`, `564b8d6a`, `5dfbafce`, `69151b40`,
`ba5d8d1e`, `cb0c7428`) — altısında da aynı kalıp tekrarlanmış.

**Onarım:** 45'inde de kural cümlesi **ilk cümleydi**; kesildi (−9.634 karakter).
Dört güvenlik kilidi kondu: kesimden sonra kök 250 karakterden kısaysa, büyük
harfle başlamıyorsa, soru işareti kaybolduysa ya da %50'den fazlası gidecekse
o soruya **dokunulmuyor**. 45'i de kilitleri geçti.

Doğrulama (5 sınav): kayıt 3.357 ✓ · değişen **tam 45** ✓ · şık/açıklama/hap
değişimi **0** ✓ · bozulma kapısı **0** ✓ · bozuk kök **0** ✓.

**Bu sınıfta toplam 56 soru düzeltildi (11 + 45).**

**Yolda çıkan iki ayrı bulgu (bu ölçümün konusu değildi, kaydedildi):**
- `a1937700` — B şıkkı kökte doğrulanıyor; soru "hangisi doğrudur" ise **iki doğru
  şık** riski (K11'in konusu)
- `487eb7e9` — C ve D şıkları neredeyse aynı cümleyle başlıyor; **mükerrer şık** riski

**ÖLÇÜLEMEDİ KAPANDI (11.08).** Kalan 3 soru tam metinle okundu; **üçü de KUSUR**
çıktı ve onarıldı. Nihai tablo: **48 kusur · 21 meşru · 62 yanlış alarm ·
0 ölçülemedi = 131.** Dedektör isabeti **%37**.

- `3bb4d90a` — kısmi: kökün ikinci cümlesi **D şıkkının birebir kendisiydi**
- `bd1705c4` — ağır: kök *"kâr dağıtımıyla ilgisi olmayan ayrı bir sermaye yedeği"*
  diyerek B'yi (590) ve E'yi (ayrı hesap yok iddiası) eliyordu
- `f4fb32c1` — ağır: kök *"ikamet şartı aranmaksızın"* ve *"talep tarihini takip
  eden günden itibaren"* diyerek D ve E şıklarını **birebir** eliyordu

**ATIF ONARIMI — körlemesine kesim soruyu bozacaktı.** `f4fb32c1`'in ikinci cümlesi
*"…**anılan** (ç) bendinde belirtilenlerden…"* diye başlıyordu; ilk cümle silinince
"anılan" havada kalıyordu. Kesim yerine **atıf açık yazıldı**: *"6735 sayılı
Uluslararası İşgücü Kanununun 16 ncı maddesinin birinci fıkrasının (ç) bendinde
belirtilenlerden…"*. Böylece kişinin hukukî kapsamı korundu, **kural** ise kökten
çıktı.

Bunun üzerine daha önce kesilen **56 sorunun tamamı** boşta atıf bakımından
denetlendi (`anılan`, `söz konusu`, `bu hüküm`, `yukarıdaki`…): **0 bulgu.**
Varsayılmadı, ölçüldü.

**BU SINIFTA TOPLAM 59 SORU ONARILDI (11 + 45 + 3). AÇIK KALAN YOK.**

## D. DİL — "yapay zeka yazmış demesinler"

| # | Şart | İstem | Kapı | Teslim (ölçüldü) |
|---|---|---|---|---|
| D1 | Kusursuz Türkçe, arkaik kelime yok | ✅ | ✅ TR yoğunluk ≥8 | kapı çalışıyor |
| D2 | Kalıp açılış yasağı | ✅ | ✅ yasak kalıp | **%46,1 → %1,2** |
| D3 | Şık uzunluk simetrisi kırılacak | ✅ | ⛔ yok | **%57 → %17,5** |
| D4 | Tuzak adı tekrarı olmayacak | ⛔ | ⛔ yok | 1.680 kesildi (temizlik betiği) |
| D5 | Senaryo 2025 öncesine gitmeyecek | ✅ | ✅ betikten dağıtılır | **0/3357** ihlal |
| D6 | Model düşüncesi/çöp metin sızmayacak | ✅ **istem 9. madde** (11.08) | ✅ **BOZULMA KAPISI** (11.08) | **31 soru bulundu → 31'i onarıldı → 0** ✅ |

**D6 — eski not yanlıştı, düzeltildi (11.08).** Karnede *"adayın gördüğü alanlarda 0"*
yazıyordu; ölçüm yapılmadan yazılmıştı. GM okuması sırasında tesadüfen bir yapışık
cümle görüldü, tüm 3.357 taranınca **31 soruda (%0,92)** üç ayrı bozulma imzası çıktı:

| İmza | Örnek | Sayı |
|---|---|---|
| Tekrar döngüsü | `...yansıtılamaz.impaypayı payı payı.` | 4 |
| **Modelin kendi düzeltme notu** | `...gözden kaçar.gerekir.gerekir yerine: kaçar.` | 1 |
| Yapışık cümle / bozuk kırıntı | `...aittir.muhasebe mantığı...` · `.png yerine` · `.bbölge tededeğil` | 26 |

Bunların **4'ü adayın gördüğü alandaydı** (2 şık + 2 hap), 27'si açıklamada.
Kasaya basılmamıştı — bozulma dışarı sızmadı, onarım **0 USD**.

Kapı `motor/birlesik-yazim-olcum.ps1` içinde, `KAPIDA RED - BOZULMA` damgasıyla.
**Yanlış alarm elemesi ölçümle seçildi, tahminle değil:** ham tarama 373 bulgu
veriyordu; `798 no.lu hesap` kalıbı (14) ve `ayrı ayrı`/`adım adım` gibi Türkçe
ikilemeler (318) elendikten sonra **33 gerçek bulgu** kaldı. Kapı bu haliyle
3.357 soruda tam 31'i yakaladı, onarımdan sonra **0** verdi.

Onarım ilkesi (`veri/bozulma-onarim-tablosu.json`): kırıntıdan sonrası anlamlıysa
bozuk kelime düzeltildi, anlamsızsa son tam cümleye kadar kırpıldı, **hiçbir yere
yeni iddia/rakam eklenmedi**. Sonuç: tam 31 soru değişti, −329 karakter, başka
hiçbir soruya dokunulmadı (yedekle bire bir karşılaştırıldı).

**İSTEM TARAFI DA KAPATILDI (11.08).** Karne ilk yazıldığında yalnız Kapı sütunu
işaretlenmişti; geri okuyunca İstem sütununun ⛔ kaldığı görüldü. Kapı tek başına
yetmez: çıktıyı reddeder ama model aynı çöpü **yeniden üretir, parasını öderiz,
sonra çöpe atarız.** (Defalarca öğrenilen ders: *yeni kapı önce isteme yazılır,
sonra makineye.*) İsteme **9. madde** eklendi — üç bozulma biçimi örnekleriyle
yasaklandı, Türkçe ikilemelerin serbest olduğu ayrıca belirtildi.

**KARŞI SINAV yapıldı** — bir kapının "0 red" vermesi tek başına kanıt değildir;
hiçbir şey yakalamayan bozuk bir kapı da 0 verir. Aynı kapı iki dosyada koşuldu:
onarılmış dosyada **0 red**, onarım öncesi yedekte **31 red**. Kapı gerçekten
ayırt ediyor.

## F. ZORLUK KADEMESİ — adayın ilerleyebileceği yol

| # | Şart | İstem | Kapı | Teslim (ölçüldü) |
|---|---|---|---|---|
| F1 | Üç kademe gerçekten dolu olacak | ⛔ | ✅ türetme betiği | **883 / 2.133 / 341** ✅ |
| F2 | Kademe modelin beyanına değil **ölçüme** dayanacak | ⛔ | ✅ türetme betiği | 6 özellikten puanlanıyor |
| F3 | Kasadaki değer doğrulanacak | — | ✅ geri okuma | **3.357/3.357**, uyuşmayan 0 |

### F1 — neden gerekliydi

Yeniden yazımda model `zorluk` alanını kendi doldurdu ve **%95,6'sına "sınav"** dedi:

```
ESKİ:  kolay 63 (%1,9) · sinav 3.209 (%95,6) · zor 85 (%2,5)
```

Bu bir dağılım değil, tek etiket. Adaya "kolaydan başla, zora çık" diyemezdik —
63 kolay soru vardı.

### F2 — kademe nasıl türetiliyor

Zorluk artık **modelin beyanından değil**, sorunun altı ölçülebilir özelliğinden
puanlanıyor (her biri 0–2, toplam 0–12):

| Özellik | 2 puan | 1 puan |
|---|---|---|
| Veri noktası sayısı | ≥8 | ≥5 |
| Çözüm adımı yoğunluğu (açıklamadaki işlem) | ≥25 | ≥10 |
| Çok çıktılı mı | evet | — |
| Olumsuz kök mü | — | evet |
| Kaç ayrı hesap kodu geçiyor | ≥5 | ≥3 |
| Soru kökü uzunluğu | ≥700 krk | ≥450 krk |

Eşikler keyfî değil — puan dağılımı kendiliğinden çan eğrisi verdi, tepe 6'da:

```
0–3  →  kolay  (883)
4–7  →  sinav  (2.133)
8+   →  zor    (341)
```

Sağlaması örneklerde: en zorlar Mali Tablolar Analizi / Muhasebe Standartları /
Maliyet Muhasebesi; en kolaylar Ticaret Hukuku / Maliye / Meslek Hukuku.

**Not:** `zorluk` kolonu **smallint** — 1/2/3 yazılır, metin yazılırsa 22P02
hatası verir (10.08 dersi). Eski değerler `veri/zorluk-turetme.txt`'de satır
satır duruyor, geri alınabilir.

## E. KAPSAM

| # | Şart | Durum |
|---|---|---|
| E1 | Çıkmış sınavda olup bizde olmayan konu kalmayacak | **350 konu boş** (960 değil), 372 çıkmış soru |
| E2 | Her sorunun kaynağı olacak | `kanun_no` boş **3.729 → 126** |
| E3 | Ders etiketi içerikle uyacak | beceri derslerinde ölçüldü; Matematik/YD'de **0 hata** |

---

## ⛔ KOŞUDAN ÖNCE KAPATILACAK — kırmızı satırlar

1. **B3 (%16,3)** — en büyük açık. 2.814 soru "doğrusunu" söylemiyor.
   → İsteme 11.08'de **ZORUNLU ÖZ** maddesi eklendi. Kapısı **bilerek yok**:
   birebir "Doğrusu:" aramak D2/D3'te kırdığımız tekdüzeliği geri getirir.
   Denetim **Mercek C**'de. *(Cem kararı 11.08: B seçeneği)*
2. **B2 (%77)** — tuzak adı şıkka uymuyor. Sözlük 81 → **481 ada** çıkarıldı,
   Mercek C bunu şık harfiyle raporlayacak.

## Kapısı olmayıp merceğe bırakılanlar

A1, A2, A5, A6 → **Mercek A + B**
B2, B3, B6, B7 → **Mercek C**

Bunlar makineyle ölçülemez; ölçülemeyene kapı kurulmaz, mercek kurulur.

---

## Para

| İş | Soru | USD |
|---|---|---|
| Mercek A (mevzuat) | 3.284 | 46 |
| Mercek B (hesap) | 3.079 | 75 |
| Mercek C (öğretme + dil) | 3.357 | 43 |
| B3 onarımı — yeniden yazım | 2.814 | ~210 |
| Boş açıklama + 229 vade | 36 | 3 |
| **TOPLAM** | | **~377** |

Harcanan: 291 (yeniden yazım, 10.08). Kalan: **~377**.
Engel: API tavanı — destek talebi `215475428186397`.
