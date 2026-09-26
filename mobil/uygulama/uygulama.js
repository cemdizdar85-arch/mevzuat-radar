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
    if (d.adet) alt.push(d.adet.toLocaleString('tr-TR') + ' soru');
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
    var liste = $('liste'); liste.innerHTML = '<p class="soluk">Paket bilgisi okunuyor…</p>';
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
  function olayGonder() { if (window.TTOlay && window.TT && window.TT.SB_URL) window.TTOlay.gonder(window.TT.SB_URL, window.TT.SB_KEY, platformAdi()); }

  $('girisForm').addEventListener('submit', async function (e) {
    e.preventDefault();
    var h = $('girisHata'); h.textContent = '';
    var ep = $('eposta').value.trim(), sf = $('sifre').value;
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(ep)) { h.textContent = 'E-posta adresini yaz.'; return; }
    if (sf.length < 6) { h.textContent = 'Şifre en az 6 karakter olmalı.'; return; }
    var dg = $('girisGonder'); dg.disabled = true;
    try {
      if (mod === 'uye') {
        if (!$('kosul').checked) { h.textContent = 'Üye olmak için sözleşmeyi ve aydınlatma metnini kabul etmen gerekiyor.'; return; }
        var an = new Date().toISOString(), riza = $('riza').checked;
        var u = await sb.auth.signUp({ email: ep, password: sf, options: { data: {
          hesap_turu: 'ogrenci', kaynak: 'uygulama', ad: $('ad').value.trim().slice(0, 60),
          kosul_kabul: an, pazarlama_rizasi: riza, riza_tarihi: riza ? an : null } } });
        if (u.error) { h.textContent = /already|registered|exists/i.test(u.error.message || '') ? 'Bu e-postayla zaten hesap var. "Giriş yap"a geç.' : trHata(u.error); return; }
        if (!u.data.session) { h.textContent = 'Hesabın açıldı. E-postana gelen bağlantıya tıkla, sonra giriş yap.'; modSec('giris'); return; }
        olay('uye_ol', true);
      } else {
        var g = await sb.auth.signInWithPassword({ email: ep, password: sf });
        if (g.error) { h.textContent = trHata(g.error); return; }
        olay('giris', true);
      }
      $('sifre').value = '';
      await yenile();
      olayGonder();
      /* üyelik kapısından gelindiyse kaldığı soruya dön */
      var don = null; try { don = sessionStorage.getItem('tt_uyg_donus'); sessionStorage.removeItem('tt_uyg_donus'); } catch (x) {}
      if (don && /^kaydir\/[a-z0-9\/-]+\.html(#s=\d+)?$/.test(don)) location.href = don;
      else if (window.TTSekme) window.TTSekme.sec('bugun');
    } finally { dg.disabled = false; }
  });
  $('sifreUnuttum').addEventListener('click', async function () {
    var ep = $('eposta').value.trim();
    if (!ep) { $('girisHata').textContent = 'Önce e-posta adresini yaz.'; return; }
    var r = await sb.auth.resetPasswordForEmail(ep, { redirectTo: SIFRE_DONUS });
    $('girisHata').textContent = r.error ? trHata(r.error) : 'Şifre yenileme bağlantısı e-postana gönderildi.';
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
      schedule: { on: { hour: +sa[0], minute: +sa[1] } }
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
