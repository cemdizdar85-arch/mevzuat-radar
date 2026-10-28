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
  if (/\/kaydir\/vitrin\//.test(location.pathname)) {
    /* 08.10 Cem ("5 örnek soru bizim soru paketi gibi değil" -> seçenek a): ücretsiz sayfada "Nöbetçi'ye sor" (ücretli yapay zekâ
       çağrısı) YÜKLENMEZ; yerinde pakete götüren yazı durur. Kart araç satırı (.soruArac) kasa/basım sonrası gelebilir -> izlenir. */
    var nbYaz = function () {
      [].forEach.call(document.querySelectorAll('.soruArac'), function (a) {
        if (a.querySelector('.bNobetciPaket')) return;
        var l = document.createElement('a'); l.className = 'arac bNobetciPaket'; l.href = '/fiyat.html' + (/smmm/.test(location.pathname) ? '?sinav=yeterlilik' : '?sinav=sgs');
        l.target = '_top'; l.textContent = '💬 Pakette: Nöbetçi\'ye kendi sorunu sor'; a.appendChild(l);
      });
    };
    /* 08.10 5 örnek soru (kaydir/vitrin/ornek-*.html): şablonda sayaç yok -> yalnız bu sayfalara GoatCounter (sayfa açılışı) +
       pakete giden tıklama 'ornek/<sinav>/paket' (motor/huni-raporu.js "Örnek:" adımları). Cevaplar cevap_kayit'e kaynak 'ornek-soru'. */
    var ornekS = (location.pathname.match(/\/kaydir\/vitrin\/ornek-(sgs|smmm)\.html$/) || [])[1];
    if (ornekS) {
      try { var gs = document.createElement('script'); gs.async = true; gs.src = '//gc.zgo.at/count.js'; gs.setAttribute('data-goatcounter', 'https://mevzuatradar.goatcounter.com/count'); document.head.appendChild(gs); } catch (e) {}
      document.addEventListener('click', function (e) {
        var a = e.target && e.target.closest && e.target.closest('a[href*="fiyat.html"],a[href*="satin-al.html"]'); if (!a) return;
        try { window.goatcounter && window.goatcounter.count && window.goatcounter.count({ path: 'ornek/' + (ornekS === 'smmm' ? 'yeterlilik' : 'sgs') + '/paket', title: '5 örnek soru: paket', event: true }); } catch (x) {}
      }, true);
    }
    /* 08.10 Cem ("2 yap"): örnek sayfasının son ekranında (#sonSkor, motor/kaydir-coz.ps1) satın alma adımı yoktu -> en üste
       "Paketleri gör" + "30 soruda seviyeni ölç". 5 soruluk setin "Hazırlık %" kutusu yanıltıcı (bankanın tamamına göre değil) -> gizli.
       Normal ders sayfalarına dokunulmaz (bu blok yalnız kaydir/vitrin/ornek-*). */
    /* 11.10 Cem ("1.2.3"): ana sayfanın ilk kapısı bu sayfa oldu. (a) ?k= etiketiyle gelen ziyaretçinin "5 soruyu açtı" adımı
       kaynak sayacına (menu.js'in KAYNAK-ETIKETI bloğuyla aynı anahtarlar: tt_kaynak, tt_kaynak_say; sunucu
       2026-10-11-kaynak-ornek.sql). Etiketsizde istek gitmez. (b) son ekranda ÜYE OLMAYANA ilk adım "yanlışlarını kaydet":
       üyelik → Yanlışlarım (kutu-esitle.js cihazdaki kutuyu hesaba taşır). Üyeye "Yanlışlarım". */
    var uyeVar = function () { try { return Object.keys(localStorage).some(function (k) { return /^sb-.+-auth-token$/.test(k); }); } catch (e) { return false; } };
    if (ornekS) try {
      var kx = JSON.parse(localStorage.getItem('tt_kaynak') || 'null'), ke = kx && Date.now() - kx.t < 30 * 86400000 ? kx.k : null;
      if (!ke) try { ke = sessionStorage.getItem('tt_kaynak'); } catch (e) {}
      if (ke && /^[a-z0-9][a-z0-9_-]{0,31}$/.test(ke)) {
        var ks = []; try { ks = JSON.parse(sessionStorage.getItem('tt_kaynak_say') || '[]'); } catch (e) {}
        if (ks.indexOf('ornek:' + ke) < 0) {
          ks.push('ornek:' + ke); try { sessionStorage.setItem('tt_kaynak_say', JSON.stringify(ks.slice(-20))); } catch (e) {}
          fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/kaynak_say', { method: 'POST', keepalive: true,
            headers: { 'apikey': 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg', 'Content-Type': 'application/json' },
            body: JSON.stringify({ p_etiket: ke, p_olay: 'ornek' }) }).catch(function () {});
        }
      }
    } catch (e) {}
    var sonYaz = function () {
      if (!ornekS) return; var s = document.getElementById('sonSkor');
      if (!s || !s.querySelector('.buyuk') || s.querySelector('.ornekSatin')) return;
      var yet = ornekS === 'smmm', d = document.createElement('div'); d.className = 'ornekSatin';
      d.style.cssText = 'display:flex;flex-direction:column;gap:8px;margin:0 0 14px';
      var kutuN = 0; try { kutuN = (JSON.parse(localStorage.getItem('kc_kutu') || '[]') || []).length; } catch (e) {}
      var uyelik = uyeVar()
        ? '<a class="btn ana" target="_top" href="/yanlislarim.html" style="text-decoration:none;text-align:center">Yanlışlarım' + (kutuN ? ' (' + kutuN + ')' : '') + ' →</a>'
        : '<p style="margin:0;font-size:15px;line-height:1.5;text-align:center">' + (kutuN
            ? '<b>' + kutuN + ' yanlışın</b> şu an yalnız bu tarayıcıda. Ücretsiz üye ol; 2 gün sonra yeniden karşına gelsin, telefonda da bilgisayarda da.'
            : 'Ücretsiz üye ol; çözdüğün sorular ve yanlışların hesabında dursun, telefonda da bilgisayarda da.') + '</p>' +
          '<a class="btn ana" target="_top" href="/ogrenci.html?sonra=yanlislarim.html#uye-ol" style="text-decoration:none;text-align:center">' +
            (kutuN ? 'Ücretsiz üye ol, yanlışlarımı kaydet →' : 'Ücretsiz üye ol →') + '</a>';
      /* 17.10 Cem ("30 soru çözdürmeyelim, kimse 30 soru çözmüyor, 5 örnek soru çözsünler"): son ekrandan 30 soruluk ölçüm kalktı */
      /* 19.10 (Cem: "Google'dan gelenin satın alma oranını artıralım"): 5 soruyu bitiren son ekranda fiyatı hiç görmüyordu; satın alma
         yalnız "Paketleri gör" ile iki sayfa ötedeydi. En üste fiyat + doğrudan satın al (fiyatYaz, rakam fiyat-motoru.js'ten);
         üyelik ikinci sıraya indi. Motor yüklenemezse fiyat kutusu boş kalır, gerisi eskisi gibi. */
      uyelik = uyelik.replace('class="btn ana"', 'class="btn"');
      d.innerHTML = '<div class="ornekFiyat"></div>' + uyelik +
        '<a class="btn" target="_top" href="/fiyat.html?sinav=' + (yet ? 'yeterlilik' : 'sgs') + '" style="text-decoration:none;text-align:center">Paketleri gör →</a>';
      d.addEventListener('click', function (e) {
        var a = e.target && e.target.closest && e.target.closest('a[href*="ogrenci.html"]'); if (!a) return;
        try { window.goatcounter && window.goatcounter.count && window.goatcounter.count({ path: 'ornek/' + (yet ? 'yeterlilik' : 'sgs') + '/uye-ol', title: '5 örnek soru: üye ol', event: true }); } catch (x) {}
      });
      s.insertBefore(d, s.firstChild);
      var h = s.querySelector('.skorBuyuk'); if (h) h.style.display = 'none';
      fiyatYaz();
    };
    var fiyatYaz = function () {
      var k = document.querySelector('#sonSkor .ornekFiyat');
      if (!k || k.childNodes.length || typeof paketBul !== 'function' || typeof fiyatAna !== 'function') return;
      var yet = ornekS === 'smmm', id = yet ? 'yeterlilik-1' : 'sgs', p = paketBul(id); if (!p || !p.acik) return;
      var dahil = function (i, n) { var x = fiyatDahilNot(i, n); return x ? ' <span style="font-size:13px;opacity:.75">(' + x + ')</span>' : ''; };
      var satir = yet
        ? 'Bu sorular ve daha fazlası, seçtiğin derste sınavına kadar:<br><b style="font-size:20px">1 ders ' + fiyatAna(id, p.fiyat) + '</b>' + dahil(id, p.fiyat) +
          '<br><span style="font-size:13px;opacity:.75">Bir dersin sınav ücreti ' + tl(HARC.yeterlilik.ders) + ' TL</span>'
        : 'Bu sorular ve daha fazlası, Staja Giriş sınavına kadar:<br><b style="font-size:20px">' + fiyatAna(id, p.fiyat) + '</b>' + dahil(id, p.fiyat);
      k.innerHTML = '<p style="margin:0 0 8px;font-size:15px;line-height:1.5;text-align:center">' + satir + '</p>' +
        '<a class="btn ana" target="_top" href="/satin-al.html?paket=' + id + '" style="display:block;text-decoration:none;text-align:center">' +
        (yet ? 'Dersini seç, satın al →' : 'Satın al →') + '</a>' +
        '<p style="margin:6px 0 0;font-size:12.5px;opacity:.75;text-align:center">Kartla ödersen paketin hemen açılır.</p>';
    };
    if (ornekS) try { var fm = document.createElement('script'); fm.src = '/fiyat-motoru.js?v=20261028z'; fm.onload = fiyatYaz; document.head.appendChild(fm); } catch (e) {}
    var nbBasla = function () { nbYaz(); sonYaz(); try { new MutationObserver(function () { nbYaz(); sonYaz(); }).observe(document.body, { childList: true, subtree: true }); } catch (e) {} };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', nbBasla); else nbBasla();
    return;
  }

  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/paket-kapisi\.js.*$/, '') : '/';
  var SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
  var SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var kok = document.documentElement;
  var bitti = false, dersler = null;
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
    '#pkPerde .pk-kilit{font-size:26px;margin-bottom:6px}' +
    /* 15.10 Cem ("x işareti olmayan bir şey istemiyorum"): perdede sağ üstte ✕ → Soru Çöz sayfasına döner (içerik yine açılmaz) */
    '#pkPerde a.pk-x{position:absolute;top:10px;right:10px;width:44px;height:44px;margin:0;padding:0;display:flex;align-items:center;justify-content:center;border:0;font:22px/1 system-ui,sans-serif}';
  (document.head || kok).appendChild(st);
  kok.classList.add('pk-bekle');

  function sonraAdresi() {
    return encodeURIComponent(location.pathname.replace(/^\//, '') + location.search + location.hash);
  }
  function ac() {
    if (bitti) return; bitti = true;
    kok.classList.remove('pk-bekle');
    kapiCoz({ acik: true, sb: window.__pkSb, dersler: dersler });
  }
  function perde(tur) {
    if (bitti) return; bitti = true;
    /* 07.10 Cem ("pakete dahil dediğimde ücretsiz soru çöz yine 10 soru çıkıyor"): ücretsiz deneme o sınavın 30 soruluk seviye
       testine gider (10 soruluk sabit örnek sayfası değil). Sınav sayfa yolundan: kaydir/smmm = Yeterlilik, öteki SGS. */
    var yetSayfa = /\/kaydir\/smmm\//.test(location.pathname) || /[?&]sinav=(smmm|yeterlilik)\b/i.test(location.search);
    /* 17.10 Cem ("kimse 30 soru çözmüyor, 5 örnek soru çözsünler"): ücretsiz yol = o sınavın 5 örnek sorusu. KGK'da örnek
       sayfası yok (13.10 ölçüldü) -> KGK perdesinde ücretsiz satırı çizilmez. */
    var kgkSayfa = /\/kaydir\/kgk\//.test(location.pathname);
    var ucretsizA = kgkSayfa ? '' : '<a href="' + KOK + 'kaydir/vitrin/ornek-' + (yetSayfa ? 'smmm' : 'sgs') + '.html">Önce ücretsiz 5 örnek soru çöz</a>';
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
        '<a href="' + fiyatAdr + '">Paketleri gör</a>' + ucretsizA;
    } else if (tur === 'paket') {
      baslik = 'Hesabında aktif paket yok';
      metin = 'Bu sayfa pakete dahil. Paketi aldığında hesabına tanımlanır ve buradan devam edersin.';
      dugmeler = '<a class="pk-ana" href="' + satinAl + '">Paketi al</a>' + ucretsizA;
    } else if (tur === 'son20-sgs' || tur === 'son20-yet') {
      var yet20 = tur === 'son20-yet', acilT = Date.parse(yet20 ? '2026-11-08T00:00:00+03:00' : '2026-11-01T00:00:00+03:00');
      baslik = 'Senin paketin: ' + (yet20 ? 'Yeterlilik Son 20 Gün' : 'Sadece 7 Deneme');
      metin = 'Bu sayfa paketinde yok. ' + (Date.now() < acilT ? 'Denemelerin ' + (yet20 ? '8' : '1') + ' Kasım 2026\'da açılır.' : 'Denemelerin seni bekliyor.')
        + ' Bütün soru bankası için Tam Pakete geçebilirsin; ödediğin 999 TL düşülür.';
      dugmeler = '<a class="pk-ana" href="' + KOK + (yet20 ? 'ogrenci.html' : 'son-20-gun.html') + '">' + (yet20 ? 'Hesabıma git' : 'Son 20 Gün sayfam') + '</a>' +
        '<a href="' + KOK + 'iletisim.html">Tam Pakete geç</a>';
    } else {
      baslik = 'Bağlantı kurulamadı';
      metin = 'Paket bilgin kontrol edilemedi. İnternet bağlantını kontrol edip yeniden dene.';
      dugmeler = '<a class="pk-ana" href="' + location.href.replace(/"/g, '%22') + '">Yeniden dene</a>' + ucretsizA;
    }
    var cizim = function () {
      var d = document.createElement('div');
      d.id = 'pkPerde';
      d.setAttribute('role', 'dialog'); d.setAttribute('aria-modal', 'true');
      var xAdr = tur === 'son20-sgs' ? KOK + 'son-20-gun.html' : tur === 'son20-yet' ? KOK + 'ogrenci.html'   /* 28.10 Son 20 Gün üyesi kendi sayfasına */
        : KOK + 'sorular.html' + (yetSayfa ? '#smmm' : /\/kaydir\/kgk\//.test(location.pathname) ? '#kgk' : '#sgs');
      d.innerHTML = '<a class="pk-x" href="' + xAdr + '" aria-label="Kapat">✕</a><div class="pk-kutu"><div class="pk-kilit" aria-hidden="true">🔒</div><h2>' + baslik + '</h2><p>' + metin + '</p>' + dugmeler + '</div>';
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
      s.src = KOK + 'ilerleme-web.js?v=20261015y';   /* 12.10: kaldığın yer kimlikle */
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
      var r = await sb.from('paket_uyeler').select('paket,bitis,dersler').eq('user_id', oturum.user.id);
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
      /* 13.10 KGK açılış hazırlığı: kaydir/kgk/ yolu tanınmıyordu -> sinavi=null -> kapsar() her aktif pakete "true" diyordu
         (SGS paketi KGK sayfasının perdesini açardı; içerik kasada RLS ile yine kilitliydi). Eşleme uye-durumu.js paketSinavlari
         ve radar-app/sql/2026-10-09-kasa-olcer.sql paket_erisim_var ile AYNI: kgk | kgk-* | yeterlilik-kgk | tam | kurucu. */
      var sinavi = sgYet ? 'yeterlilik'
        : (/\/kaydir\/sgs\//.test(location.pathname) || /sinav-gibi\.html$/.test(location.pathname) ? 'sgs'
        : (/\/kaydir\/smmm\//.test(location.pathname) ? 'yeterlilik'
        : (/\/kaydir\/kgk\//.test(location.pathname) ? 'kgk' : null)));
      var kapsar = function (paket) {
        var p = String(paket == null ? '' : paket).trim().toLowerCase();
        if (!sinavi || !p || p === 'tam' || p === 'kurucu') return true;
        if (sinavi === 'sgs') return p === 'sgs' || p.indexOf('sgs-') === 0 || p === 'sinav-249';
        if (sinavi === 'yeterlilik') return p === 'yeterlilik' || p.indexOf('yeterlilik-') === 0 || p === 'smmm' || p === 'yeterlilik-kgk';
        if (sinavi === 'kgk') return p === 'kgk' || p.indexOf('kgk-') === 0 || p === 'yeterlilik-kgk';
        return false;
      };
      var gecerli = (r.data || []).filter(function (x) { return (!x.bitis || x.bitis >= bugun) && kapsar(x.paket); });
      if (gecerli.length) {
        /* 11.10 Ders Denemesi: kapı alınan dersleri de bildirir (null = tüm dersler). Yalnız GÖRÜNÜM içindir
           (kilitli set işareti); asıl kilit kasada (paket_erisim_var, dersler sütunu). */
        dersler = gecerli.some(function (x) { return !x.dersler || !x.dersler.length; }) ? null
          : [].concat.apply([], gecerli.map(function (x) { return x.dersler; }));
        ac();                               // ÖNCE sayfa açılır ...
        kutuyuAc();                         // 07.10: "Tekrar et" bağlantısı (#kutu) yanlış kutusunu açık getirir
        cihazKorumasi(sb, oturum.user);     // ... SONRA paylaşım koruması (arızada üye içeride kalır)
        ilerleme(sb, oturum.user);          // ... ve kaldığın yerden devam (hesaba eşitlenir)
        return;
      }
      /* 28.10 Cem ("7 deneme alan sadece onu görecek, sitede başka şeye ulaşamayacak"): yalnız Son 20 Gün paketi olan üyeye
         "aktif paketin yok · paketi al" DENMEZ; perde kendi paketini söyler ve oraya götürür (asıl kilit kasada, değişmedi). */
      var s20 = (r.data || []).filter(function (x) { return (!x.bitis || x.bitis >= bugun) && /^son20-(sgs|yet)$/.test(String(x.paket || '').trim().toLowerCase()); })[0];
      if (s20) return perde(String(s20.paket).trim().toLowerCase() === 'son20-yet' ? 'son20-yet' : 'son20-sgs');
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
  /* 08.10 Cem (seçenek a): ücretsiz vitrin / 5 örnek soru sayfasında ücretli "Nöbetçiye sor" yüklenmez; yerinde "Pakette: ..." bağlantısı (yukarıda) */
  if (/\/kaydir\/vitrin\//.test(location.pathname)) return;
  var bu = document.querySelector('script[src*="paket-kapisi.js"]'), kok = bu ? bu.src.replace(/paket-kapisi\.js.*$/, '') : '/';
  var s = document.createElement('script'); s.src = kok + 'nobetci-sor.js'; s.defer = true; document.head.appendChild(s);
  document.addEventListener('click', function (e) { var b = e.target && e.target.closest && e.target.closest('.bNobetci'); if (b && window.goatcounter && window.goatcounter.count) { try { window.goatcounter.count({ path: 'kart/nobetci-ac', title: 'Soru kartı: nobetci-ac', event: true }); } catch (x) {} } }, true);
})();
