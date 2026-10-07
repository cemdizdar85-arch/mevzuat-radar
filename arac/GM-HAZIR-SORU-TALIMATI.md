# GM HAZIR SORU YAZIM TALİMATI — Yeterlilik (bitirme) · kalıcı şablon

> 05.10.2026, Cem "1.2.3" (GM2). Her GM turunda yazar ajana BU dosya verilir; tura özgü konu/zorluk ayrıca söylenir.
> Neden kalıcı: GM talimatları oturum scratchpad'inde duruyordu ve oturumla kayboldu (gm3 TALIMAT.md bulunamadı).
> Soru metni bu dosyaya ve depoya GİRMEZ; yazar yalnız kendisine verilen yerel dosyaya yazar (`veri/fabrika/hazir-*.json` gitignore'da).

## Ölçülmüş neden (gm6 + gm7, 05.10.2026)
28 hazır soru yazıldı → 12'si partiye girdi → **1'i yayına girdi**, ≈1,19 USD (yayına giren soru başı ≈1,2 USD; gm2 0,065).
- 13 soru girişte **KAPI-Y** (yıl) ve **KAPI-K** (sınav dili) ile düştü; ön denetim ikisini görmüyordu → eklendi.
- Partiye girenlerin en az 6'sı **adım/sade katmanında** düştü: hazır soruda `adimlar` yoktu, bulut modeli yazdı (ADIM-KAYMA, YY-SIKSIZ,
  simülasyon yanlış, açıklama hakemi "6. adımda bulduk"); teori sorusunda adım hiç yazılmadı → "simülasyon koşamadı".
- 2 hakem HAYIR kaynak paketinden: ambardaki kanun kaydı tek bir yılın tutarını yılsız taşıyor (iş emri `veri/AMBAR-YUTMA-IS-EMRI-20260930.md` 15–18).

## Bağlayıcı belgeler (önce OKU)
1. `SORU-URETIM-SOZLESMESI.md` — Bölüm A (A1: çıkmış soru KOPYALANMAZ) ve Bölüm B'nin TAMAMI; **B24 S1–S8** ve **B25** aynen geçerli.
2. `STANDART-CEVAP-KALIBI.md` — açıklama kalıbı kilitli (doğru şık: "Ne soruluyor: … Kural: … Bu olayda/Hesap: … Doğrusu: …").
3. Biçim örneği (yalnız BİÇİM): yayında olan bir partinin `kalip-parti-smmm-*.json` kaydı — `adimlar`, `verilen`, `sade` alanlarının yapısı.

## Kaynak — hafızadan rakam YAZILMAZ
Rakam, oran, had yalnız AMBARDAN (`dokumanlar.kaynak_ad`). Kullanılan her kaydın adı `kaynak_adlar`'a birebir yazılır (ön denetim ambarda arar).
Yıla bağlı had: kanun kaydındaki parantezli tutar yılını SÖYLEMEZ → tutarı o yılın genel tebliğinden al (ör. GVK 2026 tarifesi ve hadleri GVGT `SERİ NO:332` — ambarda adı BOŞLUKSUZ; 2025 için `SERİ NO: 329`). Ambar araması geniş desenle yapılır (`%NO:332%`) — 05.10'da boşluklu arama "yok" dedi, kayıt vardı.
GVK m.22 (kâr payı istisnası) 05.10'da ambara eklendi.

## Ücretsiz kapılar (bulut bunlarla soruyu PARA HARCAMADAN düşürür)
- **KAPI-Y:** kökteki EN YENİ yıl = bugünün yılı. Geçmiş yıl soruluyorsa kökte bugünün yılı bağlamı verilir
  ("2025 yılı gelirleri için 2026 yılı Mart ayında verilecek beyanname"). Kanun numarası ("6183 sayılı") sayılmaz. "2026'da" kesmeyle.
- **KAPI-K:** kökte SMMM test kitapçıklarında geçmeyen (≥6 harfli) kelime en çok 1. Kişi/şirket/yer adı da sayılır → "(A) Bey", "Ece".
- **AYNI KONU:** bir dosyada bir konudan yalnız BİR soru (üretici fazlasını iz bırakmadan atar) → zorluk/etiket başına ayrı dosya.
- Şık artan sıra · uzunluk tavanı · yuvarlak tutar · ikiz (KAPI-B, sayı ikizi) · kaynak adı ambarda.

