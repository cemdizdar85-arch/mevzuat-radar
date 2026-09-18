# RET KUTUGU — dusen sorularin nedeni ve onarim emri

> Uretim: **18.09.2026 04:11** (makine; elle duzenlenmez — arac/ret-kutugu.ps1). Bedel 0.
> Taranan 10.715 soru · dusen **3.521** (%32,9)

## KURAL

**Uretim turu bittiginde bu betik kosar. Ret nedenleri okunmadan yeni tur baslatilmaz.**
Bir kok neden sinifi ilk uce giriyorsa once ona KAPI kurulur — kapisiz tekrar uretim, ayni parayi ikinci kez yakar.

## 1 · HANGI KAPI DUSURDU

| Kapi | Soru | Pay |
|---|---:|---:|
| KAPI-HAKEM | 1.674 | %47,5 |
| KAPI-HAKEM2 | 813 | %23,1 |
| KAPI-SIM | 633 | %18,0 |
| KAPI-KOR | 370 | %10,5 |
| hakem KOSMADI | 31 | %0,9 |

## 2 · KOK NEDEN SINIFI — asil okunacak tablo

| Sinif | Soru | Pay | Onarim yolu |
|---|---:|---:|---|
| KAYNAK-EKSIK | 1.447 | %41,1 | Paket cevabi destekleyen HUKMU tasimiyor. Once KAYNAK SIRALAMASI (KAPI-KP) ve konu-kaynak bagi bakilir; kaynak ambarda yoksa yutma is emri. |
| SIM-YANLIS | 633 | %18,0 | Ogrenci simulasyonu yanlis cevapladi. Celdirici cok guclu ya da istem mugllak; genelde tek kelime duzeltmesi yeter. |
| YZ-KOKUSU | 499 | %14,2 | Yapay zeka kokusu: en uzun sik dogru, mutlak ifade. Sik boylari esitlenir, mutlak zarflar atilir. |
| (siniflanmamis) | 374 | %10,6 | **Desen yok — yeni kusur ailesi olabilir, asagidaki orneklere bak ve SINIF listesine desen ekle.** |
| KOR-CELISKI | 370 | %10,5 | Bagimsiz kor cozum anahtardan FARKLI cevap verdi. Ikisinden biri yanlis: once anahtari elle dogrula, sonra soruyu yeniden uret. |
| KAYNAK-KESIK | 74 | %2,1 | Kaynak paketi KIRPILMIS (kp-01 sinifi). KAPI-KP (11.09) bunu onluyor; ESKI kayitlar icin hakem tazelenir. |
| HAKEM-KOSMADI | 31 | %0,9 | Soru hic denetlenmemis. Parti -PilotId ile yeniden kosulur; kapilardan gecerse hasada girer. |
| COK-ANLAMLI | 31 | %0,9 | Istem cumlesi tek anlama indirilir; cogu zaman tek kelime duzeltmesi yeter. |
| YAPAY-DIL | 27 | %0,8 | Dil kapisi. Istem, cikmis sinav yazimina gore yeniden kurulur. |
| CELDIRICI-SAHTE | 17 | %0,5 | Celdirici sayilar uydurulmus. KAPI-C yolu; soru yeniden uretilir. |
| SINAV-DUZEYI | 17 | %0,5 | Soru SGS duzeyinin USTUNDE (paragraf numarasi sorgusu vb). Konu kartina zorluk tavani yazilir; soru sadelestirilir. |
| ESKI-MEVZUAT | 1 | %0,0 | Kaynak bayat. Ambardaki mevzuat tazelenir, soru yeniden uretilir. |

### Siniflanmamis 374 gerekceden ornekler

