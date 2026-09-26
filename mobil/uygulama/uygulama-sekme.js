/* uygulama-sekme.js — ANA EKRANIN ALT SEKME ÇUBUĞU (26.09.2026, Cem "yap hepsini")
 *
 * Önce: giriş, sınavlar, paketler, ücretsiz, hatırlatıcı, hesap TEK uzun sayfada alt alta. Telefon
 * uygulamalarında alışılan düzen alt sekme çubuğu (Duolingo, Pocket Prep, UWorld): Sınavlar · Ücretsiz ·
 * Paketler · Hesap. Bölümlerin görünürlüğünü uygulama.js/magaza.js (hidden) yönetmeye DEVAM eder; bu dosya
 * yalnız "hangi sekmenin bölümleri ekranda" sorusunu çözer (body[data-sekme] + bölümlerin data-sekme'si).
 *   - Girişsizken "Sınavlar" sekmesi giriş formunu + ücretsiz soruları gösterir (ilk açılışta deneme yolu).
 *   - "Paketler" sekmesi yalnız mağaza bölümü açıkken görünür (magaza.js: Android / iPhone anahtarı).
 *   - index.html#paketler, #giris gibi bağlantılar ilgili sekmeyi açar (kilitli sınav perdesi bunları kullanır).
 */
(function () {
  var SEKMELER = [
    { id: 'sinav', ad: 'Sınavlar', ikon: '📚' },
    { id: 'ucretsiz', ad: 'Ücretsiz', ikon: '🎁' },
    { id: 'paket', ad: 'Paketler', ikon: '🛒' },
    { id: 'hesap', ad: 'Hesap', ikon: '👤' }
  ];
  var BOLUM = { giris: 'sinav hesap', ana: 'sinav', paketler: 'paket', ucretsiz: 'ucretsiz', hatirlatici: 'hesap', hesap: 'hesap' };
  var HASH = { '#paketler': 'paket', '#giris': 'sinav', '#ucretsiz': 'ucretsiz', '#hesap': 'hesap' };
  var ANAHTAR = 'tt_uyg_sekme';
  var body = document.body;

  Object.keys(BOLUM).forEach(function (id) { var el = document.getElementById(id); if (el) el.setAttribute('data-sekme', BOLUM[id]); });
  var alt = document.querySelector('footer.alt'); if (alt) alt.setAttribute('data-sekme', 'hesap');

  var ALT = 'max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px))';   // Capacitor 8 SystemBars + env()
  var st = document.createElement('style');
  st.textContent = [
    'body[data-sekme] main [data-sekme]{display:none}',
    'body[data-sekme=sinav] main [data-sekme~=sinav],body[data-sekme=ucretsiz] main [data-sekme~=ucretsiz],' +
    'body[data-sekme=paket] main [data-sekme~=paket],body[data-sekme=hesap] main [data-sekme~=hesap]{display:block}',
    /* girişsizken Sınavlar sekmesi ücretsiz soruları da gösterir */
    'body.girissiz[data-sekme=sinav] main #ucretsiz{display:block}',
    'main{padding-bottom:calc(84px + ' + ALT + ')!important}',
    '#sekmeCubugu{position:fixed;left:0;right:0;bottom:0;z-index:50;display:flex;justify-content:space-around;' +
    'background:var(--panel);border-top:1px solid var(--cizgi);padding:6px 4px calc(6px + ' + ALT + ')}',
    '#sekmeCubugu button{flex:1;background:none;border:0;color:var(--soluk);font:600 11.5px/1.2 inherit;padding:6px 2px;' +
    'display:flex;flex-direction:column;align-items:center;gap:3px;border-radius:12px}',
    '#sekmeCubugu button .i{font-size:20px;line-height:1;filter:grayscale(1);opacity:.7}',
    '#sekmeCubugu button[aria-selected=true]{color:var(--vurgu)}',
    '#sekmeCubugu button[aria-selected=true] .i{filter:none;opacity:1}'
  ].join('\n');
  document.head.appendChild(st);

  var cubuk = document.createElement('nav');
  cubuk.id = 'sekmeCubugu'; cubuk.setAttribute('role', 'tablist'); cubuk.setAttribute('aria-label', 'Ana bölümler');
  SEKMELER.forEach(function (s) {
    var b = document.createElement('button');
    b.type = 'button'; b.setAttribute('role', 'tab'); b.dataset.sekme = s.id;
    b.innerHTML = '<span class="i" aria-hidden="true">' + s.ikon + '</span>' + s.ad;
    b.addEventListener('click', function () { sec(s.id, true); });
    cubuk.appendChild(b);
  });
  body.appendChild(cubuk);

  function sec(id, dokunus) {
    var pb = cubuk.querySelector('[data-sekme=paket]');
    if (id === 'paket' && pb && pb.hidden) id = 'sinav';
    body.setAttribute('data-sekme', id);
    [].forEach.call(cubuk.children, function (b) { b.setAttribute('aria-selected', b.dataset.sekme === id ? 'true' : 'false'); });
    try { sessionStorage.setItem(ANAHTAR, id); } catch (e) {}
    if (dokunus) window.scrollTo(0, 0);
  }

  /* durum izleyici: giriş formu görünürse "girişsiz"; paket bölümü görünmüyorsa Paketler sekmesi gizli */
  function durumu() {
    var g = document.getElementById('giris'), p = document.getElementById('paketler');
    body.classList.toggle('girissiz', !!(g && !g.hidden));
    var pb = cubuk.querySelector('[data-sekme=paket]');
    if (pb) pb.hidden = !(p && !p.hidden);
    if (pb && pb.hidden && body.getAttribute('data-sekme') === 'paket') sec('sinav');
  }
  try {
    var mo = new MutationObserver(durumu);
    ['giris', 'paketler'].forEach(function (id) { var el = document.getElementById(id); if (el) mo.observe(el, { attributes: true, attributeFilter: ['hidden'] }); });
  } catch (e) {}

  var ilk = HASH[location.hash] || null;
  if (!ilk) { try { ilk = sessionStorage.getItem(ANAHTAR); } catch (e) {} }
  durumu();
  sec(ilk || 'sinav');
  /* magaza.js paket bölümünü sonradan açınca #paketler hedefi o sekmeye düşsün */
  if (location.hash === '#paketler') setTimeout(function () { durumu(); sec('paket'); }, 1500);
  window.addEventListener('hashchange', function () { if (HASH[location.hash]) sec(HASH[location.hash], true); });
})();
