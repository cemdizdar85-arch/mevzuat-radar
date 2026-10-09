/* uygulama-sayfa.js — UYGULAMAYA GÖMÜLEN SİTE SAYFASININ KÖPRÜSÜ (09.10.2026, Cem "1.8 seviyesini koy · siteye aynıları olsun")
 *
 * Kaydır-Çöz kabukları dışında kalan site sayfaları (bugün: seviye-testi.html) uygulamaya mobil/hazirla.js
 * "2b. site sayfaları" bölümüyle girer. Derleme sayfadan site menüsünü, fiyat motorunu, üye-durumu betiğini,
 * sayacı ve satış bağlarını söker; bu dosya sayfanın o betiklerden beklediği ÜÇ şeyi uygulamanın kendi
 * ayağından (ortak.js) verir:
 *   1. window.__pkSb          — Supabase istemcisi (kutu-esitle.js, sayfa betiği hesaba yazarken kullanır)
 *   2. window.TetikteUye      — { hazir: Promise<{oturum, sinavlar:{sgs:{durum}, yeterlilik:{durum}}}>, onbellek }
 *                               uye-durumu.js'in sayfanın okuduğu kadarı: paket sahibi 'aktif', üye 'uye', yoksa 'ziyaretci'
 *   3. sol üstte "‹" dönüş düğmesi (uygulama-kapisi.js ile aynı; iOS'ta geri hareketi yok)
 * APPLE 3.1.1 / 2.1: iPhone'da satış kapalıyken (ortak.js yalnizUcretsiz) paket çağrısı taşıyan öğeler gizlenir:
 *   derlemede satış bağları "index.html#paketler"e çevrilir; burada o bağı taşıyan her <a> ve [data-tt-satis] kaldırılır
 *   (gözlemci: sonradan çizilen Nöbetçi oynatıcısı düğmesi dahil).
 * BU DOSYA ŞUNU GÖRMEZ: bağlantısız metin olarak "paket al" cümlesi (hazirla.js KAPI-SATIS derlemede tarar).
 */
(function () {
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/uygulama-sayfa\.js.*$/, '') : '';
  var TT = window.TT;

  var st = document.createElement('style');
  st.textContent =
    '#ttGeri{position:fixed;z-index:2147482000;left:calc(10px + env(safe-area-inset-left));top:calc(10px + env(safe-area-inset-top));' +
    'padding:7px 12px;border-radius:999px;font:700 13px/1.2 -apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;text-decoration:none;' +
    'background:var(--panel,var(--kart));color:var(--ink,var(--yazi));border:1px solid var(--line,var(--cizgi))}' +
    'body{padding-top:calc(34px + env(safe-area-inset-top))}';
  (document.head || document.documentElement).appendChild(st);

  function geriDugmesi() {
    var ciz = function () {
      if (document.getElementById('ttGeri')) return;
      var a = document.createElement('a');
      a.id = 'ttGeri'; a.href = KOK + 'index.html'; a.textContent = '‹';
      a.setAttribute('aria-label', 'Uygulamaya dön');
      document.body.appendChild(a);
    };
    if (document.body) ciz(); else document.addEventListener('DOMContentLoaded', ciz);
  }
  geriDugmesi();

  /* 1. istemci */
  var sb = null;
  try { sb = TT ? TT.istemci() : null; } catch (e) { sb = null; }
  if (sb && !window.__pkSb) window.__pkSb = sb;

  /* 2. üye durumu (uye-durumu.js'in sayfanın okuduğu alanları) */
  function bos() { return { oturum: null, sinavlar: { sgs: { durum: 'ziyaretci' }, yeterlilik: { durum: 'ziyaretci' }, kgk: { durum: 'ziyaretci' } } }; }
  var hazir = (async function () {
    if (!sb || !TT) return bos();
    var k = await TT.kullanici(sb);
    if (!k) return bos();
    var satir = [];
    try { satir = (await TT.paketler(sb, k.id)).satir || []; } catch (e) { satir = []; }
    var d = { oturum: { user: { id: k.id, email: k.email } }, sinavlar: {} };
    ['sgs', 'yeterlilik', 'kgk'].forEach(function (s) { d.sinavlar[s] = { durum: TT.acarMi(satir, s) ? 'aktif' : 'uye' }; });
    return d;
  })();
  if (!window.TetikteUye) window.TetikteUye = { hazir: hazir, onbellek: null };

  /* 3. iPhone'da satış çağrısı yok */
  function satisSok(kapsam) {
    if (!(TT && TT.yalnizUcretsiz && TT.yalnizUcretsiz())) return;
    var liste = (kapsam && kapsam.querySelectorAll ? kapsam : document).querySelectorAll('a[href*="#paketler"],[data-tt-satis]');
    for (var i = 0; i < liste.length; i++) { var e = liste[i]; if (e.parentNode) e.parentNode.removeChild(e); }
  }
  function gozlemci() {
    satisSok(document);
    try {
      new MutationObserver(function (kayitlar) {
        for (var i = 0; i < kayitlar.length; i++) {
          var ek = kayitlar[i].addedNodes;
          for (var j = 0; j < ek.length; j++) if (ek[j].nodeType === 1) satisSok(ek[j]);
        }
      }).observe(document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
  }
  if (document.body) gozlemci(); else document.addEventListener('DOMContentLoaded', gozlemci);
})();
