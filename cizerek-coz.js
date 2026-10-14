/* cizerek-coz.js — "✍️ Nöbetçi çizerek çözsün" PİLOTU (14.10.2026, Cem: "sitedeki sorular da böyle cevaplansın")
 *
 * Kaydır-Çöz soru kartında, cevaptan sonra açılan panele bir düğme ekler. Düğme yalnız PILOT listesindeki
 * sorularda ve yalnız KAPI geçerse çıkar. Tıklanınca soru, şıklar ve bir karalama alanı açılır; Nöbetçi
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
    'sgs-k5-fmuh-zor/kp-17', 'sgs-p-ekonomi-kolay-r1-a/kp-04', 'sgs-t1-mta-zor/kp-01', 'sgs-t1-maliyet-kolay/kp-07'
  ];

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
  var ATLA = /^\s*(Verilen|Soruda ne var|Soru bize|Yanlış yol|Ters durum|Senin seçimin|Takıldığın yer|Konu:)/i;
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

  var api = { PILOT: PILOT, senaryo: senaryo, cizerekKapi: cizerekKapi, sayilar: sayilar, kaynaktaVar: kaynaktaVar, aritmetikHatasi: aritmetikHatasi, sadele: sadele, celdiriciBol: celdiriciBol, cozumAdimi: cozumAdimi, hesapla: hesapla };
  if (typeof document === 'undefined') return api;

  // ---------------- tarayıcı ----------------
  var BETIK = document.currentScript && document.currentScript.src;
  var KOK = BETIK ? BETIK.replace(/cizerek-coz\.js.*$/, '') : '../../';
  var PSET = {}; PILOT.forEach(function (x) { PSET[x] = 1; });
  var NS = 'http://www.w3.org/2000/svg';
  function esc(t) { return String(t == null ? '' : t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  function stilEkle() {
    if (document.getElementById('czStil')) return;
    var st = document.createElement('style'); st.id = 'czStil';
    st.textContent =
      "@font-face{font-family:'TetikteKalem';font-style:normal;font-weight:600;font-display:swap;src:url('" + KOK + "kutuphane/caveat-600-latin-ext.woff2') format('woff2');unicode-range:U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308,U+0329,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C4,U+2113,U+2C60-2C7F,U+A720-A7FF}" +
      "@font-face{font-family:'TetikteKalem';font-style:normal;font-weight:600;font-display:swap;src:url('" + KOK + "kutuphane/caveat-600-latin.woff2') format('woff2');unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}" +
      ".czKat{--cz-bg:var(--bg);--cz-yazi:var(--yazi,var(--ink));--cz-dim:var(--dim,var(--muted));--cz-cizgi:var(--cizgi,var(--line));--cz-kart:var(--kart,var(--yuzey));--cz-mavi:var(--mavi,var(--link));--cz-yesil:var(--yesil,var(--green));--cz-kirmizi:var(--kirmizi,var(--red));--cz-altin:var(--altin,var(--amber));--cz-ustYazi:var(--ustYazi,var(--taban));position:fixed;inset:0;z-index:60;background:var(--cz-bg);color:var(--cz-yazi);display:flex;flex-direction:column}" +
      ".czUst{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:10px 14px;border-bottom:1px solid var(--cz-cizgi);font-size:.86em;color:var(--cz-dim);max-width:640px;width:100%;margin:0 auto;box-sizing:border-box}" +
      ".czUst b{color:var(--cz-yazi)}.czKapat{font:inherit;background:var(--cz-bg);color:var(--cz-yazi);border:1px solid var(--cz-cizgi);border-radius:9px;padding:5px 11px;cursor:pointer}" +
      ".czGovde{flex:1 1 auto;overflow:auto;-webkit-overflow-scrolling:touch}" +
      ".czSahne{position:relative;max-width:640px;margin:0 auto;padding:12px 14px 18px;box-sizing:border-box}" +
      ".czSoru{font-size:.98em;line-height:1.6;margin:0 0 12px}" +
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
    var N = sen.sahne.length, adim = -1, q = 1, oynat = false, raf = 0, bekle = 0, P = [];
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
      var ust = adim < 0 ? '' : (a.tur === 'alti' ? 'Soruda verilenler' : a.tur === 'yaz' ? ('Çözüm adımı ' + (sen.sahne.slice(0, adim + 1).filter(function (x) { return x.tur === 'yaz'; }).length) + ' / ' + sen.cozumSay) : a.tur === 'daire' ? ('Doğru cevap: ' + a.harf) : ('Yanlış şık ' + a.harf));
      altEl.innerHTML = adim < 0 ? '<small>Hazır</small>Kalem soruyu adım adım çözecek. <b>Sonraki adım</b> ya da <b>Tümünü oynat</b>.' : '<small>' + esc(ust) + '</small>' + esc(a.alt || '');
      kat.querySelector('.czSay').textContent = (adim + 1) + ' / ' + N;
      kat.querySelector('.czGeri').disabled = adim < 0;
      var dar = window.innerWidth < 480;   /* telefonda düğme yazısı tek satır kalsın, alt yazının üstüne binmesin */
      var ileri = kat.querySelector('.czIleri'); ileri.disabled = adim >= N - 1 && q >= 1; ileri.textContent = adim >= N - 1 && q >= 1 ? 'Bitti ✓' : (dar ? 'Sonraki ▶' : 'Sonraki adım ▶');
      kat.querySelector('.czOyna').textContent = oynat ? (dar ? '⏸ Dur' : '⏸ Durdur') : (adim >= N - 1 && q >= 1 ? '↺ Baştan' : (dar ? '▶ Oynat' : '▶ Tümünü oynat'));
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
    kat.querySelector('.czIleri').addEventListener('click', function () { oynat = false; if (q < 1) { bitir(); return; } if (adim < N - 1) oyna(adim + 1); });
    kat.querySelector('.czGeri').addEventListener('click', function () { oynat = false; cancelAnimationFrame(raf); clearTimeout(bekle); adim = Math.max(-1, adim - (q < 1 ? 0 : 1)); if (adim >= 0) { q = 1; } ciz(); if (adim < 0) kat.querySelector('.czGovde').scrollTop = 0; });
    kat.querySelector('.czOyna').addEventListener('click', function () {
      if (oynat) { oynat = false; bitir(); return; }
      oynat = true; if (adim >= N - 1 && q >= 1) { adim = -1; ciz(); kat.querySelector('.czGovde').scrollTop = 0; }
      if (q < 1) { q = 1; } oyna(adim + 1);
    });
    function kapat() { cancelAnimationFrame(raf); clearTimeout(bekle); window.removeEventListener('resize', yenile); document.removeEventListener('keydown', tus); kat.remove(); }
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
    k.__cz = 1; var id = na.getAttribute('data-id'); if (!PSET[id]) return;
    var s = soruBul(id); if (!s) { k.__cz = 0; return; }
    var kp = KAPI_ON[id] || (KAPI_ON[id] = cizerekKapi(s));
    if (!kp.gecer) { if (window.console) console.info('[cizerek-coz] kapı döndü', id, kp.neden); return; }
    var b = document.createElement('button'); b.type = 'button'; b.className = 'cip2 bCiz'; b.textContent = '✍️ Nöbetçi çizerek çözsün';
    b.addEventListener('click', function (e) { e.stopPropagation(); ac(s, kp.senaryo); });
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