## ⭐ B25 — ADIM ve SADE YAZAR TARAFINDAN YAZILIR
Her soruda:
- `adimlar`: dizi, en az 2 adım. ADIM 1 = "Verilen: …" (soruda verilen her değer). Her adım `{formul, anlatim, doldur}`;
  `doldur` = `cozum_tablo` satır/sütun koordinatları ([[satır,sütun],…]). S1: "(N. adımda bulduk)" N = o değerin "= sonuç" yazıldığı adım.
  S2: yanlış yol adımı bir ÇELDİRİCİ şıkkın değerine birebir varır, doğru cevaba ya da şıksız bir sayıya varamaz.
  Teori sorusunda da adım yazılır (Ne soruluyor → Kural → Bu olayda → Doğru şık).
- `verilen`: soruda verilen değerlerin `cozum_tablo` koordinatları.
- `sade`: `{dogru, sinav, siklar{A..E}}` — herkesin anlayacağı dilde doğru yol + sınav notu + her şık için tek cümle.
- `hap` (07.10 eklendi): kuralın akılda kalan TEK cümlesi, ≤140 karakter. Açıklamanın "Kural:" cümlesini tekrar etmez (sayfa,
  kelimelerin %60'ı kural/doğrusu ile aynıysa hap'ı gizler); "Sen anlat" bölümünde "Nöbetçi böyle anlatırdı:" diye gösterilir.
  Ölçüldü (07.10): sitedeki 508 GM sorusunun 497'sinde hap BOŞTU — bulut GM sorusuna hap yazmaz, yalnız dosyadakini taşır;
  model basımlarında FAZ'lar yazıyordu. Boş hap KAPI-BOS'a (BOS-KALINTI) takılır ve "Sen anlat" bölümü boş kalır.
Bulut bu alanları dosyadan alır, model yazdırmaz (motor/kalip-parti-uret.ps1 FAZ GM).

## ⭐ BİLİNEN HATA KONTROL LİSTESİ — her soru tek tek (Cem 05.10: "eski kurallar, hakemin bulduğu hatalar kontrol edilsin")
Her madde yazımdan SONRA soruya karşı tek tek işaretlenir; "kapı yakalar" diye atlanmaz.
**A. Hakemin yayındaki 1.000 soruda bulduğu sınıflar (sözleşme B23):**
1. Kavram kaynakla çelişiyor → her kural cümlesinin karşılığı ambardaki metinde AYNEN var mı?
2. Hesap kodu/adı THP ile aynı mı (100 KASA ≠ 102 BANKALAR, 590 ≠ 591, 780 ≠ 660)?
3. Madde/fıkra/bent/paragraf numarası kaynak metinden mi okundu (hafızadan değil)? (gm7: "m.75/2-2" yerine 2-1 olmalıydı)
4. "(N. adımda bulduk)" N doğru mu (ADIM 1 = Verilen)? (gm7: "6. adımda" yazılmış, değer 7. adımda)
5. Her yanlış şık açıklaması KENDİ şıkkının yolunu mu anlatıyor (başka şıkkın sayısını değil)?
6. Her işlem tutuyor mu (adımlar, çözüm tablosu, sade, açıklama aynı sayıyı veriyor mu)? (gm7: sade "E beş kalemin toplamı" dedi, değildi)
7. Teşhis (yanilgi/gercek) açık ve o şıkka özgü mü?
8. "(soruda verilen)" yalnız kökte harfiyen geçen değere mi?
9. Teori/DEĞİLDİR sorusunda ✓/✗ işaretleri ters değil mi?
**B. Sözleşme B24 S1–S8** (adım atfı · yanlış yol çeldiriciye varır · Türkçe harf · istem kalıntısı yok · THP · madde no kaynaktan · uydurma yok · kök tek anlamlı).
**C. Eski kurallar (KAPI-EK, `arac/eski-kurallar.json`, 13 madde):** KDV %20 (18 değil) · 630 = Ar-Ge (GÜG değil) · VUK m.270 mülga →
m.262 · VUK'ta "yıl 360 gün" yok · kâr payı stopajı %15 · eski GV dilimleri 18.000/40.000/98.000 kullanılmaz · KV %25 · teminatsız tecil
10.000.000 · TMS 1 → TFRS 18 · TMS 8 yeni adı · faiz/temettü sınıflaması TFRS 18 sonrası · 649/659 eski açıklama → 645/646/655/656.
**D. Yeterlilik vergi ölçümünde (gm6/gm7) çıkanlar:** kökte yıl = bugün (KAPI-Y) · yılsız kanun tutarı yerine o yılın tebliği
(GVK 2026: `SERİ NO:332`) · kişi adı kısa · bir dosyada bir konu.

