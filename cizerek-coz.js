/* cizerek-coz.js — "✍️ Nöbetçi çizerek çözsün" PİLOTU (14.10.2026, Cem: "sitedeki sorular da böyle cevaplansın")
 *
 * Kaydır-Çöz soru kartında, cevaptan sonra açılan panele bir düğme ekler. Düğme SGS/Yeterlilik'te yalnız PILOT listesindeki,
 * KGK'da (22.10.2026) "kgk-" önekli her soruda (KGK_DIS hariç; bkz. dugmeAday) ve yalnız KAPI geçerse çıkar. Tıklanınca soru, şıklar ve bir karalama alanı açılır; Nöbetçi
 * kalemle ADIM ADIM çözer ("Sonraki adım" / "Tümünü oynat"): soruda verilenlerin altını çizer, her çözüm
 * adımını el yazısıyla karalamaya yazar, doğru şıkkı yuvarlar, yanlış şıkları çeldirici nedeniyle karalar.
 * Ses yok (sessiz: kalem + alt yazı). Dosya/video yok: çizim tarayıcıda, sorunun kendi verisinden.
 *
 * İÇERİK KURALI: yazılan her şey sorunun kendi alanlarından gelir — adimlar[].formul (karalama satırı),
 * adimlar[].anlatim (alt yazı), siklar, celdiriciYol (yanlış şık notu), teshis (çeldiricisiz şıkta alt yazı).
 * Bu dosya rakam ÜRETMEZ, hesap YAPMAZ; yalnız metni sadeleştirir (açıklama ekleri silinir).
 *
 * KAPI (çizerekKapi): şu durumlardan biri varsa o soruda düğme GÖSTERİLMEZ:
 *   RAKAM   — çizimde yazılan bir sayı sorunun kaynak alanlarında (soru, siklar, adimlar.formul, celdiriciYol) birebir yok
 *   ARITMETIK — yazılan "a op b = c" zinciri tutmuyor (yuvarlama payı: 1 birim ya da %0,5)
 *   DOGRU   — doğru şıkkın sayısı karalamada yazılan satırlarda geçmiyor (çözüm doğru şıkka varmıyor)
 *   SOZEL   — sayılı çözüm adımı 2'den az (sözel soru şablonu ayrı aşama)
 *   VERI    — şık / doğru harf / adım alanı eksik
 * Öz-sınav + mutasyon: node arac/cizerek-coz-kapisi.js --sinav (dogrula.yml). Pilot listesi: aynı aracın --liste kipi.
 * 🚫 GÖRMEZ: sözel kusur (adım metni yanlış kural anlatıyor ama sayılar tutuyor) · adım SIRASININ mantığı ·
 *   alt yazının doğruluğu (anlatim alanından aynen gelir; yalnız sayıları denetlenir) · "%30" gibi oranın neye
 *   uygulandığı · kelimeli işlem ("3 Mart + 10 gün") hesaplanmaz, yalnız rakamları denetlenir.
 *
 * Yazı tipi: Caveat (SIL Open Font License 1.1, Google Fonts), kutuphane/caveat-600-*.woff2 — siteden sunulur,
 * yalnız düğmeye basılınca iner. Renkler sayfanın tema jetonlarından (sabit renk yok).
 */
