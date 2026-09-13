# KONU PLANI — STAJA BAŞLAMA (SGS)

> Uretim: **13.09.2026 07:08** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.238 konu** var. Bunlarin **2.560**'inde elimizde soru YETERSIZ; toplam **5.253 soru** basilacak. Su an bu konularda **3.220** saglam sorumuz var.

## 0a · IKI HAT — Cem karari (11.09)

> *"matematik, ingilizce ve baska ne varsa sozel beklesin; digerlerini bir bitirelim sonra bunlara donelim"*

| Hat | Ders | Konu | Soru | Bedel (toplu) |
|---|---|---:|---:|---:|
| **SIMDI** | Alan Bilgisi (muhasebe · denetim · hukuk · ekonomi · maliye) | **1.994** | **3.825** | **25.092 TL** |
| BEKLESIN | Matematik · Yabanci Dil · Turkce · Inkilap · Genel Kultur | 566 | 1.428 | 9.368 TL |

Bekleyen hat mevzuata dayanmaz; kaynak paketi mantigi (ambardan madde cekme)
orada islemez, ayri bir hat gerektirir. 08.09'da da ayni sebeple Tur 1 disinda kalmislardi.
**Asagidaki butun tablolar SIMDI hattini gosterir**; bekleyen hat bolum 4'te ayri durur.

