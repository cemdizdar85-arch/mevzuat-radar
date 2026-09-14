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
