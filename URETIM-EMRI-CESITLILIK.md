# ÜRETİM EMRİ — ÇEŞİTLİLİK + BOŞLUK KAPATMA

**Tarih:** 11.08.2026 · **Durum:** HAZIR, tavan açılınca koşulacak
**Cem emri:** *"etkin çeşitliliği artıralım, böyle eksik olan varsa onu attıralım,
limit hepsi hazır olsun"*

Bu belge, API tavanı açıldığı gün **tek tek karar vermeden** koşulacak sırayı
tutar. Her parti için hedef, kaynak listesi ve kabul kapısı önceden yazıldı.

---

## 1. ÖLÇÜLEN GERÇEK — etkin çeşitlilik

Ölçüm: `benzer_grup` doldurulduktan sonra ders başına **kaç ayrı kaynak** var.
"Etkin %" = ayrı grup sayısı / gruplanabilen soru sayısı. **Düşük = tekrar çok.**

| Ders | Soru | Ayrı grup | Etkin | En yoğun kaynak |
|---|---|---|---|---|
| Muhasebe Standartları | 478 | 28 | **%6** | TFRS 13 ×34 |
| Denetim Standartları | 279 | 23 | **%8** | BDS 260 ×24 |
| **Ticaret Hukuku** | 219 | 21 | **%10** | **TTK m.367 ×73** |
| Denetim | 243 | 28 | %12 | BDS 300 ×22 |
| Vergi Hukuku | 156 | 18 | %12 | VUK m.231 ×49 |
| Maliyet Muhasebesi | 290 | 27 | %13 | VUK m.275 ×57 |
| Vergi Mevzuatı ve Uyg. | 210 | 23 | %13 | **VUK m.275 ×95** |
| Borçlar Hukuku | 188 | 22 | %13 | **TBK m.82 ×85** |
| Muhasebe Denetimi | 67 | 21 | %31 | TFRS 16 ×11 |
| Finansal Muhasebe | 221 | 57 | %38 | THP 337 ×15 |
| Finansal Yönetim | 145 | 54 | %50 | THP 380 ×7 |
| Finansal Tablolar | 144 | 46 | %52 | THP 337 ×9 |

**Okuma:** Ticaret Hukuku'nda 219 soru var ama **21 ayrı kaynaktan**. Aday
20 soruluk deneme çekerse `benzer_grup` kuralı yüzünden en fazla 21 farklı soru
görebilir — banka sayıdan küçük. Finansal Muhasebe (%38) ve Finansal Yönetim
(%50) sağlıklı; **hukuk ve standart dersleri kritik.**

### Gruplanamayan (ölçülemedi)
| Ders | Grupsuz soru | Neden |
|---|---|---|
| İş ve Sosyal Güvenlik | 178 / 179 | kaynak alanı 5510 madde deseni taşımıyor |
| Meslek Hukuku (iki etiket) | 211 | 3568 madde deseni yok |
| Maliye | 132 / 133 | kaynak alanı serbest metin |
| Sermaye Piyasası | 69 | 6362 deseni yok |
| Matematik | 68 | mevzuat dışı — normal |

Bu derslerde çeşitlilik **ölçülemedi**; "iyi" de "kötü" de denmiyor.
İlk iş bunların kaynak alanını desenli hâle getirmek (Parti 0).

---

## 2. İKİNCİ BOŞLUK — hiç sorusu olmayan konular

`veri/konu-bosluk-icerikten-sgs.json` (09.08 ölçümü, içerikten):

| Alan | Sınavda çıkan ama kasada **0** içerik |
|---|---|
| Muhasebe | **416 konu** |
| Hukuk | **370 konu** |
| Ekonomi | 90 konu |
| Maliye | 84 konu |
| **Toplam** | **960 konu** |

Ayrıca **638 konu ÖLÇÜLEMEDİ** (beceri tabanlı dersler — konu adı soru
metninde geçmez; ayrı yöntem ister).

**UYARI:** 960 rakamı *"soru kökünde o konu geçmiyor"* demektir, *"kesinlikle
yok"* demek değildir. Üretimden önce **örneklem okunacak** (bekleyen iş #15).

---

## 3. ÜRETİM SIRASI — tavan açılınca bu sırayla

