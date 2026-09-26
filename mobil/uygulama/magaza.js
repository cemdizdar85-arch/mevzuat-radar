/* magaza.js — UYGULAMA İÇİ SATIN ALMA, istemci ayağı (25.09.2026, Cem "1 ve 2 yap")
 *
 * Ürünler window.TT_KATALOG.urunler'den (mobil/magaza-urunleri.json, hazirla.js gömer); FİYAT
 * mağazadan okunur (Play Console'da girilen). Akış:
 *   1) kontrol  → sunucu (radar-app/edge/magaza-dogrula.ts) "bu ürün bu hesaba tanımlanabilir mi" der.
 *   2) ödeme    → Google ekranı; hesap kimliği (appAccountToken = Supabase user id) ödemeye iliştirilir.
 *                 Satın alma ONAYLANMADAN bırakılır (autoAcknowledgePurchases:false).
 *   3) doğrula  → sunucu Google'a sorar, paketi yazar, sonra tüketir (onay). Sunucu tanımlayamazsa
 *                 onaylamaz ve Google parayı 3 gün içinde kendiliğinden iade eder.
 * Bağlantı koparsa: satın alma "bekleyen" olarak cihazda kalır; uygulama her açılışta yeniden dener,
 * ayrıca mağazada onaylanmamış kalan satın almaları (getPurchases) toplar.
 *
 * Tarayıcıda ya da eklenti yokken bölüm HİÇ gösterilmez (Capacitor.Plugins.NativePurchases).
 *
 * iPhone (26.09.2026): aynı akış App Store ile. Jeton = StoreKit transactionId; sunucu App Store Server
 * API'den doğrular; işlem sunucu cevabından SONRA cihazda bitirilir (acknowledgePurchase = finish).
 * Apple kendiliğinden iade ETMEZ → "kontrol" adımı ödeme ekranından önce şart. iPhone'da bölüm yalnız
 * TT_KATALOG.iosSatis true iken açılır (mobil/magaza-urunleri.json "ios_satis"; Apple banka/sözleşme onayı).
 * BU DOSYA ŞUNU YAPMAZ: fiyat yazmaz (mağazadan okur) · siteye satış bağlantısı vermez.
 */
