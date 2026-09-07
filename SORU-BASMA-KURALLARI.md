# SORU BASMA KURALLARI — dört sınav, iki yol (v2 taslak 07.09.2026 gece · Cem'in okeyi bekleniyor)

Kalıp (ekran, anlatım, panel) `STANDART-CEVAP-KALIBI.md` bölüm 12'dedir (v29). Bu belge **soruların nasıl basılacağını** toplar:
26.07'den bu yana Cem'le kararlaştırılan bütün soru kurallarının tek listesi. Kaynaklar: kalıp bölüm 7 · kütük K1–K14, Ö1–Ö69 ·
çıkmış-örnek kuralı (27.08) · yapay zeka kokusu (19.08–14.08) · kod-ad çifti (10.08) · rakam disiplini (11.07, 02.08) · sınav anatomisi (02.09) ·
soru kalite kusurları (02.09) · üretim hattı dersleri (29.07–31.08). İki yol: **A) yeni soru yazma** · **B) eski soruyu kalıba çevirme (kurtarma)**.
Kural koda girer (üretici, kapı, koşucu); kod kuraldan saparsa kod düzeltilir, kural değil. Her kural için parantez içinde uygulayan kapı/araç yazılıdır.

---

## 1 · SINAV KALIBINA UYGUNLUK — "sınav sorusu gibi olacak"

1.1 **Çıkmış soru çapadır** (27.08 kuralı). Her üretimde konunun GERÇEK çıkmış sorusu isteme gider: tip (kayıt / hesaplama / teori), uzunluk, ses, şık biçimi. Çapa hesaplama ise soru sayısal veri verip "kaç TL" sorar ve ≥2 satırlı çözüm tablosu taşır (KAPI-T). Çapa yalnız biçim örneğidir, **metni, rakamı, şık dizilimi kopyalanmaz** (benzerlik kapısı, telif).
1.2 **Konu son 7 dönemin penceresinden** (K10). Pencere dışı konuya soru basılmaz. Konu tekilleştirme: yakın adlar tek konu (cari oran ×3 olmaz).
1.3 **Uzunluk tavanı dersin çıkmış p75'i** (`cikmis-ders-kalibi-sgs.json`; FMuh medyan 317 kr, hukuk dersleri daha uzun). Sınav uzuyor (+%40, 2024→2026): tavan her dönem yeniden ölçülür, sabit rakam yazılmaz. Aşan soru 2 kez yeniden yazdırılır.
1.4 **Tip kotası gerçek dağılımdan** (FMuh: kayıt %41 · hesaplama %26 · teori %18). **Kök kalıbı sınavdan:** olumsuz kök ("hangisi yanlıştır") Meslek %45 · Denetim %44 · Ticaret %41 · FMuh %7; öncüllü (I-II-III) Ekonomi %40. Ders partisi bu oranları izler (⏳ kota kapısı yazılacak; bugün istemde).
1.5 **Şık biçimi sınav biçimidir:** sonuç + kısa etiket; **şıkka gerekçe yazılmaz** (4b, doğruyu ele verir). Sayı şıkları hepsi farklı, küçükten büyüğe sıralı, birim yazılmaz; cümle şıklarında doğru en uzun olamaz (çıkmışta rastgele düzeyde). Sapma sorularında 2 tutar × 2 yön + 1 (KAPI-Ş).
1.6 **Sızıntı kuralı 4c:** çeldiriciler "her durumda / hiçbir şekilde / yalnızca" mutlakiyetçi kalıba yığılmaz; en az bir çeldirici nüanslı; iki şık birbirinin birebir tersi olamaz; kökün atıf yaptığı kaynak öncüllerin dayanağını içerir. Ölçekli sızıntı yasak: örnek, sorunun rakamlarını binde bire indirip kullanmaz (800.000→800).
1.7 **Zor = hesap konusu** (Ö51): ≥4 bağlı ara hesap, sınavın birleştirdiği katmanlar, her çeldirici atlanan bir katmandan türer; gövde sınav gibi yöntemi işletme cümlesiyle söyler, çözüm sırasını anlatmaz; kök "Buna göre, … kaç TL'dir?". Üç seviye: kolay = tek kural tek işlem · zor = iki zorluk kaynağı · çok zor = ters soru + çeldirici verilen + iki kuralın kesişimi.
1.8 **Çeldirici gerçek yanlış yoldur** (KAPI-Ç, 07.09): her yanlış şık, sayılı bir yanlış yol formülünün sonucudur, makine hesaplar, tutmayan soru geri döner. Her şık farklı kavram yanılgısı; aynı tuzak adı partide ≤2 (TUZAK TEKDÜZE raporu). Teoride yakın-şık: en az iki şık aynı paragraftan tek kelime farkıyla.
1.9 **Şık harfi dağılımı** ders içinde dengeli ("hep C" olmaz) (⏳ kapı).
1.10 **Zorluk sınavdan ölçülür, varsayılmaz** (26.08 ölçümü `zorluk-kiyas-v2.json`, 16.355 tekil çıkmış soru, 8 sinyalli cetvel): çıkmış sınav **kolay %42 · zor %52 · çok zor %7**; eski kasamız sınav sepetiyle tartılınca **kolay %68 · zor %18 · çok zor %14** → kasa belirgin kolay, zorlar hesap derslerinde yığılı, hukuk ve dil derslerinde çok zor %0. İki biçim işareti (Cem): öncüllü soru (I-II-III) sınavda %5,4 · kasada %0,9; şaşırtmalı kök (yanlıştır/değildir) sınavda %4,3 · kasada %0,2. Ders zorluk sıralaması (anatomi, 0-100): Maliyet 60 ≫ FMuh 30 ≈ MTA 29 > Meslek 23 > İş-SGK 22 > Ticaret 21 > Denetim 18 > Vergi 17 > Maliye 16 > Ekonomi 15 > Türkçe 12 > Matematik 10 > Atatürk 9.
   **Kural:** her ders partisinin kolay/zor/çok zor dağılımı o dersin ÇIKMIŞ dağılımını izler (hesap derslerinde zor ağır, hukuk/dil derslerinde öncüllü + şaşırtmalı kök kotası). Üretilen her soru aynı 8 sinyalli cetvelle puanlanır ve karneye yazılır; partinin dağılımı sınavdan sapıyorsa karne SARI, parti yeniden dengelenir (⏳ 08.09: `zorluk-kiyas-v2.ps1` karneye bağlanır). Zorluk ders ders yeniden ölçülür (sınav uzuyor, 2024/2 → 2026/2 zorluk 20,2 → 24,2).

