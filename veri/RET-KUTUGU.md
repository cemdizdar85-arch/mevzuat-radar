# RET KUTUGU — dusen sorularin nedeni ve onarim emri

> Uretim: **11.09.2026 20:45** (makine; elle duzenlenmez — arac/ret-kutugu.ps1). Bedel 0.
> Taranan 3.797 soru · dusen **1.358** (%35,8)

## KURAL

**Uretim turu bittiginde bu betik kosar. Ret nedenleri okunmadan yeni tur baslatilmaz.**
Bir kok neden sinifi ilk uce giriyorsa once ona KAPI kurulur — kapisiz tekrar uretim, ayni parayi ikinci kez yakar.

## 1 · HANGI KAPI DUSURDU

| Kapi | Soru | Pay |
|---|---:|---:|
| hakem KOSMADI | 737 | %54,3 |
| KAPI-HAKEM2 | 206 | %15,2 |
| KAPI-HAKEM | 194 | %14,3 |
| KAPI-SIM | 157 | %11,6 |
| KAPI-KOR | 64 | %4,7 |

## 2 · KOK NEDEN SINIFI — asil okunacak tablo

| Sinif | Soru | Pay | Onarim yolu |
|---|---:|---:|---|
| HAKEM-KOSMADI | 737 | %54,3 | Soru hic denetlenmemis. Parti -PilotId ile yeniden kosulur; kapilardan gecerse hasada girer. |
| SIM-YANLIS | 157 | %11,6 | Ogrenci simulasyonu yanlis cevapladi. Celdirici cok guclu ya da istem mugllak; genelde tek kelime duzeltmesi yeter. |
| (siniflanmamis) | 144 | %10,6 | **Desen yok — yeni kusur ailesi olabilir, asagidaki orneklere bak ve SINIF listesine desen ekle.** |
| KAYNAK-EKSIK | 112 | %8,2 | Paket cevabi destekleyen HUKMU tasimiyor. Once KAYNAK SIRALAMASI (KAPI-KP) ve konu-kaynak bagi bakilir; kaynak ambarda yoksa yutma is emri. |
| KOR-CELISKI | 64 | %4,7 | Bagimsiz kor cozum anahtardan FARKLI cevap verdi. Ikisinden biri yanlis: once anahtari elle dogrula, sonra soruyu yeniden uret. |
| YZ-KOKUSU | 58 | %4,3 | Yapay zeka kokusu: en uzun sik dogru, mutlak ifade. Sik boylari esitlenir, mutlak zarflar atilir. |
| KAYNAK-KESIK | 35 | %2,6 | Kaynak paketi KIRPILMIS (kp-01 sinifi). KAPI-KP (11.09) bunu onluyor; ESKI kayitlar icin hakem tazelenir. |
| YAPAY-DIL | 34 | %2,5 | Dil kapisi. Istem, cikmis sinav yazimina gore yeniden kurulur. |
| COK-ANLAMLI | 7 | %0,5 | Istem cumlesi tek anlama indirilir; cogu zaman tek kelime duzeltmesi yeter. |
| SINAV-DUZEYI | 5 | %0,4 | Soru SGS duzeyinin USTUNDE (paragraf numarasi sorgusu vb). Konu kartina zorluk tavani yazilir; soru sadelestirilir. |
| CELDIRICI-SAHTE | 5 | %0,4 | Celdirici sayilar uydurulmus. KAPI-C yolu; soru yeniden uretilir. |

### Siniflanmamis 144 gerekceden ornekler

