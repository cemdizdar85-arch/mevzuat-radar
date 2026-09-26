/* ilerleme.js — UYGULAMADAKİ ÇALIŞMA İLERLEMESİNİN TEK KAYDI (26.09.2026, Cem "eksiklerin hepsini yapalım")
 *
 * Kaydır-Çöz sayfası cevapları yalnız bellekte tutar (sayfa kapanınca gider) ve karta soru kimliği yazmaz.
 * Uygulamanın rakiplerde olan özellikleri (kaldığın yerden devam, bayrak, not, yanlışları tekrar, günlük
 * hedef + seri, ana ekran karnesi) bu kayda dayanır. Tek anahtar: localStorage "tt_ilerleme" (JSON).
 *   sid   = soru metninin kısa özeti (FNV-1a) → sayfa/sıra değişse de aynı soru aynı kimlik.
 *   cevap = { sid: { s: "ok"|"yan", t: ms, gun, yol } }       son sonuç
 *   bayrak= { sid: { yol, i, t } | { yok: 1, t } }             yok = kaldırıldı (diğer cihaza da taşınsın)
 *   not   = { sid: { m: metin, yol, i, t } | { yok: 1, t } }
 *   konum = { yol: { i, t } }   son = { yol, i, t }   gun = { "YYYY-AA-GG": sayı }
 *   ayar  = { sinav, hedef, yazi, kurulum, t }
 *
 * HESABA EŞİTLEME (B kümesi): esitle(sb, userId) sunucudaki public.ogrenci_ilerleme satırıyla BİRLEŞTİRİR
 * (radar-app/sql/2026-09-26-ogrenci-ilerleme.sql): soru/bayrak/not/konum başına en yeni t kazanır, günlük
 * sayaçta büyük olan, ayarda en yeni. Birleşik sonuç iki tarafa yazılır; hiçbir taraf diğerini ezmez.
 * Tablo yoksa / ağ yoksa sessizce yerelde kalır. Birleştirme saf (birlestir) → mobil/ilerleme-sinavi.js ölçer.
 * BU DOSYA ŞUNU YAPMAZ: site sayfalarında yüklenmez (site aynı biçimi ayrı görevle kullanacak).
 */
