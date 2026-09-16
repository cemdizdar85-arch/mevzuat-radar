# KGK (BAĞIMSIZ DENETÇİLİK) KAYNAK ÖLÇÜMÜ — 14.09.2026

> ## ⚡ GÜNCELLEME 14.09.2026 ~15:00 — ONARIM SONRASI (Cem "1 ve 3 yap")
>
> **Onarım yapıldı (bedel 0):**
> - Yalnız özet olan 13 standart resmî metinle yeniden yutuldu (TMS 24/27, TFRS 8/9/10, BDS 260/265/330/510/580/620/701, GDS 3400).
> - Yutucunun iki kök kusuru düzeltildi: Git'teki xpdf 4.06 yerine poppler, sayfa numarası + koşu başlığı kuralı (commit `f71256e5`).
> - Reçeteyle 76 standart + TMS 37 yeniden yazıldı, düşen 0. Ölçüm `-Tazele` ile yeniden koşuldu (ambar 47.675 satır, 14:38).
>
> | Ders | HAZIR | ZAYIF | YOK | (sabah: H / Z / Y) |
> |---|---:|---:|---:|---|
> | a) TMS | 12 | 18 | **0** | 11 / 13 / 6 |
> | b) TDS | 28 | 3 | **0** | 24 / 0 / 7 |
> | c) KY + FY | 10 | 1 | 11 | 10 / 1 / 11 |
> | ç) SPK | 7 | 1 | 0 | aynı |
> | d) Bankacılık | 6 | 5 | 0 | aynı |
> | e) Sigortacılık | 3 | 2 | 1 | aynı |
> | f) Sürdürülebilirlik Rap. | 0 | 13 | 0 | aynı |
> | g) Sürdürülebilirlik Den. | 4 | 2 | 0 | 3 / 3 / 0 |
>
> **Okuma notu:**
> - TMS/TDS'de **YOK kalmadı**; özet olan her standart artık resmî metin.
> - TMS'de ZAYIF'ın artması bir kötüleşme değil. Yeni bölmede metin tam, ama bazı paragrafların **numara etiketi kayık**. Poppler bazı sayfalarda numaraları alt alta diziyor ("16", "17" art arda, metin sonra geliyor); bölücü p.16'yı boş sayıp metnini p.17'nin altına koyuyor. Kontrol edilen örnek TMS 16 p.11/16/23/73–76.
> - Bu kusur eski kuralda da vardı. Açık iş: bölücüye "ardışık numara sütunu" kuralı + eşdeğerlik provası.
>
> **3. madde yapıldı:** KAPI-AILE (commit `2e0d333c`). KGK kaynak paketine yalnız dersin resmî aileleri girer (`veri/kgk-ders-aile.json`).
>
> **Yan etki kaydı:** Kaynak adı bağı kopan 243 soru `veri/standart-yutma-kopan-bag-20260914.json` dosyasında (KGK 218, SGS 25). Ayrıca 2.725 standart kaynaklı sorunun bağı bugünden önce kopuktu.
>
> **Aşağıdaki bölümler sabahki (onarım öncesi) ölçümdür**; iş emri 4-B uygulandı.

> **Bedel: 0 USD.** Soru basılmadı, ambara/kasaya yazılmadı, para harcayan çağrı yok.
> Ölçüm betiği: `arac/kgk-kaynak-olcumu.ps1` · makine çıktısı: `veri/kgk-kaynak-olcumu.json`
> Ambar okuması: 14.09.2026 11:06 (46.281 satırın ad listesi) + KGK kaynak ailelerinin 10.701 satırının metni.
> Ambar yükü: ölçüm boyunca nabız 0,42–0,64 sn; hiçbir sayfa 5 sn'yi aşmadı.

## 0 · Tek paragraf sonuç

127 kota konu satırının **64'ü HAZIR, 38'i ZAYIF, 25'i YOK**. HAZIR satırlar bugün basılabilir: **a) 11, b) 24, c) 10 (tamamı Kurumsal Yönetim), ç) 7, d) 6, e) 3, g) 3**. **f) Kurumsal Sürdürülebilirlik Raporlaması'nda HAZIR konu yok** (TSRS 1 ve TSRS 2 resmî ama numara delikli). **Finansal Yönetim'in 11 konusu Cem'in "resmî metin" şartıyla YOK**: ambarda yalnız teori notu var, bu dersin mevzuat anlamında resmî metni yok (karar bölüm 4-C). Ret kütüğündeki KGK "kaynak eksik" retlerinin önemli kısmı yutma eksiği değil **paket seçimi / etiket kayması**: ölçülen iki vakada hüküm ambarda var ama yanlış parçada ya da yanlış adla duruyor (bölüm 6).

## 1 · Ders × sınıf özeti

Eksik (ders) = `veri/SINAV-TEK-SAYFA.md` bölüm 1 (kasa 13.09.2026 05:58). Çıkmış* = `veri/kgk-analiz.json` konularından kota satırına **eşlenebilen** alt küme (bölüm 7'deki sınıra bak).

| Ders | Konu satırı | HAZIR | ZAYIF | YOK | HAZIR kota | Çıkmış* HAZIR / ZAYIF / YOK | Ders eksiği |
|---|---:|---:|---:|---:|---:|---|---:|
| a) Türkiye Muhasebe Standartları | 30 | **11** | 13 | 6 | 530 | 241 / 283 / 64 | 312 |
| b) Türkiye Denetim Standartları | 31 | **24** | 0 | 7 | 1.130 | 310 / 0 / 76 | 394 |
| c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim | 22 | **10** | 1 | 11 | 380 | 146 / 0 / 146 | 1.322 |
| ç) Sermaye Piyasası Mevzuatı | 8 | **7** | 1 | 0 | 320 | 26 / 12 / 0 | 360 |
| d) Bankacılık Mevzuatı | 11 | **6** | 5 | 0 | 205 | 31 / 41 / 0 | 360 |
| e) Sigortacılık ve Özel Emeklilik Mevzuatı | 6 | **3** | 2 | 1 | 160 | 33 / 35 / 2 | 360 |
| f) Kurumsal Sürdürülebilirlik Raporlaması | 13 | **0** | 13 | 0 | 0 | 0 / 151 / 0 | 297 |
| g) Sürdürülebilirlik Denetimi | 6 | **3** | 3 | 0 | 160 | 23 / 24 / 0 | 300 |
| **Toplam** | **127** | **64** | **38** | **25** | **2.885** | | **3.705** |

### Sınıflar nasıl verildi

| Sınıf | Şart (hepsi birlikte) |
|---|---|
| **HAZIR** | Beklenen resmî metin ambarda · metin **RESMÎ** (Türkçe harfli, elle yazılmış büyük harf ASCII özet değil) · **TAM** (madde/paragraf numara deliği ≤ %5, bölünmüş `[k/n]` parça eksiği 0, kesik adayı ≤ %5) · konunun hüküm anahtarı **o ailenin içinde** ≥ 2 parçada |
| **ZAYIF** | Resmî metin var ama delikli/kesik, ya da hüküm anahtarı ailede < 2 parçada |
| **YOK** | Beklenen resmî metin ambarda yok **ya da yalnız elle yazılmış özet / teori notu / taslak var** (Cem 14.09: "resmî metin olması ve metnin tam olması") |

