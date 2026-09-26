/* uygulama-odeme.js — ÖDEME SAYFASI (26.09.2026, Cem "tüm uygulamayı incele, rakipsiz yap")
 *
 * Kilitli bir şeye dokunan girişli ama paketsiz kişi eskiden Hesap sekmesindeki düz ürün listesine atılıyordu.
 * Satışın olduğu an uygulamanın en sıradan ekranıydı. Şimdi alttan açılan tam sayfa: lacivert başlık, paketin
 * kazandırdıkları, YALNIZ seçili sınavın paketleri (fiyat mağazadan — magaza.js), yasal not.
 * Ürün satırları ve satın alma akışı magaza.js'in #paketler bölümüdür: sayfa açılınca bölüm buraya TAŞINIR,
 * kapanınca yerine döner (tek satın alma kodu, iki görünüm).
 * APPLE KURALI: satış kapalı cihazda (iPhone iosSatis false) bu sayfa AÇILMAZ; çağıran eski yola düşer.
 * BU DOSYA ŞUNU YAPMAZ: fiyat yazmaz · satın alma yapmaz · sayı uydurmaz.
 */
(function () {
  var K = window.TT_KATALOG || {}, IL = window.TTIlerleme;
  function $(id) { return document.getElementById(id); }
  var AD = { sgs: 'SGS · Staja Giriş', yeterlilik: 'SMMM Yeterlilik (Bitirme)' };
  var KAZANC = [
    ['Tüm derslerin soruları', 'Her soruda tuzağın adı, doğrusu ve kanun maddesi'],
    ['Kısa sınav ve en çok çıkanlar', 'Süreli karışık sınav, çıkmış dönemlere göre seçilmiş sorular'],
    ['Tuzak ve konu haritası', 'Hangi tuzağa düştüğünü ve zayıf konunu karnende gör'],
    ['Her yerde, internetsiz', 'Dersleri telefona indir; ilerlemen tüm cihazlarında aynı']
  ];
  var st = document.createElement('style');
  st.textContent = [
    '#odeme{position:fixed;inset:0;z-index:110;background:rgba(0,0,0,.5);display:flex;align-items:flex-end}',
    '#odeme .ic{width:100%;max-height:94%;overflow-y:auto;background:radial-gradient(120% 360px at 50% -40px,var(--aura),transparent 70%) no-repeat,var(--taban);border-radius:28px 28px 0 0;animation:odemeGel .42s cubic-bezier(.2,1.1,.3,1)}',
    '@keyframes odemeGel{from{transform:translateY(60px);opacity:.3}to{transform:none;opacity:1}}',
    '#odeme .oUst{position:relative;color:var(--yazi);padding:26px 22px 8px}',
    '#odeme .kapat{position:absolute;right:14px;top:14px;width:34px;height:34px;border-radius:50%;border:0;background:rgba(127,127,127,.16);color:var(--yazi);font:400 20px/1 inherit}',
    '#odeme .etk{font-size:12px!important;letter-spacing:.06em!important;text-transform:uppercase!important;font-weight:600!important;color:var(--vurgu)!important;margin:0 0 8px!important}',
    '#odeme h1{font-size:34px;line-height:1.04;margin:0 0 8px}',
    '#odeme .oUst p{margin:0;color:var(--soluk);font-size:15.5px}',
    '#odeme .govde{position:relative;z-index:1;padding:0 16px calc(20px + max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px)));margin-top:16px}',
    '#odeme .kazanc{background:var(--panel);border-radius:22px;box-shadow:var(--golge);padding:6px 18px}',
    '#odeme .kazanc div{display:flex;gap:12px;padding:12px 0;border-top:1px solid var(--cizgi)}',
    '#odeme .kazanc div:first-child{border-top:0}',
    '#odeme .kazanc i{flex:none;width:22px;height:22px;border-radius:50%;background:#f5a524;display:grid;place-items:center;margin-top:1px}',
    '#odeme .kazanc i:after{content:"";width:9px;height:5px;border:2px solid #0b0b0c;border-top:0;border-right:0;transform:rotate(-45deg) translate(1px,-1px)}',
    '#odeme .kazanc b{display:block;font-size:15px;font-weight:600}',
    '#odeme .kazanc span{display:block;font-size:13px;color:var(--soluk);margin-top:1px}',
    '#odeme #paketler{margin-top:18px}',
    '#odeme #paketler>.etk{color:var(--soluk)}',
    '#odeme .urun[data-sinav]:not(.buSinav){display:none!important}',
    '#odeme .urun{min-height:72px}',
    '#odeme .urun .ad{font-size:15.5px}',
    '#odeme .urun .al{background:var(--zit);color:var(--zitYazi);padding:11px 18px;border-radius:999px;font-weight:600}',
    '#odeme .yasal{margin:14px 4px 0;font-size:12px;color:var(--soluk);line-height:1.5}'
  ].join('\n');
  document.head.appendChild(st);

  function secili() { return (IL && IL.veri().ayar.sinav) === 'sgs' ? 'sgs' : 'yeterlilik'; }
  var yer = null;   /* #paketler'in asıl yeri */
  function ac(sinav) {
    var p = $('paketler');
    if (!p || p.hidden) return false;   /* satış bu cihazda/oturumda kapalı → çağıran eski yola düşer */
    sinav = sinav || secili();
    kapat();
    var e = document.createElement('div'); e.id = 'odeme'; e.setAttribute('role', 'dialog'); e.setAttribute('aria-label', 'Tam paket');
    e.innerHTML = '<div class="ic"><div class="oUst"><button type="button" class="kapat" aria-label="Kapat">×</button>' +
      '<span class="etk">Tam paket · ' + AD[sinav] + '</span><h1>Sınavına tam hazırlan.</h1><p>Sınavına kadar erişim. Tek ödeme, abonelik yok.</p></div>' +
      '<div class="govde"><div class="kazanc">' + KAZANC.map(function (k) { return '<div><i></i><span><b>' + k[0] + '</b><span>' + k[1] + '</span></span></div>'; }).join('') +
      '</div><div id="odemeYuva"></div><p class="yasal">Ödeme ' + ((window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform() === 'ios') ? 'App Store' : 'Google Play') +
      ' üzerinden alınır; paket hesabına hemen tanımlanır. Satın alma koşulları: üyelik sözleşmesi ve mesafeli satış bilgileri.</p></div></div>';
    document.body.appendChild(e);
    yer = { ebeveyn: p.parentNode, sonraki: p.nextSibling };
    e.querySelector('#odemeYuva').appendChild(p);
    [].forEach.call(p.querySelectorAll('.urun'), function (u) { u.classList.toggle('buSinav', u.getAttribute('data-sinav') === sinav); });
    e.addEventListener('click', function (ev) { if (ev.target === e || ev.target.classList.contains('kapat')) kapat(); });
    if (window.TTOlay) window.TTOlay.say('paket_ekrani');
    return true;
  }
  function kapat() {
    var e = $('odeme'); if (!e) return;
    var p = $('paketler');
    if (p && yer) yer.ebeveyn.insertBefore(p, yer.sonraki);
    e.remove(); yer = null;
  }
  window.TTOdeme = { ac: ac, kapat: kapat };

  /* soru sayfasındaki ara karneden "Tam paketi incele" ile gelindiyse: paket bölümü açılınca sayfayı aç */
  var iste = null; try { iste = sessionStorage.getItem('tt_uyg_odeme'); sessionStorage.removeItem('tt_uyg_odeme'); } catch (x) {}
  if (iste) {
    var dene = 0, zam = setInterval(function () { if (ac(iste) || ++dene > 20) clearInterval(zam); }, 300);
  }
})();
