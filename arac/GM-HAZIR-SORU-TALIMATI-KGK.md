# GM HAZIR SORU YAZIM TALİMATI — KGK (Bağımsız Denetçilik) · kalıcı şablon

> 07.10.2026, Cem "eksik kuralları yapalım" (KGK oturumu, K1 + K7). Her KGK GM turunda yazar ajana BU dosya + `arac/GM-HAZIR-SORU-TALIMATI.md`
> (yeterlilik talimatı) verilir. Yeterlilik talimatının **B25, A/B kontrol listesi, E6/G1 önek alıntı, G2 çeldirici = tek yanlış, G3 atıf
> zinciri, G4 kökte olmayan bilgi, F.1 çeldirici yolu `;` zinciri, F.2 teoride tablo yok, F.3 adım kuralı genel, F.4 harf planı, DALGA DÜZENİ ve
> İKİNCİ GÖZ** bölümleri KGK'da AYNEN geçerlidir. Vergiye özgü maddeler (C listesinin KDV/GV oranları, D, E1–E5) KGK'da yalnız konu vergiye
> değiyorsa (TMS 12) uygulanır. Bu dosya KGK'ya özgü olanları ekler; çelişkide bu dosya kazanır.
> Soru metni bu dosyaya ve depoya GİRMEZ; yazar yalnız `veri/fabrika/hazir-kgk-<dalga>-<modül>-<zorluk>[-N].json` dosyasına yazar.

## Neden ayrı dosya (ölçüldü 07.10)
- Yerel KGK hazır dosyalarında (60 dosya, 814 soru; d1/d1b 27.09'da yazıldı) **808 soruda adımlar şık HARFİ anıyor** ("Cevap B şıkkıdır.",
  "A şıkkını seçmek (HATALI) → doğrusu B"). Seviye testi ve şık kaydırma şıkların yerini değiştirir → metin yanlış harfi gösterir.
- KGK'da KAPI-K sözlüğü, B25 sertliği, uzunluk tavanı ve onarım hattı KGK listesi yoktu (07.10 kuruldu, aşağıda).
- 27.09 ölçümü (79 GM Denetim sorusu, 71 yayın şartı geçti): düşen 8'in 5'i hakem2 "YZ kokusu", 3'ü simülasyon YETMEDİ (anlatım tanımı ve
  faktörün yönünü eksik veriyordu).

## Kaynak — hafızadan paragraf/madde/rakam YAZILMAZ
- Paragraf, madde, fıkra, oran, eşik yalnız AMBARDAN (`dokumanlar.kaynak_ad`); kullanılan her kayıt `kaynak_adlar`'a birebir.
  Ad biçimleri: `BDS 701 p.13 - …`, `TMS 16 p.31 - …`, `Sermaye Piyasası K. (6362 s.K.) m.35`, `Bankacılık K. (5411 s.K.) m.24 [1/2]`,
  `Sigortacılık K. (5684 s.K.) m.16 [1/3]`, `KGK Kurulus KHK (660 s.) m.9 [1/4]`. Parçalı maddede ([k/n]) atıf yapılan fıkranın geçtiği parça da listeye.
- **KAPI-AILE:** kaynak yalnız modülün resmî aileleri (`veri/kgk-ders-aile.json`). Örnek: Denetim sorusuna TTK maddesi değil BD Yönetmeliği/BDS;
  Sigorta sorusuna TTK yalnız m.14xx–15xx. Aile dışı kaynak paketten sessizce atılır → soru "kaynak yetersiz" düşer.
- **Paragraf numarası resmî metinden:** BDS 500 eski numaralama (A25→A29 … A31→A35 kaydı) kullanılmaz; KAPI-BP komşu paragrafı yakalar.
  BDS 700 p.50 bent harfleri ambarda YOK → bent harfiyle atıf yapma, paragrafla yap.
- **Yeni sürüm esas** (Cem 30.09): TMS 1 yerine TFRS 18 (KAPI-EK). TFRS 18 01.01.2027'de yürürlüğe giriyor; sunum sorusunda kök hangi standarda
  göre sorulduğunu AÇIK yazar ("TFRS 18'e göre …"). İki standarda göre farklı cevabı olan kök yazılmaz.
- **Finansal Yönetim istisnası** (Cem 27.09, karar A): resmî metin yok (SPL 1007 telifli). Formül/kavram notunu GM yazar; her soru yine kör çözüm
  + simülasyondan geçer. "Resmî metin" kuralının TEK istisnası, yalnız FY modülü.

