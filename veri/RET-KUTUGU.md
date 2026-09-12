# RET KUTUGU — dusen sorularin nedeni ve onarim emri

> Uretim: **13.09.2026 00:46** (makine; elle duzenlenmez — arac/ret-kutugu.ps1). Bedel 0.
> Taranan 5.627 soru · dusen **1.852** (%32,9)

## KURAL

**Uretim turu bittiginde bu betik kosar. Ret nedenleri okunmadan yeni tur baslatilmaz.**
Bir kok neden sinifi ilk uce giriyorsa once ona KAPI kurulur — kapisiz tekrar uretim, ayni parayi ikinci kez yakar.

## 1 · HANGI KAPI DUSURDU

| Kapi | Soru | Pay |
|---|---:|---:|
| KAPI-HAKEM | 930 | %50,2 |
| KAPI-HAKEM2 | 368 | %19,9 |
| KAPI-SIM | 291 | %15,7 |
| KAPI-KOR | 151 | %8,2 |
| hakem KOSMADI | 112 | %6,0 |

## 2 · KOK NEDEN SINIFI — asil okunacak tablo

| Sinif | Soru | Pay | Onarim yolu |
|---|---:|---:|---|
| KAYNAK-EKSIK | 785 | %42,4 | Paket cevabi destekleyen HUKMU tasimiyor. Once KAYNAK SIRALAMASI (KAPI-KP) ve konu-kaynak bagi bakilir; kaynak ambarda yoksa yutma is emri. |
| SIM-YANLIS | 291 | %15,7 | Ogrenci simulasyonu yanlis cevapladi. Celdirici cok guclu ya da istem mugllak; genelde tek kelime duzeltmesi yeter. |
| YZ-KOKUSU | 218 | %11,8 | Yapay zeka kokusu: en uzun sik dogru, mutlak ifade. Sik boylari esitlenir, mutlak zarflar atilir. |
| (siniflanmamis) | 206 | %11,1 | **Desen yok — yeni kusur ailesi olabilir, asagidaki orneklere bak ve SINIF listesine desen ekle.** |
| KOR-CELISKI | 151 | %8,2 | Bagimsiz kor cozum anahtardan FARKLI cevap verdi. Ikisinden biri yanlis: once anahtari elle dogrula, sonra soruyu yeniden uret. |
| HAKEM-KOSMADI | 112 | %6,0 | Soru hic denetlenmemis. Parti -PilotId ile yeniden kosulur; kapilardan gecerse hasada girer. |
| KAYNAK-KESIK | 46 | %2,5 | Kaynak paketi KIRPILMIS (kp-01 sinifi). KAPI-KP (11.09) bunu onluyor; ESKI kayitlar icin hakem tazelenir. |
| YAPAY-DIL | 14 | %0,8 | Dil kapisi. Istem, cikmis sinav yazimina gore yeniden kurulur. |
| COK-ANLAMLI | 13 | %0,7 | Istem cumlesi tek anlama indirilir; cogu zaman tek kelime duzeltmesi yeter. |
| SINAV-DUZEYI | 10 | %0,5 | Soru SGS duzeyinin USTUNDE (paragraf numarasi sorgusu vb). Konu kartina zorluk tavani yazilir; soru sadelestirilir. |
| CELDIRICI-SAHTE | 6 | %0,3 | Celdirici sayilar uydurulmus. KAPI-C yolu; soru yeniden uretilir. |

### Siniflanmamis 206 gerekceden ornekler

