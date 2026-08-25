/* ============================================================================
   KONU ŞEMASI ÇİZİCİ — 25.08.2026
   Cem: "şema ile konuyu daha iyi öğretiriz dersen onu yapalım"

   NE YAPAR: konu_semasi.yapi (JSON) -> SVG. Çizim TAMAMEN burada, deterministik.
   Model asla SVG yazmaz; yalnız yapıyı üretir. Sebep: koordinat taşması,
   kutudan metin çıkması ve karanlık temada okunmayan renk, model SVG yazdığında
   kaçınılmaz. Yapıyı modele, çizimi koda bırakınca 300 şema birbirinin aynısı
   görünür ve bir tasarım değişikliği tek dosyada yapılır.

   TEMA: renkler HEP CSS değişkeninden okunur (--ink, --line2, --panel2,
   --accent2 ...). Sabit renk yazılmaz - site üç temalı (açık/sepya/koyu) ve
   19.08 dersi: gömülü renk bir temada görünmez olur.

   GENİŞLİK: viewBox 680 sabit, width=100%. Telefonda kırılmasın diye tüm
   içerik x=40..640 güvenli alanında; metin genişliği ÖLÇÜLEREK kutuya sığdırılır
   (SVG metni kendiliğinden satır kırmaz - taşarsa sessizce kutudan çıkar).
============================================================================ */
(function (global) {
  'use strict';

  var W = 680, KENAR = 40, GUVENLI = W - 2 * KENAR;   // 600
  var BOSLUK = 20;      // yan yana kutular arası
  var DIKEY  = 26;      // seviyeler arası ok boşluğu

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  /* Metin genişliği tahmini. Ölçüm (Anthropic Sans kalibrasyonu + kendi
     denememiz): 14px/500 ~7,6px/karakter · 13px/400 ~7,0 · 12px/400 ~6,5.
     Türkçe harfler (ı ş ğ ü ö ç) latin genişliğindedir, ek pay gerekmez. */
  function genislik(metin, boy, kalin) {
    var kat = boy >= 14 ? (kalin ? 7.6 : 7.4) : (boy >= 13 ? 7.0 : 6.5);
    return String(metin || '').length * kat;
  }

  /* Kutuya sığmayan metni KIRPMAZ, satırlara böler. SVG <text> kendiliğinden
     sarmaz; her satır ayrı <tspan> olmak zorunda. Sığmıyorsa sessizce taşmak
     yerine ikinci satıra inmek doğru davranış - şema okunabilir kalır. */
  function satirla(metin, enGenis, boy, kalin) {
    var kelimeler = String(metin || '').split(/\s+/).filter(Boolean);
    var satirlar = [], simdi = '';
    for (var i = 0; i < kelimeler.length; i++) {
      var deneme = simdi ? simdi + ' ' + kelimeler[i] : kelimeler[i];
      if (genislik(deneme, boy, kalin) <= enGenis || !simdi) { simdi = deneme; }
      else { satirlar.push(simdi); simdi = kelimeler[i]; }
    }
    if (simdi) satirlar.push(simdi);
    return satirlar.length ? satirlar : [''];
  }

  function metinBlogu(x, y, satirlar, sinif, boy, dy) {
    var h = '<text class="' + sinif + '" x="' + x + '" y="' + y + '" text-anchor="middle">';
    for (var i = 0; i < satirlar.length; i++) {
      h += i === 0
        ? esc(satirlar[i])
        : '<tspan x="' + x + '" dy="' + dy + '">' + esc(satirlar[i]) + '</tspan>';
    }
    return h + '</text>';
  }

  /* Kutu yüksekliği içeriğe göre hesaplanır - sabit yükseklik uzun başlıkta
     taşar. 12.08 dersi: "yeşil koşu ≠ sığan metin". */
  function kutuYuksek(basSatir, altSatir) {
    var h = 16 + basSatir * 19;
    if (altSatir) h += altSatir * 16 + 4;
    return Math.max(44, h + 12);
  }

  // ---------------------------------------------------------------- AKIŞ
  /* yapi = { tip:'akis', dugumler:[{id,tip,metin,alt}], baglar:[[a,b],...] }
     dugum.tip: baslangic | karar | sonuc                                   */
  function akisCiz(y, isaret) {
    var dugumler = y.dugumler || [], baglar = y.baglar || [];
    var harita = {}, cocuk = {}, ebeveynVar = {};
    dugumler.forEach(function (d) { harita[d.id] = d; cocuk[d.id] = []; });
    baglar.forEach(function (b) {
      if (cocuk[b[0]] && harita[b[1]]) { cocuk[b[0]].push(b[1]); ebeveynVar[b[1]] = 1; }
    });

    // Seviyeler: kökten genişlik-öncelikli. Döngü olursa 12 seviyede durur.
    var sira = dugumler.filter(function (d) { return !ebeveynVar[d.id]; }).map(function (d) { return d.id; });
    if (!sira.length && dugumler.length) sira = [dugumler[0].id];
    var seviyeler = [], gorulen = {};
    while (sira.length && seviyeler.length < 12) {
      seviyeler.push(sira);
      sira.forEach(function (id) { gorulen[id] = 1; });
      var sonraki = [];
      sira.forEach(function (id) {
        (cocuk[id] || []).forEach(function (c) {
          if (!gorulen[c] && sonraki.indexOf(c) < 0) sonraki.push(c);
        });
      });
      sira = sonraki;
    }

    // Geometri
    var yer = {}, ust = KENAR, parcalar = [];
    seviyeler.forEach(function (seviye) {
      var n = seviye.length;
      var kutuG = n === 1 ? 400 : Math.floor((GUVENLI - (n - 1) * BOSLUK) / n);
      var solBas = n === 1 ? Math.round((W - 400) / 2) : KENAR;
      var enYuksek = 0, satirBilgi = [];
      seviye.forEach(function (id, i) {
        var d = harita[id] || { metin: '' };
        var ic = kutuG - 32;
        var bs = satirla(d.metin, ic, 14, true);
        var as = d.alt ? satirla(d.alt, ic, 12, false) : null;
        var h = kutuYuksek(bs.length, as ? as.length : 0);
        if (h > enYuksek) enYuksek = h;
        satirBilgi.push({ id: id, d: d, bs: bs, as: as, x: solBas + i * (kutuG + BOSLUK), g: kutuG });
      });
      satirBilgi.forEach(function (s) {
        yer[s.id] = { x: s.x, y: ust, g: s.g, h: enYuksek, ox: s.x + s.g / 2 };
        /* İŞARET: aynı şema herkese aynı, ama öğrencinin İŞARETLEDİĞİ ŞIKKA göre
           üzerinde vurgulanır. Cem'in sorusunun cevabı: şema KONUYU anlatır,
           işaret CEVABI anlatır - ikisi birden. */
        var sinif = (s.d.tip === 'sonuc') ? 'smSonuc' : 'smKutu';
        if (isaret) {
          if (s.id === isaret.dogruDugum) sinif = 'smDogru';
          else if (s.id === isaret.dugum) sinif = 'smSecim';
        }
        parcalar.push('<rect class="' + sinif + '" x="' + s.x + '" y="' + ust +
          '" width="' + s.g + '" height="' + enYuksek + '" rx="10"/>');
        var basY = ust + (s.as ? 26 : Math.round(enYuksek / 2) + 5);
        parcalar.push(metinBlogu(s.x + s.g / 2, basY, s.bs, 'smBas', 14, 19));
        if (s.as) {
          parcalar.push(metinBlogu(s.x + s.g / 2, basY + (s.bs.length - 1) * 19 + 20, s.as, 'smAlt', 12, 16));
        }
      });
      ust += enYuksek + DIKEY;
    });

    // Oklar: ebeveyn altından çocuk üstüne. Yatay kayma varsa dirsekli.
    var oklar = [];
    baglar.forEach(function (b) {
      var a = yer[b[0]], c = yer[b[1]];
      if (!a || !c) return;
      var y1 = a.y + a.h, y2 = c.y - 6, orta = y1 + (y2 - y1) / 2;
      oklar.push(Math.abs(a.ox - c.ox) < 2
        ? '<line class="smOk" x1="' + a.ox + '" y1="' + y1 + '" x2="' + c.ox + '" y2="' + y2 + '" marker-end="url(#smOkBas)"/>'
        : '<path class="smOk" fill="none" d="M' + a.ox + ' ' + y1 + ' L' + a.ox + ' ' + orta +
          ' L' + c.ox + ' ' + orta + ' L' + c.ox + ' ' + y2 + '" marker-end="url(#smOkBas)"/>');
    });

    var alt = ust - DIKEY;

    /* ŞIK ŞEMADA YOK: en çok öğreten hâl. Öğrenci yanlış şıkkın nerede
       DURDUĞUNU değil, hiç OLMADIĞINI görür. Kesik çizgili kutu bilerek —
       "bu kanunun bir dalı değil" demenin görsel karşılığı. */
    if (isaret && isaret.dugum === 'yok') {
      var ys = satirla(isaret.notMetni || 'Bu şıkkın karşılığı kanunda yok.', GUVENLI - 44, 12, false);
      var yh = 22 + 19 + ys.length * 16;
      alt += DIKEY;
      parcalar.push('<rect class="smYok" x="' + KENAR + '" y="' + alt + '" width="' + GUVENLI + '" height="' + yh + '" rx="10"/>');
      parcalar.push(metinBlogu(W / 2, alt + 26, ['Senin cevabın: ' + (isaret.sik || '?')], 'smBas', 14, 19));
      parcalar.push(metinBlogu(W / 2, alt + 47, ys, 'smAlt', 12, 16));
      alt += yh;
    }
    return { govde: oklar.join('') + parcalar.join(''), alt: alt };
  }

  // -------------------------------------------------------------- FORMÜL
  /* yapi = { tip:'formul', pay, payda, sonuc, ornek:{pay,payda,sonuc}, not } */
  function formulCiz(y) {
    var p = [], ust = KENAR;
    var kutuX = 90, kutuG = 500;
    var payS   = satirla(y.pay,   kutuG - 40, 14, true);
    var paydaS = satirla(y.payda, kutuG - 40, 14, true);
    var h = 40 + payS.length * 19 + 18 + paydaS.length * 19 + 22;

    p.push('<rect class="smKutu" x="' + kutuX + '" y="' + ust + '" width="' + kutuG + '" height="' + h + '" rx="10"/>');
    p.push('<text class="smAlt" x="' + (kutuX + 20) + '" y="' + (ust + 24) + '">' + esc(y.sonuc || 'Sonuç') + ' =</text>');
    var payY = ust + 50;
    p.push(metinBlogu(kutuX + kutuG / 2, payY, payS, 'smBas', 14, 19));
    var cizgiY = payY + (payS.length - 1) * 19 + 12;
    p.push('<line class="smCizgi" x1="' + (kutuX + 60) + '" y1="' + cizgiY + '" x2="' + (kutuX + kutuG - 60) + '" y2="' + cizgiY + '"/>');
    p.push(metinBlogu(kutuX + kutuG / 2, cizgiY + 24, paydaS, 'smBas', 14, 19));
    ust += h + DIKEY;

    if (y.ornek) {
      var o = y.ornek, satir = o.pay + ' ÷ ' + o.payda + ' = ' + o.sonuc;
      var os = satirla(satir, kutuG - 40, 13, false);
      var oh = 20 + os.length * 18;
      p.push('<rect class="smSonuc" x="' + kutuX + '" y="' + ust + '" width="' + kutuG + '" height="' + oh + '" rx="10"/>');
      p.push(metinBlogu(kutuX + kutuG / 2, ust + 24, os, 'smBas', 13, 18));
      ust += oh + DIKEY;
    }
    if (y.not) {
      var ns = satirla(y.not, GUVENLI - 40, 12, false);
      var nh = 18 + ns.length * 16;
      p.push('<rect class="smKutu" x="' + KENAR + '" y="' + ust + '" width="' + GUVENLI + '" height="' + nh + '" rx="10"/>');
      p.push(metinBlogu(W / 2, ust + 22, ns, 'smAlt', 12, 16));
      ust += nh + DIKEY;
    }
    return { govde: p.join(''), alt: ust - DIKEY };
  }

  // -------------------------------------------------------------- ZİNCİR
  /* yapi = { tip:'zincir', adimlar:[{kod,ad}] } — THP hesap akışı gibi.
     Dört adımdan fazlası yan yana sığmaz; ikinci satıra alınır.            */
  function zincirCiz(y) {
    var adim = y.adimlar || [], p = [], ust = KENAR;
    var sutun = adim.length <= 3 ? adim.length : (adim.length <= 4 ? 4 : 3);
    var kutuG = Math.floor((GUVENLI - (sutun - 1) * 34) / sutun);
    var satirSay = Math.ceil(adim.length / sutun);

    for (var r = 0; r < satirSay; r++) {
      var dilim = adim.slice(r * sutun, (r + 1) * sutun);
      var enYuksek = 0, bilgi = [];
      dilim.forEach(function (a, i) {
        var as = satirla(a.ad, kutuG - 20, 12, false);
        var h = 46 + as.length * 15;
        if (h > enYuksek) enYuksek = h;
        bilgi.push({ a: a, as: as, x: KENAR + i * (kutuG + 34) });
      });
      bilgi.forEach(function (b, i) {
        p.push('<rect class="smKutu" x="' + b.x + '" y="' + ust + '" width="' + kutuG + '" height="' + enYuksek + '" rx="10"/>');
        p.push('<text class="smKod" x="' + (b.x + kutuG / 2) + '" y="' + (ust + 28) + '" text-anchor="middle">' + esc(b.a.kod) + '</text>');
        p.push(metinBlogu(b.x + kutuG / 2, ust + 46, b.as, 'smAlt', 12, 15));
        if (i < bilgi.length - 1) {
          var x1 = b.x + kutuG + 6, x2 = b.x + kutuG + 28, oy = ust + enYuksek / 2;
          p.push('<line class="smOk" x1="' + x1 + '" y1="' + oy + '" x2="' + x2 + '" y2="' + oy + '" marker-end="url(#smOkBas)"/>');
        }
      });
      ust += enYuksek + DIKEY;
    }
    return { govde: p.join(''), alt: ust - DIKEY };
  }

  // ---------------------------------------------------------------- DIŞ YÜZ
  var STIL =
    '.smKutu{fill:var(--panel2);stroke:var(--line2);stroke-width:.5}' +
    '.smSonuc{fill:var(--panel2);stroke:var(--accent2);stroke-width:1.2}' +
    /* Işaret siniflari: renk TEK BASINA ayirt edici degildir (renk korlugu +
       uc tema). Bu yuzden her biri ayrica CIZGI KALINLIGI/DESENIYLE de ayrilir. */
    '.smDogru{fill:var(--panel2);stroke:var(--green);stroke-width:2.4}' +
    '.smSecim{fill:var(--panel2);stroke:var(--red);stroke-width:2.4;stroke-dasharray:6 3}' +
    '.smYok{fill:var(--panel2);stroke:var(--red);stroke-width:1.2;stroke-dasharray:5 4}' +
    '.smBas{fill:var(--ink);font-size:14px;font-weight:600}' +
    '.smAlt{fill:var(--muted);font-size:12px;font-weight:400}' +
    '.smKod{fill:var(--accent2);font-size:15px;font-weight:800;font-family:var(--mono)}' +
    '.smOk{stroke:var(--line2);stroke-width:1.4;fill:none}' +
    '.smCizgi{stroke:var(--ink);stroke-width:1.2}' +
    '.smKay{fill:var(--dim);font-size:11.5px}';

  /* Şemayı çizer. Şema yoksa BOŞ döner - çağıran yer "şema yok" yazmaz,
     hiç göstermez (boş kutu göstermek kusurdur, 21.08 vitrin dersi). */
  /* isaret (istege bagli) = { sik:'A', dugum:'n5'|'yok', dogruDugum:'n3', notMetni:'...' }
     Semanin KENDISI degismez - yalniz uzerindeki vurgu degisir. Ayni sema
     bes sikta bes ayri gorunum verir, tek uretimle. */
  function ciz(sema, isaret) {
    if (!sema || !sema.yapi) return '';
    var y = typeof sema.yapi === 'string' ? JSON.parse(sema.yapi) : sema.yapi;
    var s;
    if (sema.tip === 'formul' || y.tip === 'formul') s = formulCiz(y);
    else if (sema.tip === 'zincir' || y.tip === 'zincir') s = zincirCiz(y);
    else s = akisCiz(y, isaret);
    if (!s || !s.govde) return '';

    var alt = s.alt;
    var kaynak = '';
    if (sema.dayanak) {
      var d = 'Dayanak: ' + sema.dayanak + (sema.son_kontrol ? ' · son teyit ' + sema.son_kontrol : '');
      kaynak = '<text class="smKay" x="' + (W / 2) + '" y="' + (alt + 26) + '" text-anchor="middle">' + esc(d) + '</text>';
      alt += 32;
    }
    var H = alt + 16;
    var baslik = esc(sema.baslik || 'Konu şeması');

    return '<div class="semaSar">' +
      '<div class="semaUst">' + baslik + '</div>' +
      '<svg width="100%" viewBox="0 0 ' + W + ' ' + H + '" role="img" xmlns="http://www.w3.org/2000/svg">' +
      '<title>' + baslik + '</title>' +
      '<style>' + STIL + '</style>' +
      '<defs><marker id="smOkBas" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">' +
      '<path d="M2 1L8 5L2 9" fill="none" stroke="context-stroke" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
      '</marker></defs>' +
      s.govde + kaynak +
      '</svg></div>';
  }

  global.Sema = { ciz: ciz };
})(window);