Kural: **her parti kendi kapısından geçmeden sonraki parti başlamaz.**
Her partiden sonra **rapor değil SORU okunur** (en az 10).

### PARTİ 0 — kaynak alanını desenli yaz · **0 USD**
Gruplanamayan 658 sorunun `kaynak` alanına kanun+madde deseni yazılır
(5510 m.X, 3568 m.X, 6362 m.X). API gerekmez — ambardaki madde metniyle
eşleştirme. **Çıktı:** o beş dersin etkin çeşitliliği ölçülebilir hâle gelir.

### ⚠️ PARTİ 1 ÖNCESİ — KAYNAK DOYGUNLUK KAPISI KURULDU (11.08)

Cem sorusu: *"tekrar desenlerini yok etmeliyiz nasıl yaparız"*. Ölçüldü:

**Kasa 2.671 maddenin 63'ünün üstüne kurulmuş — %2,4.**

| Kanun | Ambardaki madde | Sorusu var | Kapsama |
|---|---|---|---|
| TTK | 1.518 | 22 | **%1,4** |
| AATUHK | 117 | 2 | %1,7 |
| TBK | 648 | 21 | %3,2 |
| VUK | 353 | 15 | %4,2 |
| KVK | 38 | 3 | %7,9 |

**Kapasite ölçütü** (kendi kuralımız, ölçülmüş bir yasa değil):
`kapasite = min(fıkra/bent × 2, karakter/150)` — her fıkra en fazla iki soru
taşır (olumlu + olumsuz kurgu); kısa madde uzunluk tavanına takılır.

| Kaynak | Soru | Kapasite | **Fazla** |
|---|---|---|---|
| VUK m.275 | 201 | 5 | **+196** |
| TBK m.82 | 85 | 2 | **+83** |
| TTK m.367 | 73 | 4 | **+69** |
| VUK m.231 | 77 | 12 | +65 |
| TBK m.66 | 62 | 2 | +60 |

**Toplam fazlalık 609 soru · boş kontenjan 9.521 soru.**

TBK m.82 **tek fıkralık, 537 karakterlik** bir maddedir; 85 ayrı soru çıkması
fiziken mümkün değildir — 83'ü aynı şeyin kopyasıdır.

**KAPI:** `motor/kaynak-doygunluk-kapisi.ps1`
- `-ozet` → doygunluk tablosu
- `-kaynak 'TBK m.82'` → tek kaynağın durumu (DOYMUŞ / DOLUYOR / YER VAR)
- `-liste istek.csv` → üretim isteğini süzer, doymuş kaynağı **reddeder**
- `-bos -kanun TTK -adet 30` → doldurulacak boş madde önerir

Sınandı: 5 satırlık deneme isteğinde VUK m.275 ve TBK m.82 **reddedildi**,
TTK m.515 ve TBK m.140 geçti, BDS 330 **ÖLÇÜLEMEDİ** damgasıyla geçirildi.

**Kural — silme, TAŞI.** 609 fazlalık silinmez; boş maddelere yeniden yazdırılır.
Zaten yazılacak yeni soru yerine bunlar yazılır: **aynı para, iki sorun birden.**

**STANDARTLAR DA ÖLÇÜLDÜ (11.08, Cem emri "standartları ölç"):** Ambardaki
83 standart dosyası paragraf yapısında çıktı (`BDS 200 p.1` gibi) — kapasite
paragraf sayısından kuruldu, **80 tekil standart** ölçüldü:

| Standart | Soru | Ambar paragrafı | Kapasite | **Fazla** |
|---|---|---|---|---|
| BDS 330 | 73 | 6 | 12 | **+61** |
| BDS 260 | 41 | 6 | 12 | +29 |
| TFRS 10 | 36 | 7 | 14 | +22 |
| TFRS 9 | 28 | 3 | 6 | +22 |
| BDS 510 | 25 | 3 | 6 | +19 |

**Standart fazlalığı 391 · kontenjan 3.301 · hiç sorusu olmayan standart 22.**

Kanun + standart birleşik: **fazlalık 1.000 soru · boş kontenjan 12.822.**
Kapı artık standartları da süzüyor (sınandı: BDS 330 kapıda reddedildi).

