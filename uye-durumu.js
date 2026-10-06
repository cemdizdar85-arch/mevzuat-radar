/* uye-durumu.js — ÜYE DURUMU · ÜÇ SINAV (15.09.2026)
 *
 * Cem 15.09: "kurumsal firmalar üyeler ile yeni üyelere farklı giriş yapıyor" +
 * "sınava giriş, bitirme ve KGK nasıl girecek, onları ayırmak lazım; plan yaparken hepsi için yap".
 * Sayfa herkes için tek; düğmenin ne diyeceğine bu dosya karar verir. Tek kaynak:
 *   - SINAVLAR  : üç sınavın adı, sayfaları, içerik hazır mı
 *   - durum     : ziyaretci · uye (paketsiz) · aktif · bitmis  — SINAV BAŞINA
 *
 * Paket -> sınav eşlemesi radar-app/sql/TASLAK-2026-09-15-paket-soru.sql ile AYNI:
 *   sgs · yeterlilik / yeterlilik-N / yeterlilik-tum -> yeterlilik · kgk-M / kgk-tum -> kgk ·
 *   yeterlilik-kgk -> ikisi · tam / kurucu / boş -> üçü. 'sinav-249' (07.2026 varsayılanı) SGS dönemi paketidir -> sgs.
 * paket_uyeler bugün kişi başına tek satır (birincil anahtar user_id); birden çok satır gelirse de doğru okunur.
 *
 * ⚠ Bu dosya YALNIZ GÖRÜNÜMÜ değiştirir. Kilit sunucudadır (RLS) ve paket-kapisi.js'tedir;
 *   düğmeyle oynayan biri paket içeriğine ulaşamaz.
 *
 * Kullanım:  TetikteUye.hazir.then(function(d){ d.sinavlar.sgs.durum ... })
 *            document.addEventListener('tetikte-uye', function(e){ e.detail ... })
 * Oturum anahtarı cihazda yoksa Supabase kütüphanesi HİÇ indirilmez (ziyaretçi için sıfır yük).
 */
