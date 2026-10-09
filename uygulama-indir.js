/* uygulama-indir.js — SİTEDEN MAĞAZA UYGULAMASINA BAĞLANTI (09.10.2026, Cem "yeni sürümü sunmak istiyorum, siteye koy, herkes görsün")
 *
 * Bağlantı: Google Play com.tetikte.app (09.10 anonim ölçüm: mağaza sayfası 200).
 * Görsel: sitenin CSP'si img-src 'self' — Google'ın rozet resmi dışarıdan bağlanamaz; resmi rozet dosyası depoya
 * indirilmedi (Cem onayı gerekir). Bu yüzden sitenin kendi düğme/bağlantı stiliyle "Google Play'den indir" yazısı.
 *   [data-uygulama]  iPhone/iPad'de GİZLENİR (App Store onayı yok, Apple incelemesi sürüyor). Android'de ve masaüstünde görünür.
 *   #uygSerit        yalnız Android telefonda; "×" ile kapatılınca bu cihazda bir daha çıkmaz (tt_uyg_serit).
 *   Sayaç: Play bağlantısına tıklama goatcounter 'uygulama/play' olayı.
 * BU DOSYA ŞUNU GÖRMEZ: App Store bağlantısı (onay gelince eklenecek) · iPadOS'u masaüstü Safari sanan eski sürümler (dokunma noktasıyla ayrılır).
 */
(function () {
  var ua = navigator.userAgent || '';
  var ios = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && (navigator.maxTouchPoints || 0) > 1);
  var android = /Android/i.test(ua);
  function uygula() {
    var liste = document.querySelectorAll('[data-uygulama]');
    for (var i = 0; i < liste.length; i++) liste[i].hidden = ios;
    var s = document.getElementById('uygSerit');
    if (s) {
      var kapali = false;
      try { kapali = localStorage.getItem('tt_uyg_serit') === '1'; } catch (e) {}
      s.hidden = !(android && !kapali);
      var k = s.querySelector('[data-kapat]');
      if (k) k.onclick = function () { s.hidden = true; try { localStorage.setItem('tt_uyg_serit', '1'); } catch (e) {} };
    }
    document.addEventListener('click', function (e) {
      var a = e.target && e.target.closest && e.target.closest('a[href*="play.google.com/store/apps"]');
      if (a && window.goatcounter && typeof window.goatcounter.count === 'function') {
        try { window.goatcounter.count({ path: 'uygulama/play', title: 'Google Play bağlantısı', event: true }); } catch (x) {}
      }
    }, true);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', uygula); else uygula();
})();