**E. gm8 ikinci göz ölçümünde (05.10, 15 soru, 5 dosya, 14 okuma) bulunan sınıflar — yazarken baştan uygula:**
1. **Oranın dayanağı oranı koyan düzenlemedir**, kanun maddesi değil: kâr payı stopajı "%15 (2009/14592 sayılı BKK m.1/6-a, 9286 sayılı CBK
   ile değişik)"; tarife "GVK m.103 + o yılın GVGT'si (2026: SERİ NO:332 m.3/3)". Kanun maddesinde yazmayan oran o maddeye bağlanmaz.
2. **Atıf biçimi her alanda aynı:** `m.X/fıkra` ya da `m.X/fıkra-bent`; numaralı fıkrası olmayan maddede "birinci fıkrasının (1) numaralı
   bendinin (b) alt bendi" (m.86/1-b). Ambar paragraf sırasından okunur (m.74: /1 bentler, /3 götürü gider, /4 para cezası).
3. **Sınır ifadesi kanundaki gibi:** m.86/1-c "vergiye tâbi gelir toplamı" (istisna içindeki kısım girmez), m.21 "gayrisafi tutarları toplamı".
   Kısaltılmaz; iki toplam aynı soruda geçiyorsa karışır.
4. **Varsayım yerine kaynak:** ambarda olan parametre (2026 asgari ücret: ASGARİ ÜCRET TESPİT KOMİSYONU KARARI, RG 26.12.2025/33119) kökte
   "kabul edilecektir" diye uydurulmaz. Kaynakta yoksa senaryo o parametreye çarpmaz (B11).
5. **Yürürlük:** "Bu madde hükümleri … tarihine kadar uygulanır" diyen geçici maddeye (ör. GVK geç. m.67 → 31.12.2025) uzatması ambarda
   yoksa dayanılmaz.
6. **Kural cümlesi kanun alıntısı gibi yazılmaz** ("GVK m.86/1-c: …" önekiyle kanunda olmayan cümle yok); uygulama yolu "m.X gereği …" diye
   çıkarım olarak anlatılır. Listeyi kapatan "yalnız" kanunda kapalı değilse kullanılmaz.
7. **Adımda dayanılan her madde açıklamanın "Kural:" kısmında da anılır**; sınır kontrolü kendi adımında, toplam bulunduktan SONRA.
8. Kökte ödeme biçimi/yıl/kesinti yapılıp yapılmadığı gibi sonucu değiştiren her olgu açıkça yazılır (yemek bedeli banka mı nakit mi).

**F. gm8 bulut sonucundan (05.10: 15 gönderildi → 12 hakem EVET, açıklama hakemi 10/10 TEMİZ, 7 yayına; kayıp içerikten değil biçimden):**
1. **Çeldirici yolu biçimi (KAPI-Ç):** her yanlış şık için TEK zincir; çok adım `;` ile ayrılır, SON parça `işlem = şık değeri`. "… ve …" ile
   zincirleme YASAK (üretici çözemez, soru düşer — GMSİ 3/3 böyle düştü). Açıklama notu yalnız EN SONDA parantezde: `105.000 + 225.000 = 330.000;
   330.000 x %85 = 280.500 (istisnayı unuttu)`. Ön denetim artık üreticinin gerçek KAPI-Ç işlevini koşar.
2. **Teori sorusuna `cozum_tablo` YAZILMAZ** (VUK/kavram soruları): tablo varsa üretici soruyu hesap sorusu sanıp sayısal ikiz kurar, öğrenci
   simülasyonu metin cevabı çözemez ("U" ≠ "(U)'nun 2019 faturaları") ya da hiç koşmaz → yayına girmez (gm8: VUK 3/3). Teoride `adimlar`
   yazılır (Ne soruluyor → Kural → Bu olayda → Doğru şık), `doldur: []`, `verilen: []`.