(function () {
  if (window.TetikteUye) return;

  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/uye-durumu\.js.*$/, '') : '';
  var SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
  var SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';

  /* icerik:false = soru sayfaları henüz yayında değil -> satış yok, ön kayıt var (Cem 15.09 "1.2.3 yap"). */
  var SINAVLAR = {
    sgs: {
      kod: 'sgs', ad: 'Staja Giriş', uzun: 'SMMM Staja Giriş (SGS)', icerik: true,
      dene: 'ucretsiz-dene.html?sinav=sgs', olc: 'seviye-testi.html',
      gir: 'sinav-gibi.html', devam: 'sorular.html#sgs',   /* 04.10 site turu: kaydir/sgs/index.html taslak dizin (adet + ASCII konu) -> resmî ders listesi */
      al: 'satin-al.html?paket=sgs', fiyat: 'fiyat.html'
    },
    yeterlilik: {
      kod: 'yeterlilik', ad: 'Yeterlilik', uzun: 'SMMM Yeterlilik (staj bitirme)', icerik: true,   /* 24.09 Cem: satışta (fiyat-motoru.js ICERIK_HAZIR ile aynı) */
      dene: 'ucretsiz-dene.html?sinav=yeterlilik', onkayit: 'ucretsiz-dene.html?sinav=yeterlilik#onkayit',
      /* 23.09 Cem: her sınavın sabit 30 soruluk seviye testi -> içerik hazırlanırken de "ölç" düğmesi var */
      olc: 'seviye-testi.html?sinav=yeterlilik', olcDk: 40,
      /* 24.09 satışa açılınca gereken alanlar. sinav-gibi.html yalnız SGS'dir -> Yeterlilik'te giriş = kendi soru bankası.
         Satın alma ders seçimli -> fiyat sayfasına (Yeterlilik kartı). Ücretsiz deneme = 70 soruluk açık vitrin. */
      gir: 'sorular.html#smmm', devam: 'sorular.html#smmm',
      /* 01.10 Cem "önce tüm sınavı yaz": Becker/UWorld/Gleim gibi ana yol tam paket; düğme doğrudan ödemeye, tüm dersler
         seçili gelir (1–4 ders paketleri aynı listede durur). Tek ders kahramanda ikincil bağlantı (alTek). */
      al: 'satin-al.html?paket=yeterlilik-tum', alTek: 'satin-al.html?paket=yeterlilik-1', vitrin: 'kaydir/vitrin/smmm.html?vitrin=1',
      fiyat: 'fiyat.html'
    },
    kgk: {
      kod: 'kgk', ad: 'KGK', uzun: 'Bağımsız Denetçilik (KGK)', icerik: false,
      dene: 'ucretsiz-dene.html?sinav=kgk', onkayit: 'ucretsiz-dene.html?sinav=kgk#onkayit',
      fiyat: 'fiyat.html'
    }
  };
  var SIRA = ['sgs', 'yeterlilik', 'kgk'];

  function paketSinavlari(paket) {
    var p = String(paket == null ? '' : paket).trim().toLowerCase();
    if (!p || p === 'tam' || p === 'kurucu') return SIRA.slice();
    if (p === 'yeterlilik-kgk') return ['yeterlilik', 'kgk'];
    if (p === 'sgs' || p.indexOf('sgs-') === 0 || p === 'sinav-249') return ['sgs'];
    if (p === 'yeterlilik' || p.indexOf('yeterlilik-') === 0 || p === 'smmm') return ['yeterlilik'];
    if (p === 'kgk' || p.indexOf('kgk-') === 0) return ['kgk'];
    return [];
  }

  function bos(oturum, eposta) {
    var s = {};
    SIRA.forEach(function (k) { s[k] = { durum: oturum ? 'uye' : 'ziyaretci', bitis: null, dersler: null }; });
    return { oturum: !!oturum, eposta: eposta || '', sinavlar: s, hata: false };
  }

  function satirlardan(satirlar, eposta) {
    var d = bos(true, eposta);
    var bugun = new Date().toISOString().slice(0, 10);
    (satirlar || []).forEach(function (r) {
      var aktif = !r.bitis || r.bitis >= bugun;
      paketSinavlari(r.paket).forEach(function (k) {
        var o = d.sinavlar[k];
        if (o.durum === 'aktif' && (!aktif || !o.bitis || (r.bitis && o.bitis >= r.bitis))) return;  /* aktif olan kalır; ikisi aktifse geç biten */
        if (o.durum === 'bitmis' && !aktif && o.bitis && r.bitis && o.bitis >= r.bitis) return;
        d.sinavlar[k] = { durum: aktif ? 'aktif' : 'bitmis', bitis: r.bitis || null, dersler: r.dersler || null };
      });
    });
    return d;
  }

  function anahtarVar() {
    try { return Object.keys(localStorage).some(function (k) { return k.indexOf('-auth-token') > -1; }); }
    catch (e) { return false; }
  }

  function kutuphane() {
    return new Promise(function (tamam, red) {
      if (window.supabase && window.supabase.createClient) return tamam();
      var s = document.createElement('script');
      s.src = KOK + 'kutuphane/supabase-2.112.3.js';
      s.onload = function () { tamam(); };
      s.onerror = red;
      (document.head || document.documentElement).appendChild(s);
    });
  }

  /* 07.10 Cem ("tetikte'ye üst üste basınca bir anda sanki üyeliğim yok gibi duruyor"): sunucu cevabı gelene kadar sayfa
     ziyaretçi düğmelerini çiziyordu. Son bilinen durum bu cihazda saklanır (tt_uye_son: yalnız sınav başına durum/bitiş/ders,
     e-posta YOK), oturum anahtarı varken sayfa İLK ÇİZİMİ bununla yapar; sunucu cevabı gelince yine doğrulanır.
     Görünüm içindir; kilit sunucuda (RLS) olduğu için bayat önbellek içerik açmaz. 7 günden eski ya da anahtarsız önbellek atılır. */
  var ONB = 'tt_uye_son';
  function onbellekOku() {
    try {
      if (!anahtarVar()) { localStorage.removeItem(ONB); return null; }
      var o = JSON.parse(localStorage.getItem(ONB) || 'null');
      if (!o || !o.sinavlar || !(Date.now() - (o.zaman || 0) < 7 * 86400000)) return null;
      var d = bos(true, ''), bugun = new Date().toISOString().slice(0, 10);
      SIRA.forEach(function (k) { var x = o.sinavlar[k]; if (!x) return;
        var durum = x.durum === 'aktif' && x.bitis && x.bitis < bugun ? 'bitmis' : x.durum;   /* önbellekteyken süresi dolduysa */
        d.sinavlar[k] = { durum: durum, bitis: x.bitis || null, dersler: x.dersler || null }; });
      d.onbellek = true; return d;
    } catch (e) { return null; }
  }
  function onbellekYaz(d) {
    try {
      if (!d || !d.oturum) { localStorage.removeItem(ONB); return; }
      if (d.hata || d.onbellek) return;   /* okunamadıysa eski önbellek kalır; önbellekten dönen tazelenmiş sayılmaz (süresi uzamasın) */
      var s = {}; SIRA.forEach(function (k) { var x = d.sinavlar[k]; s[k] = { durum: x.durum, bitis: x.bitis, dersler: x.dersler }; });
      localStorage.setItem(ONB, JSON.stringify({ sinavlar: s, zaman: Date.now() }));
    } catch (e) {}
  }
  var ONBELLEK = onbellekOku();

  function yay(d) {
    onbellekYaz(d);
    try { document.dispatchEvent(new CustomEvent('tetikte-uye', { detail: d })); } catch (e) {}
    return d;
  }

  var hazir = (anahtarVar() ? kutuphane().then(async function () {
    var sb = window.__pkSb || (window.__pkSb = window.supabase.createClient(SB_URL, SB_KEY));
    var oturum = (await sb.auth.getSession()).data.session;
    if (!oturum) return bos(false);
    /* supabase-js sorgusu tembeldir: await edilmeden GİTMEZ (19.08 dersi). */
    var r = await sb.from('paket_uyeler').select('paket,bitis,dersler').eq('user_id', oturum.user.id);
    if (r.error) { var h = bos(true, oturum.user.email); h.hata = true; return h; }
    return satirlardan(r.data, oturum.user.email);
  }).catch(function () { var h = bos(anahtarVar()); h.hata = true; return h; })
    : Promise.resolve(bos(false)))
    .then(function (d) { return d && d.hata && d.oturum && ONBELLEK ? ONBELLEK : d; })   /* 07.10: sunucu o an okunamadıysa son bilinen durum kalır (üye birden "ziyaretçi"ye düşmesin) */
    .then(yay);

  function tarihYazi(t) {
    if (!t) return '';
    try { return new Date(t + 'T12:00:00').toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' }); }
    catch (e) { return t; }
  }

  window.TetikteUye = {
    SINAVLAR: SINAVLAR, SIRA: SIRA, hazir: hazir,
    /* 07.10: son bilinen durum (yoksa null) - ilk çizim bununla, sonra hazir ile doğrulanır */
    onbellek: ONBELLEK,
    paketSinavlari: paketSinavlari, tarihYazi: tarihYazi,
    /* paket_uyeler satırları -> sınav başına durum (ogrenci.html girişten hemen sonra kendi okuduğu satırla çağırır) */
    durumHesapla: satirlardan,
    /* seçili sınav cihazda hatırlanır; adres #sinav=kgk ile de gelinebilir */
    seciliSinav: function () {
      /* 30.09 Cem "site sadece SMMM başlama + bitirme": KGK sekmesi gizli; eskiden KGK seçmiş cihaz SGS'ye döner. */
      var m = /(?:^|[#&?])sinav=(sgs|yeterlilik)\b/.exec(location.hash + '&' + location.search);
      if (m) return m[1];
      try { var v = localStorage.getItem('tt_sinav'); if (SINAVLAR[v] && v !== 'kgk') return v; } catch (e) {}
      return 'sgs';
    },
    sinavSec: function (k) { try { if (SINAVLAR[k]) localStorage.setItem('tt_sinav', k); } catch (e) {} }
  };
})();
