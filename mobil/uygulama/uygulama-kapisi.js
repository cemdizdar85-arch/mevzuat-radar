/* uygulama-kapisi.js — MAĞAZA UYGULAMASINDA PAKET KAPISI (25.09.2026)
 *
 * Sitedeki paket-kapisi.js'in uygulama karşılığı. mobil/hazirla.js, uygulamaya gömülen her
 * Kaydır-Çöz sayfasında `<script src="../../paket-kapisi.js">` etiketini şu üçlüyle değiştirir:
 *   kutuphane/supabase-*.js  ->  ortak.js  ->  uygulama-kapisi.js
 * Sözleşme paket-kapisi.js ile AYNI: window.__pkKapi = Promise<{acik:true, sb} | {acik:false}>.
 * kasa-yukle.js değişmeden çalışır ve soruları kilitli kasadan (paket_soru, RLS) çeker.
 *
 * Sitedekinden farkları (Cem 25.09: dışarıya satış yönlendirmesi yok; satış yalnız mağaza içinden):
 *   - Perdede SİTENİN satın alma sayfasına düğme YOK (mağaza kuralı). Paketi olmayana uygulamanın
 *     kendi "Paketler" bölümü gösterilir (magaza.js, Google Play ödemesi).
 *   - Sayfaya sonradan eklenen satın alma bağlantıları (kasa-yukle.js'in "ders pakette yok"
 *     ekranındaki düğme gibi) gözlemciyle kaldırılır. hazirla.js aynı düğmeyi derlemede de söker; bu ikinci kat.
 *   - Ağ yoksa son bilinen paket bilgisiyle açılır (ortak.js, en fazla 7 gün).
 *   - Sol üstte "Sınavlar" düğmesi: iOS'ta geri hareketi olmadığı için ana ekrana dönüş yolu.
 *
 * Muaf: kaydir/vitrin/ (ücretsiz örnek sorular) — kapı hiç kurulmaz, yalnız dönüş düğmesi.
 * Renk yazılmaz: sayfanın kendi jetonları kullanılır (Kaydır-Çöz: --bg/--kart/--yazi).
 *
 * BU DOSYA ŞUNU GÖRMEZ: sayfa içindeki metin olarak geçen satış çağrıları (bağlantı olmayan
 * "paketini güncelle" cümlesi). Bunları hazirla.js derlemede tarar ve derlemeyi durdurur.
 */