Hüküm anahtarı mekanik bir göstergedir, **hakem teyidi değildir**. Eski karnenin (`konu-kaynak-karnesi-kgk.json`) farkı: o, iki kelimenin **tüm ambarda** geçmesine bakıyordu ("kuruluş + banka" → 956 kayıt); bu ölçüm konuyu beklenen resmî metne bağlayıp **o metnin içinde** arar.

## 2 · Konu konu sonuç

### a) Türkiye Muhasebe Standartları

| Sınıf | Konu | Kota | Çıkmış* | Aile | Hüküm parçası | Neden |
|---|---|---:|---:|---|---:|---|
| HAZIR | TMS 2 stoklar, NGD | 60 | 42 | TMS 2 | 13 | resmî + tam |
| HAZIR | TFRS 15 hasılat beş adım | 60 | 34 | TFRS 15 | 64 | resmî + tam |
| HAZIR | TMS 7 nakit akış tablosu | 60 | 28 | TMS 7 | 7 | resmî + tam |
| HAZIR | TFRS 5 satış amaçlı / durdurulan faaliyet | 30 | 27 | TFRS 5 | 14 | resmî + tam |
| HAZIR | TMS 23 borçlanma maliyetleri | 40 | 21 | TMS 23 | 10 | resmî + tam |
| HAZIR | TFRS 16 kiralamalar | 60 | 19 | TFRS 16 | 51 | resmî + tam |
| HAZIR | TMS 8 politika/tahmin/hata | 50 | 16 | TMS 8 | 25 | resmî + tam |
| HAZIR | TMS 28 özkaynak yöntemi | 40 | 15 | TMS 28 | 35 | resmî + tam |
| HAZIR | TMS 29 yüksek enflasyon | 40 | 14 | TMS 29 | 10 | resmî + tam |
| HAZIR | TFRS 13 gerçeğe uygun değer | 50 | 13 | TFRS 13 | 56 | resmî + tam |
| HAZIR | TMS 10 raporlama dönemi sonrası | 40 | 12 | TMS 10 | 7 | resmî + tam |
| ZAYIF | TMS 36 değer düşüklüğü | 60 | 52 | TMS 36 | 60 | 10 delik (25–27, 91–95, 138–139) |
| ZAYIF | TMS 16 yeniden değerleme | 71 | 40 | TMS 16 | 8 | **p.31–40 (yeniden değerleme modeli) numara olarak yok; metin "TMS 16 p.5 - Maliyet modeli" parçasına yapışık** — teyit edildi |
| ZAYIF | TMS 40 yatırım amaçlı gayrimenkul | 40 | 29 | TMS 40 | 36 | 23 delik (33–39 gerçeğe uygun değer yöntemi dahil) |
| ZAYIF | TMS 38 maddi olmayan duran varlık | 50 | 27 | TMS 38 | 19 | 8 delik |
| ZAYIF | TMS 12 ertelenmiş vergi | 60 | 27 | TMS 12 | 81 | 8 delik + 7 kesik adayı |
| ZAYIF | TMS 1 önemlilik / netleştirme | 60 | 24 | TMS 1 | 2 | 10 delik |
| ZAYIF | TFRS 3 şerefiye | 50 | 20 | TFRS 3 | 29 | 10 kesik adayı (%5,8) |
| ZAYIF | TMS 41 canlı varlık | 30 | 17 | TMS 41 | 31 | 11 delik |
| ZAYIF | TMS 21 parasal kalemler | 50 | 16 | TMS 21 | 11 | 5 kesik adayı (%5,8) |
| ZAYIF | TMS 37 koşullu borç/varlık | 60 | 16 | TMS 37 | 85 | 16 delik |
| ZAYIF | TMS 19 kıdem / tanımlanmış fayda | 40 | 11 | TMS 19 | 53 | 22 delik |
| ZAYIF | TMS 1 süreklilik / tablo seti | 30 | 3 | TMS 1 | 2 | 10 delik |
| ZAYIF | TFRS 7 açıklamalar / risk | 30 | 1 | TFRS 7 | 30 | 11 kesik adayı |
| **YOK** | TFRS 9 sınıflandırma / BKZ | 60 | 25 | TFRS 9 | — | ambarda yalnız **11 parçalık elle yazılmış özet** |
| **YOK** | TMS 24 ilişkili taraf | 30 | 15 | TMS 24 | — | yalnız 6 parçalık özet |
| **YOK** | TFRS 8 faaliyet bölümleri | 30 | 9 | TFRS 8 | — | yalnız 6 parçalık özet |
| **YOK** | TFRS 10 konsolidasyon / kontrol | 50 | 9 | TFRS 10 | — | yalnız 7 parçalık özet |
| **YOK** | TMS 27 bireysel tablolar | 30 | 4 | TMS 27 | — | yalnız 5 parçalık özet |
| **YOK** | TFRS 9 korunma muhasebesi | 30 | 2 | TFRS 9 | — | yalnız özet |

### b) Türkiye Denetim Standartları

HAZIR (24): BDS 315 (çıkmış* 32) · 530 (27) · 200 (24) · 705 (23) · 240 (19) · 570 (16) · 500 (16) · 700 (15) · 230 (13) · 520 (13) · 540 (12) · 210 (12) · 320 (12) · 706 (11) · 300 (11) · 220 (10) · 450 (10) · 720 (9) · 501 (9) · 505 (8) · 550 (7) · Bağımsız Denetim Yönetmeliği yetkilendirme (1) · BDY bağımsızlık/rotasyon (0) · 660 KHK görev-yetki (0). Hepsi resmî KGK 2025 TDS seti + tam.

| Sınıf | Konu | Kota | Çıkmış* | Neden |
|---|---|---:|---:|---|
| **YOK** | BDS 330 risklere karşı yapılacak işler | 50 | 26 | yalnız 6 parçalık özet |
| **YOK** | BDS 701 kilit denetim konuları | 30 | 13 | yalnız 4 parçalık özet |
| **YOK** | BDS 510 ilk denetimler | 30 | 12 | yalnız 3 parçalık özet |
| **YOK** | BDS 580 yazılı beyanlar | 30 | 8 | yalnız 3 parçalık özet |
| **YOK** | BDS 620 uzman çalışmaları | 30 | 7 | yalnız 3 parçalık özet |
| **YOK** | BDS 265 iç kontrol eksiklikleri | 30 | 6 | yalnız 4 parçalık özet |
| **YOK** | BDS 260 üst yönetimle iletişim | 30 | 4 | yalnız 6 parçalık özet |

### c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim

**Kurumsal Yönetim — 10/10 HAZIR.** Kaynak: Kurumsal Yönetim Tebliği (II-17.1), 47 parça, resmî, tam. Komiteler (çıkmış* 60) · genel kurul (19) · faaliyet raporu (19) · menfaat sahipleri (14) · yatırımcı ilişkileri (12) · pay sahipliği/azlık (7) · kamuyu aydınlatma (7) · ilişkili taraf işlemleri (5) · teminat-rehin-ipotek (2) · uyum raporu (1).
Bütünlük kapısının bu tebliğ için saydığı 15 "kesik", İlkeler ekinin 24 parçaya bölündüğü sınırlardır (ilke numarası bir parçanın sonunda, gövdesi sonrakinde) — **metin kaybı yok**, parça parça okunarak teyit edildi.

