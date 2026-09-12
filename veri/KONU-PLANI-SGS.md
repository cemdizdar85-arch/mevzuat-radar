# KONU PLANI — STAJA BAŞLAMA (SGS)

> Uretim: **11.09.2026 18:37** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.238 konu** var. Bunlarin **2.833**'inde elimizde soru YETERSIZ; toplam **6.636 soru** basilacak. Su an bu konularda **1.687** saglam sorumuz var.

## 0a · IKI HAT — Cem karari (11.09)

> *"matematik, ingilizce ve baska ne varsa sozel beklesin; digerlerini bir bitirelim sonra bunlara donelim"*

| Hat | Ders | Konu | Soru | Bedel (toplu) |
|---|---|---:|---:|---:|
| **SIMDI** | Alan Bilgisi (muhasebe · denetim · hukuk · ekonomi · maliye) | **2.265** | **5.197** | **34.092 TL** |
| BEKLESIN | Matematik · Yabanci Dil · Turkce · Inkilap · Genel Kultur | 568 | 1.439 | 9.440 TL |

Bekleyen hat mevzuata dayanmaz; kaynak paketi mantigi (ambardan madde cekme)
orada islemez, ayri bir hat gerektirir. 08.09'da da ayni sebeple Tur 1 disinda kalmislardi.
**Asagidaki butun tablolar SIMDI hattini gosterir**; bekleyen hat bolum 4'te ayri durur.