(function () {
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/uygulama-kapisi\.js.*$/, '') : '../../';
  var kok = document.documentElement;
  var vitrin = /\/kaydir\/vitrin\//.test(location.pathname);
  var SATIS = /(satin-al|fiyat|radar-fiyat|odeme|uyelik-sozlesmesi|mesafeli-satis)\.html/i;

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
    '#ttGeri{position:fixed;z-index:2147482000;left:calc(10px + env(safe-area-inset-left));top:calc(10px + env(safe-area-inset-top));' +
    'padding:7px 12px;border-radius:999px;font:700 13px/1.2 -apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;text-decoration:none;' +
    'background:var(--kart,var(--panel));color:var(--yazi,var(--ink));border:1px solid var(--cizgi,var(--line));visibility:visible}' +
    /* Kaydır-Çöz kartının üst satırı (.ust: konu etiketi + seviye) düğmenin altında kalmasın. */
    '#akis .ust{padding-left:96px}';
  (document.head || kok).appendChild(st);

  function geriDugmesi() {
    var ciz = function () {
      if (document.getElementById('ttGeri')) return;
      var a = document.createElement('a');
      a.id = 'ttGeri'; a.href = KOK + 'index.html'; a.textContent = '‹ Sınavlar';
      a.setAttribute('aria-label', 'Sınav listesine dön');
      document.body.appendChild(a);
    };
    if (document.body) ciz(); else document.addEventListener('DOMContentLoaded', ciz);
  }

  /* Satış bağlantısı sökücü: href'i satış sayfasına giden her <a> kaldırılır.
     Site hesabına giden bağlantılar (ogrenci.html#cihazlarim) sistem tarayıcısında açılır. */
  function bagSokucu(kapsam) {
    var liste = (kapsam || document).querySelectorAll ? (kapsam || document).querySelectorAll('a[href]') : [];
    for (var i = 0; i < liste.length; i++) {
      var a = liste[i], h = a.getAttribute('href') || '';
      if (SATIS.test(h)) { a.parentNode && a.parentNode.removeChild(a); continue; }
      if (/(^|\/)ogrenci\.html/.test(h) && !/^https?:/.test(h)) {
        a.setAttribute('href', 'https://tetikte.com/ogrenci.html' + (h.split('ogrenci.html')[1] || ''));
        a.setAttribute('target', '_blank'); a.setAttribute('rel', 'noopener');
      }
    }
  }
  function gozlemci() {
    bagSokucu(document);
    try {
      new MutationObserver(function (kayitlar) {
        for (var i = 0; i < kayitlar.length; i++) {
          var eklenen = kayitlar[i].addedNodes;
          for (var j = 0; j < eklenen.length; j++) if (eklenen[j].nodeType === 1) bagSokucu(eklenen[j].parentNode || eklenen[j]);
        }
      }).observe(document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', gozlemci); else gozlemci();

  geriDugmesi();
  if (vitrin) return;

  var bitti = false, kapiCoz;
  window.__pkKapi = new Promise(function (r) { kapiCoz = r; });
  kok.classList.add('pk-bekle');

  function ac(sb) {
    if (bitti) return; bitti = true;
    kok.classList.remove('pk-bekle');
    kapiCoz({ acik: true, sb: sb });
  }
  function perde(tur) {
    if (bitti) return; bitti = true;
    kapiCoz({ acik: false, tur: tur });
    var baslik, metin, dugmeler;
    if (tur === 'giris') {
      baslik = 'Önce giriş yap';
      metin = 'Bu bölüm Tetikte hesabınla açılır. Giriş yaptıktan sonra buradan devam edersin.';
      dugmeler = '<a class="pk-ana" href="' + KOK + 'index.html#giris">Giriş yap</a>';
    } else if (tur === 'paket') {
      baslik = 'Bu sınav hesabında açık değil';
      // "Paket seç" yalnız bu cihazda uygulama içi satış açıkken (magaza.js ana ekranda yazar: Android her
      // zaman, iPhone katalog anahtarı iosSatis açıkken). Kapalıyken satın alma yolu gösterilmez
      // (Apple 3.1.1: IAP dışı satın alma yönlendirmesi ret sebebi; 25.09 satışsız ilk sürüm kararı).
      var satisAcik = false;
      try { satisAcik = localStorage.getItem('tt_uyg_satis_acik') === '1'; } catch (e) {}
      if (satisAcik) {
        metin = 'Hesabındaki paket bu sınavı kapsamıyor. Paketler ekranından uygulama içinde açabilirsin.';
        dugmeler = '<a class="pk-ana" href="' + KOK + 'index.html#paketler">Paket seç</a>' +
          '<a href="' + KOK + 'index.html">Ana ekrana dön</a>';
      } else {
        metin = 'Hesabındaki paket bu sınavı kapsamıyor. Ücretsiz örnek soruları ana ekrandan çözebilirsin.';
        dugmeler = '<a class="pk-ana" href="' + KOK + 'index.html">Ana ekrana dön</a>';
      }
    } else {
      baslik = 'Bağlantı kurulamadı';
      metin = 'Paket bilgin kontrol edilemedi. İnternet bağlantını kontrol edip yeniden dene.';
      dugmeler = '<a class="pk-ana" href="' + location.href.replace(/"/g, '%22') + '">Yeniden dene</a>' +
        '<a href="' + KOK + 'index.html">Ana ekrana dön</a>';
    }
    var cizim = function () {
      var d = document.createElement('div');
      d.id = 'pkPerde';
      d.setAttribute('role', 'dialog'); d.setAttribute('aria-modal', 'true');
      d.innerHTML = '<div class="pk-kutu"><h2>' + baslik + '</h2><p>' + metin + '</p>' + dugmeler + '</div>';
      document.body.appendChild(d);
      document.body.style.overflow = 'hidden';
    };
    if (document.body) cizim(); else document.addEventListener('DOMContentLoaded', cizim);
  }

  /* Hesap paylaşım koruması (cihaz-kapisi.js) sitedekiyle aynı: sayfa açıldıktan SONRA,
     arızada üye içeride kalır. Çevrimdışıyken hiç çağrılmaz. */
  function cihazKorumasi(sb, k) {
    try {
      var calistir = function () {
        if (!window.ttCihaz) return;
        sb.auth.getUser().then(function (r) { if (r.data && r.data.user) window.ttCihaz.koru(sb, r.data.user); });
      };
      if (window.ttCihaz) return calistir();
      var s = document.createElement('script');
      s.src = KOK + 'cihaz-kapisi.js';
      s.onload = calistir;
      (document.head || kok).appendChild(s);
    } catch (e) {}
  }

  var zaman = setTimeout(function () { perde('hata'); }, 12000);
  (async function () {
    try {
      var sb = window.TT.istemci();
      var k = await window.TT.kullanici(sb);
      if (!k) { clearTimeout(zaman); return perde('giris'); }
      var p = await window.TT.paketler(sb, k.id);
      clearTimeout(zaman);
      if (window.TT.acarMi(p.satir, window.TT.sinaviBul(location.pathname))) {
        ac(sb);
        if (!k.cevrimdisi && !p.cevrimdisi) cihazKorumasi(sb, k);
        return;
      }
      perde('paket');
    } catch (e) { clearTimeout(zaman); perde('hata'); }
  })();
})();
