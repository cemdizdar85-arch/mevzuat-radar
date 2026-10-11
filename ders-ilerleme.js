/* ders-ilerleme.js — YETERLİLİK DERS İLERLEMESİ (11.10.2026, Cem "öğrencinin yanında olalım" + "sorular bitti mi, yine aynı
 * sorular geliyor demesin"). sinav-gibi.html (sana özel deneme, ilerleme satırı) ve sorular.html (karşılama kartı) AYNI sayımı
 * kullansın diye tek dosya.
 *
 * HAVUZ   : veri/deneme/smmm-ders-havuz.json (motor/sik-konu-deneme-bas.js) — dersin sitedeki TÜM soruları, yalnız kimlik,
 *           son 10 yılda sık sorulan konu önde ağırlıklı sıra.
 * GÖRÜLEN : ders sayfalarının son 500 cevabı (kc_kayit, hesaba eşitlenir) + yanlış kutusu (kc_kutu) + deneme sayfasındaki
 *           bütün denemeler (sg_smmm_*: cevaplar + açılan setin kimlikleri). Değer = son görülme zamanı (ms).
 * 🚫 GÖRMEZ: son 500'den eski ders sayfası cevabı · başka cihazda çözülüp bu cihazda ders sayfası hiç açılmamış soru ·
 *           11.10 öncesi açılmış deneme setlerinde cevaplanmamış soru (kimlik listesi o günden beri yazılır).
 */
(function () {
  if (window.ttDersIlerleme) return;
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/ders-ilerleme\.js.*$/, '') : '';
  var HAVUZ = null, bekleyen = null;
  function trk(s) { return String(s || '').toLocaleLowerCase('tr-TR').replace(/\s+/g, ' ').trim(); }
  function havuzAl() {
    if (HAVUZ) return Promise.resolve(HAVUZ);
    if (bekleyen) return bekleyen;
    bekleyen = fetch(KOK + 'veri/deneme/smmm-ders-havuz.json', { cache: 'no-store' })
      .then(function (y) { return y.ok ? y.json() : null; })
      .then(function (d) { HAVUZ = d && d.dersler ? d : null; bekleyen = null; return HAVUZ; })
      .catch(function () { bekleyen = null; return null; });
    return bekleyen;
  }
  function oku(k, v) { try { var x = JSON.parse(localStorage.getItem(k) || 'null'); return x == null ? v : x; } catch (e) { return v; } }
  function gorulen() {
    var g = {};
    function ek(id, t) { id = String(id); t = +t || 1; if (!g[id] || g[id] < t) g[id] = t; }
    (oku('kc_kayit', []) || []).forEach(function (x) { if (x && x.id != null) ek(x.id, x.t); });
    (oku('kc_kutu', []) || []).forEach(function (x) { if (x && x.id != null) ek(x.id, 1); });
    try {
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i); if (!/^sg_smmm_/.test(k)) continue;
        var d = oku(k, null); if (!d || typeof d !== 'object') continue;
        var t = Date.parse(d.bitis || d.basla || '') || 1;
        Object.keys(d.cevap || {}).forEach(function (id) { ek(id, t); });
        (d.ids || []).forEach(function (id) { ek(id, t); });
      }
    } catch (e) {}
    return g;
  }
  /* havuz yüklüyse: {ad, h} (h = {sayfa, soru, konular, sorular:[[id, konuSira, sayfaSira]]}) */
  function ders(ad) {
    if (!HAVUZ) return null;
    var k = Object.keys(HAVUZ.dersler).filter(function (x) { return trk(x) === trk(ad); })[0];
    return k ? { ad: k, h: HAVUZ.dersler[k] } : null;
  }
  function ilerleme(ad, g) {
    var hd = ders(ad); if (!hd) return null; g = g || gorulen(); var gor = 0;
    hd.h.sorular.forEach(function (r) { if (g[String(r[0])]) gor++; });
    return { ad: hd.ad, toplam: hd.h.soru, gor: gor, yeni: hd.h.soru - gor, sayfa: hd.h.sayfa };
  }
  window.ttDersIlerleme = { havuzAl: havuzAl, gorulen: gorulen, ders: ders, ilerleme: ilerleme, trk: trk };
})();
