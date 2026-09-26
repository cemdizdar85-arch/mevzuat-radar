/* ilerleme.js — UYGULAMADAKİ ÇALIŞMA İLERLEMESİNİN TEK KAYDI (26.09.2026, Cem "eksiklerin hepsini yapalım")
 *
 * Kaydır-Çöz sayfası cevapları yalnız bellekte tutar (sayfa kapanınca gider) ve karta soru kimliği yazmaz.
 * Uygulamanın rakiplerde olan özellikleri (kaldığın yerden devam, bayrak, not, yanlışları tekrar, günlük
 * hedef + seri, ana ekran karnesi) bu kayda dayanır. Tek anahtar: localStorage "tt_ilerleme" (JSON).
 *   sid   = soru metninin kısa özeti (FNV-1a) → sayfa/sıra değişse de aynı soru aynı kimlik.
 *   cevap = { sid: { s: "ok"|"yan", t: ms, yol } }     son sonuç
 *   bayrak= { sid: { yol, i, t } }   not = { sid: { m: metin, yol, i, t } }
 *   konum = { yol: i }   son = { yol, i, t }   gun = { "YYYY-AA-GG": sayı }
 *   ayar  = { sinav: "sgs"|"yeterlilik", hedef: 10, yazi: 1, kurulum: true }
 * Hesaba eşitleme (telefon ↔ bilgisayar) B kümesi: bu nesne olduğu gibi sunucuya yazılacak (sade JSON).
 * BU DOSYA ŞUNU YAPMAZ: sunucuya bir şey göndermez; site sayfalarında yüklenmez.
 */
(function () {
  var ANAHTAR = 'tt_ilerleme';
  function bos() { return { surum: 1, cevap: {}, bayrak: {}, not: {}, konum: {}, son: null, gun: {}, ayar: { hedef: 10, yazi: 1 } }; }
  function oku() {
    try {
      var v = JSON.parse(localStorage.getItem(ANAHTAR) || 'null');
      if (!v || v.surum !== 1) return bos();
      var b = bos(); for (var k in b) if (v[k] === undefined) v[k] = b[k];
      return v;
    } catch (e) { return bos(); }
  }
  var veri = oku();
  function yaz() { veri.degisim = Date.now(); try { localStorage.setItem(ANAHTAR, JSON.stringify(veri)); } catch (e) {} }
  function bugun(ms) { var d = new Date(ms || Date.now()); return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2); }
  function sid(metin) {
    var s = String(metin || '').replace(/\s+/g, ' ').trim().slice(0, 400), h = 0x811c9dc5;
    for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = (h + ((h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24))) >>> 0; }
    return ('0000000' + h.toString(16)).slice(-8);
  }
  /* seri: bugünden (hedef tutmadıysa dünden) geriye, hedefi tutan ardışık gün sayısı */
  function seri() {
    var h = veri.ayar.hedef || 10, n = 0, d = new Date();
    if ((veri.gun[bugun()] || 0) < h) d.setDate(d.getDate() - 1);
    for (var k = 0; k < 400; k++) { if ((veri.gun[bugun(d.getTime())] || 0) >= h) { n++; d.setDate(d.getDate() - 1); } else break; }
    return n;
  }

  window.TTIlerleme = {
    sid: sid, bugun: bugun, seri: seri,
    veri: function () { return veri; },
    yenidenOku: function () { veri = oku(); return veri; },
    cevapla: function (s, dogru, yol) {
      var ilk = !veri.cevap[s] || veri.cevap[s].gun !== bugun();
      veri.cevap[s] = { s: dogru ? 'ok' : 'yan', t: Date.now(), gun: bugun(), yol: yol };
      if (ilk) veri.gun[bugun()] = (veri.gun[bugun()] || 0) + 1;
      yaz();
    },
    bayrakDegis: function (s, yol, i) { if (veri.bayrak[s]) delete veri.bayrak[s]; else veri.bayrak[s] = { yol: yol, i: i, t: Date.now() }; yaz(); return !!veri.bayrak[s]; },
    notYaz: function (s, metin, yol, i) { metin = String(metin || '').trim(); if (metin) veri.not[s] = { m: metin.slice(0, 2000), yol: yol, i: i, t: Date.now() }; else delete veri.not[s]; yaz(); },
    konumYaz: function (yol, i) { veri.konum[yol] = i; veri.son = { yol: yol, i: i, t: Date.now() }; yaz(); },
    ayarYaz: function (a) { for (var k in a) veri.ayar[k] = a[k]; yaz(); },
    /* bir sayfanın (dersin) sonuçları: { ok, yan } — ana ekran karnesi */
    dersSonucu: function (yol) {
      var ok = 0, yan = 0;
      for (var k in veri.cevap) { var c = veri.cevap[k]; if (c.yol === yol) { if (c.s === 'ok') ok++; else yan++; } }
      return { ok: ok, yan: yan };
    }
  };
})();
