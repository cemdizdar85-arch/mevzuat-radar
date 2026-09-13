# KONU PLANI — STAJA BAŞLAMA (SGS)

> Uretim: **13.09.2026 12:52** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.238 konu** var. Bunlarin **2.487**'inde elimizde soru YETERSIZ; toplam **5.008 soru** basilacak. Su an bu konularda **3.495** saglam sorumuz var.

## 0a · IKI HAT — Cem karari (11.09)

> *"matematik, ingilizce ve baska ne varsa sozel beklesin; digerlerini bir bitirelim sonra bunlara donelim"*

| Hat | Ders | Konu | Soru | Bedel (toplu) |
|---|---|---:|---:|---:|
| **SIMDI** | Alan Bilgisi (muhasebe · denetim · hukuk · ekonomi · maliye) | **1.932** | **3.684** | **24.167 TL** |
| BEKLESIN | Matematik · Yabanci Dil · Turkce · Inkilap · Genel Kultur | 555 | 1.324 | 8.685 TL |

Bekleyen hat mevzuata dayanmaz; kaynak paketi mantigi (ambardan madde cekme)
orada islemez, ayri bir hat gerektirir. 08.09'da da ayni sebeple Tur 1 disinda kalmislardi.
**Asagidaki butun tablolar SIMDI hattini gosterir**; bekleyen hat bolum 4'te ayri durur.

