/* paket-kapisi.js — PAKET İÇERİĞİ KAPISI (14.09.2026)
 *
 * Cem 14.09: "soru çözme kısmı paralı olacak; deneme amaçlı sadece kendin dene olsun,
 * buraya üye olmayan girememeli." Bu dosya paket içeriği taşıyan sayfaların başına konur
 * (kaydir/sgs/*.html, sinav-gibi.html). Sayfa önce GİZLİ açılır:
 *   - oturum yok            -> "Giriş yap / Paketleri gör / Ücretsiz dene" ekranı
 *   - oturum var, paket yok -> "Paket al / Ücretsiz dene" ekranı
 *   - aktif paket var       -> sayfa açılır
 * Paket bilgisi paket_uyeler tablosundan okunur (RLS: üye yalnız kendi satırını görür).
 *
 * ⚠ DÜRÜST SINIR: Bu kapı GÖRÜNTÜDE kilittir. Soru içeriği bugün sayfa dosyasının içinde ve
 * depoda açık duruyor; bilen biri dosyayı doğrudan indirebilir. Gerçek kilit ADIM 2'dir:
 * paket soruları Supabase'deki kilitli kasadan yalnız paketi olana gelir (kart ödemesi haftası).
 * Açıkta kalan içeriği her gün motor/icerik-nobetcisi.js sayar.
 *
 * Muaf: kaydir/vitrin/ (ücretsiz örnek sorular, ana sayfa çerçevesi).
 * Renk yazılmaz: sayfanın kendi jetonları kullanılır (Kaydır-Çöz: --bg/--kart/--yazi,
 * site: --taban/--panel/--ink).
 */