## ⭐ K7 — YILA BAĞLI TUTAR VE EŞİK
- Yıla bağlı eşik (bağımsız denetime tabi olma ölçütleri, sermaye/özkaynak alt sınırları, idari para cezası tutarları, BDDK/SEDDK oranları)
  **o yılın düzenlemesinden** alınır (Cumhurbaşkanı kararı, kurul kararı, yeniden değerleme ilanı) ve dayanağı o düzenlemedir, kanun maddesi değil
  (yeterlilik talimatı E1'in KGK karşılığı). Ambarda o yılın düzenlemesi yoksa senaryo o eşiğe ÇARPMAZ (sözleşme B11) — ayrıca kaynak borcu yazılır.
- Kökteki EN YENİ yıl = bugünün yılı (KAPI-Y, ön denetimde KUSUR). Geçmiş yıl soruluyorsa bugünün yılı bağlamı verilir
  ("2025 yılı finansal tabloları için 2026 yılında yapılan bağımsız denetimde …"). Kanun numarası ("6362 sayılı") sayılmaz.
- "Bu madde … tarihine kadar uygulanır" diyen geçici maddeye uzatması ambarda yoksa dayanılmaz.

## ⭐ KGK'YA ÖZGÜ YAZIM KURALLARI
1. **K4 — Şık harfi ANILMAZ** (kök dışında hiçbir alanda: açıklama, teşhis, sade, adımlar, çeldirici yolu, hap, sınav taktiği).
   "Cevap B şıkkıdır." / "C şıkkı bu yüzden düşer" / "doğrusu A" / açıklama sonunda "Doğrusu: B." / çıplak harf ("A ve D düşer",
   "B söyler →", "yalnız E'de → E") YASAK — 07.10 onarımında 770 KGK sorusunun 486'sında bu kalıplar vardı, site "Doğrusu:" sonrasını
   olduğu gibi gösteriyor. Şık İÇERİĞİYLE anılır: "Doğru cevap: görüş vermekten kaçınma."
   "Bildirimi kaldıran seçenek p.14'e aykırıdır." Teori adımının son adımı: "Doğru şık: <şık metni>". Kişi adı "(A) Bey" serbest.
2. **K5 — "(soruda verilen)"** yalnız kökte harfiyen geçen sayıya. Hesaplanan değer "(N. adımda bulduk)" ile anılır (S1).
3. **K6 — Fıkra atfı** (`m.X/Y`) ambar metnindeki "(Y)" fıkrasından okunur; maddenin parçalı kaydında fıkra hangi parçadaysa o parça `kaynak_adlar`'da.
   Numarasız fıkralı eski kanunda fıkra numarası verme ("birinci fıkra" diye sayma da yapma) — maddeyle atıf yap.
4. **Olumlu kök tercih edilir** (15.09 ölçümü: hakem olumsuz kökte "işaretli şık yanlış" deyip HAYIR verdi). Olumsuz kök gerçek sınav kalıbındaki
   payı aşmaz (`veri/sinav-anatomisi-kgk.json`; ölçülmeden sabit oran yazılmaz).
5. **Doğru şık TEK bir maddeye/paragrafa dayanır** (KAPI-KP konu dışı sayıp ilke kararını paketten düşürebiliyor).
6. **Tutar resmî yazımla:** "750.000.000 TL" ("750 milyon TL" KAPI-H'de THP 750 hesabı sanılır). Üç haneli sayıyı birimsiz yazma (KAPI-HG).
7. **Çözüm anlatımı tanımı ve her faktörün YÖNÜNÜ eksiksiz verir** (27.09: simülasyon "yetmedi" 3/8). Risk/önemlilik sorusunda "artırır/azaltır"
   her faktör için ayrı yazılır; simüle öğrenci ikiz soruyu (aynı kural, başka faktör) bu anlatımla çözebilmeli.
8. **YZ kokusu yok** (27.09: hakem2 düşüşlerinin 5/8'i): "bu bağlamda", "önem arz etmektedir", aynı cümle kalıbının tekrarı, em-dash, placeholder
   unvan (ABC A.Ş.) yok. Denetçi/işletme adı kısa ve doğal ("Ege Denetim", "(K) A.Ş.").
9. **KAPI-K (KGK sözlüğü):** kökte KGK kitapçıklarında hiç geçmeyen (≥6 harfli) kelime en çok 1. Ön denetim tüm KGK kitapçıklarından kurulan
   sözlükle ölçer (`KGK KAPI-K` satırı); bulut KGK'da KAPI-K koşmaz — bu yalnız sınav dili kalitesidir, düşen kelimeyi sınav diliyle değiştir.
11. **T kodlu paragraf (Türkiye uygulaması) esastır** (07.10 ikinci göz, kgk-o2-tds-zor/kp-10 ÇIKAR): BDS 700/705/720'de "2T, 21T, 22T" gibi
    Türkiye'ye özgü paragraf varsa soru onlara göre kurulur ve kök bunu yazar. Örn. Türkiye'de faaliyet raporu (diğer bilgiler) DENETLENİR
    (BDS 720 p.2T) — uluslararası p.21-22'ye göre "denetlenmez" diye anlatılan soru iki doğru şıklı olur.
12. **Tanım tek bende indirgenmez** (07.10, 27 DÜZELT'in en sık sınıfı): tanımın birden çok bendi/şartı varsa (BDS 505 p.6 "yanıt" tanımı,
    BDS 250 kapsam kısıtı p.27-28, BDS 510 p.10-11 görüş seçenekleri) "yalnız / her / … olur" ile tek bende daraltılmaz.
13. **"Kural:" kısmına kaynakta olmayan sonuç cümlesi eklenmez** ("böylece yeni risk doğar") ve "gerekebilir" → "gerekir" sertleştirilmez.
14. **Kavram tanımının kaynağı** (`sade.kavramlar[].kaynak`) tanımın GERÇEKTEN geçtiği paragraftır ve `kaynak_adlar`'a da eklenir
    (07.10: GDS 3400 p.9 yerine p.4, BDS 500 p.A64 yerine BDS 315 p.12 — hiçbir kapı bu alanı okumuyor).
15. **Örnek olayda iki ilkeye birden uyan senaryo kurulmaz** (07.10, kp-30: yönetim müşteriyle birlikte → hem muvazaa hem kontrol ihlali).
16. ~~Çeldirici yolunda tek haneli yüzde yazılmaz~~ — KALDIRILDI 08.10: üretici KAPI-Ç yüzde hatası f32e6971 ile düzeldi; 08.10 ölçümü
    "x %3", "x %3,5", "x %30", "x 0,03", "(…) x %3", "x %3 x 2" altı vakanın altısı doğru. "%3" çeldirici yolunda da serbest.
17. **Kural 12 kısa alanlarda da geçerli** (07.10 TMS turu, 117 soruda 7 DÜZELT'in 3'ü): `sinav_taktigi`, `sade`, `hap` gibi tek cümlelik alanlarda
    tanım/kural tek şarta indirgenmez ("birçok yıl ürün veren ağaç taşıyıcı bitkidir" — p.5 üç şart arar), liste kapatılmaz ("yalnız FIFO ve ortalama").
18. **Kökteki kanıt cümlesi hükmün şartıyla çatışmaz** (07.10, TMS 12 p.35 ÇIKAR): standart "güçlü kanıt/karine" şartı arıyorsa kök "başka kanıt
    yoktur" demez; doğru cevabın dayandığı kanıtı kökte açıkça verir ("imzalı satış sözleşmelerine dayanan bütçe").
19. **Yıla bağlı eşik kökte verilir** (K7'nin uygulaması; 07.10 BOBİ FRS büyük işletme: ambardaki tek kaynak 2021 kararı): soru eşiğin ezberini
    değil uygulanışını ölçer ("Ölçütler: aktif 200.000.000 TL, hasılat 400.000.000 TL, 250 çalışan").
20. **Açıklamada anılan her paragraf `kaynak_adlar`'da** (07.10 ikinci gözün en sık notu: TMS 20 p.7, p.36, TFRS 10 B94 listede yoktu) — hakem
    paketi o paragrafı görmezse doğru açıklama "kaynaksız" sayılır.
10. **Bir dosyada bir konudan BİR soru** (27.09: 85 sorunun 19'u aynı konu adıyla iz bırakmadan kayboldu).

## Modül sırası ve önkoşul (07.10)
- Denetim Standartları → Muhasebe Standartları → Finansal Yönetim → Kurumsal Yönetim → Sürdürülebilirlik.
- **Başlık sızması (madde sonuna sonraki başlık):** yutucu düzeltildi (122d1279). 07.10 altyapı: Bankacılık (255 kayıt) + Sigortacılık
  (106) TAZELENDİ (928af587), SPK 6362 da 07.10 3. turda TAZELENDİ (00a6dca3) → yazılabilir. ⚠ SPK'da t2 yazarlarının bulduğu 6 ambar
  kusuru (6362 m.13/84/106/107 bozuk metin, II-26.1 m.8'e m.9 karışmış, Borsalar Yön. m.5 ESKİ metin) `veri/AMBAR-YUTMA-IS-EMRI-20260930.md`'de
  AÇIK (13.10) — bu maddelere dayanan soru yazılmaz, ambar düzelene dek SPK'ya yeni dalga açılmaz (Cem 13.10 GM3).

## ⭐ 13.10 KURALLARI (Cem "1.2.3 üçünü de yap")
- **K10 — Plan bütçesi AÇIKLAMA HAKEMİNİ kapsar.** Ölçüldü 13.10: t1/t2'nin 8 planı (326 soru, ≈14,7 USD) yazım + dört hakemi ödedi, açıklama
  hakemine bütçe kalmadı → bulut "plan tamamlandı" dedi, yayın şartı 0 soru seçti. Plan tavanı = yazım+hakem bedeli + **AH payı ≈0,03 USD/soru**.
  Mekanik: `arac/aciklama-hakemi-uretim.ps1` `AhButceYarimIzi` — AH bütçesiz kalırsa `butce-doldu.log` YARIM izi, bulut işi KIRMIZI, zincir durur
  (öz-sınav + mutasyon `iz-yok`, dogrula.yml). Devam: bütçeyi artır, aynı planı `bulut-sira -Yeniden` ile sıraya koy (önceki işler bedava hasat).
- **K11 — KGK kasa yayını bulut bitişinde otomatik** (`bulut-uretim.yml` KGK adımı: `kgk-kasa-yayin.yml yaz+site_kabuk`). 13.10'a dek yalnız
  elle tetikleniyordu; d1b'nin 154 sorusu 6 gün ambarda bekledi.
- **K12 — İKİ BAĞIMSIZ OKUYUCU.** Her hazır dosya, yazarından bağımsız İKİ okuyucu tarafından ayrı ayrı okunur (`ig/BRIF.md` düzeni: bağımsız
  çözüm → kaynak uyumu → A/S listesi → karar). İkisinden biri CIKAR dediyse soru dosyadan çıkar; DUZELT varsa düzeltme uygulanır ve düzeltilen soru
  YENİ bir okuyucuya gider; ikisi de TEMİZ demeden dosya yüklenmez. Neden: KGK'da bugüne dek tek okuyucu koştu; bitirmede tek okuyucunun TEMİZ
  dediği 10 sorunun 6'sı ikinci okuyucuda kusurlu çıktı (30.09). İki okuyucunun ANAHTAR uyuşmazlığı → üçüncü okuyucu (hakem), çoğunluk değil
  kaynak cümlesi karar verir.
  **Durma kuralı (13.10, t3 ölçümü):** düzeltilen soru yeni okuyucuya gider; **üçüncü düzeltme turundan sonra hâlâ KUSUR çıkan soru dalgadan
  çıkar** (kopyası saklanır, sonraki dalgada sıfırdan yazılır). Neden: t3'te kusurlar tur tur başka alanda çıktı (fy-g1 etkin piyasa 4 tur,
  tms-g3 16 düzeltilen sorunun 13'ü 3. turda yine kusurlu) — sonsuz onarım yerine yeniden yazım.
- **K14 — KISA ALANDA ŞART DÜŞMEZ** (13.10 t3: DUZELT'lerin en sık sınıfı, ~70 soruda). `hap`, `sinav_taktigi`, `sade` ve yanlış-yol adımında
  "yalnız / her zaman / hep / yoktur / … içindir / … değildir / kesinlikle" geçiyorsa dayandığı paragrafın ŞARTI ya da İSTİSNASI aynı cümlede yazılır.
  Kaynaktaki kip korunur: "genellikle", "-ebilir", "gösterebilir", "mümkündür" kesinleştirilmez. Tanımın bentleri (TMS 32 p.11 (c)(ii), TMS 24 p.9/p.11,
  TFRS 15 p.82 üç şartı, TFRS 16 p.27/p.32, TFRS 3 p.23/p.32/p.58) sayılıyorsa hepsi sayılır ya da "örneğin" denir — kapalı liste kurulmaz.
  Konuya özgü tekrarlar: **TMS 40 p.53** anılınca "ilk defa edinildiğinde" şartı yazılır (p.55: önceden gerçeğe uygun değerle ölçülen o yöntemde kalır);
  **TMS 33 bedelsiz pay** "dağıtım tarihinden tartılmaz, ilgili grubun ağırlığını alır" diye anlatılır, "ay ağırlığı yok" denmez.
- **K15 — KÖK, HÜKMÜN UYGULANMA ŞARTINI AÇIK VERİR** (13.10 t3: 9 ÇIKAR'ın 7'si). Doğru cevap bir şarta bağlıysa o şart kökte olgu olarak
  yazılır; okuyucu "şart yoksa hangi şık?" diye sorar. t3 vakaları: TFRS 3 p.23 "geçmiş olaylardan kaynaklanan mevcut yükümlülük" (×2) · BOBİ FRS 9.33
  değer düşüklüğü kanıtı · temettünün ödenme zamanı (son ödenen / gelecek yıl) · TMS 7 sürümü (2026 sorusunda TFRS 18 ile değişik metin → kök
  "TFRS 18 ile değişik TMS 7'ye göre" der; eski TMS 7 ile aynı cevap çıkmıyorsa) · BOBİ hasılat iade tahmini · borç/özkaynak "pasif yalnız …" ·
  TFRS 2 planın özkaynağa mı nakde mi dayalı olduğu. Değer düşüklüğü sorusunda kanıt olgusu (TMS 36 göstergesi / BOBİ 9.34) kökte ZORUNLU.
  Kök verisi kendi içinde tutarlı olur (t3 fy-g4: kredili alış > stoktan çıkan net alış idi).
  **Kök düzeltilince eski ifade her alanda aranır** (13.10, tms-g1 TFRS 15: kökten "sabit bedelli" çıkarıldı, açıklama katmanında 6 yerde
  "sabit bedel" kaldı → son okumada kusur, soru dalgadan çıktı). Kökte değişen her kelime/sayı soru, aciklama, teshis, adimlar, verilenler,
  cozum_tablo, celdirici_yol, sade, hap, sinav_taktigi alanlarında taranır; kalıntı 0 olmadan yeni okuyucuya gönderilmez. Yuvarlama "iki basamağa yuvarlanacaktır" diye yazılır
  ("alınacaktır" kesme okunur, 13.10'da 17 kökte düzeltildi).
- **K16 — t4 DERSLERİ (14.10, Cem "1.2.3"; 336 yazılan → 309 ambarda, 27 çıktı — okuyucu bulgularının sınıfları)**
  - **Şart açıklamada var, kısa alanda yok** (son turlardaki kusurların çoğu): şart/istisna `aciklama`/`teshis`'te yazıldıktan sonra
    `hap`, `sinav_taktigi`, `sade.*`, yanlış-yol adımı, `notlandirici`, `verilenler` alanlarında AYNI şart aranır. Konuya özgü tekrarlar:
    TFRS 15 p.56 "önemli bir iptal olmayacağı kuvvetle muhtemel değilse" ("iptal riski yüksek" DEĞİL) · p.60–62 "önemli", 62(a) "bedel devirden
    önce ödenmiş", p.63 "düzeltme zorunluluğunu kaldırır" · p.B19(a) yalnız fiyata yansıtılmamış beklenmedik fire · TFRS 3 p.B55(a) yalnız iş
    ilişkisi bitince **kendiliğinden** kesilen ödeme · TFRS 5 p.8 bentlerin hepsi (ortak onayı olasılığı, p.9 istisnası), p.11 "ihtimali yüksek" ·
    TFRS 9 p.5.4.1 kredi-değer düşüklüğü istisnası, p.5.4.3 iki oran istisnası · TMS 12 p.23 sonraki değişiklik kâr/zarara, p.58 işletme birleşmesi
    bendi · TMS 29 p.27 "fiyat düzeyine bağlı olmadığı oranda" · TMS 32 p.22A, p.16A–16D · BOBİ 13.19 "gerçeğe uygun değerle ölçülüyorsa",
    artış/azalış · TTK m.1444/2 üç "derhâl" hâli ve "bilgisi dışında", m.1445/6 "riziko gerçekleşmeden", m.1429/1 kastın sahibi · 5684 m.3/1
    "doğrudan bağlantılı işler", m.3/3 yalnız üyeleri dışındakilerle sözleşme yapmayan kooperatif, m.17/4 yalnız hayat dışı · Kredi Yön. m.8/5
    bütün kolları · TSRS 1 p.C2 "atıfta bulunabilir" + "standardın amacına yardımcı olduğu ölçüde", p.84 iki nitelik, E6(b) yalnız E5 kullanıldıysa.
    **Gerekli koşul daraltılırsa KUSUR; yeterli koşul eksik yazılırsa NOT** (okuyucu ayrımı).
  - **Niteleyici düşmez:** "önemli", "tamamen", "büyük ölçüde", "kuvvetle muhtemel", "ihtimali yüksek" kısa alanda da aynen yazılır.
  - **Kavram tanımı (`sade.kavramlar[].tanim`) tek bende indirgenmez** (TFRS 9 Ek A, TMS 2 p.6, TMS 32 p.11, TFRS 5 p.6–7, TSRS 1 p.21).
  - **Mutlak olumsuz hüküm yasak:** "Kanunda yoktur / geçmez / öngörmez" yazılmaz; yargı ilgili maddeyle sınırlanır ("m.3/3 bu sayıyı öngörmez").
  - **Yetkili makam güncel adla:** ambardaki 5684 metni "Müsteşarlık/Bakan" der; bugün **SEDDK Kurum/Kurul** (`SEDDK Teskilat ve Gorevleri Hakkinda
    CBK (47 s.) m.19` — m.19/1). Kökte/şıkta eski makam = soru yeniden yazılır; açıklamada makam anılmadan edilgen yazılabilir. Mekanik: KGK-MK.
  - **"Doğru cevap: <tutar>" satırı doğru şıkla aynı** (tms-g1: 5 soruda tutar değişmiş, satır eski kalmıştı). Tutar değişince her alanda aranır. Mekanik: KGK-DC.
  - **Kök olgusu (K15 eki):** zamanı/önemliliği cevabı belirleyen şart kökte açık yazılır — TFRS 5 p.B1(c)(i) "ilk yıl içinde tedbir aldı" ·
    TFRS 15 finansman "fark önemlidir" · TFRS 9 yapılandırma "kredi-değer düşüklüklü alınmamıştır; korunma muhasebesi yoktur" · TSRS kapsam
    sorusunda önceki yılın eşik durumu · TFRS 5 p.12'de yayım tarihi ≠ onay tarihi · AOSM "piyasa değeri ağırlıklarıyla" · TMS 29'da endeksli kalem
    ancak p.28 netleştirmesi soruluyorsa (yoksa iki şık savunulur — t4 çıktı).
  - **Çeldirici tek hata (G2/H3):** yanılgının adı tek başına uygulanınca şıkkın sayısını vermeli (fy-g2: iki hatalı yol tek yanılgı diye anlatılmıştı → çıktı).
  - Mekanik kapı: `arac/kgk-ek-kapi.js` (ön denetimde kgk- etiketinde kendiliğinden): KGK-DC ve KGK-MK DURDURUR; NOT-KGK-KA kısa alanda istisna
    sözlüğündeki atfın şartı yoksa NOT yazar (madde listesinde yanlış alarm verir, okuyucu karar verir).
- **K13 — Dalga = tek modül, ≤25 USD, önce ölç.** Yayına giren soru başına bedel + yayın oranı Cem'e gitmeden sonraki dalga açılmaz
  (CLAUDE.md para kuralı 1'in KGK uygulaması).
- **Standartlarda da sızma var** (07.10 altyapı ölçümü: 4.240 paragrafta 610 başlık kuyruğu adayı, örneklem 39/40 gerçek; Etik 317, TFRS 124,
  TMS 94, BDS 29). 122d1279 standart yutucusunu KAPSAMIYOR. Yazarken: paragraf metninin sonundaki noktalamasız başlık parçası hükmün parçası
  DEĞİLDİR — ona dayanan şık/açıklama yazılmaz (ör. BDS 701 p.13 sonu "…Denetçi Raporunda Bildirilmediği").

## ⭐ K17 — ÇİZİM KAPISI: her yeni soru "✍️ Nöbetçi çizerek çözsün"den GEÇER (22.10.2026)
> Cem 22.10: *"KGK eksiklerini tamamla ama Nöbetçi çizsin ve çizimle anlatsın; 'var zaten' deme."* KGK'da düğme listeyle değil kuralla açılır
> (`kgk-` öneki + `cizerek-coz.js` cizimKapi). Kapıdan dönen soru sitede düğmesiz çıkar → **hedefe sayılmaz**. Mekanik: ön denetimde
> **KGK-CZ (DURDURUR)** — `arac/kgk-ek-kapi.js` hazır soruyu sitedeki biçime çevirir (`motor/kaydir-coz.ps1` ile aynı alanlar) ve sitenin
> kapısından geçirir; kusur satırı ihlal edilen CZ kuralını söyler.
> **Ölçüldü (22.10, kasa):** t7 75/88 (%85,2) · t8 100/127 (%78,7) geçiyordu. Dönüşlerin sınıfı: öncüllü soruda hüküm okunamadı (en çok),
> sözel açıklamada dayanakta olmayan sayı, doğru şık kural cümlesinde aynen yok. Aşağıdaki kurallar kasadaki 215 t7/t8 sorusuna **mekanik
> benzetimle** uygulanınca 210/215 (%97,7) — yeni yazımda ÖLÇÜLMEDİ (ilk ölçüm: tek modül koşusu).
- **CZ1 — Öncüllü soru: "Bu olayda" satırı.** Öncüller kökte satır başında `I. … II. …` (soru cümlesinin altında); şıklar yalnız Romen kümesi
  (`Yalnız I` · `I ve III` · `I, II ve III`). Adımlarda TEK satır: `Bu olayda: I doğru · II yanlış · III doğru · IV yanlış` — kökteki **her**
  öncül bir kez, hüküm sözcüğü `doğru` / `yanlış` (kök "hangileri yanlıştır" diye sorsa da öncülün kendisi doğru mu yanlış mı o yazılır; kapı
  olumsuz kökte ✓'yi kendisi çevirir). Ölçüldü: `I: … → DOĞRU (m.4/1)` satırını kapı OKUMAZ (t7/t8'de öncüllü dönüşlerin çoğu) — yazılabilir
  ama "Bu olayda" satırının yerini tutmaz. Yanlış şık açıklaması öncül hükmü anıyorsa aynı hükmü verir (`III de doğrudur; …` · `II yanlıştır; …`);
  bir öncüle bir yerde doğru, başka yerde yanlış denmez (SZ-HUKUM). `doğru sandın` / `yanlış sanılır` serbesttir (hüküm sayılmaz). Son adım K4
  gereği `Doğru şık: I ve III`.
- **CZ2 — Öncülsüz sözel soru: doğru şık AYNEN.** `hap`'ın ilk cümlesi ya da `teshis.<doğru>.gercek` doğru şıkkın metnini harfiyen içerir
  (büyük/küçük harf dışında) ve başka hiçbir şıkkın metnini içermez. Kısa şıkta (kurum adı, süre, oran) en güvenlisi `teshis.<doğru>.gercek`
  = şık metnini aynen taşıyan tek cümle ("Denetçiyi Kurul yetkilendirir."). "Doğru cevap: …" / "Doğru şık: …" satırı kural sayılmaz.
- **CZ3 — Sayı disiplini (sözel alanlar).** `sinav_taktigi`'nde **rakam yok**. `hap` ve `teshis.*.gercek/yanilgi`'nin ilk cümlesinde, yanlış şık
  açıklamasının (tuzak metninin) ilk cümlesinde ve adım `anlatim`'ının ilk cümlesinde geçen her sayı soruda, şıklarda ya da `dayanak`'ta AYNI
  biçimde geçer. Kapı `m.54`, `p.4.29`, `İlke 1.3.8` gibi **nokta bitişik numarayı bulamaz** → bu alanların ilk cümlesinde madde/paragraf numarası
  yazılmaz; atıf `dayanak` + `kaynak_adlar` + `teshis.paragraf` alanında, gerekirse açıklamanın İKİNCİ cümlesinde kalır (K20 ve "Kaynak" bölümü
  değişmez). Kanun numarası ("5684 sayılı") ilk cümlede ancak soruda ya da dayanakta da varsa.
- **CZ4 — Hesap adımı.** Karalamaya giren her satır `Ad = a op b = c` tutar (±%0,5); adım adı rakam taşımaz (`D1`, `P0`, `2. yıl` yerine
  "Bir yıl sonraki temettü") — kapı addaki rakamı işlemin parçası sayar. Doğru şıkkın sayısı son hesap satırının sonucunda aynen yazılır
  (şık `4.000 TL` ise satır `… = 4.000`). Karalamadaki her sayı soruda, şıklarda ya da adım formüllerinde geçer; `Sağlama` satırı sonuç sayılmaz.
- **CZ5 — Her yanlış şıkta neden.** Yanlış şık açıklaması `<Ad> Tuzağı: <neden>` biçiminde ve ilk cümlesi CZ3'e uyar; ya da `teshis.<şık>.yanilgi`
  dolu. Nedeni boş şık karalanamaz (SZ-NEDEN).
- **CZ6 — Kök/şık biçimi.** Kökün soru cümlesi `?` ile biter ve "hangisi / hangileri …" kalıbını taşır (kapı altını bu öbekten çizer). Yanlış
  şıkkın tuzak adı "Doğru ifade" / "Yanlış ifade" olmaz (SZ-CELISKI).
- Ön denetim KGK-CZ verirse soru **yeniden yazılır** (çizimsiz yayın yok). Okuyucu (K12) çizim kapısını ayrıca okumaz; kapı mekaniktir.
- 🚫 Kapının GÖRMEDİĞİ (cizerek-coz.js): çizimin anlamca doğruluğu, hap/tuzak metninin hukuken doğruluğu, şartlı hüküm cümlesinin hangi öncüle
  ait olduğu — bunlar hakem + okuyucu işidir.

## ⭐ K18 — SINAV PROFİLİ HEDEFİ + ZORUNLU KAPI (29.10.2026, Cem "gm önerilerini yap ve bağımsız denetimi bitirelim")
- **Profil HEDEFİ (tavan değil)** — 27.10 "sınava benzemiyor" kuralının KGK karşılığı. Ölçüldü 29.10 (çıkmış KGK 2016+ ↔ t8 hazırları,
  `C:\TETIKTE-CALISMA\kgk-is\profil-olc.js`, anahtar kelimeyle modül sınıfı): kök medyanı SPK 174↔460 · Banka 192↔489 · Sigorta 200↔495 ·
  TSRS 426↔476 krk; olumsuz kök SPK %48↔%11 · Banka %34↔%8 · Sigorta %36↔%8 · TSRS %35↔%4; öncüllü SPK %11↔%27 · Banka %12↔%23.
  Yazar bu modüllerde gerçek oranı hedefler: kök medyanı ±%30, olumsuz kök gerçeğe yakın, öncüllü gerçeğin en çok 1,5 katı, şık kısa.
  Madde 4 ("olumlu kök tercih") bu modüllerde gerçek payı HEDEF alır. K15 geçerli ama şart tek cümleyle.
  🚫 GÖRMEZ (ölçü): modül sınıfı anahtar kelimeyle (yanlış sınıf olabilir) · kitapçıkta iki sütun karışması.
- **KGK-G2 (29.10, DURDURUR):** öncüllü soruda her yanlış şık doğru kümeden TAM BİR öncülle ayrılır ("I ve III" doğruysa "Yalnız I",
  "Yalnız III", "I, II ve III", "I, III ve IV"; "II ve IV" yazılmaz). Bankacılık t9 okumalarında çıkan 11 sorunun 7'si bu sınıftı. 3 öncüllü
  soruda "Yalnız II" ya da "I, II ve III" doğruysa dört komşu şık kurulamaz → dördüncü öncül ekle. Kasada yayındaki 205 öncüllü KGK
  sorusunun 10'u bu kurala uymuyor (29.10 ölçümü; ayrı iş).
- **Zorunlu kapı (öneri B):** okumaya gönderilmeden ÖNCE ve plan kurulmadan ÖNCE teslim denetimi + KGK-CZ 0 KUSUR. Plan kurucu
  (`kgk-is\plan-kur.js`) KUSURLU dosyayla plan yazmaz. Neden (23.10 ölçüldü): t8 spk-g5 teslim denetimi koşulmadan okumaya gitti;
  21 sorunun 11'i bulutta KAPI-Ş'den düştü, dört tur okuma boşa gitti.

## Teslimden önce (zorunlu)
```
powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya veri/fabrika/hazir-kgk-<…>.json
```
Dosya adı `hazir-kgk-…` ise (ya da `-IkizEtiket kgk-…`) KGK sıkı modu kendiliğinden açılır: ADIM YOK / SADE YOK / SIM KUSUR · KGK HARF ANMA ·
KGK SORUDA VERİLEN · KGK FIKRA ATFI · KGK-DC "Doğru cevap" kayması · KGK-MK eski sigorta makamı (14.10) · **KGK-CZ çizim kapısı (22.10, K17)** · KGK uzunluk tavanı (Denetim 784, Muhasebe Standartları 661 — etikette tms/tfrs yoksa `-Tavan 661`;
KGK'da `-Ders` VERME, SGS sözlüğü kurulur) · KGK KAPI-K. Çıktıda KUSUR kalmaz. Sonra İKİNCİ GÖZ (yeterlilik talimatı) → yükle → plan → bulut sırası.
Onarım: `node arac/onarim-hatti.js teslim <klasör>` kgk- etiketini artık `veri/sinav/kgk-elle-ret.json`'a yazar (07.10, K8).