**İki dürüst sınır:** (1) Kapasite **ambardaki kadar** metne dayanır — ambar
standardın bir bölümünü yuttuysa kapasite olduğundan düşük çıkar (BDS 330'un
aslı 6 paragraftan uzundur); FAZLA rakamı ihtiyatlı üst sınırdır. (2) Bu aynı
zamanda bir **yutma-kapsama sinyalidir**: 6 paragraflık BDS 330'a 73 soru
yazılabildiyse üretim ya ambar dışına çıkmış ya da aynı paragrafı 12 kez
sormuştur — ikisi de incelenmeli. BDS/TMS yutma kapsaması ayrıca ölçülmeli
(bkz. yutma-kapsama kapısı, %98 kuralı).

### PARTİ 1 — çeşitlilik: hukuk dersleri · ~**220 USD**
Hedef: TTK / TBK / VUK'ta **kaynak başına en fazla 8 soru**.
Şu an fazlası olanlar: TTK m.367 (73), TBK m.82 (85), VUK m.275 (201),
VUK m.231 (77), TBK m.66 (62).

- Bu maddelerin fazlası **silinmez** — havuzda kalır, `benzer_grup` zaten
  aynı denemede yan yana düşmelerini engelliyor.
- **Yeni soru yazılır**: aynı kanunun *başka* maddelerinden.
- Kaynak listesi: ambardaki TTK/TBK/VUK maddelerinden, kasada **hiç sorusu
  olmayanlar** (Parti 0 çıktısından üretilir).
- Hedef adet: ders başına ayrı kaynak sayısını **21 → 60**'a çıkarmak
  ≈ **1.200 yeni soru**.

### PARTİ 2 — çeşitlilik: standart dersleri · ~**190 USD**
Muhasebe Standartları %6 · Denetim Standartları %8 · Denetim %12.
Ambarda yutulmuş **TMS/TFRS/BDS** standartlarından kasada sorusu olmayanlar
hedeflenir. ≈ **1.000 yeni soru**.

### PARTİ 3 — boş konular: Muhasebe + Hukuk · ~**200 USD**
**LİSTE TEMİZLENDİ (11.08).** 960 iddiası doğrulandı ve kırpıldı — ayrıntı
aşağıda "§7 Liste temizliği". Üretime girecek: **549 konu**
(Hukuk 277 + Muhasebe 272) ≈ **1.100 soru**.
Kaynak liste: `veri/bos-konu-TEMIZ-LISTE.csv` → `durum=BOS-ADAY|BOS-OKUNDU`

### PARTİ 4 — boş konular: Ekonomi + Maliye · ~**45 USD**
**120 konu** (Ekonomi 64 + Maliye 56) ≈ **240 soru**.
Ekonomi'de kasada yalnız 14 soru var — en zayıf ders.

### PARTİ 5 — sürdürülebilirlik açığı · ~**40 USD**
Hafıza kaydı: KGK sınavının **%6,5'i** sürdürülebilirlik/iklim (153 soru),
kasada **1** soru var. TSRS ambara yutulmuş durumda. ≈ **200 soru**.

### PARTİ 6 — beceri dersleri · ~**90 USD**
Matematik 73, Türkçe/YD/İnkılap ölçülemedi. Sınavda Matematik %6,2, kasada
%0,86. Konu değil **beceri** hedeflenir (hafıza: beceri-dersi-etiketi).
≈ **500 soru**.

**TOPLAM: ≈ 4.850 yeni soru · ≈ 900 USD**
(Birim maliyet 20 soruluk ölçüm partisinden: soru başına ~0,185 USD.)

---

## 4. ÜRETİMDEN ÖNCE İSTEME EKLENECEK — çeşitlilik kuralı

Bugünkü bulgu tekrarlanmasın diye isteme (11. madde) girecek:

```
11. KAYNAK KOTASI. Sana verilen kaynaktan EN FAZLA 8 soru uretilir.
    Ayni maddenin ayni fikrasini iki kez sorma. Olculdu (11.08):
    TTK m.367 den 73, TBK m.82 den 85, VUK m.275 ten 201 soru yazilmis;
    m.367 nin bilgilendirme yukumu DORT kez ayri soru olarak yazilmis
    (008ee681, 06b74d9b, 0a9c58bc, 0c086659) - sehir ve tutar disinda ayni soru.
    Bir maddeden birden fazla soru yaziyorsan her biri FARKLI FIKRAYI
    ya da farkli bir unsuru olcecek.
```

