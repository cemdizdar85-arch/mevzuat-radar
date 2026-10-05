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

## Teslimden önce (zorunlu)
`powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya <dosya> -IkizEtiket smmm-<etiket>`
Çıktıda KAPI-Y / KAPI-K DUSER / KAPI-KALITE / ADIM YOK / SADE YOK kalmaz. (KAPI-S'in bir türünü ön denetim görmeyebilir — gm7'de 1 vaka.)
