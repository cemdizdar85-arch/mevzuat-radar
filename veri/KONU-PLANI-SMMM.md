# KONU PLANI — STAJ BİTİRME / YETERLİLİK (SMMM)

> Uretim: **21.09.2026 00:36** (makine; elle duzenlenmez — motor/konu-plani.ps1). Bedel 0.
> Kaynak: cikmis siklik = veri/fabrika/konu-koprusu.json · bizim soru = veri/fabrika/kalip-parti-*.json · ders agirligi = veri/ders-profili.json
> Hedef kurali: konu cikmis arsivde N kez gorulduyse hedef = max(2, N x 1,5), tavan 12. Cikmis arsivde HIC gorulmemis konu plana GIRMEZ.

## 0 · TEK CUMLE

Cikmis SGS arsivinde gorulen **3.230 konu** var. Bunlarin **2.878**'inde elimizde soru YETERSIZ; toplam **6.355 soru** basilacak. Su an bu konularda **2.542** saglam sorumuz var.

## 0a · IKI HAT — Cem karari (11.09)

> *"matematik, ingilizce ve baska ne varsa sozel beklesin; digerlerini bir bitirelim sonra bunlara donelim"*

| Hat | Ders | Konu | Soru | Bedel (toplu) |
|---|---|---:|---:|---:|
| **SIMDI** | Alan Bilgisi (muhasebe · denetim · hukuk · ekonomi · maliye) | **2.878** | **6.355** | **41.689 TL** |
| BEKLESIN | Matematik · Yabanci Dil · Turkce · Inkilap · Genel Kultur | 0 | 0 | 0 TL |

Bekleyen hat mevzuata dayanmaz; kaynak paketi mantigi (ambardan madde cekme)
orada islemez, ayri bir hat gerektirir. 08.09'da da ayni sebeple Tur 1 disinda kalmislardi.
**Asagidaki butun tablolar SIMDI hattini gosterir**; bekleyen hat bolum 4'te ayri durur.

## 0b · BEDEL ve ONCELIK — SIMDI hatti

Uretim bedeli **0,320 USD/saglam soru = 13,12 TL** (veri/fabrika/bedel-kayit.jsonl, 122 parti).
Toplu istekle (Message Batches) bunun **yarisi** hedeflenir.

| Oncelik | Kural | Konu | Soru | Bedel (sirali) | Bedel (toplu) |
|---|---|---:|---:|---:|---:|
| 1 · cok kritik | cikmis >= 10 | 19 | 99 | 1.299 TL | 649 TL |
| 2 · kritik | cikmis >= 5 | 75 | 454 | 5.956 TL | 2.978 TL |
| 3 · onemli | cikmis >= 3 | 234 | 1.112 | 14.589 TL | 7.295 TL |
| 4 · orta | cikmis >= 2 | 473 | 1.732 | 22.724 TL | 11.362 TL |
| 5 · tamami | cikmis >= 1 | 2.878 | 6.355 | 83.378 TL | 41.689 TL |

**Oneri:** once **cikmis >= 3** kusagini bas. O kusak sinavda tekrar eden konulardir; geri kalan uzun kuyruk tek donemlik konulardan olusur (cikmis arsivinde 3.246 konunun 2.668'i TEK donemlik — sinav anatomisi olcumu).

## 1 · DERS OZETI

| Ders | Sinavda | Cikmis konu | Bizde soru | Hedef | ACIK soru | Acik konu |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | — | 1.297 | 355 | 3.458 | **3.118** | 1.282 |
| Finansal Tablolar ve Analizi | — | 307 | 345 | 859 | **616** | 268 |
| Vergi Mevzuatı ve Uygulaması | — | 338 | 306 | 785 | **576** | 290 |
| Muhasebecilik ve Mali Müşavirlik Meslek Hukuku | — | 292 | 293 | 690 | **495** | 247 |
| Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) | — | 297 | 333 | 647 | **482** | 246 |
| Muhasebe Denetimi | — | 281 | 329 | 639 | **457** | 232 |
| Maliyet Muhasebesi | — | 244 | 396 | 590 | **354** | 182 |
| Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) | — | 174 | 185 | 384 | **257** | 131 |
| **TOPLAM** | **130** | **3.230** | **2.542** | | **6.355** | **2.878** |

## 2 · DERS DERS, KONU KONU — ne basacagiz