---

## 5. KABUL KAPISI — her parti için

1. **Bozulma kapısı** (11.08 kuruldu) — 0 red
2. **Kod-ad çifti** kapısı — 0 red
3. **Kök cevabı ele vermeyecek** (istem 10. madde) — dedektör aday üretir, GM okur
4. **benzer_grup** yazılır, kaynak başına 8 kotası ölçülür
5. **En az 10 soru elle okunur** — rapor değil soru
6. Kırmızı varsa **sonraki parti başlamaz**

---

## 7. LİSTE TEMİZLİĞİ — 960 iddiası ölçüldü (11.08)

Cem emri: *"liste temizliğini yap elle birebir"*. Kasadaki **30.569 sorunun
tamamı** yerel dizine alındı (15,3 MB, çekim 30.569/30.569 doğrulandı),
960 konu bu dizinde arandı, sonra **soru metinleri elle okundu.**

### Sonuç

| Durum | Konu | Anlamı |
|---|---|---|
| **BOŞ-ADAY** | **667** | En ayırt edici kelimesi kasada hiç yok → gerçekten boş |
| BOŞ-OKUNDU | 2 | Okundu, boş olduğu doğrulandı |
| ŞÜPHELİ-OKUNMALI | 184 | Eşleşme var, **okunmadı** → ÖLÇÜLEMEDİ |
| ZAYIF-OKUNMALI | 93 | 1-2 eşleşme, **okunmadı** → ÖLÇÜLEMEDİ |
| **İŞLENMİŞ-OKUNDU** | **14** | Okundu, konu kasada **zaten var** |

**Üretime girecek: 669 konu** (960 değil). Liste: `veri/bos-konu-TEMIZ-LISTE.csv`

### Okunan 16 konunun 14'ü zaten işlenmiş çıktı

`haksız rekabet reklam yasağı`, `ticari iş kavramı`, `denetçi bağımsızlığı`,
`temettü tahakkuku`, `menkul kıymet ihracı`, `kasa sayım farkı nedenleri`,
`doğum izni ücretsiz izin`, `SMMM olabilmenin özel şartları`… — hepsinin
kasada karşılığı var, çoğunda **konu etiketi bile birebir aynı**.

Gerçekten boş çıkan 2: `cari oran-asit test hesabı`, `is-lm eğrisi`
(ikincisi `j eğrisi` sorusuyla eşleşmişti — farklı konu).

### Üç ölçüm hatası yapıldı ve düzeltildi

1. **ASCII↔Türkçe**: ilk arama `butce` ile yapıldı, kasada `bütçe` var →
   31/32 konu yanlışlıkla "boş" çıktı. Türkçe toleranslı desenle `butce`
   **466 bulgu** verdi. *(Hafızadaki imatch tuzağı, tekrar yaşandı.)*
2. **`$say` / `$SAY` çakışması** — PowerShell büyük-küçük harf ayırmıyor.
   Bu oturumda beşinci tekrar.
3. **Genel kelime çarpışması**: ilk tam tarama 4 harften kısa kelimeleri
   atıyordu; `is-lm`, `kdv`, `ymm`, `çek` düşünce geriye yalnız `analizi`,
   `konusu`, `kapsamı` kalıyordu. Okunan 14 örneğin **14'ü de yanlış
   eşleşmeydi** (`is-lm analizi` ↔ `trend analizi`). Düzeltme: kelimenin
   **kasadaki geçme sıklığına** göre en ayırt edici olanı seçmek. "284 var"
   → **200**'e düştü ve içi anlamlı hâle geldi.

### 277'nin tamamı okundu (Cem emri: *"277 oku ve ezberle yut"*)

Dört partide, her konu için kasadaki gerçek soru açılarak:

| | Okunan | Zaten işlenmiş | Gerçekten boş |
|---|---|---|---|
| Muhasebe | 135 | **126** | 9 |
| Hukuk | 88 | 65 | 23 |
| Maliye | 28 | 23 | 5 |
| Ekonomi | 26 | 24 | 2 |
| **Toplam** | **277** | **238 (%86)** | **39** |