- kgk-bosluk-trkiyedenetimstandartlar/kp-06 [KAPI-HAKEM] Soru VUK m.323'e dayansa da, şüpheli alacak karşılığı muhasebe/vergi muhasebesi konusu olup bağımsız denetim standartları kapsamında değildir.
- kgk-bosluk-trkiyemuhasebestandartlar/kp-17 [KAPI-HAKEM] Kaynak metinde THP 128 hesabının işleyişi açıklanmakta ancak doğru sikta gösterilen muhasebe kaydının (128 borç / 120 alacak) temel mantığı kaynakta eksiktir; kaynakta 'ilgili hesapların ala…
- kgk-bosluk-trkiyemuhasebestandartlar/kp-18 [KAPI-HAKEM] Kaynak metni sadece THP 622 (hizmet maliyeti) ve teorik üç kademeli formülü içerir; mamul maliyeti hesaplama yöntemi için muhasebe standardı, TMS, TFRS veya MSUGT/BOBI FRS dayanak maddesi/pa…
- kgk-kurfin-30/kp-05 [KAPI-HAKEM] Kaynak metni matematik (kesirler) teorisi içerir; soru ise saf matematik problemidir ve denetçilik/muhasebe/finansal yönetim bilgisine dayanmaz.
- sgs-a6-denetim-cokzor-r1/kp-02 [KAPI-HAKEM2] KOKU: B, D, E şıkları hemen hemen aynı kalıbın ('yalnızca X'i kapsar, Y'yi kapsamaz/hizmet etmez') tekrarı şeklinde kurulmuş.
- sgs-a6-maliye-zor-r1/kp-04 [KAPI-HAKEM2] KOKU: Soru kökündeki 'ekonomik, malî ve sosyal etkinliğin birlikte sağlanması' ifadesi doğru şıkta (B) birebir tekrarlanıyor; bu doğru cevabı kelime eşleşmesiyle ele veriyor
- sgs-fmuh-p30/kp-02 [KAPI-HAKEM2] KOKU: 'ABC A.S.' seklinde anlamsiz harf dizisiyle kurulan yer tutucu unvan kullanimi · KOKU: Tutarin yuvarlak sayi (300.000 TL) olarak se�ilmesi
- sgs-fmuh-p30/kp-03 [KAPI-HAKEM2] KOKU: Sirket adi olarak yalnizca 'ABC A.S.' kullanilmis; bu tam olarak anlamsiz harf dizisi t�r�nde yer tutucu isimdir (ger�ek�i bir unvan degil), bu YZ kokusu sayilir.
- sgs-fmuh-p30/kp-06 [KAPI-HAKEM2] KOKU: ABC A.Ş. yer tutucu unvan kullanılmış · KOKU: Tüm tutarlar yuvarlak (10.000'in katları)
- sgs-gk-pilot2-yd-kolay/kp-02 [KAPI-HAKEM] Soru, yabancı dil (İngilizce) dersinin resmi kapsamındaki 'fiil zamanı (past tense)' konusunu doğru ölçmektedir, ancak kaynak metinde verilen VUK m.30 hükümü (vergi tarhi) soru ve cevapla ta…
- sgs-gk-pilot-ekonomi-kolay/kp-01 [KAPI-HAKEM2] Kök ve veri sunumu klasik mutlak üstünlük kalıbına uygun ancak şıklar arasında uzunluk/yargı asimetrisi var; doğru şık (D) ek bir sonuç yargısı (uzmanlaşmalı) taşırken diğer şıklar sadece te…
- sgs-gk-pilot-inkilap-kolay/kp-01 [KAPI-HAKEM2] İtalya soru başlığında 'İttifak Devleti' olarak sunulmuş ancak İtalya, Üçlü İttifak'tan 1915'te ayrılıp İtilaf Devletleri safında savaşa girmiştir; bu şık gerçek bir çeldirici değil, tarihse…

## 3 · ONARIM EMRI — sinif sinif ilk 10 soru

### HAKEM-KOSMADI (737 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-02 | ticari isletme unsurlari |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-05 | eldeki kus teorisi |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-06 | intifa hakki konusu |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-14 | sebepsiz zenginlesme |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-17 | borcun sona ermesi |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-20 | haksiz fiil unsurlari |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-21 | faaliyet kaldirac derecesi |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-23 | modern portfoy teorisi |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-27 | isletme sermayesi yetersizligi |  |
| kgk-bosluk-kurumsalynetimİlkelerivefinansalynetim/kp-28 | isleyen tesebbus degeri |  |

### SIM-YANLIS (157 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-maliye-zor-r1/kp-11 | parafiskal gelir |  |
| sgs-denetim-p30/kp-02 | bds 500 denetim kaniti guvenilirligi |  |
| sgs-fmuh-parti1/kp-08 | gelecek yillara ait giderler |  |
| sgs-fmuh-parti1/kp-10 | kar dagitimi |  |
| sgs-gk-pilot-mat-kolay/kp-01 | cebirsel sadelestirme |  |
| sgs-maliyet-k10/kp-01 | satilan mamul maliyeti |  |
| sgs-maliyet-kalip3/kp-01 | ortak maliyet dagitimi |  |
| sgs-maliyet-kalip4/kp-01 | evre maliyet sistemi |  |
| sgs-mta-parti2/kp-01 | dikey yuzde analizi |  |
| sgs-mta-parti2/kp-02 | yatay analiz |  |

### KAYNAK-EKSIK (112 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| devir-analiz-tms/kp-06 | tms 36 deger dusuklugu | Kaynak metni TMS 36 paragraf 2'de TFRS 9 kapsamındaki finansal varlıkları kapsam dışı tutarken, özkaynak yöntemiyle muhasebeleştirilen iştirak yatırım… |
| devir-analiz-tms/kp-07 | nakit akis tablosu | Kaynak metni yalnızca TMS 7'nin tanım, yürürlük ve geçiş hükümlerini içerirken; sorunun doğru cevabını destekleyen temel kural olan 'dolaylı yöntemde … |
| devir-analiz-tms/kp-16 | tms 12 ertelenmis vergi | Kaynak metni TMS 12'nin kapsam ve amaçlarını açıklasa da, geçici farkın tanımı, vergiye tabi geçici fark kavramı, defter değeri ile vergiye esas değer… |
| devir-analiz-tms/kp-29 | tms 7 nakit akis tablosu | Kaynak metni TMS 7'nin amaç, kapsam ve genel hükümleri içermekte olup, nakit ve nakit benzerlerinin bileşenlerinin açıklanması ve finansal durum tablo… |
| kgk-bosluk-bankaclkmevzuat/kp-07 | denetim komitesi gorevleri | Kaynak metinde m.18/2 hükmü yer almadığı için, denetim komitesine üye belirleme imtiyazı veren payların Kurul iznine tabi olduğu kuralı kaynaktan doğr… |
| kgk-bosluk-sermayepiyasasmevzuat/kp-37 | katilma intifa senedi | Kaynak metinde intifa senedi sahiplerine dağıtılabilecek azami kâr payı oranına ilişkin 1/4 kuralı açıkça yer almamakta; SPK Tebliği m.5/4 sadece kâr … |
| kgk-bosluk-sigortaclkvezelemeklilikmevzuat/kp-02 | sigorta sirketi kurulusu | Kaynak metinde m.3/2-a-4 hükmü yer almamakta, kurucu şartlarına ilişkin detaylı kural açıkça desteklenmemektedir. |
| kgk-bosluk-trkiyedenetimstandartlar/kp-24 | bds 315 ic kontrol bilesenleri | Kaynak metni sadece BDS 315'teki yapısal risk ve kontrol riski kavramlarını içerir; görevler ayrılığı ilkesi, iç kontrol bileşenleri ve kontrol faaliy… |
| kgk-bosluk-trkiyedenetimstandartlar/kp-29 | mevzuata aykirilik gostergeleri | Kaynak metinde BDS 315 A23 paragrafından iç hukuk müşavirinin sorgulanması konusunda hiç bahsedilmemiş; sağlanan metinde yapısal risk aralığı, temel k… |
| kgk-bosluk-trkiyedenetimstandartlar/kp-30 | operasyonel risk tanimi | Kaynak metinde 'iş hayatına ilişkin riskler' tanımı yer almamakta; sağlanan BDS 315 paragrafları yapısal risk, kontrol riski, BT riskleri ve ciddi ris… |

### KOR-CELISKI (64 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-gk-pilot2-yd-kolay/kp-01 | verb tense passive | kor cozum D · anahtar A |
| sgs-issgk-p30/kp-03 | kisa uzun vadeli sigorta kollari | kor cozum HİÇBİRİ · anahtar D |
| sgs-t1-borclar-cokzor/kp-10 | sebepsiz zenginlesme giderler | kor cozum HİÇBİRİ · anahtar C |
| sgs-t1-borclar-cokzor/kp-21 | haksiz fiil ceza hukuku iliskisi | kor cozum A · anahtar B |
| sgs-t1-denetim-cokzor/kp-32 | denetim gorusu beyani | kor cozum A · anahtar C |
| sgs-t1-denetim-zor/kp-21 | denetim sureci safhalari | kor cozum B · anahtar A |
| sgs-t1-denetim-zor/kp-84 | bds 700 denetci raporu | kor cozum E · anahtar A |
| sgs-t1-fmuh-cokzor/kp-11 | kar dagitimi kaydi | kor cozum C · anahtar B |
| sgs-t1-fmuh-cokzor/kp-63 | hisse senedi iptali | kor cozum A · anahtar B |
| sgs-t1-fmuh-cokzor/kp-85 | normal amortisman yontemi | kor cozum D · anahtar C |

### YZ-KOKUSU (58 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-gk-pilot-turkce-zor/kp-02 | metin anlama | Bu soru SGS Türkçe sınavında değil, aslında bir iktisat/ekonomi kavramı (tüketim düzleştirmesi, permanent income hypothesis) üzerinden kurulmuş; TESME… |
| sgs-p-fmuh-kolay-r3/kp-01 | muhasebe bilgi sistemi | SGS Finansal Muhasebe sorularında genelde işlem/kayıt/hesaplama üzerinden mizan-bilanço ilişkisi sorulur; burada tamamen tanım/terminoloji ezberi soru… |
| sgs-t1-borclar-zor/kp-18 | sozlesme iptal sebepleri | KOKU: Şıklarda anlamsız ABC/XYZ unvanı veya klişe cümle yok, ancak D ve E şıklarının doğru şıkla karşılaştırıldığında belirgin şekilde kısa/mutlak ifa… |
| sgs-t1-denetim-cokzor/kp-06 | calisma kagitlari | KOKU: 'önem arz edecek' klişesi D şıkkında geçiyor |
| sgs-t1-denetim-cokzor/kp-21 | denetim sureci safhalari | KOKU: B ve E şıkları 'nihai denetim dosyası' ifadesini tekrarlayarak benzer kalıp oluşturuyor · KOKU: Cümle yapıları biraz karmaşık/resmi ama klişe if… |
| sgs-t1-denetim-kolay/kp-02 | denetim calisma kagitlari | KOKU: 'önem arz edecek' klişe ifadesi C şıkkında kullanılmış |
| sgs-t1-denetim-kolay/kp-27 | dis teyit denetim kaniti | KOKU: E şıkkı klişe ve genel geçer bir olumsuzlama cümlesi ile doldurulmuş |
| sgs-t1-denetim-kolay/kp-54 | denetim belgeleme sorumlulugu | BDS 230 p.10 gibi çok spesifik bir paragraf numarasına atıf yapıp, denetim belgelemesi gerektiren 'önemli hususları' tutar toplama işlemine indirgemek… |
| sgs-t1-denetim-kolay/kp-63 | bds 230 denetim belgelendirme | KOKU: 'önem arz edecek hususların kaydı' ifadesinde klişe 'önem arz etmek' kalıbı kullanılmış |
| sgs-t1-denetim-kolay/kp-78 | calisma kagitlari amaci | Kök 'beş ifadeden hangisi doğrudur' kalıbı SGS sınavlarında nadir görülen bir formattır; gerçek sınavlarda genellikle somut olay/tablo verilir, burada… |

### KAYNAK-KESIK (35 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| kgk-bosluk-sigortaclkvezelemeklilikmevzuat/kp-07 | sigorta ettiren yukumlulukleri | Kaynak metinde m.3/4 hükmü açıkça yer almamakta; sağlanan metinde yalnızca m.1, m.2 ve m.3'ün başlangıcı bulunmakta olup kooperatiflerin üyeleri dışın… |
| kgk-kurfin-30/kp-13 | optimal sermaye yapisi | Kaynak metni sermaye bütçelemesi, işletme sermayesi yönetimi ve belirsizlik altında yatırım kararlarını kapsamakta; sermaye yapısı teorileri bölümü ke… |
| sgs-gk-pilot-ekonomi-zor/kp-01 | mutlak ustunlukler teorisi | Soru 'mutlak üstünlükler teorisi' konusunu ölçüyor ve doğru sikk (B) teorinin tanımına göre hatalıdır; X tekstilde 4 saat (daha az) ile Y'nin 6 saatin… |
| sgs-kapituru-11eylul/kp-01 | muhasebe bilgi sistemi | Kaynak metni muhasebe bilgi sistemi kontrolleri ve nakit dönüşüm döngüsü konularını içermekte, mizan türleri ve kesin mizanın tanımını açıklayan teori… |
| sgs-t1-denetim-cokzor/kp-41 | onemlilik varsayimlari | Kaynak metinde BDS 320 p.A9 'vergi ve ücret ödemesi öncesi kâr' kuralı bulunmamaktadır; metinde 'vergi ve ücret ödemesi öncesi' ifadesi tamamlanmamış … |
| sgs-t1-denetim-kolay/kp-21 | denetim sureci safhalari | Kaynak metinde BDS 800 p.14'de denetim sözleşmesi şartlarının yönetim sorumluluğunu yansıtmasının hangi safhada sağlandığı açıkça belirtilmemiştir; BD… |
| sgs-t1-fmuh-cokzor/kp-10 | donemsellik kavrami | Kaynak metni dönemsellik kavramını tanımlamakta ancak 381 GİDER TAHAKKUKLARI hesabının işleyişini (borç/alacak yönü) içermemektedir; kaynak paketi 381… |
| sgs-t1-fmuh-cokzor/kp-74 | satistan iade stok girisi | Kaynak metni satıştan iade ve stok giriş kaydının muhasebe işleyişini desteklemiyor; VUK m.328 amortismana tabi malların satışını, m.160/A teminat işl… |
| sgs-t1-fmuh-cokzor-b/kp-113 | ucret bordrosu kaydi | Kaynak metni Vergi Usul Kanunu'nun genel hükümlerini (yasaklar, kar hadleri, zirai kazançlar, banka kayıtları, kayıt zamanı) içerir; ücret bordrosu ka… |
| sgs-t1-fmuh-cokzor-b/kp-136 | donem net kâri hesaplama | Kaynak metni VUK m.275 (İmal edilen emtia maliyet unsurları) ve maliyet muhasebesi teorisini içeriyor; donem sonu ayarlama kayıtlarının dayanağı olan … |

### YAPAY-DIL (34 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-04 | calisma kagitlari | KOKU: A, B, C şıklarının hepsi aynı 'X yeterlidir, Y gerekmez' kalıbının tekrarı, yapay simetri kokusu var |
| sgs-a6-maliye-zor-r1/kp-10 | operasyonel acik | Soru kökü ve kavram seti ('işletmenin bütçe harcaması/geliri', 'operasyonel açık') kamu maliyesi/bütçe açığı analizinde kullanılan, gerçek SGS Maliye … |
| sgs-fmuh-p30/kp-01 | gelir tablosu | KOKU: T�m tutarlar (40.000, 58.000, 60.000, 66.000, 30.000, 21.000, 4.000) bastan sona yuvarlak binlik rakamlar; ger�ek�ilik kaygisi olmayan yapay say… |
| sgs-t1-borclar-kolay/kp-07 | secimlik borc | KOKU: A ve E şıkları neredeyse birebir aynı kalıbın tekrarı (alacaklı/borçlu değişimiyle simetrik çeldirici), bu tarz ayna-şık kullanımı yapay üretim … |
| sgs-t1-denetim-cokzor/kp-17 | bds 230 calisma kagitlari | Soru kökü ve şıklar teorik/kavramsal metin yorumu tarzında, gerçek SGS sınavında BDS hükümleri genellikle somut bir denetim olayı/senaryo üzerinden ve… |
| sgs-t1-denetim-cokzor/kp-31 | denetim gorus turleri | KOKU: A, C, D şıklarında 'her koşulda', 'her hâlükârda', 'hiçbir şekilde' gibi aşırı kesinlik ifadelerinin art arda tekrarı yapay bir kalıp izlenimi v… |
| sgs-t1-denetim-cokzor/kp-35 | denetim kaniti tetkik | Soru kökü BDS 500/402 paragraf numaralarına dayalı çok spesifik bir bilgi sorusu; gerçek sınavlarda bu tür paragraf numarası eşleştirmesi genelde bu k… |
| sgs-t1-denetim-zor/kp-24 | denetim sureci asamalari | KOKU: B,C,D,E şıklarının hepsi aynı olumsuz mutlaklık kalıbını tekrarlıyor: 'tek ve yeterli unsurdur', 'yalnızca ... ile sınırlıdır', 'gerekmez', 'yal… |
| sgs-t1-denetim-zor/kp-62 | bds 330 yetersiz denetim kaniti | Gerçek SGS sınavında şıklar kısa etiket biçiminde olur, gerekçe içermez; burada her şıkta 'bu prosedür ... riskine karşı ihtiyaca uygundur/değildir' ş… |
| sgs-t1-denetim-zor/kp-81 | bds 530 orneklem buyuklugu | Kök ve şık uzunluğu sınav formatına yakın olsa da, B ve E şıkları aynı BDS 530 par.11 hükmünü ('yerini alan başka bir kalem üzerinde prosedür uygulanı… |

### COK-ANLAMLI (7 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-t1-genel-ekonomi-kolay/kp-02 | taylor prensibi | C(8) ve A(4) mantıklı hata kaynakları (sadece enflasyonu alma, sadece katsayı terimini alma) olsa da D(10) ve B(7) için net bir hesaplama hatası izlen… |
| sgs-t1-genel-turkce-kolay/kp-31 | belirtisiz ad tamlamasi | C şıkkı 'Yün kazak' dil bilgisinde tartışmalı bir örnektir; bazı kaynaklarda madde+isim ilişkisi nedeniyle belirtisiz ad tamlaması, bazılarında sıfat … |
| sgs-t1-mta-cokzor/kp-02 | yatay analiz | B(150.000=60.000/0,4 UFE ile karıştırma) ve E(300.000=60.000/0,2) mantıklı çeldiriciler; C(180.000) hangi hatadan türediği belirsiz; A(2.400) ise muht… |
| sgs-t2b-borclar-zor/kp-01 | sebepsiz zenginlesme | Doğru sık ifadesi eksik ve yanıltıcı; TBK m.79'a göre iyiniyetli elden çıkaran kişi için 'iade gerekir ama iyiniyetle elden çıkan kısım kapsam dışıdır… |
| sgs-t2-fmuh-zor/kp-68 | temettu geliri tahakkuku | Kaynak metinde 281 GELİR TAHAKKUKLARI hesabı tanımı 'bir yıl veya daha sonraki yıllarda yapılacak gelirlerin' için kullanılacağını belirtir; ancak sor… |
| sgs-t2-vergi-kolay/kp-12 | vergi ziyai cezasi zamanasimi | Kaynak metinde vergi ziyaı cezasında zamanaşımı süresinin beş yıl olduğu açıkça yazılmamış; madde 374/1 başlangıcında sadece başlangıç noktası belirti… |
| sgs-t4-maliye-cokzor/kp-14 | arz yanli iktisat | Soru kökü ve şıklar SGS Maliye sorularının tipik kalıbından (kısa senaryo/tanım + sayısal veya kavramsal tek doğru) ziyade doktriner/teorik tartışma d… |

### SINAV-DUZEYI (5 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-01 | denetim kaniti yeterliligi | SGS denetim sorularında standart paragraf numarası (A27-A29) verilerek 'birlikte değerlendirildiğinde' şeklinde akademik/hukuk sınavı kalıbı kullanılm… |
| sgs-p-fmuh-zor-r1/kp-14 | tms 21 gecerli para birimi | Soru kalıbı ('hangisi yanlıştır') SGS'ye uygun ama içerik TMS 21'in 42. paragrafının alt bentlerinin (a,b,c,d gibi) neredeyse birebir standart metnind… |
| sgs-t1-genel-ekonomi-cokzor/kp-08 | rasyonel beklentiler hipotezi | SGS Ekonomi soruları genellikle kısa bir tanım/hesap/karşılaştırma sorar; bu soru ise tek kökte 'önceden duyurulup duyurulmamasına VE Phillips eğrisin… |
| sgs-t2-fmuh-cokzor/kp-53 | muhasebe akis semasi | SGS Finansal Muhasebe soruları genellikle işlem/hesap üzerinden tutar hesaplatan somut sorulardır (mizan, envanter, dönem sonu kaydı vb.). Bu soru 'ak… |
| sgs-t2-fmuh-zor/kp-65 | tfrs 15 hasilat olcumu | Kök, TFRS 15 sözleşme feshi/tahsil hakkı konusunu içeriyor; bu düzeyde teorik-hesaplama karışımı bir soru SGS Finansal Muhasebe'de görülen klasik enva… |

### CELDIRICI-SAHTE (5 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-t1-fmuh-zor/kp-29 | hazine bonosu tahsili | B ve E şıkları gerçekçi bir celdirici (nominal değer ile alış bedelinin karıştırılması, net tahsilatın brüt değer sanılması) iken; C şıkkındaki 20.000… |
| sgs-t1-genel-turkce-cokzor/kp-15 | mecaz anlam | Çeldiriciler rastgele değil ama ölçme hatası var: B şıkkındaki 'göz kulak olmak' kalıbı bizatihi bir deyim olup 'göz' burada da mecazi/deyimleşmiş kul… |
| sgs-t1-genel-turkce-cokzor/kp-23 | ozne bulma | SGS Türkçe sorularında bu denli teknik dilbilgisi terminolojisi ('sözde özne', 'sıfat-fiil grubu', 'edilgen çatı' üçlü tanım birleşimi) tek kökte üst … |
| sgs-t2b-borclar-zor/kp-07 | oneri-icap kurallari | C şıkkı iyi bir çeldirici (m.11'deki 'gönderildiği an' ile 'ulaştığı an' karışıklığı gerçek bir aday tuzağı), ancak B ve D birbirinin tekrarı niteliği… |
| sgs-t2-fmuh-cokzor/kp-99 | alacaklar kontrol testleri | A ve B şıkları (200.000 fazla/eksik) mantıklı çeldiricilerdir; ancak C ve D şıklarındaki 225.000 TL tutarının nereden geldiğine dair mantıklı bir hesa… |

