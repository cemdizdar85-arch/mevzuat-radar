/* uygulama.js — mağaza uygulamasının ana ekranı (25.09.2026)
 *
 * Ekranlar: giriş · Sınavlarım (hesabın paketine göre) · Ücretsiz dene · Günlük hatırlatıcı · Hesap.
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
  var HESAP_SIL_EPOSTA = 'info@dizdardenetim.com';   // kvkk.html'deki silme kanalıyla AYNI
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
    a.className = 'ders'; a.href = d.yol;
    a.innerHTML = '<span class="ad">' + esc(d.baslik) + '<span class="etiket">' + esc(d.sinavAd || '') +
      (m ? ' · cihazda (' + esc(m.tarih) + ')' : '') + '</span></span>' +
      (indirilebilir ? '<button type="button" class="indir"' + (m ? ' data-durum="cihazda"' : '') + '>' + (m ? 'Yenile' : 'Cihaza indir') + '</button>' : '');
    var dugme = a.querySelector('.indir');
    if (dugme) dugme.addEventListener('click', async function (e) {
      e.preventDefault(); e.stopPropagation();
      dugme.disabled = true; dugme.textContent = 'İniyor…';
      try { var n = await dersIndir(d.yol); dugme.textContent = n + ' soru cihazda'; dugme.setAttribute('data-durum', 'cihazda'); }
      catch (err) { dugme.textContent = 'İnmedi, yeniden dene'; }
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
    goster('giris', false); goster('ana', true); goster('hesap', true);
    $('hesapEposta').textContent = k.email ? 'Giriş yapılan hesap: ' + k.email : '';
    var liste = $('liste'); liste.innerHTML = '<p class="soluk">Paket bilgisi okunuyor…</p>';
    var p;
    try { p = await window.TT.paketler(sb, k.id); }
    catch (e) { liste.innerHTML = '<p class="soluk">Paket bilgisi okunamadı. İnternet bağlantını kontrol et.</p>'; return; }
    rozet(k.cevrimdisi || p.cevrimdisi ? 'Çevrimdışı' : '');
    var acik = (K.paket || []).filter(function (d) { return window.TT.acarMi(p.satir, d.sinav); });
    liste.innerHTML = '';
    acik.forEach(function (d) { liste.appendChild(dersKarti(d, true)); });
    $('anaNot').textContent = acik.length
      ? 'Bir derse dokun, kaldığın yerden devam et. "Cihaza indir" ile internetsiz çözebilirsin.'
      : 'Hesabında bu uygulamada açılabilen bir sınav görünmüyor.';
    if (window.TTMagaza) window.TTMagaza.goster(sb, k, yenile);
    var sinavlar = {};
    acik.forEach(function (d) { sinavlar[d.sinav] = 1; });
    var yakin = (K.yakinda || []).filter(function (d) { return sinavlar[d.sinav]; });
    $('yakinda').innerHTML = yakin.map(function (d) { return '<li>' + esc(d.baslik) + ' <span class="kucuk">(' + esc(d.sinavAd) + ')</span></li>'; }).join('');
    goster('yakindaKutu', yakin.length > 0);
  }

  function girisCiz() {
    goster('ana', false); goster('hesap', false); goster('giris', true); rozet('');
    if (window.TTMagaza) window.TTMagaza.gizle();
  }
  function rozet(t) { $('durumRozet').textContent = t; $('durumRozet').hidden = !t; }

  $('girisForm').addEventListener('submit', async function (e) {
    e.preventDefault();
    $('girisHata').textContent = '';
    var r = await sb.auth.signInWithPassword({ email: $('eposta').value.trim(), password: $('sifre').value });
    if (r.error) { $('girisHata').textContent = trHata(r.error); return; }
    $('sifre').value = '';
    yenile();
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
  $('hesapSil').addEventListener('click', function () {
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
    if (location.hash === '#giris') $('eposta').focus();
  }

  $('surum').textContent = 'Sürüm ' + K.surum + ' · ' + K.derleme;
  try { sb = window.TT.istemci(); }
  catch (e) { $('liste').textContent = 'Uygulama başlatılamadı.'; return; }
  ucretsizCiz();
  hatBaslat();
  yenile();
})();