Her ders icin konular **cikmis sikliga gore** siralidir: ustteki konu sinavda daha cok cikiyor.
ACIK sutunu o konudan kac soru basilacagini soyler. Acigi olmayan konular listelenmez.

### Finansal Muhasebe — 1282 konu, 3118 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| amortisman ayirma | 43 | 42 | 0 | 9 | 12 | **3** |
| bilanco duzenleme | 31 | 30 | 0 | 11 | 12 | **1** |
| acilis kaydi | 14 | 14 | 0 | 5 | 12 | **7** |
| kdv mahsup kaydi | 14 | 14 | 0 | 6 | 12 | **6** |
| gelecek aylara ait gider | 14 | 14 | 0 | 9 | 12 | **3** |
| ucret tahakkuku | 13 | 13 | 0 | 3 | 12 | **9** |
| ticari mal satisi | 12 | 12 | 0 | 4 | 12 | **8** |
| hisse senedi satisi | 12 | 12 | 0 | 7 | 12 | **5** |
| kredi faiz tahakkuku | 12 | 12 | 0 | 7 | 12 | **5** |
| borc senedi reeskontu | 11 | 11 | 0 | 0 | 12 | **12** |
| kdv mahsubu | 11 | 11 | 0 | 2 | 12 | **10** |
| supheli alacak tahsili | 11 | 11 | 0 | 7 | 12 | **5** |
| stok deger dusuklugu karsiligi | 10 | 9 | 0 | 3 | 12 | **9** |
| satistan iade | 10 | 10 | 0 | 8 | 12 | **4** |
| kapanis kaydi | 10 | 10 | 0 | 11 | 12 | **1** |
| satis iadesi | 9 | 9 | 0 | 1 | 12 | **11** |
| satis ve maliyet kaydi | 9 | 9 | 0 | 11 | 12 | **1** |
| ticari mal alimi | 8 | 8 | 0 | 1 | 12 | **11** |
| hisse senedi alimi | 8 | 8 | 0 | 4 | 12 | **8** |
| duran varlik satisi | 8 | 8 | 0 | 5 | 12 | **7** |
| faiz geliri tahakkuku | 8 | 8 | 0 | 6 | 12 | **6** |
| verilen cek odemesi | 8 | 8 | 0 | 7 | 12 | **5** |
| satilan ticari mal maliyeti | 8 | 8 | 0 | 10 | 12 | **2** |
| satis iadesi kaydi | 7 | 7 | 0 | 0 | 11 | **11** |
| personel ucret tahakkuku | 7 | 7 | 0 | 1 | 11 | **10** |
| supheli alacak silinmesi | 7 | 7 | 0 | 2 | 11 | **9** |
| alacak senedi reeskontu | 7 | 7 | 0 | 4 | 11 | **7** |
| alacak senedi tahsilati | 7 | 7 | 0 | 5 | 11 | **6** |
| banka kredisi kullanimi | 7 | 7 | 0 | 5 | 11 | **6** |
| kidem tazminati karsiligi | 7 | 7 | 0 | 7 | 11 | **4** |
| menkul kiymet deger dusuklugu | 6 | 6 | 0 | 0 | 9 | **9** |
| finansman gideri tahakkuku | 6 | 6 | 0 | 1 | 9 | **8** |
| pazarlama gideri odeme | 6 | 6 | 0 | 1 | 9 | **8** |
| menkul kiymet satisi | 6 | 6 | 0 | 2 | 9 | **7** |
| gelir tablosu hazirlama | 6 | 6 | 0 | 6 | 9 | **3** |
| saticiya mal iadesi | 5 | 5 | 0 | 0 | 8 | **8** |
| kredili satis kaydi | 5 | 5 | 0 | 0 | 8 | **8** |
| gelir tablosu bilanco hazirlama | 5 | 5 | 0 | 0 | 8 | **8** |
| personel gideri tahakkuku | 5 | 5 | 0 | 0 | 8 | **8** |
| alacak borc senedi reeskontu | 5 | 5 | 0 | 1 | 8 | **7** |
| _… 1242 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Finansal Tablolar ve Analizi — 268 konu, 616 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| dikey yuzde analizi | 15 | 14 | 0 | 10 | 12 | **2** |
| stok devir hizi | 13 | 13 | 0 | 7 | 12 | **5** |
| nakit orani | 11 | 11 | 0 | 11 | 12 | **1** |
| alacak devir hizi | 9 | 9 | 0 | 9 | 12 | **3** |
| ticari borc odeme suresi | 8 | 8 | 0 | 0 | 12 | **12** |
| cari oran | 8 | 8 | 0 | 3 | 12 | **9** |
| kaldirac orani | 8 | 8 | 0 | 11 | 12 | **1** |
| varlik devir hizi | 7 | 7 | 0 | 0 | 11 | **11** |
| stok devir suresi | 7 | 7 | 0 | 7 | 11 | **4** |
| finansal kaldirac orani | 7 | 7 | 0 | 9 | 11 | **2** |
| cari oran hesaplama | 6 | 6 | 0 | 3 | 9 | **6** |
| trend analizi | 6 | 5 | 0 | 7 | 9 | **2** |
| ticari alacak devir hizi | 6 | 6 | 0 | 8 | 9 | **1** |
| faaliyet karliligi | 5 | 5 | 0 | 0 | 8 | **8** |
| ticari alacak tahsil suresi | 5 | 5 | 0 | 3 | 8 | **5** |
| varlik karlilik orani | 5 | 5 | 0 | 5 | 8 | **3** |
| ticari borc devir hizi | 4 | 4 | 0 | 0 | 6 | **6** |
| satislarin karliligi | 4 | 4 | 0 | 2 | 6 | **4** |
| tutarlilik kavrami | 4 | 4 | 0 | 2 | 6 | **4** |
| faiz karsilama orani | 4 | 4 | 0 | 3 | 6 | **3** |
| stok bagimlilik orani | 4 | 4 | 0 | 4 | 6 | **2** |
| oz kaynak karliligi | 4 | 4 | 0 | 4 | 6 | **2** |
| muhasebe temel kavramlari | 4 | 4 | 0 | 4 | 6 | **2** |
| net calisma sermayesi | 3 | 3 | 0 | 0 | 5 | **5** |
| ticari mal devir hizi | 3 | 3 | 0 | 0 | 5 | **5** |
| oran analizi hesaplama | 3 | 3 | 0 | 0 | 5 | **5** |
| satislardan nakit girisi | 3 | 3 | 0 | 0 | 5 | **5** |
| asit test orani | 3 | 3 | 0 | 0 | 5 | **5** |
| mamul devir hizi | 3 | 3 | 0 | 0 | 5 | **5** |
| kayitli sermaye sistemi | 3 | 3 | 0 | 1 | 5 | **4** |
| faaliyet kari orani | 3 | 3 | 0 | 1 | 5 | **4** |
| faaliyet karlilik orani | 3 | 3 | 0 | 1 | 5 | **4** |
| nakit akim tablosu | 3 | 3 | 0 | 1 | 5 | **4** |
| likidite orani hesaplama | 3 | 3 | 0 | 1 | 5 | **4** |
| alacak satis iliskisi | 2 | 1 | 0 | 0 | 3 | **3** |
| finansal analiz teknikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| mamul stok devir hizi | 2 | 2 | 0 | 0 | 3 | **3** |
| nakit oran hesaplama | 2 | 2 | 0 | 0 | 3 | **3** |
| varliklarin karliligi | 2 | 2 | 0 | 0 | 3 | **3** |
| asit-test oran | 2 | 1 | 0 | 0 | 3 | **3** |
| _… 228 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Vergi Mevzuatı ve Uygulaması — 290 konu, 576 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| gelir vergisi matrahi hesaplama | 7 | 7 | 0 | 3 | 11 | **8** |
| gelecek aylara ait gider mahsubu | 6 | 6 | 0 | 3 | 9 | **6** |
| kurumlar vergisi matrahi | 5 | 5 | 0 | 1 | 8 | **7** |
| beyanname cesitleri | 5 | 5 | 0 | 4 | 8 | **4** |
| defter beyan sistemi | 4 | 4 | 0 | 1 | 6 | **5** |
| kurumlar vergisi hesaplama | 4 | 4 | 0 | 1 | 6 | **5** |
| gelir vergisi beyani hesaplama | 4 | 4 | 0 | 2 | 6 | **4** |
| bilanco tanimi | 3 | 3 | 0 | 0 | 5 | **5** |
| serbest meslek kazanci | 3 | 3 | 0 | 0 | 5 | **5** |
| gelir vergisi matrahi | 3 | 2 | 0 | 0 | 5 | **5** |
| aciz hali | 3 | 3 | 0 | 0 | 5 | **5** |
| gelir vergisi matrahi hesabi | 3 | 3 | 0 | 1 | 5 | **4** |
| gelir vergisi beyani | 3 | 3 | 0 | 1 | 5 | **4** |
| kurumlar vergisi mukellefleri | 3 | 3 | 0 | 3 | 5 | **2** |
| ortulu sermaye | 3 | 3 | 0 | 4 | 5 | **1** |
| kdv tam kismi istisna | 2 | 1 | 0 | 0 | 3 | **3** |
| tutulmasi zorunlu defterler | 2 | 2 | 0 | 0 | 3 | **3** |
| telif kazanci istisnasi | 2 | 2 | 0 | 0 | 3 | **3** |
| isyeri kira geliri beyani | 2 | 2 | 0 | 0 | 3 | **3** |
| kdv hizmet tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| repo kazanci vergilendirme | 2 | 2 | 0 | 0 | 3 | **3** |
| otv mukellefiyeti | 2 | 2 | 0 | 0 | 3 | **3** |
| transfer fiyatlandirmasi ortulu kazanc | 2 | 2 | 0 | 0 | 3 | **3** |
| serbest meslek kazanci hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi teminati | 2 | 2 | 0 | 0 | 3 | **3** |
| vergi sorumlusu tanimi | 2 | 2 | 0 | 0 | 3 | **3** |
| defter belge muhafaza suresi | 2 | 2 | 0 | 0 | 3 | **3** |
| tahsil zamanasimi | 2 | 2 | 0 | 0 | 3 | **3** |
| finansman gider kisitlamasi | 2 | 2 | 0 | 0 | 3 | **3** |
| aciz hali aatuhk | 2 | 2 | 0 | 0 | 3 | **3** |
| degerleme olculeri | 2 | 2 | 0 | 1 | 3 | **2** |
| gayrimenkul sermaye iradi | 2 | 2 | 0 | 1 | 3 | **2** |
| kdv ozel matrah sekilleri | 2 | 2 | 0 | 1 | 3 | **2** |
| vergi mukellefi tanimi | 2 | 2 | 0 | 1 | 3 | **2** |
| tasfiye beyannamesi | 2 | 2 | 0 | 1 | 3 | **2** |
| komanditer kazanc unsuru | 2 | 2 | 0 | 1 | 3 | **2** |
| gecikme zammi faizi | 2 | 1 | 0 | 1 | 3 | **2** |
| ihrac kaydiyla teslim tecil terkin | 2 | 2 | 0 | 1 | 3 | **2** |
| gelir vergisi beyanname cesitleri | 2 | 2 | 0 | 1 | 3 | **2** |
| turkiye'de yerlesme suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 250 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebecilik ve Mali Müşavirlik Meslek Hukuku — 247 konu, 495 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| musterek muteselsil sorumluluk | 6 | 6 | 0 | 1 | 9 | **8** |
| meslekle bagdasan isler | 5 | 5 | 0 | 5 | 8 | **3** |
| meslek mensubu olma sartlari | 4 | 4 | 0 | 2 | 6 | **4** |
| oda gelirleri | 4 | 4 | 0 | 4 | 6 | **2** |
| calisanlar listesinden silinme | 4 | 4 | 0 | 4 | 6 | **2** |
| zorunlu sozlesme konulari | 4 | 4 | 0 | 5 | 6 | **1** |
| yasaklanmis faaliyetler | 3 | 3 | 0 | 1 | 5 | **4** |
| mali tablolar siniflandirma | 3 | 3 | 0 | 1 | 5 | **4** |
| etik ilkeler tehditleri | 3 | 3 | 0 | 1 | 5 | **4** |
| sozlesme zorunlulugu | 3 | 3 | 0 | 3 | 5 | **2** |
| disiplin sorusturma organlari | 2 | 2 | 0 | 0 | 3 | **3** |
| haksiz rekabet kurulu | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin cezasi is kabul yasagi | 2 | 2 | 0 | 0 | 3 | **3** |
| zorunlu temel etik ilkeler | 2 | 2 | 0 | 0 | 3 | **3** |
| meslegin konusu | 2 | 2 | 0 | 0 | 3 | **3** |
| disiplin tedbir karari | 2 | 2 | 0 | 0 | 3 | **3** |
| mali tablolar siniflandirmasi | 2 | 2 | 0 | 1 | 3 | **2** |
| sozlesme fesih gerekceleri | 2 | 2 | 0 | 1 | 3 | **2** |
| etik ilkeler tehditler | 2 | 2 | 0 | 1 | 3 | **2** |
| meslek sirri | 2 | 2 | 0 | 1 | 3 | **2** |
| temel etik ilkeler | 2 | 2 | 0 | 1 | 3 | **2** |
| disiplin kararina itiraz | 2 | 2 | 0 | 1 | 3 | **2** |
| odalarin kurulus maksadi | 2 | 2 | 0 | 1 | 3 | **2** |
| disiplin cezasi is yasagi | 2 | 2 | 0 | 1 | 3 | **2** |
| etik komitesi gorevleri | 2 | 2 | 0 | 1 | 3 | **2** |
| defter belge saklama iade | 2 | 2 | 0 | 1 | 3 | **2** |
| isin devri ucret esaslari | 2 | 2 | 0 | 2 | 3 | **1** |
| is kabulu reddi | 2 | 2 | 0 | 2 | 3 | **1** |
| staj sonrasi hizmet yasagi ve bekleme suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin cezasi ev buro | 1 | 1 | 0 | 0 | 2 | **2** |
| birlik disiplin kurulu uye vasiflari | 1 | 1 | 0 | 0 | 2 | **2** |
| birlik yonetim kurulu olusumu | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| oda kurulus meslek mensubu sayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| temel egitim staj merkezi | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin cezalari bildirimi | 1 | 1 | 0 | 0 | 2 | **2** |
| sinav bilirkisi heyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| buro standartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| disiplin cezasi musteri kapma | 1 | 1 | 0 | 0 | 2 | **2** |
| stajdan sayilan haller | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 207 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.) — 246 konu, 482 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| ticari isletme unsurlari | 4 | 4 | 0 | 2 | 6 | **4** |
| borcu sona erdiren sebepler | 4 | 4 | 0 | 3 | 6 | **3** |
| kidem tazminati kosullari | 4 | 4 | 0 | 3 | 6 | **3** |
| hizmet akdi borclari | 3 | 3 | 0 | 0 | 5 | **5** |
| hukukun yazili kaynaklari | 3 | 3 | 0 | 1 | 5 | **4** |
| borc iliskisi unsurlari | 3 | 3 | 0 | 1 | 5 | **4** |
| fiil ehliyeti | 3 | 3 | 0 | 1 | 5 | **4** |
| haksiz rekabet | 3 | 3 | 0 | 3 | 5 | **2** |
| kambiyo senetleri ozellikleri | 2 | 2 | 0 | 0 | 3 | **3** |
| ticaret unvani koruma | 2 | 2 | 0 | 0 | 3 | **3** |
| gercek kisi tacir | 2 | 2 | 0 | 0 | 3 | **3** |
| hukuk kaynaklari hiyerarsisi | 2 | 2 | 0 | 0 | 3 | **3** |
| limited sirket idare temsil | 2 | 2 | 0 | 1 | 3 | **2** |
| hizmet akdi turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| sebepsiz zenginlesme unsurlari | 2 | 2 | 0 | 1 | 3 | **2** |
| tuzel kisi turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| yazili is sozlesmeleri | 2 | 2 | 0 | 1 | 3 | **2** |
| kidem tazminati | 2 | 2 | 0 | 1 | 3 | **2** |
| limited sirket temsili | 2 | 2 | 0 | 1 | 3 | **2** |
| zamanasimi | 2 | 2 | 0 | 2 | 3 | **1** |
| is sozlesmesi feshi | 2 | 2 | 0 | 2 | 3 | **1** |
| tacirin bagimli yardimcilari | 2 | 2 | 0 | 2 | 3 | **1** |
| ticari isletme tanimi | 2 | 2 | 0 | 2 | 3 | **1** |
| borcu sona erdiren yenileme | 1 | 1 | 0 | 0 | 2 | **2** |
| hakkin kazanilmasi yollari | 1 | 1 | 0 | 0 | 2 | **2** |
| komandit sirket ana sozlesme | 1 | 1 | 0 | 0 | 2 | **2** |
| hukuk kaynaklari hiyerarsi | 1 | 1 | 0 | 0 | 2 | **2** |
| sirket birlesmesi ttk | 1 | 1 | 0 | 0 | 2 | **2** |
| tacir bagimli yardimcilari | 1 | 1 | 0 | 0 | 2 | **2** |
| tacir tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| hak kavrami ve turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| 4/a sigortalisi kapsami | 1 | 1 | 0 | 0 | 2 | **2** |
| ucret ve asgari ucret | 1 | 1 | 0 | 0 | 2 | **2** |
| istinaf yolu | 1 | 1 | 0 | 0 | 2 | **2** |
| yenilik doguran hak tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ticari defter tutma yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| vergi yargisinda yurutmenin durdurulmasi | 1 | 1 | 0 | 0 | 2 | **2** |
| yurutmenin durdurulmasi sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| is kanunu yonetmelik yetkisi | 1 | 1 | 0 | 0 | 2 | **2** |
| pozitif hukuk yardimci kaynaklar | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 206 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Muhasebe Denetimi — 232 konu, 457 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| denetim teknikleri | 6 | 6 | 0 | 2 | 9 | **7** |
| raporlama standartlari | 5 | 5 | 0 | 2 | 8 | **6** |
| denetim raporu bolumleri | 5 | 3 | 0 | 4 | 8 | **4** |
| calisma alani standartlari | 4 | 4 | 0 | 1 | 6 | **5** |
| gorus bildirmekten kacinma | 4 | 4 | 0 | 2 | 6 | **4** |
| denetim sozlesmesi unsurlari | 4 | 4 | 0 | 2 | 6 | **4** |
| genel kabul gormus denetim standartlari | 4 | 4 | 0 | 2 | 6 | **4** |
| denetim riski turleri | 4 | 4 | 0 | 5 | 6 | **1** |
| ic kontrol tanima yontemleri | 3 | 3 | 0 | 1 | 5 | **4** |
| ic kontrol unsurlari | 3 | 3 | 0 | 2 | 5 | **3** |
| uygulamali mesleki egitim | 2 | 2 | 0 | 0 | 3 | **3** |
| ic kontrol amaclari | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim riski | 2 | 2 | 0 | 0 | 3 | **3** |
| denetim stratejisi | 2 | 2 | 0 | 1 | 3 | **2** |
| mesleki suphecilik | 2 | 2 | 0 | 1 | 3 | **2** |
| teyit teknigi turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| iliskili taraf tanimi | 2 | 2 | 0 | 1 | 3 | **2** |
| maddi dogruluk denetim islemleri | 2 | 2 | 0 | 2 | 3 | **1** |
| denetim sureci asamalari | 2 | 2 | 0 | 2 | 3 | **1** |
| sartli denetim gorusu | 2 | 2 | 0 | 2 | 3 | **1** |
| uygunluk denetimi | 2 | 2 | 0 | 2 | 3 | **1** |
| gelecek yillara ait giderler | 2 | 2 | 0 | 2 | 3 | **1** |
| standart denetim raporu bolumleri | 2 | 2 | 0 | 2 | 3 | **1** |
| kalite kontrol unsurlari | 1 | 1 | 0 | 0 | 2 | **2** |
| kgk kalite guvence denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim resmi sicili | 1 | 1 | 0 | 0 | 2 | **2** |
| destekleyici kanit guvenilirligi | 1 | 1 | 0 | 0 | 2 | **2** |
| olumlu gorus kosullari | 1 | 1 | 0 | 0 | 2 | **2** |
| bagimsiz denetim turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim gorus tipi belirleme | 1 | 1 | 0 | 0 | 2 | **2** |
| gorus belirtme turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| maddi dogruluk denetim kaniti | 1 | 1 | 0 | 0 | 2 | **2** |
| muhasebe denetimi tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim planlama | 1 | 1 | 0 | 0 | 2 | **2** |
| denetimin on kosullari | 1 | 1 | 0 | 0 | 2 | **2** |
| denetimde bagimsizlik ve yasak denetim disi hizmetler | 1 | 1 | 0 | 0 | 2 | **2** |
| denetim gorusu turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| ic denetim | 1 | 1 | 0 | 0 | 2 | **2** |
| yonetimin sorumluluklari (bds) | 1 | 1 | 0 | 0 | 2 | **2** |
| denetimin tamamlanma sureci | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 192 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Maliyet Muhasebesi — 182 konu, 354 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| satislarin maliyeti tablosu | 12 | 11 | 0 | 9 | 12 | **3** |
| gug yukleme katsayisi | 6 | 6 | 0 | 0 | 9 | **9** |
| normal maliyet yontemi | 6 | 6 | 0 | 4 | 9 | **5** |
| satilan mamul maliyeti | 5 | 5 | 0 | 5 | 8 | **3** |
| brut satis karliligi | 4 | 4 | 0 | 0 | 6 | **6** |
| tam maliyet yontemi | 4 | 4 | 0 | 1 | 6 | **5** |
| gug birinci dagitim | 4 | 4 | 0 | 5 | 6 | **1** |
| tutar saglamasi | 3 | 3 | 0 | 1 | 5 | **4** |
| ikinci dagitim matematiksel yontem | 3 | 3 | 0 | 2 | 5 | **3** |
| ucret tahakkuku kaydi | 3 | 3 | 0 | 2 | 5 | **3** |
| tamamlanan yari mamul maliyeti | 3 | 2 | 0 | 3 | 5 | **2** |
| kademeli dagitim yontemi | 3 | 3 | 0 | 3 | 5 | **2** |
| gider yansitma hesaplari | 3 | 3 | 0 | 4 | 5 | **1** |
| net satis degeri dagitimi | 2 | 2 | 0 | 0 | 3 | **3** |
| esdeger urun hesabi | 2 | 2 | 0 | 0 | 3 | **3** |
| maliyet muhasebesi kayitlari | 2 | 2 | 0 | 0 | 3 | **3** |
| miktar saglamasi | 2 | 2 | 0 | 1 | 3 | **2** |
| tamamlanan ve yari mamul maliyeti | 2 | 2 | 0 | 1 | 3 | **2** |
| tamamlanan mamul maliyeti | 2 | 2 | 0 | 2 | 3 | **1** |
| esdeger birim maliyet | 2 | 2 | 0 | 2 | 3 | **1** |
| esdeger uretim miktari | 2 | 2 | 0 | 2 | 3 | **1** |
| degisken maliyet yontemi | 2 | 2 | 0 | 2 | 3 | **1** |
| gelir tablosu brut kar | 2 | 2 | 0 | 2 | 3 | **1** |
| gider dagitimi ve birim maliyet | 1 | 1 | 0 | 0 | 2 | **2** |
| siparis maliyet karti | 1 | 1 | 0 | 0 | 2 | **2** |
| yari mamul stok hesabi | 1 | 1 | 0 | 0 | 2 | **2** |
| gug ikinci dagitim matematiksel | 1 | 1 | 0 | 0 | 2 | **2** |
| mamul satis kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| maliyet hacim kar varsayimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| yardimci gider yeri yararlanma orani | 1 | 1 | 0 | 0 | 2 | **2** |
| standart fiili maliyet karsilastirma | 1 | 1 | 0 | 0 | 2 | **2** |
| ortalama maliyet hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| donem gideri personel maas kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| tamamlanan ve dsym maliyeti | 1 | 1 | 0 | 0 | 2 | **2** |
| standart fiili maliyet | 1 | 1 | 0 | 0 | 2 | **2** |
| ek gider dagitimi | 1 | 1 | 0 | 0 | 2 | **2** |
| genel uretim giderleri | 1 | 1 | 0 | 0 | 2 | **2** |
| gug dagitim katsayisi | 1 | 1 | 0 | 0 | 2 | **2** |
| gider dagitim yevmiye kaydi | 1 | 1 | 0 | 0 | 2 | **2** |
| satis karliligi hesaplama | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 142 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

### Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093) — 131 konu, 257 soru basilacak

| Konu | Cikmis | Donem | Yayinda | Rafta | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|
| sermaye piyasasi kurumlari | 6 | 6 | 0 | 3 | 9 | **6** |
| yatirim ortakligi kurulus izni | 4 | 4 | 0 | 3 | 6 | **3** |
| spk suc tipleri | 3 | 3 | 0 | 0 | 5 | **5** |
| halka acik ortaklik statusu | 3 | 3 | 0 | 1 | 5 | **4** |
| bagimsiz denetim sorumlulugu | 3 | 3 | 0 | 3 | 5 | **2** |
| idari para cezasi | 2 | 2 | 0 | 0 | 3 | **3** |
| izahname sorumlulugu | 2 | 2 | 0 | 0 | 3 | **3** |
| sermaye piyasasi kavramlari | 2 | 2 | 0 | 0 | 3 | **3** |
| iliskili taraf islemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| halka arz yontemleri | 2 | 2 | 0 | 0 | 3 | **3** |
| sermaye piyasasi suclari | 2 | 2 | 0 | 0 | 3 | **3** |
| pay turleri | 2 | 2 | 0 | 1 | 3 | **2** |
| halka arz tanimi | 2 | 2 | 0 | 1 | 3 | **2** |
| yatirim fonu tanimi | 2 | 2 | 0 | 1 | 3 | **2** |
| urun ihtisas borsasi | 2 | 2 | 0 | 1 | 3 | **2** |
| spk temel kavramlar | 2 | 2 | 0 | 2 | 3 | **1** |
| halka arz mali tablo yukumlulugu | 1 | 1 | 0 | 0 | 2 | **2** |
| reel piyasaya kaynak | 1 | 1 | 0 | 0 | 2 | **2** |
| borsa denetimi | 1 | 1 | 0 | 0 | 2 | **2** |
| semsiye fon turleri | 1 | 1 | 0 | 0 | 2 | **2** |
| idari para cezalari | 1 | 1 | 0 | 0 | 2 | **2** |
| menkul kiymet yatirim ortakligi | 1 | 1 | 0 | 0 | 2 | **2** |
| mulkiyeti tabana yayma | 1 | 1 | 0 | 0 | 2 | **2** |
| vadeli islem uzun pozisyon | 1 | 1 | 0 | 0 | 2 | **2** |
| yatirimci tazmin suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| izahname tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| kira sertifikasi varlik kiralama | 1 | 1 | 0 | 0 | 2 | **2** |
| merkezi takas kuruluslari | 1 | 1 | 0 | 0 | 2 | **2** |
| birlesme sermaye artirimi | 1 | 1 | 0 | 0 | 2 | **2** |
| ozel durum aciklamasi | 1 | 1 | 0 | 0 | 2 | **2** |
| halka arz kavramlari | 1 | 1 | 0 | 0 | 2 | **2** |
| kayitli sermaye tavani suresi | 1 | 1 | 0 | 0 | 2 | **2** |
| yatirim ortakligi tanimi | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye piyasasi islevleri | 1 | 1 | 0 | 0 | 2 | **2** |
| fon mal varliginin ayriligi | 1 | 1 | 0 | 0 | 2 | **2** |
| spkn kavram tanimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| halka acik ortaklik statusu sona ermesi | 1 | 1 | 0 | 0 | 2 | **2** |
| kaydilestirme | 1 | 1 | 0 | 0 | 2 | **2** |
| araci kurum faaliyet sartlari | 1 | 1 | 0 | 0 | 2 | **2** |
| sermaye piyasasi araci tanimlari | 1 | 1 | 0 | 0 | 2 | **2** |
| _… 91 konu daha (tamami veri/konu-plani-sgs.json)_ | | | | | | |

## 5 · KOPRUDE KARSILIGI OLMAYAN KONULARIMIZ

Ürettigimiz sorularin **54**'i, cikmis arsivde karsiligi olmayan **13** konuya ait.
Bu konular ya cikmis arsivde hic sorulmadi ya da konu ADI koprudekinden farkli yazildi.
Ikincisi ise olcum hatasidir — asagidaki ilk 25 ad elle gozden gecirilmeli.

| Konu (bizde) | Soru |
|---|---:|
| gelir tablosu duzenleme | 15 |
| etik ilkeler tehdit onlemleri | 9 |
| donusturme maliyeti hesabi | 6 |
| gider yansitma kaydi | 6 |
| mevduat faiz tahakkuku | 4 |
| uretilen mamul maliyeti formulu | 3 |
| kdv nin konusu | 3 |
| kambiyo kari kaydi | 3 |
| esdeger mamul birimi | 1 |
| gug dagitim tablosu | 1 |
| kurumlar vergisi mukellefiyeti | 1 |
| kdv hizmet sayilan haller | 1 |
| tacir sifati ve temsil | 1 |

