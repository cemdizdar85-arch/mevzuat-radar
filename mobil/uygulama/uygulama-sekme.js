/* uygulama-sekme.js — ANA EKRANIN ALT SEKME ÇUBUĞU
 *
 * 26.09.2026 (2. sürüm, Cem "olsun"): Bugün · Sınavlar · Karnem · Hesap. Önceki düzendeki ayrı "Ücretsiz" ve
 * "Paketler" sekmeleri kaldırıldı — yurt dışındaki büyük uygulamaların hiçbirinde mağaza sekmesi yok (Pocket Prep:
 * Çalış · İstatistik · Ayarlar; Duolingo: Öğren · Pratik · Profil). Ücretsiz sorular ve kilitli dersler Sınavlar'da,
 * satın alma Hesap'ta ve kilitli derse dokununca. İkonlar ince çizgi SVG (index.html <symbol>), emoji YOK.
 *
 * Bölümler hangi sekmede: index.html'deki data-sekme (bugun · sinav · karne · hesap · yok). Görünürlüğü
 * (hidden) uygulama.js/magaza.js yönetmeye DEVAM eder; bu dosya yalnız "hangi sekme ekranda" sorusunu çözer.
 * Dış bağlantılar: index.html#paketler / #giris / #hesap → Hesap; #ucretsiz → Sınavlar (kilitli sınav perdesi).
 * window.TTSekme.sec(sekme, hedefBolumId) — diğer dosyalar sekme değiştirip bir bölüme kaydırır.
 */
(function () {
  var SEKMELER = [
    { id: 'bugun', ad: 'Bugün', ikon: 'bugun' },
    { id: 'sinav', ad: 'Sınavlar', ikon: 'sinav' },
    { id: 'karne', ad: 'Karnem', ikon: 'karne' },
    { id: 'hesap', ad: 'Hesap', ikon: 'hesap' }
  ];
  var HASH = { '#paketler': ['hesap', 'paketler'], '#giris': ['hesap', 'giris'], '#hesap': ['hesap'], '#ucretsiz': ['sinav'], '#karne': ['karne'] };
  var ANAHTAR = 'tt_uyg_sekme';
  var body = document.body;

  var ALT = 'max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px))';   // Capacitor 8 SystemBars + env()
  var st = document.createElement('style');
  st.textContent = [
    'body[data-sekme] main [data-sekme]{display:none}',
    'body[data-sekme=bugun] main [data-sekme=bugun],body[data-sekme=sinav] main [data-sekme=sinav],' +
    'body[data-sekme=karne] main [data-sekme=karne],body[data-sekme=hesap] main [data-sekme=hesap]{display:block}',
    'main{padding-bottom:calc(88px + ' + ALT + ')!important}',
    '#sekmeCubugu{position:fixed;left:0;right:0;bottom:0;z-index:50;display:flex;justify-content:space-around;' +
    'background:color-mix(in srgb,var(--taban) 88%,transparent);-webkit-backdrop-filter:blur(18px);backdrop-filter:blur(18px);' +
    'border-top:1px solid var(--cizgi);padding:4px 6px calc(4px + ' + ALT + ')}',
    '#sekmeCubugu button{position:relative;flex:1;background:none;border:0;color:var(--soluk);font:500 10.5px/1.2 inherit;letter-spacing:.02em;' +
    'padding:10px 2px 6px;display:flex;flex-direction:column;align-items:center;gap:5px}',
    '#sekmeCubugu svg{width:22px;height:22px;fill:none;stroke:currentColor;stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round}',
    '#sekmeCubugu button[aria-selected=true]{color:var(--yazi)}',
    /* etkin sekme: üstte kısa vurgu çizgisi */
    '#sekmeCubugu button[aria-selected=true]:before{content:"";position:absolute;top:-5px;left:50%;width:18px;height:2px;margin-left:-9px;background:var(--vurgu)}'
  ].join('\n');
  document.head.appendChild(st);

  var cubuk = document.createElement('nav');
  cubuk.id = 'sekmeCubugu'; cubuk.setAttribute('role', 'tablist'); cubuk.setAttribute('aria-label', 'Ana bölümler');
  SEKMELER.forEach(function (s) {
    var b = document.createElement('button');
    b.type = 'button'; b.setAttribute('role', 'tab'); b.dataset.sekme = s.id;
    b.innerHTML = '<svg aria-hidden="true"><use href="#i-' + s.ikon + '"/></svg>' + s.ad;
    b.addEventListener('click', function () { sec(s.id); });
    cubuk.appendChild(b);
  });
  body.appendChild(cubuk);

  function sec(id, hedef) {
    if (!SEKMELER.some(function (s) { return s.id === id; })) id = 'bugun';
    body.setAttribute('data-sekme', id);
    [].forEach.call(cubuk.children, function (b) { b.setAttribute('aria-selected', b.dataset.sekme === id ? 'true' : 'false'); });
    try { sessionStorage.setItem(ANAHTAR, id); } catch (e) {}
    var el = hedef && document.getElementById(hedef);
    if (el && !el.hidden) el.scrollIntoView({ block: 'start' });
    else window.scrollTo(0, 0);
  }
  window.TTSekme = { sec: sec };

  var h = HASH[location.hash], ilk = h ? h[0] : null;
  if (!ilk) { try { ilk = sessionStorage.getItem(ANAHTAR); } catch (e) {} }
  sec(ilk || 'bugun', h && h[1]);
  /* magaza.js paket bölümünü oturum okunduktan SONRA açar: #paketler hedefi o zaman kaydırılsın */
  if (h && h[1]) setTimeout(function () { sec(h[0], h[1]); }, 1500);
  window.addEventListener('hashchange', function () { var x = HASH[location.hash]; if (x) sec(x[0], x[1]); });
})();