(function () {
  var P = (window.Capacitor && window.Capacitor.Plugins) || {};
  var NP = P.NativePurchases;
  var K = window.TT_KATALOG || {};
  var URUNLER = K.urunler || [];
  var DERSLER = K.dersler || {};
  var BEKLEYEN = 'tt_uyg_bekleyen';
  var sb = null, kullanici = null, yenileFn = null, magazaFiyat = {};

  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function durum(t) { $('satinDurum').textContent = t || ''; }
  function yerelMi() { return !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform() && NP); }
  function platform() { return (window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform()) || 'web'; }
  function ios() { return platform() === 'ios'; }
  /* Satış bu cihazda açık mı: Android her zaman; iPhone yalnız katalog anahtarı açıkken. */
  function satisAcik() { return platform() === 'android' || (ios() && K.iosSatis === true); }
  function magaza() { return ios() ? 'apple' : 'google'; }
  function magazaAdi() { return ios() ? 'App Store' : 'Google'; }
  var BITEN = 'tt_uyg_biten';   // iPhone: sunucunun kesin yanıt verdiği işlemler (yeniden gönderilmez)
  function bitenler() { try { return JSON.parse(localStorage.getItem(BITEN) || '[]'); } catch (e) { return []; } }
  function bitenEkle(j) { var l = bitenler(); if (l.indexOf(j) < 0) { l.push(j); try { localStorage.setItem(BITEN, JSON.stringify(l.slice(-200))); } catch (e) {} } }
  /* iPhone'da işlemi cihazda bitir (StoreKit finish). Google'da tüketimi sunucu yapar. */
  async function bitir(jeton) {
    if (!ios()) return;
    bitenEkle(jeton);
    try { await NP.acknowledgePurchase({ purchaseToken: jeton }); } catch (e) {}
  }

  var NEDEN = {
    'baska-sinav': 'Hesabında başka bir sınavın aktif paketi var. Bu paket şu an uygulamadan tanımlanamıyor.',
    'zaten-acik': 'Bu içerik hesabında zaten açık.',
    'ders-secilmedi': 'Ders seçimi eksik.', 'ders-sayisi': 'Seçtiğin ders sayısı paketle uyuşmuyor.',
    'giris-yok': 'Oturumun kapanmış. Yeniden giriş yap.', 'isleniyor': 'Satın alman işleniyor. Birkaç saniye sonra yeniden dene.',
    'beklemede': 'Ödemen henüz tamamlanmadı. Tamamlanınca paketin açılır.',
    'baska-hesap': 'Bu ödeme başka bir Tetikte hesabına ait.',
    'google-ulasilamadi': 'Google’a şu an ulaşılamadı. Uygulama bir sonraki açılışta yeniden dener.',
    'apple-ulasilamadi': 'App Store’a şu an ulaşılamadı. Uygulama bir sonraki açılışta yeniden dener.',
    'sunucu-ayari': 'Satın alma şu an kapalı. Lütfen daha sonra dene.'
  };
  function nedenYazi(n) { return NEDEN[n] || 'İşlem tamamlanamadı (' + (n || 'bilinmiyor') + ').'; }

  async function sunucu(govde) {
    var s = (await sb.auth.getSession()).data.session;
    if (!s) return { durum: 401, j: { neden: 'giris-yok' } };
    var r = await fetch(window.TT.SB_URL + '/functions/v1/magaza-dogrula', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + s.access_token, apikey: window.TT.SB_KEY },
      body: JSON.stringify(govde)
    });
    var j = {}; try { j = await r.json(); } catch (e) {}
    return { durum: r.status, j: j };
  }

  /* ---- bekleyenler: jeton cihazda, sunucu onaylayana kadar ---- */
  function bekleyenler() { try { return JSON.parse(localStorage.getItem(BEKLEYEN) || '[]'); } catch (e) { return []; } }
  function bekleyenYaz(l) { try { localStorage.setItem(BEKLEYEN, JSON.stringify(l)); } catch (e) {} }
  function bekleyenEkle(b) { var l = bekleyenler().filter(function (x) { return x.jeton !== b.jeton; }); l.push(b); bekleyenYaz(l); }
  function bekleyenSil(jeton) { bekleyenYaz(bekleyenler().filter(function (x) { return x.jeton !== jeton; })); }

  async function dogrula(b) {
    var r = await sunucu({ islem: 'dogrula', magaza: magaza(), urun: b.urun, jeton: b.jeton, dersler: b.dersler || null });
    if (r.j && r.j.tamam) { bekleyenSil(b.jeton); await bitir(b.jeton); return { tamam: true, j: r.j }; }
    var kesin = r.durum === 409 && r.j.neden !== 'isleniyor' || r.durum === 400;
    if (kesin) { bekleyenSil(b.jeton); await bitir(b.jeton); }
    return { tamam: false, kesin: kesin, neden: r.j.neden };
  }
  async function bekleyenleriIsle() {
    var l = bekleyenler().filter(function (x) { return x.uid === kullanici.id; });
    /* mağazada onaylanmamış kalan satın almalar (uygulama ödeme ile kayıt arasında kapandıysa) */
    try {
      /* iOS eklentisi süzgeci UUID'nin BÜYÜK harfli yazımıyla birebir kıyaslar (uuidString). */
      var g = await NP.getPurchases({ productType: 'inapp', appAccountToken: ios() ? String(kullanici.id).toUpperCase() : kullanici.id });
      var biten = bitenler();
      (g.purchases || []).forEach(function (t) {
        var jt = ios() ? t.transactionId : t.purchaseToken;
        if (!jt || t.isAcknowledged || biten.indexOf(jt) >= 0) return;
        if (!l.some(function (x) { return x.jeton === jt; })) {
          var niyet = null; try { niyet = JSON.parse(localStorage.getItem('tt_uyg_niyet_' + t.productIdentifier) || 'null'); } catch (e) {}
          var b = { uid: kullanici.id, urun: t.productIdentifier, jeton: jt, dersler: niyet ? niyet.dersler : null };
          bekleyenEkle(b); l.push(b);
        }
      });
    } catch (e) {}
    for (var i = 0; i < l.length; i++) {
      var s = await dogrula(l[i]).catch(function () { return { tamam: false }; });
      if (s.tamam) { durum('Önceki satın alman hesabına tanımlandı.'); if (yenileFn) yenileFn(); }
    }
  }

  /* ---- ders seçimi (yalnız 1–4 derslik Yeterlilik paketleri) ---- */
  function dersSec(urun) {
    return new Promise(function (coz) {
      var liste = DERSLER[urun.sinav] || [];
      $('dersSecimBaslik').querySelector('b').textContent = urun.ad + ': ' + urun.ders + ' ders seç';
      $('dersKutular').innerHTML = liste.map(function (d, i) {
        return '<label><input type="checkbox" value="' + esc(d) + '" id="ds' + i + '"> ' + esc(d) + '</label>';
      }).join('');
      $('dersSecimHata').textContent = '';
      $('dersSecim').hidden = false; $('urunListe').hidden = true;
      var bitir = function (sonuc) { $('dersSecim').hidden = true; $('urunListe').hidden = false; coz(sonuc); };
      $('dersSecimTamam').onclick = function () {
        var secili = [].slice.call($('dersKutular').querySelectorAll('input:checked')).map(function (x) { return x.value; });
        if (secili.length !== urun.ders) { $('dersSecimHata').textContent = 'Tam ' + urun.ders + ' ders seçmelisin (seçilen ' + secili.length + ').'; return; }
        bitir(secili);
      };
      $('dersSecimVazgec').onclick = function () { bitir(null); };
    });
  }

  function olay(ad) { if (window.TTOlay) window.TTOlay.say(ad); }   // adım sayacı (ilerleme.js)
  async function satinAl(urun, dugme) {
    durum('');
    olay('satin_al_bas');
    var dersler = null;
    if (urun.ders > 0 && urun.ders < (DERSLER[urun.sinav] || []).length) {
      dersler = await dersSec(urun);
      if (!dersler) return;
    }
    dugme.disabled = true;
    try {
      durum('Hesabın kontrol ediliyor…');
      var k;
      try { k = await sunucu({ islem: 'kontrol', urun: urun.id, dersler: dersler }); }
      catch (e) { durum('Sunucuya ulaşılamadı. Ödeme alınmadı; bağlantını kontrol edip yeniden dene.'); return; }
      if (!k.j || !k.j.tamam) { durum(nedenYazi(k.j && k.j.neden) + ' Ödeme alınmadı.'); return; }
      try { localStorage.setItem('tt_uyg_niyet_' + urun.id, JSON.stringify({ dersler: dersler, zaman: Date.now() })); } catch (e) {}
      durum(magazaAdi() + ' ödeme ekranı açılıyor…');
      var t = await NP.purchaseProduct({ productIdentifier: urun.id, productType: 'inapp', quantity: 1,
        appAccountToken: kullanici.id, isConsumable: false, autoAcknowledgePurchases: false });
      var jeton = t && (ios() ? t.transactionId : t.purchaseToken);
      if (!jeton) { durum('Satın alma tamamlanmadı.'); return; }
      var b = { uid: kullanici.id, urun: urun.id, jeton: String(jeton), dersler: dersler };
      bekleyenEkle(b);
      durum('Ödeme alındı, paketin hesabına tanımlanıyor…');
      var s = await dogrula(b);
      if (s.tamam) { olay('satin_aldi'); durum('Paketin açıldı. Bitiş: ' + (s.j.bitis || '')); if (yenileFn) yenileFn(); return; }
      var iade = !s.kesin || s.neden === 'beklemede' ? '' : ios()
        ? ' Ödemenin iadesi için Apple’a başvurabilirsin: reportaproblem.apple.com'
        : ' Ödemen Google tarafından 3 gün içinde otomatik iade edilir.';
      durum(nedenYazi(s.neden) + iade);
    } catch (e) {
      var m = String((e && (e.message || e.code)) || '');
      durum(/cancel|iptal|USER_CANCELED/i.test(m) ? 'Satın alma iptal edildi.' : 'Satın alma tamamlanamadı. Uygulama bir sonraki açılışta yeniden dener.');
    } finally { dugme.disabled = false; }
  }

  async function urunleriCiz() {
    var ids = URUNLER.map(function (u) { return u.id; });
    try {
      var r = await NP.getProducts({ productIdentifiers: ids, productType: 'inapp' });
      (r.products || []).forEach(function (p) { magazaFiyat[p.identifier] = p.priceString; });
    } catch (e) {}
    var l = $('urunListe'); l.innerHTML = '';
    /* kapsamlı paket en üstte (ödeme sayfasında ilk görülen) */
    URUNLER.slice().sort(function (a, b) { return (b.ders === 0 || b.ders >= 8) - (a.ders === 0 || a.ders >= 8); }).forEach(function (u) {
      var fiyat = magazaFiyat[u.id];
      var el = document.createElement('div');
      el.className = 'urun'; el.setAttribute('data-sinav', u.sinav);
      el.innerHTML = '<span class="ad">' + esc(u.ad) + '<span class="etiket">' +
        (fiyat ? esc(fiyat) : 'Fiyat mağazadan okunamadı') + ' · sınava kadar erişim</span></span>' +
        '<button type="button" class="al"' + (fiyat ? '' : ' disabled') + '>Satın al</button>';
      el.querySelector('.al').addEventListener('click', function () { satinAl(u, el.querySelector('.al')); });
      l.appendChild(el);
    });
    if (!Object.keys(magazaFiyat).length) $('paketNot').textContent = 'Paketler şu an mağazadan yüklenemedi. İnternet bağlantını kontrol et.';
  }

  window.TTMagaza = {
    goster: function (istemci, k, yenile) {
      /* Kilitli sınav perdesi (uygulama-kapisi.js) "Paket seç" düğmesini bu bilgiyle gösterir. */
      try { localStorage.setItem('tt_uyg_satis_acik', yerelMi() && satisAcik() ? '1' : '0'); } catch (e) {}
      if (!yerelMi() || !satisAcik() || !URUNLER.length || k.cevrimdisi) { $('paketler').hidden = true; return; }
      sb = istemci; kullanici = k; yenileFn = yenile;
      $('paketler').hidden = false;
      $('paketNot').textContent = 'Ödeme ' + (ios() ? 'App Store' : 'Google Play') + ' üzerinden yapılır; paket hesabına hemen tanımlanır.';
      urunleriCiz().then(function () { if (location.hash === '#paketler') $('paketler').scrollIntoView({ block: 'start' }); });
      bekleyenleriIsle();
    },
    gizle: function () { var p = $('paketler'); if (p) p.hidden = true; }
  };
})();
