/* uygulama-sinavlar.js — "SINAVLAR" SEKMESİ (26.09.2026, Cem "olsun" — 4 sekme: Bugün · Sınavlar · Karnem · Hesap)
 *
 * Yurt dışı rakip incelemesi (Pocket Prep, Duolingo, UWorld): ayrı "Ücretsiz" ve "Paketler" sekmesi YOK; sorular
 * tek yerde durur, ücretli olan yerinde KİLİTLİ görünür, kilide dokununca açma yolu çıkar. Bu dosya:
 *   #sinavUst  sınav seçici (Yeterlilik · SGS · KGK) + ücretsiz örnek sorular (hesap gerekmez)
 *   #ana       hesapta açık dersler — uygulama.js çizer; burada yalnız seçili sınava süzülür
 *   #kilitli   pakette olup hesapta açık olmayan dersler (+ kasaya taşınmamış "hazırlanıyor" dersler)
 * Seçili sınav ilerleme.js ayarına (ayar.sinav) yazılır: Bugün sekmesindeki günün sorusu da ona göre gelir.
 * KGK uygulamada henüz yok → "hazırlanıyor" durumu; seçim ayara YAZILMAZ.
 *
 * APPLE KURALI: iPhone'da satış kapalıyken (katalog iosSatis false) fiyat, satın alma çağrısı, dış satış
 * bağlantısı GÖSTERİLMEZ; kilitli ders yalnız kilitli görünür. KAPI-SATIS (hazirla.js) sitenin satış düğmesi metinlerini yasaklar.
 * BU DOSYA ŞUNU YAPMAZ: paket okumaz (uygulama.js 'tt-durum' olayıyla bildirir) · satın alma yapmaz (magaza.js).
 */