**Finansal Yönetim — 11 YOK + 1 ZAYIF.** Ambarda 85 parçalık teori notu var; hüküm anahtarları bulunuyor ama **resmî metin değil**. Faiz hesapları (çıkmış* 39) · paranın zaman değeri (24) · işletme sermayesi (18) · risk-getiri/CAPM (17) · sermaye bütçelemesi (14) · başabaş/kaldıraç (9) · oran analizi (7) · tahvil/para piyasası (7) · türev (6) · temettü (3) · WACC (2). ZAYIF: finansman teknikleri — 6361 s.K. resmî ama **forfaiting** hiçbir kaynakta yok. Dayanak kara listesinde iki FY notu zaten var (`Teori Notu - isletme sermayesi yonetimi`, `- oran analizi likidite`).

### ç) Sermaye Piyasası Mevzuatı — 7 HAZIR, 1 ZAYIF

HAZIR: halka arz satış yöntemleri (II-5.2) · borsalar ve piyasa işleticileri (Yönetmelik + 6362) · değiştirilebilir tahvil (VII-128.8) · nitelikli yatırımcıya satış (II-5.2) · fiyat/dağıtım esasları (II-5.2) · sermaye piyasası suçları (6362) · izahname muafiyeti (II-5.1).
ZAYIF: kayıtlı sermaye sistemi (II-18.1, çıkmış* 12) — 22 parçanın 2'si kesik adayı (%9).

### d) Bankacılık Mevzuatı — 6 HAZIR, 5 ZAYIF

HAZIR: VYŞ Yönetmeliği · kredi açma yetkisi · kredi komitesi · düzeltici önlemler (5411) · genel karşılık (Kredilerin Sınıflandırılması ve Karşılıklar Yön.) · sorunlu alacak (aynı Yön. + BDDK rehberi).
ZAYIF: Bankalar THP (çıkmış* 13; THP ailesinin %66'sı resmî Türkçe, izahname parçalarının bir kısmı değil) · katılım bankası fon kullandırma (13; Kredi İşlemleri Yön. m.10, 11, 13, 17 yok) · Bankaların Bağımsız Denetimi Yön. (7; m.22 yok) · hesap durumu belgesi (5; Kredi İşl. Yön. delikli) · operasyonel risk (3; Sermaye Yeterliliği Yön. 97 parçanın 7'si kesik adayı).

### e) Sigortacılık ve Özel Emeklilik Mevzuatı — 3 HAZIR, 2 ZAYIF, 1 YOK

HAZIR: BES devlet katkısı (4632 s.K., çıkmış* 21) · TTK hayat sigortaları (m.1487–1520, 34 parça) · TTK sorumluluk sigortaları (m.1473–1486, 14 parça).
ZAYIF: TFRS 17 (23; 7 delik: 27, 106, 108–112) · Teknik Karşılıklar Yön. (12; m.4 yok).
**YOK: sigortacılıkta iç sistemler yönetmeliği** — ambarda hiçbir adla yok.

### f) Kurumsal Sürdürülebilirlik Raporlaması — 13 ZAYIF

TSRS 1 (105 parça) ve TSRS 2 (73 parça, 28.07.2026 değişiklikleri dahil) **resmî ama numara delikli**: TSRS 1'de 30, 34, 38, 40, 43, 48, 58, 80; TSRS 2'de 3, 21, 30, 31, 33. En çok çıkan iki konu bu deliklerin yanında: gerçeğe uygun sunum (çıkmış* 47) ve sektörler-arası metrikler (42; ilk koşuda anahtar "sektörler **-** arası" tiresi yüzünden 0 buldu, düzeltildi — ad köprüsü tuzağı).
TSRS uygulama kapsamı kararı (RG 29.12.2023-32414 1. Mük.) ve eşik değer kararı (RG 16.01.2026-33139) **ambarda var**.

### g) Sürdürülebilirlik Denetimi — 3 HAZIR, 3 ZAYIF

HAZIR: GDS 3000 çerçeve (çıkmış* 20) · GDS 3000 kanıt/önemlilik · GDS 3402.
ZAYIF: GDS 3410 sera gazı (24) ve GDS 3410 kapsam — 15 delik (25–26, 33, 37–45 …) · GDS 3400 — 8 parça, hepsi 3.000 karakterlik **mekanik dilim** (paragraf yok).
SGDS 5000: ambarda 702 parça, adında "TASLAK (SORU DAYANAĞI YAPILAMAZ)". KGK taslağı 22.10.2025 duyurusuyla görüşe açmış; kesinleşip kesinleşmediği **ölçülmedi**.

## 3 · Aile tamlık tablosu (özet)

Tamamı JSON `aileler` alanında. Burada yalnız HAZIR'ı engelleyenler:

| Durum | Aileler |
|---|---|
| Elle yazılmış özet (resmî değil) | TMS 24 (6) · TMS 27 (5) · TFRS 8 (6) · TFRS 9 (11) · TFRS 10 (7) · TFRS 18 (23) · BDS 260 (6) · 265 (4) · 330 (6) · 510 (3) · 580 (3) · 620 (3) · 701 (4) |
| Resmî, numara delikli | TMS 1 · 12 · 16 · 19 · 20 · 34 · 36 · 37 · 38 · 40 · 41 · TFRS 1 · 17 · BDS 710 · KYS 1 · Etik Kurallar · TSRS 1 · TSRS 2 · GDS 3410 · BBD-Yön · Kredi İşl. Yön · TK Yön |
| Resmî, kesik adayı > %5 | TMS 21 · TMS 32 · TFRS 3 · TFRS 7 · BDS 610 · II-18.1 · SY Yön · BDDK Sorunlu Alacak Rehberi (paragraf numarası yok, 36/102) |
| Mekanik dilim | GDS 3400 |
| Yok | Sigortacılıkta iç sistemler yönetmeliği · BES devlet katkısı yönetmeliği |

**Numara deliği iki anlama gelir:** metin gerçekten yok, ya da başka parçanın içine yapışık. TMS 16'da yapışık çıktı. İkisinde de paket seçici "p.31"i bulamaz, hakem "kaynakta yok" der. Onarım aynı: **resmî PDF'ten yeniden parçalama (bedel 0)**.

## 4 · YUTMA İŞ EMRİ TASLAĞI (Cem onayı bekler — başlatılmadı)

### A) Ambarda hiç olmayan resmî metinler

| # | Metin | Künye | Resmî kaynak | İndirme yeri | Engellediği |
|---|---|---|---|---|---|
| A1 | Sigortacılık ve Özel Emeklilik Sektörlerinde İç Sistemlere İlişkin Yönetmelik (SEDDK) | RG 25.11.2021-31670 (önceki: Sigorta ve Reasürans ile Emeklilik Şirketlerinin İç Sistemlerine İlişkin Yön., RG 21.06.2008-26913) | mevzuat.gov.tr | **yerel makine** (TR-IP) | e) 1 konu, kota 40 |
| A2 | Bireysel Emeklilik Sisteminde Devlet Katkısı Hakkında Yönetmelik | RG 31.12.2022-32060 (5. Mük.) | resmigazete.gov.tr/eskiler/2022/12/20221231M5-4.htm | ölçülmedi (Resmî Gazete'nin buluttan inip inmediği `ip-olcum.yml`'de yok) | konu 4632 ile HAZIR; oran/hak kazanma ayrıntısı için |

### B) Ambarda yalnız özet olan standartlar → KGK resmî setinden yeniden yutulacak

