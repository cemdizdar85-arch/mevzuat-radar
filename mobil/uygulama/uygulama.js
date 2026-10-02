/* uygulama.js — mağaza uygulamasının ana ekranı (25.09.2026)
 *
 * Ekranlar: giriş · açık dersler (hesabın paketine göre) · Günlük hatırlatıcı · Hesap. Sekme düzeni
 * (Bugün · Sınavlar · Karnem · Hesap) uygulama-sekme.js'te; ücretsiz ve kilitli dersler uygulama-sinavlar.js'te.
 * Giriş durumu değişince document'e 'tt-durum' olayı atılır; window.TT_DURUM = { girisli, acik: [yol] }.
 * Katalog (window.TT_KATALOG) derlemede mobil/hazirla.js tarafından yazılır: yalnız KASA MODUNDAKİ
 * (sorusuz) sayfalar + ücretsiz vitrin (sınav başına 30) + mağaza ürünleri. Satın alma YALNIZ
 * mağaza üzerinden (magaza.js, Cem 25.09 "1 ve 2 yap"); dışarıdaki satış sayfasına yönlendirme YOK.
 *
 * Yerel eklentiler window.Capacitor.Plugins üzerinden çağrılır (paketleyici yok). Tarayıcıda
 * açılırsa (Capacitor yok) hatırlatıcı gizlenir, dış bağlantılar yeni sekmede açılır.
 */
