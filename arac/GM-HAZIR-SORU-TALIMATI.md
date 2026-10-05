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

## İKİNCİ GÖZ (zorunlu, gönderimden önce)
Soruyu YAZMAYAN ayrı bir okuyucu her soruyu ambar kaynağıyla birlikte okur: (1) anahtarı kendisi bağımsız çözer, (2) A ve B listesini
işaretler, (3) karar: TEMİZ / DÜZELT (ne) / ÇIKAR. Anahtar anlaşmazlığı ya da ÇIKAR → soru gönderilmez. Düzeltme yazara döner, ön denetim
yeniden koşar. Kapıların GÖRMEDİĞİ sınıflar (madde/fıkra atfı, uydurma, kök muğlaklığı, kavram) yalnız burada ve bulut hakemlerinde yakalanır.

## Teslimden önce (zorunlu)
`powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya <dosya> -IkizEtiket smmm-<etiket>`
Çıktıda KAPI-Y / KAPI-K DUSER / KAPI-KALITE / ADIM YOK / SADE YOK kalmaz. (KAPI-S'in bir türünü ön denetim görmeyebilir — gm7'de 1 vaka.)