Adresler 14.09.2026'da bu makineden HEAD isteğiyle yoklandı: **14/14 HTTP 200, application/pdf** (içerik imzası `%PDF` indirmeden ölçülmedi). Taban: `https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/`. KGK buluttan iner.

| # | Standart | Yol (tabana eklenir) | Boyut | Engellediği çıkmış* |
|---|---|---|---:|---:|
| B1 | TFRS 9 | `TMS_TFRS_Setleri/2026/Kirmizi_Kitap/TFRS/TFRS 9.pdf` | 1,34 MB | 27 |
| B2 | TMS 24 | `TMS_TFRS_Setleri/2026/Kirmizi_Kitap/TMS/TMS 24.pdf` | 0,35 MB | 15 |
| B3 | TFRS 8 | `…/Kirmizi_Kitap/TFRS/TFRS 8.pdf` | 0,30 MB | 9 |
| B4 | TFRS 10 | `…/Kirmizi_Kitap/TFRS/TFRS 10.pdf` | 0,54 MB | 9 |
| B5 | TMS 27 | `…/Kirmizi_Kitap/TMS/TMS 27.pdf` | 0,31 MB | 4 |
| B6 | BDS 330 | `TDS/TDS_2025_Seti/BDS 330_2025.pdf` | 1,12 MB | 26 |
| B7 | BDS 701 | `TDS/TDS_2025_Seti/BDS 701_2025.pdf` | 1,23 MB | 13 |
| B8 | BDS 510 | `TDS/TDS_2025_Seti/BDS 510_2025.pdf` | 0,65 MB | 12 |
| B9 | BDS 580 | `TDS/TDS_2025_Seti/BDS 580_2025.pdf` | 0,82 MB | 8 |
| B10 | BDS 620 | `TDS/TDS_2025_Seti/BDS 620_2025.pdf` | 1,02 MB | 7 |
| B11 | BDS 265 | `TDS/TDS_2025_Seti/BDS 265_2025.pdf` | 0,46 MB | 6 |
| B12 | BDS 260 | `TDS/TDS_2025_Seti/BDS 260_2025.pdf` | 0,82 MB | 4 |
| B13 | GDS 3400 (mekanik dilim → paragraf) | `TDS/TDS_2025_Seti/GDS 3400_2025.pdf` | 0,43 MB | — |

⚠ Eski özet parçalar yeniden yutmada **silinmeden önce** kasada onlara dayanan sorular sayılmalı (bölüm 6, madde 4).

### C) Karar gerektiren: Finansal Yönetim'in resmî kaynağı

Finansal yönetimin (paranın zaman değeri, WACC, CAPM…) kanun/yönetmelik anlamında resmî metni yoktur. Ölçülen seçenek: **SPL "Finansal Yönetim ve Mali Analiz" (ders kodu 1007) sınav çalışma notu** — `https://spl.com.tr/sinav-calisma-notlari/` sayfasında ücretsiz PDF, güncelleme tarihi 30.06.2026; yayın hakları SPL'de. SPL resmî lisanslama kuruluşudur ama bu **mevzuat değil, ders notudur**. Seçenekler: (1) SPL notunu "resmî kurum yayını" sayıp yut (telif: yalnız dayanak olarak, metin soruya kopyalanmaz), (2) FY'yi mevcut teori notlarıyla "resmî metin dışı" hatta bırak, (3) FY'yi sprinte almamak. **Kararı Cem verir.**

### D) Parasız onarım listesi (ZAYIF → HAZIR adayı; resmî PDF'ten yeniden parçalama)

TMS 1, 12, 16, 19, 21, 36, 37, 38, 40, 41 · TFRS 3, 7, 17 · TSRS 1, TSRS 2 · GDS 3410 · II-18.1 · Bankaların Bağımsız Denetimi Yön. · Kredi İşlemleri Yön. · Sermaye Yeterliliği Yön. · Teknik Karşılıklar Yön. · Bankalar THP izahname. Hepsi resmî kaynaktan bir kez inmiş (kaynak_url dolu; TSRS 2'nin 9 parçasında adres bozuk, bölüm 6).
Yutucuya kapı eklenirse **kapı eklendiyse veri tazelenir** kuralı geçerli; bu betik yeniden koşularak (önce `-Tazele`) etkisi ölçülür.

## 5 · HAZIR KONULARDAN ÜRETİM PLANI ÖNERİSİ — BAŞLATILMADI

**Birim bedel (ölçülmüş, hafızadan değil):** `KALIP-KARAR-KUTUGU.md` 08.09 kaydı — Tur 1 defteri 16 etiket, **160 USD / 748 üretilen / 402 yayınlanabilir = 0,21 USD/üretilen · 0,40 USD/yayınlanabilir**; hakem öne alındıktan sonra beklenen ≈ **0,30 USD/yayınlanabilir**. KGK sorusu için ayrı ölçüm yok → aralık 0,30–0,40 kullanıldı.

| Faz | Kapsam | Hedef (yayınlanabilir) | Tahmini bedel |
|---|---|---:|---:|
| **0** | Ucuz prova: yeni 5 ders/alan (KY, ç, d, e, g) × 1 etiket × 15 üretim | 75 üretilen | ≈ **16 USD** (0,21 × 75) |
| **1** | Boş dersler, yalnız HAZIR satırlar: KY 338 (kota 380 − kasadaki 42) · ç 320 · d 205 · e 160 · g 160 | **1.183** | **≈ 355 – 473 USD** |
| **2** | a) ve b) ders eksiği, yalnız HAZIR satırlarda: a 312 · b 394 | **706** | **≈ 212 – 282 USD** |
| | **Toplam** | **1.889** | **≈ 583 – 771 USD** (prova dahil) |

Satır dağılımı (Faz 1, ek alanlarda kota = satır adedi, kasada 0):
- **ç)** nitelikli yatırımcıya satış 60 · borsalar/piyasa işleticileri 60 · halka arz satış yöntemleri 40 · değiştirilebilir tahvil 40 · fiyat/dağıtım 40 · SP suçları 40 · izahname muafiyeti 40
- **d)** VYŞ 50 · kredi açma yetkisi 40 · kredi komitesi 40 · genel karşılık 25 · düzeltici önlemler 25 · sorunlu alacak 25
- **e)** TTK hayat 60 · TTK sorumluluk 60 · BES devlet katkısı 40
- **g)** GDS 3000 çerçeve 70 · GDS 3000 kanıt/önemlilik 50 · GDS 3402 40
- **KY)** komiteler 55 · ilişkili taraf 45 · genel kurul 40 · menfaat sahipleri 40 · yatırımcı ilişkileri 40 · faaliyet raporu 35 · kamuyu aydınlatma 35 · teminat-rehin 30 · azlık hakları 30 · uyum raporu 30 (toplam 380; kasadaki 42 KY sorusu kota eleğinde düşülür)

Faz 2 önceliği çıkmış* sırasıyla: a) TMS 2 · TFRS 15 · TMS 7 · TFRS 5 · TMS 23 · TFRS 16 · TMS 8 · TMS 28 · TMS 29 · TFRS 13 · TMS 10; b) BDS 315 · 530 · 200 · 705 · 240 · 570 · 500 · 700 …

Hesap: 1.183 × 0,30 = 354,9 · × 0,40 = 473,2 · 706 × 0,30 = 211,8 · × 0,40 = 282,4 · prova 75 × 0,21 = 15,75.
**Kural gereği:** bu tablo onay değildir; para harcayan her adım ayrıca bedeliyle sorulur (UCUZ PROVA → önce Faz 0).

