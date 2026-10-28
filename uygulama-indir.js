/* uygulama-indir.js — SİTEDEN MAĞAZA UYGULAMASINA BAĞLANTI (09.10.2026, Cem "yeni sürümü sunmak istiyorum, siteye koy, herkes görsün")
 *
 * 28.10.2026 Cem ("Apple ve Google'ın resmî Türkçe rozetlerini indir; alt bilgi, ana sayfa, Hesabım ve iPhone akıllı bandını kur"):
 * iOS uygulaması App Store'da YAYINDA (24.10, id6816072026) → iPhone'da gizleme kalktı, cihaza göre doğru mağaza gösterilir.
 * Rozetler RESMÎ dosyalar (gorsel/magaza/: Apple toolbox.marketingtools.apple.com tr-tr siyah SVG · Google Play tr_badge_web_generic.png),
 * depoda (CSP img-src 'self'). Rozet şekli değiştirilmez (Apple / Google rozet kuralları).
 *   [data-uyg="ios"]      Android telefonda gizlenir · [data-uyg="android"] iPhone/iPad'de gizlenir · bilgisayarda ikisi de görünür.
 *   #uygSerit             yalnız Android telefonda (iPhone'da Safari'nin kendi akıllı bandı var: <meta name="apple-itunes-app">);
 *                         "×" ile kapatılınca bu cihazda bir daha çıkmaz (tt_uyg_serit).
 *   Sayaç: goatcounter 'uygulama/play' ve 'uygulama/appstore' olayları.
 */
(function () {
  var ua = navigator.userAgent || '';
  var ios = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && (navigator.maxTouchPoints || 0) > 1);
  var android = /Android/i.test(ua);
  function uygula() {
    var liste = document.querySelectorAll('[data-uyg]');
    for (var i = 0; i < liste.length; i++) {
      var t = liste[i].getAttribute('data-uyg');
      liste[i].hidden = (t === 'ios' && android) || (t === 'android' && ios);
    }
    var s = document.getElementById('uygSerit');
    if (s) {
      var kapali = false;
      try { kapali = localStorage.getItem('tt_uyg_serit') === '1'; } catch (e) {}
      s.hidden = !(android && !kapali);
      var k = s.querySelector('[data-kapat]');
      if (k) k.onclick = function () { s.hidden = true; try { localStorage.setItem('tt_uyg_serit', '1'); } catch (e) {} };
    }
  }
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('a[href*="play.google.com/store/apps"],a[href*="apps.apple.com/"]');
    if (a && window.goatcounter && typeof window.goatcounter.count === 'function') {
      var apple = /apps\.apple\.com/.test(a.href);
      try { window.goatcounter.count({ path: apple ? 'uygulama/appstore' : 'uygulama/play', title: apple ? 'App Store bağlantısı' : 'Google Play bağlantısı', event: true }); } catch (x) {}
    }
  }, true);
  window.ttUygulamaUygula = uygula;   /* menu.js altbilgi rozetlerini sonradan ekler → yeniden uygular */
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', uygula); else uygula();
})();