## 2 · YAPAY ZEKA İZİ — "öğrenci yapay zeka yazmış demesin"

2.1 İz **dildedir, iskelette değil**. Yasak izler (`kasa-sayim.ps1` koku taraması + `yapayzeka-izi-denetim.ps1`): **placeholder unvan** ("ABC A.Ş.", "XYZ Ticaret") → gerçekçi ad ya da "işletme" · **bütün tutarlar yuvarlak** (100.000 + 8.000 + 3.000) → gerçekçi tutar karışımı · **şişirme klişe** ("önem arz etmektedir", "bu bağlamda", "dolayısıyla", "ayrıca" zinciri) · **aynı cümle kalıbının tekrarı** (5 şıkta aynı "Ne soruluyor", "karıştırıyor" kalıbı) · **em-dash (—) cümle içi ayraç** yasak · ellipsis (…) yok · "sadece … değil, aynı zamanda" yok.
2.2 **Türkçe harfler tam** (26/30 soruda eksikti, 02.09): `YazimOnar` + kapı. Kök kural: **istem, üründe görünmek istenen yazımla yazılır**; model istemin biçimini kopyalar.
2.3 **Kurumsal dil:** "robot", "tohum", "hoca", laubali başlık yok; Nöbetçi dili kısa, etken çatı, cümle ≤20 kelime ortalama.
2.4 **İkinci hakem** (⏳ 08.09): "bu soru gerçek sınav sorusu gibi mi, yapay zeka kokusu var mı, çeldirici gerçek adayın düşeceği tuzak mı" — HAYIR diyen soru geri döner.
2.5 Yeni üretim iç monolog taşımaz ("tersine mühendislik", "burada model…" kalıpları) — IC-MONOLOG süzgeci kara liste.

## 3 · FORMÜL ve RAKAM KONTROLÜ — "doğru hesaplama"