## 0b · BEDEL ve ONCELIK — SIMDI hatti

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 5 | 12 | 157 TL | 79 TL |
| 2 · kritik | cikmis >= 5 | 38 | 142 | 1.863 TL | 932 TL |
| 3 · onemli | cikmis >= 3 | 125 | 342 | 4.487 TL | 2.244 TL |
| 4 · orta | cikmis >= 2 | 256 | 569 | 7.465 TL | 3.733 TL |
| 5 · tamami | cikmis >= 1 | 1.994 | 3.825 | 50.184 TL | 25.092 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 585 | 849 | 1.503 | **752** | 410 |
| Denetim | 16 | 361 | 560 | 884 | **445** | 244 |
| Maliyet Muhasebesi | 8 | 213 | 316 | 530 | **256** | 144 |
| Mali Tablolar Analizi | 8 | 115 | 164 | 315 | **167** | 84 |
| Maliye | 6 | 104 | 99 | 239 | **165** | 83 |
| Ekonomi | 6 | 90 | 97 | 213 | **122** | 69 |
| Vergi Hukuku | 6 | 161 | 146 | 369 | **258** | 126 |
| Meslek Hukuku | 6 | 82 | 74 | 228 | **155** | 72 |
| Borclar Hukuku | 6 | 106 | 175 | 293 | **143** | 68 |
| Is ve Sosyal Guvenlik Hukuku | 6 | 99 | 116 | 272 | **160** | 82 |
| Ticaret Hukuku | 6 | 159 | 185 | 396 | **244** | 124 |
| Ekonomi (ayristirilamadi) | — | 83 | 23 | 167 | **148** | 76 |
| Hukuk (ayristirilamadi) | — | 175 | 47 | 351 | **319** | 161 |
| Muhasebe (ayristirilamadi) | — | 234 | 78 | 469 | **407** | 209 |
| Maliye (ayristirilamadi) | — | 45 | 8 | 90 | **84** | 42 |
| **TOPLAM** | **130** | **3.238** | **3.220** | | **5.253** | **2.560** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 410 konu, 752 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| muhasebe bilgi sistemi | 10 | 10 | 9 | 0 | 12 | **3** |
| nakit akis tablosu | 8 | 7 | 11 | 0 | 12 | **1** |
| tms 40 yatirim amacli gayrimenkul | 8 | 8 | 10 | 1 | 12 | **1** |
| hisse senedi satisi | 7 | 7 | 5 | 0 | 11 | **6** |
| tms 37 karsiliklar | 7 | 7 | 5 | 0 | 11 | **6** |
| tms 36 deger dusuklugu | 7 | 7 | 7 | 0 | 11 | **4** |
| gider tahakkuku | 7 | 7 | 9 | 0 | 11 | **2** |
| sermaye artirimi | 7 | 7 | 8 | 1 | 11 | **2** |
| tms 38 maddi olmayan duran varlik | 6 | 6 | 6 | 0 | 9 | **3** |
| kar dagitimi kaydi | 5 | 5 | 7 | 0 | 8 | **1** |
| donemsellik kavrami | 5 | 5 | 7 | 0 | 8 | **1** |
| tutarlilik kavrami | 4 | 4 | 1 | 1 | 6 | **4** |
| yasal yedek akce | 4 | 4 | 3 | 0 | 6 | **3** |
| stok deger dusuklugu | 4 | 4 | 4 | 0 | 6 | **2** |
| gelecek aylara ait giderler | 4 | 4 | 5 | 0 | 6 | **1** |
| tms 28 istirakler | 4 | 4 | 5 | 0 | 6 | **1** |
| depozito iadesi kaydi | 4 | 4 | 5 | 0 | 6 | **1** |
| kasa sayim farki | 4 | 4 | 5 | 0 | 6 | **1** |
| nazim hesaplar | 3 | 3 | 0 | 0 | 5 | **5** |
| donem kari hesaplama | 3 | 3 | 2 | 0 | 5 | **3** |
| fifo yontemi | 3 | 3 | 2 | 0 | 5 | **3** |
| kidem tazminati | 3 | 3 | 3 | 0 | 5 | **2** |
| kesin mizan | 3 | 3 | 4 | 0 | 5 | **1** |
| onemlilik kavrami | 3 | 3 | 4 | 0 | 5 | **1** |
| depozitolu kap kirilmasi kaydi | 3 | 3 | 4 | 0 | 5 | **1** |
| tms-38 maddi olmayan duran varliklar | 3 | 3 | 4 | 0 | 5 | **1** |
| tms 10 raporlama sonrasi olaylar | 3 | 3 | 4 | 0 | 5 | **1** |
| hazine bonosu tahsili | 3 | 3 | 4 | 0 | 5 | **1** |
| tahvil ihraci | 3 | 3 | 4 | 0 | 5 | **1** |
| duzenleyici hesaplar | 2 | 2 | 0 | 0 | 3 | **3** |
| toplulastirma riski | 2 | 2 | 0 | 0 | 3 | **3** |
| akreditif kaydi | 2 | 2 | 0 | 0 | 3 | **3** |
| tfrs 9 finansal yukumluluk olcumu | 2 | 2 | 0 | 0 | 3 | **3** |
| oz kaynak toplami hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| ortalama tahsilat suresi | 2 | 2 | 0 | 1 | 3 | **2** |
| tms 40 gayrimenkul | 2 | 1 | 1 | 0 | 3 | **2** |
| maddi duran varlik dogruluk testi | 2 | 1 | 1 | 0 | 3 | **2** |
| iasb calismalari | 2 | 2 | 0 | 1 | 3 | **2** |
| zorunlu karsilik orani | 2 | 2 | 1 | 0 | 3 | **2** |
| finansal tablolar | 2 | 2 | 1 | 0 | 3 | **2** |
| _… 370 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Denetim — 244 konu, 445 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim kaniti yeterliligi | 11 | 9 | 10 | 0 | 12 | **2** |
| denetim kaniti guvenilirligi | 8 | 7 | 10 | 0 | 12 | **2** |
| denetim riski | 6 | 5 | 1 | 0 | 9 | **8** |
| kasa denetimi | 5 | 5 | 4 | 0 | 8 | **4** |
| denetim kanitlari | 5 | 5 | 5 | 0 | 8 | **3** |
| denetim calisma kagitlari | 5 | 5 | 7 | 0 | 8 | **1** |
| iliskili taraflar denetimi | 4 | 4 | 5 | 0 | 6 | **1** |
| stok sayimi denetimi | 4 | 4 | 5 | 0 | 6 | **1** |
| ic kontrol sistemi | 4 | 4 | 5 | 0 | 6 | **1** |
| yonetim beyanlari | 3 | 3 | 2 | 0 | 5 | **3** |
| denetim belgelendirme | 3 | 3 | 2 | 0 | 5 | **3** |
| bagimsiz denetim sureci | 3 | 3 | 2 | 0 | 5 | **3** |
| denetim planlamasi | 3 | 3 | 2 | 0 | 5 | **3** |
| maddi duran varlik denetimi | 3 | 3 | 3 | 0 | 5 | **2** |
| kanit guvenilirligi | 3 | 3 | 4 | 0 | 5 | **1** |
| yonetim iddialari | 3 | 3 | 4 | 0 | 5 | **1** |
| is guvencesi | 3 | 3 | 4 | 0 | 5 | **1** |
| dikkat cekilen hususlar paragrafi | 3 | 3 | 4 | 0 | 5 | **1** |
| stok denetimi | 3 | 2 | 4 | 0 | 5 | **1** |
| denetim gorusu turleri | 3 | 3 | 4 | 0 | 5 | **1** |
| yapisal risk faktorleri | 3 | 3 | 4 | 0 | 5 | **1** |
| guvence hizmetleri | 3 | 3 | 4 | 0 | 5 | **1** |
| maddi olmayan duran varlik denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| uluslararasi muhasebe kuruluslari | 2 | 2 | 0 | 1 | 3 | **2** |
| finansal tablo iddialari | 2 | 2 | 1 | 0 | 3 | **2** |
| denetci gorusu | 2 | 2 | 2 | 0 | 3 | **1** |
| kamu alacagi guvence onlemleri | 2 | 2 | 2 | 0 | 3 | **1** |
| denetci raporu bolumleri | 2 | 2 | 2 | 0 | 3 | **1** |
| analitik prosedur | 2 | 2 | 2 | 0 | 3 | **1** |
| ucuncu taraf stok denetimi | 2 | 2 | 2 | 0 | 3 | **1** |
| onemlilik kavrami denetim | 2 | 2 | 2 | 0 | 3 | **1** |
| denetim kaniti uygunlugu | 2 | 2 | 2 | 0 | 3 | **1** |
| dis teyit prosedurleri | 2 | 2 | 2 | 0 | 3 | **1** |
| kontrol cevresi unsurlari | 2 | 2 | 0 | 2 | 3 | **1** |
| kanit yeterliligi unsurlari | 2 | 2 | 2 | 0 | 3 | **1** |
| baslangic analitik prosedur amaclari | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim etik ilkeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| hile riski (hasilat) | 1 | 1 | 0 | 0 | 2 | **2** |
| bds 240 firsat faktoru | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim tamamlama raporlama | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 204 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliyet Muhasebesi — 144 konu, 256 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ortak maliyet dagitimi | 13 | 13 | 11 | 0 | 12 | **1** |
| siparis maliyet sistemi | 7 | 7 | 10 | 0 | 11 | **1** |
| evre maliyet sistemi | 5 | 5 | 5 | 0 | 8 | **3** |
| satilan mamul maliyeti | 5 | 5 | 7 | 0 | 8 | **1** |
| ekonomik siparis miktari | 3 | 3 | 0 | 0 | 5 | **5** |
| standart maliyet farklari | 3 | 3 | 4 | 0 | 5 | **1** |
| birlesik maliyet dagitimi | 3 | 3 | 4 | 0 | 5 | **1** |
| ozel maliyet amortismani | 2 | 2 | 1 | 0 | 3 | **2** |
| birlesik maliyet satis degeri yontemi | 2 | 2 | 1 | 0 | 3 | **2** |
| safha maliyetleme | 2 | 2 | 1 | 0 | 3 | **2** |
| gug birim pay hesabi | 2 | 2 | 1 | 0 | 3 | **2** |
| direkt ilk madde geriye dogru hesap | 2 | 2 | 2 | 0 | 3 | **1** |
| maliyet yontemleri karsilastirma | 2 | 2 | 2 | 0 | 3 | **1** |
| maliyet fonksiyonu | 2 | 2 | 2 | 0 | 3 | **1** |
| gider yeri dagitimi | 2 | 2 | 2 | 0 | 3 | **1** |
| birim uretim maliyeti | 2 | 2 | 2 | 0 | 3 | **1** |
| basabas noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| aralikli sayim satilan mal maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| esdeger birim hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| stok maliyet yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ve degisken maliyet sistemi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyetler kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| aralikli envanter satilan mal maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| artan firsat maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| satilan mamul maliyeti tablosu | 1 | 1 | 0 | 0 | 2 | **2** |
| siparise dusen direkt iscilik hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| siparis maliyetinde gug yukleme orani | 1 | 1 | 0 | 0 | 2 | **2** |
| maliyet ve otomasyon sistemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| basabas noktasi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel siparis karari | 1 | 1 | 0 | 0 | 2 | **2** |
| hareketli ortalama maliyet yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| normal-tam maliyet birim farki | 1 | 1 | 0 | 0 | 2 | **2** |
| kiralanan varlige asansor (ozel maliyet) kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| degisken maliyet katki payi | 1 | 1 | 0 | 0 | 2 | **2** |
| genel uretim gideri ikramiye tahakkuku | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyet | 1 | 1 | 0 | 0 | 2 | **2** |
| tam maliyet birim gug hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel maliyet gideri | 1 | 1 | 0 | 0 | 2 | **2** |
| ortalama maliyet tamamlanma derecesi | 1 | 1 | 0 | 0 | 2 | **2** |
| tam maliyet sistemi brut kâr | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 104 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Mali Tablolar Analizi — 84 konu, 167 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| dikey yuzde analizi | 12 | 11 | 11 | 0 | 12 | **1** |
| net isletme sermayesi | 9 | 8 | 3 | 0 | 12 | **9** |
| yatay analiz | 8 | 8 | 8 | 0 | 12 | **4** |
| aktif devir hizi | 8 | 8 | 9 | 1 | 12 | **2** |
| cari oran analizi | 6 | 6 | 1 | 0 | 9 | **8** |
| stok devir hizi | 6 | 6 | 6 | 0 | 9 | **3** |
| asit-test orani | 4 | 4 | 3 | 0 | 6 | **3** |
| cari oran hesaplama | 4 | 4 | 5 | 0 | 6 | **1** |
| dikey analiz | 3 | 3 | 4 | 0 | 5 | **1** |
| piyasa degeri-defter degeri orani | 2 | 2 | 0 | 0 | 3 | **3** |
| finansal oran analizi | 2 | 2 | 0 | 0 | 3 | **3** |
| stokta kalma suresi hesabi | 2 | 2 | 1 | 0 | 3 | **2** |
| dikey yuzdelerden bilanco yorumu | 2 | 2 | 1 | 0 | 3 | **2** |
| alacak devir hizi | 2 | 2 | 1 | 0 | 3 | **2** |
| standart oranlar | 2 | 2 | 2 | 0 | 3 | **1** |
| dikey yuzdelerden oz kaynak-aktif | 2 | 2 | 2 | 0 | 3 | **1** |
| finansal oranlar | 2 | 2 | 2 | 0 | 3 | **1** |
| yuzde degisim analizi | 2 | 2 | 2 | 0 | 3 | **1** |
| likidite orani | 2 | 2 | 2 | 0 | 3 | **1** |
| mali tablo analiz teknikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak kârlilik orani | 1 | 1 | 0 | 0 | 2 | **2** |
| sektorel oran analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| trend (yatay) analiz teknigi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac orani hesabi (borc-ozsermaye) | 1 | 1 | 0 | 0 | 2 | **2** |
| dikey yuzde ve duran varlik oraniyla donen varlik | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran borc ozsermaye | 1 | 1 | 0 | 0 | 2 | **2** |
| oran analizi karsilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| olagan kar analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari orani artiran islemler | 1 | 1 | 0 | 0 | 2 | **2** |
| yatay analiz kar marji | 1 | 1 | 0 | 0 | 2 | **2** |
| brut kar analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaldirac siniriyla kredi kapasitesi | 1 | 1 | 0 | 0 | 2 | **2** |
| devir hizi ve kaldiractan oz kaynak | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynak degisimi analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| net isletme sermayesi negatif kosulu | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran-asit test hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran | 1 | 1 | 0 | 0 | 2 | **2** |
| net isletme sermayesi hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| brut karlilik orani | 1 | 1 | 0 | 0 | 2 | **2** |
| cari oran asit test orani | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 44 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye — 83 konu, 165 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| laffer egrisi | 4 | 4 | 0 | 5 | 6 | **1** |
| kamu harcamalari artis nedenleri | 3 | 3 | 0 | 0 | 5 | **5** |
| wagner yasasi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi tarifesi | 2 | 2 | 0 | 0 | 3 | **3** |
| kamu borc yonetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| otomatik istikrarlandirici | 2 | 2 | 1 | 0 | 3 | **2** |
| parafiskal gelirler | 2 | 2 | 2 | 0 | 3 | **1** |
| artan oranli vergi | 2 | 2 | 2 | 0 | 3 | **1** |
| vergi yansimasi | 2 | 2 | 2 | 0 | 3 | **1** |
| enflasyonist acik maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kanunu teklifi | 1 | 1 | 0 | 0 | 2 | **2** |
| mundell-fleming sabit kur maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi entegrasyon yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| cebre dayanan kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sabit kurda maliye politikasi etkinligi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi tarifesi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| saf kamusal mal uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| butce dengesi kamu maliyesi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu gelirleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin karar etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu borc tahvilleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu geliri turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye giderleri (butce siniflamasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| butce kapatma usulu | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamasi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| stagflasyonda maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| dolayli vergi kaldirilmasinin yansimasi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliye politikasi amaclari (ekonomik istikrar) | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi oranlilik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| verginin yansima asamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalarinda gercek-gorunuste artis | 1 | 1 | 0 | 0 | 2 | **2** |
| butce acigi turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| durgunlukta maliye politikasi | 1 | 1 | 0 | 0 | 2 | **2** |
| duz oranli vergi grafigi | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi harcamasi hesaplama yontemleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kamu harcamalari artis teorisi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 43 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi — 69 konu, 122 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| talep esnekligi | 4 | 4 | 5 | 0 | 6 | **1** |
| taylor prensibi | 3 | 3 | 4 | 0 | 5 | **1** |
| marjinal fayda | 3 | 3 | 4 | 0 | 5 | **1** |
| para politikasi araclari | 3 | 3 | 4 | 0 | 5 | **1** |
| tuketim fonksiyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| gresham kanunu | 2 | 2 | 0 | 0 | 3 | **3** |
| tuketici fazlasi | 2 | 2 | 0 | 0 | 3 | **3** |
| yeni keynesyen model | 2 | 2 | 0 | 0 | 3 | **3** |
| likidite tuzagi | 2 | 2 | 1 | 0 | 3 | **2** |
| tuketim duzlestirmesi | 2 | 2 | 1 | 0 | 3 | **2** |
| mukayeseli ustunluk firsat maliyeti | 2 | 2 | 2 | 0 | 3 | **1** |
| keynesyen tuketim fonksiyonu | 2 | 2 | 2 | 0 | 3 | **1** |
| paranin yansizligi | 2 | 2 | 2 | 0 | 3 | **1** |
| taylor kurali | 2 | 2 | 2 | 0 | 3 | **1** |
| cari islemler hesabi | 2 | 2 | 2 | 0 | 3 | **1** |
| talep/fiyat esnekligi kâr analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| doymazlik varsayimi marjinal fayda | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz kuru sterilizasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| leontief uretim fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim fonksiyonu ikame esnekligi (dogrusal) | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik turleri hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda maksimizasyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci rekabet dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| issizlik istihdam hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| j egrisi devaluasyon | 1 | 1 | 0 | 0 | 2 | **2** |
| bilanco talep haklari | 1 | 1 | 0 | 0 | 2 | **2** |
| enflasyon olcum sapmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam talep uzun donem denge | 1 | 1 | 0 | 0 | 2 | **2** |
| talep kanunu | 1 | 1 | 0 | 0 | 2 | **2** |
| phillips egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| gsyh hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| gsyh harcama yaklasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| tasarruf paradoksu | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet uretim durdurma | 1 | 1 | 0 | 0 | 2 | **2** |
| emek arz egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| arz talep esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam arz egrileri (keynesyen) | 1 | 1 | 0 | 0 | 2 | **2** |
| faiz orani ust siniri | 1 | 1 | 0 | 0 | 2 | **2** |
| dogal issizlik turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz arz egrisi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 29 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Vergi Hukuku — 126 konu, 258 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| damga vergisi | 5 | 5 | 4 | 0 | 8 | **4** |
| kdv vergiyi doguran olay | 4 | 4 | 2 | 0 | 6 | **4** |
| transfer fiyatlandirmasi | 3 | 3 | 0 | 0 | 5 | **5** |
| vuk degerleme olculeri | 3 | 3 | 0 | 0 | 5 | **5** |
| ozel tuketim vergisi | 3 | 3 | 0 | 0 | 5 | **5** |
| kurumlar vergisi mukellefleri | 3 | 3 | 4 | 0 | 5 | **1** |
| kurumlar vergisi indirimleri | 2 | 2 | 0 | 0 | 3 | **3** |
| verginin kapitalizasyonu | 2 | 2 | 0 | 0 | 3 | **3** |
| ihtiyati hacze itiraz suresi (15 gun) | 2 | 2 | 0 | 0 | 3 | **3** |
| vuk kapsami | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi zarar mahsubu (5 yil) | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv matrah | 2 | 2 | 1 | 0 | 3 | **2** |
| tahakkuk esasi | 2 | 2 | 1 | 0 | 3 | **2** |
| kurumlar vergisi istisnalari | 2 | 2 | 1 | 0 | 3 | **2** |
| asgari kurumlar vergisi | 2 | 2 | 1 | 0 | 3 | **2** |
| vergilemede etkinlik | 2 | 2 | 0 | 1 | 3 | **2** |
| vergi cezalari | 2 | 2 | 1 | 0 | 3 | **2** |
| kdv indirimi | 2 | 2 | 2 | 0 | 3 | **1** |
| kdv kapsami | 2 | 2 | 2 | 0 | 3 | **1** |
| vergi incelemesi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| bakanlar kurulu vergi yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset ve intikal vergisi istisnalari | 1 | 1 | 0 | 0 | 2 | **2** |
| munferit beyanname | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi cezasi yanilma | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tevkifat | 1 | 1 | 0 | 0 | 2 | **2** |
| odeme emrine dava acma suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv indirim hakki | 1 | 1 | 0 | 0 | 2 | **2** |
| konaklama vergisi orani (%2) | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv konusu | 1 | 1 | 0 | 0 | 2 | **2** |
| veraset ve intikal vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| dijital hizmet vergisi beyani | 1 | 1 | 0 | 0 | 2 | **2** |
| ikramiye tahakkuku | 1 | 1 | 0 | 0 | 2 | **2** |
| kurumlar vergisi matrahi | 1 | 1 | 0 | 0 | 2 | **2** |
| degerli konut vergisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kdv tevkifati | 1 | 1 | 0 | 0 | 2 | **2** |
| otv kapsaminda vergi ziyai | 1 | 1 | 0 | 0 | 2 | **2** |
| harcama vergileri | 1 | 1 | 0 | 0 | 2 | **2** |
| tarh zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| vuk tekerrur | 1 | 1 | 0 | 0 | 2 | **2** |
| damga vergisi nusha | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 86 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Meslek Hukuku — 72 konu, 155 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| disiplin cezalari | 11 | 11 | 7 | 0 | 12 | **5** |
| meslek etik ilkeleri | 9 | 9 | 2 | 0 | 12 | **10** |
| haksiz rekabet reklam yasagi | 7 | 7 | 6 | 0 | 11 | **5** |
| meslek mensubu ucret esaslari | 3 | 3 | 0 | 0 | 5 | **5** |
| reklam yasagi | 3 | 3 | 0 | 0 | 5 | **5** |
| sir saklama yukumlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| mesleki etik ilkeler | 3 | 3 | 2 | 0 | 5 | **3** |
| buro edinme zorunlulugu | 3 | 3 | 3 | 0 | 5 | **2** |
| disiplin yonetmeligi | 3 | 3 | 3 | 0 | 5 | **2** |
| smmm disiplin cezalari | 3 | 2 | 4 | 0 | 5 | **1** |
| serbest meslek kazanci | 3 | 3 | 4 | 0 | 5 | **1** |
| calisma usul esaslari | 2 | 2 | 1 | 0 | 3 | **2** |
| oda organlari gorevleri | 2 | 2 | 1 | 0 | 3 | **2** |
| smmm odalari | 2 | 2 | 1 | 0 | 3 | **2** |
| etik ilkeler tehditler | 2 | 2 | 2 | 0 | 3 | **1** |
| uyarma cezasi halleri | 2 | 2 | 2 | 0 | 3 | **1** |
| disiplin kovusturmasi | 2 | 2 | 2 | 0 | 3 | **1** |
| disiplin yonetmeligi itiraz | 1 | 1 | 0 | 0 | 2 | **2** |
| oda genel kurulu yetkileri | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek disiplin cezalari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek ucret tarifesi | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun meslek konusu | 1 | 1 | 0 | 0 | 2 | **2** |
| ymm sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu genel sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun birlik | 1 | 1 | 0 | 0 | 2 | **2** |
| 3568 sayili kanun-odalar | 1 | 1 | 0 | 0 | 2 | **2** |
| birlik (turmob) kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| tabela asilmasi kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm olabilmenin ozel sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma usul ve esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu ticari faaliyet yasagi | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek hukuku oda organlari | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu silinme halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm ucret esaslari | 1 | 1 | 0 | 0 | 2 | **2** |
| smmm oda yapisi | 1 | 1 | 0 | 0 | 2 | **2** |
| staj suresi (3568 sayili kanun) | 1 | 1 | 0 | 0 | 2 | **2** |
| unvan kullanma cezasi (6 ay-1 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek mensubu olmayi engelleyen haller | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 32 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Borclar Hukuku — 68 konu, 143 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sebepsiz zenginlesme | 8 | 8 | 6 | 0 | 12 | **6** |
| sozlesme sekli | 5 | 5 | 1 | 0 | 8 | **7** |
| haksiz fiil zamanasimi | 4 | 4 | 4 | 0 | 6 | **2** |
| sozlesmenin kurulmasi | 4 | 4 | 4 | 1 | 6 | **1** |
| alacagin devri | 4 | 4 | 5 | 0 | 6 | **1** |
| borclu temerrudu | 3 | 3 | 0 | 0 | 5 | **5** |
| zamanasimi | 3 | 3 | 0 | 0 | 5 | **5** |
| takas | 3 | 3 | 0 | 0 | 5 | **5** |
| tazminattan indirim halleri | 3 | 3 | 1 | 0 | 5 | **4** |
| haksiz fiil unsurlari | 3 | 3 | 2 | 0 | 5 | **3** |
| zamanasimi suresi | 3 | 3 | 2 | 0 | 5 | **3** |
| hizmet borclanmasi | 3 | 3 | 3 | 1 | 5 | **1** |
| haksiz fiil | 3 | 3 | 4 | 0 | 5 | **1** |
| kusursuz sorumluluk halleri | 3 | 3 | 4 | 0 | 5 | **1** |
| sorumsuzluk anlasmalari | 2 | 2 | 1 | 0 | 3 | **2** |
| hukuka aykiriligi kaldiran haller | 2 | 2 | 1 | 0 | 3 | **2** |
| kesin hukumsuzluk halleri | 2 | 2 | 2 | 0 | 3 | **1** |
| sebepsiz zenginlesme sartlari | 2 | 2 | 2 | 0 | 3 | **1** |
| irade bozuklugu | 2 | 2 | 2 | 0 | 3 | **1** |
| ucret sozlesmesi kurallari (iade) | 1 | 1 | 0 | 0 | 2 | **2** |
| akdi temerrut faizi siniri (%100) | 1 | 1 | 0 | 0 | 2 | **2** |
| hazir olmayanlar arasi sozlesme | 1 | 1 | 0 | 0 | 2 | **2** |
| sebepsiz zenginlesme ahlaka aykiri amac | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme onerisi (icap) | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmeden dogan alacakta zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| tahsil zamanasimini kesen haller | 1 | 1 | 0 | 0 | 2 | **2** |
| kosula bagli sozlesme | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesme kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin kesilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret sozlesmesi asgari bilgileri | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasimi sureleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerin kurulmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| takas kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| ifa yeri ve zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| alacagin devri sekli | 1 | 1 | 0 | 0 | 2 | **2** |
| zamanasiminin durmasi halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| borcun ifa zamani | 1 | 1 | 0 | 0 | 2 | **2** |
| sozlesmelerde kesin hukumsuzluk | 1 | 1 | 0 | 0 | 2 | **2** |
| sureye bagli borclarda vade hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 28 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Is ve Sosyal Guvenlik Hukuku — 82 konu, 160 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| toplu is sozlesmesi | 6 | 6 | 2 | 0 | 9 | **7** |
| sendika uyeligi | 6 | 6 | 6 | 0 | 9 | **3** |
| is sozlesmesi turleri | 5 | 5 | 7 | 0 | 8 | **1** |
| yillik ucretli izin | 4 | 4 | 4 | 0 | 6 | **2** |
| is sozlesmesi feshi | 4 | 4 | 4 | 0 | 6 | **2** |
| calisma suresi | 3 | 3 | 0 | 0 | 5 | **5** |
| sigortali sayilma | 3 | 3 | 0 | 0 | 5 | **5** |
| calisma ve dinlenme sureleri | 3 | 3 | 1 | 0 | 5 | **4** |
| ucret hukumleri | 3 | 3 | 1 | 1 | 5 | **3** |
| isci ucretleri | 3 | 3 | 2 | 0 | 5 | **3** |
| İs kanunu kapsami | 3 | 3 | 3 | 0 | 5 | **2** |
| is kazasi sayilmayan haller | 3 | 3 | 3 | 0 | 5 | **2** |
| sureli fesih | 3 | 3 | 4 | 0 | 5 | **1** |
| sureli fesih kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| toplu is sozlesmesi kurallari | 2 | 2 | 1 | 0 | 3 | **2** |
| grev lokavt | 2 | 2 | 1 | 0 | 3 | **2** |
| isletme toplu is sozlesmesi | 2 | 2 | 1 | 0 | 3 | **2** |
| gecici is iliskisi | 2 | 2 | 1 | 0 | 3 | **2** |
| belirli sureli is sozlesmesi | 2 | 2 | 2 | 0 | 3 | **1** |
| isyeri devri | 2 | 2 | 2 | 0 | 3 | **1** |
| ise iade arabuluculuk | 2 | 2 | 2 | 0 | 3 | **1** |
| is kazasi meslek hastaligi | 2 | 2 | 2 | 0 | 3 | **1** |
| kisa uzun vadeli sigorta kollari | 2 | 2 | 2 | 0 | 3 | **1** |
| is kazasi sigortasi | 2 | 2 | 2 | 0 | 3 | **1** |
| sendika uyeligi kurallari (issizlik 1 yil) | 1 | 1 | 0 | 0 | 2 | **2** |
| grev lokavt erteleme | 1 | 1 | 0 | 0 | 2 | **2** |
| is kazasi-meslek hastaligi saglanan haklar | 1 | 1 | 0 | 0 | 2 | **2** |
| belirli belirsiz sureli is sozlesmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortalilik | 1 | 1 | 0 | 0 | 2 | **2** |
| sendika toplu is sozlesmesi yetkisi (%1) | 1 | 1 | 0 | 0 | 2 | **2** |
| yillik izin zamanasimi | 1 | 1 | 0 | 0 | 2 | **2** |
| toplu is sozlesmesi yararlanma | 1 | 1 | 0 | 0 | 2 | **2** |
| grev-lokavtta is sozlesmesinin askida kalmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| is sozlesmesi feshi alacaklari | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| isverenin hakli feshi | 1 | 1 | 0 | 0 | 2 | **2** |
| sigortalilik hali | 1 | 1 | 0 | 0 | 2 | **2** |
| is sozlesmesi sekli ve turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| alt isveren iliskisi | 1 | 1 | 0 | 0 | 2 | **2** |
| satis sozlesmesi zapttan sorumluluk | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 42 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ticaret Hukuku — 124 konu, 244 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| genel islem kosullari | 9 | 9 | 4 | 0 | 12 | **8** |
| cek zorunlu unsurlari | 5 | 5 | 3 | 2 | 8 | **3** |
| bono zorunlu unsurlari | 4 | 4 | 2 | 0 | 6 | **4** |
| ticari temsilci yetkisi | 4 | 4 | 3 | 0 | 6 | **3** |
| ticari is kavrami | 3 | 3 | 1 | 0 | 5 | **4** |
| cek hukuku | 3 | 3 | 3 | 0 | 5 | **2** |
| tacir olmanin sonuclari | 3 | 3 | 4 | 0 | 5 | **1** |
| kiymetli evrak cek | 3 | 3 | 4 | 0 | 5 | **1** |
| limited sirket kurallari | 2 | 2 | 0 | 0 | 3 | **3** |
| cek odeme kontrolu | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari orf ve adet | 2 | 2 | 0 | 0 | 3 | **3** |
| anonim sirket sona erme | 2 | 2 | 0 | 0 | 3 | **3** |
| sirket birlesmesi | 2 | 2 | 0 | 0 | 3 | **3** |
| ticaret sicili itiraz | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet ve reklam yasagi | 2 | 2 | 1 | 0 | 3 | **2** |
| limited sirket sermayesi | 2 | 2 | 1 | 0 | 3 | **2** |
| ticari isletme unsurlari | 2 | 2 | 1 | 0 | 3 | **2** |
| bono unsurlari | 2 | 2 | 2 | 0 | 3 | **1** |
| kambiyo senetleri | 2 | 2 | 2 | 0 | 3 | **1** |
| tacir kavrami | 2 | 2 | 2 | 0 | 3 | **1** |
| tacir sayilmayanlar (il ozel idaresi) | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket kurulus sozlesmeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| cek hukumleri | 1 | 1 | 0 | 0 | 2 | **2** |
| pay senedi getirisi | 1 | 1 | 0 | 0 | 2 | **2** |
| kambiyo senedi (bono) temsil yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket genel kurul | 1 | 1 | 0 | 0 | 2 | **2** |
| bonoya uygulanmayan police hukumleri (kabul) | 1 | 1 | 0 | 0 | 2 | **2** |
| temsil yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| aval (kambiyo teminati) | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket butlan davasi | 1 | 1 | 0 | 0 | 2 | **2** |
| cek kurallari (vade kaydi) | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret sicili | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirkete ayni sermaye olabilecekler | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket ortak sayisi (1-50) | 1 | 1 | 0 | 0 | 2 | **2** |
| bono cirosu | 1 | 1 | 0 | 0 | 2 | **2** |
| reklam yoluyla haksiz rekabet halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| anonim sirket yonetim kurulu temsil | 1 | 1 | 0 | 0 | 2 | **2** |
| cek cirosu kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| haksiz rekabet ve reklam yasagi yonetmeligi | 1 | 1 | 0 | 0 | 2 | **2** |
| limited sirket genel kurul yetkileri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 84 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Ekonomi (ayristirilamadi) — 76 konu, 148 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| tam rekabet denge uretimi | 1 | 1 | 0 | 0 | 2 | **2** |
| fayda fonksiyonu | 1 | 1 | 0 | 0 | 2 | **2** |
| carpan etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercih aksiyomlari | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisler hipotezi | 1 | 1 | 0 | 0 | 2 | **2** |
| kredi tayinlamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ricardo modeli varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| tam rekabet piyasa dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi kaymasi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopolcu rekabet | 1 | 1 | 0 | 0 | 2 | **2** |
| monopson emek piyasasi | 1 | 1 | 0 | 0 | 2 | **2** |
| optimal emek talebi | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol piyasasi | 1 | 1 | 0 | 0 | 2 | **2** |
| rasyonel bekleyisli makro modeller | 1 | 1 | 0 | 0 | 2 | **2** |
| uclu acmaz | 1 | 1 | 0 | 0 | 2 | **2** |
| lm egrisi ozellikleri | 1 | 1 | 0 | 0 | 2 | **2** |
| cobb-douglas ikame esnekligi | 1 | 1 | 0 | 0 | 2 | **2** |
| heckscher-ohlin modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| pigou etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| tercihlerin butunlugu varsayimi | 1 | 1 | 0 | 0 | 2 | **2** |
| para arzi parasal taban | 1 | 1 | 0 | 0 | 2 | **2** |
| tam ikame mallar kose dengesi | 1 | 1 | 0 | 0 | 2 | **2** |
| uretim varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| yeni klasik model | 1 | 1 | 0 | 0 | 2 | **2** |
| monopol fiyat farklilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| piyasa denge fiyati | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici fazlasi degisimi | 1 | 1 | 0 | 0 | 2 | **2** |
| trampa ekonomisi fiyat sayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| alman merkantilizmi | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketici tercihleri konvekslik | 1 | 1 | 0 | 0 | 2 | **2** |
| toplam fayda doyum noktasi | 1 | 1 | 0 | 0 | 2 | **2** |
| tekelci firma fiyat belirleme | 1 | 1 | 0 | 0 | 2 | **2** |
| tahvil piyasasi servet etkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| j egrisi (devaluasyon-net ihracat) | 1 | 1 | 0 | 0 | 2 | **2** |
| is-lm analizi | 1 | 1 | 0 | 0 | 2 | **2** |
| isci yanilma modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| klasik model | 1 | 1 | 0 | 0 | 2 | **2** |
| baumol-tobin modeli | 1 | 1 | 0 | 0 | 2 | **2** |
| tamamlayici mallar | 1 | 1 | 0 | 0 | 2 | **2** |
| tarife disi ticaret engelleri | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 36 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Hukuk (ayristirilamadi) — 161 konu, 319 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| etik ilkeler kisisel cikar | 1 | 1 | 0 | 0 | 2 | **2** |
| ticaret unvani kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri bildirgesi | 1 | 1 | 0 | 0 | 2 | **2** |
| defter belge teslimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret gelirinin kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari hukum | 1 | 1 | 0 | 0 | 2 | **2** |
| etik yakinlik tehditleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ozen (olagan sebep) sorumlulugu halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sirket ortaklarinin sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| engelli ve eski hukumlu calistirma | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari faaliyet yasagi cezasi | 1 | 1 | 0 | 0 | 2 | **2** |
| ayirt etme gucunun gecici kaybi sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret odeme kurallari | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler (bagimsiz calisanlar) | 1 | 1 | 0 | 0 | 2 | **2** |
| 4857 kapsam disi istisnalar | 1 | 1 | 0 | 0 | 2 | **2** |
| asiri yararlanma (gabin) | 1 | 1 | 0 | 0 | 2 | **2** |
| sosyal guvenlik ayligi | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tesvik | 1 | 1 | 0 | 0 | 2 | **2** |
| kesin hukumsuzluk-iptal sebepleri ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| irade beyan uygunsuzlugu | 1 | 1 | 0 | 0 | 2 | **2** |
| tur degistirme | 1 | 1 | 0 | 0 | 2 | **2** |
| is akdi feshi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek odalari yonetmeligi | 1 | 1 | 0 | 0 | 2 | **2** |
| meslek ile bagdasan isler | 1 | 1 | 0 | 0 | 2 | **2** |
| kutukten silinme halleri | 1 | 1 | 0 | 0 | 2 | **2** |
| yoksun kalinan kar | 1 | 1 | 0 | 0 | 2 | **2** |
| temlik cirosu | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler tehdit | 1 | 1 | 0 | 0 | 2 | **2** |
| telif kazanclari istisnasi | 1 | 1 | 0 | 0 | 2 | **2** |
| hakli savunma | 1 | 1 | 0 | 0 | 2 | **2** |
| calisma-dinlenme sureleri (tatil calismasi) | 1 | 1 | 0 | 0 | 2 | **2** |
| isyeri devri sorumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| engelli istihdam yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| asiri yararlanma | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret kurallari (mevduat faizi) | 1 | 1 | 0 | 0 | 2 | **2** |
| mecburi meslek karari | 1 | 1 | 0 | 0 | 2 | **2** |
| etik ilkeler yakinlik tehdidi | 1 | 1 | 0 | 0 | 2 | **2** |
| yanilma-hata | 1 | 1 | 0 | 0 | 2 | **2** |
| meslekle bagdasan isler | 1 | 1 | 0 | 0 | 2 | **2** |
| 4/1-a kapsaminda sayilanlar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 121 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebe (ayristirilamadi) — 209 konu, 407 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| anomali tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| duzenleyici hesaplarin tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| nakit esasi ve donemsellik kavrami | 1 | 1 | 0 | 0 | 2 | **2** |
| ihtiyatlilik kavrami (yedek akce) | 1 | 1 | 0 | 0 | 2 | **2** |
| doviz degerleme | 1 | 1 | 0 | 0 | 2 | **2** |
| yenileme fonu kullanimdan vazgecme | 1 | 1 | 0 | 0 | 2 | **2** |
| muhasebe bilgi sistemi ilkeleri | 1 | 1 | 0 | 0 | 2 | **2** |
| musteri kabulu asamalari | 1 | 1 | 0 | 0 | 2 | **2** |
| borca mahsuben odeme karisik kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| tutarlilik kavrami (politika degisikligi) | 1 | 1 | 0 | 0 | 2 | **2** |
| oz kaynaklari artiran islemler | 1 | 1 | 0 | 0 | 2 | **2** |
| ozkaynaklar hesaplari | 1 | 1 | 0 | 0 | 2 | **2** |
| ara donem raporlama | 1 | 1 | 0 | 0 | 2 | **2** |
| sorgulama tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| aktif duzenleyici hesaplar | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi muhasebe kuruluslari (ifac) | 1 | 1 | 0 | 0 | 2 | **2** |
| uluslararasi standart kuruluslari | 1 | 1 | 0 | 0 | 2 | **2** |
| kismi kredili satis kayitlari | 1 | 1 | 0 | 0 | 2 | **2** |
| alacaklara ait uygunluk testleri | 1 | 1 | 0 | 0 | 2 | **2** |
| geri kazanilabilir tutar | 1 | 1 | 0 | 0 | 2 | **2** |
| raporlama standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| kademeli dagitim gug toplami | 1 | 1 | 0 | 0 | 2 | **2** |
| istirak muhasebesi | 1 | 1 | 0 | 0 | 2 | **2** |
| gkgd standartlari kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| demirbas alimi karisik odeme kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| ifac organizasyonlari | 1 | 1 | 0 | 0 | 2 | **2** |
| gecmis yil zarari yedeklerden mahsup | 1 | 1 | 0 | 0 | 2 | **2** |
| ortaga kredili satis (alicilar) | 1 | 1 | 0 | 0 | 2 | **2** |
| menkul kiymet uygunluk testi | 1 | 1 | 0 | 0 | 2 | **2** |
| kredili mal alisi | 1 | 1 | 0 | 0 | 2 | **2** |
| oran standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| ipsasb uluslararasi kurulus | 1 | 1 | 0 | 0 | 2 | **2** |
| asli-duzenleyici hesap ayrimi | 1 | 1 | 0 | 0 | 2 | **2** |
| risk degerlendirme sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| blok secim yontemi | 1 | 1 | 0 | 0 | 2 | **2** |
| fatura yerine gecen belgeler | 1 | 1 | 0 | 0 | 2 | **2** |
| nakit akis faaliyet siniflamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| kayit sisteminin izlenmesi teknigi | 1 | 1 | 0 | 0 | 2 | **2** |
| finansal analiz turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| sayim fazlasi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 169 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliye (ayristirilamadi) — 42 konu, 84 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
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

Cem karari (11.09): bu dersler **sonraya**. 566 konu · 1.428 soru · 9.368 TL.

| Ders | Acik konu | Acik soru |
|---|---:|---:|
| Genel Kultur-Genel Yetenek (ayristirilamadi) | 150 | 299 |
| Yabanci Dil | 76 | 269 |
| Turkce | 81 | 243 |
| Matematik | 75 | 230 |
| Matematik-Istatistik (ayristirilamadi) | 104 | 205 |
| Yabanci Dil (ayristirilamadi) | 57 | 113 |
| Ataturk Ilke ve Inkilap Tarihi | 23 | 69 |

En cok cikan bekleyen konular (hat acildiginda ilk bunlar basilir):

| Ders | Konu | Cikmis | Bizde | BASILACAK |
|---|---|---:|---:|---:|
| Yabanci Dil | cumle tamamlama | 51 | 5 | 7 |
| Turkce | yazim kurallari | 17 | 3 | 9 |
| Turkce | noktalama isaretleri | 16 | 3 | 9 |
| Turkce | anlatim bozuklugu | 15 | 4 | 8 |
| Yabanci Dil | kelime bilgisi | 14 | 1 | 11 |
| Yabanci Dil | sentence completion | 9 | 4 | 8 |
| Matematik | denklem cozme | 9 | 2 | 10 |
| Turkce | ses olaylari | 8 | 1 | 11 |
| Turkce | sozcukte anlam | 8 | 3 | 9 |
| Yabanci Dil | cumle tamamlama-kosul | 7 | 1 | 10 |
| Matematik | yas problemi | 7 | 0 | 11 |
| Yabanci Dil | kelime tamamlama | 7 | 0 | 11 |
| Yabanci Dil | baglac kullanimi | 6 | 0 | 9 |
| Matematik | seri toplami | 6 | 1 | 8 |
| Matematik | belirli integral | 6 | 1 | 8 |

## 5 · KOPRUDE KARSILIGI OLMAYAN KONULARIMIZ

Ürettigimiz sorularin **1**'i, cikmis arsivde karsiligi olmayan **1** konuya ait.
Bu konular ya cikmis arsivde hic sorulmadi ya da konu ADI koprudekinden farkli yazildi.
Ikincisi ise olcum hatasidir — asagidaki ilk 25 ad elle gozden gecirilmeli.

| Konu (bizde) | Soru |
|---|---:|
| ic kontrol ic denetim | 1 |