## 6 · Ölçüm sırasında kanıtlanan yan bulgular

1. **KGK "KAYNAK-EKSIK" retlerinin bir kısmı yutma değil paket seçimi hatası.** `kgk-kurfin-30` partisinde "bağımsız üye sayısı üçte bir kuralı kaynakta yok" diye iki ret var; kural ambarda **var**: II-17.1 İlke 4.3.4, `Kurumsal Yonetim Tebligi (II-17.1) m.17 [14/24]`. Aynı partide "yönetim kurulu komiteleri" sorusuna **VYŞ Yönetmeliği m.1–3**, "sistematik olmayan risk" ve "net gelir yaklaşımı" sorularına **TFRS 17 p.0–5** paketlenmiş (ret gerekçelerinden). Paketleyici konunun beklenen ailesinin dışına çıkıyor.
2. **II-17.1'in İlkeler eki `m.17 [k/24]` adıyla duruyor.** Tebliğin 17. maddesi değil, ekidir. Dayanak "İlke 4.3.4" diye aranırsa bulunmaz (ad köprüsü).
3. **TMS 16 p.31–40 yanlış etiket:** yeniden değerleme modeli paragrafları `TMS 16 p.5 - Maliyet modeli` parçasının içinde; p.41/42 başlıkları "Ofis gereçleri ve". Envanter aynı aileyi "TAM (set-birebir; resmî metinde de yok)" diye işaretliyor — bu vakada iddia yanlış (tek vaka ölçüldü, genelleme yapılmadı).
4. **Özet-dayanaklı kasa riski (ölçülmedi, dokunulmadı):** YOK sınıfındaki 13 özet-kaynaklı konuda kasada aynı konu adıyla 206 KGK sorusu var (BDS 330: 34 · 265: 23 · 510: 22 · 260/580/620: 20'şer · TFRS 10: 19 · TMS 24: 18 · TFRS 9: 11 · BDS 701: 7 · TMS 27: 7 · TFRS 8: 5). Dayanaklarının özet parça olup olmadığı ölçülmedi.
5. **TSRS 2'nin 9 parçasında `kaynak_url` = `https://www.mevzuat.gov.tr/mevzuatmetin/HAZIR.pdf`** — geçersiz yer tutucu.

## 7 · Sınırlar (dürüst not)

- **Çıkmış eşlemesi alt sınırdır:** 6.080 çıkmış sorunun 1.644'ü kota satırına eşlenebildi; 640'ı "Genel Hukuk Mevzuatı" (bugünkü 8 dersin dışında); kalan konular ya < 3 çıkmışlı dağınık etiket ya da kota satırıyla kelime eşleşmesi zayıf. Örnek: "sermaye piyasası suçları" satırında çıkmış* 0 görünüyor, eşlenemeyen listede aynı konu 9 soruyla duruyor. ≥ 3 çıkmışlı eşlenemeyen 143 konu (566 soru) JSON `arsiv_kota_disi_sik_konular` alanında.
- **Kasa satır eşlemesi:** `kasa-sayim.json` konu adları kota satırlarıyla yalnız 60/127 birebir eşleşiyor; bu yüzden plan ders eksiğini esas aldı.
- **Hüküm anahtarı hakem değildir.** HAZIR = "resmî + tam metin içinde konu hükmü bulunuyor"; sorunun doğru şıkkını taşıyan cümlenin varlığını ancak üretimdeki hakem söyler.
- **Ölçüt üç kez düzeltildi**, her biri örneklenerek: (1) "noktalamayla bitmeyen = kesik" kanunlarda %50+ yanlış alarm verdi (sonraki madde başlığı yapışması) → bağlaç/virgül kuyruğu ya da 120+ karakter kuyruk; (2) delik sayımında tek uç numara (660 KHK m.34'te biter, "m.46" bir not) → uç değer atıldı; (3) hüküm anahtarı tırnak/tireye takıldı (“önemli yanlışlık” riskleri, sektörler-arası) → kelime arası esnek. Her düzeltmeden sonra yalnız ilgili satırlar değişti.
- **AMBAR-ENVANTERI.md 02.09 tarihli (12 gün bayat)**; VAR/YOK bu yüzden envanterle birlikte **canlı ambardan** (14.09 11:06) okundu. Envanter tazelenmedi.

## SORMADIĞIN AMA GÖRDÜĞÜM

1. **`motor/oturum.ps1 -Ac` birleştirme hatasını yutuyor.** Açılışta `git merge` "Your local changes … would be overwritten" ile **durdu**, betik yine "temiz birleşti" ve "Dal: main · ana telle eşit" yazdı; gerçekte 13 commit geride kalmıştı. İki dosya ana telle birebir aynı olduğu için elle hizaladım. Başka oturumda bu hata sessiz çakışma üretir.
2. **KGK Finansal Yönetim kasasında ders dışı konu etiketleri var:** "kamu gideri tanımı", "kamu mali yılı", "VUK maliyet bedeline dahil unsurlar (m.275)", "TMS 7 nakit akış tablosu", "TFRS 8 bölüm raporlaması" (`kasa-sayim.json` konu_yogunluk). Yanlış derse yazılmış ya da yanlış dersten üretilmiş.
3. **Commit'siz 3 dosya başka oturumdan duruyor:** `veri/bekleyen-partiler.json` (+2.852 satır), `veri/yanveri-damga.json`, `veri/sinav/kaydir-secim/plan-smmm-pilot-1309-secim.json`. Dokunmadım.

## GM ÖNERİLERİ

1. **Önce parasız onarım, sonra para (bu hafta 1. gün).** Bölüm 4-B'deki 13 PDF'i (11 özet standart + GDS 3400) ve 4-D'deki delikli aileleri KGK/mevzuat resmî setinden yeniden yut; bu betiği `-Tazele` ile yeniden koş. Beklenen: a) 6 YOK + b) 7 YOK konunun resmî metne kavuşması (çıkmış* 140 soru), TSRS onarılırsa f) dersinin açılması (çıkmış* 151). Bedel 0; yutma listesi senin onayına bağlı.
2. **Sprint'i boş derslerden başlat, ucuz provayla.** Faz 0 (≈16 USD, 75 üretilen) KGK'ya özgü verimi ölçer; oran Tur 1'in %54 yayın verimine yakınsa Faz 1 (1.183 soru, ≈355–473 USD). a/b zaten %71–78 dolu; Faz 2 onarım bittikten sonra, HAZIR satır sayısı artmış hâlde koşulursa aynı para daha fazla konuya yayılır.
3. **Paketleyiciye "beklenen ailede kal" kapısı (KGK yolu, SGS'ye dokunmadan).** KGK konu satırında beklenen resmî aile belli (bu ölçümün `aileler` alanı); kaynak paketi o ailenin dışından parça alırsa hakem öncesi düşsün. Bölüm 6-1'deki üç ret doğrudan bu kapıya takılırdı. Ayrı iş emri; kod değişikliği senin onayınla.

---

## GÜNCELLEME 15.09 ~14:45 · Cem "1.2.3 üçünüde yap"

**(1) GM elle yazım → kilitli kasa (`kalip_parti`).** Her soru kaynak alıntısıyla geri okundu, kod kapılarından (0 USD) ve dört ücretli kapıdan geçti (hakem EVET ∧ kör çözüm doğru ∧ hakem2 EVET ∧ simülasyon doğru).

| Parti | Ders | Soru | Ücretli doğrulama |
|---|---|---|---|
| kgk-gm-ky-r1 | Kurumsal Yönetim (II-17.1) | 10 | ≈0,33 USD (14.09) |
| kgk-gm-spk-r1 | Sermaye Piyasası (II-5.2, II-5.1, VII-128.8, 6362 m.65/107) | 7 | ≈0,27 USD |
| kgk-gm-bank-r1 | Bankacılık (Kredi İşl. Yön., KSK Yön., VYŞ Yön., 5411 m.68-70) | 6 | ≈0,13 USD (+ağ kesintisinde yarım kalan toplu parti) |
| kgk-gm-gds-r1 | Sürdürülebilirlik Denetimi (GDS 3000, 3400, 3402) | 4 | ≈0,11 USD |

Yeni soru 27 (15.09) + 10 (14.09) = 37. Düzeltilerek geçen: SPK kp-03 (ilke kararı paketten düştü → D şıkkı Tebliğ m.13), SPK kp-04 (hakem olumsuz kökte şaştı → olumlu kök), GDS kp-03 (GDS 3402 p.9 6.408 kr, 4.500 kr hakem paketinden düştü → p.2/p.8/p.15). Site sayfası kurulmadı (paket içeriği açıkta riski; karar Cem'de).

**Hat dersleri (tekrar düşülmesin):** hakem paketi 4.500 kr → dayanak parçaları kısa ve toplamı tavanın altında seçilir · KGK'da olumlu kök · tutar resmî yazımla ("750.000.000 TL"; "750 milyon" KAPI-H'de THP 750 hesabı sanılıyor) · `-DersRegex` KAPI-AILE ders desenini tutmalı ("Bankacılık", "Sürdürülebilirlik Denetim").

**(3) TMS/TFRS paragraf numarası onarımı (`b5ad762b`, 0 USD).** Layout bölmesi + resmî numara hakikati seçimi. Eşdeğerlik provası 41 standartta (ambarın tamamı): eksik 641→412 · sahte 27→7 · çift 225→24; kötüleşen yalnız TMS 36 p.140G (+1 sahte, metin kaybı yok). 37 standart `yutma-recetesi -uygula` ile yazıldı, 37/37 doğrulandı, düşen 0; bağ etkisi önceden ölçüldü: kopan bağ 0, korunan 582, TMS 8'in 39 kopuk bağı ("p.1 - Amaç") kendiliğinden geri geldi.

Tazeleme (14:37, bu betik `-Tazele`): **a) TMS HAZIR 12→23, ZAYIF 18→7** · b) H28/Z3 · c) H10/Z1/Y11 · ç) H7/Z1 · d) H6/Z5 · e) H4/Z1/Y1 · f) Z13 · g) H4/Z2.

