# RET KUTUGU — dusen sorularin nedeni ve onarim emri

> Uretim: **12.09.2026 17:10** (makine; elle duzenlenmez — arac/ret-kutugu.ps1). Bedel 0.
> Taranan 4.602 soru · dusen **1.453** (%31,6)

## KURAL

**Uretim turu bittiginde bu betik kosar. Ret nedenleri okunmadan yeni tur baslatilmaz.**
Bir kok neden sinifi ilk uce giriyorsa once ona KAPI kurulur — kapisiz tekrar uretim, ayni parayi ikinci kez yakar.

## 1 · HANGI KAPI DUSURDU

| Kapi | Soru | Pay |
|---|---:|---:|
| KAPI-HAKEM | 728 | %50,1 |
| KAPI-HAKEM2 | 292 | %20,1 |
| KAPI-SIM | 230 | %15,8 |
| hakem KOSMADI | 110 | %7,6 |
| KAPI-KOR | 93 | %6,4 |

## 2 · KOK NEDEN SINIFI — asil okunacak tablo

| Sinif | Soru | Pay | Onarim yolu |
|---|---:|---:|---|
| KAYNAK-EKSIK | 596 | %41,0 | Paket cevabi destekleyen HUKMU tasimiyor. Once KAYNAK SIRALAMASI (KAPI-KP) ve konu-kaynak bagi bakilir; kaynak ambarda yoksa yutma is emri. |
| SIM-YANLIS | 230 | %15,8 | Ogrenci simulasyonu yanlis cevapladi. Celdirici cok guclu ya da istem mugllak; genelde tek kelime duzeltmesi yeter. |
| (siniflanmamis) | 218 | %15,0 | **Desen yok — yeni kusur ailesi olabilir, asagidaki orneklere bak ve SINIF listesine desen ekle.** |
| HAKEM-KOSMADI | 110 | %7,6 | Soru hic denetlenmemis. Parti -PilotId ile yeniden kosulur; kapilardan gecerse hasada girer. |
| KOR-CELISKI | 93 | %6,4 | Bagimsiz kor cozum anahtardan FARKLI cevap verdi. Ikisinden biri yanlis: once anahtari elle dogrula, sonra soruyu yeniden uret. |
| YZ-KOKUSU | 91 | %6,3 | Yapay zeka kokusu: en uzun sik dogru, mutlak ifade. Sik boylari esitlenir, mutlak zarflar atilir. |
| KAYNAK-KESIK | 45 | %3,1 | Kaynak paketi KIRPILMIS (kp-01 sinifi). KAPI-KP (11.09) bunu onluyor; ESKI kayitlar icin hakem tazelenir. |
| YAPAY-DIL | 43 | %3,0 | Dil kapisi. Istem, cikmis sinav yazimina gore yeniden kurulur. |
| COK-ANLAMLI | 13 | %0,9 | Istem cumlesi tek anlama indirilir; cogu zaman tek kelime duzeltmesi yeter. |
| SINAV-DUZEYI | 8 | %0,6 | Soru SGS duzeyinin USTUNDE (paragraf numarasi sorgusu vb). Konu kartina zorluk tavani yazilir; soru sadelestirilir. |
| CELDIRICI-SAHTE | 6 | %0,4 | Celdirici sayilar uydurulmus. KAPI-C yolu; soru yeniden uretilir. |

### Siniflanmamis 218 gerekceden ornekler

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

### KAYNAK-EKSIK (596 soru)

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

### SIM-YANLIS (230 soru)

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

### HAKEM-KOSMADI (110 soru)

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

### KOR-CELISKI (93 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-gk-pilot2-yd-kolay/kp-01 | verb tense passive | kor cozum D · anahtar A |
| sgs-issgk-p30/kp-03 | kisa uzun vadeli sigorta kollari | kor cozum HİÇBİRİ · anahtar D |
| sgs-kurtarma-fmuh-pilot/e-01ba3094 | kar dagitimi kaydi | kor cozum D · anahtar B |
| sgs-p-borclar-cokzor-r1/kp-04 | hizmet borclanmasi | kor cozum A · anahtar D |
| sgs-p-borclar-cokzor-r1-b2/kp-03 | hizmet borclanmasi | kor cozum A · anahtar C |
| sgs-p-borclar-zor-r1/kp-02 | alacagin devri | kor cozum B · anahtar C |
| sgs-p-ekonomi-cokzor-r3-a/kp-01 | para politikasi araclari | kor cozum A · anahtar C |
| sgs-p-fmuh-cokzor-r1/kp-03 | tms 38 maddi olmayan duran varlik | kor cozum D · anahtar A |
| sgs-p-fmuh-cokzor-r1/kp-16 | aktiflestirilmis giderler | kor cozum B · anahtar C |
| sgs-p-fmuh-cokzor-r2/kp-16 | kambiyo senetleri | kor cozum B · anahtar A |

