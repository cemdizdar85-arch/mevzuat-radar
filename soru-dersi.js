/* soru-dersi.js — ÜYE SORU SAYFASINDA SESLİ NÖBETÇİ DERSİ (27.11.2026 prova)
 *
 * Cem 27.11: "provayı başlat, hazır soruları siteye al". Dersi yazılıp sesi basılmış soruda, cevaptan sonra
 * "Nöbetçi sesli anlatsın" düğmesi çıkar; ders 5 örnek soruda onaylanan ekranla (kaydir/vitrin/ornek-smmm-yeni.html)
 * tam ekran çerçevede açılır. Ders verisi ve ses paralı içeriktir: veri soru_dersi_getir (paket kapılı RPC), ses
 * cizim-ses-paket kovasından 30 dk'lık imzalı adresle gelir; bu dosyada ve ders sayfasında soru içeriği DURMAZ.
 * Yükleyen: paket-kapisi.js (yalnız /kaydir/smmm/ ders sayfaları). Dersi olmayan soruda hiçbir şey değişmez.
 * 🚫 GÖRMEZ: imzalı adres 30 dk boyunca adresi bilen herkese açıktır; ders dinleme kasa sayacına yazılmaz.
 */
(function () {
  if (window.__soruDersi) return; window.__soruDersi = true;
  var KOVA = 'cizim-ses-paket', MOTOR = '../vitrin/ornek-smmm-yeni.html?gom=1&uye=1';
  var VAR = null, kat = null, bekleyen = null;
  var css = document.createElement('style');
  css.textContent =
    '.sdKat{position:fixed;inset:0;z-index:9999;background:var(--bg);display:flex}' +
    '.sdKat iframe{border:0;width:100%;height:100%;flex:1}' +
    '.sdX{position:fixed;top:max(8px,env(safe-area-inset-top));right:8px;z-index:10000;width:44px;height:44px;border-radius:50%;border:0;background:var(--kart);color:var(--yazi);font:22px/1 system-ui,sans-serif;cursor:pointer;box-shadow:0 2px 8px color-mix(in srgb,var(--yazi) 30%,transparent)}' +
    '.sdBlok{display:flex;flex-direction:column;gap:8px;margin:10px 0;order:1}' +
    '.sdBlok button{min-height:48px;border-radius:12px;font:inherit;font-weight:800;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;padding:8px 12px;border:2px solid var(--mavi);background:color-mix(in srgb,var(--mavi) 10%,transparent);color:var(--mavi)}' +
    '.sdBlok button[disabled]{opacity:.6;cursor:progress}' +
    '.sdBlok small{font-weight:500;opacity:.8}' +
    '.sdNot{margin:0;font-size:.85em;color:var(--yazi);opacity:.8}';
  document.head.appendChild(css);

  function say(olay) { try { window.goatcounter && window.goatcounter.count && window.goatcounter.count({ path: 'soru-dersi/' + olay, title: olay, event: true }); } catch (e) {} }
  function kapat() { if (!kat) return; kat.remove(); kat = null; bekleyen = null; document.documentElement.style.overflow = ''; }
  function ac(soru, drs, sec) {
    kapat(); bekleyen = { tetikte: 'gom-ders', soru: soru, drs: drs };
    kat = document.createElement('div'); kat.className = 'sdKat'; kat.setAttribute('role', 'dialog'); kat.setAttribute('aria-modal', 'true');
    var f = document.createElement('iframe'); f.allow = 'autoplay'; f.title = 'Nöbetçi sesli anlatım'; f.src = MOTOR + (sec ? '&sec=' + sec : '');
    var x = document.createElement('button'); x.className = 'sdX'; x.type = 'button'; x.setAttribute('aria-label', 'Kapat'); x.textContent = '✕';
    x.addEventListener('click', kapat);
    kat.appendChild(f); kat.appendChild(x); document.body.appendChild(kat);
    document.documentElement.style.overflow = 'hidden';
  }
  window.addEventListener('message', function (e) {
    if (e.origin !== location.origin || !e.data || !kat) return;
    var f = kat.querySelector('iframe'); if (!f || e.source !== f.contentWindow) return;
    if (e.data.tetikte === 'gom-bekliyor' && bekleyen) { f.contentWindow.postMessage(bekleyen, location.origin); bekleyen = null; }
    if (e.data.tetikte === 'gom-kapat') kapat();
    if (e.data.tetikte === 'gom-hazir') { var x = kat.querySelector('.sdX'); if (x) x.hidden = true; }   /* dersin kendi ✕'i var */
  });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') kapat(); });

  function soruAl(k) { try { return SORULAR[+k.dataset.i] || null; } catch (e) { return null; } }
  function dersAc(k, q, dugme, not) {
    var sb = window.__pkSb; if (!sb) return;
    var kl = q.id.replace(/\//g, '__'), y = k.querySelector('.sik.yanlis'), sec = y ? y.dataset.h : '';
    dugme.disabled = true; not.textContent = '';
    Promise.all([sb.rpc('soru_dersi_getir', { p_id: q.id }), sb.storage.from(KOVA).createSignedUrls([kl + '/ders-oku.mp3', kl + '/ders-coz.mp3'], 1800)]).then(function (r) {
      dugme.disabled = false;
      var drs = r[0] && !r[0].error && r[0].data, u = (r[1] && !r[1].error && r[1].data) || [];
      if (!drs || !u[0] || !u[0].signedUrl || !u[1] || !u[1].signedUrl) { not.textContent = 'Ders şu an açılamadı. Biraz sonra yeniden dene.'; say('acilamadi'); return; }
      drs.yol = ''; drs.oku.ses = u[0].signedUrl; drs.coz.ses = u[1].signedUrl;
      ac({ id: q.id, ders: q.ders, konu: q.konu, soru: q.soru, siklar: q.siklar, dogru: q.dogru }, drs, sec); say('ac');
    }, function () { dugme.disabled = false; not.textContent = 'Ders şu an açılamadı. Bağlantını kontrol et.'; });
  }
  function kur() {
    if (!VAR) return;
    [].forEach.call(document.querySelectorAll('section.kart'), function (k) {
      if (k.querySelector('.sdBlok')) return;
      var q = soruAl(k); if (!q || !VAR[q.id]) return;
      var geri = k.querySelector('.panel .geri'); if (!geri) return;
      var blok = document.createElement('div'); blok.className = 'sdBlok';
      var b = document.createElement('button'); b.type = 'button';
      b.innerHTML = '<span aria-hidden="true">🔊</span><span>Nöbetçi sesli anlatsın <small>· soruyu okur, kâğıtta çözer</small></span>';
      var not = document.createElement('p'); not.className = 'sdNot'; not.setAttribute('role', 'status');
      b.addEventListener('click', function () { dersAc(k, q, b, not); });
      blok.appendChild(b); blok.appendChild(not); geri.parentNode.insertBefore(blok, geri.nextSibling);
    });
  }
  function listeAl(deneme) {
    var sb = window.__pkSb, sayfa = document.documentElement.getAttribute('data-kasa-sayfa');
    if (!sayfa) return;
    if (!sb || !sb.rpc) { if (deneme < 40) setTimeout(function () { listeAl(deneme + 1); }, 500); return; }
    sb.rpc('soru_dersi_liste', { p_sayfa: sayfa }).then(function (r) {
      var d = (r && !r.error && r.data) || []; if (!d.length) return;
      VAR = {}; d.forEach(function (id) { VAR[id] = 1; });
      kur();
      document.addEventListener('click', function () { setTimeout(kur, 60); setTimeout(kur, 600); }, true);
      new MutationObserver(kur).observe(document.getElementById('akis') || document.body, { childList: true, subtree: true });
    }, function () { });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { listeAl(0); }); else listeAl(0);
})();