**Kopan bağlar:** 243'ün 137'si (KGK, yayında değil, "BDS 501/505/520/705 p.1 - Giriş - Kapsam" → "p.1 - Kapsam") yeniden bağlandı, geri okundu; yedek `_yerel-veri-kasasi/baglama-yedek/20260915-bds-p1-kapsam.json`. TMS 8 (39) yeniden yutmayla döndü. **Açık:** 2 SGS sorusu (BDS 501; SGS'ye dokunulmadı) · 65 KGK sorusu "BDS 530 Ek-2 1" (yeni ad da kusurlu, aşağıda) · TMS/TFRS'de eskiden kopuk 1.659 bağ (eski numaralar kaymalı olduğu için p-numarasıyla körlemesine bağlanamaz; metin eşleştirmeli iş emri).

**Yeni bulgular:** BDS 530/315/540/600/210 ve GDS 3000 ek tabloları "Ek" ön ekini kaybetmiş (ör. `BDS 530 p.1 - ETKİSİ`, ana metnin p.1'iyle çakışıyor; tablo metni sütun karışık) · GDS 3000 p.45–47 S/M iki sütun iç içe · TFRS 17 B-serisi, TMS 32 UR, TMS 33/21 Ek A, TMS 27 p.6+ iki kipte de ayrı parçaya bölünmüyor (412 eksiğin çoğu; metin var, etiket yok).

---

## GÜNCELLEME 15.09 ~16:00 · Cem ikinci "1.2.3 üçünüde yap"

**(1) Muhasebe Standartları GM elle yazım — `kgk-gm-tms-r1`, 10 soru kasada.** 15.09 TMS onarımıyla yeni HAZIR olan konular: TFRS 15, TMS 7, TMS 38, TFRS 16 (hesaplı), TMS 37, TMS 29, TFRS 13, TMS 19, TFRS 8, TMS 23. Dört ücretli kapı 10/10; bedel ≈0,34 USD. TMS 24 bilerek seçilmedi (p.9 tek başına 4.890 kr, hakem paketine sığmaz). Kasa şimdi: KY 10 · SPK 7 · Bankacılık 6 · GDS 4 · TMS 10 = **37+10 = 47 GM sorusu**.
Düzeltilen: TMS 37 hesaplı garanti karşılığı sorusu hakemden iki kez HAYIR aldı (hakem "sayılar Standarttaki çözümlü örnekle aynı değil" dedi, doğru şıkkı kendisi EVET buldu) → kavramsal soruya çevrildi, geçti. **Hat kusuru:** Standardın içinde çözümlü sayısal örnek bulunan paragrafa dayanan hesaplı sorularda hakem yanlış HAYIR veriyor; TFRS 16 hesaplısı (örneksiz paragraf) geçti.

**(2) BDS/GDS rakamlı ek adları — `7ae253f2`, 0 USD.** "Ek 1/2" başlıklı ekler artık `BDS 530 Ek 2 p.1 - …` adını alıyor; ad içindeki hizalama boşlukları sadeleşti. Eşdeğerlik: 86 standart asıl hat provası (fark yalnız ek önekli adlar + 5 boşluk sadeleşmesi, diğer 0) + 82 standart işlev düzeyi (ek başlığı dışında metin 82/82 aynı). 24 standart yeniden yutuldu (24/24 doğrulandı, düşen 0, kopan soru bağı 0). **65 KGK sorusu** `BDS 530 Ek-2 1 - …` → `BDS 530 Ek 2 p.1 - FAKTÖR ETKİSİ` bağlandı, 65/65 geri okundu (yedek `_yerel-veri-kasasi/baglama-yedek/20260915-bds530-ek2.json`). 15.09 sabahki 243 kopuk bağdan açık kalan: yalnız 2 SGS sorusu (SGS'ye dokunulmadı).
Yan etki (ölçüldü): 4 ek giriş parçası yalnız atıf satırından oluşuyor ("(Bkz.: A88 paragrafı)", 21–45 kr), bütünlük kapısı bunları başlık-only sayıyor. Metin resmî, kayıp yok. SBDS 2400/2410 kapsam dışı bırakıldı: ambardaki biçimleri başka hattan ("ön bölüm [k/31]").

**(3) Hakem/kör paket tavanı ölçümü — 0 USD.** Ayrı rapor: [PAKET-TAVANI-OLCUMU.md](PAKET-TAVANI-OLCUMU.md). Tavanı (4.500 kr) aşan sorularda hakem reddi 2,1–2,4 kat (SGS %20,9 / %8,6 · SMMM %24,5 / %12,4 · KGK %9,0 / %4,3); korelasyon, nedensellik ≈0,5 USD'lik provayla ölçülür. Tavan yükseltmenin tahmini bedeli +0,003–0,005 USD/soru. Karar Cem'de.

---

## GÜNCELLEME 15.09 ~23:50 · Cem "1.2.3 üçünüde yapalım" (eksik resmî metin · Finansal Yönetim · parasız onarım/ölçüm)

Kaynak: KGK sınav/kaynak/basım Excel'i (masaüstü `KGK-Sinav-Kaynak-Basim-Plani.xlsx`; 29 dönem, 5.440 çıkmış soru × kaynak × ambar). Bedel 0.

**(1) Eksik resmî metinler — yutuldu (geri okumayla doğrulandı):**

| Kaynak | Künye | Ambar | Çıkmış (2022+) |
|---|---|---|---|
| Bankaların Bilgi Sistemleri ve Elektronik Bankacılık Hizmetleri Yön. | RG 15.03.2020-31069 · MevzuatNo 34360 | 98 parça · m.1–47 deliksiz | 23 (23) |
| BES Devlet Katkısı Hakkında Yön. | RG 31.12.2022-32060 (5. mük.) · 39939 | 38 parça · m.1–22 + geç. 3 | 14 (12) |
| Sigortacılık ve Özel Emeklilik Sektörlerinde İç Sistemlere **Dair** Yön. | RG 25.11.2021-31670 · 39063 | 91 parça · m.1–58 | 10 (8) |
| İHS 4400 Üzerinde Mutabık Kalınan Prosedürlerin Uygulandığı İşler | KGK TDS 2025 seti | 98 parça · 1–35, A1–A60, Ek 1–2 | 3 (2) |
| TFRS 19 Kamuya Hesap Verme Sorumluluğu Bulunmayan Bağlı Ortaklıklar | RG 10.08.2025-32982 | 283 parça | 1 (1) |

**BEKLİYOR — TFRS 18** (RG 08.05.2025-32894, 01.01.2027'de yürürlüğe girer): resmî metin 255 parça hazır (kuru prova), ama ambardaki 23 özet parçasına **103 parti bağı (SGS 65 · KGK 28 · SMMM/SPL 10) + 37 KGK havuz sorusu** bağlı. Yutmak bağları koparır, SGS partilerine dokunmayı gerektirir → Cem kararı.

**Parçalayıcı kusuru (motor/mevzuat-yut.ps1 AralikliMaddeDuzelt):** bazı resmî PDF'lerde madde başlığı harf harf aralıklı ("M A D D E1 2 -", "M ADDE 25 –"); madde öncekinin içine yapışıyordu. Eşdeğerlik: 719 metnin tamamı, değişen **18 kaynak**, hepsi kasıtlı (kaybolan madde geri geldi). 18'i yeniden yutuldu. Bağ: soru_havuzu 0; 1 GM sorusu (kgk-gm-bank-r1 kp-01, dayanağı m.13/2) "m.12 [2/2]"den "m.13"e, 2 KGK parti sorusu Pay Tebliği m.15 [2/5]/[3/5]'ten m.15 [2/2]/m.16 [1/4]'e taşındı (yedek `_yerel-veri-kasasi/baglama-yedek/20260915-*`). spl-duzey1-1002 kp-07 kasada sinav=SGS → dokunulmadı.

**(2) Finansal Yönetim:** SPL 1007 "Finansal Yönetim ve Mali Analiz" notu (159 sayfa, 30.06.2026) ilk sayfasında SPL'nin izni olmadan "çoğaltılamaz, kopya edilemez, dijital ortama aktarılamaz" diyor → **izinsiz yutulamaz.** Ambarda FY için ~40 kendi teori notumuz var (paranın zaman değeri, WACC, CAPM, oranlar…); resmî metin değil.

**(3) Tamlık ölçütü düzeltildi — `arac/kgk-hakikat-olcumu.ps1` → `veri/kgk-hakikat-olcumu.json`:** eski "numara deliği" ölçütü resmî metinde [Silinmiştir] olan paragrafları delik sayıyordu (TMS 40: 18 "delik", resmî PDF'e göre 1 eksik). Yeni ölçüt resmî PDF'in paragraf numaralarıyla kıyaslar. **84 standart: 67 TAM · 17 EKSİK.** Eski "delikli" TMS 12/16/40/41, BDS 510/570/610/705 → TAM. EKSİK olanlarda (TFRS 9 161 · TFRS 17 149 · TMS 32 55 · TMS 36 35 · TMS 27 29 …) örneklemde 137 eksik paragrafın 134'ünün **metni ambarda komşu parçada** — metin kaybı değil, etiket (paket hassasiyeti) eksiği. 14 delikli standardın 12'sinde resmî PDF'ten yeniden parçalama ambarla birebir aynı çıktı → yeniden yutma kazandırmıyor; iş bölücüde (B/AG/UR serileri). `kgk-kaynak-olcumu.ps1` artık standart tamlığında hakikat sonucunu kullanıyor. TSRS 1/2 KGK PDF adresi olmadığı için ölçülemedi.

Maddeli SPK/BDDK/SEDDK kaynakları (ambar ad dizisi, bedel 0): SPK tebliğlerinin çoğu deliksiz; mülga maddeler (ör. Sigorta Acenteleri m.21) gerçek.

**Tazeleme sonrası sınıflar:** a) H22/Z8 · b) H30/Z1 · c) H10/Z1/Y11 (Y = FY) · ç) H7/Z1 · d) H6/Z5 · e) H4/Z2/**Y0** · f) Z13 (TSRS ölçülemedi) · g) **H6/Z0**.
**Basım (Excel, modül başına 400):** şimdi basılabilir 1.648 · önce onarım/ölçüm 964 · basılamaz 319 (FY 304 + teori + TFRS 18).

---

## GÜNCELLEME 16.09 ~09:30 · Cem "1.2.3 üçünüde yap" (SPK tamlık · TSRS resmî metin · kaynaksız 223 soru)

**(1) Tebliğ/yönetmelik tamlığı resmî metinle ölçüldü — yeni araç `arac/kgk-mevzuat-tamlik.ps1` → `veri/kgk-mevzuat-tamlik.json`.**
KGK derslerinde geçen 133 belge; ambardaki madde numaraları resmî PDF'le kıyaslandı (mülga maddeler eksik sayılmaz; ek/geçici maddeler ayrı dizi).
**123 ölçüldü: 120 TAM · 3 EKSİK · 10 ölçülemedi.** Bedel 0.
- **EKSİK bulunan ve ONARILAN:** Portföy Saklama Tebliği (III-56.1) 24 maddenin 11'i ambarda yoktu → yeniden yutuldu, 24/24 TAM. Sigorta Teknik Karşılıklar Yön. m.4 → TAM.
- **Kalan tek eksik:** Kâr Payı Tebliği (II-19.1) m.19 ("Yürütme"), m.18'in içinde duruyor — bölücü son maddeyi ayırmıyor; soru değeri yok, bilinen sınır.
- **Ölçülemeyen 10 belge:** 7'si eski SPK tebliğleri (metinde "MADDE" yok, "Madde 3" veya bölüm yapılı), 2'si bot sayfası, 1'i Kotasyon Yönetmeliği.
- **Parçalayıcıda iki yazım kusuru daha bulundu** (`motor/mevzuat-yut.ps1 AralikliMaddeDuzelt`): "MADDE1 –" (sayı bitişik) ve "MADDE 4 (2) –" (dipnot işaretli). Eşdeğerlik provası 719 metnin tamamında: değişen 22 metin, hepsi kasıtlı; 22'si yeniden yutuldu. Bağ: soru_havuzu 0; kalıp-parti önbelleklerinde 22 paket-bağı (SGS/SPL partileri, yayın kararını değiştirmez) — SGS'ye dokunulmadı.
- **Yan bulgu:** 23 belgenin ambardaki `kaynak_url`'i bozuk ("mevzuatmetin/G9:18527.pdf" — pdfId yola yapıştırılmış, HTML hata sayfası veriyor). Yutma etkilenmiyor (adres manifestten kuruluyor), ölçüm aracı adresi çevirerek indiriyor.

**(2) TSRS resmî metni.** Yürürlükteki metin KGK Kurul Kararı, **RG 29.12.2023-32414 (1. mükerrer)**; değişiklik **RG 28.07.2026-33323** (sera gazı). ⚠ RG'nin PDF'i **taranmış görüntü** (3 MB, metin katmanı 4 bin karakter) — makine okuyamaz. Metinli tek resmî kopya KGK'nın kendi dosyası (02.01.2024), ona 2026 değişikliği İŞLENMEMİŞ.
Ölçüm (`kgk-hakikat-olcumu.ps1`, TSRS adresleri eklendi): TSRS 1 resmî 187 numara / ambar 78 · TSRS 2 113 / 32 → **ek paragrafları (B, D, E serileri) etiketlenmemiş.** Kuru prova: yeniden yutma TSRS 1'de +2.027 karakter getiriyor ama ek adlarını bozuyor; TSRS 2'de **8.137 karakter kaybettiriyor** → **yutulmadı.** 28.07.2026 değişikliği ambarda ayrı kaynak olarak VAR (9 parça).

**(3) Kaynağı belirlenemeyen soru 223 → 0.** Eşleme sözlüğüne denetim (BDS 200/210/230/250/265/315/320/330/500/501/520/530/540/600/701/710/720, ETİK, BDY) ve muhasebe (TFRS 15/10/3/6/9/13, TMS 1/7/8/10/12/16/19/20/21/28/37/38/40/41) kuralları eklendi; artıkta kalanlar dersin varsayılanına (genel muhasebe / BDS 200) bağlandı. Excel'in 5. sayfasında her satırın hangi yöntemle bağlandığı yazıyor; **"ders varsayılanı" 1.426 soru — en zayıf bağ, oradan okunur.**

**Excel tazelendi** (`arac/kgk-basim-excel.ps1` artık depoda): her modülde kaynak eşleşmesi %100 · **şimdi basılabilir 1.992** (dünkü ölçümde 1.648) · önce onarım/ölçüm 623 · basılamaz 319 (Finansal Yönetim 304 + maliyet/analiz teori + TFRS 18).

---

## GÜNCELLEME 16.09 ~10:30 · Cem "1.2.3 üçünüde yap" (SPK ölçülemeyenler · TSRS bölücü kipi · varsayılan bağlar)

**(1) Ölçülemeyen 10 belge kapandı — mevzuat tamlığı artık 133/133.**
İki kök neden bulundu:
- **Farklı çizgi karakteri.** Eski SPK tebliğleri madde başlığında tire yerine başka karakter kullanıyor: "MADDE 1 ‒" (U+2012, III-52.2) ve "Madde 1 —" (U+2014, Seri: VIII No: 11). Ölçüm yalnız `-` ve `–` tanıyordu; sınıfa ‒ — − ― eklendi.
- **İndirilemeyen kaynak.** Ambarda `kaynak_url` "mevzuatmetin/HAZIR.pdf" olan iki belge (Değerleme Standartları Tebliği, TSPB Meslek Kuralları) mevzuat.gov.tr'de yok; resmî metni depoda (`veri/mevzuat-hazir/<slug>.txt`). Ölçüm artık o metni okuyor.
**Sonuç: 133 belge ölçüldü, 132 TAM.** Tek eksik: Kâr Payı Tebliği (II-19.1) m.19 "Yürütme" — m.18'in gövdesinde duruyor (bölücü son maddeyi ayırmıyor); soru değeri yok, bilinen sınır.

**(2) TSRS bölücü kipi — `motor/standart-yut.ps1` (dördüncü düzen: SÜTUN KİPİ).**
TSRS'de paragraf numarası SOL SÜTUNDA, metin sağda ("1   TSRS 1 …", "B7   İşletme, …"); mevcut üç kip (TMS / BDS / kılavuz) hiçbiri tutmuyordu. Kip **ada bağlı** açılır (`^TSRS `), başka standardı etkileyemez.
İkinci kusur: metnin İÇİNDEKİ "Ek A'da tanımlanan terimler…" cümlesi sözlük kipini ana metnin ortasında açıyor, 1–86 paragrafını Ek A yığınına akıtıyordu; sütun kipinde başlığın tek başına durması şart koşuldu.
Öz-sınava üç yeni vaka eklendi (p.1/p.2/p.B7 ayrı parça · gerçek "Ek A" sözlük açar · kip BDS'ye sızmaz). Eşdeğerlik: TMS 40 · BDS 510 · TFRS 9 yeniden bölmede **parça ve karakter birebir aynı**.
**TSRS 1 yazıldı: 105 → 195 parça, 91.175 → 96.174 karakter** (ana metin 91, Ek B 59, Ek D 33, Ek E 6). Geri okuma doğrulandı.
**TSRS 2 YAZILMADI:** yeniden bölme 5.367 karakter kaybettiriyor (ambar 97.929 → 92.562); metin ambarda zaten tam, kayıp göze alınmadı.
Bağ: TSRS 1'e bağlı 108 paket bağının KGK partisindeki 72'si yeni adlara taşındı (yedek `_yerel-veri-kasasi/baglama-yedek/20260916-tsrs1-*`), kasaya yüklendi. **SGS partilerindeki 60 bağa dokunulmadı** (5 parti: sgs-t1/t2-fmuh) — paket listesi bağı, yayın kararını değiştirmez.

**(3) "Ders varsayılanı" bağlar için bağımsız ikinci ölçü — yeni araç `arac/kgk-soru-atif-olcumu.ps1` → `veri/kgk-soru-atif.json`.**
Konu etiketi kaynağı söylemiyorsa bağ dersin ana kanununa düşüyordu (1.426 soru). Etiketten bağımsız ölçü: **sorunun kendi metnindeki açık atıf**. Ambardaki 108 KGK kitapçığı "SORU N:" ile bölündü, metinde geçen standart/kanun/tebliğ adları sayıldı.
**12.131 soru tarandı; 3.671'inde (%30,3) açık atıf var, 124 tekil kaynak.** En çok: 6362 s.K. 572 (2022+ 264) · 5411 s.K. 394 (122) · BOBİ FRS 205 (94) · TSRS 2 146 (114) · 5684 s.K. 144 (44) · TSRS 1 117 (89).
Excel'e iki sütun (kaynak başına "soru metninde açık atıf" ve "2022+") ve 8. sayfa eklendi. Basım payları hâlâ etiket ölçümünden gelir; bu sütun **kontrol** içindir: payı büyük ama metin kanıtı zayıf kaynak buradan görülür.
