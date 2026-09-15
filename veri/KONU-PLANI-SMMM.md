# KONU PLANI — STAJ BİTİRME / YETERLİLİK (SMMM)

> Uretim: **15.09.2026 15:31** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.209 konu** var. Bunlarin **3.209**'inde elimizde soru YETERSIZ; toplam **7.983 soru** basilacak. Su an bu konularda **29** saglam sorumuz var.

## 0a · IKI HAT — Cem karari (11.09)

> *"matematik, ingilizce ve baska ne varsa sozel beklesin; digerlerini bir bitirelim sonra bunlara donelim"*

| Hat | Ders | Konu | Soru | Bedel (toplu) |
|---|---|---:|---:|---:|
| **SIMDI** | Alan Bilgisi (muhasebe · denetim · hukuk · ekonomi · maliye) | **3.209** | **7.983** | **52.368 TL** |
| BEKLESIN | Matematik · Yabanci Dil · Turkce · Inkilap · Genel Kultur | 0 | 0 | 0 TL |

Bekleyen hat mevzuata dayanmaz; kaynak paketi mantigi (ambardan madde cekme)
orada islemez, ayri bir hat gerektirir. 08.09'da da ayni sebeple Tur 1 disinda kalmislardi.
**Asagidaki butun tablolar SIMDI hattini gosterir**; bekleyen hat bolum 4'te ayri durur.