### YZ-KOKUSU (91 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-gk-pilot-turkce-zor/kp-02 | metin anlama | Bu soru SGS Türkçe sınavında değil, aslında bir iktisat/ekonomi kavramı (tüketim düzleştirmesi, permanent income hypothesis) üzerinden kurulmuş; TESME… |
| sgs-p-borclar-cokzor-r2-b2/kp-04 | haksiz fiil | Soru kökü ve şıklar gerçek SGS/Borçlar-Ticaret hukuku sorularına göre aşırı uzun ve gerekçeli; SGS'de şıklar genellikle kısa sonuç ifadeleri olur (örn… |
| sgs-p-borclar-kolay-r1/kp-03 | zamanasimi suresi | SGS Borçlar Hukuku sorularında genellikle kavramsal/tanımsal bilgi (zamanaşımı süreleri, kesilme/durma halleri, hangi işlemlerin kesme sebebi olduğu) … |
| sgs-p-denetim-cokzor-r1/kp-03 | iliskili taraflar denetimi | Kök cümle kavramsal olarak sınav diline uygun olsa da, şıkların tamamı uzun, gerekçeli, alt cümlecikli tam tümceler halinde yazılmış; SGS/Denetim soru… |
| sgs-p-denetim-cokzor-r2/kp-05 | denetim planlamasi | SGS denetim sorularında 'HER ZAMAN doğrudur' kalıbıyla soyut, gerekçesiz beş tekli-cümle şıkkı karşılaştırma tarzı nadirdir; gerçek sınav soruları gen… |
| sgs-p-denetim-cokzor-r2/kp-10 | iliskili taraf islemleri denetimi | KOKU: 'piyasa şartlarına uygun ve tutarı önemsiz' gibi ifadeler doğal ama şıklardaki 'hiç değerlendirilmez', 'her durumda', 'tek başına yeterlidir' gi… |
| sgs-p-denetim-cokzor-r2-b2/kp-05 | bagimsiz denetim sureci | SGS denetim sorularında 'HER ZAMAN doğrudur' başlığı altında beş farklı teorik önermeyi (müşteri kabulü, yapısal risk bileşenleri, denetim riski formü… |
| sgs-p-denetim-cokzor-r2-b2/kp-08 | iliskili taraf islemleri denetimi | KOKU: 'her durumda' ve 'yalnızca...sınırlıdır' gibi mutlak ifadelerin farklı şıklarda tekrarı klişe çeldirici kurgusu izlenimi veriyor ama bu düzeyde … |
| sgs-p-denetim-cokzor-r2-b2/kp-17 | kanit yeterliligi | KOKU: D ve E şıklarında 'önemini yitirir', 'asla test edilmez' gibi mutlak/klişe abartı ifadeler |
| sgs-p-denetim-cokzor-r3/kp-03 | iliskili taraflar denetimi | KOKU: Şık C ve D'de 'hiç dikkate alınmaz', 'mutlak niteliktedir' gibi aşırı kesin/klişe ifadeler yapay zeka tipik abartısı |

### KAYNAK-KESIK (45 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| kgk-bosluk-sigortaclkvezelemeklilikmevzuat/kp-07 | sigorta ettiren yukumlulukleri | Kaynak metinde m.3/4 hükmü açıkça yer almamakta; sağlanan metinde yalnızca m.1, m.2 ve m.3'ün başlangıcı bulunmakta olup kooperatiflerin üyeleri dışın… |
| kgk-kurfin-30/kp-13 | optimal sermaye yapisi | Kaynak metni sermaye bütçelemesi, işletme sermayesi yönetimi ve belirsizlik altında yatırım kararlarını kapsamakta; sermaye yapısı teorileri bölümü ke… |
| sgs-gk-pilot-ekonomi-zor/kp-01 | mutlak ustunlukler teorisi | Soru 'mutlak üstünlükler teorisi' konusunu ölçüyor ve doğru sikk (B) teorinin tanımına göre hatalıdır; X tekstilde 4 saat (daha az) ile Y'nin 6 saatin… |
| sgs-kapituru-11eylul/kp-01 | muhasebe bilgi sistemi | Kaynak metni muhasebe bilgi sistemi kontrolleri ve nakit dönüşüm döngüsü konularını içermekte, mizan türleri ve kesin mizanın tanımını açıklayan teori… |
| sgs-p-meslek-cokzor-r2-a/kp-04 | ucret tarifesi | Dogru sikkin dayandigi Etik İlkeler Yönetmeliği madde 3/1-a kaynakta sunulmamıştır; kaynakta yalnızca m.1 (temel ilkeler) yer almakta, madde 3 ve 'kiş… |
| sgs-p-ticaret-cokzor-r3-b2/kp-06 | sirket birlesmesi | Kaynak metni (TTK m.39-42) ticaret unvanı ve şirket türlerine ilişkin hükümleri içermekte, ancak birleşme-bölünme-tür değiştirme kapsamında 'genel kur… |
| sgs-p-ticaret-zor-r2-b2/kp-02 | tacir sifati | Kaynak metinde m.12/2 ve m.16/1 doğru tarafından desteklenirken, m.16/2 açıkça II. ve IV. seçeneklerin tacir olmadığını belirtir; ancak m.12/1 eksik o… |
| sgs-p-vergi-kolay-r3-a/kp-03 | kdv istisnalari | Kaynak metni madde 12'yi içermemektedir; soru madde 12/1'e atıf yapmakta ancak kaynakta madde 11 ve madde 12'nin başlığı (İKİNCİ BÖLÜM Araçlar...) yer… |
| sgs-t1-borclar-kolay/kp-10 | sebepsiz zenginlesme giderler | Kaynak metinde m.79/II başlığı 'Giderleri isteme hakkı' görünmekle birlikte, bu bölümün tam metni ve zorunlu giderlerin zaman sınırlaması (öğrendiği a… |
| sgs-t1-denetim-cokzor/kp-41 | onemlilik varsayimlari | Kaynak metinde BDS 320 p.A9 'vergi ve ücret ödemesi öncesi kâr' kuralı bulunmamaktadır; metinde 'vergi ve ücret ödemesi öncesi' ifadesi tamamlanmamış … |

### YAPAY-DIL (43 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-04 | calisma kagitlari | KOKU: A, B, C şıklarının hepsi aynı 'X yeterlidir, Y gerekmez' kalıbının tekrarı, yapay simetri kokusu var |
| sgs-a6-maliye-zor-r1/kp-10 | operasyonel acik | Soru kökü ve kavram seti ('işletmenin bütçe harcaması/geliri', 'operasyonel açık') kamu maliyesi/bütçe açığı analizinde kullanılan, gerçek SGS Maliye … |
| sgs-fmuh-p30/kp-01 | gelir tablosu | KOKU: T�m tutarlar (40.000, 58.000, 60.000, 66.000, 30.000, 21.000, 4.000) bastan sona yuvarlak binlik rakamlar; ger�ek�ilik kaygisi olmayan yapay say… |
| sgs-p-denetim-cokzor-r1-b2/kp-03 | iliskili taraflar denetimi | KOKU: A, C, D, E şıklarının hepsinde 'her koşulda/her zaman/koşulsuz' gibi mutlaklık kalıbının tekrarlanması yapay bir örüntü oluşturuyor |
| sgs-p-denetim-kolay-r1/kp-02 | denetim calisma kagitlari | KOKU: 'katkıda bulunmak' kalıbının A,B,C,D şıklarında tekrarı yapay bir kalıp hissi veriyor |
| sgs-p-ekonomi-kolay-r2-a/kp-03 | talep fiyat esnekligi | SGS ekonomi sorularında şıklar sonuç+kısa etiket biçiminde, gerekçesiz yazılır; burada her şıkkın yanına 'çünkü...' ile uzun gerekçe eklenmiş, bu klas… |
| sgs-p-ekonomi-kolay-r3-a/kp-01 | talep esnekligi | Soru kökü ve veri sunumu (|e|=0,6, fiyat artışı) klasik esneklik-hasılat kalıbına uygun; ancak gerçek TESMER sorularında şıklar genelde kısa sonuç ifa… |
| sgs-p-issgk-zor-r1-a/kp-03 | ucret yonetmeligi kurallari | KOKU: İşletme/kişi kısaltmalarının hepsi tek harf (A,B,C,D) olması biraz mekanik ama sınavlarda da yaygın, yine de tekrarlı harf kullanımı hafif yapay… |
| sgs-p-meslek-cokzor-r1/kp-03 | smmm odalari | KOKU: A,B,C,E şıklarının dördünde de 'yalnızca' kelimesinin tekrarlanması yapay bir kalıp tekrarı oluşturuyor |
| sgs-p-meslek-zor-r1-a/kp-03 | disiplin yonetmeligi | KOKU: Şıklarda 'yalnızca', 'ancak', 'alınmadıkça' gibi kesinlik bildiren aşırı mutlak ifadelerin tekrarı çeldiricileri belirgin şekilde yapaylaştırmış… |

### COK-ANLAMLI (13 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-fmuh-parti1/kp-01 | muhasebe bilgi sistemi | 900 TL'lik sapma seçeneklerinin (A ve C) nereden türetildiği belirsizdir; verilen 6 rakamdan mantıklı bir yanlış toplama, atlama veya rakam ters yazma… |
| sgs-p-fmuh-kolay-r3/kp-07 | isletmenin surekliligi | Soru Denetim standardı (BDS 570) hakkında olup Finansal Muhasebe dersinin kapsamı dışındadır; Denetim dersinin konusudur. Kaynak metinde (TEORI bölümü… |
| sgs-p-issgk-zor-r1-a/kp-07 | belirli sureli is sozlesmesi | İfade II (belirli süreli sözleşme sözlü yapılabilir) kaynakta açıkça yanlışlanmakta; m.11 'yazılı şekilde' şartı ve m.8 'süresi bir yıl ve daha fazla'… |
| sgs-t1-fmuh-cokzor/kp-71 | satistan iade-surekli envanter | 610 Satıştan İadeler hesabı tanımında 'fatura tutarları' kapsar denilmektedir; kaynak metinde nakliye bedelinin iadesinde 610'a kaydedilmeyeceği açıkç… |
| sgs-t1-fmuh-cokzor/kp-89 | muhasebe bilgi sistemi kontrolleri | SGS Finansal Muhasebe sınavı tipik olarak hesap/işlem bazlı sayısal veya doğru-yanlış kısa teori soruları içerir; bu soru bilgi sistemleri denetimi/iç… |
| sgs-t1-genel-ekonomi-kolay/kp-02 | taylor prensibi | C(8) ve A(4) mantıklı hata kaynakları (sadece enflasyonu alma, sadece katsayı terimini alma) olsa da D(10) ve B(7) için net bir hesaplama hatası izlen… |
| sgs-t1-genel-turkce-kolay/kp-31 | belirtisiz ad tamlamasi | C şıkkı 'Yün kazak' dil bilgisinde tartışmalı bir örnektir; bazı kaynaklarda madde+isim ilişkisi nedeniyle belirtisiz ad tamlaması, bazılarında sıfat … |
| sgs-t1-maliyet-cokzor/kp-27 | safha maliyet-esdeger birim | Kaynak metni safha maliyet-eşdeğer birim konusunu teorik olarak tanımlasa da, soru FIFO formülünün uygulanmasını gerektirir; kaynaktaki 'Teori Notu' b… |
| sgs-t1-mta-cokzor/kp-02 | yatay analiz | B(150.000=60.000/0,4 UFE ile karıştırma) ve E(300.000=60.000/0,2) mantıklı çeldiriciler; C(180.000) hangi hatadan türediği belirsiz; A(2.400) ise muht… |
| sgs-t2b-borclar-zor/kp-01 | sebepsiz zenginlesme | Doğru sık ifadesi eksik ve yanıltıcı; TBK m.79'a göre iyiniyetli elden çıkaran kişi için 'iade gerekir ama iyiniyetle elden çıkan kısım kapsam dışıdır… |

### SINAV-DUZEYI (8 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-01 | denetim kaniti yeterliligi | SGS denetim sorularında standart paragraf numarası (A27-A29) verilerek 'birlikte değerlendirildiğinde' şeklinde akademik/hukuk sınavı kalıbı kullanılm… |
| sgs-p-denetim-cokzor-r1-b2/kp-09 | stok denetimi | SGS denetim sorularında BDS madde bilgisi kısa kök+kısa şık formatında sorulur; bu soru uzun, çok cümleli ve teorik tartışma biçiminde şıklar içeriyor… |
| sgs-p-denetim-cokzor-r2/kp-06 | uluslararasi muhasebe kuruluslari | Soru kökü ve şıkların biçimi (sonuç+kısa etiket) sınav formatına uygun olsa da, IFRS Vakfı/IFAC/IASB/IAASB/İzleme Kurulu/IFRS Yorum Komitesi arasındak… |
| sgs-p-denetim-cokzor-r2-b2/kp-03 | iliskili taraflar denetimi | Kök 'HER ZAMAN doğrudur' kalıbıyla beş ayrı teorik önerme karşılaştırması istiyor; bu, SGS/Denetim çıkmışlarındaki kısa, tek bir olay/duruma dayalı so… |
| sgs-t1-fmuh-zor-b/kp-99 | tms 36 deger dusuklugu testi | SGS Finansal Muhasebe soruları genelde işlem/kayıt/hesaplama ağırlıklıdır; bu soru TFRS/TMS standart metnini birebir aktaran, tamamen kavramsal-teorik… |
| sgs-t1-genel-ekonomi-cokzor/kp-08 | rasyonel beklentiler hipotezi | SGS Ekonomi soruları genellikle kısa bir tanım/hesap/karşılaştırma sorar; bu soru ise tek kökte 'önceden duyurulup duyurulmamasına VE Phillips eğrisin… |
| sgs-t2-fmuh-cokzor/kp-53 | muhasebe akis semasi | SGS Finansal Muhasebe soruları genellikle işlem/hesap üzerinden tutar hesaplatan somut sorulardır (mizan, envanter, dönem sonu kaydı vb.). Bu soru 'ak… |
| sgs-t2-fmuh-zor/kp-65 | tfrs 15 hasilat olcumu | Kök, TFRS 15 sözleşme feshi/tahsil hakkı konusunu içeriyor; bu düzeyde teorik-hesaplama karışımı bir soru SGS Finansal Muhasebe'de görülen klasik enva… |

### CELDIRICI-SAHTE (6 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-t1-denetim-kolay/kp-30 | denetim kanit toplama prosedurleri | Kök cümle BDS 500 diline uygun ama şık seti sınav pratiğine aykırı: A ve B aynı konuya (ticari borç eksik gösterimi) odaklanırken C, D, E tamamen fark… |
| sgs-t1-fmuh-zor/kp-29 | hazine bonosu tahsili | B ve E şıkları gerçekçi bir celdirici (nominal değer ile alış bedelinin karıştırılması, net tahsilatın brüt değer sanılması) iken; C şıkkındaki 20.000… |
| sgs-t1-genel-turkce-cokzor/kp-15 | mecaz anlam | Çeldiriciler rastgele değil ama ölçme hatası var: B şıkkındaki 'göz kulak olmak' kalıbı bizatihi bir deyim olup 'göz' burada da mecazi/deyimleşmiş kul… |
| sgs-t1-genel-turkce-cokzor/kp-23 | ozne bulma | SGS Türkçe sorularında bu denli teknik dilbilgisi terminolojisi ('sözde özne', 'sıfat-fiil grubu', 'edilgen çatı' üçlü tanım birleşimi) tek kökte üst … |
| sgs-t2b-borclar-zor/kp-07 | oneri-icap kurallari | C şıkkı iyi bir çeldirici (m.11'deki 'gönderildiği an' ile 'ulaştığı an' karışıklığı gerçek bir aday tuzağı), ancak B ve D birbirinin tekrarı niteliği… |
| sgs-t2-fmuh-cokzor/kp-99 | alacaklar kontrol testleri | A ve B şıkları (200.000 fazla/eksik) mantıklı çeldiricilerdir; ancak C ve D şıklarındaki 225.000 TL tutarının nereden geldiğine dair mantıklı bir hesa… |

