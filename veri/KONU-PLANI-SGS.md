# KONU PLANI — STAJA BASLAMA (SGS)

> Uretim: **11.09.2026 16:42** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.238 konu** var. Bunlarin **2.818**'inde elimizde soru YETERSIZ; toplam **6.597 soru** basilacak. Su an bu konularda **1.748** saglam sorumuz var.

## 0b · BEDEL ve ONCELIK

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 10 | 89 | 1.168 TL | 584 TL |
| 2 · kritik | cikmis >= 5 | 75 | 595 | 7.806 TL | 3.903 TL |
| 3 · onemli | cikmis >= 3 | 253 | 1.368 | 17.948 TL | 8.974 TL |
| 4 · orta | cikmis >= 2 | 527 | 2.105 | 27.618 TL | 13.809 TL |
| 5 · tamami | cikmis >= 1 | 2.818 | 6.597 | 86.553 TL | 43.276 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 461 | 312 | 1.220 | **946** | 393 |
| Denetim | 16 | 96 | 204 | 266 | **129** | 45 |
| Yabanci Dil | 10 | 38 | 45 | 155 | **113** | 32 |
| Maliyet Muhasebesi | 8 | 172 | 130 | 445 | **342** | 137 |
| Mali Tablolar Analizi | 8 | 83 | 62 | 246 | **196** | 67 |
| Matematik | 8 | 22 | 22 | 83 | **62** | 19 |
| Turkce | 7 | 58 | 56 | 205 | **157** | 51 |
| Ekonomi | 6 | 31 | 22 | 78 | **58** | 25 |
| Ticaret Hukuku | 6 | 50 | 96 | 151 | **79** | 31 |
| Maliye | 6 | 39 | 49 | 94 | **61** | 29 |
| Vergi Hukuku | 6 | 40 | 55 | 99 | **66** | 27 |
| Is ve Sosyal Guvenlik Hukuku | 6 | 39 | 41 | 121 | **81** | 30 |
| Borclar Hukuku | 6 | 35 | 78 | 113 | **51** | 13 |
| Meslek Hukuku | 6 | 19 | 16 | 82 | **66** | 18 |
| Hukuk (ayristirilmamis) | — | 583 | 125 | 1.315 | **1.221** | 551 |
| Maliye (ayristirilmamis) | — | 129 | 36 | 276 | **250** | 120 |
| Genel Kultur-Genel Yetenek (ayristirilmamis) | — | 206 | 43 | 458 | **424** | 194 |
| Matematik-Istatistik (ayristirilmamis) | — | 172 | 46 | 418 | **375** | 160 |
| Ekonomi (ayristirilmamis) | — | 153 | 45 | 326 | **289** | 140 |
| Ataturk Ilke ve Inkilap Tarihi | — | 19 | 13 | 53 | **41** | 14 |
| Muhasebe (ayristirilmamis) | — | 677 | 199 | 1.477 | **1.320** | 621 |
| Yabanci Dil (ayristirilmamis) | — | 116 | 53 | 314 | **270** | 101 |
| **TOPLAM** | **130** | **3.238** | **1.748** | | **6.597** | **2.818** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 393 konu, 946 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| muhasebe bilgi sistemi | 10 | 10 | 2 | 1 | 12 | **9** |
| nakit akis tablosu | 8 | 7 | 3 | 0 | 12 | **9** |
| tms 40 yatirim amacli gayrimenkul | 8 | 8 | 1 | 3 | 12 | **8** |
| hisse senedi satisi | 7 | 7 | 0 | 0 | 11 | **11** |
| sermaye artirimi | 7 | 7 | 0 | 1 | 11 | **10** |
| gider tahakkuku | 7 | 7 | 2 | 0 | 11 | **9** |
| tms 36 deger dusuklugu | 7 | 7 | 2 | 1 | 11 | **8** |
| tms 37 karsiliklar | 7 | 7 | 3 | 0 | 11 | **8** |
| tms 38 maddi olmayan duran varlik | 6 | 6 | 1 | 0 | 9 | **8** |
| gelir tahakkuku | 5 | 5 | 1 | 0 | 8 | **7** |
| tms 2 stoklar | 5 | 5 | 2 | 0 | 8 | **6** |
| donemsellik kavrami | 5 | 5 | 1 | 1 | 8 | **6** |
| ozkaynak hesaplama | 5 | 5 | 1 | 2 | 8 | **5** |
| tms 12 ertelenmis vergi | 5 | 5 | 0 | 4 | 8 | **4** |
| kar dagitimi kaydi | 5 | 5 | 2 | 2 | 8 | **4** |
| yasal yedek akce | 4 | 4 | 0 | 0 | 6 | **6** |
| kasa sayim farki | 4 | 4 | 0 | 0 | 6 | **6** |
| gelecek aylara ait giderler | 4 | 4 | 0 | 0 | 6 | **6** |
| stok deger dusuklugu | 4 | 4 | 0 | 1 | 6 | **5** |
| tutarlilik kavrami | 4 | 4 | 0 | 2 | 6 | **4** |
| amortisman ayirma | 4 | 4 | 2 | 0 | 6 | **4** |
| supheli alacak karsiligi | 4 | 4 | 2 | 0 | 6 | **4** |
| kollektif sirket kar dagitimi | 4 | 4 | 2 | 1 | 6 | **3** |
| tms 7 nakit akis tablosu | 4 | 4 | 1 | 2 | 6 | **3** |
| duran varlik satisi | 4 | 4 | 4 | 0 | 6 | **2** |
| tms 28 istirakler | 4 | 4 | 4 | 0 | 6 | **2** |
| donem kari hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| gelecek yillara ait giderler | 3 | 3 | 0 | 0 | 5 | **5** |
| depozitolu kap kirilmasi kaydi | 3 | 3 | 0 | 0 | 5 | **5** |
| maddi duran varlik denetimi | 3 | 3 | 0 | 0 | 5 | **5** |
| tahvil ihraci | 3 | 3 | 0 | 0 | 5 | **5** |
| tms 21 kur cevrimi | 3 | 3 | 0 | 0 | 5 | **5** |
| onemlilik kavrami | 3 | 3 | 0 | 0 | 5 | **5** |
| azalan bakiyeler amortisman | 3 | 3 | 0 | 0 | 5 | **5** |
| fifo yontemi | 3 | 3 | 0 | 0 | 5 | **5** |
| donem kari zarari hesabi | 3 | 3 | 0 | 0 | 5 | **5** |
| kesin mizan | 3 | 3 | 0 | 0 | 5 | **5** |
| tms-38 maddi olmayan duran varliklar | 3 | 3 | 0 | 0 | 5 | **5** |
| sermaye taahhudu iptali | 3 | 3 | 0 | 0 | 5 | **5** |
| kar dagitimi | 3 | 3 | 0 | 0 | 5 | **5** |
| _… 353 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Denetim — 45 konu, 129 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim kaniti yeterliligi | 11 | 9 | 2 | 3 | 12 | **7** |
| denetim kaniti guvenilirligi | 8 | 7 | 0 | 0 | 12 | **12** |
| kasa denetimi | 5 | 5 | 0 | 0 | 8 | **8** |
| analitik prosedurler | 5 | 5 | 3 | 1 | 8 | **4** |
| denetim calisma kagitlari | 5 | 5 | 2 | 3 | 8 | **3** |
| denetim gorusu | 4 | 4 | 0 | 0 | 6 | **6** |
| calisma kagitlari | 4 | 4 | 2 | 1 | 6 | **3** |
| dikkat cekilen hususlar paragrafi | 3 | 3 | 0 | 0 | 5 | **5** |
| yapisal risk faktorleri | 3 | 3 | 0 | 2 | 5 | **3** |
| kanit guvenilirligi | 3 | 3 | 0 | 3 | 5 | **2** |
| kilit denetim konulari | 3 | 3 | 3 | 0 | 5 | **2** |
| risk degerlendirme prosedurleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetci raporu bolumleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim teknikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kaniti uygunlugu | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim sozlesmesi icerigi | 2 | 2 | 0 | 0 | 3 | **3** |
| menkul kiymet denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| ic kontrol bilesenleri | 2 | 2 | 0 | 0 | 3 | **3** |
| genel kabul gormus denetim standartlari | 2 | 2 | 1 | 0 | 3 | **2** |
| onemlilik kavrami denetim | 2 | 2 | 0 | 1 | 3 | **2** |
| performans onemliligi | 1 | 1 | 0 | 0 | 2 | **2** |
| kanit guvenilirligi kaynak unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| hile onleme sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim guvence sinirlamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| stok denetim prosedurleri | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 700 gorus olusturma | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 700 gorusun dayanagi bolumu | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 550 iliskili taraflar prosedurleri | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim raporu | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 550 iliskili taraf riski | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim | 1 | 1 | 0 | 0 | 2 | **2** |
| ifac yapisi | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim kanit turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim raporu unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim kanit toplama yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| iliskili taraf islemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim kanit yeterliligi | 1 | 1 | 0 | 0 | 2 | **2** |
| beta riski (yanlis kabul) | 1 | 1 | 0 | 0 | 2 | **2** |
| ic kontrol sistemi amaclari | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 5 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Yabanci Dil — 32 konu, 113 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| cumle tamamlama | 51 | 18 | 0 | 5 | 12 | **7** |
| baglac kullanimi | 6 | 6 | 0 | 0 | 9 | **9** |
| edat kullanimi | 6 | 6 | 0 | 2 | 9 | **7** |
| karsilastirma yapilari | 5 | 5 | 0 | 0 | 8 | **8** |
| baglac secimi | 5 | 5 | 0 | 0 | 8 | **8** |
| passive voice | 5 | 5 | 0 | 3 | 8 | **5** |
| present perfect tense | 5 | 5 | 0 | 4 | 8 | **4** |
| ilgi zamiri | 4 | 4 | 0 | 0 | 6 | **6** |
| relative clause | 4 | 4 | 0 | 4 | 6 | **2** |
| modal fiil | 3 | 3 | 0 | 0 | 5 | **5** |
| zarf kullanimi | 3 | 3 | 0 | 0 | 5 | **5** |
| fiil secimi | 3 | 3 | 0 | 0 | 5 | **5** |
| ilgi zamiri (which) | 3 | 3 | 0 | 0 | 5 | **5** |
| ilgi zamiri whose | 3 | 3 | 0 | 3 | 5 | **2** |
| phrasal verb | 2 | 2 | 0 | 0 | 3 | **3** |
| cumle tamamlama (baglac) | 2 | 2 | 0 | 0 | 3 | **3** |
| fiil zamani | 2 | 2 | 0 | 0 | 3 | **3** |
| cumle tamamlama (although) | 2 | 2 | 0 | 1 | 3 | **2** |
| zarf secimi | 2 | 2 | 0 | 2 | 3 | **1** |
| karsilastirma sifatlari | 1 | 1 | 0 | 0 | 2 | **2** |
| zaman secimi (past simple) | 1 | 1 | 0 | 0 | 2 | **2** |
| used to yapisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kelime secimi (fiil) | 1 | 1 | 0 | 0 | 2 | **2** |
| ilgi zamiri (where) | 1 | 1 | 0 | 0 | 2 | **2** |
| bosluk doldurma-baglac | 1 | 1 | 0 | 0 | 2 | **2** |
| zaman (tense) kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| fiil zamani (past tense) | 1 | 1 | 0 | 0 | 2 | **2** |
| modal fiiller | 1 | 1 | 0 | 0 | 2 | **2** |
| present perfect continuous | 1 | 1 | 0 | 0 | 2 | **2** |
| relative clause-where | 1 | 1 | 0 | 1 | 2 | **1** |
| kelime bilgisi (sifat secimi) | 1 | 1 | 0 | 1 | 2 | **1** |
| preposition kullanimi | 1 | 1 | 0 | 1 | 2 | **1** |

