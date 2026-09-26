/* uygulama-sinavlar.js — "SINAVLAR" SEKMESİ (26.09.2026, Cem "kur")
 *
 * Üç görünüm, sekme içinde (Android geri tuşu geri götürür: history.pushState + popstate):
 *   liste    sınav kartları alt alta (SGS · Yeterlilik · KGK; yeni sınav = bir kart daha). Seçim zorunlu DEĞİL;
 *            ilk açılışta seçilen sınav en üstte.
 *   sinav    sınavın içi: ÜCRETSİZ DENE (açık) + dört çalışma yolu — Ders ders çöz · Kısa sınav · En çok çıkanlar ·
 *            Sınav gibi. Cem 26.09: "bunların hepsi kilitli olacak". Paketi olmayana kilitli görünür, altında TEK
 *            "Kilidi aç" düğmesi. Henüz kurulmamış yollar "yakında" diye yazar (kilit açılınca boş çıkmasın diye).
 *   dersler  ders listesi: hesapta açık dersler (#ana, uygulama.js çizer; burada sınava süzülür) + kilitli dersler
 *            + kasaya taşınmamışlar. Soru SAYISI yazılmaz (Cem 26.09: derlemedeki sayı kasadan geride kalıyor).
 * KGK uygulamada henüz yok → kartı "hazırlanıyor".
 *
 * APPLE KURALI: iPhone'da satış kapalıyken (katalog iosSatis false) fiyat, satın alma çağrısı, dış satış
 * bağlantısı GÖSTERİLMEZ. KAPI-SATIS (hazirla.js) sitenin satış düğmesi metinlerini yasaklar.
 * BU DOSYA ŞUNU YAPMAZ: paket okumaz (uygulama.js 'tt-durum' olayıyla bildirir) · satın alma yapmaz (magaza.js).
 */