(function () {
  var K = window.TT_KATALOG || { paket: [], ucretsiz: [], yakinda: [], surum: '?', derleme: '?' };
  var P = (window.Capacitor && window.Capacitor.Plugins) || {};
  var yerel = !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
  var HESAP_SIL_EPOSTA = 'destek@tetikte.com';   // 25.09 Cem: dışarıya yalnız tetikte adresleri (kvkk.html de buna çevrilecek)
  var SIFRE_DONUS = 'https://tetikte.com/ogrenci.html';
  var INDIRME_ANAHTARI = 'tt_uyg_indirilen';
  var PARCA = 100;                                    // kasa-yukle.js ile AYNI (hazirla-sinavi.js ölçer)
  var sb = null;

  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function goster(id, acik) { $(id).hidden = !acik; }

  function disAc(url) {
    if (P.Browser && P.Browser.open) return P.Browser.open({ url: url });
    window.open(url, '_blank', 'noopener');
  }
  document.addEventListener('click', function (e) {
    var b = e.target.closest && e.target.closest('[data-dis]');
    if (b) { e.preventDefault(); disAc(b.getAttribute('data-dis')); }
  });

  function trHata(h) {
    var m = (h && (h.message || h.error_description || '')) + '';
    if (/Invalid login credentials/i.test(m)) return 'E-posta ya da şifre hatalı.';
    if (/Email not confirmed/i.test(m)) return 'E-posta adresin henüz doğrulanmamış.';
    if (/fetch|network|Failed/i.test(m)) return 'İnternet bağlantısı kurulamadı.';
    if (/rate|too many/i.test(m)) return 'Çok fazla deneme yapıldı. Biraz sonra yeniden dene.';
    if (/captcha/i.test(m)) return 'Güvenlik doğrulaması tamamlanamadı. İnternetini kontrol edip yeniden dene.';
    return 'Giriş yapılamadı. Bilgilerini kontrol edip yeniden dene.';
  }

  /* ---------- çevrimdışı indirme: kasa-yukle.js'in çağrılarının AYNISI (önbellek anahtarı eşleşsin) ---------- */
  function indirilenler() { try { return JSON.parse(localStorage.getItem(INDIRME_ANAHTARI) || '{}'); } catch (e) { return {}; } }
  function indirildi(yol, adet) {
    var m = indirilenler(); m[yol] = { tarih: new Date().toISOString().slice(0, 10), adet: adet };
    try { localStorage.setItem(INDIRME_ANAHTARI, JSON.stringify(m)); } catch (e) {}
  }
  async function dersIndir(yol) {
    var ilk = await sb.from('paket_soru').select('sira,veri', { count: 'exact' })
      .eq('sayfa', yol).order('sira', { ascending: true }).range(0, PARCA - 1);
    if (ilk.error) throw ilk.error;
    var toplam = ilk.count == null ? ilk.data.length : ilk.count;
    var istekler = [];
    for (var i = PARCA; i < toplam; i += PARCA) {
      istekler.push(sb.from('paket_soru').select('sira,veri')
        .eq('sayfa', yol).order('sira', { ascending: true }).range(i, i + PARCA - 1)
        .then(function (r) { if (r.error) throw r.error; return r.data.length; }));
    }
    var adet = ilk.data.length + (await Promise.all(istekler)).reduce(function (a, b) { return a + b; }, 0);
    if (adet !== toplam) throw new Error('eksik ' + adet + '/' + toplam);
    indirildi(yol, adet);
    return adet;
  }

  function dersKarti(d, indirilebilir) {
    var m = indirilenler()[d.yol];
    var a = document.createElement('a');
    a.className = 'ders'; a.href = d.yol; a.setAttribute('data-sinav', d.sinav || '');
    var alt = [];
    if (m) alt.push('cihazda · ' + m.tarih.split('-').reverse().join('.'));
    a.innerHTML = '<span class="ad">' + esc(d.baslik) + '<span class="etiket">' + esc(alt.join(' · ')) + '</span></span>' +
      (indirilebilir ? '<button type="button" class="indir"' + (m ? ' data-durum="cihazda"' : '') + '>' + (m ? 'Yenile' : 'İndir') + '</button>' : '');
    var dugme = a.querySelector('.indir');
    if (dugme) dugme.addEventListener('click', async function (e) {
      e.preventDefault(); e.stopPropagation();
      dugme.disabled = true; dugme.textContent = 'İniyor…';
      try { var n = await dersIndir(d.yol); dugme.textContent = 'Cihazda'; dugme.setAttribute('data-durum', 'cihazda'); }
      catch (err) { dugme.textContent = 'Yeniden dene'; }
      dugme.disabled = false;
    });
    return a;
  }

  function ucretsizCiz() {
    var l = $('ucretsizListe'); l.innerHTML = '';
    (K.ucretsiz || []).forEach(function (d) { l.appendChild(dersKarti(d, false)); });
    goster('ucretsiz', (K.ucretsiz || []).length > 0);
  }

  async function anaCiz(k) {
    goster('giris', false); goster('ana', true); goster('hesap', true); goster('hesapDugmeler', true);
    $('hesapEposta').textContent = k.email || '';
    profilCiz(k);
    var liste = $('liste'); liste.innerHTML = '<div class="iskelet" aria-label="Paket bilgisi okunuyor"><i></i><i></i><i></i></div>';
    var p;
    try { p = await window.TT.paketler(sb, k.id); }
    catch (e) { liste.innerHTML = '<p class="soluk">Paket bilgisi okunamadı. İnternet bağlantını kontrol et.</p>'; durumBildir(true, null); return; }
    rozet(k.cevrimdisi || p.cevrimdisi ? 'Çevrimdışı' : '');
    var acik = (K.paket || []).filter(function (d) { return window.TT.acarMi(p.satir, d.sinav); });
    liste.innerHTML = '';
    acik.forEach(function (d) { liste.appendChild(dersKarti(d, true)); });
    goster('ana', acik.length > 0);
    $('anaNot').textContent = 'Derse dokun, kaldığın sorudan devam et. İndir: internetsiz çözmek için.';
    durumBildir(true, acik.map(function (d) { return d.yol; }));
    if (window.TTMagaza) window.TTMagaza.goster(sb, k, yenile);
    var sinavlar = {};
    acik.forEach(function (d) { sinavlar[d.sinav] = 1; });
    var yakin = (K.yakinda || []).filter(function (d) { return sinavlar[d.sinav]; });
    $('yakinda').innerHTML = yakin.map(function (d) { return '<li>' + esc(d.baslik) + ' <span class="kucuk">(' + esc(d.sinavAd) + ')</span></li>'; }).join('');
    goster('yakindaKutu', yakin.length > 0);
  }

  function girisCiz() {
    goster('ana', false); goster('hesap', false); goster('hesapDugmeler', false); goster('giris', true); rozet('');
    if (window.TTMagaza) window.TTMagaza.gizle();
    durumBildir(false, []);
  }
  /* Hesap: profil kartı (baş harf, e-posta, paket durumu) — bandın kenarına biner */
  function profilCiz(k) {
    var kap = $('profilKart');
    if (!kap) { kap = document.createElement('div'); kap.id = 'profilKart'; kap.className = 'kart'; var b = $('hesap').querySelector('.bant'); b.parentNode.insertBefore(kap, b.nextSibling); }
    var ep = k.email || '', harf = (ep.charAt(0) || '?').toLocaleUpperCase('tr');
    var paket = (window.TT_DURUM && window.TT_DURUM.acik && window.TT_DURUM.acik.length) ? window.TT_DURUM.acik.length + ' ders açık' : 'Paket yok';
    kap.innerHTML = '<div class="profil"><span class="avatar">' + esc(harf) + '</span><span class="ad"><b>' + esc(ep) + '</b><small>' + esc(paket) + '</small></span></div>';
  }
  document.addEventListener('tt-durum', function () { if (window.TT_DURUM && window.TT_DURUM.girisli && $('profilKart')) profilCiz({ email: $('hesapEposta').textContent }); });
  function durumBildir(girisli, acik) {
    window.TT_DURUM = { girisli: girisli, acik: acik };
    /* soru sayfaları (supabase'siz vitrin) üyelik kapısı için bunu okur: uygulama-kaydir.js */
    try { localStorage.setItem('tt_uyg_girisli', girisli ? '1' : '0'); } catch (e) {}
    try { document.dispatchEvent(new CustomEvent('tt-durum', { detail: window.TT_DURUM })); } catch (e) {}
  }
  function rozet(t) { $('durumRozet').textContent = t; $('durumRozet').hidden = !t; }

  /* ---------- üye ol / giriş (26.09 Cem "kur": üyelik kapısı) ----------
     Üye ol = ogrenci.html ile AYNI meta alanları (koşullar zorunlu, açık rıza isteğe bağlı ve ayrı). Supabase e-posta
     onayı 23.09'dan beri kapalı → signUp oturumu hemen açar; açmazsa kişiye söylenir. */
  var mod = 'uye';
  function modSec(m) {
    mod = m;
    $('modUye').setAttribute('aria-pressed', m === 'uye'); $('modGiris').setAttribute('aria-pressed', m === 'giris');
    $('adSatir').hidden = m !== 'uye'; $('onaySatir').hidden = m !== 'uye'; $('sifreUnuttum').hidden = m !== 'giris';
    /* 02.10: üye ol'a geçerken kutudaki (tarayıcının doldurduğu ya da giriş için yazılan) şifre taşınmaz */
    $('sifre2Satir').hidden = m !== 'uye'; if (m === 'uye') { $('sifre').value = ''; $('sifre2').value = ''; }
    $('girisGonder').textContent = m === 'uye' ? 'Ücretsiz üye ol' : 'Giriş yap';
    $('girisBaslik').textContent = m === 'uye' ? 'Ücretsiz üye ol' : 'Giriş yap';
    $('girisAlt').textContent = m === 'uye' ? '30 ücretsiz soru, açıklamaları ve karnen açılır. İlerlemen tüm cihazlarında saklanır.'
      : 'Tetikte hesabınla giriş yap. Paketindeki dersler açılır, ilerlemen tüm cihazlarında aynı kalır.';
    $('sifre').setAttribute('autocomplete', m === 'uye' ? 'new-password' : 'current-password');
    $('girisHata').textContent = '';
  }
  $('modUye').addEventListener('click', function () { modSec('uye'); });
  /* diğer dosyalar: TTGiris.ac('uye'|'giris') → Hesap sekmesinde o form */
  window.TTGiris = { ac: function (m) { modSec(m === 'giris' ? 'giris' : 'uye'); if (window.TTSekme) window.TTSekme.sec('hesap', 'giris'); } };
  window.addEventListener('hashchange', function () { if (location.hash === '#uyeol') modSec('uye'); else if (location.hash === '#giris') modSec('giris'); });
  $('modGiris').addEventListener('click', function () { modSec('giris'); });
  function olay(ad, tek) { if (window.TTOlay) window.TTOlay.say(ad, tek); }
  function platformAdi() { return (window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform()) || 'web'; }
  /* bot koruması: captcha.js (sitedeki) açıkken taze Turnstile belirteci; kapalıyken undefined — hiçbir şey değişmez */
  function captcha() { return window.ttCaptchaToken ? window.ttCaptchaToken() : Promise.resolve(undefined); }
  function olayGonder() { if (window.TTOlay && window.TT && window.TT.SB_URL) window.TTOlay.gonder(window.TT.SB_URL, window.TT.SB_KEY, platformAdi()); }

  $('girisForm').addEventListener('submit', async function (e) {
    e.preventDefault();
    var h = $('girisHata'); h.textContent = '';
    var ep = $('eposta').value.trim(), sf = $('sifre').value;
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(ep)) { h.textContent = 'E-posta adresini yaz.'; return; }
    if (!sf) { h.textContent = 'Şifreni yaz.'; return; }
    if (mod === 'uye' && sf.length < 8) { h.textContent = 'Şifre en az 8 karakter olmalı.'; return; }
    if (mod === 'uye' && sf !== $('sifre2').value) { h.textContent = 'İki şifre aynı değil. Tekrar yaz.'; return; }
    var dg = $('girisGonder'); dg.disabled = true;
    try {
      if (mod === 'uye') {
        if (!$('kosul').checked) { h.textContent = 'Üye olmak için sözleşmeyi ve aydınlatma metnini kabul etmen gerekiyor.'; return; }
        var an = new Date().toISOString(), riza = $('riza').checked;
        var u = await sb.auth.signUp({ email: ep, password: sf, options: { captchaToken: await captcha(), data: {
          hesap_turu: 'ogrenci', kaynak: 'uygulama', ad: $('ad').value.trim().slice(0, 60),
          kosul_kabul: an, pazarlama_rizasi: riza, riza_tarihi: riza ? an : null } } });
        if (u.error) {
          if (/already|registered|exists/i.test((u.error.code || '') + ' ' + (u.error.message || ''))) {
            modSec('giris'); $('sifre').value = '';
            $('girisHata').textContent = 'Bu e-postayla zaten bir hesabın var. Şifrenle giriş yap ya da "Şifremi unuttum"a bas.'; return;
          }
          h.textContent = trHata(u.error); return;
        }
        if (!u.data.session) { h.textContent = 'Hesabın açıldı. E-postana gelen bağlantıya tıkla, sonra giriş yap.'; modSec('giris'); return; }
        olay('uye_ol', true);
        try { localStorage.setItem('tt_teklif_hosgeldin', '1'); } catch (x) {}
      } else {
        var g = await sb.auth.signInWithPassword({ email: ep, password: sf, options: { captchaToken: await captcha() } });
        if (g.error) { h.textContent = trHata(g.error); return; }
        olay('giris', true);
      }
      $('sifre').value = '';
      await girisSonrasi();
    } finally { dg.disabled = false; }
  });
  async function girisSonrasi() {
    await yenile();
    olayGonder();
    /* üyelik kapısından gelindiyse kaldığı soruya dön */
    var don = null; try { don = sessionStorage.getItem('tt_uyg_donus'); sessionStorage.removeItem('tt_uyg_donus'); } catch (x) {}
    if (don && /^kaydir\/[a-z0-9\/-]+\.html(#s=\d+)?$/.test(don)) location.href = don;
    else if (window.TTSekme) window.TTSekme.sec('bugun');
  }

  /* GOOGLE İLE GİRİŞ (27.09 Cem "yapalım").
     1.6.0–1.6.6: telefonun yerleşik Google penceresi (Credential Manager, @capgo/capacitor-social-login) denendi;
     Cem'in telefonunda "[16] Account reauth failed" aşılamadı. 1.6.7: SİTEYLE AYNI web akışı — Supabase Google OAuth
     sayfası uygulama içi tarayıcıda (Custom Tabs / SFSafariViewController) açılır, bitince
     com.tetikte.app://giris#access_token=… adresiyle uygulamaya döner (implicit akış, detectSessionInUrl kapalı → elle setSession).
     ŞART: Supabase → Authentication → URL Configuration → Redirect URLs listesinde com.tetikte.app://giris (Cem ekler).
     Android: MainActivity'ye intent-filter (mobil-android.yml); iOS: CFBundleURLSchemes'e com.tetikte.app (mobil-ios.yml).
     Onay: düğmenin üstündeki satır; yeni hesapta meta alanları e-postalı üyelikle AYNI; pazarlama rızası false (İYS). */
  var G_DONUS = 'com.tetikte.app://giris';
  var yerelMi = !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
  async function googleTamam(u) {
    var meta = (u && u.user_metadata) || {};
    var yeni = u && u.created_at && (Date.now() - new Date(u.created_at).getTime() < 120000);
    if (!meta.kosul_kabul) {
      var an = new Date().toISOString();
      await sb.auth.updateUser({ data: { hesap_turu: meta.hesap_turu || 'ogrenci', kaynak: meta.kaynak || 'uygulama-google',
        kosul_kabul: an, pazarlama_rizasi: false, riza_tarihi: null } }); /* kaynak: uygulama-google ya da Apple (aynı akış) */
    }
    if (yeni) { olay('uye_ol', true); try { localStorage.setItem('tt_teklif_hosgeldin', '1'); } catch (x) {} }
    else olay('giris', true);
    await girisSonrasi();
  }
  /* APPLE İLE GİRİŞ (27.09, App Store 4.8: Google girişi olan uygulamada zorunlu). Yalnız iPhone.
     Apple geliştirici: com.tetikte.app kimliğinde "Sign in with Apple" AÇIK (API ile, 27.09).
     Supabase → Providers → Apple: Client IDs = com.tetikte.app (yerel belirteç için gizli anahtar gerekmez). */
  var SLA = yerelMi && window.Capacitor.getPlatform && window.Capacitor.getPlatform() === 'ios' && P.SocialLogin;
  async function sha256Hex(s) {
    var b = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
    return [].map.call(new Uint8Array(b), function (x) { return ('0' + x.toString(16)).slice(-2); }).join('');
  }
  if (SLA && $('appleDugme') && $('googleKutu')) {
    $('googleKutu').hidden = false; $('appleDugme').hidden = false;
    var aHazir = null;
    $('appleDugme').addEventListener('click', async function () {
      var h = $('googleHata'), b = this; h.textContent = ''; b.disabled = true;
      try {
        if (!aHazir) aHazir = SLA.initialize({ apple: {} });
        await aHazir;
        var ham = [].map.call(crypto.getRandomValues(new Uint8Array(16)), function (x) { return ('0' + x.toString(16)).slice(-2); }).join('');
        var r = await SLA.login({ provider: 'apple', options: { scopes: ['email', 'name'], nonce: await sha256Hex(ham) } });
        var tok = r && r.result && r.result.idToken;
        if (!tok) throw new Error('Apple kimlik belirteci gelmedi');
        var s = await sb.auth.signInWithIdToken({ provider: 'apple', token: tok, nonce: ham });
        if (s.error) throw s.error;
        var pr = (r.result && r.result.profile) || {};
        var ad = [pr.givenName, pr.familyName].filter(Boolean).join(' ');
        if (ad && s.data && s.data.user && !(s.data.user.user_metadata || {}).ad) { try { await sb.auth.updateUser({ data: { ad: ad.slice(0, 60) } }); } catch (x) {} }
        await googleTamam(s.data && s.data.user);
      } catch (err) {
        aHazir = null;
        var m = String((err && err.message) || err || '');
        if (!/cancel|1001/i.test(m)) h.textContent = 'Apple girişi açılamadı. Tekrar dene ya da e-postayla devam et. (Kod: ' + m.slice(0, 160) + ')';
      } finally { b.disabled = false; }
    });
  }
  if (yerelMi && P.Browser && P.App && $('googleKutu')) {
    $('googleKutu').hidden = false;
    $('googleDugme').addEventListener('click', async function () {
      var h = $('googleHata'), b = this; h.textContent = ''; b.disabled = true;
      try {
        var r = await sb.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: G_DONUS, skipBrowserRedirect: true } });
        if (r.error || !r.data || !r.data.url) throw (r.error || new Error('giriş adresi alınamadı'));
        await P.Browser.open({ url: r.data.url, presentationStyle: 'popover' });
      } catch (err) {
        h.textContent = 'Google girişi açılamadı. Tekrar dene ya da e-postayla devam et. (Kod: ' + String((err && err.message) || err).slice(0, 160) + ')';
      } finally { setTimeout(function () { b.disabled = false; }, 1500); }
    });
    /* dönüş: com.tetikte.app://giris#access_token=…&refresh_token=… (hata: #error=…&error_description=…) */
    P.App.addListener('appUrlOpen', async function (ev) {
      var url = (ev && ev.url) || '';
      if (url.indexOf(G_DONUS) !== 0) return;
      try { await P.Browser.close(); } catch (x) {}
      var h = $('googleHata'); if (h) h.textContent = '';
      var parca = url.split('#')[1] || url.split('?')[1] || '';
      var q = {}; parca.split('&').forEach(function (kv) { var i = kv.indexOf('='); if (i > 0) q[decodeURIComponent(kv.slice(0, i))] = decodeURIComponent(kv.slice(i + 1).replace(/\+/g, ' ')); });
      try {
        if (q.error) throw new Error(q.error_description || q.error);
        var s;
        if (q.access_token && q.refresh_token) s = await sb.auth.setSession({ access_token: q.access_token, refresh_token: q.refresh_token });
        else if (q.code) s = await sb.auth.exchangeCodeForSession(q.code);
        else throw new Error('dönüşte oturum yok');
        if (s.error) throw s.error;
        await googleTamam(s.data && s.data.user);
      } catch (err) {
        if (window.TTSekme) window.TTSekme.sec('hesap', 'giris');
        if (h) h.textContent = 'Google girişi tamamlanmadı. (Kod: ' + String((err && err.message) || err).slice(0, 160) + ')';
      }
    });
  }
  $('sifreUnuttum').addEventListener('click', async function () {
    var ep = $('eposta').value.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(ep)) { $('girisHata').textContent = 'Önce hesabının e-posta adresini yaz.'; return; }
    var b = this; b.disabled = true;
    try {
      var r = await sb.auth.resetPasswordForEmail(ep, { redirectTo: SIFRE_DONUS, captchaToken: await captcha() });
      /* 02.10: Supabase hesap varlığını söylemez; mesaj da öyle. Bağlantı tetikte.com'da "Yeni şifre belirle" ekranını açar. */
      $('girisHata').textContent = r.error ? trHata(r.error)
        : ep + ' adresine kayıtlı bir hesap varsa şifre yenileme bağlantısı gönderdik (hesap@tetikte.com). Gelen kutunda yoksa Gereksiz klasörüne bak. Bağlantıda yeni şifreni belirle, sonra buradan giriş yap. Gelmezse: destek@tetikte.com';
    } finally { setTimeout(function () { b.disabled = false; }, 60000); }
  });
  $('cikis').addEventListener('click', async function () {
    await window.TT.cikis(sb);
    try { localStorage.removeItem(INDIRME_ANAHTARI); } catch (e) {}
    girisCiz();
  });
  $('cihazlar').addEventListener('click', function () { disAc('https://tetikte.com/ogrenci.html#cihazlarim'); });
  /* hesap silme: uygulama içinden (Apple 5.1.1(v)); SQL hesabimi_sil basılmamışsa eski yol (e-posta) */
  $('hesapSil').addEventListener('click', async function () {
    if (!confirm('Hesabın ve ilerlemen kalıcı olarak silinir. Hesabında açık bir paket varsa o da silinir ve geri alınamaz. Devam edilsin mi?')) return;
    var s = await sb.rpc('hesabimi_sil').catch(function (x) { return { error: x }; });
    if (!s.error && s.data && s.data.tamam) {
      olay('hesap_sil'); olayGonder();
      await window.TT.cikis(sb).catch(function () {});
      try { ['tt_ilerleme', INDIRME_ANAHTARI, 'tt_uyg_girisli'].forEach(function (a) { localStorage.removeItem(a); }); } catch (e) {}
      alert('Hesabın silindi.');
      location.reload();
      return;
    }
    var ep = ($('hesapEposta').textContent || '').replace(/^.*: /, '');
    var govde = 'Merhaba,\n\nTetikte hesabımın ve verilerimin silinmesini istiyorum.\nHesap e-postası: ' + ep + '\n';
    location.href = 'mailto:' + HESAP_SIL_EPOSTA + '?subject=' + encodeURIComponent('hesabımı sil') + '&body=' + encodeURIComponent(govde);
  });

  /* ---------- günlük hatırlatıcı (yerel bildirim; sunucu yok, veri cihazdan çıkmaz) ---------- */
  var HAT_ANAHTARI = 'tt_uyg_hatirlatici', HAT_ID = 1;
  function hatAyar() { try { return JSON.parse(localStorage.getItem(HAT_ANAHTARI) || 'null') || { acik: false, saat: '20:00' }; } catch (e) { return { acik: false, saat: '20:00' }; } }
  async function hatKur(ayar) {
    var LN = P.LocalNotifications;
    await LN.cancel({ notifications: [{ id: HAT_ID }] }).catch(function () {});
    if (!ayar.acik) { $('hatNot').textContent = ''; return true; }
    var izin = await LN.requestPermissions();
    if (izin.display !== 'granted') { $('hatNot').textContent = 'Bildirim izni verilmedi. Telefon ayarlarından Tetikte bildirimlerini açabilirsin.'; return false; }
    var sa = ayar.saat.split(':');
    await LN.schedule({ notifications: [{
      id: HAT_ID, title: 'Tetikte', body: 'Bugünün soruları seni bekliyor. Birkaç soruyla seriyi koru.',
      /* 27.09: isExactNotification:false → eklenti "Alarmlar ve hatırlatıcılar" ayar sayfasını AÇMAZ, kesin olmayan alarm kurar
         (birkaç dakika sapabilir; çalışma hatırlatması için yeterli). SCHEDULE_EXACT_ALARM izni derlemede manifestten sökülür
         (mobil-android.yml) — Play, alarm uygulaması olmayana bu izni gerekçesiz vermiyor. */
      schedule: { on: { hour: +sa[0], minute: +sa[1] }, allowWhileIdle: true }, isExactNotification: false
    }] });
    $('hatNot').textContent = 'Her gün ' + ayar.saat + '’de hatırlatılacak.';
    return true;
  }
  function hatBaslat() {
    if (!yerel || !P.LocalNotifications) { goster('hatirlatici', false); return; }
    var a = hatAyar();
    $('hatAcik').checked = a.acik; $('hatSaat').value = a.saat;
    if (a.acik) $('hatNot').textContent = 'Her gün ' + a.saat + '’de hatırlatılacak.';
    var degisti = async function () {
      var yeni = { acik: $('hatAcik').checked, saat: $('hatSaat').value || '20:00' };
      var tamam = await hatKur(yeni).catch(function () { return false; });
      if (!tamam && yeni.acik) { yeni.acik = false; $('hatAcik').checked = false; }
      try { localStorage.setItem(HAT_ANAHTARI, JSON.stringify(yeni)); } catch (e) {}
    };
    $('hatAcik').addEventListener('change', degisti);
    /* ilk açılış bunu çağırır: izin sonucu beklenir (reddedilirse anahtar kapalı kalır, kişiye söylenir) */
    window.TTHatirlat = { kur: async function (saat) {
      $('hatSaat').value = saat; $('hatAcik').checked = true;
      var tamam = await hatKur({ acik: true, saat: saat }).catch(function () { return false; });
      if (!tamam) $('hatAcik').checked = false;
      try { localStorage.setItem(HAT_ANAHTARI, JSON.stringify({ acik: !!tamam, saat: saat })); } catch (e) {}
      return !!tamam;
    } };
    $('hatSaat').addEventListener('change', function () { if ($('hatAcik').checked) degisti(); });
  }

  /* Android geri tuşu: sayfa geçmişi varsa geri, yoksa uygulamadan çık. */
  if (P.App && P.App.addListener) {
    P.App.addListener('backButton', function (d) { if (d && d.canGoBack) history.back(); else P.App.exitApp(); });
  }

  async function yenile() {
    var k = await window.TT.kullanici(sb);
    if (k) return anaCiz(k);
    girisCiz();
    if (location.hash === '#giris') modSec('giris');
    if (location.hash === '#uyeol') modSec('uye');
  }

  $('surum').textContent = 'Sürüm ' + K.surum + ' · ' + K.derleme;
  try { sb = window.TT.istemci(); }
  catch (e) { $('liste').textContent = 'Uygulama başlatılamadı.'; return; }
  ucretsizCiz();
  hatBaslat();
  olay('ilk_acilis', true);
  yenile().then(olayGonder, olayGonder);
  document.addEventListener('visibilitychange', function () { if (!document.hidden) olayGonder(); });
  window.addEventListener('pageshow', olayGonder);
})();