3.1 **Rakam disiplini:** hiçbir sayı uydurulmaz; her sayı soruda verilir ya da kaynaktan gelir ya da makinenin kendi hesabıdır. **Yıla bağlı had / oran / tavan** (kıdem tavanı, istisna haddi, prim oranı) kaynağa bakılmadan kullanılmaz; kaynakta yoksa senaryo o parametreye çarpmayacak şekilde kurulur ya da "kaynak yetersiz" (27.08 parametre kuralı; 5 puan→2 puan, %20→%21 dersleri).
3.2 **Aritmetik kapısı:** adımlardaki her formül zinciri makinede hesaplanır ("sol taraf hesaplanınca sağdaki sonuç çıkmalı"); tutmayan adım geri döner, son turda da tutmazsa karneye KIRMIZI. Tarih farkı zincir sayılmaz, % ve × öncelik kuralı var.
3.3 **Bir adım = bir işlem** (07.09): çarpımların toplamı tek adımda yasak; tamamlanmayan oran "(1 − %100 = %0)".
3.4 **Sağlama adımı zorunlu** (bulunan değer denkleme geri konur); **ters durum adımı** iki yüzlü kuralda (kâr/zarar, borç/alacak).
3.5 **Kör çözüm** (⏳ 08.09, en kritik açık): anlatımı ve ikizi görmeden ASIL soruyu sıfırdan çözen bağımsız ikinci model (farklı model). Cevap doğru şıkla tutmuyorsa yayın yok. 07.09 Maliyet kp-05 (yüzdeler ters, hiçbir şık doğru değil) hakem+sim+aritmetik üçünü geçmişti; bunu yalnız bu yakalar.
3.6 **Öğrenci simülasyonu** ikiz üstünde koşar; ikiz ile soru anlaşmazsa **önce ikiz şüphelidir**, sim asıl soruda tekrar koşar.
3.7 **Tablo ve şık aynı sayıyı söyler:** çözüm tablosu sonuç satırı = doğru şık; tablo hücresi ↔ adım ara sonucu birebir (aritmetik kapısı ölçer).

## 4 · TARİH / YIL — "sorular 2026 yılında olsun"

4.1 **KAPI-Y:** soruda yıl geçiyorsa en yenisi bugünün yılıdır (`(Get-Date).Year`); geçmiş dönem sorulmaz; edinme tarihleri eski olabilir. Kanun numarası ("2004 sayılı") yıl sayılmaz. Düşen soru yıllar kaydırılarak yeniden yazdırılır.
4.2 İkizde yıllar aynı farkla kaydırılır, süreler ve Türkçe ekler korunur (2023'te, 2026'da).
4.3 Kurtarmada (B yolu) hukuk sorularının yılı kaydırılmaz (yıla bağlı had gerçeği bozulur); muhasebe sorularında kaydırılır.
4.4 **Güncellik kapısı** (Ö47): kaynak belge tarihi ve yürürlük; eski dönem tebliği (5422 dönemi KV tebliğleri) kaynak paketine girmez; mülga standart (TMS 11/18/39, KKS 1→KYS 1, TFRS 4→17) önerilmez (`mulga-cek.ps1`); kurul kararıyla değişen tutar (TTK m.580 50.000 TL) işlenmiş olmalı.
4.5 **KAPI-M mülga mevzuat / kapanmış kurum (Cem 08.09 "yanlışlıkla eski kanuna bakıyordur, o kanun değişmiştir"):** soru, şık, açıklama, dayanak ve hapta mülga kanun numarası (6762→6102, 818→6098, 5422→5520, 506/1479→5510, 2499→6362, 1050→5018, 4077, 1086, 743, 765, 2821/2822→6356, 4389→5411; 1475 yalnız m.14 kıdem bağlamında), mülga standart (TMS 11/17/18/39, TFRS 4, KKS 1) ya da kapanmış kurum adı (SSK, Bağ-Kur, Emekli Sandığı, TMSK, Sanayi ve Ticaret Bak., DPT, YTL) ve "yeni TTK / eski TTK / mülga" karşılaştırma dili **sert** düşer; kurtarmada eski künye `kanun_no` mülga listesindeyse soru arşive. "Maliye Bakanlığı" sert değil, rapor notu (kanun alıntısı olabilir). Neden ayrı kapı: ambar günlük ayna olduğu için yürürlükteki metinle çelişen kural hakemde düşüyordu; ama mülga kanunun metni ambarda **hiç yok** (6762/818/5422/506 ölçüldü), atıf boş kalıyor ve hakem başka kaynakla EVET diyebiliyordu.
4.6 **KAPI-S süresi dolan veri (Cem 08.09 "eski, süresi dolan verinin olmaması"):** geçmiş bir son tarih ("31.12.2025 tarihine kadar") ya da eski yıla bağlanmış had/oran ("2024 yılı için geçerli yeniden değerleme oranı") **sert** düşer; geçici madde dayanağı hakeme **GÜNCELLİK** sorusu olarak gider (kaynak metninde süresi dolmuşsa ESKİ → karar HAYIR).