## 0b · BEDEL ve ONCELIK — SIMDI hatti

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 5 | 46 | 604 TL | 302 TL |
| 2 · kritik | cikmis >= 5 | 47 | 367 | 4.815 TL | 2.408 TL |
| 3 · onemli | cikmis >= 3 | 184 | 962 | 12.621 TL | 6.311 TL |
| 4 · orta | cikmis >= 2 | 408 | 1.557 | 20.428 TL | 10.214 TL |
| 5 · tamami | cikmis >= 1 | 2.265 | 5.197 | 68.185 TL | 34.092 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 598 | 332 | 1.526 | **1.232** | 524 |
| Denetim | 16 | 337 | 281 | 822 | **630** | 265 |
| Mali Tablolar Analizi | 8 | 107 | 64 | 295 | **243** | 91 |
| Maliyet Muhasebesi | 8 | 209 | 133 | 521 | **413** | 173 |
| Maliye | 6 | 103 | 70 | 236 | **188** | 88 |
| Ekonomi | 6 | 79 | 39 | 178 | **145** | 68 |
| Borclar Hukuku | 6 | 98 | 89 | 260 | **189** | 72 |
| Ticaret Hukuku | 6 | 133 | 111 | 331 | **248** | 109 |
| Meslek Hukuku | 6 | 73 | 23 | 204 | **182** | 71 |
| Vergi Hukuku | 6 | 153 | 81 | 349 | **297** | 131 |
| Is ve Sosyal Guvenlik Hukuku | 6 | 92 | 44 | 245 | **202** | 83 |
| Ekonomi (ayristirilamadi) | — | 93 | 25 | 199 | **178** | 86 |
| Hukuk (ayristirilamadi) | — | 221 | 55 | 491 | **451** | 207 |
| Muhasebe (ayristirilamadi) | — | 269 | 66 | 566 | **508** | 251 |
| Maliye (ayristirilamadi) | — | 47 | 6 | 96 | **91** | 46 |
| **TOPLAM** | **130** | **3.238** | **1.687** | | **6.636** | **2.833** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 524 konu, 1232 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| muhasebe bilgi sistemi | 10 | 10 | 2 | 1 | 12 | **9** |
| nakit akis tablosu | 8 | 7 | 3 | 0 | 12 | **9** |
| tms 40 yatirim amacli gayrimenkul | 8 | 8 | 1 | 3 | 12 | **8** |
| hisse senedi satisi | 7 | 7 | 0 | 0 | 11 | **11** |
| sermaye artirimi | 7 | 7 | 0 | 1 | 11 | **10** |
| gider tahakkuku | 7 | 7 | 2 | 0 | 11 | **9** |
| tms 37 karsiliklar | 7 | 7 | 3 | 0 | 11 | **8** |
| tms 36 deger dusuklugu | 7 | 7 | 2 | 1 | 11 | **8** |
| tms 18 hasilat | 6 | 6 | 0 | 0 | 9 | **9** |
| tms 38 maddi olmayan duran varlik | 6 | 6 | 1 | 0 | 9 | **8** |
| gelir tahakkuku | 5 | 5 | 1 | 0 | 8 | **7** |
| donemsellik kavrami | 5 | 5 | 1 | 1 | 8 | **6** |
| tms 2 stoklar | 5 | 5 | 2 | 0 | 8 | **6** |
| ozkaynak hesaplama | 5 | 5 | 1 | 2 | 8 | **5** |
| kar dagitimi kaydi | 5 | 5 | 2 | 2 | 8 | **4** |
| tms 12 ertelenmis vergi | 5 | 5 | 0 | 4 | 8 | **4** |
| gelecek aylara ait giderler | 4 | 4 | 0 | 0 | 6 | **6** |
| yasal yedek akce | 4 | 4 | 0 | 0 | 6 | **6** |
| kasa sayim farki | 4 | 4 | 0 | 0 | 6 | **6** |
| depozito iadesi kaydi | 4 | 4 | 0 | 0 | 6 | **6** |
| stok deger dusuklugu | 4 | 4 | 0 | 1 | 6 | **5** |
| tutarlilik kavrami | 4 | 4 | 0 | 2 | 6 | **4** |
| supheli alacak karsiligi | 4 | 4 | 2 | 0 | 6 | **4** |
| amortisman ayirma | 4 | 4 | 2 | 0 | 6 | **4** |
| kollektif sirket kar dagitimi | 4 | 4 | 2 | 1 | 6 | **3** |
| tms 7 nakit akis tablosu | 4 | 4 | 1 | 2 | 6 | **3** |
| tms 28 istirakler | 4 | 4 | 4 | 0 | 6 | **2** |
| duran varlik satisi | 4 | 4 | 4 | 0 | 6 | **2** |
| fifo yontemi | 3 | 3 | 0 | 0 | 5 | **5** |
| donem kari hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| depozitolu kap kirilmasi kaydi | 3 | 3 | 0 | 0 | 5 | **5** |
| isletmenin surekliligi | 3 | 3 | 0 | 0 | 5 | **5** |
| tahvil ihraci | 3 | 3 | 0 | 0 | 5 | **5** |
| onemlilik kavrami | 3 | 3 | 0 | 0 | 5 | **5** |
| kidem tazminati | 3 | 3 | 0 | 0 | 5 | **5** |
| maddi duran varlik denetimi | 3 | 3 | 0 | 0 | 5 | **5** |
| azalan bakiyeler amortisman | 3 | 3 | 0 | 0 | 5 | **5** |
| nazim hesaplar | 3 | 3 | 0 | 0 | 5 | **5** |
| gelecek yillara ait giderler | 3 | 3 | 0 | 0 | 5 | **5** |
| donem kari zarari hesabi | 3 | 3 | 0 | 0 | 5 | **5** |
| _… 484 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Denetim — 265 konu, 630 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim kaniti yeterliligi | 11 | 9 | 2 | 2 | 12 | **8** |
| denetim kaniti guvenilirligi | 8 | 7 | 0 | 0 | 12 | **12** |
| denetim riski | 6 | 5 | 0 | 0 | 9 | **9** |
| kasa denetimi | 5 | 5 | 0 | 0 | 8 | **8** |
| denetim kanitlari | 5 | 5 | 0 | 0 | 8 | **8** |
| analitik prosedurler | 5 | 5 | 3 | 1 | 8 | **4** |
| denetim calisma kagitlari | 5 | 5 | 2 | 3 | 8 | **3** |
| denetim gorusu | 4 | 4 | 0 | 0 | 6 | **6** |
| iliskili taraflar denetimi | 4 | 4 | 0 | 0 | 6 | **6** |
| ic kontrol sistemi | 4 | 4 | 1 | 0 | 6 | **5** |
| stok sayimi denetimi | 4 | 4 | 2 | 1 | 6 | **3** |
| calisma kagitlari | 4 | 4 | 2 | 1 | 6 | **3** |
| stok denetimi | 3 | 2 | 0 | 0 | 5 | **5** |
| is guvencesi | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim belgelendirme | 3 | 3 | 0 | 0 | 5 | **5** |
| dikkat cekilen hususlar paragrafi | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim planlamasi | 3 | 3 | 0 | 0 | 5 | **5** |
| yonetim iddialari | 3 | 3 | 0 | 0 | 5 | **5** |
| guvence hizmetleri | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim prosedurleri | 3 | 3 | 0 | 0 | 5 | **5** |
| bagimsiz denetim sureci | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim gorusu turleri | 3 | 3 | 0 | 0 | 5 | **5** |
| yapisal risk faktorleri | 3 | 3 | 0 | 2 | 5 | **3** |
| kilit denetim konulari | 3 | 3 | 3 | 0 | 5 | **2** |
| kanit guvenilirligi | 3 | 3 | 0 | 3 | 5 | **2** |
| denetci raporu | 3 | 3 | 1 | 2 | 5 | **2** |
| kanit yeterliligi | 2 | 1 | 0 | 0 | 3 | **3** |
| risk degerlendirme prosedurleri | 2 | 2 | 0 | 0 | 3 | **3** |
| acilis bakiyeleri denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kaniti uygunlugu | 2 | 2 | 0 | 0 | 3 | **3** |
| denetimde ornekleme | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu alacagi guvence onlemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf islemleri denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetci raporu bolumleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim sozlesmesi icerigi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim teknikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| ucuncu taraf stok denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| hile riski | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal yatirimlar denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kalite kontrolu | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 225 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Mali Tablolar Analizi — 91 konu, 243 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| dikey yuzde analizi | 12 | 11 | 1 | 1 | 12 | **10** |
| net isletme sermayesi | 9 | 8 | 0 | 0 | 12 | **12** |
| yatay analiz | 8 | 8 | 2 | 1 | 12 | **9** |
| aktif devir hizi | 8 | 8 | 1 | 4 | 12 | **7** |
| stok devir hizi | 6 | 6 | 0 | 0 | 9 | **9** |
| cari oran analizi | 6 | 6 | 0 | 0 | 9 | **9** |
| asit-test orani | 4 | 4 | 0 | 0 | 6 | **6** |
| cari oran hesaplama | 4 | 4 | 1 | 1 | 6 | **4** |
| dikey analiz | 3 | 3 | 0 | 0 | 5 | **5** |
| aktif karlilik orani | 3 | 3 | 0 | 1 | 5 | **4** |
| alacak devir hizi | 2 | 2 | 0 | 0 | 3 | **3** |
| cari oran duran varlik | 2 | 2 | 0 | 0 | 3 | **3** |
| likidite orani | 2 | 2 | 0 | 0 | 3 | **3** |
| dikey yuzdelerden bilanco yorumu | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal oran analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| dikey yuzdelerden oz kaynak-aktif | 2 | 2 | 0 | 0 | 3 | **3** |
| karsilastirmali tablolar analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| basit (dogrudan) dagitim yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| yatay analiz degisim yuzdesi | 2 | 2 | 0 | 0 | 3 | **3** |
| kapasite artirici harcama amortismani | 2 | 2 | 0 | 0 | 3 | **3** |
| yuzde degisim analizi | 2 | 2 | 0 | 2 | 3 | **1** |
| karlilik orani secimi | 1 | 1 | 0 | 0 | 2 | **2** |
| trend (yatay) analiz teknigi | 1 | 1 | 0 | 0 | 2 | **2** |
| oz sermaye karliligi (kaldirac ve aktif karlilik) | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran borc ozsermaye | 1 | 1 | 0 | 0 | 2 | **2** |
| oran analizi karsilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| mali tablo analiz teknikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| olagan kar analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| surekli sermaye orani dikey yuzdelerle | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak kârlilik orani | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac orani hesabi (borc-ozsermaye) | 1 | 1 | 0 | 0 | 2 | **2** |
| yatay analiz kar marji | 1 | 1 | 0 | 0 | 2 | **2** |
| cari orani artiran islemler | 1 | 1 | 0 | 0 | 2 | **2** |
| kredili tasit alimi kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| surekli sermaye yuzdesinden asit-test | 1 | 1 | 0 | 0 | 2 | **2** |
| net isletme sermayesi hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak degisimi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac siniriyla kredi kapasitesi | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzde faaliyet kari | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran-asit test hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 51 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliyet Muhasebesi — 173 konu, 413 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ortak maliyet dagitimi | 13 | 13 | 0 | 3 | 12 | **9** |
| normal maliyet yontemi | 7 | 7 | 1 | 2 | 11 | **8** |
| genel uretim gideri dagitimi | 7 | 7 | 2 | 1 | 11 | **8** |
| siparis maliyet sistemi | 7 | 7 | 2 | 1 | 11 | **8** |
| evre maliyet sistemi | 5 | 5 | 0 | 0 | 8 | **8** |
| satilan mamul maliyeti | 5 | 5 | 1 | 2 | 8 | **5** |
| kademeli dagitim yontemi | 4 | 4 | 0 | 0 | 6 | **6** |
| birlesik maliyet dagitimi | 3 | 3 | 0 | 0 | 5 | **5** |
| standart maliyet farklari | 3 | 3 | 0 | 0 | 5 | **5** |
| ekonomik siparis miktari | 3 | 3 | 0 | 0 | 5 | **5** |
| standart maliyet sapmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| uretim maliyeti hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| yari mamul maliyeti | 3 | 3 | 0 | 0 | 5 | **5** |
| ortak urun maliyet dagitimi | 3 | 3 | 1 | 2 | 5 | **2** |
| genel uretim gideri yukleme | 3 | 3 | 2 | 1 | 5 | **2** |
| safha maliyetleme | 2 | 2 | 0 | 0 | 3 | **3** |
| direkt ilk madde geriye dogru hesap | 2 | 2 | 0 | 0 | 3 | **3** |
| ardisik donem satilan mamul maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger birim hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| birlesik maliyet uretim miktari yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| ozel maliyet amortismani | 2 | 2 | 0 | 0 | 3 | **3** |
| ozel maliyet tahliye kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| degisken-normal maliyet birim farki | 2 | 2 | 0 | 0 | 3 | **3** |
| fifo esdeger birim (dimm) | 2 | 2 | 0 | 0 | 3 | **3** |
| birlesik maliyet satis degeri yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| standart maliyet sapma analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| gug birim pay hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet yontemleri karsilastirma | 2 | 2 | 0 | 0 | 3 | **3** |
| borclanma maliyetleri tms23 | 2 | 1 | 0 | 0 | 3 | **3** |
| birim uretim maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| siparis maliyet gug yukleme | 2 | 2 | 0 | 2 | 3 | **1** |
| standart maliyet sistemi | 2 | 2 | 1 | 1 | 3 | **1** |
| safha maliyet sistemi | 2 | 2 | 1 | 1 | 3 | **1** |
| siparis avansi mahsubu | 2 | 2 | 1 | 1 | 3 | **1** |
| direkt ilk madde tuketimi hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| aralikli envanter satilan mal maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ve degisken maliyet sistemi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel siparis karari | 1 | 1 | 0 | 0 | 2 | **2** |
| sekillendirme (donusturme) maliyeti birim hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 133 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye — 88 konu, 188 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| laffer egrisi | 4 | 4 | 0 | 0 | 6 | **6** |
| kamu harcamalari artis nedenleri | 3 | 3 | 0 | 0 | 5 | **5** |
| butce siniflandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| mali anestezi | 3 | 3 | 0 | 2 | 5 | **3** |
| vergi yansimasi | 2 | 2 | 0 | 0 | 3 | **3** |
| artan oranli vergi | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu borc yonetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi tarifesi | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu gelirleri turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| otomatik istikrarlandirici | 2 | 2 | 0 | 1 | 3 | **2** |
| otomatik istikrarlandiricilar | 2 | 2 | 0 | 1 | 3 | **2** |
| parafiskal gelirler | 2 | 2 | 0 | 2 | 3 | **1** |
| parafiskal gelir | 2 | 2 | 0 | 2 | 3 | **1** |
| kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| mundell-fleming sabit kur maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi kamu maliyesi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali kaldirac (tam istihdam butce acigi) | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyonist acik maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kanunu teklifi | 1 | 1 | 0 | 0 | 2 | **2** |
| sabit kurda maliye politikasi etkinligi | 1 | 1 | 0 | 0 | 2 | **2** |
| stagflasyonda maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| saf kamusal mal uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliye politikasi amaclari (ekonomik istikrar) | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| gelir vergisi dilim tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalari artis teorisi | 1 | 1 | 0 | 0 | 2 | **2** |
| yari kamusal mallar | 1 | 1 | 0 | 0 | 2 | **2** |
| durgunlukta maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| duzenleyici denetleyici kurumlar | 1 | 1 | 0 | 0 | 2 | **2** |
| duz oranli vergi grafigi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kapatma usulu | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu borc tahvilleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi harcamasi hesaplama yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye giderleri (butce siniflamasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin karar etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalarinda gercek-gorunuste artis | 1 | 1 | 0 | 0 | 2 | **2** |
| cebre dayanan kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 48 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi — 68 konu, 145 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| is-lm para politikasi etkinligi | 4 | 4 | 0 | 0 | 6 | **6** |
| talep esnekligi | 4 | 4 | 0 | 2 | 6 | **4** |
| para politikasi araclari | 3 | 3 | 0 | 0 | 5 | **5** |
| marjinal fayda | 3 | 3 | 0 | 0 | 5 | **5** |
| cari islemler hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| stolper-samuelson teoremi | 2 | 2 | 0 | 0 | 3 | **3** |
| mukayeseli ustunluk firsat maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| talep fiyat esnekligi | 2 | 2 | 0 | 1 | 3 | **2** |
| genisletici para politikasi araclari | 2 | 2 | 0 | 2 | 3 | **1** |
| j egrisi | 2 | 2 | 0 | 2 | 3 | **1** |
| issizlik istihdam hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| talep/fiyat esnekligi kâr analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogrusal uretim fonksiyonu kose cozumu | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz kuru sterilizasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| bilesik faiz cari hesap | 1 | 1 | 0 | 0 | 2 | **2** |
| j egrisi devaluasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| bilanco talep haklari | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda maksimizasyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| doymazlik varsayimi marjinal fayda | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci rekabet dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik turleri hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| talep kanunu | 1 | 1 | 0 | 0 | 2 | **2** |
| tasarruf paradoksu | 1 | 1 | 0 | 0 | 2 | **2** |
| esneklik ilkesi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam talep uzun donem denge | 1 | 1 | 0 | 0 | 2 | **2** |
| gsyh hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| phillips egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| manset enflasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| faiz orani ust siniri | 1 | 1 | 0 | 0 | 2 | **2** |
| marjinal fayda hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| leontief uretim fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim fonksiyonu ikame esnekligi (dogrusal) | 1 | 1 | 0 | 0 | 2 | **2** |
| marjinal tuketim egilimi | 1 | 1 | 0 | 0 | 2 | **2** |
| arz talep esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet uretim durdurma | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon olcum sapmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| talep egrisini kaydiran faktorler | 1 | 1 | 0 | 0 | 2 | **2** |
| talep fiyat esnekligi (inelastik) | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon-dezenflasyon ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal issizlik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 28 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Borclar Hukuku — 72 konu, 189 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sebepsiz zenginlesme | 8 | 8 | 2 | 0 | 12 | **10** |
| sozlesme sekli | 5 | 5 | 0 | 0 | 8 | **8** |
| sozlesmenin kurulmasi | 4 | 4 | 0 | 0 | 6 | **6** |
| alacagin devri | 4 | 4 | 0 | 0 | 6 | **6** |
| borcun ifa yeri | 4 | 4 | 1 | 1 | 6 | **4** |
| haksiz fiil zamanasimi | 4 | 4 | 2 | 1 | 6 | **3** |
| zamanasimi | 3 | 3 | 0 | 0 | 5 | **5** |
| ucret sozlesmesi | 3 | 3 | 0 | 0 | 5 | **5** |
| takas | 3 | 3 | 0 | 0 | 5 | **5** |
| haksiz fiil unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| haksiz fiil | 3 | 3 | 0 | 0 | 5 | **5** |
| hizmet borclanmasi | 3 | 3 | 1 | 1 | 5 | **3** |
| zamanasimi suresi | 3 | 3 | 1 | 1 | 5 | **3** |
| borclarin ifasi | 3 | 3 | 0 | 3 | 5 | **2** |
| muteselsil sorumluluk | 2 | 2 | 0 | 0 | 3 | **3** |
| sebepsiz zenginlesme sartlari | 2 | 2 | 0 | 0 | 3 | **3** |
| manevi tazminat | 2 | 2 | 0 | 0 | 3 | **3** |
| muteselsil borcluluk | 2 | 2 | 0 | 0 | 3 | **3** |
| ucret sozlesmesi kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| ucret sozlesmesi suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| akdi temerrut faizi siniri (%100) | 1 | 1 | 0 | 0 | 2 | **2** |
| iyiniyetli olmayan sebepsiz zenginlesen | 1 | 1 | 0 | 0 | 2 | **2** |
| alacagin devri sekli | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme onerisi (icap) | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmeden dogan alacakta zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin kesilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sebepsiz zenginlesme ahlaka aykiri amac | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin durmasi halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi kurallari (iade) | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerin kurulmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| borcun ifa zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| kosula bagli sozlesmeler | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimini kesen haller | 1 | 1 | 0 | 0 | 2 | **2** |
| kosula bagli sozlesme | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerde kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| takas kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| ifa yeri ve zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasimi sureleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi asgari bilgileri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 32 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ticaret Hukuku — 109 konu, 248 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| genel islem kosullari | 9 | 9 | 3 | 1 | 12 | **8** |
| cek zorunlu unsurlari | 5 | 5 | 0 | 3 | 8 | **5** |
| ticaret unvani | 5 | 5 | 3 | 1 | 8 | **4** |
| bono zorunlu unsurlari | 4 | 4 | 0 | 0 | 6 | **6** |
| ticari temsilci yetkisi | 4 | 4 | 0 | 0 | 6 | **6** |
| kiymetli evrak ciro | 4 | 4 | 3 | 0 | 6 | **3** |
| tacir sifati | 4 | 4 | 1 | 3 | 6 | **2** |
| tacir olmanin sonuclari | 3 | 3 | 0 | 0 | 5 | **5** |
| kiymetli evrak cek | 3 | 3 | 0 | 2 | 5 | **3** |
| haksiz rekabet davalari | 3 | 3 | 1 | 3 | 5 | **1** |
| anonim sirket organlari | 2 | 2 | 0 | 0 | 3 | **3** |
| tacir kavrami | 2 | 2 | 0 | 0 | 3 | **3** |
| ticaret sicili itiraz | 2 | 2 | 0 | 0 | 3 | **3** |
| bono unsurlari | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket sermayesi | 2 | 2 | 0 | 0 | 3 | **3** |
| sirket birlesmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| anonim sirket sona erme | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari isletme unsurlari | 2 | 2 | 0 | 0 | 3 | **3** |
| temsil yetkisinin sona ermesi | 2 | 2 | 0 | 0 | 3 | **3** |
| cek uzerindeki kayitlar | 2 | 2 | 0 | 1 | 3 | **2** |
| limited sirket ozellikleri | 2 | 2 | 2 | 0 | 3 | **1** |
| pay senedi getirisi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirkete ayni sermaye olabilecekler | 1 | 1 | 0 | 0 | 2 | **2** |
| tacir sifati tasimayanlar | 1 | 1 | 0 | 0 | 2 | **2** |
| genel kurul erteleme | 1 | 1 | 0 | 0 | 2 | **2** |
| zirai kazanc-kollektif sirket | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket ortak sayisi (1-50) | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket kurallari (tescil-organlar) | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket kurulus sozlesmeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirkette mudurler | 1 | 1 | 0 | 0 | 2 | **2** |
| bonoya uygulanmayan police hukumleri (kabul) | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket butlan davasi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket genel kurul | 1 | 1 | 0 | 0 | 2 | **2** |
| ayni sermaye taahhudunun yerine getirilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| beyaz ciro | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret unvani ve isletme adi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| cek ibraz ve duzenleme tarihi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket yonetim kurulu temsil | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 69 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Meslek Hukuku — 71 konu, 182 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| disiplin cezalari | 11 | 11 | 2 | 0 | 12 | **10** |
| meslek etik ilkeleri | 9 | 9 | 0 | 0 | 12 | **12** |
| haksiz rekabet reklam yasagi | 7 | 7 | 2 | 0 | 11 | **9** |
| smmm disiplin cezalari | 3 | 2 | 0 | 0 | 5 | **5** |
| sir saklama yukumlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| meslek mensubu ucret esaslari | 3 | 3 | 0 | 0 | 5 | **5** |
| disiplin yonetmeligi | 3 | 3 | 0 | 0 | 5 | **5** |
| mesleki etik ilkeler | 3 | 3 | 0 | 0 | 5 | **5** |
| reklam yasagi | 3 | 3 | 0 | 0 | 5 | **5** |
| serbest meslek kazanci | 3 | 3 | 3 | 0 | 5 | **2** |
| calisma usul esaslari | 2 | 2 | 0 | 0 | 3 | **3** |
| smmm odalari | 2 | 2 | 0 | 0 | 3 | **3** |
| oda organlari gorevleri | 2 | 2 | 0 | 0 | 3 | **3** |
| meslekle bagdasmayan isler | 2 | 2 | 1 | 0 | 3 | **2** |
| ucret tarifesi | 2 | 2 | 1 | 0 | 3 | **2** |
| disiplin kovusturmasi | 2 | 2 | 2 | 0 | 3 | **1** |
| ucret tarifesi esaslari | 2 | 2 | 2 | 0 | 3 | **1** |
| birlik (turmob) kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| turmob organlari | 1 | 1 | 0 | 0 | 2 | **2** |
| tabela asilmasi kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu ticari faaliyet yasagi | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin kurulu itiraz suresi (30 gun) | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin yonetmeligi itiraz | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek hukuku disiplin cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun birlik | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm oda yapisi | 1 | 1 | 0 | 0 | 2 | **2** |
| staj suresi (3568 sayili kanun) | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek hukuku oda organlari | 1 | 1 | 0 | 0 | 2 | **2** |
| oda gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm disiplin cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek ucret tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin cezalari eslestirme | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek hukuku staj | 1 | 1 | 0 | 0 | 2 | **2** |
| oda genel kurulu yetkileri | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun-odalar | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu silinme halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma usul ve esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm'nin yapabilecegi isler | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 31 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Vergi Hukuku — 131 konu, 297 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| damga vergisi | 5 | 5 | 0 | 0 | 8 | **8** |
| kdv vergiyi doguran olay | 4 | 4 | 1 | 0 | 6 | **5** |
| ozel tuketim vergisi | 3 | 3 | 0 | 0 | 5 | **5** |
| vuk degerleme olculeri | 3 | 3 | 0 | 0 | 5 | **5** |
| kdv matrahi | 3 | 3 | 0 | 0 | 5 | **5** |
| transfer fiyatlandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| kurumlar vergisi mukellefleri | 3 | 3 | 0 | 1 | 5 | **4** |
| kdv istisnalari | 3 | 3 | 0 | 1 | 5 | **4** |
| kdv indirimi | 2 | 2 | 0 | 0 | 3 | **3** |
| asgari kurumlar vergisi | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi istisnalari | 2 | 2 | 0 | 0 | 3 | **3** |
| vuk kapsami | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi zarar mahsubu (5 yil) | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv matrah | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv kapsami | 2 | 2 | 0 | 0 | 3 | **3** |
| tahakkuk esasi | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi mukellefi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi cezalari | 2 | 2 | 0 | 0 | 3 | **3** |
| verginin kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi indirimleri | 2 | 2 | 0 | 0 | 3 | **3** |
| vergilemede etkinlik | 2 | 2 | 0 | 1 | 3 | **2** |
| veraset ve intikal vergisi istisnalari | 1 | 1 | 0 | 0 | 2 | **2** |
| munferit beyanname | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv indirim hakki | 1 | 1 | 0 | 0 | 2 | **2** |
| damga vergisi nusha | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset ve intikal vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| degerli konut vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| harcama vergileri | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv iade incelemesi suresi (3 ay) | 1 | 1 | 0 | 0 | 2 | **2** |
| vuk vergilendirme sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| dijital hizmet vergisi beyani | 1 | 1 | 0 | 0 | 2 | **2** |
| tarh zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ikramiye tahakkuku | 1 | 1 | 0 | 0 | 2 | **2** |
| kurumlar vergisi matrahi | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tevkifat | 1 | 1 | 0 | 0 | 2 | **2** |
| vuk tekerrur | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi incelemesi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv konusu | 1 | 1 | 0 | 0 | 2 | **2** |
| otv kapsaminda vergi ziyai | 1 | 1 | 0 | 0 | 2 | **2** |
| emlak vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 91 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Is ve Sosyal Guvenlik Hukuku — 83 konu, 202 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| toplu is sozlesmesi | 6 | 6 | 1 | 1 | 9 | **7** |
| sendika uyeligi | 6 | 6 | 2 | 1 | 9 | **6** |
| is sozlesmesi turleri | 5 | 5 | 1 | 2 | 8 | **5** |
| yillik ucretli izin | 4 | 4 | 0 | 0 | 6 | **6** |
| is sozlesmesi feshi | 4 | 4 | 0 | 0 | 6 | **6** |
| isci ucretleri | 3 | 3 | 0 | 0 | 5 | **5** |
| sigortali sayilma | 3 | 3 | 0 | 0 | 5 | **5** |
| isveren vekili | 3 | 3 | 0 | 0 | 5 | **5** |
| is kazasi sayilmayan haller | 3 | 3 | 0 | 0 | 5 | **5** |
| sureli fesih | 3 | 3 | 0 | 0 | 5 | **5** |
| ucret yonetmeligi kurallari | 3 | 3 | 0 | 0 | 5 | **5** |
| İs kanunu kapsami | 3 | 3 | 0 | 1 | 5 | **4** |
| kisa uzun vadeli sigorta kollari | 2 | 2 | 0 | 0 | 3 | **3** |
| is kazasi sigortasi | 2 | 2 | 0 | 0 | 3 | **3** |
| is kazasi meslek hastaligi | 2 | 2 | 0 | 0 | 3 | **3** |
| isletme toplu is sozlesmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| toplu is sozlesmesi kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| grev lokavt | 2 | 2 | 0 | 0 | 3 | **3** |
| kismi sureli is sozlesmesi | 2 | 2 | 0 | 1 | 3 | **2** |
| belirli sureli is sozlesmesi | 2 | 2 | 1 | 1 | 3 | **1** |
| fazla calisma | 2 | 2 | 0 | 2 | 3 | **1** |
| uzun vadeli sigorta kollari | 2 | 2 | 1 | 1 | 3 | **1** |
| alt isverenlik | 2 | 2 | 1 | 1 | 3 | **1** |
| satis sozlesmesi zapttan sorumluluk | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika uyeligi kurallari (issizlik 1 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortalilik | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika toplu is sozlesmesi yetkisi (%1) | 1 | 1 | 0 | 0 | 2 | **2** |
| alt isveren iliskisi | 1 | 1 | 0 | 0 | 2 | **2** |
| grev lokavt erteleme | 1 | 1 | 0 | 0 | 2 | **2** |
| yaslilik ayligi prim gunu | 1 | 1 | 0 | 0 | 2 | **2** |
| is sozlesmesi sekli ve turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| is sozlesmesi feshi alacaklari | 1 | 1 | 0 | 0 | 2 | **2** |
| toplu is sozlesmesi yararlanma | 1 | 1 | 0 | 0 | 2 | **2** |
| is kazasi sigortasi kapsami disindakiler | 1 | 1 | 0 | 0 | 2 | **2** |
| is kazasi sayilan haller (sut izni) | 1 | 1 | 0 | 0 | 2 | **2** |
| belirli belirsiz sureli is sozlesmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| is kazasi malulluk orani | 1 | 1 | 0 | 0 | 2 | **2** |
| grev-lokavtta is sozlesmesinin askida kalmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika uyeligi kurallari (15 yas) | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 43 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi (ayristirilamadi) — 86 konu, 178 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| taylor prensibi | 3 | 3 | 0 | 1 | 5 | **4** |
| keynesyen tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketici fazlasi | 2 | 2 | 0 | 0 | 3 | **3** |
| gresham kanunu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| likidite tuzagi | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim duzlestirmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| yeni keynesyen model | 2 | 2 | 0 | 0 | 3 | **3** |
| paranin yansizligi | 2 | 2 | 0 | 0 | 3 | **3** |
| taylor kurali | 2 | 2 | 0 | 0 | 3 | **3** |
| tam rekabet piyasa dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisler hipotezi | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi kaymasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercihleri konvekslik | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam fayda doyum noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| kredi tayinlamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ricardo modeli varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet denge uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| heckscher-ohlin modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tahvil piyasasi dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisli makro modeller | 1 | 1 | 0 | 0 | 2 | **2** |
| cobb-douglas ikame esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| carpan etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercih aksiyomlari | 1 | 1 | 0 | 0 | 2 | **2** |
| uclu acmaz | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi ozellikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| trampa ekonomisi fiyat sayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| piyasa denge fiyati | 1 | 1 | 0 | 0 | 2 | **2** |
| pigou etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tercihlerin butunlugu varsayimi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol fiyat farklilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol piyasasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici fazlasi degisimi | 1 | 1 | 0 | 0 | 2 | **2** |
| yeni klasik model | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ikame mallar kose dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| isci yanilma modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| alman merkantilizmi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 46 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Hukuk (ayristirilamadi) — 207 konu, 451 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ticari is kavrami | 3 | 3 | 0 | 0 | 5 | **5** |
| calisma suresi | 3 | 3 | 0 | 0 | 5 | **5** |
| borclu temerrudu | 3 | 3 | 0 | 0 | 5 | **5** |
| cek hukuku | 3 | 3 | 0 | 0 | 5 | **5** |
| tazminattan indirim halleri | 3 | 3 | 0 | 0 | 5 | **5** |
| kusursuz sorumluluk halleri | 3 | 3 | 0 | 0 | 5 | **5** |
| calisma ve dinlenme sureleri | 3 | 3 | 0 | 0 | 5 | **5** |
| buro edinme zorunlulugu | 3 | 3 | 1 | 0 | 5 | **4** |
| ucret hukumleri | 3 | 3 | 0 | 1 | 5 | **4** |
| odeme emrine itiraz | 3 | 3 | 1 | 2 | 5 | **2** |
| hukuka uygunluk sebepleri | 3 | 3 | 2 | 2 | 5 | **1** |
| kesin hukumsuzluk halleri | 2 | 2 | 0 | 0 | 3 | **3** |
| isyeri devri | 2 | 2 | 0 | 0 | 3 | **3** |
| ise iade arabuluculuk | 2 | 2 | 0 | 0 | 3 | **3** |
| sorumsuzluk anlasmalari | 2 | 2 | 0 | 0 | 3 | **3** |
| hukuka aykiriligi kaldiran haller | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet ve reklam yasagi | 2 | 2 | 0 | 0 | 3 | **3** |
| etik ilkeler tehditler | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari orf ve adet | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari faaliyet yasagi | 2 | 2 | 0 | 0 | 3 | **3** |
| ihtiyati hacze itiraz suresi (15 gun) | 2 | 2 | 0 | 0 | 3 | **3** |
| gecici is iliskisi | 2 | 2 | 0 | 0 | 3 | **3** |
| cek odeme kontrolu | 2 | 2 | 0 | 0 | 3 | **3** |
| sureli fesih kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| irade bozuklugu | 2 | 2 | 0 | 0 | 3 | **3** |
| uyarma cezasi halleri | 2 | 2 | 0 | 0 | 3 | **3** |
| kesin hukumsuzluk-iptal sebepleri ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ayirt etme gucunun gecici kaybi sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari faaliyet yasagi cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tehdit | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler kisisel cikar | 1 | 1 | 0 | 0 | 2 | **2** |
| defter belge teslimi | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri bildirgesi | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tesvik | 1 | 1 | 0 | 0 | 2 | **2** |
| engelli ve eski hukumlu calistirma | 1 | 1 | 0 | 0 | 2 | **2** |
| sosyal guvenlik ayligi | 1 | 1 | 0 | 0 | 2 | **2** |
| 4857 kapsam disi istisnalar | 1 | 1 | 0 | 0 | 2 | **2** |
| asiri yararlanma (gabin) | 1 | 1 | 0 | 0 | 2 | **2** |
| cek hukumleri | 1 | 1 | 0 | 0 | 2 | **2** |
| odeme emrine dava acma suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 167 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebe (ayristirilamadi) — 251 konu, 508 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| yonetim beyanlari | 3 | 3 | 0 | 0 | 5 | **5** |
| temel muhasebe kavramlari | 3 | 3 | 1 | 0 | 5 | **4** |
| bilanco hesaplari | 3 | 3 | 1 | 1 | 5 | **3** |
| stokta kalma suresi hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| uluslararasi muhasebe kuruluslari | 2 | 2 | 0 | 0 | 3 | **3** |
| standart oranlar | 2 | 2 | 0 | 0 | 3 | **3** |
| akreditif kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal oranlar | 2 | 2 | 0 | 0 | 3 | **3** |
| surekli dosya icerigi | 2 | 2 | 0 | 0 | 3 | **3** |
| ozkaynaklar hesaplama | 2 | 2 | 0 | 0 | 3 | **3** |
| analitik prosedur | 2 | 2 | 0 | 0 | 3 | **3** |
| dis teyit prosedurleri | 2 | 2 | 0 | 0 | 3 | **3** |
| duzenleyici hesaplar | 2 | 2 | 0 | 0 | 3 | **3** |
| bilanco sonrasi olaylar | 2 | 2 | 0 | 0 | 3 | **3** |
| bilanco toplami degisimi | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal tablo iddialari | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| piyasa degeri-defter degeri orani | 2 | 2 | 0 | 0 | 3 | **3** |
| iasb calismalari | 2 | 2 | 0 | 1 | 3 | **2** |
| ozkaynak hesaplari | 2 | 2 | 0 | 2 | 3 | **1** |
| borc senedi yenileme | 2 | 2 | 0 | 2 | 3 | **1** |
| kademeli dagitim gug toplami | 1 | 1 | 0 | 0 | 2 | **2** |
| raporlama standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| geri kazanilabilir tutar | 1 | 1 | 0 | 0 | 2 | **2** |
| nakit esasi ve donemsellik kavrami | 1 | 1 | 0 | 0 | 2 | **2** |
| demirbas alimi karisik odeme kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| yenileme fonu kullanimdan vazgecme | 1 | 1 | 0 | 0 | 2 | **2** |
| anomali tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| duzenleyici hesaplarin tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ara donem raporlama | 1 | 1 | 0 | 0 | 2 | **2** |
| ihtiyatlilik kavrami (yedek akce) | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz degerleme | 1 | 1 | 0 | 0 | 2 | **2** |
| alacaklara ait uygunluk testleri | 1 | 1 | 0 | 0 | 2 | **2** |
| baslangic analitik prosedur amaclari | 1 | 1 | 0 | 0 | 2 | **2** |
| sorgulama tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| kismi kredili satis kayitlari | 1 | 1 | 0 | 0 | 2 | **2** |
| cift amacli test | 1 | 1 | 0 | 0 | 2 | **2** |
| planlama asamasinda ele alinan konular | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi standart kuruluslari | 1 | 1 | 0 | 0 | 2 | **2** |
| aktif duzenleyici hesaplar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 211 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye (ayristirilamadi) — 46 konu, 91 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| wagner yasasi | 2 | 2 | 0 | 0 | 3 | **3** |
| operasyonel acik | 2 | 2 | 0 | 2 | 3 | **1** |
| mali yanilsama modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| leviathan modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tanzi etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc itfa yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| operasyonel acik hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu giderleri siniflandirma | 1 | 1 | 0 | 0 | 2 | **2** |
| egemenlik gucune dayanan gelirler | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer harcamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| formul esnekligi yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc senedi ihrac turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| merkantalizm | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu mallari samuelson modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| mali somuru | 1 | 1 | 0 | 0 | 2 | **2** |
| devlet gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| disliyici etki | 1 | 1 | 0 | 0 | 2 | **2** |
| lorenz egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari harcamalar | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer harcamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| uygunluk ilkesi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc yonetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc servis orani | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm acik ekonomi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu yatirim harcamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| kamusal tercih yaklasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| genel yonetim kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| peacock-wiseman sicrama hipotezi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali yerellesme | 1 | 1 | 0 | 0 | 2 | **2** |
| capraz yansima | 1 | 1 | 0 | 0 | 2 | **2** |
| resesyon tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel butceli idareler | 1 | 1 | 0 | 0 | 2 | **2** |
| dalton-atkinson olcutu | 1 | 1 | 0 | 0 | 2 | **2** |
| butcenin ekonomik-mali islevi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu finansmani nakit islemleri siniri (4749) | 1 | 1 | 0 | 0 | 2 | **2** |
| devlet tahvili ihraci | 1 | 1 | 0 | 0 | 2 | **2** |
| 5018 sayili kanun mali yonetim araclari | 1 | 1 | 0 | 0 | 2 | **2** |
| peacock-wiseman teorisi | 1 | 1 | 0 | 0 | 2 | **2** |
| mundell-fleming esnek kur genisletici maliye | 1 | 1 | 0 | 0 | 2 | **2** |
| kalkinma carileri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 6 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

## 4 · BEKLEYEN HAT — simdilik basilmayacak

Cem karari (11.09): bu dersler **sonraya**. 568 konu · 1.439 soru · 9.440 TL.

| Ders | Acik konu | Acik soru |
|---|---:|---:|
| Genel Kultur-Genel Yetenek (ayristirilamadi) | 166 | 362 |
| Matematik-Istatistik (ayristirilamadi) | 124 | 293 |
| Yabanci Dil | 65 | 216 |
| Turkce | 74 | 210 |
| Yabanci Dil (ayristirilamadi) | 69 | 170 |
| Matematik | 56 | 147 |
| Ataturk Ilke ve Inkilap Tarihi | 14 | 41 |

En cok cikan bekleyen konular (hat acildiginda ilk bunlar basilir):

| Ders | Konu | Cikmis | Bizde | BASILACAK |
|---|---|---:|---:|---:|
| Yabanci Dil | cumle tamamlama | 51 | 5 | 7 |
| Turkce | yazim kurallari | 17 | 3 | 9 |
| Turkce | noktalama isaretleri | 16 | 3 | 9 |
| Turkce | anlatim bozuklugu | 15 | 4 | 8 |
| Yabanci Dil | kelime bilgisi | 14 | 1 | 11 |
| Matematik | denklem cozme | 9 | 2 | 10 |
| Yabanci Dil (ayristirilamadi) | sentence completion | 9 | 4 | 8 |
| Turkce | ses olaylari | 8 | 0 | 12 |
| Genel Kultur-Genel Yetenek (ayristirilamadi) | sozcukte anlam | 8 | 3 | 9 |
| Yabanci Dil (ayristirilamadi) | kelime tamamlama | 7 | 0 | 11 |
| Matematik-Istatistik (ayristirilamadi) | yas problemi | 7 | 0 | 11 |
| Yabanci Dil | cumle tamamlama-kosul | 7 | 1 | 10 |
| Yabanci Dil | edat kullanimi | 6 | 2 | 7 |
| Ataturk Ilke ve Inkilap Tarihi | lozan antlasmasi | 6 | 0 | 9 |
| Matematik-Istatistik (ayristirilamadi) | seri toplami | 6 | 0 | 9 |

