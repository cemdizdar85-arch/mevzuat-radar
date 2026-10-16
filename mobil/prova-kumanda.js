/* PROVA KUMANDASI — YALNIZ iOS simülatör provası derlemesine girer (prova-kumanda-kur.js ekler; mağaza derlemesinde YOK).
 * 16.10.2026: Appium'un Safari denetleyici köprüsü iOS 18.6 simülatöründe WebView'i görmedi (koşu 38835785529:
 * bağlamlar yalnız NATIVE_APP). Bu betik her sayfanın başında açılır, Mac'teki prova sunucusundan (cihaz-akis-ios.js,
 * 127.0.0.1:8777) JS ifadesi alır, sonucu geri yollar; JS hatalarını sayfa açıldığı andan itibaren sunucuya bildirir. */
(function () {
  'use strict';
  var U = 'http://127.0.0.1:8777';
  function yolla(yol, veri) {
    try { return fetch(U + yol, { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: JSON.stringify(veri) }); } catch (e) { return Promise.resolve(); }
  }
  window.addEventListener('error', function (e) { yolla('/hata', { h: String(e.message || e).slice(0, 160), s: location.pathname }); });
  window.addEventListener('unhandledrejection', function (e) { yolla('/hata', { h: String(e.reason && e.reason.message || e.reason).slice(0, 160), s: location.pathname }); });
  /* dokunuş sayacı: prova her gerçek dokunuştan sonra bakar → dokunuş sayfaya ULAŞTI mı (araç mı uygulama mı ayrımı) */
  window.__ttDok = 0;
  ['touchstart', 'pointerdown', 'click'].forEach(function (t) { window.addEventListener(t, function () { window.__ttDok++; }, true); });
  var sayfa = Math.random().toString(36).slice(2);
  function dongu() {
    fetch(U + '/al?s=' + sayfa, { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (k) {
      if (!k || !k.id) { setTimeout(dongu, 50); return; }
      Promise.resolve().then(function () { return (0, eval)('(' + k.ifade + ')'); })
        .then(function (v) { return { id: k.id, v: v === undefined ? null : v }; }, function (e) { return { id: k.id, h: String(e && e.message || e) }; })
        .then(function (s) { return yolla('/ver', s); })
        .then(function () { setTimeout(dongu, 0); }, function () { setTimeout(dongu, 200); });
    }, function () { setTimeout(dongu, 500); });
  }
  dongu();
})();
