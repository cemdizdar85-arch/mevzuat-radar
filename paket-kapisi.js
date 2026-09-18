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
    kapiCoz({ acik: false, tur: tur });
    var baslik, metin, dugmeler;
    if (tur === 'giris') {
      baslik = 'Bu bölüm pakete dahil';
      metin = 'Soru bankasının tamamı, deneme setleri ve "sınav gibi" modu paket sahiplerine açık. Paketin varsa giriş yap.';
      dugmeler = '<a class="pk-ana" href="' + KOK + 'ogrenci.html?sonra=' + sonraAdresi() + '">Giriş yap</a>' +
        '<a href="' + KOK + 'fiyat.html">Paketleri gör</a>' +
        '<a href="' + KOK + 'ucretsiz-dene.html">Önce ücretsiz dene</a>';
    } else if (tur === 'paket') {
      baslik = 'Hesabında aktif paket yok';
      metin = 'Bu sayfa pakete dahil. Paketi aldığında hesabına tanımlanır ve buradan devam edersin.';
      dugmeler = '<a class="pk-ana" href="' + KOK + 'satin-al.html">Paketi al</a>' +
        '<a href="' + KOK + 'ucretsiz-dene.html">Önce ücretsiz dene</a>';
    } else {
      baslik = 'Bağlantı kurulamadı';
      metin = 'Paket bilgin kontrol edilemedi. İnternet bağlantını kontrol edip yeniden dene.';
      dugmeler = '<a class="pk-ana" href="' + location.href.replace(/"/g, '%22') + '">Yeniden dene</a>' +
        '<a href="' + KOK + 'ucretsiz-dene.html">Ücretsiz dene</a>';
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
      var sinavi = /\/kaydir\/sgs\//.test(location.pathname) || /sinav-gibi\.html$/.test(location.pathname) ? 'sgs'
        : (/\/kaydir\/smmm\//.test(location.pathname) ? 'yeterlilik' : null);
      var kapsar = function (paket) {
        var p = String(paket == null ? '' : paket).trim().toLowerCase();
        if (!sinavi || !p || p === 'tam' || p === 'kurucu') return true;
        if (sinavi === 'sgs') return p === 'sgs' || p.indexOf('sgs-') === 0 || p === 'sinav-249';
        if (sinavi === 'yeterlilik') return p === 'yeterlilik' || p.indexOf('yeterlilik-') === 0 || p === 'smmm' || p === 'yeterlilik-kgk';
        return false;
      };
      if ((r.data || []).some(function (x) { return (!x.bitis || x.bitis >= bugun) && kapsar(x.paket); })) return ac();
      perde('paket');
    } catch (e) { clearTimeout(zaman); perde('hata'); }
  });
})();