## 5 · HESAP KODU KONTROLÜ

5.1 **Kod-ad çifti kuralı** (10.08): soruda geçen her **kod + hesap adı** çifti Tekdüzen'de gerçekten var olan çifttir; kökte, doğru şıkta, **yanlış şıkta**, açıklamada ve hapta aynı. Çeldirici **muhasebede** yanlış olur, **adında** yanlış olmaz (⛔ "657 Karşılık Giderleri", ⛔ "105 Hisse Senetleri"). Sözlük `veri/thp-resmi-adlar.json`; sözlük yoksa kapı kendini kapatır (KAPI-H).
5.2 Hesap planı **Tekdüzen**, TMS konularında da (TFRS-eki adları KGK sınavına ait). Hesap tanımları isteme **ambardan** girer ("X nedir?" uydurulmaz).
5.3 Tutarın binler basamağı kod sanılmaz (243 soruda uydurma kod dersi); kapı ölçümü: tutar/kod ayrımı regex ile.
5.4 **Toptan düzeltme yasak:** hesap kodu hatası görülen eski soru elle yamalanmaz, yeniden yazım bütünüyle kurar (229/129 vakası: 40 adayın 31'i değiştirilemezdi).

## 6 · KANUN / DAYANAK KONTROLÜ

6.1 **Kaynak okunmadan soru yoktur.** Madde/paragraf ambardan, hafızadan değil; kaynak yoksa "kaynak borcu", soru yok.
6.2 **Dersin kanun listesi** tam ve ambar adlarıyla (Vergi: VUK, GVK, **KVK 5520**, KDVK, ÖTV, MTV, Harçlar, Emlak, Veraset, Gider V., Damga, AATUHK, İİK · İş-SGK: 4857, 5510, **6356**, 6331, 4447 · Meslek: 3568 + Haksız Rekabet ve Reklam Yasağı Yön. + TÜRMOB Etik Yön. + Disiplin Yön. + Staj Yön. · Ticaret: TTK · Borçlar: TBK · Maliyet: MSUGT 2 + THP · Denetim: BDS · FMuh: THP + VUK · TMS/TFRS/KYS KGK için). Köprü dayanağı listede olmayan kanunsa **zayıf** sayılır (07.09'da Vergi 4→1 bu yüzden düşmüştü).
6.3 **Ders ↔ kanun uyum kapısı** (`ders-kanun-kapisi.ps1`): dar kapsamlı kanun alakasız derse bağlanamaz (Kamu Malî Yönetimi K. m.3'e bağlı 1.064 "cari oran" sorusu vakası). VUK/TTK/GVK/KDV her muhasebe dersinde meşru.
6.4 **Hakem maddenin METNİYLE yargılar**, etiketiyle değil; hükmünde maddeden birebir alıntı zorunlu, alıntı metinde yoksa hüküm çöp (Profesör v2). Üç soru: kaynak destekliyor mu · tek doğru mu · çelişki var mı + ders uyumu + konu uyumu.
6.5 **Atıf doğruluğu:** soru metnindeki madde atfı doğru kanunda olmalı (TTK m.222 ≠ HMK m.222 vakası); dayanak **bent düzeyinde** ("p.22(b)"); kanun adı tam ("213 sayılı Vergi Usul Kanunu"), kısaltma yalnız KDV/TMS/TFRS/BDS.
6.6 **Dayanak kara listesi** (`dayanak-kara-liste.json`, hakemle >%50 yanlış): teyitli görünse de dayanaksız sayılır. **Yığılma ≠ çöp**: VUK m.275'e 2.088 konu bağlıydı, %80'i doğruydu; körlemesine boşaltma yasak.
6.7 **Kaynak metni resmî metnin aynısı:** ders başına bir kez ambar ↔ resmî PDF karşılaştırması (TMS 36 ✓; sırada BDS 500, VUK). Ambardaki çift paragraf numaraları (Ek/UR) yutucuda düzeltilecek (Ö57).
6.8 **Kaynak türü dağılımı raporlanır:** bir dersin soruları tek maddeye yığılıyorsa eşleşme çökmüştür (40 sorunun hepsi 5 maddeye bağlanmıştı, cevaplar hafızadandı). "Yeşil koşu ≠ doğru soru; her paralı koşudan sonra sorular okunur."
6.9 **Konu etiketi** hakem `konu_uyum` ile doğrulanır (etiket doğruluğu %87,5 ölçüldü); etiketi uymayan soru pencereye girmez.
6.10 **Hakem 5–6: güncellik + atıf (08.09, Cem "kanun maddelerinin doğru olduğu"):** hakem her soruda iki alan daha verir: `guncellik` GUNCEL/ESKI (kaynakta "mülga / yürürlükten kaldırılmıştır", süresi geçmiş geçici madde, eski yıl parametresi → ESKI ve karar HAYIR) ve `atif` EVET / ATIF-YANLIS / TEYITSIZ (dayanaktaki kanun+madde numarası kaynak metnindeki madde başlığıyla uyuşmuyorsa ATIF-YANLIS ve karar HAYIR; madde kaynak paketinde hiç yoksa TEYITSIZ → yayına çıkar ama karneye iz). Dayanaktaki madde ambarda bulunamazsa üretici `atif_ambarda_yok` izi + rapor satırı yazar. Sıfır ek bedel (aynı Haiku çağrısı). Eski hakem kararları yeniden verdirilmez; yeni basımdan itibaren geçerli.
6.11 **Sınav dili terim çiftleri kapılardan ÖNCE uygulanır (Cem 08.09 "genel yönetim gideri gibi kalıplar"):** `veri/terim-ciftleri.json` ölçümünden gelen 9 çift (genel idare→genel yönetim gideri, genel imal→genel üretim, DİMM/GÜG/Dİ açılımı…) `DilOnarNesne` ile soru kapılara girmeden onarılır; böylece KAPI-K (pencere dışı kavram) sınav dilini ölçer, kanun dilini değil. Kök kalıbı (1.4) ve tip tarifi istemde zaten sınavdan.

## 7 · KAPI ZİNCİRİ (sırayla; her soru hepsinden geçer)

yazım + terim onarımı (kapı öncesi) → uzunluk (p75) → KAPI-Ş şık dengesi/biçimi → KAPI-H kod-ad çifti → KAPI-K pencere dışı kavram → KAPI-T tip → KAPI-Ç çeldirici doğrulama → KAPI-Y yıl → KAPI-O koku → KAPI-B benzerlik → KAPI-D2 Türkçe harf → KAPI-YD yevmiye dengesi → KAPI-P yasal parametre → **KAPI-M mülga mevzuat/kurum → KAPI-S süresi dolan veri** → KAPI-E tek anlam → dil kapısı (Türkçe harf, klişe, tekrar) → aritmetik kapısı → tek işlem → YAPI kapısı (teori) → giriş kapıları (240 kelime, terim kim/kaynak, yer tarifi, sızıntı) → **kör çözüm** → hakem (kaynak metniyle) → **ikinci hakem** (sınav gibi / koku) → öğrenci simülasyonu → karne → Cem örneklemi.
Kapılar 2 deneme; ikincide de düşen soru rapora yazılır, kaydedilmez. **Kapıdan önce istem düzeltilir** (istemsiz kapı para yakar). **Yeni hat: önce ölçüm (0 USD), sonra pilot, sonra tam koşu.**

## 8 · YAYIN ŞARTI ve SONRASI

8.1 **Vitrine çıkma şartı:** hakem EVET ∧ simülasyon ✓ ∧ kör çözüm ✓ ∧ karne yeşil/sarı ∧ Cem örnekleminde hata yok. Dördü birden yoksa yayın yok; üretilen her soru `yayin=false` doğar.
8.2 **Karne her partide**; Cem yalnız kırmızı/sarı + %5 örneklem okur. Örneklemde **bir gerçek hata = o dersin partisi bütünüyle geri**, sebep kütüğe, kapı eklenir.
8.3 **Yayın sonrası nöbet:** adayların çoğu aynı yanlış şıkka gidiyorsa soru "şüpheli"; "Hata bildir" aynı gün karantina (yayından çekilir, silinmez).
8.4 **Vitrin ≠ kasa:** eski kasa "arşiv" etiketiyle durur, öğrenciye gösterilmez.

## 9 · BEDEL ve KALICILIK

9.1 Para harcayan her parti ÖNCE Cem'e bedeliyle sorulur; her koşu jeton yazar, USD'ye çevrilir, bitince gerçek bedel raporlanır. Aylık organizasyon tavanı koşudan önce bakılır (429 ortasında ölen parti dersi).
9.2 Ödenen işin kimliği anında loga ve `bekleyen-partiler.json`'a yazılır (18 + 39 USD kaybı dersi).
9.3 Hiçbir düzeltme tek soruya yapılmaz; kod/istem/kapı düzeltilir, kütüğe Ö satırı, aynı çağrıda commit + push. Öz-sınav: her kapı neden düştüğünü söyler, sessiz atlama yok.

## A · YENİ SORU YAZMA (ek kurallar)

A1. Konu pencere sayısına göre sıralı, bugün basılanlar dışlanır; boş konular (eski kasada aday yok) önceliklidir.
A2. Üretici JSON eksiksiz: soru · şıklar · doğru · açıklama · **teşhis (her şık: yanılgı/gerçek/ayırt/paragraf)** · **çeldirici yolu** · hap · sınav taktiği · notlandırıcı · şema · çözüm tablosu · verilenler · dayanak (bent).
A3. Gövdede mamul/gider yeri harfle olabilir (sınav böyle yazar); adım/açıklama/ikizde tam ad. TL yazılır (sınav 2018'den beri ₺ yazıyor; K2 kararı TL).
A4. Zor ayarı hesap konusunda; FMuh'ta teori konusu "zor" olmaz.

## B · ESKİ SORUYU KALIBA ÇEVİRME (kurtarma)

B1. **Giriş şartı:** kapı-temiz (K1–K17 + kara liste) ∧ kaynak damgalı ∧ konusu pencerede. Üçü yoksa arşiv.
B2. **Soru, şıklar, doğru cevap, kaynak DOKUNULMAZ** (29.07). Değişmesi gereken soru yeni sorudur (A yolu). Tek istisna yok; yuvarlak tutar düzeltmesi bile şıkları bozar, yapılmaz.
B3. **Uyarlama fazı** (tek çağrı): eski soru + açıklamadan çözüm tablosu, her şık için teşhis, yanlış şıklar için çeldirici yolu, verilenler, dayanak künyesi çıkarılır. Sonra hattın kalanı (adımlar, verilenler, giriş, ikiz, sim, hakem, kör çözüm) yeni soruyla AYNI.
B4. **Kapılar esnetilmez:** çeldirici tutmayan hesap sorusu KAPI-Ç'de düşer · kaynağı ambarda olmayan hakemden düşer · kör çözümle cevabı tutmayan düşer · konu etiketi pencereye uymayan düşer · kod-ad çifti tutmayan düşer · placeholder unvan / yuvarlak tutar taşıyan düşer (koku).
B5. **Düşen soru silinmez**, arşivde "neden düştü" satırıyla durur.
B6. **Bedel kuralı:** kurtarılan soru başına gerçek bedel yeni basımı geçerse o ders için kurtarma durur, kalan yeni basılır. Eşik 50'lik pilotla ölçülür, sonra tartışılmaz.
B7. Künyede iz: "eski kasa, v29'a çevrildi (tarih)" / "v29 (tarih)".
B8. **MEKANİK DÜZELTME İSTİSNASI (Cem 08.09 "üçüne de evet"; 29.07 "soru değişmez" kuralının tek istisnası):** anlamı değiştirmeyen düzeltmeler kurtarmada uygulanır ve `mekanik` alanında iz bırakır: (a) **yıl kaydırma** yalnız muhasebe derslerinde (FMuh, Maliyet, MTA, Denetim; bütün yıllar aynı farkla, süreler ve Türkçe ekler korunur) — hukuk derslerinde eski yıl **elenir** (yıla bağlı had riski); (b) yer tutucu unvan (ABC/XYZ A.Ş.) → "İşletme"; (c) uzun tire ve üç nokta → virgül/nokta (soru, şık, açıklama); (d) Türkçe harf onarımı ve kanun kısaltması açılımı (DilOnar); (e) sayı şıklarının küçükten büyüğe sıralanması (harf, doğru ve açıklama birlikte). Ölçüm (08.09, 5.909 aday): temiz %41 · mekanikle geçer %33 · sert kuralla elenir %26.
B9. **Sert kurallar kurtarmada da eler (Cem 08.09):** doğru şık en uzun (sızıntı), şıkta gerekçe / >160 karakter cümle şık, sayı şıklarında tekrar tutar, yön dengesi, koku (hepsi yuvarlak tutar, klişe, ABC/XYZ), **mülga mevzuat/kurum (KAPI-M, eski künye `kanun_no` dahil) ve süresi dolan veri (KAPI-S)**. Şık yeniden yazılmaz; düşen soru nedeniyle arşive. İlk 3 soruluk ölçüm: 1 dil kusuru (hakem2), 1 uzun tire (düzeltildi), 1 **muhasebe tekniği hatası** (590 hesabının yönü; kör çözüm ✗ + hakem2 HAYIR) — eski kasanın gerçek hata oranını pilot ölçer.

## C · SINAVA ve DERSE ÖZEL

C1. **SGS** hazır hat. **Yeterlilik**, **KGK** aynı hat, önce 3'er soru pilot (KGK ders sözlüğü eksik: sürdürülebilirlik/sermaye piyasası/banka/sigorta — %61 sınıflandırılamıyor, önce sözlük).
C2. **SPK:** çıkmış arşiv yok → çapa yok; konu listesi SPL resmî 195 alt konu, kaynak ambardaki SPK mevzuatı; künyede "çıkmışta N kez" yazılamaz, sayfada "resmî alt konu" yazılır ve bu fark açıkça gösterilir.
C3. **Genel kültür (Türkçe, Matematik, Yabancı Dil, İnkılap):** kaynak mevzuat değil. Matematik yapılabilir (kör çözümle doğrulanır); **Atatürk İlkeleri** karşılaştırılacak metin yok, kapı tutmaz → doğrulanamayan üretilmez, eksik bırakılır ya da eski kasadan gider (29.07 kararı). Türkçe/YD pilotsuz basılmaz.
C4. **Ekonomi, Maliye:** teori notu kaynağı bağlanmadan basım yok; bağlanamazsa açılışta eski kasadan gider, karnede "kaynaksız" işaretlenir.
C5. Aynı ders adı iki sınavda varsa (Finansal Muhasebe SGS + Yeterlilik) sayım ve kota `sinav` filtresiyle.

## E · BAŞLAMA ŞARTLARI — A kovası (07.09 gece çıkarıldı, 08.09 01:00 kapatıldı; kütük Ö70)

| # | Şart | Durum |
|---|---|---|
| 1 | Kör çözüm kapısı (FAZ K, farklı model, anlatımsız) | ✅ kodda, tek soruda ölçüldü |
| 2 | İkinci hakem (sınav gibi · koku · çeldirici gerçek · zorluk) | ✅ kodda, tek soruda ölçüldü |
| 3 | Koku kapısı üreticide (yer tutucu unvan, onbinlik tutarlar, klişe, uzun tire) | ✅ kodda |
| 4 | Zorluk cetveli karnede + sınavla kıyas | ✅ kodda; ilk ölçüm: parti sınavdan sapıyor (çok zor %48, şaşırtmalı %41) |
| 5 | Benzerlik kapısı (çapa ve parti içi) | ✅ kodda |
| 6 | Şık harfi dağılımı | ✅ kodda |
| 7 | Konu tekilleştirme + genel kök stoplist | ✅ kodda, ölçüldü |
| 8 | Konu listesi kalıcı (dosya) | ✅ kodda, ölçüldü |
| 9 | Bedel her çağrıda, koşu sonunda USD | ✅ kodda (fiyat tablosu varsayım) |
| 10 | Yayın yolu (ders sayfaları + dizin) | ✅ araç; menü/üye kapısı Cem kararı |

Basım ancak bu tablo tamamen ✅ iken başlar. Yeni şart çıkarsa buraya eklenir, basım durur.

**B kovası (basarken paralel; 08.09 03:00 durumu):** 11 kurtarma fazı ✅ (tek soruda ölçüldü) · 12 genel gece koşucusu ✅ · 18 kapı-temiz tazeleme ✅ (15.922) · 19 KAPI-Ç iç eşitlik + zincir eşitlik ✅ · 13 yeterlilik/KGK pilotu ⏳ (≈2 USD, KGK sözlüğü önce) · 14 SPK hattı ⏳ (pilot ≈1 USD) · 15 Ekonomi/Maliye teori notu ⏳ · 16 genel kültür pilotu ⏳ (≈1,5 USD) · 17 ambar↔resmî PDF aracı ⏳ · 20 paralel hat ölçümü ⏳ (≈0,1 USD).
**Kural 7/A6 kodlandı (08.09):** sert kapılar ikinci denemede de düşerse soru KAYDEDİLMEZ; yalnız yumuşak kapılar (uzunluk, pencere dışı kavram) raporla kalır.

**08.09 05:30 — Cem "engellememiz gereken bir yer var mı, atladık demeyelim" taraması, üç açık kapatıldı:**
- **KAPI-P yasal parametre (sert):** asgari ücret, kıdem tavanı, KDV/SGK/damga/stopaj oranı, gecikme zammı, yeniden değerleme, istisna haddi, defter/fatura sınırı, vergi tarifesi soruda geçiyorsa SAYISI soruda verilir ("…olduğu varsayılmıştır"); verilmezse düşer. Cevap yılın gerçeğine değil soruya bağlanır. İstem kuralı 16.
- **Benzerlik havuzu seviyeler/turlar arası:** aynı planın (sgs-t1-*) bütün etiketleri karşılaştırmaya girer; kolay/zor/çok zor ve tur 2 aynı konuda kopya senaryo üretemez.
- **Plan bölüm süzgeci:** analiz bölümü dersle uyuşmayan konu (Genel Kültür → FMuh gibi) plana alınmaz; para harcanıp hakemde düşmez.
- Bilerek kabul edilenler: olumsuz kök / öncüllü soru KOTASI (karne dağılımı ölçer, kapı yok — tur 1 sonrası bakılır) · KAPI-K kök şişmesi yumuşak · Ekonomi/Maliye kaynaksız · yayın sonrası şüpheli nöbeti (cevap verisi gelince) · fiyat tablosu varsayım.

## D · KARAR KAYDI

| Tarih | Karar | Kim |
|---|---|---|
| 07.09.2026 | v1 taslak (12 ortak + A + B + C) | GM |
| 07.09.2026 | v2: sınav kalıbı, yapay zeka izi, formül, yıl, hesap kodu, kanun bölümleri ayrıntılı eklendi (Cem: "kalıplarımıza ayrıntılı bak") | GM |
| 08.09.2026 | 4.5 KAPI-M, 4.6 KAPI-S, 6.10 hakem güncellik/atıf, 6.11 terim çiftleri kapı öncesi (Cem: "eski kanun, madde doğruluğu, süresi dolan veri, soru kalıpları") | GM |
| 08.09.2026 | **Tur 1 kapsamı: kaynaklı 9 ders (1.593 soru); Yabancı Dil, Matematik, Türkçe, İnkılap, Ekonomi, Maliye açılışta basılmaz, ayrı hat sonra** ("hiç basma, SGS açılışı 9 dersle çıksın") | Cem |
| 08.09.2026 | Kurallar Tur 1 ile fiilen yürürlükte ("basalım diyeceğim artık, eksiğimiz yok") | Cem |