(function (kok) {
  var ANAHTAR = 'tt_ilerleme';
  function bos() { return { surum: 1, cevap: {}, bayrak: {}, not: {}, konum: {}, son: null, gun: {}, ayar: { hedef: 10, yazi: 1, t: 0 } }; }
  function duzelt(v) {
    if (!v || v.surum !== 1) return bos();
    var b = bos(); for (var k in b) if (v[k] === undefined || v[k] === null && k !== 'son') v[k] = b[k];
    /* eski biçim: konum[yol] = sayı → { i, t: 0 } */
    for (var y in v.konum) if (typeof v.konum[y] === 'number') v.konum[y] = { i: v.konum[y], t: 0 };
    if (v.ayar.t === undefined) v.ayar.t = 0;
    return v;
  }
  function tt(x) { return x && x.t ? x.t : 0; }
  function enYeni(a, b) { return tt(b) > tt(a) ? b : a; }
  function haritaBirlestir(a, b) {
    var s = {}, k;
    for (k in a) s[k] = a[k];
    for (k in b) s[k] = k in s ? enYeni(s[k], b[k]) : b[k];
    return s;
  }
  /* SAF: iki kaydı birleştirir, hiçbirini değiştirmez */
  function birlestir(a, b) {
    a = duzelt(JSON.parse(JSON.stringify(a || {}))); b = duzelt(JSON.parse(JSON.stringify(b || {})));
    var g = {}, k;
    for (k in a.gun) g[k] = a.gun[k];
    for (k in b.gun) g[k] = Math.max(g[k] || 0, b.gun[k]);
    return {
      surum: 1,
      cevap: haritaBirlestir(a.cevap, b.cevap),
      bayrak: haritaBirlestir(a.bayrak, b.bayrak),
      not: haritaBirlestir(a.not, b.not),
      konum: haritaBirlestir(a.konum, b.konum),
      son: enYeni(a.son, b.son) || null,
      gun: g,
      ayar: tt(b.ayar) > tt(a.ayar) ? b.ayar : a.ayar
    };
  }
  /* anahtar sırasından bağımsız karşılaştırma (sıra farkı gereksiz sunucu yazımı doğurmasın) */
  function sirali(x) { if (Array.isArray(x)) return x.map(sirali); if (x && typeof x === 'object') { var o = {}; Object.keys(x).sort().forEach(function (k) { o[k] = sirali(x[k]); }); return o; } return x; }
  function ayni(a, b) { return JSON.stringify(sirali(a)) === JSON.stringify(sirali(b)); }

  if (!kok.localStorage && typeof module !== 'undefined') { module.exports = { birlestir: birlestir, duzelt: duzelt, ayni: ayni }; return; }

  function oku() { try { return duzelt(JSON.parse(localStorage.getItem(ANAHTAR) || 'null')); } catch (e) { return bos(); } }
  var veri = oku();
  function yaz() { try { localStorage.setItem(ANAHTAR, JSON.stringify(veri)); } catch (e) {} }
  function bugun(ms) { var d = new Date(ms || Date.now()); return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2); }
  function sid(metin) {
    var s = String(metin || '').replace(/\s+/g, ' ').trim().slice(0, 400), h = 0x811c9dc5;
    for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = (h + ((h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24))) >>> 0; }
    return ('0000000' + h.toString(16)).slice(-8);
  }
  function varMi(x) { return !!(x && !x.yok); }
  /* seri: bugünden (hedef tutmadıysa dünden) geriye, hedefi tutan ardışık gün sayısı */
  function seri() {
    var h = veri.ayar.hedef || 10, n = 0, d = new Date();
    if ((veri.gun[bugun()] || 0) < h) d.setDate(d.getDate() - 1);
    for (var k = 0; k < 400; k++) { if ((veri.gun[bugun(d.getTime())] || 0) >= h) { n++; d.setDate(d.getDate() - 1); } else break; }
    return n;
  }
  var esitleniyor = null;

  kok.TTIlerleme = {
    sid: sid, bugun: bugun, seri: seri, birlestir: birlestir,
    veri: function () { return veri; },
    yenidenOku: function () { veri = oku(); return veri; },
    bayrakVar: function (s) { return varMi(veri.bayrak[s]); },
    notu: function (s) { var n = veri.not[s]; return varMi(n) ? n : null; },
    cevapla: function (s, dogru, yol) {
      var ilk = !veri.cevap[s] || veri.cevap[s].gun !== bugun();
      veri.cevap[s] = { s: dogru ? 'ok' : 'yan', t: Date.now(), gun: bugun(), yol: yol };
      if (ilk) veri.gun[bugun()] = (veri.gun[bugun()] || 0) + 1;
      yaz();
    },
    bayrakDegis: function (s, yol, i) {
      var acik = !varMi(veri.bayrak[s]);
      veri.bayrak[s] = acik ? { yol: yol, i: i, t: Date.now() } : { yok: 1, t: Date.now() };
      yaz(); return acik;
    },
    notYaz: function (s, metin, yol, i) {
      metin = String(metin || '').trim();
      veri.not[s] = metin ? { m: metin.slice(0, 2000), yol: yol, i: i, t: Date.now() } : { yok: 1, t: Date.now() };
      yaz();
    },
    konumYaz: function (yol, i) { var t = Date.now(); veri.konum[yol] = { i: i, t: t }; veri.son = { yol: yol, i: i, t: t }; yaz(); },
    konumu: function (yol) { var k = veri.konum[yol]; return k ? k.i || 0 : 0; },
    ayarYaz: function (a) { for (var k in a) veri.ayar[k] = a[k]; veri.ayar.t = Date.now(); yaz(); },
    /* bir sayfanın (dersin) sonuçları: { ok, yan } — ana ekran karnesi */
    dersSonucu: function (yol) {
      var ok = 0, yan = 0;
      for (var k in veri.cevap) { var c = veri.cevap[k]; if (c.yol === yol) { if (c.s === 'ok') ok++; else yan++; } }
      return { ok: ok, yan: yan };
    },
    /* hesapla eşitle: döner Promise<"esit"|"guncellendi"|"yerel"> ("yerel" = sunucuya ulaşılamadı/tablo yok) */
    esitle: function (sb, userId) {
      if (!sb || !userId) return Promise.resolve('yerel');
      if (esitleniyor) return esitleniyor;
      esitleniyor = (async function () {
        try {
          var r = await sb.from('ogrenci_ilerleme').select('veri').eq('user_id', userId).maybeSingle();
          if (r.error) return 'yerel';
          var uzak = r.data ? r.data.veri : null;
          veri = oku();
          var birlesik = birlestir(veri, uzak);
          var yereldeDegisti = !ayni(birlesik, veri), uzaktaDegisti = !uzak || !ayni(birlesik, duzelt(uzak));
          if (yereldeDegisti) { veri = birlesik; yaz(); }
          if (uzaktaDegisti) {
            var w = await sb.from('ogrenci_ilerleme').upsert({ user_id: userId, veri: birlesik, degisim: Date.now(), guncelleme: new Date().toISOString() }, { onConflict: 'user_id' });
            if (w.error) return 'yerel';
          }
          return yereldeDegisti ? 'guncellendi' : 'esit';
        } catch (e) { return 'yerel'; }
        finally { esitleniyor = null; }
      })();
      return esitleniyor;
    }
  };
})(typeof window !== 'undefined' ? window : this);
