/* ortak.js — MAĞAZA UYGULAMASININ ORTAK AYAĞI (25.09.2026)
 *
 * Hem uygulamanın ana ekranı (index.html) hem uygulamaya gömülen Kaydır-Çöz kabukları
 * (uygulama-kapisi.js üzerinden) bu dosyayı kullanır. Tek iş: Supabase istemcisi +
 * paket kuralı + çevrimdışı önbellek.
 *
 * ÇEVRİMDIŞI: istemcinin fetch'i sarılır. paket_soru ve paket_uyeler GET yanıtları başarılı
 * gelince cihaza (IndexedDB) yazılır; ağ yoksa aynı adres önbellekten verilir. Ağ varsa
 * HER ZAMAN ağ kazanır (önbellek bayat içerik göstermez). Çıkışta önbellek silinir.
 *
 * PAKET KURALI: paket-kapisi.js / uye-durumu.js paketSinavlari ile AYNI eşleme (18.09 hali).
 * Oradaki kural değişirse burası da değişmeli — mobil/hazirla-sinavi.js bu eşlemenin
 * paket-kapisi.js ile aynı kaldığını her koşuda ölçer (kopya kayarsa sınav KIRMIZI).
 *
 * BU DOSYA ŞUNU GÖRMEZ / YAPAMAZ:
 *   - Önbellek cihazdadır; cihazı ele geçiren indirilmiş dersleri okuyabilir (tarayıcıdaki
 *     sayfanın indirdiğiyle aynı risk). Paket bitince ağ varken kapı kapanır; ağ yokken
 *     son bilinen paket bilgisiyle en fazla CEVRIMDISI_GUN gün açık kalır.
 *   - Supabase oturumu ağ yokken yenilenemez; o sürede kimlik, cihazdaki son oturumdan okunur.
 */