(function () {
  var K = window.TT_KATALOG || {}, IL = window.TTIlerleme;
  var SINAVLAR = [
    { id: 'sgs', ad: 'SGS · Staja Giriş', kisa: 'SGS' },
    { id: 'yeterlilik', ad: 'SMMM Yeterlilik', kisa: 'Yeterlilik' },
    { id: 'kgk', ad: 'KGK Bağımsız Denetçilik', kisa: 'KGK' }
  ];
  /* sınav içi çalışma yolları; hazir:false olanın arkası henüz kurulmadı */
  var YOLLAR = [
    { id: 'dersler', ad: 'Ders ders çöz', alt: 'Dersini seç, kaldığın sorudan devam et', ikon: 'sinav', hazir: true },
    { id: 'kisa', ad: 'Kısa sınav', alt: 'Derslerden karışık 10 ya da 20 soru, süreli, sonunda karne', ikon: 'bugun', hazir: false },
    { id: 'cok', ad: 'En çok çıkanlar', alt: 'En çok dönemde soru gelen konulardan 20 soru', ikon: 'karne', hazir: false },
    { id: 'deneme', ad: 'Sınav gibi', alt: 'Tam deneme: gerçek süre, resmî ders dağılımı, ders ders karne', ikon: 'takvim', hazir: false }
  ];
  var ANAHTAR = 'tt_uyg_sinavgor';
  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function ik(ad, sinif) { return '<svg class="ik' + (sinif ? ' ' + sinif : '') + '" aria-hidden="true"><use href="#i-' + ad + '"/></svg>'; }
  var OK = ik('ok', 'ok');
  function sayi(n) { return Number(n).toLocaleString('tr-TR'); }
  function platform() { return (window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform()) || 'web'; }
  function yerel() { return !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform()); }
  /* bu cihazda uygulama içi satış olabilir mi (magaza.js satisAcik ile aynı kural) */
  function satisMumkun() { return yerel() && (platform() === 'android' || (platform() === 'ios' && K.iosSatis === true)); }
  function durum() { return window.TT_DURUM || { girisli: false, acik: [] }; }

  /* katalogdan sınav özeti — sayılar YALNIZ katalogdan (uydurma yok) */
  function ozet(s) {
    var paket = (K.paket || []).filter(function (d) { return d.sinav === s; });
    var yakin = (K.yakinda || []).filter(function (d) { return d.sinav === s; });
    var ucr = (K.ucretsiz || []).filter(function (d) { return d.sinav === s; })[0] || null;
    var acik = (durum().acik || []).filter(function (y) { return paket.some(function (d) { return d.yol === y; }); });
    var soru = paket.reduce(function (a, d) { return a + (d.adet || 0); }, 0);
    return { paket: paket, yakin: yakin, ucr: ucr, acik: acik, soru: soru, var_: paket.length + yakin.length > 0 || !!ucr };
  }
  function sinavAd(s) { return (SINAVLAR.filter(function (x) { return x.id === s; })[0] || {}).ad || s; }

  var st = document.createElement('style');
  st.textContent = [
    '#ana.gizle,#kilitli.gizle{display:none!important}',
    '#sinavUst .geri{display:inline-flex;align-items:center;gap:4px;margin:0 0 4px -6px;padding:6px;background:none;border:0;color:var(--soluk);font:500 14px/1 inherit}',
    '#sinavUst .geri svg{width:16px;height:16px;transform:scaleX(-1)}',
    '#sinavUst .alt1{color:var(--soluk);margin:4px 0 0;font-size:14px}',
    '.etiketK{flex:none;font-size:10.5px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--soluk);border:1px solid var(--cizgi2);border-radius:4px;padding:3px 6px}',
    '.etiketK.acik{color:var(--yazi);border-color:var(--yazi)}',
    '#kilitli .not,#sinavUst .not{font-size:13px;color:var(--soluk);margin:12px 0 0}',
    '#kilitli .ana,#sinavUst .ana{margin-top:14px}'
  ].join('\n');
  document.head.appendChild(st);

  /* görünüm durumu: { g: 'liste'|'sinav'|'dersler', s: sınav } */
  var gor = { g: 'liste', s: null };
  try { var eski = JSON.parse(sessionStorage.getItem(ANAHTAR) || 'null'); if (eski && eski.g) gor = eski; } catch (e) {}
  function git(g, s, gecmis) {
    gor = { g: g, s: s || null };
    try { sessionStorage.setItem(ANAHTAR, JSON.stringify(gor)); } catch (e) {}
    if (gecmis) try { history.pushState({ ttSinav: gor }, ''); } catch (e) {}
    if (s && s !== 'kgk' && IL && IL.veri().ayar.sinav !== s) { IL.ayarYaz({ sinav: s }); try { document.dispatchEvent(new CustomEvent('tt-sinav', { detail: s })); } catch (e) {} }
    ciz(); window.scrollTo(0, 0);
  }
  window.addEventListener('popstate', function (e) {
    var g = e.state && e.state.ttSinav;
    gor = g || { g: 'liste', s: null };
    try { sessionStorage.setItem(ANAHTAR, JSON.stringify(gor)); } catch (x) {}
    ciz();
  });

  function kilitAc() {
    var D = durum();
    if (!window.TTSekme) return;
    if (!D.girisli) { if (window.TTGiris) window.TTGiris.ac('uye'); else window.TTSekme.sec('hesap', 'giris'); }
    else if (satisMumkun() && window.TTMagaza) window.TTSekme.sec('hesap', 'paketler');
  }
  /* paketi olmayanın kilit altındaki tek düğme + açıklama */
  function kilitDugmesi() {
    var D = durum();
    if (!D.girisli) return '<button type="button" class="ana" data-kilitac="1">Kilidi aç</button>' +
      '<p class="not">Önce ücretsiz üye ol ya da hesabınla giriş yap; paketin varsa kilitler burada açılır.' +
      (satisMumkun() ? ' Paketin yoksa üye olduktan sonra uygulamadan alabilirsin.' : '') + '</p>';
    if (satisMumkun() && window.TTMagaza) return '<button type="button" class="ana" data-kilitac="1">Kilidi aç</button>';
    return '<p class="not">Bu sınav hesabındaki pakette yok.</p>';
  }

  function listeCiz() {
    var sec = IL ? IL.veri().ayar.sinav : null;
    var sira = SINAVLAR.slice().sort(function (a, b) { return (b.id === sec) - (a.id === sec); });
    var h = '<h1>Sınavlar</h1><div class="satirlar" style="margin-top:14px">';
    sira.forEach(function (x) {
      var o = ozet(x.id), etk, alt;
      if (!o.var_) { etk = '<span class="etiketK">Hazırlanıyor</span>'; alt = 'Uygulamada henüz yok'; }
      else {
        etk = o.acik.length ? '<span class="etiketK acik">Paketin açık</span>' : '';
        alt = (o.ucr ? sayi(o.ucr.adet || 30) + ' soru ücretsiz' : '') + (o.paket.length ? ' · ' + (o.paket.length + o.yakin.length) + ' ders' : '');
      }
      h += '<button type="button" class="srt" data-s="' + x.id + '"' + (o.var_ ? '' : ' disabled') + '><span class="ad">' + esc(x.ad) +
        '<small>' + esc(alt) + '</small></span>' + etk + (o.var_ ? OK : '') + '</button>';
    });
    h += '</div>';
    $('sinavUst').innerHTML = h;
    [].forEach.call($('sinavUst').querySelectorAll('[data-s]'), function (b) { b.onclick = function () { git('sinav', b.dataset.s, true); }; });
  }

  function geriDugmesi(yazi) { return '<button type="button" class="geri" data-geri="1">' + ik('ok') + esc(yazi) + '</button>'; }

  function sinavCiz(s) {
    var o = ozet(s), acik = o.acik.length > 0;
    var h = geriDugmesi('Sınavlar') + '<h1>' + esc(sinavAd(s)) + '</h1>';
    if (o.paket.length) h += '<p class="alt1">' + (o.paket.length + o.yakin.length) + ' ders' +
      (o.yakin.length ? ' (' + o.yakin.length + ' ders hazırlanıyor)' : '') + '</p>';

    h += '<span class="etk" style="margin-top:24px">Ücretsiz dene</span><div class="satirlar">';
    if (o.ucr) {
      var r = IL ? IL.dersSonucu(o.ucr.yol) : { ok: 0, yan: 0 }, n = r.ok + r.yan;
      h += '<a class="srt" href="' + esc(o.ucr.yol) + '">' + ik('oynat') + '<span class="ad">Örnek sorular<small>' +
        sayi(o.ucr.adet || 30) + ' soru · ilk 3 soru hesapsız, gerisi ücretsiz üyelikle</small></span>' +
        (n ? '<span class="sag">' + n + '/' + (o.ucr.adet || n) + '</span>' : '') + OK + '</a>';
    } else h += '<div class="bosDurum">Bu sınav için ücretsiz soru henüz yok.</div>';
    h += '</div>';

    h += '<span class="etk">Çalışma</span><div class="satirlar">';
    YOLLAR.forEach(function (y) {
      var kilitli = !acik, gidilir = y.hazir && (y.id === 'dersler' || !kilitli);
      var sag = !y.hazir ? '<span class="etiketK">Yakında</span>' : '';
      h += '<button type="button" class="srt' + (kilitli ? ' kilit' : '') + '" data-yol="' + y.id + '"' + (gidilir || kilitli ? '' : ' disabled') + '>' +
        ik(kilitli ? 'kilit' : y.ikon) + '<span class="ad">' + esc(y.ad) + '<small>' + esc(y.alt) + '</small></span>' + sag + (gidilir ? OK : '') + '</button>';
    });
    h += '</div>';
    if (!acik) h += kilitDugmesi();
    $('sinavUst').innerHTML = h;
    [].forEach.call($('sinavUst').querySelectorAll('[data-yol]'), function (b) {
      b.onclick = function () {
        if (b.dataset.yol === 'dersler') return git('dersler', s, true);
        if (!acik) return kilitAc();
      };
    });
  }

  function derslerCiz(s) {
    var o = ozet(s), D = durum();
    $('sinavUst').innerHTML = geriDugmesi(sinavAd(s)) + '<h1>Ders ders çöz</h1>';
    /* açık dersler: seçili sınava süz */
    var gorunen = 0;
    [].forEach.call($('liste').children, function (a) {
      var sn = a.getAttribute && a.getAttribute('data-sinav');
      if (sn === null) return;   // "okunuyor…" gibi durum satırı
      a.hidden = sn !== s; if (!a.hidden) gorunen++;
    });
    var durumSatiri = [].some.call($('liste').children, function (a) { return !a.hasAttribute('data-sinav'); });
    $('ana').classList.toggle('gizle', !gorunen && !durumSatiri);

    var kl = $('kilitli');
    if (D.acik === null) { kl.innerHTML = ''; kl.classList.add('gizle'); return; }
    var kilitli = o.paket.filter(function (d) { return o.acik.indexOf(d.yol) < 0; });
    if (!kilitli.length && !o.yakin.length) { kl.innerHTML = ''; kl.classList.add('gizle'); return; }
    kl.classList.remove('gizle');
    var k = '<span class="etk">' + (o.acik.length ? 'Paketinde olmayanlar' : 'Tam soru bankası') + '</span><div class="satirlar">';
    kilitli.forEach(function (d) {
      k += '<button type="button" class="srt kilit" data-kilitac="1">' + ik('kilit') + '<span class="ad">' + esc(d.baslik) +
        '<small>Pakette</small></span>' + OK + '</button>';
    });
    o.yakin.forEach(function (d) {
      k += '<div class="srt kilit">' + ik('kilit') + '<span class="ad">' + esc(d.baslik) + '<small>Hazırlanıyor</small></span></div>';
    });
    k += '</div>';
    if (kilitli.length) k += kilitDugmesi();
    kl.innerHTML = k;
  }

  function ciz() {
    var g = gor.g, s = gor.s;
    if (g !== 'liste' && !ozet(s).var_) g = 'liste';
    document.body.setAttribute('data-sinavgor', g);
    if (g !== 'dersler') { $('ana').classList.add('gizle'); $('kilitli').classList.add('gizle'); }
    if (g === 'liste') listeCiz(); else if (g === 'sinav') sinavCiz(s); else derslerCiz(s);
    [].forEach.call(document.querySelectorAll('#sinavUst [data-geri]'), function (b) {
      b.onclick = function () { if (history.state && history.state.ttSinav) history.back(); else git(gor.g === 'dersler' ? 'sinav' : 'liste', gor.s, false); };
    });
    [].forEach.call(document.querySelectorAll('#sinavUst [data-kilitac],#kilitli [data-kilitac]'), function (b) { b.onclick = kilitAc; });
  }

  /* soru sayfaları (katalogsuz) ara karnede gerçek paket büyüklüğünü yazsın diye */
  try {
    var po = {};
    SINAVLAR.forEach(function (x) { var o = ozet(x.id); if (o.paket.length) po[x.id] = { ders: o.paket.length + o.yakin.length }; });
    localStorage.setItem('tt_uyg_paket_ozet', JSON.stringify(po));
  } catch (e) {}

  ciz();
  document.addEventListener('tt-durum', ciz);
  try { new MutationObserver(function () { if (gor.g === 'dersler') ciz(); }).observe($('liste'), { childList: true }); } catch (e) {}
  window.addEventListener('pageshow', ciz);
  /* dışarıdan: TTSinavlar.ac('sgs') → o sınavın içi; ac() → liste */
  window.TTSinavlar = {
    ciz: ciz,
    secili: function () { return (IL && IL.veri().ayar.sinav) || 'yeterlilik'; },
    ac: function (s) { if (window.TTSekme) window.TTSekme.sec('sinav'); if (s) git('sinav', s, true); else git('liste', null, false); },
    ozet: ozet
  };
})();