(function () {
  if (/\/kaydir\/vitrin\//.test(location.pathname)) return;

  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/paket-kapisi\.js.*$/, '') : '/';
  var SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
  var SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var kok = document.documentElement;
  var bitti = false;
  /* 16.09 ADIM 2: kasa modundaki sayfa (kasa-yukle.js) soruları kapı AÇILINCA çeker.
     Sonuç: {acik:true, sb:<istemci>} ya da {acik:false}. Perde çıkarsa kasaya hiç istek gitmez. */
  var kapiCoz;
  window.__pkKapi = new Promise(function (r) { kapiCoz = r; });

  var st = document.createElement('style');
  st.textContent =
    'html.pk-bekle body{visibility:hidden}' +
    '#pkPerde{position:fixed;inset:0;z-index:2147483000;display:flex;align-items:center;justify-content:center;padding:22px;' +
    'background:var(--bg,var(--taban));color:var(--yazi,var(--ink));font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;visibility:visible}' +
    '#pkPerde .pk-kutu{max-width:440px;width:100%;text-align:center;background:var(--kart,var(--panel));border:1px solid var(--cizgi,var(--line));border-radius:16px;padding:28px 22px}' +
    '#pkPerde h2{margin:0 0 8px;font-size:21px;letter-spacing:-.3px}' +
    '#pkPerde p{margin:0 0 18px;font-size:14.5px;line-height:1.6;color:var(--dim)}' +
    '#pkPerde a{display:block;margin:8px 0 0;padding:12px 14px;border-radius:11px;font-weight:750;font-size:15px;text-decoration:none;' +
    'border:1px solid var(--cizgi,var(--line2));color:var(--yazi,var(--ink))}' +
    '#pkPerde a.pk-ana{background:var(--mavi,var(--accent2));border-color:transparent;color:var(--ustYazi,var(--taban))}' +
    '#pkPerde .pk-kilit{font-size:26px;margin-bottom:6px}';
  (document.head || kok).appendChild(st);
  kok.classList.add('pk-bekle');

  function sonraAdresi() {
    return encodeURIComponent(location.pathname.replace(/^\//, '') + location.search + location.hash);
  }
  function ac() {
    if (bitti) return; bitti = true;
    kok.classList.remove('pk-bekle');
    kapiCoz({ acik: true, sb: window.__pkSb });
  }
  function perde(tur) {
    if (bitti) return; bitti = true;
    /* 07.10 Cem ("pakete dahil dediğimde ücretsiz soru çöz yine 10 soru çıkıyor"): ücretsiz deneme o sınavın 30 soruluk seviye
       testine gider (10 soruluk sabit örnek sayfası değil). Sınav sayfa yolundan: kaydir/smmm = Yeterlilik, öteki SGS. */
    var yetSayfa = /\/kaydir\/smmm\//.test(location.pathname) || /[?&]sinav=(smmm|yeterlilik)\b/i.test(location.search);
    var ucretsiz = KOK + (yetSayfa ? 'seviye-testi.html?sinav=yeterlilik' : 'seviye-testi.html');
    /* 08.10 Cem ("Staja Giriş sayfasındaysam bitirme fiyatları gelmesin"): satın alma ve fiyat bulunulan sınava odaklı
       (satin-al ?paket= o sınavın grubunu açar; fiyat ?sinav= tek sınavı gösterir). */
    var satinAl = KOK + 'satin-al.html?paket=' + (yetSayfa ? 'yeterlilik-1' : 'sgs');
    var fiyatAdr = KOK + 'fiyat.html?sinav=' + (yetSayfa ? 'yeterlilik' : 'sgs');
    kapiCoz({ acik: false, tur: tur });
    var baslik, metin, dugmeler;
    if (tur === 'giris') {
      baslik = 'Bu bölüm pakete dahil';
      metin = 'Soru bankasının tamamı, deneme setleri ve "sınav gibi" modu paket sahiplerine açık. Paketin varsa giriş yap.';
      dugmeler = '<a class="pk-ana" href="' + KOK + 'ogrenci.html?sonra=' + sonraAdresi() + '">Giriş yap</a>' +
        '<a href="' + fiyatAdr + '">Paketleri gör</a>' +
        '<a href="' + ucretsiz + '">Önce ücretsiz 30 soru çöz</a>';
    } else if (tur === 'paket') {
      baslik = 'Hesabında aktif paket yok';
      metin = 'Bu sayfa pakete dahil. Paketi aldığında hesabına tanımlanır ve buradan devam edersin.';
      dugmeler = '<a class="pk-ana" href="' + satinAl + '">Paketi al</a>' +
        '<a href="' + ucretsiz + '">Önce ücretsiz 30 soru çöz</a>';
    } else {
      baslik = 'Bağlantı kurulamadı';
      metin = 'Paket bilgin kontrol edilemedi. İnternet bağlantını kontrol edip yeniden dene.';
      dugmeler = '<a class="pk-ana" href="' + location.href.replace(/"/g, '%22') + '">Yeniden dene</a>' +
        '<a href="' + ucretsiz + '">Önce ücretsiz 30 soru çöz</a>';
    }
    var cizim = function () {
      var d = document.createElement('div');
      d.id = 'pkPerde';
      d.setAttribute('role', 'dialog'); d.setAttribute('aria-modal', 'true');
      d.innerHTML = '<div class="pk-kutu"><div class="pk-kilit" aria-hidden="true">🔒</div><h2>' + baslik + '</h2><p>' + metin + '</p>' + dugmeler + '</div>';
      document.body.appendChild(d);
      document.body.style.overflow = 'hidden';
    };
    if (document.body) cizim(); else document.addEventListener('DOMContentLoaded', cizim);
  }

  /* 23.09 HESAP PAYLAŞIM KORUMASI (cihaz-kapisi.js): tek aktif ekran + en fazla 3 cihaz +
     filigran. Yalnız aktif paket görülünce, sayfa AÇILDIKTAN sonra yüklenir; betik inmezse
     ya da SQL basılmamışsa hiçbir şey kapanmaz (fail-open). */
  function cihazKorumasi(sb, kullanici) {
    try {
      var calistir = function () { if (window.ttCihaz) window.ttCihaz.koru(sb, kullanici); };
      if (window.ttCihaz) return calistir();
      var s = document.createElement('script');
      s.src = KOK + 'cihaz-kapisi.js';
      s.onload = calistir;
      (document.head || kok).appendChild(s);
    } catch (e) {}
  }

  /* 29.09 KALDIĞIN YERDEN DEVAM (ilerleme-web.js): uygulamayla aynı kayıt, hesaba eşitlenir. Yalnız Kaydır-Çöz
     sayfalarında (#akis), sayfa AÇILDIKTAN sonra; betik inmezse sayfa olduğu gibi çalışır (fail-open). */
  function ilerleme(sb, kullanici) {
    try {
      if (!/\/kaydir\//.test(location.pathname)) return;
      var calistir = function () { if (window.ttIlerlemeWeb) window.ttIlerlemeWeb.kur(sb, kullanici); };
      if (window.ttIlerlemeWeb) return calistir();
      var s = document.createElement('script');
      s.src = KOK + 'ilerleme-web.js';
      s.onload = calistir;
      (document.head || kok).appendChild(s);
    } catch (e) {}
  }

  /* 07.10 Cem ("Tekrar et" -> 1 yap): Yanlışlarım/Hesabım "Tekrar et" ders sayfasını #kutu ile açar. Sayfanın kendi
     kutuEkraniAc() işlevi (Kaydır-Çöz şablonu) hazır olunca bir kez çağrılır; adresten #kutu silinir (yenilemede tekrar açılmasın).
     İşlev 15 sn içinde gelmezse sessizce vazgeçer (sayfa olduğu gibi çalışır). */
  function kutuyuAc() {
    try {
      if (!/\/kaydir\//.test(location.pathname) || location.hash !== '#kutu') return;
      var n = 0, t = setInterval(function () {
        if (typeof window.kutuEkraniAc === 'function' && document.querySelector('#akis .kart')) {
          clearInterval(t);
          try { history.replaceState(null, '', location.pathname + location.search); } catch (e) {}
          window.kutuEkraniAc();
        } else if (++n > 60) clearInterval(t);
      }, 250);
    } catch (e) {}
  }

  var zaman = setTimeout(function () { perde('hata'); }, 9000);

  function kutuphane(sonra) {
    if (window.supabase && window.supabase.createClient) return sonra();
    var s = document.createElement('script');
    s.src = KOK + 'kutuphane/supabase-2.112.3.js';
    s.onload = sonra;
    s.onerror = function () { clearTimeout(zaman); perde('hata'); };
    (document.head || kok).appendChild(s);
  }

  kutuphane(async function () {
    try {
      var sb = window.__pkSb || (window.__pkSb = window.supabase.createClient(SB_URL, SB_KEY));
      var oturum = (await sb.auth.getSession()).data.session;
      if (!oturum) { clearTimeout(zaman); return perde('giris'); }
      /* supabase-js sorgusu tembeldir: await edilmeden GİTMEZ (19.08 dersi). */
      var r = await sb.from('paket_uyeler').select('paket,bitis').eq('user_id', oturum.user.id);
      clearTimeout(zaman);
      if (r.error) return perde('hata');
      var bugun = new Date().toISOString().slice(0, 10);
      /* 15.09 ÜÇ SINAV: paket SINAVI kapsamalı. Önceden herhangi bir aktif paket SGS sayfalarını açıyordu —
         KGK paketi alan biri SGS soru bankasına girerdi. Eşleme uye-durumu.js paketSinavlari ile AYNI. */
      /* 18.09 (Cem "kasadaki soruları siteye bağla"): bitirme (yeterlilik) sayfaları kaydir/smmm/ altında açıldı.
         O yol tanınmadığı için sinavi=null kalıyordu ve kapsar() HER aktif pakete "true" diyordu → SGS paketi olan
         bitirme soru bankasını açardı (15.09'da SGS için kapatılan açığın aynısı). Eşleme uye-durumu.js
         paketSinavlari ile AYNI: yeterlilik | yeterlilik-* | smmm | yeterlilik-kgk | tam | kurucu. */
      /* 07.10 Sık Çıkan Konular Denemesi: sinav-gibi.html?sinav=smmm Yeterlilik setidir → Yeterlilik paketi aranır */
      var sgYet = /sinav-gibi\.html$/.test(location.pathname) && /[?&]sinav=(smmm|yeterlilik)\b/i.test(location.search);
      var sinavi = sgYet ? 'yeterlilik'
        : (/\/kaydir\/sgs\//.test(location.pathname) || /sinav-gibi\.html$/.test(location.pathname) ? 'sgs'
        : (/\/kaydir\/smmm\//.test(location.pathname) ? 'yeterlilik' : null));
      var kapsar = function (paket) {
        var p = String(paket == null ? '' : paket).trim().toLowerCase();
        if (!sinavi || !p || p === 'tam' || p === 'kurucu') return true;
        if (sinavi === 'sgs') return p === 'sgs' || p.indexOf('sgs-') === 0 || p === 'sinav-249';
        if (sinavi === 'yeterlilik') return p === 'yeterlilik' || p.indexOf('yeterlilik-') === 0 || p === 'smmm' || p === 'yeterlilik-kgk';
        return false;
      };
      if ((r.data || []).some(function (x) { return (!x.bitis || x.bitis >= bugun) && kapsar(x.paket); })) {
        ac();                               // ÖNCE sayfa açılır ...
        kutuyuAc();                         // 07.10: "Tekrar et" bağlantısı (#kutu) yanlış kutusunu açık getirir
        cihazKorumasi(sb, oturum.user);     // ... SONRA paylaşım koruması (arızada üye içeride kalır)
        ilerleme(sb, oturum.user);          // ... ve kaldığın yerden devam (hesaba eşitlenir)
        return;
      }
      perde('paket');
    } catch (e) { clearTimeout(zaman); perde('hata'); }
  });
})();

/* 04.10 Cem "1 ve 2 yap": soru kartı araçlarının KULLANIM SAYACI (ilk hafta "kullanılıyor mu?" sorusu için).
   Yalnız olay adı gider (kart/isaretle-ac, kart/isaret, kart/notum-ac, kart/notum-yaz) - soru metni, not metni, kişi verisi GİTMEZ.
   Aynı olay bir sayfa açılışında bir kez sayılır (kişi başı yaklaşık kullanım, tıklama yağmuru değil). Sayaç GoatCounter (sitenin geri kalanıyla aynı). */
(function () {
  if (window.__kartSayac) return; window.__kartSayac = true;
  var sayildi = {};
  function say(ad) {
    if (sayildi[ad]) return; sayildi[ad] = 1;
    var gonder = function () { try { window.goatcounter.count({ path: 'kart/' + ad, title: 'Soru kartı: ' + ad, event: true }); } catch (e) {} };
    if (window.goatcounter && typeof window.goatcounter.count === 'function') return gonder();
    if (!document.querySelector('script[data-goatcounter]')) {
      var s = document.createElement('script'); s.async = true; s.src = '//gc.zgo.at/count.js';
      s.setAttribute('data-goatcounter', 'https://mevzuatradar.goatcounter.com/count');
      s.setAttribute('data-goatcounter-settings', '{"no_onload": true}');
      document.head.appendChild(s);
    }
    var n = 0, t = setInterval(function () { if (window.goatcounter && typeof window.goatcounter.count === 'function') { clearInterval(t); gonder(); } else if (++n > 40) clearInterval(t); }, 250);
  }
  document.addEventListener('click', function (e) {
    var b = e.target && e.target.closest && e.target.closest('.bVurgu, .bNotum');
    if (b) { say(b.classList.contains('bVurgu') ? 'isaretle-ac' : 'notum-ac'); return; }
    if (e.target && e.target.closest && e.target.closest('.vurguKip .soru')) say('isaret');
  }, true);
  document.addEventListener('input', function (e) { if (e.target && e.target.classList && e.target.classList.contains('notumAlan')) say('notum-yaz'); }, true);
})();

/* 04.10 "💬 Nöbetçiye sor": soru sayfalarında nobetci-sor.js yüklenir (kart şablonuna dokunmadan; basım gerekmez).
   Sayaç: Nöbetçi düğmesi de yukarıdaki kart sayacına katılır (kart/nobetci-ac). */
(function () {
  if (!/\/kaydir\//.test(location.pathname) || window.__nobetciYuklendi) return; window.__nobetciYuklendi = true;
  var bu = document.querySelector('script[src*="paket-kapisi.js"]'), kok = bu ? bu.src.replace(/paket-kapisi\.js.*$/, '') : '/';
  var s = document.createElement('script'); s.src = kok + 'nobetci-sor.js'; s.defer = true; document.head.appendChild(s);
  document.addEventListener('click', function (e) { var b = e.target && e.target.closest && e.target.closest('.bNobetci'); if (b && window.goatcounter && window.goatcounter.count) { try { window.goatcounter.count({ path: 'kart/nobetci-ac', title: 'Soru kartı: nobetci-ac', event: true }); } catch (x) {} } }, true);
})();