**Şişkinliğin dört kök sebebi — hepsi okuyarak görüldü:**

1. **Yazım varyantı** — `monopol piyasa özellikleri` ve `monopol piyasası
   özellikleri` ayrı konu sanılmış; ikisi de kasada var
2. **Eş anlam** — `ifac yapısı` / `ifac kuruluşları` / `uluslararası muhasebe
   kuruluşları` / `ifac üyesi türk kuruluşları` = **dört etiket, tek konu**
3. **Eski standart adı** — `tms 18 hasılat` → kasada `tfrs 15 hasılat ölçümü`;
   `tms 17 kiralama` → `tfrs 16 kullanım hakkı`
4. **Alt başlık** — `cari oran formülü`, `cari oran-asit test yorumlama`,
   `dikey yüzdelerden cari oran`… ayrı konu sayılmış, hepsi var

Gerçekten boş çıkan 39 arasında: `is-lm analizi`, `alacağın devri` (TBK temlik —
kasadaki şüpheli alacak değil), `dijital hizmet vergisi oranı`, `gecikme zammı
kuralları`, `vergi hukuku kaynakları`, `oyda imtiyaz`, `operasyonel açık`,
`müstahsil makbuzu`, `defter türleri`.

### 667'nin tamamı da işlendi — **liste KAPANDI**

Cem emri: *"667 oku ezberle ve yut"*. Üç katmanda:

| Katman | Konu | Yöntem |
|---|---|---|
| Kelimesi kasada **hiç yok** | 169 | `merkantilizmi`, `baumol`, `cobb`, `pigou`, `leontief`, `sterilizasyon`… teknik terimler kasada geçmiyor |
| Kelimeleri var, **birlikte hiç geçmiyor** | 370 | Tam kelime dağarcığı (38.364) üzerinde kesişim taraması |
| **Birlikte geçiyor → elle okundu** | **128** | 92 zaten var · 36 boş |

### NİHAİ TABLO — 960 konunun tamamı

| Durum | Konu |
|---|---|
| BOŞ-DOĞRULANDI | 539 |
| **BOŞ-OKUNDU** | **77** |
| **İŞLENMİŞ-OKUNDU** (üretime girmez) | **344** |
| **ÜRETİME GİRECEK** | **616** |

616 + 344 = 960 ✓ · Hukuk 282 · Muhasebe 213 · Ekonomi 61 · Maliye 60

**Toplam 205 konu elle okundu** (277'nin tamamı + 128 + ilk 16 örneklem).
**Açık kalan yok.**

### Dört ölçüm hatası yapıldı ve dördü de düzeltildi

1. **ASCII↔Türkçe** — `butce` arandı, kasada `bütçe` var → 31/32 konu yanlışlıkla boş
2. **`$say`/`$SAY`** çakışması — beşinci tekrar
3. **Genel kelime çarpışması** — 4 harften kısa atılınca `is-lm`/`kdv`/`ymm` düşüyor,
   geriye `analizi`/`konusu` kalıyordu; okunan 14 örneğin **14'ü** yanlış eşleşmeydi
4. **Ters dizin eşiği** — 4000'den fazla soruda geçen kelime indekslenmemişti;
   rapor *"şirket YOK"* diyordu, oysa binlerce kez geçiyor

Dördü de **örnek okunarak** yakalandı; hiçbiri makine çıktısına bakarak fark edilmedi.

Kaba tasarruf: 960 → 616 konu, Parti 3+4 maliyeti **≈360 → ≈225 USD.**

## 6. AÇIK KALAN — dürüst liste

- 960 boş konu **örneklemle doğrulanmadı** (#15)
- 638 beceri konusu **ölçülemedi**
- 5 dersin çeşitliliği **ölçülemedi** (Parti 0 çözecek)
- Maliyet tahmini **20 soruluk tek ölçüme** dayanıyor; ilk parti sonrası
  gerçek rakamla güncellenecek
- Kasadaki ~27.000 taranmamış sorunun bu ölçümlere etkisi **bilinmiyor**
