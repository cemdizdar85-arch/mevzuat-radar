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
