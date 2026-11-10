# BASIM ÖNCESİ ÖLÇÜM — 10.11.2026 (0 USD)

> Yöntem: yalnız depodaki kod ve dosyalar okundu. Ambar (canlı veri) sorgulanmadı, soru okunmadı, ücretli çağrı yapılmadı.
> Bağlı belgeler: [`BASIM-ONCESI-DUZEN-TASLAK.md`](../../BASIM-ONCESI-DUZEN-TASLAK.md) · [`CEM-ISTEK-LISTESI-1011.md`](CEM-ISTEK-LISTESI-1011.md).
> **Bu ölçümün görmediği:** her alanın bankada kaç soruda dolu olduğu · alanların içeriğinin doğruluğu · SGS ve KGK yayın yolları
> (yalnız `motor/kaydir-coz.ps1` okundu) · kanun maddesi düzeyinde kart–ambar eşleşmesi (yalnız standartlar kaynak adıyla eşlendi).

---

## 1. Ekrana basılan alanlar ve denetim durumu

Kaynak: `motor/kaydir-coz.ps1` satır 535 (ekran nesnesi, 31 alan) ile `arac/aciklama-hakemi-cekirdek.ps1` `AciklamaHakemIs` (hakeme giden alanlar).

| Ekran alanı | Ambar kaydındaki kaynağı | Açıklama hakemi görüyor mu | Not |
|---|---|---|---|
| soru · şıklar · doğru | `soru` `siklar` `dogru` | Evet (ayrıca hakem, hakem2, kör, simülasyon) | En çok denetlenen katman |
| konu özeti (`konuGiris`: nedir, sınavda, yöntemler, örnek, panel örneği, harita, desen) | `konu_giris` | Evet (06.11'den beri) | Yakalama oranı ÖLÇÜLMEDİ |
| terim notu (`konuGiris.terimler`) | `konu_giris.terimler` | Evet (07.11'den beri) | Yakalama oranı ÖLÇÜLMEDİ |
| hap · taktik | `hap` `sinav_taktigi` | Evet | |
| şık açıklamaları → ekranda `tuzak` `kural` `olay` | `aciklama` | Ham hâlini görüyor | Ekrandaki hâli yayın anında düzenli ifadeyle `aciklama`'dan AYRIŞTIRILIYOR; ayrıştırılmış hâli kimse görmüyor |
| sade (doğru, sınav, şıklar, kavramlar) | `sade` | Evet (07.11'de tamamlandı) | |
| verilenler | `verilenler` | Evet (07.11'den beri) | |
| teşhis · çeldirici yolu | `teshis` `celdirici_yol` | Evet | |
| adımlar | `adimlar` | **Kısmen:** yalnız `anlatim` ve `formul` | `doldur`, `sik`, `karar` hakeme gitmiyor (`karar` için mekanik KAPI-KARNE var) |
| **çözüm tablosu (`tablo`)** | `cozum_tablo` | **HAYIR** | Hakem istemindeki alan listesinde yok. Ekran çizicisi `tablo`'yu 52 yerde okuyor |
| yevmiye kaydı (`kayit`, `kayitlar`, `kayitBaslik`) | `ky`, `kyAll` | Belirsiz | Hakem `sema` alanını (türü yevmiye ise) görüyor; `ky` ile aynı içerik mi ÖLÇÜLMEDİ |
| ikiz soru (`oyun`, tür ikiz/tablo) | `ikiz` | **Kısmen:** `ikiz_soru`, `tablo`, `hedef_cumle` | `ikiz.verilen`, `ikiz.bosluk` ve ikiz yevmiye öğeleri gitmiyor |
| **ölçekli tekrar (`oyun` tür olcek, `oyunBonus`)** | Yok: yayın anında kod, sorunun tutarlarını değiştirerek üretiyor | **HAYIR** | Hiçbir hakem ve kapı görmüyor; kodun ürettiği sorunun doğruluğu ÖLÇÜLMEDİ |
| hesap tanımları (`hesaplar`) | Ambardaki hesap planı, kodla | Hayır (model yazmıyor) | Kaynak doğruysa doğru |
| dayanak | `dayanak` | Evet (kural 10) | |
| konu · ders · dönem · tip · ölçüm | Etiket ve sayaçlar | Hayır | Ders/konu etiketi ayrı denetimde |

### İki yapısal bulgu

1. **Hakemden sonra metin değişiyor.** `TurkceOnar` yayın betiğinde 59 yerde çağrılıyor ve öğrencinin gördüğü hemen her metin alanını
   yayın anında yeniden yazıyor. Hakem ambar kaydını okur; öğrenci dönüştürülmüş hâli görür. "katip → katıp", "BES → BEŞ" bozulmaları
   (brif, 09.11) bu adımdan. Öğrencinin gördüğü son metni denetleyen bir adım yok.
2. **Yayın anında içerik üretiliyor.** Ölçekli tekrar sorusu, türetilmiş "Adım / İçerik" ve "Şık / Kaynak / Karar" tabloları yayın
   betiğinde ya da tarayıcıda kodla kuruluyor. Bunlar ambarda durmadığı için basım tarafındaki hiçbir kapıdan geçmiyor.

Sonuç: "ekrandaki her alan hakeme gider" kuralı (B34) bugün en az üç alanda tutmuyor: çözüm tablosu, ölçekli tekrar, yayın anı dönüştürmesi.

---

## 2. Konu kartları bugün ne taşıyor

| | Bitirme (`bitirme-konu-kartlari.json`) | KGK (`kgk-konu-kartlari.json`) | SGS |
|---|---|---|---|
| Kart sayısı | 309 | 1.814 | Kart dosyası bulunamadı |
| Kalıp, kök uzunluğu, şık türü, "ne sorar", çeldirici | Var | Var | — |
| Dayanak | 309/309 dolu (serbest metin) | 1.814/1.814 dolu | — |
| Konu özeti | 0 | 0 | — |
| Terim notu | 0 | 0 | — |
| Onay kaydı (kim, ne zaman) | 0 | 0 | — |
| Kalıbı tahmini olan kart | 124 / 309 | alan yok | — |

**Okuma:** eldeki kartlar "sınav bu konuyu nasıl sorar" kartıdır; "bu konu nasıl anlatılır" kartı değildir. Taslaktaki D2 için konu özeti,
terim notu ve onay alanları sıfırdan yazılacak. Dayanak serbest metin olduğu için ambar parçasına mekanik bağ da yok.

---

## 3. Kartların dayandığı kaynak ambarda ne durumda

Kaynak: `veri/AMBAR-ENVANTERI.md` (makine üretimi, 09.11.2026 18:39): 2.828 tekil kaynak, 2.376'sı TAM, 412'si DELİK-İNCELE.

### Bitirme kartları, ders ders

| Ders | Kart | Standart atıflı kart | Standardı TAM | Standardı delikli | Teori notuna dayanan kart |
|---|---:|---:|---:|---:|---:|
| Muhasebe Denetimi | 44 | 28 | 28 | 0 | 0 |
| Maliyet Muhasebesi | 18 | 9 | 9 | 0 | 5 |
| Finansal Muhasebe | 47 | 17 | 16 | 1 (TMS 1) | 28 |
| Finansal Tablolar ve Analizi | 22 | 8 | 4 | 4 (TMS 1) | 19 |
| Vergi Mevzuatı ve Uygulaması | 57 | 0 | — | — | 0 |
| Hukuk | 57 | 0 | — | — | 0 |
| Meslek Hukuku | 29 | 0 | — | — | 0 |
| Sermaye Piyasası Mevzuatı | 35 | 0 | — | — | 2 |

"Standart atıflı" = dayanağında BDS / TMS / TFRS / KKS numarası geçen kart. Kanuna dayanan kartlar bu sütunlarda ölçülmedi.

### Ana kanunların envanterdeki durumu

| Kanun | Parça | Durum |
|---|---:|---|
| VUK (213) | 586 | DELİK-İNCELE (par 429 · kesik 29) |
| GVK (193) | 381 | DELİK-İNCELE (par 118 · kesik 37) |
| KVK (5520) | 206 | DELİK-İNCELE (öksüz 1) |
| KDVK (3065) | 169 | DELİK-İNCELE (par 2 · kesik 4 · öksüz 1) |
| TTK (6102) | 1.596 | DELİK-İNCELE (par 20 · kesik 2 · öksüz 2) |
| TBK (6098) | 652 | DELİK-İNCELE (par 1) |
| SGK (5510) | 556 | DELİK-İNCELE (par 5 · öksüz 8) |
| Sermaye Piyasası K. (6362) | 269 | DELİK-İNCELE (par 4) |
| İş K. (4857) | 153 | DELİK-İNCELE (par 18 · kesik 1 · öksüz 2) |
| AATUHK (6183) | 163 | DELİK-İNCELE (par 2 · kesik 4) |
| Teori notları (grup) | 599 | DELİK-İNCELE (par 494 · kesik 5) |
| 3568 sayılı Kanun | — | Envanterde bu adla eşleşmedi; ÖLÇÜLMEDİ |

**Okuma:**
- Vergi, Hukuk ve Sermaye Piyasası kartlarının dayandığı ana kanunların hepsi "incele" işaretli. Hangi maddenin kesik olduğu bu ölçümde
  kart düzeyine indirilmedi.
- Finansal Muhasebe (47 kartın 28'i) ve Finansal Tablolar (22 kartın 19'u) resmî metne değil **teori notuna** dayanıyor; teori notları
  grubu da "incele" işaretli. "Yalnız resmî kaynaktan" isteği (A-05) bu iki derste bugünkü kartlarla karşılanmıyor.
- **Muhasebe Denetimi** en temiz ders: standart atıflı 28 kartın 28'inde standart TAM, teori notuna dayanan kart yok, paragraf atfı için
  mekanik kapı (KAPI-BP) kurulu. Kalan 16 kart yönetmelik maddesine dayanıyor (Bağımsız Denetim Yönetmeliği envanterde 82 parça, TAM;
  16 kartın tamamı tek tek eşlenmedi). Zayıf yanı: 44 kartın 23'ünde kalıp tahmini.

---

## 4. Öneri

1. **Kanıt dalgası dersi: Muhasebe Denetimi.** Standart atıflı 28 karttan, kalıbı tahmini olmayanlar öne alınarak 20 kart seçilir.
2. Dalgadan önce (0 USD): seçilen 20 kartın konu özeti, terim notu ve "böyle düşürürler" satırı ambardaki standart metninden yazılır;
   her atıf parça kimliğine bağlanır; kart onaya sunulur.
3. Üç yapısal açık (çözüm tablosu hakemde yok · ölçekli tekrar denetimsiz · yayın anı dönüştürmesi hakemden sonra) kanıt dalgasında
   **kapatılmadan** ölçülemez: dalga sorularında ölçekli tekrar kapalı tutulur, çözüm tablosu hakem istemine eklenir, yayın sonrası metin
   ambar metniyle karşılaştırılır. Bu üçü kod değişikliğidir; ayrı onayla yapılır.
4. Vergi ve Hukuk için basım, ana kanunlardaki "incele" işaretleri kart düzeyine indirilip kapatılmadan açılmamalı.

---

## 5. EK ÖLÇÜM (10.11, akşam): kart düzeyinde madde, teori notu ve 3568

> Yöntem: Vergi, Hukuk, Meslek Hukuku ve Sermaye Piyasası kartlarının dayanağındaki 363 tekil madde ambarda salt okumayla tek tek arandı (0 USD).
> **Görmediği:** kısaltma tablosunda olmayan kanunlar (ÖTV, Damga, Dijital Hizmet, Veraset, MTV, Emlak, İYUK ve benzeri) çözülemedi → 29 kart ÖLÇÜLMEDİ ·
> "kesik şüphesi" bir vekil ölçüdür (son parçanın metni cümle sonu işaretiyle bitmiyor); parçası 10 ve üstü olan maddede sıralama yüzünden yanlış alarm verebilir, bentle biten maddeyi de şüpheli sayar. Her satır elle okunmadan "kesik" denmez.

### 5.1 Düzeltme: 3568 sayılı Kanun ambarda VAR

Envanterde adı "SMMM K. (3568 s.K.)": 84 parça, DELİK-İNCELE (öksüz 2). Bölüm 3 tablosundaki "eşleşmedi" satırı kısaltma farkındandı.

### 5.2 Kanun maddesi düzeyinde kartlar

| Ders | Kart | Maddesi çözülen | Temiz | Yalnız dipnot rakamı yapışık | Kesik / yapışık başlık şüphesi | Ambarda bulunmayan madde | Ölçülemeyen kart |
|---|---:|---:|---:|---:|---:|---:|---:|
| Vergi Mevzuatı ve Uygulaması | 57 | 50 | 29 | 10 | 11 | 0 | 7 |
| Hukuk | 57 | 48 | 36 | 6 | 6 | 0 | 9 |
| Meslek Hukuku | 29 | 16 | 13 | 0 | 3 | 0 | 13 |
| Sermaye Piyasası Mevzuatı | 35 | 35 | 31 | 2 | 2 | 0 | 0 |

Ambarda bulunmayan madde çıkmadı. İlk koşuda 8 madde "yok" göründü; neden ölçüm betiğinin süzgeciydi (başlığında "Mükellef", "gecikme" geçen maddeyi mükerrer/geçici sanıp eledi), düzeltilip yeniden koşuldu.

**Kesik ya da yapışık başlık şüphesi taşıyan kartlar (elle okunacak):**

| Ders | Konu | Çıkmış dönem | Şüpheli madde ve metnin son 70 karakteri |
|---|---|---:|---|
| Vergi Mevzuatı ve Uygulaması | GVK › Menkul sermaye iradı | 14 | GVK m.75 …"len irat tutarının tespitinde kur farkı dikkate alınmaz. Vergi Alacağı" |
| Vergi Mevzuatı ve Uygulaması | VUK › Vergi cezaları | 10 | VUK m.352 …"inde icabet edilmemesi ; 6. Bu Kanunun kayıt nizamına ait hükümlerine (" ; VUK m.368 …"ir. (Ek fıkra: 22/7/1998-4369/16 md. ; Mülga: 11/8/1999-4444/14 md.)143" |
| Sermaye Piyasası Mevzuatı | Yatırım kuruluşları ve yatırım hizmetleri | 9 | Sermaye Piyasası K. m.37 …"ması h) Kurulca belirlenecek diğer hizmet ve faaliyetlerde bulunulması" ; Sermaye Piyasası K. m.38 …"ması f) Kurulca belirlenecek diğer hizmet ve faaliyetlerde bulunulması" |
| Vergi Mevzuatı ve Uygulaması | VUK › Vergilendirme süreci (tarh, tebliğ, tahakkuk, tahsil) | 8 | VUK m.93 …"r alan “Maliye Bakanlığının teklifi üzerine Bakanlar Kurulu” ibaresi “" |
| Vergi Mevzuatı ve Uygulaması | GVK › Mükellefiyet türleri ve yerleşme | 7 | GVK m.4 …"ürkiye'de devamlı olarak altı aydan fazla oturanlar (Geçici ayrılmalar" |
| Vergi Mevzuatı ve Uygulaması | VUK › Mükellef ve vergi sorumlusu | 6 | VUK m.8 …"tlarda ve düzenlenecek belgelerde kullanılması mecburiyetini getirmeye" |
| Vergi Mevzuatı ve Uygulaması | KDV › İndirim | 6 | KDVK m.9 …"değer vergisinin ödenmesinden lisanslı depo işleticileri sorumludur. Ü" |
| Meslek Hukuku | Meslek mensubunun vergi ve ceza hukuku sorumluluğu | 6 | SMMM K. m.47 …"lilerine ait hükümleri uyarınca cezalandırılırlar.22 Disiplin cezaları" |
| Sermaye Piyasası Mevzuatı | Piyasa bozucu eylemler, bilgi suistimali ve piyasa dolandırıcılığı | 6 | Sermaye Piyasası K. m.108 …"iptal edilmesi Usulsüz halka arz ve izinsiz sermaye piyasası faaliyeti" |
| Meslek Hukuku | Mesleğin konusu | 4 | SMMM K. m.2 …"Meslek unvanlarının haksız kullanılması" |
| Meslek Hukuku | TÜRMOB organları, görevleri ve gelirleri | 4 | SMMM K. m.35 …"Birlik Yönetim Kurulunun görevleri" |
| Vergi Mevzuatı ve Uygulaması | KDV › İstisnalar | 3 | KDVK m.17 …"50 ı) (Ek:6/12/1984-3099/1 md. ; Değişik: 16/7/2004-5228/15 md.) Serbest" |
| Vergi Mevzuatı ve Uygulaması | VUK › Pişmanlık ve ıslah | 3 | VUK m.371 …"ına ilişkin usul ve esasları belirlemeye yetkilidir. Ölüm: Madde 372 –" |
| Hukuk | Borçlar › Özel borç ilişkileri (diğer tipik sözleşmeler) | 3 | TBK m.207 …"mkün olan bedel, kararlaştırılmış bedel hükmündedir. B. Yarar ve hasar" |
| Hukuk | İş Hukuku › Çalışma süreleri, fazla çalışma ve telafi çalışması | 3 | İş K. m.64 …"de telafi çalışması yaptırılamaz. Kısa çalışma ve kısa çalışma ödeneği" |
| Vergi Mevzuatı ve Uygulaması | 6183 › Kanuni temsilci ve ortakların sorumluluğu | 1 | AATUHK m.35 …"ne göre müteselsilen sorumlu tutulur. Kanuni Temsilcilerin Sorumluluğu" ; AATUHK mukerrer m.35 …"ı Kararı ile.) Birleşme, devir, bölünme ve şekil değiştirme halleri:11" |
| Vergi Mevzuatı ve Uygulaması | GVK › Vergiye uyumlu mükellef indirimi (GVK 121) | 1 | GVK mukerrer m.121 …"esasları belirlemeye yetkilidir.152 Diğer ücret vergisinin mahsubu:153" |
| Vergi Mevzuatı ve Uygulaması | KDV › Tevkifat | 1 | KDVK m.9 …"değer vergisinin ödenmesinden lisanslı depo işleticileri sorumludur. Ü" |
| Hukuk | Borçlar › Temsil | 1 | TBK m.40 …"e ilişkin hükümler uygulanır. b. Temsil yetkisinin içeriği ve derecesi" ; TBK m.43 …"arşılıklı kişisel hakları saklıdır. c. Yetki belgesinin geri verilmesi" ; TBK m.44 …"idermekle yükümlüdürler. d. Yetkinin sona erdiğinin ileri sürülememesi" |
| Hukuk | İş Hukuku › Ücret | 1 | İş K. m.32 …"aklarında zamanaşımı süresi beş yıldır. İşverenin ödeme aczine düşmesi" |
| Hukuk | SGK › Denetim, idari para cezaları ve teşvik yaptırımları | 1 | 5510 s. SGK Kanunu m.102 …"a göre defter tutmak zorunda olanlar hakkında asgari ücretin üç katını" |
| Hukuk | Borçlar › İrade sakatlıkları | 1 | TBK m.31 …"ğini etkilemez ; bunların düzeltilmesi ile yetinilir. b. Saikte yanılma" |

Görülen kusur türleri: madde cümle ortasında bitiyor (ör. GVK m.4, KDVK m.9, VUK m.352) · bir sonraki maddenin başlığı ya da ilk kelimeleri sona yapışmış (ör. VUK m.371, TBK m.40–44, İş K. m.32, m.64) · dipnot rakamı son kelimeye yapışmış.

### 5.3 Teori notuna dayanan kartlar (Bölüm 3 düzeltmesi)

| Ders | Kart | Teori notu anan | Teori + resmî kaynak birlikte | Yalnız teori notu | Dayanağında "AMBARDA YOK" / "resmî düzenleme yok" yazan |
|---|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 47 | 28 | 28 | 0 | 3 |
| Finansal Tablolar ve Analizi | 22 | 19 | 7 | 12 | 3 |
| Maliyet Muhasebesi | 18 | 5 | 1 | 4 | 10 |

**Düzeltme:** Bölüm 3'te Finansal Muhasebe için "28 kart resmî metne değil teori notuna dayanıyor" yazıldı; eksikti. O 28 kartın 28'i teori notunun YANINDA resmî kaynağı da (TMS, hesap planı, VUK) anıyor. Asıl açık Finansal Tablolar ve Analizi'nde: 12 kart yalnız teori notuna dayanıyor, çünkü oran ve analiz teknikleri için resmî düzenleme yok.

**Yalnız teori notuna dayanan kartlar:**

| Ders | Konu | Çıkmış dönem | Dayanak |
|---|---|---:|---|
| Finansal Tablolar ve Analizi | Faaliyet (devir hızı) oranları | 26 | Resmî standart yok (analiz tekniği); ambar: TEORI - Faaliyet (devir hızı) oranları; TEORI - Ortalama stok ve donem ici (ceyreklik) veriyle d |
| Finansal Tablolar ve Analizi | Likidite oranları | 20 | Resmî standart yok; ambar: TEORI - Likidite oranları: cari oran, asit-test (likidite) oranı, nakit oranı…; TEORI - Asit-test (likidite) oran |
| Finansal Tablolar ve Analizi | Mali yapı oranları | 19 | Resmî standart yok; ambar: TEORI - Finansal yapı (kaldıraç) oranları; TEORI - Kaldirac orani ve borc/oz kaynak orani; TEORI - Devir hizlari  |
| Finansal Tablolar ve Analizi | Kârlılık oranları | 19 | Resmî standart yok; ambar: TEORI - Kârlılık oranları ve piyasa oranları; TEORI - Faaliyet kar marji ve faaliyet kari hesabi; TEORI - Karlili |
| Finansal Tablolar ve Analizi | Dikey analiz | 11 | Resmî standart yok; ambar: TEORI - Dikey analiz: taban (payda) kalemleri ve kurallar; TEORI - Dikey yuzdelerden net satis ve gelir tablosu h |
| Finansal Tablolar ve Analizi | Trend analizi | 10 | Resmî standart yok; ambar: TEORI - Trend (eğilim yüzdeleri) analizi ve karşılaştırmalı tabloların yorumu; TEORI - Mali tablolar analizinde y |
| Finansal Tablolar ve Analizi | Yatay analiz (karşılaştırmalı tablolar) | 7 | Resmî standart yok; ambar: TEORI - Karşılaştırmalı (yatay) analiz ve yüzde değişim; TEORI - Yatay (karsilastirmali) analiz kurallari |
| Finansal Tablolar ve Analizi | İşletme sermayesi | 5 | Resmî standart yok; ambar: TEORI - Çalışma sermayesi analizi; TEORI - Net isletme sermayesi ve negatif olma kosulu |
| Finansal Tablolar ve Analizi | Enflasyon ve reel değişim | 1 | ambar: TEORI - GSYH deflatoru, TUFE, nominal-reel gecis ve enflasyon hesabi (iktisat notu; finansal analize özgü resmî düzenleme yok) |
| Finansal Tablolar ve Analizi | Du Pont analizi | 1 | Resmî standart yok; ambar: TEORI - Oz kaynak karliligi, aktif karliligi ve kaldirac iliskisi; TEORI - Oz sermaye carpani ve kaldirac iliskis |
| Finansal Tablolar ve Analizi | İçsel büyüme ve otofinansman | 1 | Resmî standart yok; ambar: Teori Notu - temettu politikasi (sürdürülebilir büyüme); Teori Notu - finansman kaynaklari ve sermaye yapisi (oto |
| Finansal Tablolar ve Analizi | Kaldıraç dereceleri | 1 | Resmî standart yok; ambar: Teori Notu - kaldirac ve basabas |
| Maliyet Muhasebesi | Safha (evre) maliyet sistemi | 21 | HESAP (K1e): resmî metin yok, dayanak hesabın kendisidir (kökte yöntem açıkça yazılır; iki kör bağımsız aynı sonuç — BITIRME-SORU-STANDARDI  |
| Maliyet Muhasebesi | Sipariş (parti) maliyet sistemi | 10 | AMBARDA YOK: resmî mevzuat dayanağı yok (ders kitabı); ambarda yalnız TEORI notu "Sipariş maliyet sisteminde sipariş kartı…" |
| Maliyet Muhasebesi | Maliyet muhasebesinin amaçları ve muhasebe bilgi sistemi | 2 | AMBARDA YOK: resmî dayanak yok (ders kitabı); ambarda yalnız TEORI notu "Muhasebe turleri: finansal, yonetim ve maliyet muhasebesi ayrimi" |
| Maliyet Muhasebesi | Faaliyete dayalı maliyetleme | 1 | HESAP (K1e): resmî mevzuat dayanağı yok; ambarda TEORI notu "Teori Notu - faaliyet tabanli maliyetleme ve GUG yukleme orani" VAR (yükleme or |

### 5.4 Sonuç

1. Dört derste eksik madde yok; açık, 22 kartın dayandığı maddelerde kesik ya da yapışık metin ŞÜPHESİ. Bu maddeler resmî metinle elle karşılaştırılıp onarılmadan o kartlara soru basılmamalı; temiz kartlar bu ölçüye göre engelsiz.
2. Finansal Muhasebe'de iş, yeni kaynak yutmak değil; karttaki serbest metin dayanağı ambar parça kimliğine bağlamak.
3. Finansal Tablolar ve Analizi'nde 12 kart için resmî kaynak yok. Bu konularda kaynağın ne sayılacağı Cem kararıdır (öneri: çıkmış sınav sorusu ve komisyon cevabındaki formül; teori notu hangi çıkmış soruya dayandığını yazar).
4. Maliyet Muhasebesi'nde 10 kartın dayanağında "ambarda yok" notu var; 05.11 notuna göre bir kısmı eskimiş not. Kart kart yeniden ölçülmedi.