### Maliyet Muhasebesi — 137 konu, 342 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ortak maliyet dagitimi | 13 | 13 | 0 | 3 | 12 | **9** |
| siparis maliyet sistemi | 7 | 7 | 2 | 1 | 11 | **8** |
| genel uretim gideri dagitimi | 7 | 7 | 2 | 1 | 11 | **8** |
| normal maliyet yontemi | 7 | 7 | 1 | 2 | 11 | **8** |
| evre maliyet sistemi | 5 | 5 | 0 | 0 | 8 | **8** |
| satilan mamul maliyeti | 5 | 5 | 1 | 2 | 8 | **5** |
| kademeli dagitim yontemi | 4 | 4 | 0 | 0 | 6 | **6** |
| birlesik maliyet dagitimi | 3 | 3 | 0 | 0 | 5 | **5** |
| standart maliyet sapmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| uretim maliyeti hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| ekonomik siparis miktari | 3 | 3 | 0 | 0 | 5 | **5** |
| yari mamul maliyeti | 3 | 3 | 0 | 0 | 5 | **5** |
| standart maliyet farklari | 3 | 3 | 0 | 0 | 5 | **5** |
| ortak urun maliyet dagitimi | 3 | 3 | 1 | 2 | 5 | **2** |
| genel uretim gideri yukleme | 3 | 3 | 2 | 1 | 5 | **2** |
| birlesik maliyet satis degeri yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| ozel maliyet amortismani | 2 | 2 | 0 | 0 | 3 | **3** |
| direkt ilk madde geriye dogru hesap | 2 | 2 | 0 | 0 | 3 | **3** |
| ozel maliyet tahliye kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| degisken-normal maliyet birim farki | 2 | 2 | 0 | 0 | 3 | **3** |
| gug birim pay hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| fifo esdeger birim (dimm) | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet yontemleri karsilastirma | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger birim hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| borclanma maliyetleri tms23 | 2 | 1 | 0 | 0 | 3 | **3** |
| standart maliyet sapma analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| birim uretim maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| birlesik maliyet uretim miktari yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| ardisik donem satilan mamul maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| standart maliyet sistemi | 2 | 2 | 1 | 1 | 3 | **1** |
| siparis avansi mahsubu | 2 | 2 | 1 | 1 | 3 | **1** |
| sekillendirme (donusturme) maliyeti birim hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| esdeger birim hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| normal-tam maliyet birim farki | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ve degisken maliyet sistemi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyet duran varlik | 1 | 1 | 0 | 0 | 2 | **2** |
| direkt ilk madde tuketimi hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| ortalama maliyet esdeger birim | 1 | 1 | 0 | 0 | 2 | **2** |
| satilan mamul maliyeti tablosu | 1 | 1 | 0 | 0 | 2 | **2** |
| normal maliyet birim uretim maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 97 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Mali Tablolar Analizi — 67 konu, 196 soru basilacak

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
| finansal oran analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| dikey yuzdelerden oz kaynak-aktif | 2 | 2 | 0 | 0 | 3 | **3** |
| kapasite artirici harcama amortismani | 2 | 2 | 0 | 0 | 3 | **3** |
| dikey yuzdelerden bilanco yorumu | 2 | 2 | 0 | 0 | 3 | **3** |
| karsilastirmali tablolar analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| yatay analiz degisim yuzdesi | 2 | 2 | 0 | 0 | 3 | **3** |
| basit (dogrudan) dagitim yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| alacak devir hizi | 2 | 2 | 0 | 0 | 3 | **3** |
| likidite orani | 2 | 2 | 0 | 0 | 3 | **3** |
| yuzde degisim analizi | 2 | 2 | 0 | 2 | 3 | **1** |
| cari orani artiran islemler | 1 | 1 | 0 | 0 | 2 | **2** |
| surekli sermaye orani dikey yuzdelerle | 1 | 1 | 0 | 0 | 2 | **2** |
| oran analizi karsilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| hazir degerler analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzde ve duran varlik oraniyla donen varlik | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran borc ozsermaye | 1 | 1 | 0 | 0 | 2 | **2** |
| olagan kar analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak degisimi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey analiz payda kalemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| mali tablo analiz teknikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran-asit test hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzde faaliyet kari | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran asit test orani | 1 | 1 | 0 | 0 | 2 | **2** |
| kredili tasit alimi kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac orani hesabi (borc-ozsermaye) | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzdelerden net satis hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| islem etkisi cari oran (1'in altinda) | 1 | 1 | 0 | 0 | 2 | **2** |
| brut kar marji | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzdeler analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 27 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Matematik — 19 konu, 62 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denklem cozme | 9 | 7 | 0 | 2 | 12 | **10** |
| belirli integral | 6 | 6 | 0 | 1 | 9 | **8** |
| uslu sayilar | 5 | 5 | 0 | 0 | 8 | **8** |
| limit hesaplama | 5 | 5 | 0 | 3 | 8 | **5** |
| oran oranti | 4 | 4 | 0 | 3 | 6 | **3** |
| turev hesaplama | 2 | 2 | 0 | 0 | 3 | **3** |
| turev | 2 | 2 | 0 | 0 | 3 | **3** |
| aritmetik dizi toplami | 2 | 2 | 0 | 0 | 3 | **3** |
| bolunebilme kurallari (15) | 1 | 1 | 0 | 0 | 2 | **2** |
| limit ve sureklilik | 1 | 1 | 0 | 0 | 2 | **2** |
| zincir kurali turev | 1 | 1 | 0 | 0 | 2 | **2** |
| oran hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| logaritma | 1 | 1 | 0 | 0 | 2 | **2** |
| kesir islemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| yuzde hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| birinci derece kesirli denklem | 1 | 1 | 0 | 0 | 2 | **2** |
| sabit fonksiyon | 1 | 1 | 0 | 1 | 2 | **1** |
| tek cift sayi ozellikleri | 1 | 1 | 0 | 1 | 2 | **1** |
| oran oranti denklem sistemi | 1 | 1 | 0 | 1 | 2 | **1** |

### Turkce — 51 konu, 157 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| yazim kurallari | 17 | 16 | 0 | 3 | 12 | **9** |
| noktalama isaretleri | 16 | 15 | 0 | 3 | 12 | **9** |
| anlatim bozuklugu | 15 | 15 | 0 | 4 | 12 | **8** |
| ses olaylari | 8 | 8 | 0 | 0 | 12 | **12** |
| paragraf anlama | 5 | 5 | 0 | 2 | 8 | **6** |
| dusunceyi gelistirme yollari | 5 | 5 | 0 | 3 | 8 | **5** |
| buyuk harf yazimi | 4 | 4 | 0 | 0 | 6 | **6** |
| cumle ogeleri | 4 | 4 | 0 | 2 | 6 | **4** |
| sozcuk turleri | 4 | 4 | 0 | 3 | 6 | **3** |
| ikileme | 3 | 3 | 0 | 0 | 5 | **5** |
| unlu degisimi | 3 | 3 | 0 | 0 | 5 | **5** |
| sozcuk anlami | 3 | 3 | 0 | 0 | 5 | **5** |
| paragraf tamamlama | 3 | 3 | 0 | 2 | 5 | **3** |
| i. dunya savasi | 3 | 3 | 0 | 3 | 5 | **2** |
| paragraf yorumlama | 3 | 3 | 0 | 3 | 5 | **2** |
| kesme isareti | 2 | 2 | 0 | 0 | 3 | **3** |
| kesme isareti kullanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| paragraf anlam butunlugu | 2 | 2 | 0 | 0 | 3 | **3** |
| neden-sonuc iliskisi | 2 | 2 | 0 | 0 | 3 | **3** |
| deyim anlami | 2 | 2 | 0 | 0 | 3 | **3** |
| dusuncenin akisini bozan cumle | 2 | 2 | 0 | 0 | 3 | **3** |
| mecaz anlam | 2 | 2 | 0 | 1 | 3 | **2** |
| kisa cizgi kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| yuklem turu | 1 | 1 | 0 | 0 | 2 | **2** |
| terim anlami | 1 | 1 | 0 | 0 | 2 | **2** |
| anlatim teknikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| noktali virgul kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| virgul kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| gereksiz sozcuk kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| cok anlamlilik | 1 | 1 | 0 | 0 | 2 | **2** |
| bitisik yazim | 1 | 1 | 0 | 0 | 2 | **2** |
| paragrafta ana dusunce | 1 | 1 | 0 | 0 | 2 | **2** |
| virgulun dogru kullanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| unlu daralmasi kurali | 1 | 1 | 0 | 0 | 2 | **2** |
| nesnel yargi | 1 | 1 | 0 | 0 | 2 | **2** |
| anlatim bozuklugu (sozcuk secimi) | 1 | 1 | 0 | 0 | 2 | **2** |
| ek ve baglac yazimi (de/ki) | 1 | 1 | 0 | 0 | 2 | **2** |
| amac-sonuc iliskisi | 1 | 1 | 0 | 0 | 2 | **2** |
| ki baglaci yazimi | 1 | 1 | 0 | 0 | 2 | **2** |
| gercek anlam | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 11 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi — 25 konu, 58 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| is-lm para politikasi etkinligi | 4 | 4 | 0 | 0 | 6 | **6** |
| talep esnekligi | 4 | 4 | 0 | 2 | 6 | **4** |
| para politikasi araclari | 3 | 3 | 0 | 0 | 5 | **5** |
| stolper-samuelson teoremi | 2 | 2 | 0 | 0 | 3 | **3** |
| cari islemler hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| mukayeseli ustunluk firsat maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| j egrisi | 2 | 2 | 0 | 2 | 3 | **1** |
| j egrisi devaluasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda maksimizasyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| marjinal tuketim egilimi | 1 | 1 | 0 | 0 | 2 | **2** |
| gsyih kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet uretim durdurma | 1 | 1 | 0 | 0 | 2 | **2** |
| tasarruf paradoksu | 1 | 1 | 0 | 0 | 2 | **2** |
| phillips egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci rekabet dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal issizlik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| gsyh harcama yaklasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| stackelberg modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| talep fiyat esnekligi (inelastik) | 1 | 1 | 0 | 0 | 2 | **2** |
| ucuncu derece fiyat farklilastirmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| para arzi-acik piyasa islemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm para politikasi carpani | 1 | 1 | 0 | 1 | 2 | **1** |
| tufe gsyh deflator farki | 1 | 1 | 0 | 1 | 2 | **1** |
| dezenflasyon kavrami | 1 | 1 | 0 | 1 | 2 | **1** |

### Ticaret Hukuku — 31 konu, 79 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| genel islem kosullari | 9 | 9 | 3 | 1 | 12 | **8** |
| cek zorunlu unsurlari | 5 | 5 | 0 | 3 | 8 | **5** |
| ticaret unvani | 5 | 5 | 3 | 1 | 8 | **4** |
| ticari temsilci yetkisi | 4 | 4 | 0 | 0 | 6 | **6** |
| kiymetli evrak ciro | 4 | 4 | 3 | 0 | 6 | **3** |
| tacir sifati | 4 | 4 | 1 | 3 | 6 | **2** |
| tacir olmanin sonuclari | 3 | 3 | 0 | 0 | 5 | **5** |
| kiymetli evrak cek | 3 | 3 | 0 | 2 | 5 | **3** |
| haksiz rekabet davalari | 3 | 3 | 1 | 3 | 5 | **1** |
| temsil yetkisinin sona ermesi | 2 | 2 | 0 | 0 | 3 | **3** |
| cek uzerindeki kayitlar | 2 | 2 | 0 | 2 | 3 | **1** |
| limited sirket ozellikleri | 2 | 2 | 2 | 0 | 3 | **1** |
| bedelsiz pay sermaye artirimi | 1 | 1 | 0 | 0 | 2 | **2** |
| temsil yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket kurulusu | 1 | 1 | 0 | 0 | 2 | **2** |
| beyaz ciro | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret unvani ve isletme adi | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket ortak sayisi (1-50) | 1 | 1 | 0 | 0 | 2 | **2** |
| kambiyo senetleri devir kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet | 1 | 1 | 0 | 0 | 2 | **2** |
| karsiliksiz cek yaptirimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ayni sermaye kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet tazminat | 1 | 1 | 0 | 0 | 2 | **2** |
| cek devri | 1 | 1 | 0 | 0 | 2 | **2** |
| tacir esnaf hukumleri | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasimini kesen sebepler | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet meslek hukuku | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket sermaye odeme | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari temsilcilik yetkisi | 1 | 1 | 0 | 1 | 2 | **1** |

### Maliye — 29 konu, 61 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| butce siniflandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| vergi kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| artan oranli vergi | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu gelirleri turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| otomatik istikrarlandiricilar | 2 | 2 | 0 | 1 | 3 | **2** |
| parafiskal gelirler | 2 | 2 | 0 | 2 | 3 | **1** |
| parafiskal gelir | 2 | 2 | 0 | 2 | 3 | **1** |
| vergi oranlilik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin karar etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi harcamasi hesaplama yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu geliri turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| dolayli vergi kaldirilmasinin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| duzenleyici denetleyici kurumlar | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| yari kamusal mallar | 1 | 1 | 0 | 0 | 2 | **2** |
| gelir vergisi dilim tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliye politikasi araclari | 1 | 1 | 0 | 0 | 2 | **2** |
| merkezi yonetim butcesi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce ilkeleri (gayrisafilik) | 1 | 1 | 0 | 0 | 2 | **2** |
| borc konsolidasyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| spesifik-advalorem vergi ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali surukleme | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi entegrasyon yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi gayreti | 1 | 1 | 0 | 0 | 2 | **2** |
| ricardocu denklik teoremi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi takozu | 1 | 1 | 0 | 0 | 2 | **2** |

### Vergi Hukuku — 27 konu, 66 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| kdv vergiyi doguran olay | 4 | 4 | 1 | 0 | 6 | **5** |
| vuk degerleme olculeri | 3 | 3 | 0 | 0 | 5 | **5** |
| ozel tuketim vergisi | 3 | 3 | 0 | 0 | 5 | **5** |
| kurumlar vergisi mukellefleri | 3 | 3 | 0 | 1 | 5 | **4** |
| kdv istisnalari | 3 | 3 | 0 | 3 | 5 | **2** |
| asgari kurumlar vergisi | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi mukellefi | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv indirim hakki | 1 | 1 | 0 | 0 | 2 | **2** |
| degersiz alacak | 1 | 1 | 0 | 0 | 2 | **2** |
| tarh zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi incelemesi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| gelir vergisi kazanc turu | 1 | 1 | 0 | 0 | 2 | **2** |
| dar mukellefiyet vergilendirme | 1 | 1 | 0 | 0 | 2 | **2** |
| emlak vergisi vergi degeri | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv belgesiz mal | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi ziyai cezasi orani (%50) | 1 | 1 | 0 | 0 | 2 | **2** |
| emlak vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kurumlar vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi cifte vergilendirme | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset intikal vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| istisna ve muafiyet ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| amortisman uygulamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi usul bilgi paylasim bedeli | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv teslim sayilan haller | 1 | 1 | 0 | 0 | 2 | **2** |
| defter belge saklama yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| kurumlar vergisi istisnasi | 1 | 1 | 0 | 0 | 2 | **2** |
| amme alacagi teminat paraya cevirme | 1 | 1 | 0 | 1 | 2 | **1** |

### Is ve Sosyal Guvenlik Hukuku — 30 konu, 81 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| toplu is sozlesmesi | 6 | 6 | 1 | 1 | 9 | **7** |
| sendika uyeligi | 6 | 6 | 2 | 1 | 9 | **6** |
| is sozlesmesi turleri | 5 | 5 | 1 | 2 | 8 | **5** |
| yillik ucretli izin | 4 | 4 | 0 | 0 | 6 | **6** |
| isveren vekili | 3 | 3 | 0 | 0 | 5 | **5** |
| isci ucretleri | 3 | 3 | 0 | 0 | 5 | **5** |
| sureli fesih | 3 | 3 | 0 | 0 | 5 | **5** |
| İs kanunu kapsami | 3 | 3 | 0 | 2 | 5 | **3** |
| grev lokavt | 2 | 2 | 0 | 0 | 3 | **3** |
| isletme toplu is sozlesmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| kisa uzun vadeli sigorta kollari | 2 | 2 | 0 | 0 | 3 | **3** |
| kismi sureli is sozlesmesi | 2 | 2 | 0 | 2 | 3 | **1** |
| belirli sureli is sozlesmesi | 2 | 2 | 1 | 1 | 3 | **1** |
| isyeri tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| grev lokavt erteleme | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret kurallari (odeme suresi) | 1 | 1 | 0 | 0 | 2 | **2** |
| kolaylastirilmis emeklilik | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika kanunu tanimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma sureleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sendikalar kanunu tanimlar | 1 | 1 | 0 | 0 | 2 | **2** |
| kisa vadeli sigorta kollari | 1 | 1 | 0 | 0 | 2 | **2** |
| belirli belirsiz sureli is sozlesmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| sendikalar kanunu tanimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| ucretin odenmemesi hakli fesih | 1 | 1 | 0 | 1 | 2 | **1** |
| is kazasi surekli is goremezlik | 1 | 1 | 0 | 1 | 2 | **1** |
| olum ayligi kesilmesi | 1 | 1 | 0 | 1 | 2 | **1** |
| is kazasi isveren sorumlulugu | 1 | 1 | 0 | 1 | 2 | **1** |
| tesmil karari | 1 | 1 | 0 | 1 | 2 | **1** |
| sendika uyeligi kazanilmasi | 1 | 1 | 0 | 1 | 2 | **1** |

### Borclar Hukuku — 13 konu, 51 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sebepsiz zenginlesme | 8 | 8 | 2 | 1 | 12 | **9** |
| sozlesme sekli | 5 | 5 | 0 | 0 | 8 | **8** |
| borcun ifa yeri | 4 | 4 | 1 | 2 | 6 | **3** |
| haksiz fiil zamanasimi | 4 | 4 | 2 | 1 | 6 | **3** |
| takas | 3 | 3 | 0 | 0 | 5 | **5** |
| ucret sozlesmesi | 3 | 3 | 0 | 0 | 5 | **5** |
| zamanasimi suresi | 3 | 3 | 1 | 1 | 5 | **3** |
| hizmet borclanmasi | 3 | 3 | 1 | 1 | 5 | **3** |
| borclarin ifasi | 3 | 3 | 0 | 3 | 5 | **2** |
| manevi tazminat | 2 | 2 | 0 | 0 | 3 | **3** |
| muteselsil sorumluluk | 2 | 2 | 0 | 0 | 3 | **3** |
| zamanasiminin kesilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ifa yeri | 1 | 1 | 0 | 0 | 2 | **2** |

### Meslek Hukuku — 18 konu, 66 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| disiplin cezalari | 11 | 11 | 2 | 0 | 12 | **10** |
| meslek etik ilkeleri | 9 | 9 | 0 | 0 | 12 | **12** |
| haksiz rekabet reklam yasagi | 7 | 7 | 2 | 0 | 11 | **9** |
| meslek mensubu ucret esaslari | 3 | 3 | 0 | 0 | 5 | **5** |
| reklam yasagi | 3 | 3 | 0 | 0 | 5 | **5** |
| sir saklama yukumlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| serbest meslek kazanci | 3 | 3 | 3 | 0 | 5 | **2** |
| meslekle bagdasmayan isler | 2 | 2 | 1 | 0 | 3 | **2** |
| ucret tarifesi | 2 | 2 | 1 | 0 | 3 | **2** |
| meslek hukuku disiplin cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tabela asilmasi kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| turmob meslek odasi gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu olma sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu etik sosyal sorumluluk | 1 | 1 | 1 | 0 | 2 | **1** |
| ruhsat iptali-meslek hukuku | 1 | 1 | 1 | 0 | 2 | **1** |
| yeminli mali musavirlik sinavi | 1 | 1 | 1 | 0 | 2 | **1** |
| disiplin cezasi kinama | 1 | 1 | 1 | 0 | 2 | **1** |

### Hukuk (ayristirilmamis) — 551 konu, 1221 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| damga vergisi | 5 | 5 | 0 | 0 | 8 | **8** |
| is sozlesmesi feshi | 4 | 4 | 0 | 0 | 6 | **6** |
| alacagin devri | 4 | 4 | 0 | 0 | 6 | **6** |
| bono zorunlu unsurlari | 4 | 4 | 0 | 0 | 6 | **6** |
| sozlesmenin kurulmasi | 4 | 4 | 0 | 0 | 6 | **6** |
| calisma suresi | 3 | 3 | 0 | 0 | 5 | **5** |
| ucret yonetmeligi kurallari | 3 | 3 | 0 | 0 | 5 | **5** |
| zamanasimi | 3 | 3 | 0 | 0 | 5 | **5** |
| mesleki etik ilkeler | 3 | 3 | 0 | 0 | 5 | **5** |
| tazminattan indirim halleri | 3 | 3 | 0 | 0 | 5 | **5** |
| transfer fiyatlandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| kdv matrahi | 3 | 3 | 0 | 0 | 5 | **5** |
| is guvencesi | 3 | 3 | 0 | 0 | 5 | **5** |
| ticari is kavrami | 3 | 3 | 0 | 0 | 5 | **5** |
| haksiz fiil unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| calisma ve dinlenme sureleri | 3 | 3 | 0 | 0 | 5 | **5** |
| borclu temerrudu | 3 | 3 | 0 | 0 | 5 | **5** |
| haksiz fiil | 3 | 3 | 0 | 0 | 5 | **5** |
| is kazasi sayilmayan haller | 3 | 3 | 0 | 0 | 5 | **5** |
| cek hukuku | 3 | 3 | 0 | 0 | 5 | **5** |
| kidem tazminati | 3 | 3 | 0 | 0 | 5 | **5** |
| smmm disiplin cezalari | 3 | 2 | 0 | 0 | 5 | **5** |
| sigortali sayilma | 3 | 3 | 0 | 0 | 5 | **5** |
| disiplin yonetmeligi | 3 | 3 | 0 | 0 | 5 | **5** |
| kusursuz sorumluluk halleri | 3 | 3 | 0 | 0 | 5 | **5** |
| buro edinme zorunlulugu | 3 | 3 | 1 | 0 | 5 | **4** |
| ucret hukumleri | 3 | 3 | 0 | 2 | 5 | **3** |
| odeme emrine itiraz | 3 | 3 | 1 | 2 | 5 | **2** |
| hukuka uygunluk sebepleri | 3 | 3 | 2 | 2 | 5 | **1** |
| uyarma cezasi halleri | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi istisnalari | 2 | 2 | 0 | 0 | 3 | **3** |
| ticaret sicili itiraz | 2 | 2 | 0 | 0 | 3 | **3** |
| kesin hukumsuzluk halleri | 2 | 2 | 0 | 0 | 3 | **3** |
| menkul sermaye iradi sayilmayanlar | 2 | 2 | 0 | 0 | 3 | **3** |
| etik ilkeler tehditler | 2 | 2 | 0 | 0 | 3 | **3** |
| sebepsiz zenginlesme sartlari | 2 | 2 | 0 | 0 | 3 | **3** |
| isyeri devri | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari isletme unsurlari | 2 | 2 | 0 | 0 | 3 | **3** |
| is kazasi meslek hastaligi | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv matrah | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 511 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye (ayristirilmamis) — 120 konu, 250 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| laffer egrisi | 4 | 4 | 0 | 0 | 6 | **6** |
| kamu harcamalari artis nedenleri | 3 | 3 | 0 | 0 | 5 | **5** |
| mali anestezi | 3 | 3 | 0 | 2 | 5 | **3** |
| kamu borc yonetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi tarifesi | 2 | 2 | 0 | 0 | 3 | **3** |
| wagner yasasi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi yansimasi | 2 | 2 | 0 | 0 | 3 | **3** |
| verginin kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| otomatik istikrarlandirici | 2 | 2 | 0 | 1 | 3 | **2** |
| vergilemede etkinlik | 2 | 2 | 0 | 1 | 3 | **2** |
| operasyonel acik | 2 | 2 | 0 | 2 | 3 | **1** |
| vergi geliri dususu | 1 | 1 | 0 | 0 | 2 | **2** |
| mali yanilsama modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tanzi etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi kamu maliyesi | 1 | 1 | 0 | 0 | 2 | **2** |
| operasyonel acik hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyonist acik maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| cebre dayanan kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kanunu teklifi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali kaldirac (tam istihdam butce acigi) | 1 | 1 | 0 | 0 | 2 | **2** |
| egemenlik gucune dayanan gelirler | 1 | 1 | 0 | 0 | 2 | **2** |
| harcama vergileri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu giderleri siniflandirma | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalari artis teorileri | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv talep kisici etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi tarifesi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer harcamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| formul esnekligi yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| leviathan modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| gelir vergisi sistemi | 1 | 1 | 0 | 0 | 2 | **2** |
| saf kamusal mal uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc senedi ihrac turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sabit kurda maliye politikasi etkinligi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalarinda gercek-gorunuste artis | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kapatma usulu | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu borc tahvilleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi istisna ve muafiyet | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu mallari samuelson modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye giderleri (butce siniflamasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| esneklik ilkesi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 80 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Genel Kultur-Genel Yetenek (ayristirilmamis) — 194 konu, 424 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sozcukte anlam | 8 | 8 | 0 | 3 | 12 | **9** |
| oge dizilisi ozdes cumle | 5 | 5 | 0 | 0 | 8 | **8** |
| yazim yanlisi | 4 | 4 | 0 | 0 | 6 | **6** |
| milli mucadele basini | 3 | 3 | 0 | 0 | 5 | **5** |
| paragraf bolme | 3 | 3 | 0 | 0 | 5 | **5** |
| ataturk ilkeleri | 3 | 3 | 0 | 0 | 5 | **5** |
| cumle ogeleri dizilisi | 3 | 3 | 0 | 2 | 5 | **3** |
| halifeligin kaldirilmasi | 2 | 2 | 0 | 0 | 3 | **3** |
| paragraf anlami | 2 | 2 | 0 | 0 | 3 | **3** |
| noktalama isaretleri (ayrac) | 2 | 2 | 0 | 0 | 3 | **3** |
| milletler cemiyeti uyeligi | 2 | 2 | 0 | 0 | 3 | **3** |
| buyuk harflerin yazimi | 2 | 2 | 0 | 0 | 3 | **3** |
| milli mucadele | 2 | 2 | 0 | 0 | 3 | **3** |
| teskilat-i esasiye kanunu | 2 | 2 | 0 | 0 | 3 | **3** |
| ataturk donemi ekonomi | 2 | 2 | 0 | 0 | 3 | **3** |
| unsuz yumusamasi | 2 | 2 | 0 | 0 | 3 | **3** |
| cumlede anlam | 2 | 2 | 0 | 0 | 3 | **3** |
| parafta cumle siralama | 2 | 2 | 0 | 0 | 3 | **3** |
| cumlenin ogeleri | 2 | 2 | 0 | 0 | 3 | **3** |
| takrir-i sukun kanunu | 2 | 2 | 0 | 1 | 3 | **2** |
| erzurum kongresi | 2 | 2 | 0 | 2 | 3 | **1** |
| 1921 teskilat-i esasiye kanunu | 1 | 1 | 0 | 0 | 2 | **2** |
| olumsuz-olumlu anlam | 1 | 1 | 0 | 0 | 2 | **2** |
| paragrafta anlam butunlugu | 1 | 1 | 0 | 0 | 2 | **2** |
| parafta devam cumlesi | 1 | 1 | 0 | 0 | 2 | **2** |
| parafta cumle tamamlama | 1 | 1 | 0 | 0 | 2 | **2** |
| cumhuriyet donemi dis politika | 1 | 1 | 0 | 0 | 2 | **2** |
| anlatim bicimleri (aciklayici oykuleme) | 1 | 1 | 0 | 0 | 2 | **2** |
| misak-i milli ve tbmm'nin acilmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| saltanatin kaldirilmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| kabine sistemine gecis | 1 | 1 | 0 | 0 | 2 | **2** |
| ataturk askeri atase (sofya) | 1 | 1 | 0 | 0 | 2 | **2** |
| turkiye-yunanistan iliskileri | 1 | 1 | 0 | 0 | 2 | **2** |
| neden-sonuc baglaci | 1 | 1 | 0 | 0 | 2 | **2** |
| montreux konferansi | 1 | 1 | 0 | 0 | 2 | **2** |
| birinci tbmm kanunlari | 1 | 1 | 0 | 0 | 2 | **2** |
| cumhuriyet donemi kanunlar | 1 | 1 | 0 | 0 | 2 | **2** |
| ii.dunya savasi sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| i. dunya savasi gizli antlasmalar | 1 | 1 | 0 | 0 | 2 | **2** |
| deyimler | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 154 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Matematik-Istatistik (ayristirilmamis) — 160 konu, 375 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| yas problemi | 7 | 6 | 0 | 0 | 11 | **11** |
| seri toplami | 6 | 6 | 0 | 0 | 9 | **9** |
| limit hesabi | 5 | 5 | 0 | 0 | 8 | **8** |
| uslu ifadeler | 4 | 4 | 0 | 0 | 6 | **6** |
| cebirsel ifadeler | 4 | 4 | 0 | 0 | 6 | **6** |
| koklu ifadeler | 4 | 4 | 0 | 0 | 6 | **6** |
| sayi problemi | 4 | 4 | 0 | 2 | 6 | **4** |
| tanimli islem | 4 | 4 | 0 | 2 | 6 | **4** |
| hareket problemi | 3 | 3 | 0 | 0 | 5 | **5** |
| fonksiyon tanim kumesi | 3 | 3 | 0 | 0 | 5 | **5** |
| ustel denklem | 3 | 3 | 0 | 0 | 5 | **5** |
| karmasik kesir islemi | 3 | 3 | 0 | 0 | 5 | **5** |
| cebirsel sadelestirme | 3 | 3 | 0 | 4 | 5 | **1** |
| alan hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| cebirsel ifade | 2 | 2 | 0 | 0 | 3 | **3** |
| sayi problemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| OKUNAMADI (2 soru - PDF iki sutun dizgisi) | 2 | 1 | 0 | 0 | 3 | **3** |
| denklem sistemi | 2 | 2 | 0 | 0 | 3 | **3** |
| integral hesaplama | 2 | 2 | 0 | 0 | 3 | **3** |
| cember-dogru sinirli alan | 2 | 2 | 0 | 0 | 3 | **3** |
| turev hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| islem yapma | 2 | 1 | 0 | 0 | 3 | **3** |
| kesirli islem | 2 | 2 | 0 | 0 | 3 | **3** |
| permutasyon | 2 | 2 | 0 | 0 | 3 | **3** |
| cebirsel ifade sadelestirme | 2 | 2 | 0 | 1 | 3 | **2** |
| kesirli islemler | 2 | 2 | 0 | 1 | 3 | **2** |
| analitik geometri | 2 | 2 | 0 | 2 | 3 | **1** |
| analitik geometri dik dogrular | 1 | 1 | 0 | 0 | 2 | **2** |
| birler basamagi | 1 | 1 | 0 | 0 | 2 | **2** |
| ifade hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| trigonometrik limit | 1 | 1 | 0 | 0 | 2 | **2** |
| belirli integral degisken donusumu | 1 | 1 | 0 | 0 | 2 | **2** |
| ucgen alani | 1 | 1 | 0 | 0 | 2 | **2** |
| ikinci turev (bileske) | 1 | 1 | 0 | 0 | 2 | **2** |
| uslu sayi birler basamagi | 1 | 1 | 0 | 0 | 2 | **2** |
| havuz problemi | 1 | 1 | 0 | 0 | 2 | **2** |
| kâr-zarar problemi | 1 | 1 | 0 | 0 | 2 | **2** |
| mutlak deger esitsizligi | 1 | 1 | 0 | 0 | 2 | **2** |
| yuzde para problemi | 1 | 1 | 0 | 0 | 2 | **2** |
| permutasyon (tek sayi) | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 120 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi (ayristirilmamis) — 140 konu, 289 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| marjinal fayda | 3 | 3 | 0 | 0 | 5 | **5** |
| taylor prensibi | 3 | 3 | 0 | 1 | 5 | **4** |
| yeni keynesyen model | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| gresham kanunu | 2 | 2 | 0 | 0 | 3 | **3** |
| keynesyen tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| marjinal urun hasilati | 2 | 2 | 0 | 0 | 3 | **3** |
| likidite tuzagi | 2 | 2 | 0 | 0 | 3 | **3** |
| zorunlu karsilik orani | 2 | 2 | 0 | 0 | 3 | **3** |
| taylor kurali | 2 | 2 | 0 | 0 | 3 | **3** |
| paranin yansizligi | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketici fazlasi | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim duzlestirmesi | 2 | 2 | 0 | 2 | 3 | **1** |
| genisletici para politikasi araclari | 2 | 2 | 0 | 2 | 3 | **1** |
| mundell-fleming sabit kur maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercihleri konvekslik | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik turleri hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| kredi tayinlamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ricardo modeli varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| gelir tuketim egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| doymazlik varsayimi marjinal fayda | 1 | 1 | 0 | 0 | 2 | **2** |
| marjinal maliyet hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz kuru sterilizasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| alman merkantilizmi | 1 | 1 | 0 | 0 | 2 | **2** |
| trampa ekonomisi fiyat sayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam fayda doyum noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| dogrusal uretim fonksiyonu kose cozumu | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi ozellikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| reel doviz kuru ve net ihracat | 1 | 1 | 0 | 0 | 2 | **2** |
| artan firsat maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| uclu acmaz | 1 | 1 | 0 | 0 | 2 | **2** |
| cobb-douglas ikame esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| heckscher-ohlin modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tahvil piyasasi dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| carpan etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisler hipotezi | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet piyasa dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi kaymasi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 100 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ataturk Ilke ve Inkilap Tarihi — 14 konu, 41 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| lozan antlasmasi | 6 | 6 | 0 | 0 | 9 | **9** |
| ataturk donemi dis politika | 3 | 3 | 0 | 0 | 5 | **5** |
| ataturk eserleri | 2 | 2 | 0 | 0 | 3 | **3** |
| lozan konferansi | 2 | 2 | 0 | 0 | 3 | **3** |
| kurtulus savasi antlasmalari | 2 | 2 | 0 | 0 | 3 | **3** |
| milli mucadele donemi | 2 | 2 | 0 | 0 | 3 | **3** |
| halkcilik ilkesi | 1 | 1 | 0 | 0 | 2 | **2** |
| tbmm'nin acilisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kurtulus savasi zaferleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kurtulus savasi cepheleri | 1 | 1 | 0 | 0 | 2 | **2** |
| milletler cemiyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| mondros mutarekesi | 1 | 1 | 0 | 0 | 2 | **2** |
| cumhuriyetin ilani | 1 | 1 | 0 | 0 | 2 | **2** |
| sakarya meydan muharebesi | 1 | 1 | 0 | 1 | 2 | **1** |

### Muhasebe (ayristirilmamis) — 621 konu, 1320 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim riski | 6 | 5 | 0 | 0 | 9 | **9** |
| tms 18 hasilat | 6 | 6 | 0 | 0 | 9 | **9** |
| denetim kanitlari | 5 | 5 | 0 | 0 | 8 | **8** |
| iliskili taraflar denetimi | 4 | 4 | 0 | 0 | 6 | **6** |
| depozito iadesi kaydi | 4 | 4 | 0 | 0 | 6 | **6** |
| ic kontrol sistemi | 4 | 4 | 1 | 0 | 6 | **5** |
| stok sayimi denetimi | 4 | 4 | 2 | 1 | 6 | **3** |
| denetim prosedurleri | 3 | 3 | 0 | 0 | 5 | **5** |
| bagimsiz denetim sureci | 3 | 3 | 0 | 0 | 5 | **5** |
| yonetim beyanlari | 3 | 3 | 0 | 0 | 5 | **5** |
| guvence hizmetleri | 3 | 3 | 0 | 0 | 5 | **5** |
| stok denetimi | 3 | 2 | 0 | 0 | 5 | **5** |
| denetim belgelendirme | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim gorusu turleri | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim planlamasi | 3 | 3 | 0 | 0 | 5 | **5** |
| nazim hesaplar | 3 | 3 | 0 | 0 | 5 | **5** |
| yonetim iddialari | 3 | 3 | 0 | 0 | 5 | **5** |
| temel muhasebe kavramlari | 3 | 3 | 1 | 0 | 5 | **4** |
| bilanco hesaplari | 3 | 3 | 1 | 1 | 5 | **3** |
| denetci raporu | 3 | 3 | 1 | 2 | 5 | **2** |
| serefiye hesaplama | 3 | 3 | 3 | 0 | 5 | **2** |
| nakit denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| safha maliyetleme | 2 | 2 | 0 | 0 | 3 | **3** |
| tahakkuk esasi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim finansal tablo iddialari | 2 | 1 | 0 | 0 | 3 | **3** |
| finansal oranlar | 2 | 2 | 0 | 0 | 3 | **3** |
| gelir tablosu ilkeleri | 2 | 2 | 0 | 0 | 3 | **3** |
| acilis bakiyeleri denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| uluslararasi muhasebe kuruluslari | 2 | 2 | 0 | 0 | 3 | **3** |
| azalan bakiyelerden normale gecis amortismani | 2 | 2 | 0 | 0 | 3 | **3** |
| akreditif kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| stokta kalma suresi hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| duzenleyici hesaplar | 2 | 2 | 0 | 0 | 3 | **3** |
| dis teyit prosedurleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetimde ornekleme | 2 | 2 | 0 | 0 | 3 | **3** |
| maddi duran varlik dogruluk testi | 2 | 1 | 0 | 0 | 3 | **3** |
| ucuncu taraf stok denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim riski turleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kalite kontrolu | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 581 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Yabanci Dil (ayristirilmamis) — 101 konu, 270 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| kelime bilgisi | 14 | 9 | 0 | 1 | 12 | **11** |
| sentence completion | 9 | 3 | 0 | 4 | 12 | **8** |
| kelime tamamlama | 7 | 3 | 0 | 0 | 11 | **11** |
| cumle tamamlama-kosul | 7 | 7 | 0 | 1 | 11 | **10** |
| cumle tamamlama (zitlik) | 5 | 5 | 0 | 0 | 8 | **8** |
| cumle tamamlama (zaman) | 4 | 4 | 0 | 0 | 6 | **6** |
| edat secimi | 4 | 3 | 0 | 0 | 6 | **6** |
| karsilastirma yapisi | 4 | 3 | 0 | 0 | 6 | **6** |
| kosul cumlesi | 4 | 4 | 0 | 0 | 6 | **6** |
| cumle tamamlama (sonuc) | 3 | 3 | 0 | 0 | 5 | **5** |
| baglac (although) | 3 | 3 | 0 | 0 | 5 | **5** |
| sifat karsilastirma | 3 | 3 | 0 | 0 | 5 | **5** |
| vocabulary | 3 | 2 | 0 | 4 | 5 | **1** |
| kelime secimi | 2 | 2 | 0 | 0 | 3 | **3** |
| kelime secimi (value) | 2 | 2 | 0 | 0 | 3 | **3** |
| cumle tamamlama (ilgi cumlesi) | 2 | 2 | 0 | 0 | 3 | **3** |
| cumle tamamlama (neden) | 2 | 2 | 0 | 0 | 3 | **3** |
| iliski zamiri | 2 | 2 | 0 | 0 | 3 | **3** |
| baglaclar | 2 | 1 | 0 | 0 | 3 | **3** |
| edilgen yapi | 2 | 2 | 0 | 0 | 3 | **3** |
| kelime secimi (manages) | 1 | 1 | 0 | 0 | 2 | **2** |
| conjunction | 1 | 1 | 0 | 0 | 2 | **2** |
| baglac (when) | 1 | 1 | 0 | 0 | 2 | **2** |
| baglac (even though) | 1 | 1 | 0 | 0 | 2 | **2** |
| zaman secimi (present continuous) | 1 | 1 | 0 | 0 | 2 | **2** |
| baglac (so that) | 1 | 1 | 0 | 0 | 2 | **2** |
| zaman secimi (stopped) | 1 | 1 | 0 | 0 | 2 | **2** |
| present perfect (has become) | 1 | 1 | 0 | 0 | 2 | **2** |
| miktar belirteci | 1 | 1 | 0 | 0 | 2 | **2** |
| pasif yapi | 1 | 1 | 0 | 0 | 2 | **2** |
| enustunluk (most active) | 1 | 1 | 0 | 0 | 2 | **2** |
| edilgen gecmis zaman (were consumed) | 1 | 1 | 0 | 0 | 2 | **2** |
| kelime secimi (properly) | 1 | 1 | 0 | 0 | 2 | **2** |
| baglac (before) | 1 | 1 | 0 | 0 | 2 | **2** |
| edat secimi (by/of) | 1 | 1 | 0 | 0 | 2 | **2** |
| soru yapisi (did/watch) | 1 | 1 | 0 | 0 | 2 | **2** |
| edilgen cati | 1 | 1 | 0 | 0 | 2 | **2** |
| relative clauses | 1 | 1 | 0 | 0 | 2 | **2** |
| quantifiers | 1 | 1 | 0 | 0 | 2 | **2** |
| kelime secimi (construct) | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 61 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