- kgk-bosluk-trkiyedenetimstandartlar/kp-06 [KAPI-HAKEM] Soru VUK m.323'e dayansa da, şüpheli alacak karşılığı muhasebe/vergi muhasebesi konusu olup bağımsız denetim standartları kapsamında değildir.
- kgk-kurfin-30/kp-05 [KAPI-HAKEM] Kaynak metni matematik (kesirler) teorisi içerir; soru ise saf matematik problemidir ve denetçilik/muhasebe/finansal yönetim bilgisine dayanmaz.
- sgs-bc-denetim-zor-r1/kp-01 [KAPI-HAKEM2] SGS Denetim sorularında genellikle işlem/uygulama, TDS madde-hükmü veya kısa tanım sorulur; bu soru uluslararası kurumsal yapı (IASB/IFAC/IFRS Vakfı) şemasını ezbere dayalı ve akademik/CPA s…
- sgs-bc-meslek-cokzor-r1/kp-02 [KAPI-HAKEM2] Gerçek SGS sorularında şıklar kısa, gerekçesiz sonuç ifadeleridir. Burada B-E şıkları 'X Tuzağı: ...sanırsın. Doğrusu: ...' şeklinde öğretici/meta-açıklama kalıbıyla yazılmış; bu ne kadar TE…
- sgs-bosluk-meslekhukuku/kp-01 [KAPI-HAKEM2] 3568 sayılı Kanun m.45 ve ilgili tasdik yasağı düzenlemelerinde 'boşanmış eş'in tasdik yasağı kapsamında sayılacağına dair açık bir hüküm yoktur; ayrıca C şıkkında SMMM'nin zaten tasdik yetk…
- sgs-c2-denetim-cokzor-r3/kp-02 [KAPI-HAKEM2] TESMER denetim sorularında şıklar genelde 'sonuç + kısa etiket' biçimindedir, gerekçe şıkta yer almaz; burada her şık 'X'dir çünkü/ile ...' kalıbıyla uzun gerekçe/tanım içeriyor, bu ders kit…
- sgs-c2-ekonomi-cokzor-r1/kp-01 [KAPI-HAKEM2] B ve C şıkları gerçek bir kavram karışıklığını yansıtıyor (Stolper-Samuelson'ı Heckscher-Ohlin faktör bolluğu mantığıyla karıştırma), bu güçlü bir çeldirici; ama D ve E şıkları gerçekçi bir …
- sgs-c2-fmuh-cokzor-r1/kp-06 [KAPI-HAKEM2] Kök yapısı (varlık tanımı + birden fazla masraf kalemi + sonuç isteme), şık formatı (sonuç TL, gerekçesiz, yakın aralıklı rakamlar) SGS finansal muhasebe/TFRS sorularıyla uyumlu; dil ve veri…
- sgs-c2-fmuh-cokzor-r1-2/kp-02 [KAPI-HAKEM2] Soru dil ve şık biçimi olarak (sonuç+kısa gerekçe, beş ifadeden aykırı olanı bulma) sınav kalıbına uysa da, TFRS 18 gibi çok yeni ve son derece teknik bir standardın madde numarası düzeyinde…
- sgs-c2-fmuh-cokzor-r2/kp-06 [KAPI-HAKEM] Soru TMS 36 kapsamında stoklar için değer düşüklüğü uygulanmasını soruyor, ancak TMS 36 p.2(a) ve p.3'e göre stoklar TMS 36'nın kapsamı dışındadır ve TMS 2 Stoklar Standardı uygulanır. Soru …
- sgs-c2-fmuh-cokzor-r3/kp-03 [KAPI-HAKEM] TMS 38 p.2(d) ve p.3 kapsamında maden çıkarma hakkı, Madenler, petrol, doğal gaz ve benzeri yenilenemeyen kaynakların geliştirilmesi ve çıkarılmasına ilişkin harcamalar istisnası altında old…
- sgs-c2-fmuh-cokzor-r3/kp-05 [KAPI-HAKEM] TMS 36 p.2 açıkça 'Stoklar (bakınız: TMS 2 Stoklar)' istisnası nedeniyle TMS 36 stok değer düşüklüğüne uygulanmaz; sorunun dayanağı geçersizdir. Ticari malların stok değer düşüklüğü TMS 2 ka…

## 3 · ONARIM EMRI — sinif sinif ilk 10 soru

### KAYNAK-EKSIK (1447 soru)

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

### SIM-YANLIS (633 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6e-meslek-kolay/kp-02 | buro edinme zorunlulugu |  |
| sgs-a6-maliye-zor-r1/kp-11 | parafiskal gelir |  |
| sgs-bc-borclar-kolay-r1/kp-03 | muteselsil sorumluluk |  |
| sgs-bc-issgk-kolay-r3/kp-01 | sigortali sayilma |  |
| sgs-bc-mta-cokzor-r2/kp-02 | dikey yuzdelerden bilanco yorumu |  |
| sgs-bc-mta-zor-r1/kp-02 | stokta kalma suresi hesabi |  |
| sgs-bc-ticaret-zor-r3/kp-01 | cek hukuku |  |
| sgs-bosluk-borclarhukuku/kp-07 | borclu temerrudu |  |
| sgs-bosluk-ekonomi/kp-03 | marjinal fayda |  |
| sgs-bosluk-meslekhukuku/kp-03 | buro edinme zorunlulugu |  |

### YZ-KOKUSU (499 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-02 | denetim calisma kagitlari | KOKU: B, D, E şıkları hemen hemen aynı kalıbın ('yalnızca X'i kapsar, Y'yi kapsamaz/hizmet etmez') tekrarı şeklinde kurulmuş. |
| sgs-a6-denetim-cokzor-r1/kp-04 | calisma kagitlari | KOKU: A, B, C şıklarının hepsi aynı 'X yeterlidir, Y gerekmez' kalıbının tekrarı, yapay simetri kokusu var |
| sgs-a6-maliye-zor-r1/kp-04 | vergilemede etkinlik | KOKU: Soru kökündeki 'ekonomik, malî ve sosyal etkinliğin birlikte sağlanması' ifadesi doğru şıkta (B) birebir tekrarlanıyor; bu doğru cevabı kelime e… |
| sgs-bc-ekonomi-kolay-r2/kp-01 | likidite tuzagi | KOKU: B ve D şıkları birbirine çok benzer ve içiçe geçmiş çeldirici yapıda, bu tekrar hafif yapay bir düzenlemeyi düşündürüyor |
| sgs-bc-fmuh-cokzor-r1/kp-05 | menkul sermaye iradi sayilmayanlar | KOKU: Tüm tutarlar tam yuvarlak sayılar (2.000 adet, 10 TL, 20.000, 300, 26.000, 400) - gerçek sınavda da sık görülse de tekrar eden bir yuvarlaklık d… |
| sgs-bc-vergi-kolay-r3/kp-01 | vuk degerleme olculeri | Soru kökü ve şık biçimi (kısa teorik tanım cümleleri, 'yanlıştır' kalıbı) VUK değerleme ölçüleri sorularına benzese de, Vergi Hukuku/Muhasebe sınavlar… |
| sgs-bosluk-borclarhukuku/kp-03 | kusursuz sorumluluk halleri | KOKU: Şirket adı 'XYZ Kimya A.Ş.' şeklinde anlamsız harf dizisi kullanılmış, bu yer tutucu kokusu taşır |
| sgs-bosluk-denetim/kp-01 | denetim riski | KOKU: A ve E şıkları birbirine yakın/ters kurgulanmış (önemli yanlışlık riskinin bileşenleri konusunda simetrik yanlış), klişe/kalıp tekrarı yok ama D… |
| sgs-bosluk-svesosyalguvenlikhukuku/kp-07 | calisma suresi | KOKU: Şık A ve D birbirine yakın/tekrarlayan fikirler (sorumluluk fabrika müdüründe) ile gereksiz tekrar |
| sgs-c2-denetim-cokzor-r1/kp-02 | denetim riski | Soru kökü ve konu (BDS 200 risk modeli) alan bilgisine uygun olsa da, şıklar SGS formatındaki 'sonuç+kısa etiket, gerekçesiz' yapıdan uzaklaşmış; her … |

### KOR-CELISKI (370 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-bc-fmuh-cokzor-r2/kp-02 | ortalama tahsilat suresi | kor cozum B · anahtar A |
| sgs-bc-fmuh-cokzor-r2/kp-04 | kambiyo senetleri | kor cozum B · anahtar A |
| sgs-bc-maliyet-zor-r1/kp-01 | maliyet yontemleri karsilastirma | kor cozum B · anahtar E |
| sgs-bc-mta-zor-r3/kp-01 | cari oran analizi | kor cozum E · anahtar B |
| sgs-bc-vergi-cokzor-r1/kp-01 | ozel tuketim vergisi | kor cozum C · anahtar A |
| sgs-bosluk-svesosyalguvenlikhukuku/kp-04 | ucret yonetmeligi kurallari | kor cozum B · anahtar A |
| sgs-c2-denetim-kolay-r3/kp-04 | denetim belgelendirme | kor cozum HİÇBİRİ · anahtar D |
| sgs-c2-denetim-zor-r1/kp-01 | denetim kaniti guvenilirligi | kor cozum C · anahtar B |
| sgs-c2-fmuh-cokzor-r1/kp-03 | tms 38 maddi olmayan duran varlik | kor cozum C · anahtar A |
| sgs-c2-fmuh-cokzor-r1/kp-04 | kar dagitimi kaydi | kor cozum HİÇBİRİ · anahtar B |

### KAYNAK-KESIK (74 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| kgk-bosluk-sigortaclkvezelemeklilikmevzuat/kp-07 | sigorta ettiren yukumlulukleri | Kaynak metinde m.3/4 hükmü açıkça yer almamakta; sağlanan metinde yalnızca m.1, m.2 ve m.3'ün başlangıcı bulunmakta olup kooperatiflerin üyeleri dışın… |
| kgk-kurfin-30/kp-13 | optimal sermaye yapisi | Kaynak metni sermaye bütçelemesi, işletme sermayesi yönetimi ve belirsizlik altında yatırım kararlarını kapsamakta; sermaye yapısı teorileri bölümü ke… |
| sgs-c2-borclar-cokzor-r1/kp-03 | haksiz fiil unsurlari | Kaynak metni TBK m.49'u içermediği için doğru sık dayanağı kaynaktan teyit edilemiyor; m.56 manevi tazminat, m.55 bedensel zararlar, m.48 temsil yetki… |
| sgs-d3-issgk-kolay-r1/kp-07 | grev lokavt | Sorunun doğru cevabı olarak sunulan sikka dayanak olarak gösterilen 5510 s. SGK Kanunu m.41/1-g, sağlanan kaynak metinlerinde yer almamaktadır. Kaynak… |
| sgs-d5-ticaret-zor-r1/kp-03 | sirket birlesmesi | Kaynak metni paketi, şirket birleşmesi konusunun somut ve katmanlı sorularını üretmek için gerekli hükümleri (TTK m.136-158: birleşme türleri, sözleşm… |
| sgs-fmuh-parti1/kp-06 | tms-38 maddi olmayan duran varliklar | Kaynak metinde itfa başlangıç tarihi, itfa yöntemi seçimi ve hasılat esaslı yöntemin uygulanmaması koşulları açıkça yer almakta, hesaplama mantığı doğ… |
| sgs-gk-pilot-ekonomi-zor/kp-01 | mutlak ustunlukler teorisi | Soru 'mutlak üstünlükler teorisi' konusunu ölçüyor ve doğru sikk (B) teorinin tanımına göre hatalıdır; X tekstilde 4 saat (daha az) ile Y'nin 6 saatin… |
| sgs-kapituru-11eylul/kp-01 | muhasebe bilgi sistemi | Kaynak metni muhasebe bilgi sistemi kontrolleri ve nakit dönüşüm döngüsü konularını içermekte, mizan türleri ve kesin mizanın tanımını açıklayan teori… |
| sgs-p-meslek-cokzor-r2-a/kp-04 | ucret tarifesi | Dogru sikkin dayandigi Etik İlkeler Yönetmeliği madde 3/1-a kaynakta sunulmamıştır; kaynakta yalnızca m.1 (temel ilkeler) yer almakta, madde 3 ve 'kiş… |
| sgs-p-ticaret-cokzor-r3-b2/kp-06 | sirket birlesmesi | Kaynak metni (TTK m.39-42) ticaret unvanı ve şirket türlerine ilişkin hükümleri içermekte, ancak birleşme-bölünme-tür değiştirme kapsamında 'genel kur… |

### HAKEM-KOSMADI (31 soru)

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

### COK-ANLAMLI (31 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-c2-denetim-zor-r3/kp-02 | stok sayimi denetimi | 5.000 olumlu/olumsuz çeldirici mantıklı (yön karıştırma hatası), ama 25.000 tutarının hangi işlem hatasından (örn. alış-satış maliyeti farkının yanlış… |
| sgs-c5-vergi-cokzor-r1/kp-02 | munferit beyanname | B şıkkı da GVK md.101'deki genel kurala (münferit beyannamenin kazancın iktisap edildiği tarihten itibaren 15 gün içinde verilmesi) uygun görünmektedi… |
| sgs-d2-denetim-zor-r1/kp-08 | denetim gorusu turleri | Doğru şıkta önemli bir eksiklik var: BDS 570'e göre süreklilik konusunda önemli belirsizlik varsa (açıklama yeterli olsa da) denetçi 'olumlu görüş' ve… |
| sgs-d3-vergi-kolay-r1/kp-07 | kdv indirimi | Soru kökü mevzuat atfı biçiminde sınav diline uygun görünse de doğru şık ('Bu Kanun hükümlerine göre işlem yapılır') somut bir hüküm belirtmeyen, döng… |
| sgs-d4-turkce-zor-r2/kp-06 | i. dunya savasi | Soru Türkçe dersinin (yazım, noktalama, anlatım bozukluğu, paragraf akışı) resmi kapsamına uygun olmasına rağmen, kaynak metinde soruda adı geçen olay… |
| sgs-d4-yd-zor-r2/kp-09 | cumle tamamlama (although) | D ve E bağlaç çatışması (so/because, although ile birlikte kullanılamaz) nedeniyle bariz şekilde elenebilir, gerçek çeldirici değil; ama daha önemlisi… |
| sgs-e16b-fmuh-cokzor/kp-01 | finansman bonosu ihraci | Kaynak metni, 308 hesabının işleyişinde 'vadeye paralel olarak itfa edilmesi' ilkesini belirtir ancak, soru 780 Finansman Giderleri hesabına yazılan t… |
| sgs-fmuh-parti1/kp-01 | muhasebe bilgi sistemi | 900 TL'lik sapma seçeneklerinin (A ve C) nereden türetildiği belirsizdir; verilen 6 rakamdan mantıklı bir yanlış toplama, atlama veya rakam ters yazma… |
| sgs-p-denetim-cokzor-r1/kp-10 | denetim teknikleri | 120.000 TL'lik şıklar muhtemelen 20.000 TL sayım fazlasının 100.000'e eklenmesinden türetilmiş gibi görünüyor ama doğru şık açıklaması bu veriyi hiç k… |
| sgs-p-fmuh-kolay-r3/kp-07 | isletmenin surekliligi | Soru Denetim standardı (BDS 570) hakkında olup Finansal Muhasebe dersinin kapsamı dışındadır; Denetim dersinin konusudur. Kaynak metinde (TEORI bölümü… |

### YAPAY-DIL (27 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-maliye-zor-r1/kp-10 | operasyonel acik | Soru kökü ve kavram seti ('işletmenin bütçe harcaması/geliri', 'operasyonel açık') kamu maliyesi/bütçe açığı analizinde kullanılan, gerçek SGS Maliye … |
| sgs-c5-borclar-kolay-r2/kp-07 | borclarin degerlemesi (mukayyet deger) | C ve B gerçek bir kavram karışıklığını (seçim hakkı borçluda ama sınırsız mı, ortalama nitelik sınırı var mı) yansıtsa da D ve E şıkları gerçek bir öğ… |
| sgs-c5-fmuh-kolay-r2/kp-03 | iasb calismalari | SGS Finansal Muhasebe sorularında bu tarz IFRS Vakfı kurumsal yapı/organ tanımı soruları çıkmaz; bu konu daha çok teorik denetim/muhasebe standartları… |
| sgs-c5-meslek-zor-r1/kp-08 | 3568 sayili kanun birlik | SGS Meslek Hukuku sorularında mevzuat metnindeki sayısal bilgi doğrudan bilgi/hatırlama şeklinde sorulur; burada yapay bir aritmetik işlem (fark-fark)… |
| sgs-d5-denetim-kolay-r1/kp-02 | denetim kanitlari | Yanlış şıklar gerçek BDS kavramlarına (yeterlilik, maliyet, yazılı beyan, iç kontrol) atıfta bulunsa da hepsinin mekanik olarak 'Yalnızca X' kalıbına … |
| sgs-d5-denetim-kolay-r2/kp-01 | denetim kaniti yeterliligi | D şıkkı soru kökünde açıkça 'yazılı doğrulama mektubu' denmesine rağmen mektubu 'sözlü sorgulama' olarak nitelendiriyor; bu gerçek bir kavram karışıkl… |
| sgs-d5-ekonomi-cokzor-r1/kp-04 | doviz kuru sterilizasyon | SGS Ekonomi soruları genelde kısa, hesaplama veya tanım tabanlı, net iktisadi kavram sorar (arz-talep, milli gelir, döviz kuru teorileri gibi); bu sor… |
| sgs-d5-vergi-zor-r1/kp-04 | vuk kapsami | Gerçek bir adayın vergi dairesinin görevini 'yalnızca tahsilat' sanıp tarh-tahakkuku vergi mahkemesine vermesi düşünülebilir bir hata değildir; bu çel… |
| sgs-e16-vergi-cokzor/kp-04 | kurumlar vergisi istisnasi | Şık biçimi ve dil sınav kalıbına uygun ama soru içeriği (KVK 5/1-c ve 5/1-e karşılaştırması, yurt dışı iştirak istisnasının tam/kısmi ayrımı gibi çok … |
| sgs-p-ekonomi-kolay-r3-a/kp-01 | talep esnekligi | Soru kökü ve veri sunumu (|e|=0,6, fiyat artışı) klasik esneklik-hasılat kalıbına uygun; ancak gerçek TESMER sorularında şıklar genelde kısa sonuç ifa… |

### CELDIRICI-SAHTE (17 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-bc-borclar-cokzor-r2/kp-02 | takas | B şıkkı çekişmeli alacak-takas konusunu (m.145) karıştırdığı için gerçekçi bir çeldirici; ama D şıkkı 'aynı takvim yılı' gibi kanunda yer almayan, hiç… |
| sgs-d2-ticaret-kolay-r1/kp-06 | kambiyo senetleri | B ve D gerçek TTK hükümlerinin (670, 671. md) tersine çevrilmesiyle kurulmuş makul çeldiriciler; ancak E şıkkı adayın düşebileceği gerçek bir kavram k… |
| sgs-d4-mat-zor-r4/kp-02 | sayi problemi | A) 4 en küçük sayı, B) 6 ortanca, E) 14 toplam gibi anlamlı çeldiriciler olsa da C) 7 tek sayı olup ardışık çift sayı bağlamında hiçbir hesap adımında… |
| sgs-d5-ekonomi-kolay-r1/kp-04 | faiz orani sinirlamalari | Soru kökü mevzuat maddesi ezberini soran hukuk sınavı tarzında; SGS'de bu konu (Sermaye Piyasası Kanunu madde 3) hiçbir alan dersinin (Ekonomi, Maliye… |
| sgs-d5-fmuh-kolay-r1/kp-01 | muhasebe bilgi sistemi | Aylık (geçici) mizan ve Kesin mizan gerçek kavramlar olup doğru çeldirici olabilir; ancak 'Genel geçici mizan' ve 'Yevmiye mizanı' muhasebe literatürü… |
| sgs-t1-denetim-kolay/kp-30 | denetim kanit toplama prosedurleri | Kök cümle BDS 500 diline uygun ama şık seti sınav pratiğine aykırı: A ve B aynı konuya (ticari borç eksik gösterimi) odaklanırken C, D, E tamamen fark… |
| sgs-t1-fmuh-zor/kp-29 | hazine bonosu tahsili | B ve E şıkları gerçekçi bir celdirici (nominal değer ile alış bedelinin karıştırılması, net tahsilatın brüt değer sanılması) iken; C şıkkındaki 20.000… |
| sgs-t1-genel-turkce-cokzor/kp-15 | mecaz anlam | Çeldiriciler rastgele değil ama ölçme hatası var: B şıkkındaki 'göz kulak olmak' kalıbı bizatihi bir deyim olup 'göz' burada da mecazi/deyimleşmiş kul… |
| sgs-t1-genel-turkce-cokzor/kp-23 | ozne bulma | SGS Türkçe sorularında bu denli teknik dilbilgisi terminolojisi ('sözde özne', 'sıfat-fiil grubu', 'edilgen çatı' üçlü tanım birleşimi) tek kökte üst … |
| sgs-t2b-borclar-zor/kp-07 | oneri-icap kurallari | C şıkkı iyi bir çeldirici (m.11'deki 'gönderildiği an' ile 'ulaştığı an' karışıklığı gerçek bir aday tuzağı), ancak B ve D birbirinin tekrarı niteliği… |

### SINAV-DUZEYI (17 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| sgs-a6-denetim-cokzor-r1/kp-01 | denetim kaniti yeterliligi | SGS denetim sorularında standart paragraf numarası (A27-A29) verilerek 'birlikte değerlendirildiğinde' şeklinde akademik/hukuk sınavı kalıbı kullanılm… |
| sgs-c2-maliye-kolay-r1/kp-02 | otomatik istikrarlandirici | Gerçek SGS maliye sorularında şıklar kısa, sonuç bildiren ifadelerdir; burada her şık uzun, gerekçeli, alt-analiz içeren tam cümleler (örn. 'genişleme… |
| sgs-c5-fmuh-cokzor-r2-2/kp-19 | genel standartlar (deneyim) | SGS denetim soruları genelde kısa, somut bir olay/duruma dayalı ve tek bir kuralı test eden sorulardır (örn. 'X durumunda hangi standart ihlal edilmiş… |
| sgs-d2-fmuh-cokzor-r1/kp-15 | tms 1 finansal tablolar | SGS Finansal Muhasebe soruları genellikle işlem/kayıt/hesaplama ağırlıklıdır; TMS 1 paragraf 33/64 gibi standart paragraf numaralarına dayalı, çok kat… |
| sgs-d2-fmuh-cokzor-r2/kp-12 | iasb calismalari | SGS Finansal Muhasebe soruları TMS/TFRS uygulama, hesap işleyişi, mali tablo kalemi hesaplama ağırlıklı olup kısa veri setleri ve sayısal/işlemsel kök… |
| sgs-d3-fmuh-cokzor-r1/kp-20 | ozkaynak degisimi | SGS Finansal Muhasebe sorularında bu derece yeni ve niş bir standart (TFRS 18 - IFRS 18, 2024 sonrası yayınlanmış, henüz sınav müfredatına girmemiş) p… |
| sgs-d5-ekonomi-kolay-r2/kp-04 | faiz orani sinirlamalari | SGS alan bilgisinde bu konu Meslek Hukuku/Ticaret Hukuku alt başlığı içinde çok dar yer bulur; sermaye piyasası kanunu madde detayına inen bu tarz sor… |
| sgs-e16b-fmuh-kolay/kp-05 | tutarlilik ilkesi | SGS Finansal Muhasebe sorularında genelde tek bir hesaplama/kayıt ya da kavram tanımı sorulur; burada 'yöntem değişikliği + ayrı 5.000 TL fark + dipno… |
| sgs-e16b-vergi-kolay/kp-01 | vergi entegrasyon yontemleri | SGS Vergi Hukuku sorularının kalıbı genelde vergi kanunu maddelerine dayalı somut olay/oran/süre sorularıdır; bu soru maliye teorisi/vergi politikası … |
| sgs-e16b-vergi-zor/kp-01 | vergi entegrasyon yontemleri | SGS'de Maliye sorularının kökü genelde daha kısa, doğrudan tanım/hesap sorar; burada şıkların her biri uzun, ders kitabı paragrafı gibi karmaşık tanım… |

### ESKI-MEVZUAT (1 soru)

| Parti / id | Konu | Gerekce |
|---|---|---|
| smmm-4k-a-yspk-kolay-r7/kp-07 | piyasa bozucu eylem | 6362 sayılı Kanun'un mülga 35/C maddesi kripto varlık platformlarını değil borsa üyelerini/yatırım kuruluşlarını düzenlemekteydi; ayrıca kripto varlık… |