## 0b · BEDEL ve ONCELIK — SIMDI hatti

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 5 | 11 | 144 TL | 72 TL |
| 2 · kritik | cikmis >= 5 | 38 | 121 | 1.588 TL | 794 TL |
| 3 · onemli | cikmis >= 3 | 105 | 274 | 3.595 TL | 1.797 TL |
| 4 · orta | cikmis >= 2 | 208 | 449 | 5.891 TL | 2.945 TL |
| 5 · tamami | cikmis >= 1 | 1.932 | 3.684 | 48.334 TL | 24.167 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 585 | 875 | 1.503 | **723** | 399 |
| Denetim | 16 | 361 | 590 | 884 | **419** | 228 |
| Mali Tablolar Analizi | 8 | 115 | 169 | 315 | **161** | 83 |
| Maliyet Muhasebesi | 8 | 213 | 318 | 530 | **253** | 141 |
| Maliye | 6 | 104 | 104 | 239 | **162** | 80 |
| Ekonomi | 6 | 90 | 101 | 213 | **119** | 67 |
| Vergi Hukuku | 6 | 161 | 148 | 369 | **253** | 125 |
| Meslek Hukuku | 6 | 82 | 121 | 228 | **127** | 60 |
| Borclar Hukuku | 6 | 106 | 187 | 293 | **132** | 63 |
| Is ve Sosyal Guvenlik Hukuku | 6 | 99 | 125 | 272 | **152** | 82 |
| Ticaret Hukuku | 6 | 159 | 197 | 396 | **234** | 121 |
| Ekonomi (ayristirilamadi) | — | 83 | 23 | 167 | **148** | 76 |
| Hukuk (ayristirilamadi) | — | 175 | 64 | 351 | **309** | 155 |
| Muhasebe (ayristirilamadi) | — | 234 | 77 | 469 | **408** | 210 |
| Maliye (ayristirilamadi) | — | 45 | 9 | 90 | **84** | 42 |
| **TOPLAM** | **130** | **3.238** | **3.495** | | **5.008** | **2.487** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 399 konu, 723 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| muhasebe bilgi sistemi | 10 | 10 | 10 | 0 | 12 | **2** |
| tms 40 yatirim amacli gayrimenkul | 8 | 8 | 9 | 1 | 12 | **2** |
| nakit akis tablosu | 8 | 7 | 11 | 0 | 12 | **1** |
| tms 37 karsiliklar | 7 | 7 | 5 | 1 | 11 | **5** |
| hisse senedi satisi | 7 | 7 | 5 | 1 | 11 | **5** |
| tms 36 deger dusuklugu | 7 | 7 | 8 | 0 | 11 | **3** |
| gider tahakkuku | 7 | 7 | 9 | 0 | 11 | **2** |
| sermaye artirimi | 7 | 7 | 9 | 1 | 11 | **1** |
| kar dagitimi kaydi | 5 | 5 | 7 | 0 | 8 | **1** |
| tms 12 ertelenmis vergi | 5 | 5 | 6 | 1 | 8 | **1** |
| gelir tahakkuku | 5 | 5 | 7 | 0 | 8 | **1** |
| donemsellik kavrami | 5 | 5 | 7 | 0 | 8 | **1** |
| tutarlilik kavrami | 4 | 4 | 1 | 1 | 6 | **4** |
| yasal yedek akce | 4 | 4 | 3 | 1 | 6 | **2** |
| tms 28 istirakler | 4 | 4 | 5 | 0 | 6 | **1** |
| stok deger dusuklugu | 4 | 4 | 4 | 1 | 6 | **1** |
| kasa sayim farki | 4 | 4 | 5 | 0 | 6 | **1** |
| nazim hesaplar | 3 | 3 | 1 | 0 | 5 | **4** |
| fifo yontemi | 3 | 3 | 2 | 0 | 5 | **3** |
| donem kari hesaplama | 3 | 3 | 3 | 0 | 5 | **2** |
| hazine bonosu tahsili | 3 | 3 | 3 | 0 | 5 | **2** |
| onemlilik kavrami | 3 | 3 | 4 | 0 | 5 | **1** |
| kidem tazminati | 3 | 3 | 4 | 0 | 5 | **1** |
| tms-38 maddi olmayan duran varliklar | 3 | 3 | 4 | 0 | 5 | **1** |
| menkul kiymet satisi | 3 | 3 | 4 | 0 | 5 | **1** |
| tms 10 raporlama sonrasi olaylar | 3 | 3 | 4 | 0 | 5 | **1** |
| toplulastirma riski | 2 | 2 | 0 | 0 | 3 | **3** |
| tfrs 9 finansal yukumluluk olcumu | 2 | 2 | 0 | 0 | 3 | **3** |
| akreditif kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| duzenleyici hesaplar | 2 | 2 | 1 | 0 | 3 | **2** |
| bilanco sonrasi olaylar | 2 | 2 | 1 | 0 | 3 | **2** |
| ortalama tahsilat suresi | 2 | 2 | 0 | 1 | 3 | **2** |
| tasima gideri kaydi | 2 | 2 | 1 | 0 | 3 | **2** |
| ticari alacak dogrulama | 2 | 2 | 0 | 1 | 3 | **2** |
| tms 41 tarimsal faaliyetler | 2 | 2 | 1 | 0 | 3 | **2** |
| gelir tablosu kalemleri | 2 | 2 | 1 | 0 | 3 | **2** |
| finansal tablolar | 2 | 2 | 2 | 0 | 3 | **1** |
| ozkaynak degisimi | 2 | 2 | 2 | 0 | 3 | **1** |
| gelecek yillara ait gelirler | 2 | 2 | 2 | 0 | 3 | **1** |
| zorunlu karsilik orani | 2 | 2 | 2 | 0 | 3 | **1** |
| _… 359 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Denetim — 228 konu, 419 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim kaniti yeterliligi | 11 | 9 | 9 | 0 | 12 | **3** |
| denetim kaniti guvenilirligi | 8 | 7 | 11 | 0 | 12 | **1** |
| denetim riski | 6 | 5 | 2 | 0 | 9 | **7** |
| kasa denetimi | 5 | 5 | 5 | 0 | 8 | **3** |
| denetim kanitlari | 5 | 5 | 5 | 0 | 8 | **3** |
| denetim calisma kagitlari | 5 | 5 | 7 | 0 | 8 | **1** |
| analitik prosedurler | 5 | 5 | 7 | 0 | 8 | **1** |
| iliskili taraflar denetimi | 4 | 4 | 5 | 0 | 6 | **1** |
| bagimsiz denetim sureci | 3 | 3 | 2 | 0 | 5 | **3** |
| maddi duran varlik denetimi | 3 | 3 | 3 | 0 | 5 | **2** |
| yonetim beyanlari | 3 | 3 | 3 | 0 | 5 | **2** |
| stok denetimi | 3 | 2 | 4 | 0 | 5 | **1** |
| denetim gorusu turleri | 3 | 3 | 4 | 0 | 5 | **1** |
| denetim planlamasi | 3 | 3 | 3 | 1 | 5 | **1** |
| denetim belgelendirme | 3 | 3 | 4 | 0 | 5 | **1** |
| yapisal risk faktorleri | 3 | 3 | 4 | 0 | 5 | **1** |
| maddi olmayan duran varlik denetimi | 2 | 2 | 1 | 0 | 3 | **2** |
| uluslararasi muhasebe kuruluslari | 2 | 2 | 1 | 1 | 3 | **1** |
| denetci gorusu | 2 | 2 | 2 | 0 | 3 | **1** |
| kamu alacagi guvence onlemleri | 2 | 2 | 2 | 0 | 3 | **1** |
| ic kontrol onleyici kontroller | 1 | 1 | 0 | 0 | 2 | **2** |
| baslangic analitik prosedur amaclari | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim etik ilkeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 240 firsat faktoru | 1 | 1 | 0 | 0 | 2 | **2** |
| onemlilik belirleme yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| orneklem secim yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim kaniti uzman calismasi | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 560 bilanco sonrasi olaylar | 1 | 1 | 0 | 0 | 2 | **2** |
| kalite guvence esaslari/ilkeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| gorus bildirmekten kacinma raporu | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim kaniti yeterlik uygunluk | 1 | 1 | 0 | 0 | 2 | **2** |
| denetci bagimsizligi | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim tamamlama raporlama | 1 | 1 | 0 | 0 | 2 | **2** |
| stok degerleme denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| alinan cekler denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim raporu unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| amortisman denetimi (yonetim iddialari) | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 500 denetim kaniti | 1 | 1 | 0 | 0 | 2 | **2** |
| risk temelli denetim | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim amaci-prosedur eslestirmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 188 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Mali Tablolar Analizi — 83 konu, 161 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| dikey yuzde analizi | 12 | 11 | 11 | 0 | 12 | **1** |
| net isletme sermayesi | 9 | 8 | 3 | 0 | 12 | **9** |
| yatay analiz | 8 | 8 | 9 | 0 | 12 | **3** |
| aktif devir hizi | 8 | 8 | 9 | 2 | 12 | **1** |
| cari oran analizi | 6 | 6 | 1 | 1 | 9 | **7** |
| stok devir hizi | 6 | 6 | 7 | 0 | 9 | **2** |
| asit-test orani | 4 | 4 | 3 | 0 | 6 | **3** |
| cari oran hesaplama | 4 | 4 | 5 | 0 | 6 | **1** |
| dikey analiz | 3 | 3 | 4 | 0 | 5 | **1** |
| piyasa degeri-defter degeri orani | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal oran analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| stokta kalma suresi hesabi | 2 | 2 | 1 | 0 | 3 | **2** |
| dikey yuzdelerden bilanco yorumu | 2 | 2 | 1 | 0 | 3 | **2** |
| yuzde degisim analizi | 2 | 2 | 2 | 0 | 3 | **1** |
| likidite orani | 2 | 2 | 2 | 0 | 3 | **1** |
| standart oranlar | 2 | 2 | 2 | 0 | 3 | **1** |
| alacak devir hizi | 2 | 2 | 1 | 1 | 3 | **1** |
| cari orani artiran islemler | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac orani hesabi (borc-ozsermaye) | 1 | 1 | 0 | 0 | 2 | **2** |
| finansal kaldirac orani | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak kârlilik orani | 1 | 1 | 0 | 0 | 2 | **2** |
| trend (yatay) analiz teknigi | 1 | 1 | 0 | 0 | 2 | **2** |
| yatay analiz kar marji | 1 | 1 | 0 | 0 | 2 | **2** |
| hazir degerler analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| sektorel oran analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali tablo analiz teknikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| oran analizi karsilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran borc ozsermaye | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzde ve duran varlik oraniyla donen varlik | 1 | 1 | 0 | 0 | 2 | **2** |
| karlilik orani secimi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac siniriyla kredi kapasitesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak degisimi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| devir hizi ve kaldiractan oz kaynak | 1 | 1 | 0 | 0 | 2 | **2** |
| net isletme sermayesi negatif kosulu | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran-asit test hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran | 1 | 1 | 0 | 0 | 2 | **2** |
| net isletme sermayesi hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| brut kar marji | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran asit test orani | 1 | 1 | 0 | 0 | 2 | **2** |
| oz sermaye carpani-kaldirac iliskisi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 43 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliyet Muhasebesi — 141 konu, 253 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ortak maliyet dagitimi | 13 | 13 | 11 | 0 | 12 | **1** |
| evre maliyet sistemi | 5 | 5 | 5 | 0 | 8 | **3** |
| satilan mamul maliyeti | 5 | 5 | 7 | 0 | 8 | **1** |
| ekonomik siparis miktari | 3 | 3 | 0 | 0 | 5 | **5** |
| birlesik maliyet satis degeri yontemi | 2 | 2 | 1 | 0 | 3 | **2** |
| gug birim pay hesabi | 2 | 2 | 1 | 0 | 3 | **2** |
| ozel maliyet amortismani | 2 | 2 | 1 | 0 | 3 | **2** |
| safha maliyetleme | 2 | 2 | 1 | 0 | 3 | **2** |
| direkt ilk madde geriye dogru hesap | 2 | 2 | 2 | 0 | 3 | **1** |
| gider yeri dagitimi | 2 | 2 | 2 | 0 | 3 | **1** |
| birim uretim maliyeti | 2 | 2 | 2 | 0 | 3 | **1** |
| maliyet yontemleri karsilastirma | 2 | 2 | 2 | 0 | 3 | **1** |
| maliyet fonksiyonu | 2 | 2 | 2 | 0 | 3 | **1** |
| stok maliyet yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| aralikli envanter satilan mal maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| basabas noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyetler kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ve degisken maliyet sistemi | 1 | 1 | 0 | 0 | 2 | **2** |
| esdeger birim hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| aralikli sayim satilan mal maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| genel uretim gideri ikramiye tahakkuku | 1 | 1 | 0 | 0 | 2 | **2** |
| hareketli ortalama maliyet yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliyet ve otomasyon sistemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| artan firsat maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel siparis karari | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyetler | 1 | 1 | 0 | 0 | 2 | **2** |
| firsat maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| basabas noktasi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| degisken maliyet katki payi | 1 | 1 | 0 | 0 | 2 | **2** |
| siparis maliyetinde gug yukleme orani | 1 | 1 | 0 | 0 | 2 | **2** |
| kiralanan varlige asansor (ozel maliyet) kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| ortalama maliyet tamamlanma derecesi | 1 | 1 | 0 | 0 | 2 | **2** |
| fazla calisma ucreti maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyet | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyet gideri | 1 | 1 | 0 | 0 | 2 | **2** |
| normal-tam maliyet birim farki | 1 | 1 | 0 | 0 | 2 | **2** |
| tam maliyet sistemi brut kâr | 1 | 1 | 0 | 0 | 2 | **2** |
| tam maliyet birim gug hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| genel uretim giderleri dagitimi | 1 | 1 | 0 | 0 | 2 | **2** |
| gug yukleme farklari | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 101 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye — 80 konu, 162 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| butce ilkeleri | 4 | 4 | 5 | 0 | 6 | **1** |
| laffer egrisi | 4 | 4 | 0 | 5 | 6 | **1** |
| kamu harcamalari artis nedenleri | 3 | 3 | 0 | 0 | 5 | **5** |
| vergi tarifesi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu borc yonetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| wagner yasasi | 2 | 2 | 0 | 0 | 3 | **3** |
| otomatik istikrarlandirici | 2 | 2 | 1 | 0 | 3 | **2** |
| artan oranli vergi | 2 | 2 | 2 | 0 | 3 | **1** |
| mundell-fleming sabit kur maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| cebre dayanan kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi kamu maliyesi | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyonist acik maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kanunu teklifi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi tarifesi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi entegrasyon yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi takozu | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sabit kurda maliye politikasi etkinligi | 1 | 1 | 0 | 0 | 2 | **2** |
| saf kamusal mal uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu borc tahvilleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu geliri turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye giderleri (butce siniflamasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kapatma usulu | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamasi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| stagflasyonda maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| dolayli vergi kaldirilmasinin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliye politikasi amaclari (ekonomik istikrar) | 1 | 1 | 0 | 0 | 2 | **2** |
| butce acigi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi oranlilik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin karar etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalarinda gercek-gorunuste artis | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansima asamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| duz oranli vergi grafigi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi harcamasi hesaplama yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalari artis teorisi | 1 | 1 | 0 | 0 | 2 | **2** |
| yari kamusal mallar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 40 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi — 67 konu, 119 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| taylor prensibi | 3 | 3 | 4 | 0 | 5 | **1** |
| marjinal fayda | 3 | 3 | 4 | 0 | 5 | **1** |
| gresham kanunu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketici fazlasi | 2 | 2 | 0 | 0 | 3 | **3** |
| yeni keynesyen model | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketim duzlestirmesi | 2 | 2 | 1 | 0 | 3 | **2** |
| taylor kurali | 2 | 2 | 2 | 0 | 3 | **1** |
| operasyonel acik | 2 | 2 | 2 | 0 | 3 | **1** |
| paranin yansizligi | 2 | 2 | 2 | 0 | 3 | **1** |
| mukayeseli ustunluk firsat maliyeti | 2 | 2 | 2 | 0 | 3 | **1** |
| keynesyen tuketim fonksiyonu | 2 | 2 | 2 | 0 | 3 | **1** |
| likidite tuzagi | 2 | 2 | 2 | 0 | 3 | **1** |
| talep fiyat esnekligi (inelastik) | 1 | 1 | 0 | 0 | 2 | **2** |
| tasarruf paradoksu | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet uretim durdurma | 1 | 1 | 0 | 0 | 2 | **2** |
| arz talep esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| bilesik faiz cari hesap | 1 | 1 | 0 | 0 | 2 | **2** |
| phillips egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| talep/fiyat esnekligi kâr analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| reel doviz kuru ve net ihracat | 1 | 1 | 0 | 0 | 2 | **2** |
| talep kanunu | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam talep uzun donem denge | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci rekabet dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| leontief uretim fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon olcum sapmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal tekel duzenlemesi | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim fonksiyonu ikame esnekligi (dogrusal) | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz kuru sterilizasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| bilanco talep haklari | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik istihdam hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| j egrisi devaluasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| doymazlik varsayimi marjinal fayda | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik turleri hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda maksimizasyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon-dezenflasyon ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| stackelberg modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon hedeflemesi | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz arz egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal issizlik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 27 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Vergi Hukuku — 125 konu, 253 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| damga vergisi | 5 | 5 | 6 | 0 | 8 | **2** |
| kdv vergiyi doguran olay | 4 | 4 | 2 | 0 | 6 | **4** |
| ozel tuketim vergisi | 3 | 3 | 0 | 0 | 5 | **5** |
| vuk degerleme olculeri | 3 | 3 | 0 | 0 | 5 | **5** |
| transfer fiyatlandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| kurumlar vergisi mukellefleri | 3 | 3 | 4 | 0 | 5 | **1** |
| kurumlar vergisi indirimleri | 2 | 2 | 0 | 0 | 3 | **3** |
| vuk kapsami | 2 | 2 | 0 | 0 | 3 | **3** |
| verginin kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi zarar mahsubu (5 yil) | 2 | 2 | 0 | 0 | 3 | **3** |
| ihtiyati hacze itiraz suresi (15 gun) | 2 | 2 | 0 | 0 | 3 | **3** |
| tahakkuk esasi | 2 | 2 | 1 | 0 | 3 | **2** |
| vergilemede etkinlik | 2 | 2 | 0 | 1 | 3 | **2** |
| kdv matrah | 2 | 2 | 1 | 0 | 3 | **2** |
| vergi cezalari | 2 | 2 | 1 | 0 | 3 | **2** |
| kdv kapsami | 2 | 2 | 2 | 0 | 3 | **1** |
| kurumlar vergisi istisnalari | 2 | 2 | 1 | 1 | 3 | **1** |
| kdv indirimi | 2 | 2 | 2 | 0 | 3 | **1** |
| otv kapsaminda vergi ziyai | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tarh yeri | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi incelemesi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| bakanlar kurulu vergi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi cezasi yanilma | 1 | 1 | 0 | 0 | 2 | **2** |
| odeme emrine dava acma suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset ve intikal vergisi istisnalari | 1 | 1 | 0 | 0 | 2 | **2** |
| munferit beyanname | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tevkifat | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv konusu | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset ve intikal vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| ikramiye tahakkuku | 1 | 1 | 0 | 0 | 2 | **2** |
| kurumlar vergisi matrahi | 1 | 1 | 0 | 0 | 2 | **2** |
| dijital hizmet vergisi beyani | 1 | 1 | 0 | 0 | 2 | **2** |
| degerli konut vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| konaklama vergisi orani (%2) | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tevkifati | 1 | 1 | 0 | 0 | 2 | **2** |
| harcama vergileri | 1 | 1 | 0 | 0 | 2 | **2** |
| tarh zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| vuk tekerrur | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv indirim hakki | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi ziyai cezasi orani (%50) | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 85 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Meslek Hukuku — 60 konu, 127 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| disiplin cezalari | 11 | 11 | 7 | 1 | 12 | **4** |
| meslek etik ilkeleri | 9 | 9 | 2 | 0 | 12 | **10** |
| haksiz rekabet reklam yasagi | 7 | 7 | 6 | 3 | 11 | **2** |
| sir saklama yukumlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| meslek mensubu ucret esaslari | 3 | 3 | 1 | 0 | 5 | **4** |
| mesleki etik ilkeler | 3 | 3 | 2 | 1 | 5 | **2** |
| reklam yasagi | 3 | 3 | 0 | 3 | 5 | **2** |
| serbest meslek kazanci | 3 | 3 | 4 | 0 | 5 | **1** |
| disiplin yonetmeligi | 3 | 3 | 4 | 0 | 5 | **1** |
| smmm disiplin cezalari | 3 | 2 | 4 | 0 | 5 | **1** |
| oda organlari gorevleri | 2 | 2 | 1 | 0 | 3 | **2** |
| calisma usul esaslari | 2 | 2 | 1 | 1 | 3 | **1** |
| uyarma cezasi halleri | 2 | 2 | 2 | 0 | 3 | **1** |
| meslek mensubu genel sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun birlik | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek hukuku oda organlari | 1 | 1 | 0 | 0 | 2 | **2** |
| oda genel kurulu yetkileri | 1 | 1 | 0 | 0 | 2 | **2** |
| ymm sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek disiplin cezalari | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun meslek konusu | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu silinme halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm is kabulu | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm staj yonetmeligi | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun-odalar | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm ucret esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm olabilmenin ozel sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm oda yapisi | 1 | 1 | 0 | 0 | 2 | **2** |
| staj suresi (3568 sayili kanun) | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma usul ve esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu ticari faaliyet yasagi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek ucret tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| oda organlari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm calisanlar listesi | 1 | 1 | 0 | 0 | 2 | **2** |
| oda genel kurulu | 1 | 1 | 0 | 0 | 2 | **2** |
| unvan kullanma cezasi (6 ay-1 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu ucret tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm mesleki yasaklar | 1 | 1 | 0 | 0 | 2 | **2** |
| reklam yasagi yonetmeligi (seminer duyurusu) | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 20 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Borclar Hukuku — 63 konu, 132 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sebepsiz zenginlesme | 8 | 8 | 7 | 1 | 12 | **4** |
| sozlesme sekli | 5 | 5 | 1 | 0 | 8 | **7** |
| haksiz fiil zamanasimi | 4 | 4 | 4 | 0 | 6 | **2** |
| sozlesmenin kurulmasi | 4 | 4 | 4 | 1 | 6 | **1** |
| takas | 3 | 3 | 0 | 0 | 5 | **5** |
| borclu temerrudu | 3 | 3 | 0 | 0 | 5 | **5** |
| tazminattan indirim halleri | 3 | 3 | 1 | 0 | 5 | **4** |
| haksiz fiil unsurlari | 3 | 3 | 2 | 0 | 5 | **3** |
| zamanasimi | 3 | 3 | 0 | 2 | 5 | **3** |
| zamanasimi suresi | 3 | 3 | 2 | 0 | 5 | **3** |
| hizmet borclanmasi | 3 | 3 | 3 | 1 | 5 | **1** |
| sorumsuzluk anlasmalari | 2 | 2 | 2 | 0 | 3 | **1** |
| irade bozuklugu | 2 | 2 | 2 | 0 | 3 | **1** |
| kesin hukumsuzluk halleri | 2 | 2 | 2 | 0 | 3 | **1** |
| sebepsiz zenginlesme sartlari | 2 | 2 | 2 | 0 | 3 | **1** |
| haksiz fiil borc iliskileri | 1 | 1 | 0 | 0 | 2 | **2** |
| alacagin devri sekli | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmenin kurulmasi (oneri kurallari) | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| akdi temerrut faizi siniri (%100) | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmeden dogan alacakta zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| sebepsiz zenginlesme ahlaka aykiri amac | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi kurallari (iade) | 1 | 1 | 0 | 0 | 2 | **2** |
| kosula bagli sozlesme | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerin kurulmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi asgari bilgileri | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasimi sureleri | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimini kesen haller | 1 | 1 | 0 | 0 | 2 | **2** |
| takas kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerde kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| ifa yeri ve zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin durmasi halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| borcun ifa zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin kesilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme onerisi (icap) | 1 | 1 | 0 | 0 | 2 | **2** |
| para borcu ifa yeri | 1 | 1 | 0 | 0 | 2 | **2** |
| sebepsiz zenginlesme zamanasimi (2-10 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| sureye bagli borclarda vade hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| esas sozlesme degisikligi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 23 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Is ve Sosyal Guvenlik Hukuku — 82 konu, 152 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| toplu is sozlesmesi | 6 | 6 | 2 | 0 | 9 | **7** |
| sendika uyeligi | 6 | 6 | 6 | 0 | 9 | **3** |
| yillik ucretli izin | 4 | 4 | 4 | 0 | 6 | **2** |
| is sozlesmesi feshi | 4 | 4 | 5 | 0 | 6 | **1** |
| calisma suresi | 3 | 3 | 0 | 0 | 5 | **5** |
| calisma ve dinlenme sureleri | 3 | 3 | 1 | 0 | 5 | **4** |
| sigortali sayilma | 3 | 3 | 2 | 0 | 5 | **3** |
| isci ucretleri | 3 | 3 | 2 | 1 | 5 | **2** |
| is kazasi sayilmayan haller | 3 | 3 | 3 | 0 | 5 | **2** |
| ucret hukumleri | 3 | 3 | 2 | 1 | 5 | **2** |
| İs kanunu kapsami | 3 | 3 | 4 | 0 | 5 | **1** |
| sureli fesih | 3 | 3 | 4 | 0 | 5 | **1** |
| sureli fesih kurallari | 2 | 2 | 1 | 0 | 3 | **2** |
| toplu is sozlesmesi kurallari | 2 | 2 | 1 | 0 | 3 | **2** |
| isletme toplu is sozlesmesi | 2 | 2 | 1 | 0 | 3 | **2** |
| fazla calisma | 2 | 2 | 2 | 0 | 3 | **1** |
| is kazasi meslek hastaligi | 2 | 2 | 2 | 0 | 3 | **1** |
| belirli sureli is sozlesmesi | 2 | 2 | 2 | 0 | 3 | **1** |
| isyeri devri | 2 | 2 | 2 | 0 | 3 | **1** |
| is kazasi sigortasi | 2 | 2 | 2 | 0 | 3 | **1** |
| gecici is iliskisi | 2 | 2 | 2 | 0 | 3 | **1** |
| grev lokavt | 2 | 2 | 2 | 0 | 3 | **1** |
| is kazasi malulluk orani | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortalilik | 1 | 1 | 0 | 0 | 2 | **2** |
| grev-lokavtta is sozlesmesinin askida kalmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika uyeligi kurallari (issizlik 1 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret yonetmeligi (ortaklik payi yasagi) | 1 | 1 | 0 | 0 | 2 | **2** |
| yillik izin zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortaliligin sona ermesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika toplu is sozlesmesi yetkisi (%1) | 1 | 1 | 0 | 0 | 2 | **2** |
| belirli belirsiz sureli is sozlesmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika uyeligi kazanilmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| sosyal sigortalar sigortali sayilma | 1 | 1 | 0 | 0 | 2 | **2** |
| is sozlesmesi feshi alacaklari | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplu is sozlesmesi yararlanma | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortalilik hali | 1 | 1 | 0 | 0 | 2 | **2** |
| satis sozlesmesi zapttan sorumluluk | 1 | 1 | 0 | 0 | 2 | **2** |
| grev lokavt erteleme | 1 | 1 | 0 | 0 | 2 | **2** |
| is kazasi-meslek hastaligi saglanan haklar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 42 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ticaret Hukuku — 121 konu, 234 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| genel islem kosullari | 9 | 9 | 5 | 0 | 12 | **7** |
| cek zorunlu unsurlari | 5 | 5 | 3 | 2 | 8 | **3** |
| bono zorunlu unsurlari | 4 | 4 | 2 | 0 | 6 | **4** |
| ticari temsilci yetkisi | 4 | 4 | 3 | 1 | 6 | **2** |
| ticari is kavrami | 3 | 3 | 2 | 1 | 5 | **2** |
| cek hukuku | 3 | 3 | 3 | 0 | 5 | **2** |
| cek odeme kontrolu | 2 | 2 | 0 | 0 | 3 | **3** |
| anonim sirket sona erme | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| sirket birlesmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari orf ve adet | 2 | 2 | 1 | 0 | 3 | **2** |
| ticaret sicili itiraz | 2 | 2 | 1 | 0 | 3 | **2** |
| haksiz rekabet ve reklam yasagi | 2 | 2 | 1 | 0 | 3 | **2** |
| ticari isletme unsurlari | 2 | 2 | 1 | 0 | 3 | **2** |
| tacir kavrami | 2 | 2 | 2 | 0 | 3 | **1** |
| limited sirket sermayesi | 2 | 2 | 1 | 1 | 3 | **1** |
| bono unsurlari | 2 | 2 | 2 | 0 | 3 | **1** |
| kambiyo senetleri | 2 | 2 | 2 | 0 | 3 | **1** |
| anonim sirket genel kurulu | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket genel kurul | 1 | 1 | 0 | 0 | 2 | **2** |
| bonoya uygulanmayan police hukumleri (kabul) | 1 | 1 | 0 | 0 | 2 | **2** |
| reklam yoluyla haksiz rekabet halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket butlan davasi | 1 | 1 | 0 | 0 | 2 | **2** |
| bono cirosu | 1 | 1 | 0 | 0 | 2 | **2** |
| tacir esnaf hukumleri | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket kurulus sozlesmeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket sermaye odeme | 1 | 1 | 0 | 0 | 2 | **2** |
| aval (kambiyo teminati) | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret sicili | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirkete ayni sermaye olabilecekler | 1 | 1 | 0 | 0 | 2 | **2** |
| cek kurallari (vade kaydi) | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket ortak sayisi (1-50) | 1 | 1 | 0 | 0 | 2 | **2** |
| pay senedi getirisi | 1 | 1 | 0 | 0 | 2 | **2** |
| bono on yuzunde imza (aval) | 1 | 1 | 0 | 0 | 2 | **2** |
| cek hukumleri | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet ve reklam yasagi yonetmeligi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket yonetim kurulu temsil | 1 | 1 | 0 | 0 | 2 | **2** |
| cek ibraz ve duzenleme tarihi | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket sermaye payi | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket genel kurul yetkileri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 81 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi (ayristirilamadi) — 76 konu, 148 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| tuketici tercih aksiyomlari | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet denge uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi ozellikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| carpan etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi kaymasi | 1 | 1 | 0 | 0 | 2 | **2** |
| kredi tayinlamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisler hipotezi | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet piyasa dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| zaman tutarsizligi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopolcu rekabet | 1 | 1 | 0 | 0 | 2 | **2** |
| optimal emek talebi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol piyasasi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopson emek piyasasi | 1 | 1 | 0 | 0 | 2 | **2** |
| heckscher-ohlin modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| uclu acmaz | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisli makro modeller | 1 | 1 | 0 | 0 | 2 | **2** |
| cobb-douglas ikame esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| pigou etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tercihlerin butunlugu varsayimi | 1 | 1 | 0 | 0 | 2 | **2** |
| j egrisi (devaluasyon-net ihracat) | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ikame mallar kose dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| yeni klasik model | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol fiyat farklilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| piyasa denge fiyati | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici fazlasi degisimi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam fayda doyum noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| trampa ekonomisi fiyat sayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| ricardo modeli varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercihleri konvekslik | 1 | 1 | 0 | 0 | 2 | **2** |
| alman merkantilizmi | 1 | 1 | 0 | 0 | 2 | **2** |
| isci yanilma modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tahvil piyasasi servet etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci firma fiyat belirleme | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| tarife disi ticaret engelleri | 1 | 1 | 0 | 0 | 2 | **2** |
| klasik model | 1 | 1 | 0 | 0 | 2 | **2** |
| mundell-fleming modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tamamlayici mallar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 36 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Hukuk (ayristirilamadi) — 155 konu, 309 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| defter belge teslimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret unvani kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| sosyal guvenlik ayligi | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri bildirgesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret gelirinin kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari hukum | 1 | 1 | 0 | 0 | 2 | **2** |
| etik yakinlik tehditleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ozen (olagan sebep) sorumlulugu halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sirket ortaklarinin sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| asiri yararlanma (gabin) | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler (bagimsiz calisanlar) | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari faaliyet yasagi cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| 4/1-a kapsaminda sayilanlar | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret odeme kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| ayirt etme gucunun gecici kaybi sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| kesin hukumsuzluk-iptal sebepleri ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| 4857 kapsami disindaki isler | 1 | 1 | 0 | 0 | 2 | **2** |
| 4857 kapsam disi istisnalar | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tesvik | 1 | 1 | 0 | 0 | 2 | **2** |
| hakli savunma | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek odalari yonetmeligi | 1 | 1 | 0 | 0 | 2 | **2** |
| mecburi meslek karari | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler yakinlik tehdidi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek ile bagdasan isler | 1 | 1 | 0 | 0 | 2 | **2** |
| kutukten silinme halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tehdit | 1 | 1 | 0 | 0 | 2 | **2** |
| tur degistirme | 1 | 1 | 0 | 0 | 2 | **2** |
| is akdi feshi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslekle bagdasan isler | 1 | 1 | 0 | 0 | 2 | **2** |
| engelli istihdam yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| asiri yararlanma | 1 | 1 | 0 | 0 | 2 | **2** |
| irade beyan uygunsuzlugu | 1 | 1 | 0 | 0 | 2 | **2** |
| harclar kanunu | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma-dinlenme sureleri (tatil calismasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret kurallari (mevduat faizi) | 1 | 1 | 0 | 0 | 2 | **2** |
| yanilma-hata | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri devri sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| azinlik haklari | 1 | 1 | 0 | 0 | 2 | **2** |
| kisisel cikar tehditleri | 1 | 1 | 0 | 0 | 2 | **2** |
| yersiz odeme geri istem | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 115 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebe (ayristirilamadi) — 210 konu, 408 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| duzenleyici hesaplarin tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| nakit esasi ve donemsellik kavrami | 1 | 1 | 0 | 0 | 2 | **2** |
| tutarlilik kavrami (politika degisikligi) | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz degerleme | 1 | 1 | 0 | 0 | 2 | **2** |
| yenileme fonu kullanimdan vazgecme | 1 | 1 | 0 | 0 | 2 | **2** |
| anomali tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| raporlama standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| borca mahsuben odeme karisik kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| ifac organizasyonlari | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynaklar hesaplari | 1 | 1 | 0 | 0 | 2 | **2** |
| muhasebe bilgi sistemi ilkeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| musteri kabulu asamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| ihtiyatlilik kavrami (yedek akce) | 1 | 1 | 0 | 0 | 2 | **2** |
| sorgulama tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| aktif duzenleyici hesaplar | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi muhasebe kuruluslari (ifac) | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi standart kuruluslari | 1 | 1 | 0 | 0 | 2 | **2** |
| kismi kredili satis kayitlari | 1 | 1 | 0 | 0 | 2 | **2** |
| alacaklara ait uygunluk testleri | 1 | 1 | 0 | 0 | 2 | **2** |
| geri kazanilabilir tutar | 1 | 1 | 0 | 0 | 2 | **2** |
| kademeli dagitim gug toplami | 1 | 1 | 0 | 0 | 2 | **2** |
| ara donem raporlama | 1 | 1 | 0 | 0 | 2 | **2** |
| istirak muhasebesi | 1 | 1 | 0 | 0 | 2 | **2** |
| gkgd standartlari kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| demirbas alimi karisik odeme kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| defter turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| menkul kiymet uygunluk testi | 1 | 1 | 0 | 0 | 2 | **2** |
| fatura yerine gecen belgeler | 1 | 1 | 0 | 0 | 2 | **2** |
| nakit akis faaliyet siniflamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ipsasb uluslararasi kurulus | 1 | 1 | 0 | 0 | 2 | **2** |
| gecmis yil zarari yedeklerden mahsup | 1 | 1 | 0 | 0 | 2 | **2** |
| ortaga kredili satis (alicilar) | 1 | 1 | 0 | 0 | 2 | **2** |
| blok secim yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal risk duzeyi unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| hilede ongorulemezlik | 1 | 1 | 0 | 0 | 2 | **2** |
| kayit sisteminin izlenmesi teknigi | 1 | 1 | 0 | 0 | 2 | **2** |
| asli-duzenleyici hesap ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| risk degerlendirme sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| oran standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| faaliyet giderleri gruplamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 170 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye (ayristirilamadi) — 42 konu, 84 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| leviathan modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| formul esnekligi yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| tanzi etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc itfa yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| operasyonel acik hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu giderleri siniflandirma | 1 | 1 | 0 | 0 | 2 | **2** |
| egemenlik gucune dayanan gelirler | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer harcamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| mali yanilsama modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| borc senedi ihrac turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer harcamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| merkantalizm | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu mallari samuelson modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| mali somuru | 1 | 1 | 0 | 0 | 2 | **2** |
| devlet gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| disliyici etki | 1 | 1 | 0 | 0 | 2 | **2** |
| uygunluk ilkesi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari harcamalar | 1 | 1 | 0 | 0 | 2 | **2** |
| borc servis orani | 1 | 1 | 0 | 0 | 2 | **2** |
| lorenz egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| borc yonetimi | 1 | 1 | 0 | 0 | 2 | **2** |
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
| keynezyen yaklasim | 1 | 1 | 0 | 0 | 2 | **2** |
| transfer-gercek harcama ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| dislama etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 2 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

## 4 · BEKLEYEN HAT — simdilik basilmayacak

Cem karari (11.09): bu dersler **sonraya**. 555 konu · 1.324 soru · 8.685 TL.

| Ders | Acik konu | Acik soru |
|---|---:|---:|
| Genel Kultur-Genel Yetenek (ayristirilamadi) | 150 | 299 |
| Turkce | 79 | 222 |
| Yabanci Dil | 71 | 215 |
| Matematik | 73 | 212 |
| Matematik-Istatistik (ayristirilamadi) | 104 | 205 |
| Yabanci Dil (ayristirilamadi) | 57 | 113 |
| Ataturk Ilke ve Inkilap Tarihi | 21 | 58 |

En cok cikan bekleyen konular (hat acildiginda ilk bunlar basilir):

| Ders | Konu | Cikmis | Bizde | BASILACAK |
|---|---|---:|---:|---:|
| Yabanci Dil | cumle tamamlama | 51 | 9 | 3 |
| Turkce | yazim kurallari | 17 | 4 | 8 |
| Turkce | noktalama isaretleri | 16 | 4 | 8 |
| Turkce | anlatim bozuklugu | 15 | 6 | 6 |
| Yabanci Dil | kelime bilgisi | 14 | 4 | 8 |
| Yabanci Dil | sentence completion | 9 | 4 | 8 |
| Matematik | denklem cozme | 9 | 5 | 7 |
| Turkce | ses olaylari | 8 | 3 | 9 |
| Turkce | sozcukte anlam | 8 | 3 | 9 |
| Matematik | yas problemi | 7 | 0 | 11 |
| Yabanci Dil | cumle tamamlama-kosul | 7 | 5 | 6 |
| Yabanci Dil | kelime tamamlama | 7 | 0 | 11 |
| Matematik | belirli integral | 6 | 1 | 8 |
| Ataturk Ilke ve Inkilap Tarihi | lozan antlasmasi | 6 | 0 | 9 |
| Matematik | seri toplami | 6 | 1 | 8 |

## 5 · KOPRUDE KARSILIGI OLMAYAN KONULARIMIZ

Ürettigimiz sorularin **1**'i, cikmis arsivde karsiligi olmayan **1** konuya ait.
Bu konular ya cikmis arsivde hic sorulmadi ya da konu ADI koprudekinden farkli yazildi.
Ikincisi ise olcum hatasidir — asagidaki ilk 25 ad elle gozden gecirilmeli.

| Konu (bizde) | Soru |
|---|---:|
| ic kontrol ic denetim | 1 |