(function () {
  var K = window.TT_KATALOG || {}, IL = window.TTIlerleme;
  var SINAVLAR = [{ id: 'yeterlilik', ad: 'Yeterlilik' }, { id: 'sgs', ad: 'SGS' }, { id: 'kgk', ad: 'KGK' }];
  var AD = { yeterlilik: 'SMMM Yeterlilik', sgs: 'SGS · Staja Giriş', kgk: 'KGK Bağımsız Denetçilik' };
  var ANAHTAR = 'tt_uyg_sinavsec';
  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function ik(ad) { return '<svg class="ik" aria-hidden="true"><use href="#i-' + ad + '"/></svg>'; }
  function sayi(n) { return Number(n).toLocaleString('tr-TR'); }
  function platform() { return (window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform()) || 'web'; }
  function yerel() { return !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform()); }
  /* bu cihazda uygulama içi satış olabilir mi (magaza.js satisAcik ile aynı kural) */
  function satisMumkun() { return yerel() && (platform() === 'android' || (platform() === 'ios' && K.iosSatis === true)); }

  var st = document.createElement('style');
  st.textContent = [
    '#sinavUst .segment{margin:14px 0 0}',
    '#ana.bosSinav{display:none!important}',
    '#kilitli .not{font-size:13px;color:var(--soluk);margin:12px 0 0}',
    '#kilitli .ana{margin-top:14px}'
  ].join('\n');
  document.head.appendChild(st);

  function secili() {
    var s = null; try { s = sessionStorage.getItem(ANAHTAR); } catch (e) {}
    if (!s && IL) s = IL.veri().ayar.sinav;
    return s === 'sgs' || s === 'kgk' ? s : 'yeterlilik';
  }
  function sec(id) {
    try { sessionStorage.setItem(ANAHTAR, id); } catch (e) {}
    if (IL && id !== 'kgk' && IL.veri().ayar.sinav !== id) IL.ayarYaz({ sinav: id });
    ciz();
    try { document.dispatchEvent(new CustomEvent('tt-sinav', { detail: id })); } catch (e) {}
  }

  function sekmeyeGit(sekme, hedef) {
    if (window.TTSekme) window.TTSekme.sec(sekme, hedef);
  }

  function ciz() {
    var s = secili(), D = window.TT_DURUM || { girisli: false, acik: [] };
    document.body.setAttribute('data-sinavsec', s);

    /* --- üst: başlık + seçici + ücretsiz --- */
    var h = '<h1>Sınavlar</h1><div class="segment" role="group" aria-label="Sınav seç">' +
      SINAVLAR.map(function (x) { return '<button type="button" data-s="' + x.id + '" aria-pressed="' + (x.id === s) + '">' + x.ad + '</button>'; }).join('') + '</div>';
    if (s === 'kgk') {
      h += '<span class="etk" style="margin-top:26px">' + esc(AD.kgk) + '</span><div class="satirlar"><div class="bosDurum"><b>Hazırlanıyor</b>' +
        'KGK soru bankası güvenli soru kasasına taşındığında bu sekmede açılır.</div></div>';
    } else {
      var u = (K.ucretsiz || []).filter(function (x) { return x.sinav === s; })[0];
      if (u) {
        var r = IL ? IL.dersSonucu(u.yol) : { ok: 0, yan: 0 }, n = r.ok + r.yan;
        h += '<span class="etk" style="margin-top:26px">Ücretsiz</span><div class="satirlar">' +
          '<a class="srt" href="' + esc(u.yol) + '">' + ik('oynat') + '<span class="ad">Örnek sorular<small>' +
          (u.adet ? sayi(u.adet) + ' soru · ' : '') + 'hesap gerekmez · açıklamalı</small></span>' +
          (n ? '<span class="sag">' + n + '/' + (u.adet || n) + '</span>' : '') + ik('ok').replace('class="ik"', 'class="ik ok"') + '</a></div>';
      }
    }
    $('sinavUst').innerHTML = h;
    [].forEach.call($('sinavUst').querySelectorAll('.segment button'), function (b) { b.onclick = function () { sec(b.dataset.s); }; });

    /* --- açık dersler: seçili sınava süz --- */
    var gorunen = 0;
    [].forEach.call($('liste').children, function (a) {
      var sn = a.getAttribute && a.getAttribute('data-sinav');
      if (sn === null) return;   // "okunuyor…" gibi durum satırı
      a.hidden = sn !== s; if (!a.hidden) gorunen++;
    });
    var durumSatiri = [].some.call($('liste').children, function (a) { return !a.hasAttribute('data-sinav'); });
    $('ana').classList.toggle('bosSinav', s === 'kgk' || (!gorunen && !durumSatiri));

    /* --- kilitli dersler --- */
    var kl = $('kilitli');
    if (s === 'kgk' || D.acik === null) { kl.innerHTML = ''; kl.hidden = true; return; }
    var acik = D.acik || [];
    var kilitli = (K.paket || []).filter(function (d) { return d.sinav === s && acik.indexOf(d.yol) < 0; });
    var yakin = (K.yakinda || []).filter(function (d) { return d.sinav === s; });
    if (!kilitli.length && !yakin.length) { kl.innerHTML = ''; kl.hidden = true; return; }
    kl.hidden = false;
    var satis = D.girisli && satisMumkun() && !!window.TTMagaza;
    var k = '<span class="etk">' + (acik.length ? 'Paketinde olmayanlar' : 'Tam soru bankası') + '</span><div class="satirlar">';
    kilitli.forEach(function (d) {
      k += '<button type="button" class="srt kilit" data-kilit="1">' + ik('kilit') + '<span class="ad">' + esc(d.baslik) +
        '<small>' + (d.adet ? sayi(d.adet) + ' soru' : 'Pakette') + '</small></span>' + ik('ok').replace('class="ik"', 'class="ik ok"') + '</button>';
    });
    yakin.forEach(function (d) {
      k += '<div class="srt kilit">' + ik('kilit') + '<span class="ad">' + esc(d.baslik) + '<small>Hazırlanıyor</small></span></div>';
    });
    k += '</div>';
    if (!D.girisli) {
      k += '<button type="button" class="ana" data-git="giris">Giriş yap</button>' +
        '<p class="not">Paketin varsa hesabınla giriş yap; dersler burada açılır.' +
        (satisMumkun() ? ' Paketin yoksa giriş yaptıktan sonra uygulamadan alabilirsin.' : '') + '</p>';
    } else if (satis && kilitli.length) {
      k += '<button type="button" class="ana" data-git="paket">Kilidi aç</button>';
    } else if (kilitli.length) {
      k += '<p class="not">Bu dersler hesabındaki pakette yok.</p>';
    }
    kl.innerHTML = k;
    var git = function () { if (!D.girisli) sekmeyeGit('hesap', 'giris'); else if (satis) sekmeyeGit('hesap', 'paketler'); };
    [].forEach.call(kl.querySelectorAll('[data-kilit],[data-git]'), function (b) { b.onclick = git; });
  }

  ciz();
  document.addEventListener('tt-durum', ciz);
  try { new MutationObserver(function () { ciz(); }).observe($('liste'), { childList: true }); } catch (e) {}
  window.addEventListener('pageshow', ciz);
  window.TTSinavlar = { ciz: ciz, secili: secili };
})();
