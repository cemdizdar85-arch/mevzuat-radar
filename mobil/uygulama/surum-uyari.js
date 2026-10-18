/* surum-uyari.js — "YENİ SÜRÜM HAZIR" ŞERİDİ (18.10.2026, Cem: "güncelleme geldiğinde kullanan kişi görüyor mu güncellemesi gerektiğini" → "evet yap")
 *
 * Açılışta sitedeki tek dosyayı okur: veri/uygulama-surum.json (ortak.js /veri/ isteğini tetikte.com'a yönlendirir).
 *   { "android": { "son": "1.8.7", "en_dusuk": "1.8.0", "magaza": "https://play.google.com/…", "not": "…" }, "ios": { … } }
 *   son      = mağazada YAYINDA olan en yeni sürüm. ⚠ Mağazada yayınlanmadan YÜKSELTİLMEZ (yoksa kullanıcı "güncelle" görür ama
 *              mağazada güncelleme yoktur). Sıra: mağaza yayınla → bu dosyada "son"u yükselt.
 *   en_dusuk = bunun altındaki sürüm "kritik" uyarı görür (kırmızı şerit, her açılışta yeniden çıkar; ✕ yine kapatır - kural:
 *              her bildirim ✕ ile kapanır, kullanıcı kilitlenmez).
 * Uygulamanın sürümü: window.TT_KATALOG.surum (hazirla.js, mobil/package.json "version").
 * Normal uyarı ✕ ile kapatılınca o sürüm için bu cihazda bir daha çıkmaz (tt_surum_kapat = <son>).
 * Çevrimdışı / dosya yok / sürüm bilinmiyor → hiçbir şey çizilmez (sessiz).
 * BU DOSYA ŞUNU GÖRMEZ: mağazanın gerçek yayın durumu (yalnız sitedeki dosyaya güvenir) · iOS App Store bağlantısı yayında değilse açılan sayfa.
 */
(function () {
  'use strict';
  function parca(s) { return String(s || '').split('.').map(function (x) { return parseInt(x, 10) || 0; }); }
  /* a < b ise -1, eşitse 0, büyükse 1 */
  function kiyasla(a, b) { var x = parca(a), y = parca(b); for (var i = 0; i < Math.max(x.length, y.length); i++) { var d = (x[i] || 0) - (y[i] || 0); if (d) return d < 0 ? -1 : 1; } return 0; }
  window.TTSurumKiyas = kiyasla;   /* öz-sınav için */
  function platform() { try { return window.Capacitor && window.Capacitor.getPlatform ? window.Capacitor.getPlatform() : 'web'; } catch (e) { return 'web'; } }
  function ac(url) {
    try { var B = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Browser; if (B && B.open) { B.open({ url: url }); return; } } catch (e) {}
    try { window.open(url, '_blank'); } catch (e) {}
  }
  function ciz(bilgi, kritik, son) {
    if (document.getElementById('ttSurum')) return;
    var d = document.createElement('div'); d.id = 'ttSurum'; d.setAttribute('role', 'status');
    d.style.cssText = 'position:fixed;left:10px;right:10px;top:calc(env(safe-area-inset-top,0px) + 8px);z-index:2147483000;display:flex;align-items:center;gap:10px;'
      + 'padding:10px 8px 10px 14px;border-radius:14px;box-shadow:0 10px 30px rgba(0,0,0,.18);font:600 14px/1.35 system-ui,-apple-system,"Segoe UI",sans-serif;'
      + (kritik ? 'background:#b91c1c;color:#fff' : 'background:var(--vurguDolgu);color:#1b1206');
    d.innerHTML = '<span style="flex:1;min-width:0">' + (kritik ? '⚠️ <b>Güncelleme gerekli.</b> ' : '🎉 <b>Yeni sürüm hazır.</b> ')
      + (bilgi.not ? String(bilgi.not).replace(/[<>&]/g, '') : 'Yeni özellikler için uygulamayı güncelle.') + '</span>'
      + '<button type="button" id="ttSurumAl" style="flex:none;min-height:44px;padding:0 14px;border:0;border-radius:10px;font:800 14px system-ui,sans-serif;'
      + (kritik ? 'background:#fff;color:#b91c1c' : 'background:#1b1206;color:#fff') + '">Güncelle</button>'
      + '<button type="button" id="ttSurumX" aria-label="Kapat" style="flex:none;width:44px;height:44px;border:0;border-radius:10px;background:transparent;color:inherit;font-size:18px">✕</button>';
    document.body.appendChild(d);
    d.querySelector('#ttSurumAl').addEventListener('click', function () { if (bilgi.magaza) ac(bilgi.magaza); });
    d.querySelector('#ttSurumX').addEventListener('click', function () {
      if (!kritik) { try { localStorage.setItem('tt_surum_kapat', son); } catch (e) {} }
      d.remove();
    });
  }
  function bak() {
    var p = platform(); if (p !== 'android' && p !== 'ios') return;
    var bu = window.TT_KATALOG && window.TT_KATALOG.surum; if (!bu) return;
    fetch('veri/uygulama-surum.json', { cache: 'no-store' }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
      var b = j && j[p]; if (!b || !b.son) return;
      var kritik = !!(b.en_dusuk && kiyasla(bu, b.en_dusuk) < 0);
      if (!kritik && kiyasla(bu, b.son) >= 0) return;   /* güncel */
      var kapali = null; try { kapali = localStorage.getItem('tt_surum_kapat'); } catch (e) {}
      if (!kritik && kapali === b.son) return;           /* bu sürüm için kapatılmış */
      ciz(b, kritik, b.son);
    }).catch(function () {});
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { setTimeout(bak, 1500); });
  else setTimeout(bak, 1500);
})();