(function () {
  if (window.TT) return;
  var SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
  var SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var ONBELLEK_DESENI = /\/rest\/v1\/(paket_soru|paket_uyeler)\?/;
  var CEVRIMDISI_GUN = 7;
  var PAKET_ANAHTARI = 'tt_uyg_paket';

  /* ---------- IndexedDB: tek depo, anahtar = istek adresi ---------- */
  var dbSozu = null;
  function db() {
    if (dbSozu) return dbSozu;
    dbSozu = new Promise(function (coz, reddet) {
      var r = indexedDB.open('tt-onbellek', 1);
      r.onupgradeneeded = function () { r.result.createObjectStore('yanit'); };
      r.onsuccess = function () { coz(r.result); };
      r.onerror = function () { dbSozu = null; reddet(r.error); };
    });
    return dbSozu;
  }
  function depo(kip, is) {
    return db().then(function (d) {
      return new Promise(function (coz, reddet) {
        var t = d.transaction('yanit', kip);
        var sonuc = is(t.objectStore('yanit'));
        t.oncomplete = function () { coz(sonuc && 'result' in sonuc ? sonuc.result : undefined); };
        t.onerror = function () { reddet(t.error); };
      });
    });
  }
  function yaz(anahtar, deger) { return depo('readwrite', function (s) { return s.put(deger, anahtar); }).catch(function () {}); }
  function oku(anahtar) { return depo('readonly', function (s) { return s.get(anahtar); }).catch(function () { return undefined; }); }
  function temizle() { return depo('readwrite', function (s) { return s.clear(); }).catch(function () {}); }

  function anahtarBul(url, basliklar) {
    var prefer = '';
    try { prefer = new Headers(basliklar || {}).get('Prefer') || ''; } catch (e) {}
    return 'GET ' + url + ' | ' + prefer;
  }

  /* Ağ önce; başarılı GET kasaya yazılır; ağ düşerse kasadaki aynı adres verilir. */
  function onbellekliFetch(girdi, ayar) {
    var url = typeof girdi === 'string' ? girdi : girdi.url;
    var yontem = ((ayar && ayar.method) || (girdi && girdi.method) || 'GET').toUpperCase();
    var izle = yontem === 'GET' && ONBELLEK_DESENI.test(url);
    if (!izle) return fetch(girdi, ayar);
    var anahtar = anahtarBul(url, ayar && ayar.headers);
    return fetch(girdi, ayar).then(function (y) {
      if (y.ok) {
        y.clone().text().then(function (govde) {
          yaz(anahtar, { govde: govde, durum: y.status, cr: y.headers.get('content-range') || '', zaman: Date.now() });
        });
      }
      return y;
    }, function (hata) {
      return oku(anahtar).then(function (k) {
        if (!k) throw hata;
        var h = { 'content-type': 'application/json; charset=utf-8', 'x-tt-onbellek': '1' };
        if (k.cr) h['content-range'] = k.cr;
        return new Response(k.govde, { status: k.durum, headers: h });
      });
    });
  }

  var istemciNesne = null;
  function istemci() {
    if (istemciNesne) return istemciNesne;
    if (!window.supabase || !window.supabase.createClient) throw new Error('supabase kütüphanesi yüklenmedi');
    istemciNesne = window.supabase.createClient(SB_URL, SB_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false },
      global: { fetch: onbellekliFetch }
    });
    return istemciNesne;
  }

  /* Oturum: ağ varsa supabase-js; yenileme ağ yüzünden düşerse cihazdaki son oturumun kullanıcısı. */
  function saklananKullanici() {
    try {
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (/^sb-.*-auth-token$/.test(k)) {
          var v = JSON.parse(localStorage.getItem(k) || 'null');
          var u = v && (v.user || (v.currentSession && v.currentSession.user));
          if (u && u.id) return { id: u.id, email: u.email || '' };
        }
      }
    } catch (e) {}
    return null;
  }
  async function kullanici(sb) {
    try {
      var r = await sb.auth.getSession();
      if (r.data && r.data.session) return { id: r.data.session.user.id, email: r.data.session.user.email || '', cevrimdisi: false };
    } catch (e) {}
    if (navigator.onLine === false) {
      var s = saklananKullanici();
      if (s) { s.cevrimdisi = true; return s; }
    }
    return null;
  }

  /* ---------- paket kuralı (paket-kapisi.js ile AYNI; hazirla-sinavi.js ölçer) ---------- */
  function sinaviBul(yol) {
    return /\/?kaydir\/sgs\//.test(yol) || /sinav-gibi\.html$/.test(yol) ? 'sgs'
      : (/\/?kaydir\/smmm\//.test(yol) ? 'yeterlilik' : null);
  }
  function kapsar(paket, sinavi) {
    var p = String(paket == null ? '' : paket).trim().toLowerCase();
    if (!sinavi || !p || p === 'tam' || p === 'kurucu') return true;
    if (sinavi === 'sgs') return p === 'sgs' || p.indexOf('sgs-') === 0 || p === 'sinav-249';
    if (sinavi === 'yeterlilik') return p === 'yeterlilik' || p.indexOf('yeterlilik-') === 0 || p === 'smmm' || p === 'yeterlilik-kgk';
    return false;
  }
  function bugun() { return new Date().toISOString().slice(0, 10); }
  function aktifMi(satir) { return !satir.bitis || satir.bitis >= bugun(); }

  /* Paket satırları: ağdan; ağ yoksa son başarılı okuma (en fazla CEVRIMDISI_GUN gün). */
  async function paketler(sb, kullaniciId) {
    try {
      var r = await sb.from('paket_uyeler').select('paket,bitis').eq('user_id', kullaniciId);
      if (r.error) throw r.error;
      var satir = r.data || [];
      try { localStorage.setItem(PAKET_ANAHTARI, JSON.stringify({ id: kullaniciId, zaman: Date.now(), satir: satir })); } catch (e) {}
      return { satir: satir, cevrimdisi: false };
    } catch (hata) {
      var k = null;
      try { k = JSON.parse(localStorage.getItem(PAKET_ANAHTARI) || 'null'); } catch (e) {}
      if (k && k.id === kullaniciId && Date.now() - k.zaman < CEVRIMDISI_GUN * 864e5) return { satir: k.satir || [], cevrimdisi: true };
      throw hata;
    }
  }
  function acarMi(satirlar, sinavi) {
    return (satirlar || []).some(function (x) { return aktifMi(x) && kapsar(x.paket, sinavi); });
  }

  async function cikis(sb) {
    try { await sb.auth.signOut(); } catch (e) {}
    try { localStorage.removeItem(PAKET_ANAHTARI); } catch (e) {}
    await temizle();
  }

  window.TT = {
    istemci: istemci, kullanici: kullanici, paketler: paketler, acarMi: acarMi,
    sinaviBul: sinaviBul, kapsar: kapsar, cikis: cikis, onbellekTemizle: temizle,
    CEVRIMDISI_GUN: CEVRIMDISI_GUN
  };
})();