(function (kok, fab) {
  if (typeof module === 'object' && module.exports) module.exports = fab();
  else kok.CizerekCoz = fab();
})(this, function () {
  'use strict';
  var MUT = (typeof process !== 'undefined' && process.env && process.env.CIZ_MUTASYON) || '';

  /* PİLOT LİSTESİ — 14.10.2026: site cevap kaydı (cevap_kayit, 09.10 sonrası, test oturumları hariç) en çok yanlış
     yapılan sayılı sorular; her birinin çizimi elle gözle kontrol edildi. Rapor: arac/cizerek-coz-kapisi.js --liste. */
  var PILOT = [
    // Yeterlilik — önce Finansal Muhasebe + Maliyet (11), sonra öteki sayılı sorular, yanlış sayısına göre (9)
    'smmm-4k-a-fmuh-zor-r3/kp-02', 'smmm-4k-a-fmuh-kolay-r4/kp-01', 'smmm-4k-a-fmuh-zor-r5/kp-03', 'smmm-w8-3-maliyet-kolay/kp-01',
    'smmm-4k-a-fmuh-cokzor-r4/kp-01', 'smmm-w3-maliyet-cokzor/kp-10', 'smmm-w1-fmuh-cokzor/kp-04', 'smmm-4k-a-maliyet-zor-r5/kp-03',
    'smmm-4k-a-maliyet-cokzor-r5/kp-01', 'smmm-4k-a-maliyet-zor-r3/kp-01', 'smmm-4k-a-fmuh-cokzor-r1/kp-01',
    'smmm-4k-a-yvergi-cokzor-r2/kp-02', 'smmm-4k-a-yfta-zor-r1/kp-01', 'smmm-4k-a-yvergi-cokzor-r8/kp-01', 'smmm-w5-yvergi-zor/kp-01',
    'smmm-w14-6-yvergi-cokzor/kp-02', 'smmm-4k-a-yfta-cokzor-r5/kp-01', 'smmm-gm12-1-yvergi-zor/kp-01', 'smmm-4k-a-yfta-zor-r3/kp-04',
    'smmm-4k-a-yfta-kolay-r2/kp-12',
    // SGS — yanlış sayısına göre (20)
    'sgs-k11-ticaret-zor/kp-01', 'sgs-d3-mta-cokzor-r3/kp-01', 'sgs-d3-maliyet-cokzor-r1/kp-02', 'sgs-c2-fmuh-kolay-r1/kp-02',
    'sgs-t1-fmuh-kolay/kp-11', 'sgs-d5-vergi-cokzor-r2/kp-02', 'sgs-d3-fmuh-kolay-r1/kp-16', 'sgs-d3-fmuh-kolay-r1/kp-21',
    'sgs-d2-fmuh-kolay-r1/kp-03', 'sgs-k11-mat-kolay/kp-03', 'sgs-c2-fmuh-kolay-r1/kp-03', 'sgs-d2-fmuh-zor-r1/kp-01',
    'sgs-d2-fmuh-kolay-r2/kp-04', 'sgs-c2-fmuh-zor-r3/kp-02', 'sgs-c2-denetim-kolay-r2/kp-05', 'sgs-c2-mta-kolay-r1/kp-01',
    'sgs-k5-fmuh-zor/kp-17', 'sgs-p-ekonomi-kolay-r1-a/kp-04', 'sgs-t1-mta-zor/kp-01', 'sgs-t1-maliyet-kolay/kp-07',
    // 20.10.2026 (Cem "1.2.3"): ücretsiz 5+5 örnek sorunun iki sözel sorusu — SÖZEL şablon (aşağıda sozelSenaryo)
    'sgs-k5-ekonomi-zor/kp-01', 'smmm-w3-yspk-cokzor/kp-18',
    // 27.10.2026: örnek setin yeni ilk soruları (arac/ornek5-liste.json 27.10). sgs-k10 sözel şablonla geçer; son adımı 27.10'da
    // onarıldı (önce "Çıktı = bilanço, gelir tablosu" B şıkkını taşımıyordu → SZ-DOGRU).
    'smmm-4k-a-yfta-kolay-r6/kp-01', 'sgs-k10-fmuh-kolay/kp-04'
  ];
  /* PROVA SONUCU (15.10.2026): oturum -> kimlikler. YET-2410 paketinin 80 sorusundan KAPI-CZ'yi geçen 43'ün gözle kontrolde kalan
     39'u. Çizim verisi rpc/prova_cizim'den yalnız oturum kapandıktan sonra gelir (radar-app/sql/2026-10-15-prova-cizim.sql, aynı liste).
     SGS-1710 bilerek YOK. */
  var PROVA = { 'YET-2410': [
    'smmm-w9-1-fmuh-cokzor/kp-08', 'smmm-gm3-3-fmuh-zor/kp-02', 'smmm-4k-a-fmuh-cokzor-r2/kp-01', 'smmm-4k-a-fmuh-kolay-r2-2/kp-01',
    'smmm-4k-a-fmuh-zor-r4/kp-12', 'smmm-w6-fmuh-zor/kp-34', 'smmm-w1-fmuh-zor/kp-05', 'smmm-w4-fmuh-cokzor/kp-10',
    'smmm-w5-fmuh-kolay/kp-16', 'smmm-w11-1-fmuh-cokzor/kp-02', 'smmm-w4-fmuh-cokzor/kp-09', 'smmm-4k-a-fmuh-zor-r3-2/kp-02',
    'smmm-gm5-28-fmuh-zor/kp-04', 'smmm-w10-4-fmuh-kolay/kp-01', 'smmm-gm5-10-fmuh-zor/kp-07', 'smmm-w5-fmuh-kolay/kp-15',
    'smmm-4k-a-maliyet-zor-r3/kp-20', 'smmm-4k-a-maliyet-kolay-r3/kp-02', 'smmm-gm4-5-maliyet-kolay/kp-02', 'smmm-w9-2-maliyet-kolay/kp-01',
    'smmm-4k-a-maliyet-kolay-r4-2/kp-03', 'smmm-4k-a-maliyet-zor-r3/kp-04', 'smmm-4k-a-maliyet-zor-r9/kp-03', 'smmm-4k-a-maliyet-kolay-r3/kp-20',
    'smmm-w7-2-maliyet-kolay/kp-01', 'smmm-gm5-2-maliyet-zor/kp-01', 'smmm-4k-a-maliyet-zor-r1/kp-23', 'smmm-w1-maliyet-zor/kp-14',
    'smmm-4k-a-maliyet-zor-r9/kp-02', 'smmm-gm-p2-maliyet/kp-03', 'smmm-gm5-1-maliyet-zor/kp-02', 'smmm-gm-p2-maliyet/kp-01',
    'smmm-4k-a-maliyet-zor-r7/kp-17', 'smmm-4k-a-maliyet-zor-r2/kp-01', 'smmm-w6-yhukuk-kolay/kp-01', 'smmm-4k-a-yhukuk-zor-r7/kp-05',
    'smmm-gm4-6-yspk-zor/kp-01', 'smmm-w14-11-yspk-cokzor/kp-01', 'smmm-w14-13-yspk-cokzor/kp-01'
  ] };
  /* SESLİ ÇİZİM (22.10.2026, Cem "uygun ses"): ücretsiz 10 örnek soru, maskot sesi (Instagram çizim videolarındaki kilitli ses).
     d = ses/cizim/<d>/r<n>.mp3 · b[i] = i. cümle çalarken çizilen SON sahne sırası (cümle i, önceki cümlenin bitişinden b[i]'ye kadar)
     · s[i] = cümle süresi (sn). Metin: kasa instagram-seviye/metin-site-ornek10.json (sorunun kendi çözüm adımlarından; sıklık rakamı yok).
     Senaryo değişirse (kapı/şablon) b[] kayabilir -> arac/cizerek-coz-kapisi.js --sinav "SES" vakası sahne sayısını tabloyla kıyaslar. */
  var SES = {
    'sgs-k11-ticaret-zor/kp-01':        { d: 'sgs-k11-ticaret-zor-kp-01',        n: 9,  b: [1, 2, 4, 8],       s: [10.84, 6.33, 7.3, 4.61] },
    'sgs-k5-ekonomi-zor/kp-01':         { d: 'sgs-k5-ekonomi-zor-kp-01',         n: 10, b: [0, 1, 2, 3, 9],    s: [4.31, 6.53, 8.51, 7.72, 3.42] },
    'sgs-d3-mta-cokzor-r3/kp-01':       { d: 'sgs-d3-mta-cokzor-r3-kp-01',       n: 11, b: [0, 2, 3, 6, 10],   s: [3.97, 7.66, 6.04, 4.29, 4.13] },
    'sgs-d5-vergi-cokzor-r2/kp-02':     { d: 'sgs-d5-vergi-cokzor-r2-kp-02',     n: 11, b: [0, 1, 3, 6, 10],   s: [5.09, 5.97, 5.77, 4.43, 4.13] },
    'smmm-4k-a-fmuh-zor-r3/kp-02':      { d: 'smmm-4k-a-fmuh-zor-r3-kp-02',      n: 11, b: [0, 2, 4, 6, 10],   s: [3.95, 8.72, 8.47, 8.68, 3.76] },
    /* 27.10: sgs-d3-maliyet-cokzor-r1/kp-02 ve smmm-4k-a-yfta-zor-r1/kp-01 örnek setten çıktı (arac/ornek5-liste.json; ilk soru kısa/kolay) -
       satırları kaldırıldı, ses dosyaları ses/cizim/ altında duruyor (yeniden girerse satır geri yazılır). */
    'smmm-4k-a-yvergi-cokzor-r2/kp-02': { d: 'smmm-4k-a-yvergi-cokzor-r2-kp-02', n: 11, b: [0, 2, 3, 6, 10],   s: [4.1, 8.01, 4.64, 5.63, 4.96] },
    'smmm-w3-maliyet-cokzor/kp-10':     { d: 'smmm-w3-maliyet-cokzor-kp-10',     n: 10, b: [0, 1, 2, 5, 9],    s: [4.1, 6.33, 6.75, 7.17, 5.21] },
    'smmm-w3-yspk-cokzor/kp-18':        { d: 'smmm-w3-yspk-cokzor-kp-18',        n: 7,  b: [0, 1, 3, 6],       s: [4.66, 7.8, 6.87, 4.8] },
    // 27.10.2026: aynı reçete (Mustafa Silici, eleven_v3, stability 0,3, atempo 1,14, 64k mono); r4 ham sesin sonuna kadar kesildi
    'smmm-4k-a-yfta-kolay-r6/kp-01':    { d: 'smmm-4k-a-yfta-kolay-r6-kp-01',    n: 9,  b: [0, 1, 4, 8],       s: [4.1, 4.65, 3.8, 7.2] },
    'sgs-k10-fmuh-kolay/kp-04':         { d: 'sgs-k10-fmuh-kolay-kp-04',         n: 7,  b: [0, 1, 2, 6],       s: [7.4, 7.73, 4.92, 6.09] }
  };
  if (MUT === 'sestablo') SES['sgs-k5-ekonomi-zor/kp-01'].n = 11;   /* öz-sınav bozması: tablo senaryodan kaydı */
  /* KGK SESLİ ÇİZİM (22.10.2026, Cem "çizime bağla, ses paket kapısı arkasında kalsın"): ses SİTEDE DEĞİL, kapalı depolama
     kovası 'cizim-ses-paket'te (radar-app/sql/2026-10-22-cizim-ses-paket-kasasi.sql: yalnız paketi olan üye okur, kural
     kasa_soru_getir ile aynı). d = kova klasörü (<id, / yerine __>), dosya d/r<n>.mp3. Her sahne bir cümle (b = 0..n-1).
     Ses reçetesi örnek sorularla AYNI (maskot Mustafa Silici, text-to-dialogue, stability 0,3, atempo 1,14). Tarayıcı pencere
     açılınca üyenin oturumuyla (window.__pkSb) 30 dk'lık imzalı adres ister; alamazsa (paket yok / oturum yok) çizim sessiz sürer.
     Senaryo kayarsa ses kapanır (aynı n kuralı); kasa verisi depoda olmadığı için kıyas: cizerek-coz-kapisi.js --kgk <paket.json>. */
  var KOVA = 'cizim-ses-paket';
  var SES_KASA = {
    'kgk-t2-ky-g4-cokzor/kp-03':    { d: 'kgk-t2-ky-g4-cokzor__kp-03', n: 11, b: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], s: [3.29, 5.25, 9.15, 6.2, 6.9, 3.9, 7.34, 6.81, 7.02, 7.12, 8.31] },
    'kgk-t4-tds-g2-cokzor/kp-04':   { d: 'kgk-t4-tds-g2-cokzor__kp-04', n: 11, b: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], s: [3, 1.65, 14.54, 14.87, 10.21, 4, 9.22, 13.37, 17.57, 3.41, 13.95] },
    'kgk-d1b-tds-zor-2/kp-23':      { d: 'kgk-d1b-tds-zor-2__kp-23', n: 7, b: [0, 1, 2, 3, 4, 5, 6], s: [4.18, 6.27, 4.92, 12.25, 9.53, 9.3, 9.63] },
    'kgk-t2-spk-g3-cokzor/kp-06':   { d: 'kgk-t2-spk-g3-cokzor__kp-06', n: 7, b: [0, 1, 2, 3, 4, 5, 6], s: [3.18, 9.44, 1.18, 5.02, 4.71, 4.05, 5.03] },
    'kgk-t5-tsrs-g1-kolay/kp-01':   { d: 'kgk-t5-tsrs-g1-kolay__kp-01', n: 7, b: [0, 1, 2, 3, 4, 5, 6], s: [3.44, 8.8, 5.97, 5.92, 16.47, 2.91, 10.92] },
    'kgk-d1b-tds-kolay-2/kp-07':    { d: 'kgk-d1b-tds-kolay-2__kp-07', n: 7, b: [0, 1, 2, 3, 4, 5, 6], s: [4.11, 8.29, 1.26, 3.91, 3.57, 3.25, 4.31] },
    'kgk-t7-tms-g2-kolay/kp-04':    { d: 'kgk-t7-tms-g2-kolay__kp-04', n: 7, b: [0, 1, 2, 3, 4, 5, 6], s: [4.27, 8.5, 1.3, 13.76, 15.49, 11.85, 12.74] },
    'kgk-t4-tms-g2-kolay/kp-03':    { d: 'kgk-t4-tms-g2-kolay__kp-03', n: 9, b: [0, 1, 2, 3, 4, 5, 6, 7, 8], s: [2, 7.3, 9.03, 3.64, 1.22, 2.96, 3.41, 2.83, 3.6] },
    'kgk-t5-fy-g3-kolay/kp-04':     { d: 'kgk-t5-fy-g3-kolay__kp-04', n: 9, b: [0, 1, 2, 3, 4, 5, 6, 7, 8], s: [2.14, 4.08, 3.72, 6.51, 1.11, 3.58, 2.64, 2.25, 2.81] },
    'kgk-t4-banka-g1-kolay/kp-01':  { d: 'kgk-t4-banka-g1-kolay__kp-01', n: 8, b: [0, 1, 2, 3, 4, 5, 6, 7], s: [2.29, 6.91, 9.28, 1.32, 3.78, 3.44, 3.89, 3.61] }
  };
  Object.keys(SES_KASA).forEach(function (id) { SES_KASA[id].kasa = MUT !== 'seskasaacik'; });
  function sesKaydi(id) { return SES[id] || SES_KASA[id] || null; }
  /* g. cümlenin (0'dan) ses adresi. Kasa kaydı: YALNIZ imzalı adres (u[g]); yoksa null = sessiz. Herkese açık yola ASLA düşmez. */
  function sesKaynak(e, g, kok) {
    if (!e) return null;
    if (e.kasa) return (e.u && e.u[g]) || null;
    return (kok || '') + 'ses/cizim/' + e.d + '/r' + (g + 1) + '.mp3';
  }
  function kasaYollari(e) { return e.b.map(function (x, i) { return e.d + '/r' + (i + 1) + '.mp3'; }); }

  // ---------------- saf işlevler (node'da sınanır) ----------------
  var SAYI = /%?\d+(?:[.,]\d+)*%?/g;
  function sayilar(t) { return (String(t || '').match(SAYI) || []).map(function (x) { return x.replace(/[.,]$/, ''); }); }
  function kacis(t) { return t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }
  function kaynaktaVar(sayi, kaynak) {
    var cplak = sayi.replace(/%/g, '');
    var re = new RegExp('(^|[^\\d.,])%?' + kacis(cplak) + '(?![\\d]|[.,]\\d)');
    return re.test(kaynak);
  }
  function ilkCumle(t, tavan) {
    t = String(t || '').replace(/\s+/g, ' ').trim(); if (!t) return '';
    var m = t.match(/^.+?[.!?](?=\s+[A-ZÇĞİÖŞÜ0-9(]|$)/); var c = m ? m[0] : t;
    if (/\?$/.test(c)) return '';   /* "257 … nedir?" ile başlayan anlatım o adımın hesabını değil hesabın tanımını anlatıyor: alt yazı yok */
    tavan = tavan || 170;
    if (c.length > tavan) { var k = c.lastIndexOf(',', tavan - 10); if (k < 60) k = c.lastIndexOf(' ', tavan - 10); c = c.slice(0, k) + '…'; }
    return c;
  }
  var EK = /\s*\((?:soruda verilen[^)]*|\d+\. adımda bulduk[^)]*|bulduk[^)]*)\)/gi, EK2 = /\s*=\s*\d+\. adımda bulduk/gi;
  function sadele(f) {
    var t = String(f || '').replace(EK, '').replace(EK2, '').replace(/\s+/g, ' ').trim();
    var p = t.split(' = ');
    if (p.length >= 3) {   /* "Ad = Anapara × Oran × Vade / 12 = 90.000 × %20 × 9 / 12 = 13.500" -> sayısal işlemi olmayan ara parça düşer */
      var ic = p.slice(1, -1).filter(function (x) { return /\d[^=]*?[×x*\/÷+\-−][^=]*?\d/.test(x); });
      p = [p[0]].concat(ic, [p[p.length - 1]]);
    }
    /* art arda aynı parça tek yazılır ("56.000 = 56.000 ₺") */
    var o = []; p.forEach(function (x) { var n = x.replace(/₺|TL/g, '').trim(); if (!o.length || o[o.length - 1].replace(/₺|TL/g, '').trim() !== n) o.push(x); else if (x.length > o[o.length - 1].length) o[o.length - 1] = x; });
    return o.join(' = ');
  }
  /* Yevmiye özeti ("770 … (BORÇ) 56.000; 257 … (ALACAK) 56.000") karalamada satır satır yazılır */
  /* "Oran: 125.000 / 600.000 = %20,83; Pay: 47.400 × %20,83 = 9.875" -> her önerme ayrı satır, ayrı sadeleşir */
  function satirla(f) {
    var ham = String(f || '').replace(EK, '').replace(EK2, '');
    var yev = /\((BORÇ|ALACAK)\)/i.test(ham);
    return ham.split(/;\s+/).map(function (x) { var t = sadele(x); return yev ? t.replace(/\s*=.*$/, '').trim() : t; }).filter(Boolean);   /* yevmiye: "381 … (BORÇ) 6.000 = 6.000" -> tutar bir kez */
  }
  /* Çözüm adımı sayılır mı: rakamlı ve ya "=" sonrasında sayı var ya "Dahil değil" satırı ya da yevmiye satırı.
     "257 Birikmiş Amortismanlar nedir?" gibi tanım adımları (rakamı yalnız hesap kodu) karalamaya yazılmaz. */
  function cozumAdimi(f) {
    f = String(f || ''); if (!/\d/.test(f)) return false;
    if (/^\s*Dahil değil/i.test(f)) return true;
    if (/\((BORÇ|ALACAK)\)\s*[\d.,]+/i.test(f) && f.indexOf(';') > 0) return true;   /* tek satırlık "770 … (BORÇ) 180.000" yarım kayıt yazılmaz */
    return satirla(f).some(function (t) { var i = t.indexOf('='); return i > 0 && /\d/.test(t.slice(i + 1)); });
  }
  /* Çeldirici yolu: baştaki işlem kısmı şık notu, kalanı neden ("60.000-20.000=40.000 (gider tarafı atlandı)") */
  function celdiriciBol(y) {
    y = String(y || '').replace(/\s+/g, ' ').trim(); if (!y) return { not: '', neden: '' };
    var m = y.match(/^[\d\s.,%+\-−–×x*·\/÷=();]+/); var not = m ? m[0] : '', neden = y.slice(not.length);
    var acik = (not.match(/\(/g) || []).length - (not.match(/\)/g) || []).length;
    if (acik > 0) { var k = not.lastIndexOf('('); neden = not.slice(k + 1) + neden; not = not.slice(0, k); }
    not = not.replace(/[\s(;=,]+$/, '').trim();
    if (!/\d/.test(not) || not.indexOf('=') < 0 || not.length > 60 || !/[+\-−–×x*·\/÷]/.test(not.split('=')[0])) {   /* işlemsiz ya da uzun yol not olmaz */
      not = ''; neden = y;
      var sp = y.match(/\(([^()]*[a-zçğıöşü]{3}[^()]*)\)\s*$/i);   /* "… = 137.892 (kesintiye uğramış kirayı beyan dışı bıraktı)" -> yalnız neden */
      if (sp && /\d/.test(y.slice(0, y.length - sp[0].length))) neden = sp[1];
    }
    neden = neden.replace(/^[\s(—–\-:,]+/, '').replace(/^(TL|₺)(\/[a-zçğıöşü]+)?\s*[;,]?\s*/i, '');   /* "43,05 TL/saat; bu oranla…" -> birim nedene geçmez */
    var kap = neden.indexOf(')'), ac2 = neden.indexOf('(');
    if (kap >= 0 && (ac2 < 0 || ac2 > kap)) {   /* "(ya da 12.000 x %20) — boş kapasite…" -> ara formül düşer */
      var on = neden.slice(0, kap);
      neden = (/\d/.test(on) && on.replace(/ya da/i, '').replace(/[\d\s.,%x×+\-=/]/g, '').length < 3) ? neden.slice(kap + 1) : on + neden.slice(kap + 1);
    }
    neden = neden.replace(/^[\s(—–\-:,]+/, '').replace(/\s+$/, '').trim();
    var fark = (neden.match(/\(/g) || []).length - (neden.match(/\)/g) || []).length;
    if (fark > 0) neden += ')'.repeat(fark); else if (fark < 0 && /\)$/.test(neden)) neden = neden.replace(/\)+$/, function (z) { return z.slice(0, Math.max(0, z.length + fark)); });
    return { not: not, neden: ilkCumle(neden, 150) };
  }
  var ATLA = /^\s*(Verilen|Soruda ne var|Soru bize|Yanlış yol|Ters durum|Senin seçimin|Takıldığın yer|Konu:|En sık hata)/i;   /* hata yolu karalamaya "çözüm" diye yazılmaz */
  function sayiDeger(t) {   // Türkçe yazım: nokta binlik, virgül ondalık; %30 -> 0,30
    var yuz = /%/.test(t); t = t.replace(/%/g, '');
    var v = /^\d{1,3}(\.\d{3})+(,\d+)?$/.test(t) ? t.replace(/\./g, '').replace(',', '.') : t.replace(',', '.');
    var n = parseFloat(v); if (isNaN(n)) return null; return yuz ? n / 100 : n;
  }
  // "a op b ... = c" parçalarını hesaplar; yalnız tamamen sayısal parçalar (₺/TL/✓ ve sondaki parantez silinir)
  function hesapla(ifade) {
    var s = ifade.replace(/[×x*·]/g, '*').replace(/[÷:]/g, '/').replace(/[−–]/g, '-').replace(/\s+/g, '');
    if (!/^[\d.,%+\-*/()]+$/.test(s)) return null;
    var tok = s.match(/%?\d+(?:[.,]\d+)*%?|[+\-*/()]/g); if (!tok || tok.join('') !== s) return null;
    var i = 0;
    function deger() { var t = tok[i]; if (t === '(') { i++; var v = topla(); if (tok[i] !== ')') throw 0; i++; return v; } if (t === '-') { i++; return -deger(); } i++; var n = sayiDeger(t); if (n === null) throw 0; return n; }
    function carp() { var v = deger(); while (tok[i] === '*' || tok[i] === '/') { var o = tok[i++]; var r = deger(); v = o === '*' ? v * r : v / r; } return v; }
    function topla() { var v = carp(); while (tok[i] === '+' || tok[i] === '-') { var o = tok[i++]; var r = carp(); v = o === '+' ? v + r : v - r; } return v; }
    try { var v = topla(); return i === tok.length ? v : null; } catch (e) { return null; }
  }
  /* "=" ile ayrılan her komşu parça çifti: soldakinin SONUNDAKİ sayısal ifade ile sağdakinin BAŞINDAKİ sayısal ifade
     ("Oran: 125.000 / 600.000 = %20,83" -> 125.000 / 600.000 ile %20,83). Birimli ifade ("5 kilogram × 18 ₺/kilogram")
     sayısal değildir, hesaplanmaz (GÖRMEZ). */
  var SAYISAL = '[\\d\\s.,%+\\-−–×*·\\/÷()]';
  var XCARP = '(?:(?<=[\\d\\s)%])x(?=[\\s\\d(%]))';
  /* Parçanın ucundaki sayısal ifade. İfade bir işlecin ortasından kesiliyorsa ("Tutar × (1 + %18)") yarımdır: '' döner. */
  function uc(x, son) {
    var m = x.match(new RegExp(son ? '(?:' + SAYISAL + '|' + XCARP + ')+$' : '^(?:' + SAYISAL + '|' + XCARP + ')+')); if (!m) return '';
    var t = m[0], kalan = son ? x.slice(0, x.length - t.length) : x.slice(t.length); t = t.trim();
    if (son ? /[×x*·\/÷+\-−–(]\s*$/.test(kalan) || /^[×x*·\/÷+)]/.test(t) : /^\s*[×x*·\/÷+\-−–]/.test(kalan) || /[×x*·\/÷+\-−–(]$/.test(t)) return '';
    if ((t.match(/\(/g) || []).length !== (t.match(/\)/g) || []).length) return '';
    return t;
  }
  function aritmetikHatasi(satir) {
    var t = String(satir || '').replace(/₺|TL|✓|\btl\b/g, '').replace(/\([^()]*\)/g, function (z) { return /[A-Za-zÇĞİÖŞÜçğıöşü]/.test(z.replace(new RegExp(XCARP, 'g'), '*')) ? '' : z; });   // sözel parantez ("(yön hatası)") düşer, "(500 x 25 = 12.500)" kalır
    /* iç eşitlik "(500 x 25 = 12.500)" önce kendi başına denetlenir, sonra yerine sonucu konur */
    for (var g = 0, ic; g < 5 && (ic = t.match(/\(([^()=]*)=([^()=]*)\)/)); g++) { var h0 = aritmetikHatasi(ic[1] + '=' + ic[2]); if (h0) return h0; t = t.replace(ic[0], '(' + ic[2].trim() + ')'); }
    var p = t.split('=').map(function (x) { return x.trim(); });
    for (var k = 0; k + 1 < p.length; k++) {
      var sol = uc(p[k], true), sag = uc(p[k + 1], false);
      var a = hesapla(sol), b = hesapla(sag);
      if (a === null || b === null) continue;
      if (MUT !== 'hesapkodu' && /^\s*[1-9]\d\d(\s*[+\-−]\s*[1-9]\d\d)+\s*$/.test(sol)) continue;   // "151 + 152 + 620 = 60.000 + …" hesap kodu dizisi, işlem değil
      if (!/[+\-−*×x·/÷]/.test(sol.replace(/^-/, '')) && !/[+\-−*×x·/÷]/.test(sag.replace(/^-/, ''))) continue;   // "a = b" düz eşitlik: işlem yok
      var tol = Math.max(1, Math.abs(b) * 0.005); if (Math.abs(b) < 1 && Math.abs(a) < 1) tol = 0.005;
      if (MUT === 'aritmetik') tol = Infinity;
      if (Math.abs(a - b) > tol) return p[k] + ' = ' + p[k + 1] + ' (hesap ' + (Math.round(a * 1000) / 1000) + ')';
    }
    return '';
  }

  /* Alt yazı adayının sayıları kaynakta yoksa o adımda alt yazı YAZILMAZ (anlatim alanı bazen formülde olmayan hesap
     kodu / yıl anar; doğrulanamayan rakam ekrana çıkmasın). Karalama satırı ve şık notu için böyle bir kaçış yok: kapı döndürür. */
  function guvenliAlt(t, kay) {
    if (!t) return '';
    var ok = sayilar(t).every(function (n) { return kaynaktaVar(n, kay); });
    return (ok || MUT === 'altyazi') ? t : '';
  }
  function senaryo(s) {
    var adimlar = (s && s.adimlar) || [], kay = kaynakMetni(s || {});
    var verilen = adimlar.filter(function (a) { return a && (a.verilenAdim || /^\s*(Verilen|Soruda ne var|Soru bize)/i.test(a.formul || '')); })[0];
    var cozum = adimlar.filter(function (a) { return a && !a.verilenAdim && !a.kisi && !a.giris && !a.sik && !ATLA.test(a.formul || '') && cozumAdimi(a.formul); });
    var sahne = [];
    // 0) soruda verilenlerin altını çiz
    var vs = sayilar(verilen ? verilen.formul : cozum.map(function (a) { return a.formul; }).join(' '));
    var cizgi = []; vs.forEach(function (x) { if (cizgi.indexOf(x) < 0 && kaynaktaVar(x, s.soru || '')) cizgi.push(x); });
    sahne.push({ tur: 'alti', hedef: cizgi.slice(0, 8), alt: verilen ? guvenliAlt(ilkCumle(verilen.anlatim), kay) : '' });
    // 1..n) çözüm adımları karalamaya
    cozum.forEach(function (a) { sahne.push({ tur: 'yaz', satirlar: satirla(a.formul), alt: guvenliAlt(ilkCumle(a.anlatim), kay), son: false }); });
    var dn0 = sayilar((s.siklar || {})[s.dogru])[0];   /* yeşil satır: doğru şıkkın sayısını yazan SON adım */
    var sonSayi = function (x) { var n = sayilar(x); return !/^\s*Sağlama/i.test(x) && n.length && n[n.length - 1] === dn0; };   /* önce sonucu doğru şıkla BİTEN adım (sağlama satırı değil) */
    for (var z = sahne.length - 1; z > 0 && dn0; z--) if (sahne[z].satirlar.some(sonSayi)) { sahne[z].son = true; dn0 = ''; }
    for (z = sahne.length - 1; z > 0 && dn0; z--) if (sahne[z].satirlar.some(function (x) { return kaynaktaVar(dn0, x); })) { sahne[z].son = true; dn0 = ''; }
    // n+1) doğru şık
    var d = s.dogru; sahne.push({ tur: 'daire', harf: d, alt: '' });
    // n+2..) yanlış şıklar
    var cy = s.celdiriciYol || {}, th = s.teshis || {};
    Object.keys(s.siklar || {}).sort().forEach(function (h) {
      if (h === d) return;
      var cb = celdiriciBol(cy[h]), not = cb.not, neden = cb.neden;
      if (!neden && th[h] && th[h].yanilgi) neden = ilkCumle(th[h].yanilgi, 150);
      sahne.push({ tur: 'karala', harf: h, not: not, alt: guvenliAlt(neden ? (h + ': ' + (/^.[a-zçğıöşü]/.test(neden) ? neden.charAt(0).toLocaleLowerCase('tr') : neden.charAt(0)) + neden.slice(1)) : '', kay) });
    });
    return { sahne: sahne, cozumSay: cozum.length };
  }

  function kaynakMetni(s) {
    var p = [s.soru || ''];
    Object.keys(s.siklar || {}).forEach(function (h) { p.push(s.siklar[h]); });
    (s.adimlar || []).forEach(function (a) { p.push(a && a.formul || ''); });
    var cy = s.celdiriciYol || {}; Object.keys(cy).forEach(function (h) { p.push(cy[h]); });
    return p.join(' \n ');
  }
  function yazilanlar(sen) {   // ekranda yazıyla çıkan her metin (karalama, not, alt yazı)
    var o = [];
    sen.sahne.forEach(function (a) { (a.satirlar || []).forEach(function (x) { o.push(['karalama', x]); }); if (a.not) o.push(['not ' + a.harf, a.not]); if (a.alt) o.push(['alt yazı', a.alt]); });
    return o;
  }

  /* sen verilirse o senaryo denetlenir (öz-sınav dizici hatasını böyle benzetir); verilmezse sorudan kurulur */
  function cizerekKapi(s, sen) {
    var neden = [];
    if (!s || !s.siklar || !s.dogru || !s.siklar[s.dogru] || !Array.isArray(s.adimlar)) return { gecer: false, neden: ['VERI: şık / doğru / adım alanı eksik'] };
    sen = sen || senaryo(s);
    if (sen.cozumSay < 2 && MUT !== 'sozel') neden.push('SOZEL: sayılı çözüm adımı ' + sen.cozumSay);
    var kay = kaynakMetni(s);
    yazilanlar(sen).forEach(function (y) {
      sayilar(y[1]).forEach(function (n) { if (MUT !== 'rakam' && !kaynaktaVar(n, kay)) neden.push('RAKAM: ' + y[0] + ' "' + n + '" kaynakta yok'); });
      if (y[0] !== 'alt yazı') { var h = aritmetikHatasi(y[1]); if (h) neden.push('ARITMETIK: ' + y[0] + ' ' + h); }
    });
    var dn = sayilar(s.siklar[s.dogru]);
    var satir = sen.sahne.filter(function (a) { return a.tur === 'yaz'; }).map(function (a) { return a.satirlar.join(' \n '); }).join(' \n ');
    if (MUT !== 'dogru') {
      if (!dn.length) neden.push('DOGRU: doğru şıkta sayı yok');
      else if (!kaynaktaVar(dn[0], satir)) neden.push('DOGRU: doğru şık ' + s.dogru + ' (' + dn[0] + ') karalamada yazılmıyor');
    }
    return { gecer: neden.length === 0, neden: neden, senaryo: sen };
  }

  /* ---------------- SÖZEL ŞABLON (20.10.2026, Cem "1.2.3") ----------------
     Rakamsız soruda kalem: kökte sorulan ifadenin altı çizilir → karalamaya kural yazılır → doğru şık yuvarlanır → yanlış şıklar
     tuzak adıyla karalanır. İki biçim:
       ONCUL — kökte "I. … II. …" öncülleri; adımlarda "I: …" satırları + "Sonuç = <doğru şık metni>". Her öncül satırına ✓/✗:
               öncül adımının anlatımı kökte sorulan sıfatı ("etkisiz", "yanlış"…) taşıyorsa ✓.
       DUZ   — karalamaya hap (tek cümlelik kural) yazılır; doğru şıkkın metni hapta aynen geçmeli.
     Yazılan her şey sorunun kendi alanlarından (adimlar.formul/anlatim, hap, taktik, tuzak, teshis); bilgi ÜRETMEZ.
     SÖZEL KAPI (sozelKapi) — biri tutmazsa çizim YOK:
       SZ-SONUC  ONCUL: sonuç satırı doğru şıkkın metniyle birebir değil
       SZ-ONCUL  ONCUL: ✓ konan öncüller doğru şıktaki öncüllerle aynı küme değil / kökteki bir öncülün satırı yok
       SZ-DOGRU  DUZ: doğru şıkkın metni karalamada geçmiyor
       SZ-CIFT   DUZ: başka bir şıkkın metni de karalamada geçiyor (kalem iki şıkkı birden doğrular)
       SZ-RAKAM  karalama/not/alt yazıda soru ve şıklarda olmayan bir sayı var
       SZ-NEDEN  bir yanlış şıkkın yazılı nedeni (tuzak.metin / teshis.yanilgi) yok
       SZ-ALT    altı çizilecek ifade kökte aynen bulunamadı
       SZ-YOK    hiçbir biçime uymuyor
     🚫 GÖRMEZ: hap ya da tuzak metninin HUKUKEN doğru olup olmadığı (sorunun açıklama katmanından aynen gelir; açıklama hakemi ayrı)
       · öncül anlatımının sorulan sıfatı tesadüfen taşıması (kapı yalnız ✓ kümesinin doğru şıkla tutmasına bakar) · DUZ'da hapın
       doğru şıkkı başka bir bağlamda anması · uzun hapın telefonda kaç satır tuttuğu. Sayılı soru bu şablonla KURTARILMAZ
       (cizimKapi sözel şablonu yalnız sayısal kapı SOZEL nedeniyle döndüyse dener).

     KGK EKİ (22.10.2026, KGK'da düğme): KGK sözel sorusu SGS biçimine uymuyor — öncül hükmü "I: …" satırında değil, "Bu olayda: I doğru
     · IV yanlış" satırında ya da tuzak/teşhis metninde ("III de doğrudur") yazılı; öncülsüz soruda doğru şık uzun bir cümle, hapta aynen
     geçemez. İki biçim daha (biçimler sırayla denenir, ilk geçen çizilir):
       HUKUM — öncüllü soru, "I:" satırı yok. Her öncülün hükmü (doğru/yanlış) adimlar.formul/anlatim + tuzak.metin + teshis.gercek
               cümlelerinden okunur ("I, II ve III doğru", "IV yanlış", "III de doğrudur", "doğru değildir" = yanlış; "doğru sandın",
               "doğru şık/cevap" hüküm SAYILMAZ). Kök olumsuzsa (yanlış/değildir/söylenemez…) ✓ = yanlış öncüller, değilse doğru öncüller.
               Karalama: her öncül "I → doğru ✓" + gerekçe cümlesi (alt yazı), sonra "Sonuç = <öncül kararlarından kurulan küme>".
       SIK   — öncülsüz, kökü "hangisi doğrudur/yanlıştır/söylenemez…" (ifade sorusu). Karalamaya kural (hap, yoksa doğru şıkkın
               teshis.gercek'i), doğru şık yuvarlanır, öteki şıklar tuzak adı + nedeniyle karalanır. Hangi şıkkın doğru olduğunu
               s.dogru söyler (sitedeki "Beş şık, beş cümle" paneliyle AYNI kaynak); kapı yalnız çelişkiyi arar.
       DUZ'a ek: kural cümlesi yalnız haptan değil, doğru şıkkı aynen anan ilk cümleden (hap · kural · adimlar · teshis[doğru].gercek).
     Ek kodlar:
       SZ-HUKUM    HUKUM: kökteki bir öncülün hükmü alanlarda yok ya da aynı öncüle hem doğru hem yanlış deniyor
       SZ-CELISKI  SIK: bir şıkkın tuzak adı/metni ("Doğru ifade", "bu ifade yanlıştır") s.dogru'dan çıkan durumla çelişiyor
       SZ-RAKAM kaynağı: soru + şıklar + dayanak (resmî metin alıntısı). Açıklama katmanındaki "İlke 1.3.8" dayanakta yoksa o cümle yazılmaz.
     🚫 GÖRMEZ (KGK eki): SIK'ta kuralın doğru şıkkı gerçekten açıklayıp açıklamadığı (anlam) · HUKUM'da cümledeki hükmün başka bir
       öncül listesine ait olması ("I ve II doğru olsa da…" gibi şartlı cümle) · Romen rakamı dışında öncül numarası (a, b, 1., 2.). */
  var ROMA = /^(I{1,3}|IV|V|VI{0,3})$/;
  function trKucuk(t) { return String(t || '').toLocaleLowerCase('tr').replace(/\s+/g, ' ').trim(); }
  function oncullerSik(t) {   // "Yalnız I" / "I ve III" / "I, II ve III" -> ['I','III']; öncül şıkkı değilse null
    var p = String(t || '').replace(/^\s*Yalnız\s+/i, '').split(/\s*(?:,|\bve\b)\s*/).map(function (x) { return x.trim(); }).filter(Boolean);
    return p.length && p.every(function (x) { return ROMA.test(x); }) ? p : null;
  }
  var SORULAN = /(etkisiz kal[a-zçğıöşü]*|etkisizdir|etkilidir|yanlıştır|yanlış[a-zçğıöşü]*|doğrudur|doğru[a-zçğıöşü]*|geçersiz[a-zçğıöşü]*|geçerli[a-zçğıöşü]*|söylenemez|söylenebilir|değildir|vardır|yoktur)/i;
  function ortakIfade(kok, hap) {   // hapın kökte aynen geçen en uzun 2+ kelimelik parçaları (en çok 2, örtüşmesiz)
    var w = String(hap || '').replace(/[.,;:()"]/g, ' ').split(/\s+/).filter(Boolean), bul = [], dolu = {};
    for (var n = Math.min(6, w.length); n >= 2; n--) for (var i = 0; i + n <= w.length; i++) {
      var p = w.slice(i, i + n).join(' '); if (p.length < 10 || kok.indexOf(p) < 0) continue;
      var ort = false; for (var u = i; u < i + n; u++) if (dolu[u]) ort = true;
      if (ort || bul.some(function (b) { return b.indexOf(p) >= 0 || p.indexOf(b) >= 0; })) continue;   /* aynı kelimeler iki kez çizilmez */
      for (u = i; u < i + n; u++) dolu[u] = 1;
      bul.push(p); if (bul.length >= 2) return bul;
    }
    return bul;
  }
  function yanlisNeden(s, h) {
    var t = (s.tuzak || {})[h], th = (s.teshis || {})[h];
    return ilkCumle((t && t.metin) || (th && th.yanilgi) || '', 160);
  }
  /* kökün soru cümlesi: "?" ile biten son satır (KGK'da öncüller sorunun ALTINDA), yoksa son satır */
  function kokCumle(soru) {
    var L = String(soru || '').split('\n').filter(function (x) { return x.trim(); });
    var q = MUT === 'szkok' ? [] : L.filter(function (x) { return /\?\s*$/.test(x); });
    return q.length ? q[q.length - 1] : (L[L.length - 1] || '');
  }
  function kokOnculleri(soru) { return (String(soru || '').match(/(^|\n)\s*(IV|V|I{1,3})\.\s/g) || []).map(function (x) { return x.replace(/[\s.\n]/g, ''); }); }
  /* kelime sonu şartı: "yanlışlık riski", "aykırılık göstergesi", "doğrulama prosedürü" kutup/ifade sözcüğü DEĞİL */
  /* 27.10: JS /i büyük İ'yi i saymaz → "DEĞİLDİR" (gerçek kitapçık biçimi) olumlu okunuyordu; çağıranlar İ→i yapar */
  var OLUMSUZ = /(yanlış(tır)?|yanlış olan|değildir|söylenemez|olamaz|aykırıdır|uygun değildir)(?![a-zçğıöşü])/i, IFADE = /(doğru(dur)?|yanlış(tır)?|söylenebilir|söylenemez|ifade[a-zçğıöşü]*)(?![a-zçğıöşü])/i;
  var HARF = 'A-Za-zÇĞİÖŞÜçğıöşü\'’', ROM = '(?:IV|V|I{1,3})';
  /* "I, II ve III doğru" · "IV yanlış" · "III de doğrudur" · "II. öncül yanlıştır" · "IV. ifade yanlıştır" · "I doğru değildir" (= yanlış).
     "doğru sandın/sanılır", "yanlış saydın", "doğru şık/cevap/olan" hüküm değildir. m[2] öncül listesi, m[3] hüküm, m[5] "değil". */
  var HUKUM = new RegExp('(^|[^' + HARF + '])(' + ROM + '(?:\\s*(?:,|\\bve\\b|\\bile\\b)\\s*' + ROM + ')*)(?![' + HARF + '])(?:\\.?\\s*(?:öncül|ifade)[a-zçğıöşü]*)?(?:\\s+(?:de|da|ise))?\\s*(?:[:→=\\-–—]+\\s*)?(doğru|yanlış|DOĞRU|YANLIŞ)([a-zçğıöşü]*)' + (MUT === 'szsan' ? '' : '(?!\\s+(?:san|say|kabul|zan|şık|cevap|seçenek|küme|olan))') + '(\\s+değil)?', 'g');
  function cumleler(t) { return String(t || '').replace(/\s+/g, ' ').trim().split(/(?<=[.!?])\s+(?=[A-ZÇĞİÖŞÜ(“"])/).filter(Boolean); }
  /* öncül -> { dogru:1 | yanlis:1 } ve gerekçe cümleleri. Kaynak sırası gerekçe önceliğidir: tuzak · teşhis · adımlar */
  function hukumTopla(s) {
    var kay = [], tz = s.tuzak || {}, th = s.teshis || {}, hk = {}, ger = {};
    Object.keys(tz).sort().forEach(function (h) { kay.push(tz[h] && tz[h].metin); });
    Object.keys(th).sort().forEach(function (h) { kay.push(th[h] && th[h].gercek); });
    /* "Yanlış yol: … IV de doğru sayılır → (HATALI)" hata yolunu anlatır, hüküm değildir */
    (s.adimlar || []).forEach(function (a) { if (a && !a.verilenAdim && (MUT === 'szyol' || !ATLA.test(a.formul || '') && !/HATALI/.test(a.formul || ''))) kay.push(a.formul, a.anlatim); });
    kay.forEach(function (t) {
      var cs = cumleler(t);
      cs.forEach(function (c, i) {
        HUKUM.lastIndex = 0; var m, ms = [];
        while ((m = HUKUM.exec(c))) ms.push(m);
        ms.forEach(function (m) {
          var v = /^d/i.test(m[3]) ? 'dogru' : 'yanlis'; if (m[5] && MUT !== 'szdegil') v = v === 'dogru' ? 'yanlis' : 'dogru';
          /* gerekçe yalnız TEK öncülü hükümleyen cümleden ("Bu olayda: I doğru; II yanlış…" her öncülde tekrar olmasın);
             "I de doğrudur." gibi çıplak hükümde nedeni taşıyan bir sonraki cümle eklenir */
          var g = '';
          if (ms.length === 1 && m[2].indexOf(' ') < 0) {
            var cip = c.replace(HUKUM, ' ').replace(/[\s.;:,]+/g, ' ').trim();
            if (cip.length >= 25) g = c; else if (cs[i + 1] && !new RegExp(HUKUM.source).test(cs[i + 1]) && !/^Doğru(su| cevap)/i.test(cs[i + 1])) g = c + ' ' + cs[i + 1];
          }
          m[2].split(/\s*(?:,|\bve\b|\bile\b)\s*/).forEach(function (o) { o = o.trim(); if (!o) return; (hk[o] = hk[o] || {})[v] = 1; if (g) (ger[o] = ger[o] || []).push(g); });
        });
      });
    });
    return { hk: hk, ger: ger };
  }
  function kisalt(t, tavan) {   /* ilkCumle'nin kısaltması, ilk cümlede kesmeden (iki cümlelik gerekçe için) */
    t = String(t || '').replace(/\s+/g, ' ').trim(); if (t.length <= tavan) return t;
    var k = t.lastIndexOf(',', tavan - 10); if (k < 60) k = t.lastIndexOf(' ', tavan - 10); return t.slice(0, k) + '…';
  }
  /* şık metni karalamada geçiyor mu: sayı şıkkı ("%20", "10,10") sayı sınırıyla (%20 ≠ %200), öteki şık 4+ harfle, büyük/küçük harf duyarsız */
  function sikGecer(sik, metin) {
    var t = String(sik || '').trim(), n = sayilar(t);
    if (n.length === 1 && n[0].replace(/%/g, '') === t.replace(/[%\s₺]|TL/g, '')) return kaynaktaVar(n[0], String(metin || '')) && (!/%/.test(t) || String(metin).indexOf('%' + n[0].replace(/%/g, '')) >= 0);
    return trKucuk(t).length > 3 && trKucuk(metin).indexOf(trKucuk(t)) >= 0;
  }
  function kaySozel(s) { return [s.soru || ''].concat(Object.keys(s.siklar || {}).map(function (h) { return s.siklar[h]; }), [s.dayanak || '']).join(' \n '); }
  function kumeYaz(L, ornek) { return L.length === 1 ? (/^\s*Yalnız/i.test(ornek) ? 'Yalnız ' : '') + L[0] : L.slice(0, -1).join(', ') + ' ve ' + L[L.length - 1]; }
  /* altı çizilecek öbek YALNIZ soru cümlesinden ("…'a göre aşağıdakilerden hangisi doğrudur?"): senaryodaki "yanlışlık riski",
     "KAYİK değildir" çizilmez. "hangisi doğrudur" / "hangileri yanlıştır" / yalnız "hangisidir" ise önündeki konu kelimesiyle. */
  /* kökün SON cümlesi (senaryodaki "… halka açık değildir." kökü olumsuz yapmasın) */
  function soruCumlesi(kok) { var q = String(kok || '').replace(/\?\s*$/, ''), p = q.split(/[.;:!]\s+/); return MUT === 'szkok' ? String(kok || '') : p[p.length - 1]; }
  function sorulanIfade(kok) {
    var q = soruCumlesi(kok);
    var m = q.match(/hangi[a-zçğıöşü]*((?:\s+[^\s?,]+){0,4})\s*$/i);
    if (!m) {
      var o = q.match(/hangi[a-zçğıöşü]*(?:\s+[^\s?,]+){0,2}/i); if (o) return o[0].trim();   /* "hangisi, … örnektir?" */
      var son = q.match(/(?:[A-Za-zÇĞİÖŞÜçğıöşü'’]+\s+){0,2}[A-Za-zÇĞİÖŞÜçğıöşü'’]+\s*$/);   /* "denetçi ne yapar?" / "nasıl ifade edilir?" */
      return son ? son[0].trim() : '';
    }
    if (m[1].trim()) return m[0].trim();
    var w = q.slice(0, m.index).trim().split(/\s+/), on = [];
    while (on.length < 2 && w.length && /^[A-Za-zÇĞİÖŞÜçğıöşü'’]+$/.test(w[w.length - 1])) on.unshift(w.pop());   /* bitişik kelimeler: çizgi kopmasın */
    return (on.length ? on.join(' ') + ' ' : '') + m[0].trim();
  }
  /* verilen adaylardan ilki: sayıları kaynakta olan, boş olmayan */
  function ilkGuvenli(L, kay, tavan) { for (var i = 0; i < L.length; i++) { var t = guvenliAlt(ilkCumle(L[i], tavan || 160), kay); if (t) return t; } return ''; }
  function sozelBicimler(s) {
    var dn = String((s.siklar || {})[s.dogru] || ''), adim = (s.adimlar || []).filter(function (a) { return a && a.formul; }), B = [];
    var oncul = oncullerSik(dn), kok = kokCumle(s.soru);
    if (oncul && adim.filter(function (a) { return /^\s*[IVX]+\s*:/.test(a.formul); }).length >= 2 && adim.some(function (a) { return /^\s*Sonuç\s*=/.test(a.formul); })) B.push('ONCUL');
    if (oncul && kokOnculleri(s.soru).length >= 2) B.push('HUKUM');
    if (!oncul && !OLUMSUZ.test(soruCumlesi(kok).replace(/İ/g, 'i'))) B.push('DUZ');   /* olumsuz kökte doğru şık YANLIŞ bir ifade: onu "kural" diye yazmak ters olur */
    if (!oncul && (IFADE.test(soruCumlesi(kok)) || OLUMSUZ.test(soruCumlesi(kok).replace(/İ/g, 'i')) || dn.length >= 40)) B.push('SIK');   /* uzun cümle şık hiçbir kural cümlesinde AYNEN geçemez · olumsuz kısa şıklı kök ("… hangisi … DEĞİLDİR?") DUZ alamaz, SIK ile çizilir (27.10) */
    return B;
  }
  function sozelSenaryo(s, bicim) {
    var soru = String(s.soru || ''), kok = kokCumle(soru), sahne = [];
    var dn = String((s.siklar || {})[s.dogru] || ''), adim = (s.adimlar || []).filter(function (a) { return a && a.formul; });
    var oncul = adim.filter(function (a) { return /^\s*[IVX]+\s*:/.test(a.formul); });
    var sonuc = adim.filter(function (a) { return /^\s*Sonuç\s*=/.test(a.formul); })[0];
    bicim = bicim || sozelBicimler(s)[0];
    if (!bicim || sozelBicimler(s).indexOf(bicim) < 0) return null;
    var kalip = s.taktik ? guvenliAlt(ilkCumle(s.taktik), kaynakMetni(s)) : '', kay = kaySozel(s), th = s.teshis || {};
    var yanlislar = function () {
      Object.keys(s.siklar || {}).sort().forEach(function (h) {
        if (h === s.dogru) return; var t = (s.tuzak || {})[h], ne = bicim === 'ONCUL' ? yanlisNeden(s, h) : ilkGuvenli([t && t.metin, th[h] && th[h].gercek, th[h] && th[h].yanilgi].filter(Boolean), kay);
        sahne.push({ tur: 'karala', harf: h, not: (t && t.ad) || '', alt: ne ? h + ': ' + ne : '' });
      });
    };
    if (bicim === 'HUKUM') {
      var neg = OLUMSUZ.test(soruCumlesi(kok).replace(/İ/g, 'i')), hb = hukumTopla(s), ko = kokOnculleri(soru), sec = [], eksik = [];
      var sor = sorulanIfade(kok);
      sahne.push({ tur: 'alti', hedef: sor && soru.indexOf(sor) >= 0 ? [sor] : [], alt: kalip, etiket: 'Soruda sorulan' });
      ko.forEach(function (o) {
        var h = hb.hk[o] || {}, v = h.dogru && h.yanlis ? '' : h.dogru ? 'dogru' : h.yanlis ? 'yanlis' : '';
        if (!v && MUT !== 'szhukum') { eksik.push(o + (h.dogru ? ' çelişkili hüküm' : ' hükmü yok')); return; }
        v = v || 'dogru';
        var evet = v === (neg ? 'yanlis' : 'dogru'); if (evet) sec.push(o);
        var G = (hb.ger[o] || []).map(function (g) { return guvenliAlt(kisalt(g, 190), kay); }).filter(Boolean);
        sahne.push({ tur: 'yaz', satirlar: [o + ' → ' + (v === 'dogru' ? 'doğru' : 'yanlış') + (evet ? ' ✓' : ' ✗')], alt: G[0] || '', son: false, oncul: o, evet: evet, etiket: o + '. öncül' });
      });
      sahne.push({ tur: 'yaz', satirlar: ['Sonuç = ' + (sec.length ? kumeYaz(sec, dn) : '—')], alt: '', son: true, etiket: 'Sonuç', kume: sec.slice() });
      sahne.push({ tur: 'daire', harf: s.dogru, alt: ilkGuvenli([s.hap || ''], kay, 170) });
      yanlislar();
      return { sahne: sahne, cozumSay: sahne.filter(function (a) { return a.tur === 'yaz'; }).length, bicim: bicim, eksik: eksik };
    }
    if (bicim === 'SIK') {
      var sor2 = sorulanIfade(kok);
      sahne.push({ tur: 'alti', hedef: sor2 && soru.indexOf(sor2) >= 0 ? [sor2] : [], alt: kalip, etiket: 'Soruda sorulan' });
      var kural = ilkGuvenli([s.hap || '', th[s.dogru] && th[s.dogru].gercek || ''].filter(Boolean), kay, 240);
      sahne.push({ tur: 'yaz', satirlar: [kural], alt: '', son: true, etiket: 'Kural' });
      sahne.push({ tur: 'daire', harf: s.dogru, alt: ilkGuvenli([th[s.dogru] && th[s.dogru].gercek || ''], kay, 170) });
      yanlislar();
      return { sahne: sahne, cozumSay: 1, bicim: bicim, olumsuz: OLUMSUZ.test(soruCumlesi(kok).replace(/İ/g, 'i')) };
    }
    if (bicim === 'ONCUL') {
      var sor = (kok.match(SORULAN) || [])[0] || '';
      var hedef = [sor].filter(function (x) { return x && soru.indexOf(x) >= 0; });
      sahne.push({ tur: 'alti', hedef: hedef, alt: kalip, etiket: 'Soruda sorulan' });
      var iz = trKucuk(sor).slice(0, 6);
      oncul.forEach(function (a) {
        var evet = !!iz && trKucuk(a.anlatim).indexOf(iz) >= 0;
        sahne.push({ tur: 'yaz', satirlar: [a.formul.replace(/\s+/g, ' ').trim() + (evet ? ' → ' + sor.split(' ')[0] + ' ✓' : ' ✗')], alt: ilkCumle(a.anlatim), son: false, oncul: a.formul.match(/^\s*([IVX]+)/)[1], evet: evet, etiket: a.formul.match(/^\s*([IVX]+)/)[1] + '. öncül' });
      });
      sahne.push({ tur: 'yaz', satirlar: [sonuc.formul.replace(/\s+/g, ' ').trim()], alt: ilkCumle(sonuc.anlatim), son: true, etiket: 'Sonuç' });
      sahne.push({ tur: 'daire', harf: s.dogru, alt: ilkCumle(s.hap || '') });
    } else {
      /* kural cümlesi: önce hapın ilk cümlesi (20.10 davranışı); doğru şıkkı anmıyorsa doğru şıkkı AYNEN anan, başka şıkkı anmayan,
         sayıları kaynakta olan ilk cümle (hap · kural · adımlar · teshis[doğru].gercek) — KGK eki 22.10 */
      var hap = ilkCumle(s.hap, 240), anar = function (c) { return sikGecer(dn, c) && !Object.keys(s.siklar).some(function (h) { return h !== s.dogru && sikGecer(s.siklar[h], c); }); };
      if (!anar(hap) && MUT !== 'szkural') {
        var aday = [].concat(cumleler(s.hap), cumleler(s.kural), [].concat.apply([], adim.filter(function (a) { return !a.verilenAdim; }).map(function (a) { return cumleler(a.formul).concat(cumleler(a.anlatim)); })), cumleler(th[s.dogru] && th[s.dogru].gercek));
        /* "Doğru şık: X" / "Doğru cevap: X" / "Sonuç = X" kuralı değil, cevabı tekrar eder: aday değil */
        /* "En sık hata: … (HATALI)" / "Yanlış yol: …" hata yolunu anlatır, kural değildir */
        for (var ai = 0; ai < aday.length; ai++) { var c = ilkCumle(aday[ai], 240); if (c && !/^\s*(Doğru (şık|cevap|seçenek)|Sonuç|Cevap)\b/i.test(c) && (MUT === 'szyol' || !ATLA.test(c) && !/HATALI/.test(c)) && anar(c) && guvenliAlt(c, kay)) { hap = c; break; } }
      }
      var oi = ortakIfade(kok, hap === ilkCumle(s.hap, 240) ? s.hap : hap), si = sorulanIfade(kok);
      sahne.push({ tur: 'alti', hedef: oi.length ? oi : (si && soru.indexOf(si) >= 0 ? [si] : []), alt: kalip, etiket: 'Soruda sorulan' });
      sahne.push({ tur: 'yaz', satirlar: [hap], alt: '', son: true, etiket: 'Kural' });
      sahne.push({ tur: 'daire', harf: s.dogru, alt: '' });
      yanlislar();
      return { sahne: sahne, cozumSay: 1, bicim: bicim };
    }
    Object.keys(s.siklar || {}).sort().forEach(function (h) {
      if (h === s.dogru) return; var t = (s.tuzak || {})[h], ne = yanlisNeden(s, h);
      sahne.push({ tur: 'karala', harf: h, not: (t && t.ad) || '', alt: ne ? h + ': ' + ne : '' });
    });
    return { sahne: sahne, cozumSay: sahne.filter(function (a) { return a.tur === 'yaz'; }).length, bicim: bicim };
  }
  /* biçimler sırayla denenir; ilk geçen döner. Hiçbiri geçmezse denenen her biçimin nedenleri (tekrarsız) */
  function sozelKapi(s, sen) {
    if (!s || !s.siklar || !s.dogru || !s.siklar[s.dogru]) return { gecer: false, neden: ['SZ-YOK: şık / doğru alanı eksik'] };
    if (sen) return sozelDenetle(s, sen);
    var B = sozelBicimler(s), ne = [];
    for (var i = 0; i < B.length; i++) { var se = sozelSenaryo(s, B[i]); if (!se) continue; var r = sozelDenetle(s, se); if (r.gecer) return r; r.neden.forEach(function (n) { if (ne.indexOf(n) < 0) ne.push(n); }); }
    return { gecer: false, neden: ne.length ? ne : ['SZ-YOK: öncül, hap ya da ifade biçimine uymuyor'] };
  }
  function sozelDenetle(s, sen) {
    var neden = [], dn = s.siklar[s.dogru], kay = kaySozel(s);
    var yaz = sen.sahne.filter(function (a) { return a.tur === 'yaz'; }), karalama = yaz.map(function (a) { return a.satirlar.join(' '); }).join(' \n ');
    if (sen.bicim === 'HUKUM') {
      (sen.eksik || []).forEach(function (e) { neden.push('SZ-HUKUM: ' + e); });
      var bek2 = (oncullerSik(dn) || []).slice().sort().join(','), son2 = yaz.filter(function (a) { return a.son; })[0];
      var kum = son2 ? (oncullerSik(son2.satirlar[0].split('=').pop().trim()) || []).slice().sort().join(',') : '';
      if (MUT !== 'szsonuc' && kum !== bek2) neden.push('SZ-SONUC: öncül kararlarından kurulan küme [' + kum + '] ≠ doğru şık [' + bek2 + ']');
      var isaret2 = yaz.filter(function (a) { return a.oncul && a.evet; }).map(function (a) { return a.oncul; }).sort().join(',');
      if (MUT !== 'szoncul' && isaret2 !== bek2) neden.push('SZ-ONCUL: ✓ konan [' + isaret2 + '] ≠ doğru şık [' + bek2 + ']');
      kokOnculleri(s.soru).forEach(function (o) { if (MUT !== 'szoncul' && !(sen.eksik || []).some(function (e) { return e.split(' ')[0] === o; }) && !yaz.some(function (a) { return a.oncul === o; })) neden.push('SZ-ONCUL: kökteki ' + o + '. öncülün satırı yok'); });
    } else if (sen.bicim === 'SIK') {
      if (!trKucuk(karalama)) neden.push('SZ-YOK: kural cümlesi yok (hap / teşhis boş ya da sayısı kaynakta yok)');
      Object.keys(s.siklar).forEach(function (h) { if (h !== s.dogru && MUT !== 'szcift' && sikGecer(s.siklar[h], karalama)) neden.push('SZ-CIFT: ' + h + ' şıkkı da karalamada geçiyor'); });
      /* çelişki: şıkkın kendi açıklaması "bu ifade doğrudur/yanlıştır" ya da tuzak adı "Doğru ifade/Yanlış ifade" diyorsa, s.dogru'dan
         çıkan durumla aynı olmalı (olumlu kökte doğru şık = doğru ifade, öteki = yanlış ifade; olumsuzda tersi) */
      Object.keys(s.siklar).forEach(function (h) {
        var t = (s.tuzak || {})[h] || {}, bek = (h === s.dogru) !== !!sen.olumsuz ? 'doğru' : 'yanlış';
        var m = String(t.ad || '').match(/^\s*(Doğru|Yanlış) ifade\s*$/i) || String(t.metin || '').match(/bu ifade (doğru|yanlış)/i);
        if (m && MUT !== 'szceliski' && trKucuk(m[1]) !== bek) neden.push('SZ-CELISKI: ' + h + ' şıkkı açıklaması "' + trKucuk(m[1]) + ' ifade" diyor, beklenen ' + bek);
      });
    } else if (sen.bicim === 'ONCUL') {
      var son = yaz.filter(function (a) { return a.son; })[0], sv = son ? son.satirlar[0].split('=').pop().trim() : '';
      if (MUT !== 'szsonuc' && trKucuk(sv) !== trKucuk(dn)) neden.push('SZ-SONUC: "' + sv + '" ≠ ' + s.dogru + ') "' + dn + '"');
      var isaret = yaz.filter(function (a) { return a.oncul && a.evet; }).map(function (a) { return a.oncul; }).sort().join(',');
      var bek = (oncullerSik(dn) || []).slice().sort().join(',');
      if (MUT !== 'szoncul' && isaret !== bek) neden.push('SZ-ONCUL: ✓ konan [' + isaret + '] ≠ doğru şık [' + bek + ']');
      var kokOncul = (String(s.soru || '').match(/(^|\n)\s*([IVX]+)\./g) || []).map(function (x) { return x.replace(/[\s.\n]/g, ''); });
      kokOncul.forEach(function (o) { if (MUT !== 'szoncul' && !yaz.some(function (a) { return a.oncul === o; })) neden.push('SZ-ONCUL: kökteki ' + o + '. öncülün satırı yok'); });
    } else {
      if (MUT !== 'szdogru' && !sikGecer(dn, karalama)) neden.push('SZ-DOGRU: doğru şık ' + s.dogru + ' karalamada geçmiyor');
      Object.keys(s.siklar).forEach(function (h) { if (h !== s.dogru && MUT !== 'szcift' && sikGecer(s.siklar[h], karalama)) neden.push('SZ-CIFT: ' + h + ' şıkkı da karalamada geçiyor'); });
    }
    yazilanlar(sen).forEach(function (y) { sayilar(y[1]).forEach(function (n) { if (MUT !== 'szrakam' && !kaynaktaVar(n, kay)) neden.push('SZ-RAKAM: ' + y[0] + ' "' + n + '" soruda/şıklarda/dayanakta yok'); }); });
    sen.sahne.forEach(function (a) { if (a.tur === 'karala' && !a.alt && MUT !== 'szneden') neden.push('SZ-NEDEN: ' + a.harf + ' şıkkının nedeni yok'); });
    var alti = sen.sahne[0]; if (MUT !== 'szalt' && (!alti.hedef.length || alti.hedef.some(function (x) { return String(s.soru || '').indexOf(x) < 0; }))) neden.push('SZ-ALT: altı çizilecek ifade kökte yok');
    return { gecer: neden.length === 0, neden: neden, senaryo: sen };
  }
  /* sitedeki düğmenin kapısı: önce sayısal şablon; yalnız SOZEL nedeniyle dönerse sözel şablon */
  function cizimKapi(s) {
    var r = cizerekKapi(s); if (r.gecer) return r;
    if (MUT === 'szkurtar' || r.neden.some(function (n) { return /^SOZEL/.test(n); }) && !r.neden.some(function (n) { return /^(RAKAM|ARITMETIK|VERI)/.test(n); })) {
      var z = sozelKapi(s); if (z.gecer) return z; return { gecer: false, neden: r.neden.concat(z.neden) };
    }
    return r;
  }

  /* DÜĞME ADAYI (22.10.2026): SGS + Yeterlilik yalnız PILOT listesinde (her çizimi elle bakıldı). KGK'da LİSTE YOK, KURAL var:
     "kgk-" öneki + cizimKapi geçti → düğme. Gerekçe: KGK bankası basılmaya devam ediyor (t7 bulutta, t8 yazımda); liste her basımda
     elle tazelenmek zorunda kalırdı ve yeni soru düğmesiz yayına çıkardı ("sonra tekrar basmayalım"). Kapı her kartta tarayıcıda koşar.
     Gözle kontrolde kusurlu bulunan KGK sorusu KGK_DIS'e yazılır (kimlik; soru metni yok). */
  var KGK_DIS = [];
  function dugmeAday(id, pset) { id = String(id || ''); if ((pset || PSET)[id]) return true; return MUT !== 'kgkonek' && /^kgk-/.test(id) && KGK_DIS.indexOf(id) < 0; }
  var PSET = {}; PILOT.forEach(function (x) { PSET[x] = 1; });

  var api = { PILOT: PILOT, PROVA: PROVA, SES: SES, SES_KASA: SES_KASA, KOVA: KOVA, sesKaydi: sesKaydi, sesKaynak: sesKaynak, kasaYollari: kasaYollari, KGK_DIS: KGK_DIS, dugmeAday: dugmeAday, senaryo: senaryo, cizerekKapi: cizerekKapi, sozelSenaryo: sozelSenaryo, sozelKapi: sozelKapi, cizimKapi: cizimKapi, sayilar: sayilar, kaynaktaVar: kaynaktaVar, aritmetikHatasi: aritmetikHatasi, sadele: sadele, celdiriciBol: celdiriciBol, cozumAdimi: cozumAdimi, hesapla: hesapla };
  if (typeof document === 'undefined') return api;

  // ---------------- tarayıcı ----------------
  var BETIK = document.currentScript && document.currentScript.src;
  var KOK = BETIK ? BETIK.replace(/cizerek-coz\.js.*$/, '') : '../../';
  var NS = 'http://www.w3.org/2000/svg';
  function esc(t) { return String(t == null ? '' : t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  /* 20.10 (GM3) sayaç: ciz/<sgs|yeterlilik|kgk>/<ac|son>. Ders sayfası şablonunun gcOlay'ı varsa onu kullanır (sayacı tembel yükler);
     yoksa sayfadaki goatcounter. Kişi verisi yok, soru kimliği yok (yalnız sınav). motor/huni-raporu.js "Çizim:" adımları. */
  function olay(s, ad) {
    var id = String((s && s.id) || ''), sv = /^sgs-/.test(id) ? 'sgs' : /^kgk-/.test(id) ? 'kgk' : 'yeterlilik', yol = 'ciz/' + sv + '/' + ad;
    try { if (typeof window.gcOlay === 'function') window.gcOlay(yol, 'Çizim ' + ad); else if (window.goatcounter && window.goatcounter.count) window.goatcounter.count({ path: yol, title: 'Çizim ' + ad, event: true }); } catch (e) { }
  }

  function stilEkle() {
    if (document.getElementById('czStil')) return;
    var st = document.createElement('style'); st.id = 'czStil';
    st.textContent =
      "@font-face{font-family:'TetikteKalem';font-style:normal;font-weight:600;font-display:swap;src:url('" + KOK + "kutuphane/caveat-600-latin-ext.woff2') format('woff2');unicode-range:U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308,U+0329,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C4,U+2113,U+2C60-2C7F,U+A720-A7FF}" +
      "@font-face{font-family:'TetikteKalem';font-style:normal;font-weight:600;font-display:swap;src:url('" + KOK + "kutuphane/caveat-600-latin.woff2') format('woff2');unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}" +
      ".czKat{--cz-bg:var(--bg);--cz-yazi:var(--yazi,var(--ink));--cz-dim:var(--dim,var(--muted));--cz-cizgi:var(--cizgi,var(--line));--cz-kart:var(--kart,var(--yuzey));--cz-mavi:var(--mavi,var(--link));--cz-yesil:var(--yesil,var(--green));--cz-kirmizi:var(--kirmizi,var(--red));--cz-altin:var(--altin,var(--amber));--cz-ustYazi:var(--ustYazi,var(--taban));position:fixed;inset:0;z-index:2147480600;background:var(--cz-bg);color:var(--cz-yazi);display:flex;flex-direction:column}" +
      ".czUst{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:10px 14px;border-bottom:1px solid var(--cz-cizgi);font-size:.86em;color:var(--cz-dim);max-width:640px;width:100%;margin:0 auto;box-sizing:border-box}" +
      ".czUst b{color:var(--cz-yazi)}.czKapat{font:inherit;background:var(--cz-bg);color:var(--cz-yazi);border:1px solid var(--cz-cizgi);border-radius:9px;padding:5px 11px;cursor:pointer}" +
      ".czGovde{flex:1 1 auto;overflow-y:auto;overflow-x:hidden;-webkit-overflow-scrolling:touch}" +   /* dikey çubuk çıkınca çizim katmanı 5 px taşıp yatay kaydırma açıyordu (20.10, 400 px pencere) */
      ".czSahne{position:relative;max-width:640px;margin:0 auto;padding:12px 14px 18px;box-sizing:border-box}" +
      ".czSoru{font-size:.98em;line-height:1.6;margin:0 0 12px;white-space:pre-line}" +   /* öncüllü soruda I/II/III ayrı satırda */
      ".czIpucu{margin:6px 0 0;font-size:.84em;color:var(--dim,var(--muted))}" +
      ".czSik{display:block;border:1px solid var(--cz-cizgi);border-radius:10px;padding:7px 12px;margin:0 0 7px;background:var(--cz-kart);font-size:.95em;line-height:1.45}" +
      ".czSik b{display:inline-block;width:1.6em;color:var(--cz-dim)}" +
      ".czNot{display:block;min-height:1.5em;font-family:'TetikteKalem',cursive;font-weight:600;font-size:1.22em;line-height:1.25;color:var(--cz-kirmizi);margin:2px 0 0 1.6em}" +
      ".czKar{position:relative;border:1.5px dashed var(--cz-cizgi);border-radius:12px;padding:20px 12px 10px;margin:16px 0 0;min-height:120px;" +
        "background:repeating-linear-gradient(transparent 0 33px,color-mix(in srgb,var(--cz-cizgi) 70%,transparent) 33px 34px);background-origin:content-box}" +
      ".czKar .czEt{position:absolute;left:12px;top:-10px;background:var(--cz-bg);padding:0 8px;font-size:.72em;font-weight:800;letter-spacing:.1em;color:var(--cz-dim)}" +
      ".czSat{text-align:left;font-family:'TetikteKalem',cursive;font-weight:600;font-size:1.42em;line-height:34px;color:var(--cz-yazi);margin:0;word-break:break-word}" +
      ".czSat.czYesil{color:var(--cz-yesil)}@media(max-width:480px){.czSat{font-size:1.24em;line-height:30px}.czKar{background:repeating-linear-gradient(transparent 0 29px,color-mix(in srgb,var(--cz-cizgi) 70%,transparent) 29px 30px);background-origin:content-box}}.czSat span{visibility:hidden}.czSat span.g{visibility:visible}" +
      ".czNot span{visibility:hidden}.czNot span.g{visibility:visible}" +
      ".czSvg{position:absolute;left:0;top:0;pointer-events:none;overflow:visible}" +
      ".czKalem{position:absolute;width:34px;height:34px;margin:-31px 0 0 -3px;pointer-events:none;display:none}" +
      ".czAlt{max-width:640px;width:100%;margin:0 auto;box-sizing:border-box;padding:10px 14px 4px;min-height:3.6em;font-size:.92em;line-height:1.45;font-weight:600;text-align:center;border-top:1px solid var(--cz-cizgi)}" +
      ".czAlt small{display:block;font-weight:500;color:var(--cz-dim);font-size:.82em;margin-bottom:2px}" +
      ".czAlc{flex:0 0 auto;max-width:640px;width:100%;margin:0 auto;box-sizing:border-box;display:flex;gap:8px;align-items:center;padding:6px 14px 14px}.czAlt{flex:0 0 auto}.czAlc button{white-space:nowrap}" +
      ".czAlc button{font:inherit;font-size:.9em;border-radius:10px;padding:10px 12px;cursor:pointer;border:1px solid var(--cz-cizgi);background:var(--cz-bg);color:var(--cz-yazi)}" +
      ".czAlc .czIleri{flex:1;background:var(--cz-mavi);color:var(--cz-ustYazi);border:0;font-weight:800}" +
      ".czAlc .czOyna{font-weight:700}.czAlc button:disabled{opacity:.45;cursor:default}" +
      ".czSay{font-size:.78em;color:var(--cz-dim);min-width:3.6em;text-align:center}" +
      ".cip2.bCiz{border-color:var(--altin);color:var(--yazi);font-weight:700}";
    document.head.appendChild(st);
  }

  /* telefonda '₺' / birim ya da '=' sonrası sonuç tek başına alt satıra düşmesin: boşluk bölünmez boşluk olur (rakam değişmez) */
  function harfle(metin) { var t = String(metin).replace(/ (₺|TL|birim|gün|ay)(?=$|[\s;,.)])/g, '\u00a0$1').replace(/= /g, '=\u00a0'); return Array.from(t).map(function (c) { return '<span>' + esc(c) + '</span>'; }).join(''); }

  function ac(s, sen) {
    stilEkle();
    var kat = document.createElement('div'); kat.className = 'czKat'; kat.setAttribute('role', 'dialog'); kat.setAttribute('aria-label', 'Nöbetçi çizerek çözüyor');
    var notH = {}; sen.sahne.forEach(function (a) { if (a.tur === 'karala') notH[a.harf] = a.not; });
    var satirlar = sen.sahne.filter(function (a) { return a.tur === 'yaz'; });
    kat.innerHTML = '<div class="czUst"><span>✍️ <b>Nöbetçi çizerek çözüyor</b></span><button type="button" class="czKapat" aria-label="Kapat">✕</button></div>'
      + '<div class="czGovde"><div class="czSahne"><p class="czSoru">' + esc(s.soru) + '</p>'
      + Object.keys(s.siklar).sort().map(function (h) { return '<div class="czSik" data-h="' + h + '"><b>' + h + ')</b><span class="czSm">' + esc(s.siklar[h]) + '</span>' + (notH[h] ? '<span class="czNot">' + harfle(notH[h]) + '</span>' : '') + '</div>'; }).join('')
      + '<div class="czKar"><span class="czEt">KARALAMA</span>' + satirlar.map(function (a) { return a.satirlar.map(function (x) { return '<p class="czSat' + (a.son ? ' czYesil' : '') + '">' + harfle(x) + '</p>'; }).join(''); }).join('') + '</div>'
      + '<svg class="czSvg" aria-hidden="true"></svg><svg class="czKalem" viewBox="0 0 64 64" aria-hidden="true"><g transform="rotate(35 32 32)"><rect x="26" y="2" width="12" height="44" rx="3" fill="currentColor"/><rect x="26" y="8" width="12" height="5" style="fill:var(--cz-altin)"/><polygon points="26,46 38,46 32,60" style="fill:color-mix(in srgb,var(--cz-altin) 45%,var(--cz-bg))"/><polygon points="30,55 34,55 32,60" fill="currentColor"/></g></svg>'
      + '</div></div>'
      + '<div class="czAlt" aria-live="polite"></div>'
      + '<div class="czAlc"><button type="button" class="czGeri" aria-label="Önceki adım">◀</button><span class="czSay"></span><button type="button" class="czIleri">Sonraki adım ▶</button><button type="button" class="czOyna">▶ Tümünü oynat</button></div>';
    document.body.appendChild(kat);
    var sahneEl = kat.querySelector('.czSahne'), svg = kat.querySelector('.czSvg'), kalem = kat.querySelector('.czKalem'), altEl = kat.querySelector('.czAlt');
    kalem.style.color = 'var(--cz-yazi)';
    var N = sen.sahne.length, adim = -1, q = 1, oynat = false, raf = 0, bekle = 0, P = [], sonOlay = 0;
    /* sesli: tablodaki sahne sayısı bu senaryoyla aynıysa (şablon değişip kaydıysa ses KAPANIR, çizim sessiz kalır) */
    var SE = sesKaydi(s.id), SK = SE && SE.n === N && SE.b[SE.b.length - 1] === N - 1 ? SE : null, sesEl = null, imzaS = null;
    /* KGK: pencere açılır açılmaz imzalı adresler istenir (iOS'ta ilk "Sesli oynat" dokunuşu beklemeden çalabilsin) */
    function imzaAl() {
      if (!SK || !SK.kasa) return Promise.resolve();
      if (SK.u && SK.uZaman && Date.now() - SK.uZaman < 25 * 60 * 1000) return Promise.resolve();
      var sb = window.__pkSb; if (!sb || !sb.storage) return Promise.resolve();
      return imzaS || (imzaS = sb.storage.from(KOVA).createSignedUrls(kasaYollari(SK), 1800).then(function (r) {
        var d = (r && !r.error && r.data) || []; SK.u = SK.b.map(function (x, i) { return d[i] && d[i].signedUrl ? d[i].signedUrl : null; }); SK.uZaman = Date.now();
      }, function () { }).then(function () { imzaS = null; }));
    }
    imzaAl();
    function sesDur() { if (sesEl) { sesEl.onended = sesEl.onerror = null; try { sesEl.pause(); } catch (e) { } } }
    var tohum = 7; function r() { tohum = (tohum * 16807) % 2147483647; return tohum / 2147483647; } function j(a) { return (r() - 0.5) * a; }
    function kutu(el) { var b = el.getBoundingClientRect(), k = sahneEl.getBoundingClientRect(); return { x: b.left - k.left, y: b.top - k.top, w: b.width, h: b.height }; }
    function yol(d, renk, kal, ad, t0, t1) { var p = document.createElementNS(NS, 'path'); p.setAttribute('d', d); p.setAttribute('fill', 'none'); p.style.stroke = renk; p.setAttribute('stroke-width', kal); p.setAttribute('stroke-linecap', 'round'); p.setAttribute('stroke-linejoin', 'round'); p.setAttribute('opacity', '.9'); svg.appendChild(p); var L = p.getTotalLength(); p.style.strokeDasharray = L; p.style.strokeDashoffset = L; P.push({ tur: 'yol', p: p, L: L, ad: ad, t0: t0, t1: t1 }); }
    function harfler(el, ad, t0, t1) { P.push({ tur: 'harf', s: Array.prototype.slice.call(el.querySelectorAll('span')), ad: ad, t0: t0, t1: t1 }); }
    function altCiz(b, renk, ad, t0, t1) { var y = b.y + b.h - 1; var d = 'M ' + (b.x - 3) + ' ' + (y + j(2)); for (var i = 1; i <= 4; i++) d += ' Q ' + (b.x + b.w * (i - 0.5) / 4) + ' ' + (y + j(5)) + ' ' + (b.x - 3 + (b.w + 6) * i / 4) + ' ' + (y + j(2)); yol(d, renk, 3.2, ad, t0, t1); }
    function daire(b, renk, ad, t0, t1) { var cx = b.x + b.w / 2, cy = b.y + b.h / 2, rx = b.w / 2 + 8, ry = b.h / 2 + 7, d = '', M = 40; for (var i = 0; i <= M * 1.12; i++) { var a = -2.2 + i / M * Math.PI * 2, k = 1 + j(0.04) + (i > M ? 0.04 : 0); d += (i ? ' L ' : 'M ') + (cx + Math.cos(a) * rx * k).toFixed(1) + ' ' + (cy + Math.sin(a) * ry * k).toFixed(1); } yol(d, renk, 3.6, ad, t0, t1); }
    function karala(b, renk, ad, t0, t1) { var x0 = b.x + 8, x1 = b.x + Math.min(b.w - 8, 260), y0 = b.y + 4, y1 = b.y + b.h - 4; yol('M ' + x0 + ' ' + (y0 + b.h * 0.2) + ' L ' + x1 + ' ' + (y1 - b.h * 0.15) + ' M ' + x1 + ' ' + (y0 + b.h * 0.15) + ' L ' + x0 + ' ' + (y1 - b.h * 0.2), renk, 3.4, ad, t0, t1); }
    function tik(b, renk, ad, t0, t1) { var x = b.x + b.w - 34, y = b.y + b.h / 2; yol('M ' + x + ' ' + y + ' L ' + (x + 9) + ' ' + (y + 10) + ' L ' + (x + 26) + ' ' + (y - 12), renk, 4, ad, t0, t1); }
    // soru metnindeki sayının ilk geçişini sar (yalnız çizim için; metin değişmez)
    function soruSar(hedef) {
      var p = kat.querySelector('.czSoru'), t = String(s.soru || ''), parca = [], i = 0, kalan = hedef.slice();
      while (kalan.length) {
        var en = -1, ne = null;
        kalan.forEach(function (n) { var re = new RegExp('(^|[^\\d.,])(' + kacis(n) + ')(?![\\d]|[.,]\\d)', 'g'); re.lastIndex = i; var m = re.exec(t); if (m) { var at = m.index + m[1].length; if (en < 0 || at < en) { en = at; ne = n; } } });
        if (en < 0) break; parca.push(esc(t.slice(i, en)) + '<span class="czV">' + esc(ne) + '</span>'); i = en + ne.length; kalan.splice(kalan.indexOf(ne), 1);
      }
      p.innerHTML = parca.join('') + esc(t.slice(i));
    }
    function kur() {
      P = []; while (svg.firstChild) svg.removeChild(svg.firstChild); tohum = 7;
      svg.setAttribute('width', sahneEl.scrollWidth); svg.setAttribute('height', sahneEl.scrollHeight);
      var satirEl = kat.querySelectorAll('.czSat'), si = 0;
      sen.sahne.forEach(function (a, ad) {
        if (a.tur === 'alti') { var v = kat.querySelectorAll('.czV'), n = v.length || 1; Array.prototype.forEach.call(v, function (el, k) { Array.prototype.forEach.call(el.getClientRects(), function (rc) { var kk = sahneEl.getBoundingClientRect(); altCiz({ x: rc.left - kk.left, y: rc.top - kk.top, w: rc.width, h: rc.height }, 'var(--cz-mavi)', ad, k / n, (k + 1) / n); }); }); }
        else if (a.tur === 'yaz') { var nS = a.satirlar.length; a.satirlar.forEach(function (x, u) { var el = satirEl[si++]; if (el) harfler(el, ad, u / nS, (u + 1) / nS); }); }
        else if (a.tur === 'daire') { var sk = kat.querySelector('.czSik[data-h="' + a.harf + '"]'); if (sk) { var b = kutu(sk), bm0 = kutu(sk.querySelector('.czSm')); var bd = { x: b.x, y: b.y, w: Math.min(b.w, bm0.x + bm0.w - b.x + 56), h: b.h }; daire(bd, 'var(--cz-yesil)', ad, 0, 0.75); tik(bd, 'var(--cz-yesil)', ad, 0.75, 1); }   /* yuvarlak şık metnini sarar, sahneden taşmaz */ }
        else if (a.tur === 'karala') { var sk2 = kat.querySelector('.czSik[data-h="' + a.harf + '"]'); if (sk2) { var sm = sk2.querySelector('.czSm'), b2 = kutu(sk2), bm = kutu(sm); karala({ x: b2.x, y: b2.y, w: Math.max(bm.x + bm.w - b2.x + 16, 120), h: bm.y + bm.h - b2.y + 6 }, 'var(--cz-kirmizi)', ad, 0, a.not ? 0.4 : 1); var ne = sk2.querySelector('.czNot'); if (ne) harfler(ne, ad, 0.4, 1); } }
      });
    }
    function ciz() {
      var uc = null;
      P.forEach(function (o) {
        var g = o.ad < adim ? 1 : (o.ad > adim ? 0 : Math.max(0, Math.min(1, (q - o.t0) / Math.max(0.001, o.t1 - o.t0))));
        if (o.tur === 'yol') { o.p.style.strokeDashoffset = o.L * (1 - g); o.p.style.visibility = g > 0 ? 'visible' : 'hidden'; if (g > 0 && g < 1) { var pt = o.p.getPointAtLength(o.L * g); uc = { x: pt.x, y: pt.y }; } }
        else { var n = Math.round(o.s.length * g); o.s.forEach(function (sp, k) { sp.classList.toggle('g', k < n); }); if (g > 0 && g < 1 && n > 0) { var b = kutu(o.s[n - 1]); uc = { x: b.x + b.w, y: b.y + b.h * 0.75 }; } }
      });
      if (uc) { kalem.style.display = 'block'; kalem.style.left = uc.x + 'px'; kalem.style.top = uc.y + 'px'; } else kalem.style.display = 'none';
      var a = sen.sahne[adim];
      if (adim >= N - 1 && q >= 1 && !sonOlay) { sonOlay = 1; olay(s, 'son'); }
      var ust = adim < 0 ? '' : a.etiket ? a.etiket : (a.tur === 'alti' ? 'Soruda verilenler' : a.tur === 'yaz' ? ('Çözüm adımı ' + (sen.sahne.slice(0, adim + 1).filter(function (x) { return x.tur === 'yaz'; }).length) + ' / ' + sen.cozumSay) : a.tur === 'daire' ? ('Doğru cevap: ' + a.harf) : ('Yanlış şık ' + a.harf));
      altEl.innerHTML = adim < 0 ? '<small>Hazır</small>Kalem soruyu adım adım çözecek. <b>Sonraki adım</b> ya da ' + (SK ? '<b>🔊 Sesli oynat</b> (sesi aç)' : '<b>Tümünü oynat</b>') + '.' : '<small>' + esc(ust) + '</small>' + esc(a.alt || '');
      kat.querySelector('.czSay').textContent = (adim + 1) + ' / ' + N;
      kat.querySelector('.czGeri').disabled = adim < 0;
      var dar = window.innerWidth < 480;   /* telefonda düğme yazısı tek satır kalsın, alt yazının üstüne binmesin */
      var ileri = kat.querySelector('.czIleri'); ileri.disabled = adim >= N - 1 && q >= 1; ileri.textContent = adim >= N - 1 && q >= 1 ? 'Bitti ✓' : (dar ? 'Sonraki ▶' : 'Sonraki adım ▶');
      kat.querySelector('.czOyna').textContent = oynat ? (dar ? '⏸ Dur' : '⏸ Durdur') : (adim >= N - 1 && q >= 1 ? '↺ Baştan' : SK ? (dar ? '🔊 Dinle' : '🔊 Sesli oynat') : (dar ? '▶ Oynat' : '▶ Tümünü oynat'));
      if (uc && a && a.tur !== 'alti') gorunurYap(uc);
    }
    function gorunurYap(uc) { var g = kat.querySelector('.czGovde'), gb = g.getBoundingClientRect(), kb = sahneEl.getBoundingClientRect(); var y = kb.top + uc.y - gb.top; if (y > g.clientHeight - 40 || y < 30) g.scrollTop += y - g.clientHeight * 0.55; }
    function sure(a) { if (a.tur === 'yaz') return Math.min(5200, 900 + a.satirlar.join('').length * 38); if (a.tur === 'karala') return a.not ? 2200 : 900; if (a.tur === 'alti') return 600 + 260 * Math.max(1, a.hedef.length); return 1100; }
    function oyna(k) {
      cancelAnimationFrame(raf); clearTimeout(bekle); adim = k; q = 0; var t0 = performance.now(), T = sure(sen.sahne[k]);
      if (sen.sahne[k].tur !== 'alti' && sen.sahne[k].tur !== 'yaz') { var sk = kat.querySelector('.czSik[data-h="' + sen.sahne[k].harf + '"]'); if (sk) sk.scrollIntoView({ block: 'center', behavior: 'smooth' }); }
      else if (sen.sahne[k].tur === 'alti') kat.querySelector('.czGovde').scrollTop = 0;
      (function adimla(t) { q = Math.min(1, (t - t0) / T); ciz(); if (q < 1) raf = requestAnimationFrame(adimla); else if (oynat) { if (adim < N - 1) bekle = setTimeout(function () { oyna(adim + 1); }, 900); else { oynat = false; ciz(); } } })(t0);
    }
    function bitir() { cancelAnimationFrame(raf); clearTimeout(bekle); q = 1; ciz(); }
    /* SESLİ OYNATMA: cümle g çalarken önceki cümlenin bitişinden b[g]'ye kadar sahneler, cümle süresine bölünerek çizilir;
       ses ve çizim ikisi de bitince sonraki cümle. Tek <audio> öğesi (iOS: ilk çalış dokunuşla, sonra aynı öğe kaynak değiştirir). */
    function zincir(k, son, T, bitti) {
      cancelAnimationFrame(raf); adim = k; q = 0; var t0 = performance.now();
      if (sen.sahne[k].tur !== 'alti' && sen.sahne[k].tur !== 'yaz') { var sk = kat.querySelector('.czSik[data-h="' + sen.sahne[k].harf + '"]'); if (sk) sk.scrollIntoView({ block: 'center', behavior: 'smooth' }); }
      else if (sen.sahne[k].tur === 'alti') kat.querySelector('.czGovde').scrollTop = 0;
      (function adimla(t) { if (!oynat) return; q = Math.min(1, (t - t0) / T); ciz(); if (q < 1) raf = requestAnimationFrame(adimla); else if (k < son) bekle = setTimeout(function () { zincir(k + 1, son, T, bitti); }, 120); else bitti(); })(t0);
    }
    function sesliGrup(g) {
      if (!oynat) return;
      if (g >= SK.b.length || adim >= N - 1) { oynat = false; sesDur(); ciz(); return; }
      var ilk = adim + 1, son = Math.max(ilk, SK.b[g]), sesB = false, cizB = false;
      var devam = function () { if (sesB && cizB && oynat) bekle = setTimeout(function () { sesliGrup(g + 1); }, 300); };
      sesDur(); var kaynak = sesKaynak(SK, g, KOK);
      if (!kaynak) sesB = true;   /* KGK: imzalı adres yok (paket/oturum yok) -> bu cümle sessiz, çizim sürer */
      else {
        sesEl.src = kaynak;
        sesEl.onended = sesEl.onerror = function () { sesB = true; devam(); };
        var p = sesEl.play(); if (p && p.catch) p.catch(function () { sesB = true; devam(); });   /* ses çalmazsa çizim sessiz sürer */
      }
      var T = Math.max(600, Math.min(5200, (SK.s[g] * 1000 - 300) / (son - ilk + 1)));
      zincir(ilk, son, T, function () { cizB = true; devam(); });
    }
    kat.querySelector('.czIleri').addEventListener('click', function () { oynat = false; sesDur(); if (q < 1) { bitir(); return; } if (adim < N - 1) oyna(adim + 1); });
    kat.querySelector('.czGeri').addEventListener('click', function () { oynat = false; sesDur(); cancelAnimationFrame(raf); clearTimeout(bekle); adim = Math.max(-1, adim - (q < 1 ? 0 : 1)); if (adim >= 0) { q = 1; } ciz(); if (adim < 0) kat.querySelector('.czGovde').scrollTop = 0; });
    kat.querySelector('.czOyna').addEventListener('click', function () {
      if (oynat) { oynat = false; sesDur(); bitir(); return; }
      if (SK) {   /* sesli: her zaman baştan (cümle ile sahne eşleşmesi baştan sayılır) */
        oynat = true; cancelAnimationFrame(raf); clearTimeout(bekle); adim = -1; q = 1; ciz(); kat.querySelector('.czGovde').scrollTop = 0;
        if (!sesEl) { sesEl = new Audio(); sesEl.preload = 'auto'; }
        olay(s, 'ses');
        if (SK.kasa && !SK.u) { imzaAl().then(function () { sesliGrup(0); }); return; }   /* imza henüz gelmediyse bekle (gelmezse sessiz) */
        sesliGrup(0); return;
      }
      oynat = true; if (adim >= N - 1 && q >= 1) { adim = -1; ciz(); kat.querySelector('.czGovde').scrollTop = 0; }
      if (q < 1) { q = 1; } oyna(adim + 1);
    });
    function kapat() { oynat = false; sesDur(); cancelAnimationFrame(raf); clearTimeout(bekle); window.removeEventListener('resize', yenile); document.removeEventListener('keydown', tus); kat.remove(); }
    function tus(e) { if (e.key === 'Escape') kapat(); else if (e.key === 'ArrowRight') kat.querySelector('.czIleri').click(); else if (e.key === 'ArrowLeft') kat.querySelector('.czGeri').click(); }
    var ry = 0; function yenile() { clearTimeout(ry); ry = setTimeout(function () { kur(); ciz(); }, 120); }
    kat.querySelector('.czKapat').addEventListener('click', kapat);
    window.addEventListener('resize', yenile); document.addEventListener('keydown', tus);
    soruSar(sen.sahne[0].hedef || []);
    var hazir = function () { kur(); ciz(); kat.querySelector('.czIleri').focus(); };
    /* yazı tipi inmeden ölçülürse satırlar sonradan genişler, çizgiler kayar → en çok 1,5 sn beklenir */
    if (document.fonts && document.fonts.load) Promise.race([document.fonts.load("600 20px 'TetikteKalem'", 'Aç₺ğş'), new Promise(function (y) { setTimeout(y, 1500); })]).then(hazir, hazir); else hazir();
    window.__czTest = { kat: kat, sen: sen, git: function (k) { oynat = false; cancelAnimationFrame(raf); adim = k; q = 1; ciz(); } };
  }

  // --- düğme: pilot sorunun kartına, panelin çip satırına ---
  function soruBul(id) {
    var L = null; try { L = (typeof SORULAR !== 'undefined') ? SORULAR : null; } catch (e) { L = null; }   // eslint-disable-line no-undef
    if (!L) L = window.__KASA_SORULAR || [];
    for (var i = 0; i < L.length; i++) if (L[i] && L[i].id === id) return L[i];
    return null;
  }
  var KAPI_ON = {};
  function kartIsle(k) {
    if (!k || k.__cz) return; var na = k.querySelector('.notumAlan'); var cip = k.querySelector('.panel .cipler'); if (!na || !cip) return;
    k.__cz = 1; var id = na.getAttribute('data-id'); if (!dugmeAday(id)) return;
    var s = soruBul(id); if (!s) { k.__cz = 0; return; }
    var kp = KAPI_ON[id] || (KAPI_ON[id] = cizimKapi(s));
    if (!kp.gecer) { if (window.console) console.info('[cizerek-coz] kapı döndü', id, kp.neden); return; }
    /* 20.10 (Cem "1.2.3" GM2): cevaptan ÖNCE de görünsün ama cevabı ele vermesin -> düğme değil, kökün altında tek satır haber */
    var ps = k.querySelector('.govde .soru');
    var sk0 = sesKaydi(id);   /* KGK kasa sesi yalnız oturum istemcisi olan (paketli) sayfada "sesli" sayılır */
    var sesli = !!(sk0 && kp.senaryo && sk0.n === kp.senaryo.sahne.length && (!sk0.kasa || window.__pkSb));   /* 22.10 Cem "1 yap": sesli soruda ibare */
    if (ps && !k.querySelector('.czIpucu')) { var ip = document.createElement('p'); ip.className = 'czIpucu'; ip.textContent = sesli ? '✍️🔊 Cevaplayınca Nöbetçi bu soruyu kalemle çizip sesli anlatarak çözer.' : '✍️ Cevaplayınca Nöbetçi bu soruyu kalemle adım adım çözer.'; ps.parentNode.insertBefore(ip, ps.nextSibling); }
    var b = document.createElement('button'); b.type = 'button'; b.className = 'cip2 bCiz'; b.textContent = sesli ? '✍️🔊 Nöbetçi sesli çözsün' : '✍️ Nöbetçi çizerek çözsün';
    b.addEventListener('click', function (e) { e.stopPropagation(); olay(s, 'ac'); ac(s, kp.senaryo); });
    var once = cip.querySelector('.bDaha') || cip.querySelector('.bSonraki'); cip.insertBefore(b, once || null);
    stilEkle();
  }
  function tara() { Array.prototype.forEach.call(document.querySelectorAll('#akis > .kart'), kartIsle); }
  function basla() {
    var akis = document.getElementById('akis'); if (!akis) return; tara();
    new MutationObserver(function () { tara(); }).observe(akis, { childList: true });
  }
  if (PILOT.length) { if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', basla); else basla(); }
  api.ac = ac; return api;
});