3. **Adımlar kuralı GENEL öğretir:** simüle öğrenci adımları okuyup İKİZ soruyu (aynı kural, başka değer) çözer. Kural yalnız sorudaki değer için
   anlatılırsa ikizde "yetmedi" der (gm8 GV zor: yalnız 2. derece engellilik tutarı anlatıldı, ikiz 3. dereceyi sordu). Parametreli kuralda
   bütün seçenekler ya da genel formül adımda yazılır.
4. **Doğru şık dağılımı (A4):** bir dosyada bir harf %40'ı aşmasın (ön denetim `SIK DAGILIMI` satırı uyarır). Sayısal şıklar artan sıralı
   olduğundan harf, çeldiricilerin doğru cevaba göre büyük/küçük kurulmasıyla seçilir; yazara dosya başında hedef harf verilir.
   **Harf planı yazımdan ÖNCE üretilir ve yazara aynen verilir** (05.10, gm8'de sonradan düzeltmek çeldiricileri yeniden kurdurdu):
   `powershell -NoProfile -File arac/hazir-soru-denetle.ps1 -HarfPlani veri/sinav/konu/<etiket>-kolay.json` → her konu için kolay/zor/çok zor
   harfi; her zorluk dosyasında harfler dengeli, her konunun üç sorusu üç ayrı harf. Yazar plandaki harften ayrılmaz.

**G. gm9 ikinci göz ölçümünden (05.10, 30 soru, 5 yazar, 13 okuma; anahtar sorunu 0, 1 soru çıkarıldı) — yazarken baştan uygula:**
1. **E6 yazılıydı, beş yazarın dördü yine çiğnedi** (teshis.*.gercek'te "GVK m.X: <çıkarım>" — p1 23, p4 22, p2 21 cümle sonradan
   düzeltildi). Kural aynı: önekli cümle ambar metniyle BİREBİR; değilse önek yok, "m.X gereği …". Kesik alıntı da yasak (VUK m.340'ın
   "… ile 359 uncu maddede ve diğer kanunlarda" kısmı atılmıştı).
2. **Çeldirici = TEK yanlış.** Öğrenci bir hata yapar, öteki her kuralı (sınır kontrolleri dahil) doğru uygular ve o şıkka varır.
   Öncüllü (I/II/III/IV) soruda her yanlış şık doğru kombinasyondan TEK ifadeyle ayrılır. (gm9: çok zor MSİ'de C kooperatif yolu yarı
   istisnayı atlıyordu; çok zor VUK'ta iki şık üç ifadeyle ayrılıyordu → soru dalgadan çıktı.)
3. **Atıf zinciri açıklamada:** bir madde başkasını uyguluyorsa bağı kuran cümle yazılır (VUK m.333 "m.10 hükmü vergi cezaları hakkında da
   uygulanır"). Fıkra kayıtları düşürülmez (m.10/5 "tasfiye edilerek ticaret sicilinden silinmiş" ≠ "tasfiye"; tasfiye dönemi → tasfiye memuru).
4. **Kökte olmayan bilgi olgu gibi yazılmaz** ("yurt içi müşterilerden kazanç" — kök yalnız toplamı ve yurt dışı kısmı veriyordu → "diğer kazanç").
5. **Ambar araması:** desen yalnız baştan eşleşir; ortadaki parça için `%…%` (ör. `%SERİ NO: 311%` — adda boşluk var; boşluksuz arama
   "ambarda yok" sanıldı, YANLIŞTI).
6. **KAPI-K kelimelerini yazarken sına** (aşağıda DALGA DÜZENİ 2a): gm9'da en çok yeniden yazım bundandı ("avukat, müvekkil, kiracısı, ısıtma,
   hasılat, kardeş, ihale, tahliye, sponsorluk, bilezik" SMMM test sözlüğünde yok).

**H. gm11 (FM 20) + gm12 (Vergi 20) ikinci göz ölçümünden (07.10; 40 soru, 6 yazar, 11 okuma; anahtar anlaşmazlığı 0, çıkan 0,
DÜZELT 10 soruda) — yazarken baştan uygula:**
1. **Kaynak hesap kökte yazılır:** para çıkışı/borç ödemesi olan soruda paranın hangi hesaptan çıktığı açıkça yazılır (gm11: iki döviz
   sorusunda borcun bankadaki dövizden mi ödendiği yazmıyordu → doğal okumada şıksız sonuç).
2. **Beyan sınırı ÖNCE kontrol edilir:** tevkifatlı gelirde "beyannamede mahsup edilir" ya da "götürü gider seçmiştir" yazmadan önce
   m.86/1-c sınırı (2026: 400.000) aşılıyor mu bakılır; aşılmıyorsa beyan yok, götürü gider seçilemez (gm12 GMSİ iki tur düştü).
3. **Yanılgı tutarlılığı (G2'ye ek):** teşhisteki yanılgı sorudaki BÜTÜN kalemlere tutarlı uygulandığında aynı şıkka varmalı; yalnız bir
   kaleme uygulanıp öteki kalemler doğru hesaplanıyorsa yanılgı adı yanlıştır (gm12 yıllara yaygın inşaat A şıkkı).
4. **VUK m.280 ≠ m.285:** yabancı para borç/alacak değerleme günü kuruyla (borsa rayici) değerlenir; "kayıtlı tutar" m.285'in genel kuralıdır.
5. **VUK GT 588 hadleri "m.3 ve ekli liste"**, m.5 değil (m.5 yürütme maddesi; ambar had listesini m.5 parçasına bağlıyor, oradan okuyan
   yanlış atıf yazar). Kararla değişen oranda (kreş %50 → GVGT 303 m.7, BKK 2018/11674) tebliğ kaydı da `kaynak_adlar`'a girer.
6. **Gerçekçi bağlam:** kökteki sektör verilen oranla çelişmesin (gm11: "gıda ticareti + tüm işlemlerde %20 KDV" → elektronik eşya).
7. **Mevduat stopaj oranı ambarda yok** (karar metni yutulmadı, iş emri `veri/AMBAR-YUTMA-IS-EMRI-20260930.md`): oran kökte VERİ olarak
   verilir, yasal oran iddiası kurulmaz.
8. **Ön denetimde `-Ders <ders adı>` ver:** verilmezse uzunluk tavanı 746 alınır, ders tavanı ölçülmez (07.10 FM 526). ⚠ Vergi için ön
   denetim 350 diyor ama gm9'un 529–665 kr kökleri bulutta geçti — iki ölçüm tutarsız, ÖLÇÜLMEDİ; kök ≤460 tutulursa iki durumda da güvenli.
9. **Adım formülünde `;` zinciri** ön denetimde KUSUR sayılır (F1'deki `;` yalnız `celdirici_yol` içindir): adım tek hesaplı yazılır.
10. Yazarlar ortak scratchpad'de yardımcı betik adını kendi önekiyle verir (ör. `gm11fm-amb.js`); bir yazarın betiği başkasınca ezildi.

**I. gm13 (Denetim 20) + gm14 (Vergi 20) ikinci göz ölçümünden (07–08.10; 40 soru, 6 yazar, 8 okuma; anahtar anlaşmazlığı 0,
çıkan 0, DÜZELT 15 soru — hepsi yeni okuyucudan TEMİZ) — yazarken baştan uygula:**
1. **Hap'ta kanundaki şart düşürülmez, mutlak konuşulmaz:** "YK ne seçebilir ne kovabilir" (TTK m.399/9 geçici seçim var), "itiraz kapısı
   kapalıdır" (m.399/7 üç iş günü itiraz), "dördüncü dilim" kaydı düşmüş ücret, m.27/2 "haklı sebep" şartı düşmüş emsal. Hap'ı sorunun KENDİ
   sayılarıyla sına (gm14: "faiz matrahı büyütür, ödül küçülür" dedi, soruda indirim BÜYÜYORDU). Kanundaki terim: "istisna" (muafiyet değil).
2. **Alt tutar kökte veri olarak veriliyorsa bağlı oranı kaynaktan doğrula:** BES Devlet katkısında hak kazanma 4632 ek m.1 kademeleri
   (3 yıl %15 · 6 yıl %35 · 10 yıl %60 · emeklilik/vefat/malullük tamamı); "hak edilen 38.900 / 52.700" hiçbir kademeye uymuyordu.
3. **Cevabı belirleyen olgu ambarda yoksa kökte VERİ olarak açıkça yazılır** (gm14: "İzmir kalkınmada öncelikli yöre değildir" ambarda
   yoktu, B ile E'yi o ayırıyordu). Bölge, büyükşehir, sektör teşvik listesi gibi bilgiler.
4. **Çok tehditli durum tek etiketle yanlış yapılmaz (Etik Kurallar):** uzun süreli ilişki p.540.3'te hem yakınlık hem kişisel çıkar;
   aile/kişisel ilişki p.521.2'de kişisel çıkar, yakınlık, yıldırma. Öncülde "X: kişisel çıkar" yanlış diye kurulursa iki şık savunulur.
5. **Aynı dalgada kolay ve çok zor aynı alt konudaysa tuzaklar çakışmasın:** gm14 ithalat matrahı iki soruda aynı üç tuzağı taşıyordu
   (bulutta KAPI-B benzerlik riski); çok zor soru tuzağı tersine çevirerek (CIF dışında ayrıca ödenen navlun) ayrıştırıldı.
6. **Yıl kayan tutarlarda yıl kaydı:** "12.000.000 TL (2026'da verilen beyannameler için, GVGT 332 m.3/4)" — tutarın hangi yılın beyannamesine
   ait olduğu yazılır; 2026 geliri için yeniden değerlenmiş tutar ambarda yoksa "ölçülmedi".
7. **Ambar adı tuzakları:** "Bagimsiz Denetim Yonetmeligi" Türkçe harfsiz kayıtlı; büyük İ ilike ile eşleşmez → İ'siz parçayla ara
   ("%ğımsız Denet%" değil "Bagimsiz Denetim%"). VUK/GVK/KDVK 07.10'da yeniden yutuldu (ad değişti: "GVK (193 s.K.) m.8", "m.22 [2/3]").

**J. gm15 (SPK 20) ikinci göz ölçümünden (08.10; 20 soru, 3 yazar, 4 okuma; anahtar anlaşmazlığı 0, çıkan 0, DÜZELT 11 soru):**
1. **Suç sorusunda kökte SUÇ ADLANDIRILIR** (ör. "m.107/1 piyasa dolandırıcılığı", "m.106 bilgi suistimali") ya da "genel usul (m.115 ve
   m.116)" çerçevesi yazılır. Adsız "Kurulun yazılı başvurusu muhakeme şartıdır / dava asliye cezada görülür" kökü, SPKn m.115/A yüzünden iki
   şıkkı savunulur kılar (bu dalgada üç soruda çıktı).
2. **SPKn m.115/A kapsamı birebir:** savcının Kurulu beklemeden (gecikmede sakınca varsa) resen soruşturması YALNIZ m.110/A/3'teki suç
   içindir; m.110/A/1–2 zimmetinde m.115/1 geçerli (Kurulun yazılı başvurusu). Davanın ağır cezada görülmesi (m.115/A/3) ise BÜTÜN m.110/A
   zimmet suçları içindir. "Kripto zimmetinde savcı resen başlar" genellemesi YANLIŞTIR.
3. **Etkin pişmanlık kapsamı:** m.107/3 yalnız m.107/1 (işlem bazlı) için; m.107/2 ve m.106'da yok; m.110/3 güveni kötüye kullanmada ayrıca
   var. "Etkin pişmanlık yalnız dolandırıcılıkta" YANLIŞTIR.
4. **Satış Tebliği (II-5.2) m.10/2:** fiyat aşağı revize edilirse ilk halka arzda da açıklamayı izleyen ikinci gün başlanabilir — "yalnız
   borsada işlem gören" demek E6'yı çiğner; kökte "fiyat revizyonu öngörülmemektedir" yazılır.
5. **İkinci göz okuyucusu önerdiği hap'ı da ölçer:** ≤140 kr ve doğru şık açıklaması + sade.dogru ile 5+ harfli kelime ortaklığı <%60
   (ön denetimin HAP TEKRAR ölçütü); gm15'te önerilen hapların çoğu bu ölçüte takılıp yazar ikinci kez yazdı.
6. Ambar adları: Satış Tebliği "Sermaye Piyasasi Araclarinin Satisi Tebligi (II-5.2)" Türkçe harfsiz; SPKn m.108 kaydına 7222 dipnotları
   karışmış (ceza alt sınırı oradan okunmaz, iş emri).

## DALGA DÜZENİ (05.10, gm8 düzeltme turunda ölçülen sıra — atlanmaz)
1. **Harf planı** (`-HarfPlani <konu dosyası>`) → yazara aynen verilir.
2. **Yazar** doğrudan `veri/fabrika/hazir-gmN-<etiket>-<zorluk>.json` adıyla yazar (konu başına ayrı dosya YOK). Neden: ön denetimin sıkı
   bitirme modu (KAPI-K sözlüğü, adım/sade/simülasyon KUSUR) etiketi dosya adından okur; gm8'de yazarlar `k2.json` adıyla yazdı, sıkı mod
   koşmadı, denetim ayrı kopyada ikinci kez koşturuldu.
2a. **Kök denemesi (1–2 sn, ikiz yok):** `arac/hazir-soru-denetle.ps1 -KokDene "<kök metni>" -IkizEtiket smmm-gmN-<etiket>-<zorluk>`
   ya da `-KokDene <dosya.json>`; `DUSER` satırı = bulut bu kökü KAPI-K'da düşürür. Sözlük önbellekte 12 saat (`-KokTazele` yeniler).
   Tam denetimin YERİNE GEÇMEZ (adım, sade, ikiz, KAPI-Ç, simülasyon ön kontrolü yalnız tam denetimde).
3. **Ön denetim sıkı modda + ikiz:** `-Dosya <dosya> -IkizEtiket smmm-gmN-<etiket>-<zorluk>` → 0 KUSUR.
4. **İkinci göz** (aşağıda) — her dosya bağımsız okuyucu; düzeltme olduysa düzeltilen soruyu YENİ okuyucu okur (öncekinin sonucunu görmez).
5. **Yükle + geri oku:** `arac/hazir-senkron.ps1 -Yukle -Ad gmN-…`; ambardan inen içerik yerelle (anahtar sırası hariç) birebir.
6. Plan (`hazirSoru`; düzeltilmiş ve önbellekte "GM geçti" kaydı olan soru için `pilotId` + `hazirYenileId`) → commit → `motor/bulut-sira.ps1 -Ekle`.

## İKİNCİ GÖZ (zorunlu, gönderimden önce)
Soruyu YAZMAYAN ayrı bir okuyucu her soruyu ambar kaynağıyla birlikte okur: (1) anahtarı kendisi bağımsız çözer, (2) A ve B listesini
işaretler, (3) karar: TEMİZ / DÜZELT (ne) / ÇIKAR. Anahtar anlaşmazlığı ya da ÇIKAR → soru gönderilmez. Düzeltme yazara döner, ön denetim
yeniden koşar. Kapıların GÖRMEDİĞİ sınıflar (madde/fıkra atfı, uydurma, kök muğlaklığı, kavram) yalnız burada ve bulut hakemlerinde yakalanır.
**Karar ölçütü (gm9'da ölçüldü: ölçütsüz her yeni okuyucu yeni bir üslup ayrıntısı bulup döngü açtı):**
- KUSUR = anahtarı değiştiren ya da iki şıkkı savunulur kılan · kaynakla ÇELİŞEN kural/oran/madde/fıkra/tutar · bir şıkkın gerekçesini/yolunu
  yanlış yapan · kökte olmayan bilgiyi olgu gibi yazan · önekli alıntısı ambar metnine aykırı.
- NOT (kusur değil) = üslup, uzunluk, daha iyi ifade, eksik ama yanlış olmayan bilgi. Not soruyu geri göndermez.
- **Son tur:** bir soru en çok iki düzeltme turu alır; ondan sonraki okumada hâlâ KUSUR varsa soru dalgadan ÇIKAR ve konusu o zorluğun
  konu dosyasından da çıkarılır (yoksa üretici boş yere okunmamış model sorusu yazar). gm9: zor VUK cezaları 4 okumada TEMİZ'e vardı;
  çok zor VUK defter-belge son okumada KUSUR → çıktı.
- Okuyucu talimatı (`IKINCI-GOZ.md`) okuyucuya bu ölçütle verilir; ambar örnek komutu `"%<desen>%"` biçimindedir.

## Teslimden önce (zorunlu)
`powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya <dosya> -IkizEtiket smmm-<etiket>`
Çıktıda KAPI-Y / KAPI-K DUSER / KAPI-KALITE / ADIM YOK / SADE YOK kalmaz. (KAPI-S'in bir türünü ön denetim görmeyebilir — gm7'de 1 vaka.)
