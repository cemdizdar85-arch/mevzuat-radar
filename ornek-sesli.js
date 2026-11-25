/* ornek-sesli.js — 5 ÖRNEK SORUDA SESLİ ANLATIM (25.11.2026)
 *
 * Cem 25.11: "sitedeki örnek 5 soruyu önce sesli olarak değiştirelim; en son karar verdiğimiz şekil gibi,
 * hem tam konu hem eksik konu". Onaylı iki katman (22.11): (1) SORU DERSİ — Nöbetçi soruyu sesli okur,
 * kâğıtta çözer, eksik kavramı öğretir; (2) KONU DERSİ — konunun tamamı sesli.
 * Dersler kaydir/vitrin/ornek-smmm-yeni.html'de kayıtlı; bu dosya örnek soru sayfasında (ornek-smmm.html)
 * dersi olan sorulara düğme koyar ve dersi tam ekran çerçevede açar (?gom=1). Çerçeve dersi kapatınca kapanır;
 * ayrıca ✕ (yükleme sürerken) ve Esc. Kayıt yazmaz. Yükleyen: paket-kapisi.js (yalnız ornek-smmm sayfası).
 * Soru kimliği sayfada yoksa (robot örnek soruyu değiştirdiyse) düğme çıkmaz, sayfa eskisi gibi kalır.
 */