- kgk-bosluk-trkiyedenetimstandartlar/kp-06 [KAPI-HAKEM] Soru VUK m.323'e dayansa da, şüpheli alacak karşılığı muhasebe/vergi muhasebesi konusu olup bağımsız denetim standartları kapsamında değildir.
- kgk-kurfin-30/kp-05 [KAPI-HAKEM] Kaynak metni matematik (kesirler) teorisi içerir; soru ise saf matematik problemidir ve denetçilik/muhasebe/finansal yönetim bilgisine dayanmaz.
- sgs-bc-denetim-zor-r1/kp-01 [KAPI-HAKEM2] SGS Denetim sorularında genellikle işlem/uygulama, TDS madde-hükmü veya kısa tanım sorulur; bu soru uluslararası kurumsal yapı (IASB/IFAC/IFRS Vakfı) şemasını ezbere dayalı ve akademik/CPA s…
- sgs-bc-ekonomi-kolay-r1/kp-01 [KAPI-HAKEM] Doğru sık (C) yanlış işaretlenmiştir; likidite tuzağında para arzı artışı faizi düşüremez, bu nedenle 'faiz oranını düşürmeye devam eder' ifadesi yanlıştır ve yanlış olduğu belirtilen ifaded…
- sgs-bc-meslek-cokzor-r1/kp-02 [KAPI-HAKEM2] Gerçek SGS sorularında şıklar kısa, gerekçesiz sonuç ifadeleridir. Burada B-E şıkları 'X Tuzağı: ...sanırsın. Doğrusu: ...' şeklinde öğretici/meta-açıklama kalıbıyla yazılmış; bu ne kadar TE…
- sgs-c2-denetim-cokzor-r3/kp-02 [KAPI-HAKEM2] TESMER denetim sorularında şıklar genelde 'sonuç + kısa etiket' biçimindedir, gerekçe şıkta yer almaz; burada her şık 'X'dir çünkü/ile ...' kalıbıyla uzun gerekçe/tanım içeriyor, bu ders kit…
- sgs-c2-ekonomi-cokzor-r1/kp-01 [KAPI-HAKEM2] B ve C şıkları gerçek bir kavram karışıklığını yansıtıyor (Stolper-Samuelson'ı Heckscher-Ohlin faktör bolluğu mantığıyla karıştırma), bu güçlü bir çeldirici; ama D ve E şıkları gerçekçi bir …
- sgs-c2-fmuh-cokzor-r1/kp-06 [KAPI-HAKEM2] Kök yapısı (varlık tanımı + birden fazla masraf kalemi + sonuç isteme), şık formatı (sonuç TL, gerekçesiz, yakın aralıklı rakamlar) SGS finansal muhasebe/TFRS sorularıyla uyumlu; dil ve veri…
- sgs-c2-fmuh-cokzor-r2/kp-06 [KAPI-HAKEM] Soru TMS 36 kapsamında stoklar için değer düşüklüğü uygulanmasını soruyor, ancak TMS 36 p.2(a) ve p.3'e göre stoklar TMS 36'nın kapsamı dışındadır ve TMS 2 Stoklar Standardı uygulanır. Soru …
- sgs-c2-fmuh-cokzor-r3/kp-03 [KAPI-HAKEM] TMS 38 p.2(d) ve p.3 kapsamında maden çıkarma hakkı, Madenler, petrol, doğal gaz ve benzeri yenilenemeyen kaynakların geliştirilmesi ve çıkarılmasına ilişkin harcamalar istisnası altında old…
- sgs-c2-fmuh-cokzor-r3/kp-05 [KAPI-HAKEM] TMS 36 p.2 açıkça 'Stoklar (bakınız: TMS 2 Stoklar)' istisnası nedeniyle TMS 36 stok değer düşüklüğüne uygulanmaz; sorunun dayanağı geçersizdir. Ticari malların stok değer düşüklüğü TMS 2 ka…
- sgs-c2-fmuh-cokzor-r3/kp-09 [KAPI-HAKEM2] Soru metninde alım komisyonu 4.000 TL ayrıca verilmiş ve maliyete dahil edilmesi gerekir (edinme maliyeti = 164.000+4.000=168.000 TL). Bu durumda toplam faiz farkı 200.000-168.000=32.000 TL …

## 3 · ONARIM EMRI — sinif sinif ilk 10 soru

### KAYNAK-EKSIK (785 soru)

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

### SIM-YANLIS (291 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-maliye-zor-r1/kp-11 | parafiskal gelir |  |
| sgs-bc-borclar-kolay-r1/kp-03 | muteselsil sorumluluk |  |
| sgs-bc-issgk-kolay-r3/kp-01 | sigortali sayilma |  |
| sgs-bc-mta-cokzor-r2/kp-02 | dikey yuzdelerden bilanco yorumu |  |
| sgs-bc-mta-zor-r1/kp-02 | stokta kalma suresi hesabi |  |
| sgs-bc-ticaret-zor-r3/kp-01 | cek hukuku |  |
| sgs-c2-borclar-cokzor-r1/kp-01 | sozlesmenin kurulmasi |  |
| sgs-c2-denetim-cokzor-r2/kp-02 | denetim riski |  |
| sgs-c2-denetim-zor-r3/kp-03 | bagimsiz denetim sureci |  |
| sgs-c2-fmuh-cokzor-r1/kp-14 | maddi duran varlik denetimi |  |

### YZ-KOKUSU (218 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-02 | denetim calisma kagitlari | KOKU: B, D, E şıkları hemen hemen aynı kalıbın ('yalnızca X'i kapsar, Y'yi kapsamaz/hizmet etmez') tekrarı şeklinde kurulmuş. |
| sgs-a6-denetim-cokzor-r1/kp-04 | calisma kagitlari | KOKU: A, B, C şıklarının hepsi aynı 'X yeterlidir, Y gerekmez' kalıbının tekrarı, yapay simetri kokusu var |
| sgs-a6-maliye-zor-r1/kp-04 | vergilemede etkinlik | KOKU: Soru kökündeki 'ekonomik, malî ve sosyal etkinliğin birlikte sağlanması' ifadesi doğru şıkta (B) birebir tekrarlanıyor; bu doğru cevabı kelime e… |
| sgs-bc-ekonomi-kolay-r2/kp-01 | likidite tuzagi | KOKU: B ve D şıkları birbirine çok benzer ve içiçe geçmiş çeldirici yapıda, bu tekrar hafif yapay bir düzenlemeyi düşündürüyor |
| sgs-bc-fmuh-cokzor-r1/kp-05 | menkul sermaye iradi sayilmayanlar | KOKU: Tüm tutarlar tam yuvarlak sayılar (2.000 adet, 10 TL, 20.000, 300, 26.000, 400) - gerçek sınavda da sık görülse de tekrar eden bir yuvarlaklık d… |
| sgs-bc-vergi-kolay-r3/kp-01 | vuk degerleme olculeri | Soru kökü ve şık biçimi (kısa teorik tanım cümleleri, 'yanlıştır' kalıbı) VUK değerleme ölçüleri sorularına benzese de, Vergi Hukuku/Muhasebe sınavlar… |
| sgs-c2-denetim-cokzor-r1/kp-02 | denetim riski | Soru kökü ve konu (BDS 200 risk modeli) alan bilgisine uygun olsa da, şıklar SGS formatındaki 'sonuç+kısa etiket, gerekçesiz' yapıdan uzaklaşmış; her … |
| sgs-c2-denetim-cokzor-r1/kp-03 | iliskili taraflar denetimi | KOKU: A şıkkında 'sadece' ifadesiyle absolüt dil kalıbı tekrarlanıyor; C'de 'incelemeksizin' ile aynı absolutist kalıp tekrar ediyor - dört çeldiricin… |
| sgs-c2-denetim-cokzor-r1/kp-04 | guvence hizmetleri | KOKU: A, B, C, D şıklarında 'kapsamına alır/almaz' zıtlıklarının tekrarı biraz kalıpsal ama sınavlarda da görülen bir stil |
| sgs-c2-denetim-cokzor-r1/kp-05 | is guvencesi | KOKU: A ve B şıkları birbirine yakın/tekrar niteliğinde (ikisi de mutlak güvence vurgusu yapıyor) |

### KOR-CELISKI (151 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-bc-fmuh-cokzor-r2/kp-02 | ortalama tahsilat suresi | kor cozum B · anahtar A |
| sgs-bc-fmuh-cokzor-r2/kp-04 | kambiyo senetleri | kor cozum B · anahtar A |
| sgs-bc-maliyet-zor-r1/kp-01 | maliyet yontemleri karsilastirma | kor cozum B · anahtar E |
| sgs-bc-mta-zor-r3/kp-01 | cari oran analizi | kor cozum E · anahtar B |
| sgs-bc-vergi-cokzor-r1/kp-01 | ozel tuketim vergisi | kor cozum C · anahtar A |
| sgs-c2-denetim-kolay-r3/kp-04 | denetim belgelendirme | kor cozum HİÇBİRİ · anahtar D |
| sgs-c2-denetim-zor-r1/kp-01 | denetim kaniti guvenilirligi | kor cozum C · anahtar B |
| sgs-c2-fmuh-cokzor-r1/kp-03 | tms 38 maddi olmayan duran varlik | kor cozum C · anahtar A |
| sgs-c2-fmuh-cokzor-r1/kp-04 | kar dagitimi kaydi | kor cozum HİÇBİRİ · anahtar B |
| sgs-c2-fmuh-cokzor-r1/kp-07 | kasa sayim farki | kor cozum C · anahtar A |

### HAKEM-KOSMADI (112 soru)

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

### KAYNAK-KESIK (46 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| kgk-bosluk-sigortaclkvezelemeklilikmevzuat/kp-07 | sigorta ettiren yukumlulukleri | Kaynak metinde m.3/4 hükmü açıkça yer almamakta; sağlanan metinde yalnızca m.1, m.2 ve m.3'ün başlangıcı bulunmakta olup kooperatiflerin üyeleri dışın… |
| kgk-kurfin-30/kp-13 | optimal sermaye yapisi | Kaynak metni sermaye bütçelemesi, işletme sermayesi yönetimi ve belirsizlik altında yatırım kararlarını kapsamakta; sermaye yapısı teorileri bölümü ke… |
| sgs-c2-borclar-cokzor-r1/kp-03 | haksiz fiil unsurlari | Kaynak metni TBK m.49'u içermediği için doğru sık dayanağı kaynaktan teyit edilemiyor; m.56 manevi tazminat, m.55 bedensel zararlar, m.48 temsil yetki… |
| sgs-gk-pilot-ekonomi-zor/kp-01 | mutlak ustunlukler teorisi | Soru 'mutlak üstünlükler teorisi' konusunu ölçüyor ve doğru sikk (B) teorinin tanımına göre hatalıdır; X tekstilde 4 saat (daha az) ile Y'nin 6 saatin… |
| sgs-kapituru-11eylul/kp-01 | muhasebe bilgi sistemi | Kaynak metni muhasebe bilgi sistemi kontrolleri ve nakit dönüşüm döngüsü konularını içermekte, mizan türleri ve kesin mizanın tanımını açıklayan teori… |
| sgs-p-meslek-cokzor-r2-a/kp-04 | ucret tarifesi | Dogru sikkin dayandigi Etik İlkeler Yönetmeliği madde 3/1-a kaynakta sunulmamıştır; kaynakta yalnızca m.1 (temel ilkeler) yer almakta, madde 3 ve 'kiş… |
| sgs-p-ticaret-cokzor-r3-b2/kp-06 | sirket birlesmesi | Kaynak metni (TTK m.39-42) ticaret unvanı ve şirket türlerine ilişkin hükümleri içermekte, ancak birleşme-bölünme-tür değiştirme kapsamında 'genel kur… |
| sgs-p-ticaret-zor-r2-b2/kp-02 | tacir sifati | Kaynak metinde m.12/2 ve m.16/1 doğru tarafından desteklenirken, m.16/2 açıkça II. ve IV. seçeneklerin tacir olmadığını belirtir; ancak m.12/1 eksik o… |
| sgs-p-vergi-kolay-r3-a/kp-03 | kdv istisnalari | Kaynak metni madde 12'yi içermemektedir; soru madde 12/1'e atıf yapmakta ancak kaynakta madde 11 ve madde 12'nin başlığı (İKİNCİ BÖLÜM Araçlar...) yer… |
| sgs-t1-borclar-kolay/kp-10 | sebepsiz zenginlesme giderler | Kaynak metinde m.79/II başlığı 'Giderleri isteme hakkı' görünmekle birlikte, bu bölümün tam metni ve zorunlu giderlerin zaman sınırlaması (öğrendiği a… |

### YAPAY-DIL (14 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-maliye-zor-r1/kp-10 | operasyonel acik | Soru kökü ve kavram seti ('işletmenin bütçe harcaması/geliri', 'operasyonel açık') kamu maliyesi/bütçe açığı analizinde kullanılan, gerçek SGS Maliye … |
| sgs-c5-borclar-kolay-r2/kp-07 | borclarin degerlemesi (mukayyet deger) | C ve B gerçek bir kavram karışıklığını (seçim hakkı borçluda ama sınırsız mı, ortalama nitelik sınırı var mı) yansıtsa da D ve E şıkları gerçek bir öğ… |
| sgs-c5-fmuh-kolay-r2/kp-03 | iasb calismalari | SGS Finansal Muhasebe sorularında bu tarz IFRS Vakfı kurumsal yapı/organ tanımı soruları çıkmaz; bu konu daha çok teorik denetim/muhasebe standartları… |
| sgs-c5-meslek-zor-r1/kp-08 | 3568 sayili kanun birlik | SGS Meslek Hukuku sorularında mevzuat metnindeki sayısal bilgi doğrudan bilgi/hatırlama şeklinde sorulur; burada yapay bir aritmetik işlem (fark-fark)… |
| sgs-p-ekonomi-kolay-r3-a/kp-01 | talep esnekligi | Soru kökü ve veri sunumu (|e|=0,6, fiyat artışı) klasik esneklik-hasılat kalıbına uygun; ancak gerçek TESMER sorularında şıklar genelde kısa sonuç ifa… |
| sgs-t1-denetim-cokzor/kp-17 | bds 230 calisma kagitlari | Soru kökü ve şıklar teorik/kavramsal metin yorumu tarzında, gerçek SGS sınavında BDS hükümleri genellikle somut bir denetim olayı/senaryo üzerinden ve… |
| sgs-t1-genel-maliye-cokzor/kp-01 | butce ilkeleri | Gerçek SGS/Maliye sorularında ilke eşleştirmelerinde şıklar genelde sadece ilkenin adından oluşur (kısa etiket); burada her şık ayrıca uzun bir tanım … |
| sgs-t1-genel-turkce-kolay/kp-19 | kisa cizgi kullanimi | Soru kalıbı ve şık biçimi (tek cümle, kısa etiketsiz) yüzeysel olarak sınav sorusuna benziyor; ancak D şıkkındaki 'de-bu' biçimi TDK kısa çizgi kullan… |
| sgs-t1-genel-yd-cokzor/kp-37 | cumle tamamlama-although | Kalıp (although ile başlayan zıtlık tümleme sorusu) SGS/YDS tipi sorulara benzese de şık biçimi bozuk: C ve D şıkları kendi içinde bağımsız bağlaç (be… |
| sgs-t1-genel-yd-kolay/kp-28 | adverb usage | B, C, E şıkları gerçek kelime türü karışıklığı (sıfat/isim/superlative) yansıtsa da D şıkkı gerçekçi bir adayın düşebileceği tek bir hata değil, iki f… |

### COK-ANLAMLI (13 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-c2-denetim-zor-r3/kp-02 | stok sayimi denetimi | 5.000 olumlu/olumsuz çeldirici mantıklı (yön karıştırma hatası), ama 25.000 tutarının hangi işlem hatasından (örn. alış-satış maliyeti farkının yanlış… |
| sgs-fmuh-parti1/kp-01 | muhasebe bilgi sistemi | 900 TL'lik sapma seçeneklerinin (A ve C) nereden türetildiği belirsizdir; verilen 6 rakamdan mantıklı bir yanlış toplama, atlama veya rakam ters yazma… |
| sgs-p-fmuh-kolay-r3/kp-07 | isletmenin surekliligi | Soru Denetim standardı (BDS 570) hakkında olup Finansal Muhasebe dersinin kapsamı dışındadır; Denetim dersinin konusudur. Kaynak metinde (TEORI bölümü… |
| sgs-p-issgk-zor-r1-a/kp-07 | belirli sureli is sozlesmesi | İfade II (belirli süreli sözleşme sözlü yapılabilir) kaynakta açıkça yanlışlanmakta; m.11 'yazılı şekilde' şartı ve m.8 'süresi bir yıl ve daha fazla'… |
| sgs-t1-fmuh-cokzor/kp-71 | satistan iade-surekli envanter | 610 Satıştan İadeler hesabı tanımında 'fatura tutarları' kapsar denilmektedir; kaynak metinde nakliye bedelinin iadesinde 610'a kaydedilmeyeceği açıkç… |
| sgs-t1-fmuh-cokzor/kp-89 | muhasebe bilgi sistemi kontrolleri | SGS Finansal Muhasebe sınavı tipik olarak hesap/işlem bazlı sayısal veya doğru-yanlış kısa teori soruları içerir; bu soru bilgi sistemleri denetimi/iç… |
| sgs-t1-genel-ekonomi-kolay/kp-02 | taylor prensibi | C(8) ve A(4) mantıklı hata kaynakları (sadece enflasyonu alma, sadece katsayı terimini alma) olsa da D(10) ve B(7) için net bir hesaplama hatası izlen… |
| sgs-t1-genel-turkce-kolay/kp-31 | belirtisiz ad tamlamasi | C şıkkı 'Yün kazak' dil bilgisinde tartışmalı bir örnektir; bazı kaynaklarda madde+isim ilişkisi nedeniyle belirtisiz ad tamlaması, bazılarında sıfat … |
| sgs-t1-mta-cokzor/kp-02 | yatay analiz | B(150.000=60.000/0,4 UFE ile karıştırma) ve E(300.000=60.000/0,2) mantıklı çeldiriciler; C(180.000) hangi hatadan türediği belirsiz; A(2.400) ise muht… |
| sgs-t2b-borclar-zor/kp-01 | sebepsiz zenginlesme | Doğru sık ifadesi eksik ve yanıltıcı; TBK m.79'a göre iyiniyetli elden çıkaran kişi için 'iade gerekir ama iyiniyetle elden çıkan kısım kapsam dışıdır… |

### SINAV-DUZEYI (10 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-01 | denetim kaniti yeterliligi | SGS denetim sorularında standart paragraf numarası (A27-A29) verilerek 'birlikte değerlendirildiğinde' şeklinde akademik/hukuk sınavı kalıbı kullanılm… |
| sgs-c2-maliye-kolay-r1/kp-02 | otomatik istikrarlandirici | Gerçek SGS maliye sorularında şıklar kısa, sonuç bildiren ifadelerdir; burada her şık uzun, gerekçeli, alt-analiz içeren tam cümleler (örn. 'genişleme… |
| sgs-c5-fmuh-cokzor-r2-2/kp-19 | genel standartlar (deneyim) | SGS denetim soruları genelde kısa, somut bir olay/duruma dayalı ve tek bir kuralı test eden sorulardır (örn. 'X durumunda hangi standart ihlal edilmiş… |
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