## 0b · BEDEL ve ONCELIK — SIMDI hatti

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 21 | 245 | 3.214 TL | 1.607 TL |
| 2 · kritik | cikmis >= 5 | 82 | 825 | 10.824 TL | 5.412 TL |
| 3 · onemli | cikmis >= 3 | 267 | 1.801 | 23.629 TL | 11.815 TL |
| 4 · orta | cikmis >= 2 | 569 | 2.704 | 35.476 TL | 17.738 TL |
| 5 · tamami | cikmis >= 1 | 3.209 | 7.983 | 104.737 TL | 52.368 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | — | 1.318 | 3 | 3.544 | **3.541** | 1.318 |
| Finansal Tablolar ve Analizi | — | 308 | 7 | 861 | **854** | 308 |
| Vergi Mevzuatı ve Uygulaması | — | 329 | 4 | 734 | **730** | 329 |
| Muhasebecilik ve Mali Müşavirlik Meslek Hukuku | — | 293 | 2 | 696 | **694** | 293 |
| Muhasebe Denetimi | — | 278 | 4 | 630 | **626** | 278 |
| Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) | — | 281 | 1 | 611 | **610** | 281 |
| Maliyet Muhasebesi | — | 228 | 5 | 552 | **547** | 228 |
| Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | — | 174 | 3 | 384 | **381** | 174 |
| **TOPLAM** | **130** | **3.209** | **29** | | **7.983** | **3.209** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 1318 konu, 3541 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| gelir tablosu duzenleme | 45 | 39 | 0 | 0 | 12 | **12** |
| amortisman ayirma | 43 | 42 | 0 | 1 | 12 | **11** |
| bilanco duzenleme | 31 | 30 | 0 | 1 | 12 | **11** |
| supheli alacak karsiligi | 25 | 24 | 0 | 0 | 12 | **12** |
| gelecek aylara ait gider | 14 | 14 | 0 | 0 | 12 | **12** |
| kdv mahsup kaydi | 14 | 14 | 0 | 0 | 12 | **12** |
| acilis kaydi | 14 | 14 | 0 | 0 | 12 | **12** |
| ucret tahakkuku | 13 | 13 | 0 | 0 | 12 | **12** |
| ticari mal satisi | 12 | 12 | 0 | 0 | 12 | **12** |
| hisse senedi satisi | 12 | 12 | 0 | 0 | 12 | **12** |
| kredi faiz tahakkuku | 12 | 12 | 0 | 0 | 12 | **12** |
| borc senedi reeskontu | 11 | 11 | 0 | 0 | 12 | **12** |
| kdv mahsubu | 11 | 11 | 0 | 0 | 12 | **12** |
| supheli alacak tahsili | 10 | 10 | 0 | 0 | 12 | **12** |
| stok deger dusuklugu karsiligi | 10 | 9 | 0 | 0 | 12 | **12** |
| kapanis kaydi | 10 | 10 | 0 | 0 | 12 | **12** |
| satistan iade | 10 | 10 | 0 | 0 | 12 | **12** |
| satis ve maliyet kaydi | 9 | 9 | 0 | 0 | 12 | **12** |
| satis iadesi | 9 | 9 | 0 | 0 | 12 | **12** |
| mevduat faiz tahakkuku | 9 | 9 | 0 | 0 | 12 | **12** |
| hisse senedi alimi | 8 | 8 | 0 | 0 | 12 | **12** |
| ticari mal alimi | 8 | 8 | 0 | 0 | 12 | **12** |
| verilen cek odemesi | 8 | 8 | 0 | 0 | 12 | **12** |
| faiz geliri tahakkuku | 8 | 8 | 0 | 0 | 12 | **12** |
| duran varlik satisi | 8 | 8 | 0 | 0 | 12 | **12** |
| satilan ticari mal maliyeti | 8 | 8 | 0 | 1 | 12 | **11** |
| gider yansitma kaydi | 7 | 7 | 0 | 0 | 11 | **11** |
| personel ucret tahakkuku | 7 | 7 | 0 | 0 | 11 | **11** |
| banka kredisi kullanimi | 7 | 7 | 0 | 0 | 11 | **11** |
| satis iadesi kaydi | 7 | 7 | 0 | 0 | 11 | **11** |
| kidem tazminati karsiligi | 7 | 7 | 0 | 0 | 11 | **11** |
| alacak senedi tahsilati | 7 | 7 | 0 | 0 | 11 | **11** |
| supheli alacak silinmesi | 7 | 7 | 0 | 0 | 11 | **11** |
| alacak senedi reeskontu | 7 | 7 | 0 | 0 | 11 | **11** |
| finansman gideri tahakkuku | 6 | 6 | 0 | 0 | 9 | **9** |
| gelir tablosu hazirlama | 6 | 6 | 0 | 0 | 9 | **9** |
| menkul kiymet satisi | 6 | 6 | 0 | 0 | 9 | **9** |
| pazarlama gideri odeme | 6 | 6 | 0 | 0 | 9 | **9** |
| menkul kiymet deger dusuklugu | 6 | 6 | 0 | 0 | 9 | **9** |
| satilan mal maliyeti | 6 | 6 | 0 | 0 | 9 | **9** |
| _… 1278 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Finansal Tablolar ve Analizi — 308 konu, 854 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| dikey yuzde analizi | 15 | 14 | 0 | 1 | 12 | **11** |
| stok devir hizi | 13 | 13 | 0 | 2 | 12 | **10** |
| nakit orani | 11 | 11 | 0 | 1 | 12 | **11** |
| alacak devir hizi | 9 | 9 | 0 | 0 | 12 | **12** |
| kaldirac orani | 8 | 8 | 0 | 0 | 12 | **12** |
| ticari borc odeme suresi | 8 | 8 | 0 | 0 | 12 | **12** |
| cari oran | 8 | 8 | 0 | 1 | 12 | **11** |
| varlik devir hizi | 7 | 7 | 0 | 0 | 11 | **11** |
| stok devir suresi | 7 | 7 | 0 | 0 | 11 | **11** |
| finansal kaldirac orani | 7 | 7 | 0 | 1 | 11 | **10** |
| trend analizi | 6 | 5 | 0 | 0 | 9 | **9** |
| cari oran hesaplama | 6 | 6 | 0 | 0 | 9 | **9** |
| ticari alacak devir hizi | 6 | 6 | 0 | 0 | 9 | **9** |
| likidite orani | 5 | 5 | 0 | 0 | 8 | **8** |
| varlik karlilik orani | 5 | 5 | 0 | 0 | 8 | **8** |
| ticari alacak tahsil suresi | 5 | 5 | 0 | 0 | 8 | **8** |
| faaliyet kârliligi | 5 | 5 | 0 | 0 | 8 | **8** |
| tutarlilik kavrami | 4 | 4 | 0 | 0 | 6 | **6** |
| ticari borc devir hizi | 4 | 4 | 0 | 0 | 6 | **6** |
| net isletme sermayesi | 4 | 4 | 0 | 0 | 6 | **6** |
| satislarin kârliligi | 4 | 4 | 0 | 0 | 6 | **6** |
| stok bagimlilik orani | 4 | 4 | 0 | 0 | 6 | **6** |
| muhasebe temel kavramlari | 4 | 4 | 0 | 0 | 6 | **6** |
| devamli sermaye orani | 4 | 4 | 0 | 0 | 6 | **6** |
| oz kaynak karliligi | 4 | 4 | 0 | 0 | 6 | **6** |
| faiz karsilama orani | 4 | 4 | 0 | 1 | 6 | **5** |
| ticari mal devir hizi | 3 | 3 | 0 | 0 | 5 | **5** |
| likidite asit-test orani | 3 | 2 | 0 | 0 | 5 | **5** |
| oran analizi hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| satislardan nakit girisi | 3 | 3 | 0 | 0 | 5 | **5** |
| mamul devir hizi | 3 | 3 | 0 | 0 | 5 | **5** |
| kayitli sermaye sistemi | 3 | 3 | 0 | 0 | 5 | **5** |
| asit test orani | 3 | 3 | 0 | 0 | 5 | **5** |
| aktif devir hizi | 3 | 3 | 0 | 0 | 5 | **5** |
| faaliyet kari orani | 3 | 3 | 0 | 0 | 5 | **5** |
| faaliyet kârlilik orani | 3 | 3 | 0 | 0 | 5 | **5** |
| net calisma sermayesi | 3 | 3 | 0 | 0 | 5 | **5** |
| likidite orani hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| nakit akim tablosu | 3 | 3 | 0 | 0 | 5 | **5** |
| kaldirac orani hesaplama | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 268 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Vergi Mevzuatı ve Uygulaması — 329 konu, 730 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| gelecek aylara ait gider mahsubu | 6 | 6 | 0 | 1 | 9 | **8** |
| gelir vergisi matrahi hesaplama | 5 | 5 | 0 | 0 | 8 | **8** |
| kurumlar vergisi hesaplama | 4 | 4 | 0 | 0 | 6 | **6** |
| kurumlar vergisi mukellefleri | 3 | 3 | 0 | 0 | 5 | **5** |
| gelir vergisi beyani hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| aciz hali | 3 | 3 | 0 | 0 | 5 | **5** |
| defter beyan sistemi | 3 | 3 | 0 | 0 | 5 | **5** |
| gelir vergisi beyanname cesitleri | 3 | 3 | 0 | 0 | 5 | **5** |
| gelir vergisi beyani | 3 | 3 | 0 | 0 | 5 | **5** |
| serbest meslek kazanci | 3 | 3 | 0 | 0 | 5 | **5** |
| ortulu sermaye | 3 | 3 | 0 | 0 | 5 | **5** |
| kurumlar vergisi matrahi | 3 | 3 | 0 | 1 | 5 | **4** |
| isyeri kira geliri beyani | 2 | 2 | 0 | 0 | 3 | **3** |
| transfer fiyatlandirmasi ortulu kazanc | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv tam kismi istisna | 2 | 1 | 0 | 0 | 3 | **3** |
| vergi teminati | 2 | 2 | 0 | 0 | 3 | **3** |
| otv beyannamesi mukellefi | 2 | 2 | 0 | 0 | 3 | **3** |
| kurumlar vergisi matrahi hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv hizmet tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| tasfiye beyannamesi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi mukellefi tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv istisnalari | 2 | 2 | 0 | 0 | 3 | **3** |
| verginin tarhi | 2 | 2 | 0 | 0 | 3 | **3** |
| otv mukellefiyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| mukayyet deger | 2 | 2 | 0 | 0 | 3 | **3** |
| hesap hatalari | 2 | 2 | 0 | 0 | 3 | **3** |
| mukellef tespiti ve vergi tutari | 2 | 2 | 0 | 0 | 3 | **3** |
| aciz hali aatuhk | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi ziyai | 2 | 2 | 0 | 0 | 3 | **3** |
| tahsil zamanasimi | 2 | 2 | 0 | 0 | 3 | **3** |
| gecikme zammi faizi | 2 | 1 | 0 | 0 | 3 | **3** |
| vergi sorumlusu | 2 | 2 | 0 | 0 | 3 | **3** |
| serbest meslek kazanci hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| gelir vergisi matrahi | 2 | 1 | 0 | 0 | 3 | **3** |
| kdv ozel matrah sekilleri | 2 | 2 | 0 | 0 | 3 | **3** |
| finansman gider kisitlamasi | 2 | 2 | 0 | 0 | 3 | **3** |
| degerleme olculeri | 2 | 2 | 0 | 0 | 3 | **3** |
| telif kazanci istisnasi | 2 | 2 | 0 | 0 | 3 | **3** |
| gayrimenkul sermaye iradi | 2 | 2 | 0 | 0 | 3 | **3** |
| pismanlik ve islah | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 289 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebecilik ve Mali Müşavirlik Meslek Hukuku — 293 konu, 694 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| etik ilkeler | 8 | 8 | 0 | 0 | 12 | **12** |
| musterek muteselsil sorumluluk | 6 | 6 | 0 | 1 | 9 | **8** |
| meslekten cikarma cezasi | 6 | 6 | 0 | 1 | 9 | **8** |
| disiplin cezalari | 5 | 5 | 0 | 0 | 8 | **8** |
| meslekle bagdasan isler | 5 | 5 | 0 | 0 | 8 | **8** |
| zorunlu sozlesme konulari | 4 | 4 | 0 | 0 | 6 | **6** |
| oda gelirleri | 4 | 4 | 0 | 0 | 6 | **6** |
| etik ilkeler tehdit onlemleri | 4 | 4 | 0 | 0 | 6 | **6** |
| calisanlar listesinden silinme | 4 | 4 | 0 | 0 | 6 | **6** |
| meslek mensubu olma sartlari | 4 | 4 | 0 | 0 | 6 | **6** |
| meslek mensubu genel sartlari | 3 | 3 | 0 | 0 | 5 | **5** |
| reklam yoluyla haksiz rekabet | 3 | 3 | 0 | 0 | 5 | **5** |
| etik ilkeler tehditleri | 3 | 3 | 0 | 0 | 5 | **5** |
| mali tablolar siniflandirma | 3 | 3 | 0 | 0 | 5 | **5** |
| etik tehdit onlemleri | 3 | 3 | 0 | 0 | 5 | **5** |
| etik ilkelere tehditler | 3 | 3 | 0 | 0 | 5 | **5** |
| sozlesme zorunlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| yasaklanmis faaliyetler | 3 | 3 | 0 | 0 | 5 | **5** |
| oda organlari | 3 | 3 | 0 | 0 | 5 | **5** |
| disiplin sorusturmasi | 2 | 2 | 0 | 0 | 3 | **3** |
| defter belge saklama iade | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet kurulu | 2 | 2 | 0 | 0 | 3 | **3** |
| temel etik ilkeler | 2 | 2 | 0 | 0 | 3 | **3** |
| mesleki etik ilkeler | 2 | 2 | 0 | 0 | 3 | **3** |
| etik komitesi gorevleri | 2 | 2 | 0 | 0 | 3 | **3** |
| odalarin kurulus maksadi | 2 | 2 | 0 | 0 | 3 | **3** |
| zorunlu temel etik ilkeler | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin kararina itiraz | 2 | 2 | 0 | 0 | 3 | **3** |
| is kabulu reddi | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin cezasi is kabul yasagi | 2 | 2 | 0 | 0 | 3 | **3** |
| meslek konusu | 2 | 2 | 0 | 0 | 3 | **3** |
| meslek onuruyla bagdasmayan haller | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet halleri | 2 | 2 | 0 | 0 | 3 | **3** |
| mali tablolar siniflandirmasi | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin tedbir karari | 2 | 2 | 0 | 0 | 3 | **3** |
| sozlesme yapilmasi zorunlulugu | 2 | 2 | 0 | 0 | 3 | **3** |
| etik ilkeler tehditler | 2 | 2 | 0 | 0 | 3 | **3** |
| sozlesme fesih gerekceleri | 2 | 2 | 0 | 0 | 3 | **3** |
| meslegin konusu | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin kurulu itiraz suresi | 2 | 2 | 0 | 0 | 3 | **3** |
| _… 253 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebe Denetimi — 278 konu, 626 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim teknikleri | 6 | 6 | 0 | 1 | 9 | **8** |
| raporlama standartlari | 5 | 5 | 0 | 0 | 8 | **8** |
| denetim raporu bolumleri | 5 | 3 | 0 | 2 | 8 | **6** |
| denetim riski turleri | 4 | 4 | 0 | 0 | 6 | **6** |
| gorus bildirmekten kacinma | 4 | 4 | 0 | 0 | 6 | **6** |
| calisma alani standartlari | 4 | 4 | 0 | 0 | 6 | **6** |
| genel kabul gormus denetim standartlari | 4 | 4 | 0 | 0 | 6 | **6** |
| denetim sozlesmesi unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim gorus turleri | 3 | 3 | 0 | 0 | 5 | **5** |
| onemlilik kavrami | 3 | 3 | 0 | 0 | 5 | **5** |
| mesleki muhakeme | 3 | 3 | 0 | 0 | 5 | **5** |
| ic kontrol unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim kaniti guvenilirligi | 3 | 3 | 0 | 0 | 5 | **5** |
| denetim kistasi | 3 | 3 | 0 | 0 | 5 | **5** |
| ic kontrol tanima yontemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kaniti faktorleri | 2 | 2 | 0 | 0 | 3 | **3** |
| uygulamali mesleki egitim | 2 | 2 | 0 | 0 | 3 | **3** |
| gelecek yillara ait giderler | 2 | 2 | 0 | 0 | 3 | **3** |
| mesleki suphecilik | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim stratejisi | 2 | 2 | 0 | 0 | 3 | **3** |
| standart denetim raporu bolumleri | 2 | 2 | 0 | 0 | 3 | **3** |
| sartli denetim gorusu | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim sureci asamalari | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim kanit toplama teknikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| makul guvence | 2 | 2 | 0 | 0 | 3 | **3** |
| ic kontrol amaclari | 2 | 2 | 0 | 0 | 3 | **3** |
| teyit teknigi turleri | 2 | 2 | 0 | 0 | 3 | **3** |
| denetci bagimsizligi | 2 | 2 | 0 | 0 | 3 | **3** |
| uygunluk denetimi | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim riski | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| maddi dogruluk denetim islemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| ic kontrol sistemi amaclari | 1 | 1 | 0 | 0 | 2 | **2** |
| hile risk faktorleri | 1 | 1 | 0 | 0 | 2 | **2** |
| yonetimin sorumluluklari (bds) | 1 | 1 | 0 | 0 | 2 | **2** |
| destekleyici kanit guvenilirligi | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim resmi sicili | 1 | 1 | 0 | 0 | 2 | **2** |
| denetimin tamamlanma sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim riski tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| bilanco sonrasi olaylar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 238 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) — 281 konu, 610 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| kidem tazminati kosullari | 4 | 4 | 0 | 0 | 6 | **6** |
| borcu sona erdiren sebepler | 4 | 4 | 0 | 1 | 6 | **5** |
| borc iliskisi unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| hukukun yazili kaynaklari | 3 | 3 | 0 | 0 | 5 | **5** |
| hizmet akdi borclari | 3 | 3 | 0 | 0 | 5 | **5** |
| haksiz rekabet | 3 | 3 | 0 | 0 | 5 | **5** |
| fiil ehliyeti | 3 | 3 | 0 | 0 | 5 | **5** |
| ticari isletme unsurlari | 3 | 3 | 0 | 0 | 5 | **5** |
| kollektif sirket kurulusu | 2 | 2 | 0 | 0 | 3 | **3** |
| sebepsiz zenginlesme unsurlari | 2 | 2 | 0 | 0 | 3 | **3** |
| ihtiyati haciz | 2 | 2 | 0 | 0 | 3 | **3** |
| iscinin borclari | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet reklam yasagi | 2 | 2 | 0 | 0 | 3 | **3** |
| is sozlesmesi feshi | 2 | 2 | 0 | 0 | 3 | **3** |
| kambiyo senetleri ozellikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket idare temsil | 2 | 2 | 0 | 0 | 3 | **3** |
| tuzel kisi turleri | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket temsili | 2 | 2 | 0 | 0 | 3 | **3** |
| temsil yetkisinin sona ermesi | 2 | 2 | 0 | 0 | 3 | **3** |
| zamanasimi | 2 | 2 | 0 | 0 | 3 | **3** |
| alacak zamanasimi suresi | 2 | 2 | 0 | 0 | 3 | **3** |
| borclu temerrudu | 2 | 2 | 0 | 0 | 3 | **3** |
| tacir olmanin sonuclari | 2 | 2 | 0 | 0 | 3 | **3** |
| ticaret unvani koruma | 2 | 2 | 0 | 0 | 3 | **3** |
| hizmet akdi turleri | 2 | 2 | 0 | 0 | 3 | **3** |
| hukuk kaynaklari hiyerarsisi | 2 | 2 | 0 | 0 | 3 | **3** |
| yazili is sozlesmeleri | 2 | 2 | 0 | 0 | 3 | **3** |
| tacirin bagimli yardimcilari | 2 | 2 | 0 | 0 | 3 | **3** |
| kidem tazminati | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari isletme tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| sebepsiz zenginlesme | 2 | 2 | 0 | 0 | 3 | **3** |
| ticari defter ispat kosullari | 1 | 1 | 0 | 0 | 2 | **2** |
| hakkin kazanilmasi yollari | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari isletme sube unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| idari yargida dava acma suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| istinaf yolu | 1 | 1 | 0 | 0 | 2 | **2** |
| sgk isyeri bildirgesi | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari davalarda yetki | 1 | 1 | 0 | 0 | 2 | **2** |
| tuketim oduncu sozlesmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| kanunlarin zaman bakimindan uygulanmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 241 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliyet Muhasebesi — 228 konu, 547 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| satislarin maliyeti tablosu | 12 | 11 | 0 | 1 | 12 | **11** |
| normal maliyet yontemi | 6 | 6 | 0 | 1 | 9 | **8** |
| birim maliyet hesaplama | 5 | 5 | 0 | 0 | 8 | **8** |
| satilan mamul maliyeti | 5 | 5 | 0 | 1 | 8 | **7** |
| brut satis karliligi | 4 | 4 | 0 | 0 | 6 | **6** |
| ortak maliyet dagitimi | 4 | 4 | 0 | 0 | 6 | **6** |
| gug yukleme katsayisi | 4 | 4 | 0 | 0 | 6 | **6** |
| tam maliyet yontemi | 4 | 4 | 0 | 0 | 6 | **6** |
| gider yansitma hesaplari | 3 | 3 | 0 | 0 | 5 | **5** |
| esdeger birim maliyeti | 3 | 3 | 0 | 0 | 5 | **5** |
| mamul birim maliyeti | 3 | 3 | 0 | 0 | 5 | **5** |
| tutar saglamasi | 3 | 3 | 0 | 0 | 5 | **5** |
| ikinci dagitim matematiksel yontem | 3 | 3 | 0 | 0 | 5 | **5** |
| tamamlanan yari mamul maliyeti | 3 | 2 | 0 | 0 | 5 | **5** |
| ucret tahakkuku kaydi | 3 | 3 | 0 | 0 | 5 | **5** |
| kademeli dagitim yontemi | 3 | 3 | 0 | 0 | 5 | **5** |
| gug birinci dagitim | 3 | 3 | 0 | 0 | 5 | **5** |
| yan urun maliyeti | 3 | 3 | 0 | 1 | 5 | **4** |
| uretim ve satilan mamul maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| katsayili bolme yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger birim maliyet | 2 | 2 | 0 | 0 | 3 | **3** |
| gug yukleme orani | 2 | 2 | 0 | 0 | 3 | **3** |
| safha maliyet sistemi | 2 | 2 | 0 | 0 | 3 | **3** |
| gider yerleri ikinci dagitim | 2 | 2 | 0 | 0 | 3 | **3** |
| tamamlanan ve yari mamul maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| degisken maliyet yontemi | 2 | 2 | 0 | 0 | 3 | **3** |
| yardimci gider yeri dagitimi | 2 | 2 | 0 | 0 | 3 | **3** |
| birim maliyet hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet muhasebesi kayitlari | 2 | 2 | 0 | 0 | 3 | **3** |
| miktar saglamasi | 2 | 2 | 0 | 0 | 3 | **3** |
| birlesik maliyet dagitimi | 2 | 2 | 0 | 0 | 3 | **3** |
| satilan mamul maliyeti tablosu | 2 | 2 | 0 | 0 | 3 | **3** |
| tamamlanan mamul maliyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| gug dagitimi birim maliyet | 2 | 2 | 0 | 0 | 3 | **3** |
| gelir tablosu brut kar | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger mamul birimi | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger uretim miktari | 2 | 2 | 0 | 0 | 3 | **3** |
| stok degerleme yontemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| genel uretim gideri dagitimi | 2 | 2 | 0 | 1 | 3 | **2** |
| net satis degeri dagitimi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 188 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) — 174 konu, 381 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sermaye piyasasi kurumlari | 6 | 6 | 0 | 1 | 9 | **8** |
| yatirim ortakligi kurulus izni | 4 | 4 | 0 | 1 | 6 | **5** |
| bagimsiz denetim sorumlulugu | 3 | 3 | 0 | 0 | 5 | **5** |
| spk suc tipleri | 3 | 3 | 0 | 0 | 5 | **5** |
| halka acik ortaklik statusu | 3 | 3 | 0 | 1 | 5 | **4** |
| spk temel kavramlar | 2 | 2 | 0 | 0 | 3 | **3** |
| kâr payi avansi | 2 | 2 | 0 | 0 | 3 | **3** |
| izahname sorumlulugu | 2 | 2 | 0 | 0 | 3 | **3** |
| halka arz tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| gayrimenkul sertifikasi | 2 | 2 | 0 | 0 | 3 | **3** |
| halka arz yontemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| kira sertifikasi | 2 | 2 | 0 | 0 | 3 | **3** |
| pay turleri | 2 | 2 | 0 | 0 | 3 | **3** |
| sermaye piyasasi kavramlari | 2 | 2 | 0 | 0 | 3 | **3** |
| sermaye piyasasi suclari | 2 | 2 | 0 | 0 | 3 | **3** |
| urun ihtisas borsasi | 2 | 2 | 0 | 0 | 3 | **3** |
| borclanma araclari | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf islemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| idari para cezasi | 2 | 2 | 0 | 0 | 3 | **3** |
| ortulu kazanc aktarimi | 2 | 2 | 0 | 0 | 3 | **3** |
| yatirim fonu tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| kira sertifikasi varlik kiralama | 1 | 1 | 0 | 0 | 2 | **2** |
| turkiye sermaye piyasalari birligi gorevleri | 1 | 1 | 0 | 0 | 2 | **2** |
| idari para cezalari | 1 | 1 | 0 | 0 | 2 | **2** |
| halka arz mali tablo yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| borsa kurulus sekli | 1 | 1 | 0 | 0 | 2 | **2** |
| dar yetkili araci kurum | 1 | 1 | 0 | 0 | 2 | **2** |
| yonetim kontrolunun elde edilmesi | 1 | 1 | 0 | 0 | 2 | **2** |
| semsiye fon turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| turev araclar | 1 | 1 | 0 | 0 | 2 | **2** |
| menkul kiymet yatirim ortakligi | 1 | 1 | 0 | 0 | 2 | **2** |
| ayrilma hakki | 1 | 1 | 0 | 0 | 2 | **2** |
| oydan yoksun pay turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| kurul tedbir yetkileri ve bildirim | 1 | 1 | 0 | 0 | 2 | **2** |
| muhasebe usulsuzluk sucu | 1 | 1 | 0 | 0 | 2 | **2** |
| vadeli islem uzun pozisyon | 1 | 1 | 0 | 0 | 2 | **2** |
| reel piyasaya kaynak | 1 | 1 | 0 | 0 | 2 | **2** |
| kaydilestirme | 1 | 1 | 0 | 0 | 2 | **2** |
| mulkiyeti tabana yayma | 1 | 1 | 0 | 0 | 2 | **2** |
| borsa denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 134 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