(function () {
  var DERS = {
    'smmm-4k-a-yfta-kolay-r6/kp-01':   { konu: 'konu/fta-faaliyet',          dk: '≈6 dk' },
    'smmm-4k-a-yvergi-cokzor-r2/kp-02': { konu: 'konu/vergi-gmsi',            dk: '≈5 dk' },
    'smmm-4k-a-fmuh-zor-r3/kp-02':     { konu: 'konu/fm-gelecek-donem',      dk: '≈6 dk' },
    'smmm-w3-maliyet-cokzor/kp-10':    { konu: 'konu/maliyet-gug-yukleme',   dk: '≈5 dk' }
  };
  var YOL = 'ornek-smmm-yeni.html?gom=1&';
  var css = document.createElement('style');
  css.textContent =
    '.osKat{position:fixed;inset:0;z-index:9999;background:var(--bg);display:flex}' +
    '.osKat iframe{border:0;width:100%;height:100%;flex:1}' +
    '.osX{position:fixed;top:max(8px,env(safe-area-inset-top));right:8px;z-index:10000;width:44px;height:44px;border-radius:50%;border:0;background:var(--kart);color:var(--yazi);font:22px/1 system-ui,sans-serif;cursor:pointer;box-shadow:0 2px 8px color-mix(in srgb,var(--yazi) 30%,transparent)}' +
    '.osKonu{display:flex;align-items:center;gap:8px;width:100%;min-height:44px;margin:0 0 10px;padding:8px 12px;border:1px solid var(--cizgi);border-radius:10px;background:var(--kart);color:var(--yazi);font:inherit;font-size:.92em;text-align:left;cursor:pointer}' +
    '.osKonu b{font-weight:800}' +
    '.osBlok{display:flex;flex-direction:column;gap:8px;margin:10px 0;order:1}' +
    '.osBlok button{min-height:48px;border-radius:12px;font:inherit;font-weight:800;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;padding:8px 12px}' +
    '.osBlok .osSes{border:2px solid var(--mavi);background:color-mix(in srgb,var(--mavi) 10%,transparent);color:var(--mavi)}' +
    '.osBlok .osKonuC{border:1px solid var(--cizgi);background:var(--kart);color:var(--yazi);font-weight:700}' +
    '.osBlok small{font-weight:500;opacity:.8}';
  document.head.appendChild(css);

  var kat = null;
  function kapat() {
    if (!kat) return; kat.remove(); kat = null; document.documentElement.style.overflow = '';
  }
  function ac(adres, olay) {
    kapat();
    kat = document.createElement('div'); kat.className = 'osKat'; kat.setAttribute('role', 'dialog'); kat.setAttribute('aria-modal', 'true');
    var f = document.createElement('iframe'); f.src = adres; f.allow = 'autoplay'; f.title = 'Nöbetçi sesli anlatım';
    var x = document.createElement('button'); x.className = 'osX'; x.type = 'button'; x.setAttribute('aria-label', 'Kapat'); x.textContent = '✕';
    x.addEventListener('click', kapat);
    kat.appendChild(f); kat.appendChild(x); document.body.appendChild(kat);
    document.documentElement.style.overflow = 'hidden';
    try { window.goatcounter && window.goatcounter.count && window.goatcounter.count({ path: 'ornek-sesli/' + olay, title: olay, event: true }); } catch (e) {}
  }
  window.addEventListener('message', function (e) {
    if (e.origin !== location.origin || !e.data || !kat) return;
    if (e.data.tetikte === 'gom-kapat') kapat();
    if (e.data.tetikte === 'gom-hazir') { var x = kat.querySelector('.osX'); if (x) x.hidden = true; }  /* dersin kendi ✕'i var; ikisi üst üste binmesin */
  });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') kapat(); });

  function soruId(k) {
    try { var s = SORULAR[+k.dataset.i]; return s && s.id; } catch (e) { return null; }
  }
  function konuDug(id, d) {
    var b = document.createElement('button'); b.type = 'button'; b.className = 'osKonu';
    b.innerHTML = '<span aria-hidden="true">🔊</span><span><b>Konuyu bilmiyor musun?</b> Konu anlatımını dinle · ' + d.dk + '</span>';
    b.addEventListener('click', function () { ac(YOL + 'konu=' + encodeURIComponent(d.konu), 'konu/' + d.konu.replace('konu/', '')); });
    return b;
  }
  function kur() {
    [].forEach.call(document.querySelectorAll('section.kart'), function (k) {
      var id = soruId(k), d = id && DERS[id]; if (!d) return;
      var g = k.querySelector('.govde'), soru = g && g.querySelector('p.soru');
      if (soru && !g.querySelector('.osKonu')) g.insertBefore(konuDug(id, d), soru);
      var c = k.querySelector('.cipler'), geri = k.querySelector('.panel .geri');
      if (c) [].forEach.call(c.querySelectorAll('button'), function (b) {   /* eski iki anlatım (sessiz tahta, çizerek çöz) yerine onaylı sesli ders; ikisi yan yana kafa karıştırır */
        if (b.classList.contains('bDers') || /sesli çözsün/.test(b.textContent)) b.style.display = 'none';
      });
      if (geri && !k.querySelector('.osBlok')) {
        var blok = document.createElement('div'); blok.className = 'osBlok';
        var s = document.createElement('button'); s.type = 'button'; s.className = 'osSes'; s.innerHTML = '<span aria-hidden="true">🔊</span><span>Nöbetçi sesli anlatsın <small>· soruyu okur, kâğıtta çözer</small></span>';
        s.addEventListener('click', function () {
          var y = k.querySelector('.sik.yanlis'); var sec = y ? y.dataset.h : '';
          ac(YOL + 'ders=' + encodeURIComponent(id) + (sec ? '&sec=' + sec : ''), 'ders/' + id);
        });
        var t = document.createElement('button'); t.type = 'button'; t.className = 'osKonuC'; t.innerHTML = '<span aria-hidden="true">📖</span><span>Konunun tamamını dinle <small>· ' + d.dk + '</small></span>';
        t.addEventListener('click', function () { ac(YOL + 'konu=' + encodeURIComponent(d.konu), 'konu/' + d.konu.replace('konu/', '')); });
        blok.appendChild(s); blok.appendChild(t); geri.parentNode.insertBefore(blok, geri.nextSibling);
      }
    });
  }
  function basla() { kur(); document.addEventListener('click', function () { setTimeout(kur, 60); setTimeout(kur, 600); }, true); var akis = document.getElementById('akis') || document.body; new MutationObserver(kur).observe(akis, { childList: true }); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', basla); else basla();
})();
