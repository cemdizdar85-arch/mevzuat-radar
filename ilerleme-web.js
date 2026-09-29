/* ilerleme-web.js — SİTEDE "KALDIĞIN YERDEN DEVAM" + HESABA EŞİTLEME (29.09.2026, Cem "1.2.3" madde 3)
 *
 * Sorun (ölçüldü 29.09): web Kaydır-Çöz sayfaları ilerlemeyi yalnız o tarayıcıda tutuyordu (kc_* anahtarları)
 * ve kaldığın kartı hiç yazmıyordu; telefonda başlayan bilgisayarda devam edemiyordu. Uygulama ise aynı işi
 * mobil/uygulama/ilerleme.js ile hesaba (public.ogrenci_ilerleme) yazıyordu.
 * Bu dosya AYNI kaydı sitede kullanır: tek kaynak mobil/uygulama/ilerleme.js (kopya yok) → site ile uygulama
 * birbirinin kaldığı yeri ve cevaplarını görür (sid = soru metni özeti, yol = kaydir/<sınav>/<ders>.html; ikisi de aynı).
 *
 * Yüklenme: paket-kapisi.js, aktif paket görülüp sayfa AÇILDIKTAN sonra ttIlerlemeWeb.kur(sb, kullanici) çağırır.
 * Arızada (betik inmezse, tablo/ağ yoksa) sayfa olduğu gibi çalışır; ilerleme yerelde kalır (fail-open).
 *
 * YAPAR: cevap kaydı (doğru/yanlış, ders, konu) · kaldığın kart (kaydırınca) · açılışta hesapla eşitle, sonra o karta git
 *        ("Baştan" düğmesiyle) · cevaptan 4 sn sonra ve sayfadan çıkarken hesaba yaz.
 * YAPMAZ / GÖRMEZ: sayfanın kendi yanlış kutusu ve hazırlık skoru (kc_kayit/kc_kutu/kc_oyun) hâlâ tarayıcıda kalır;
 *        tek kart (?tek=1), derin bağlantı (#s=N) ve vitrin sayfalarında kaldığın yer yazılmaz/uygulanmaz;
 *        sinav-gibi.html gibi #akis olmayan sayfalarda hiçbir şey yapmaz.
 */
(function () {
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/ilerleme-web\.js.*$/, '') : '/';
  var YOL = (location.pathname.match(/kaydir\/[^?#]+\.html$/) || [''])[0];
  var kuruldu = false;

  function yukle(src) {
    return new Promise(function (tamam, hata) {
      var s = document.createElement('script'); s.src = src; s.onload = tamam; s.onerror = hata;
      (document.head || document.documentElement).appendChild(s);
    });
  }
  function akis() { return document.getElementById('akis'); }
  function kartlar() {
    var a = akis();
    return a ? [].slice.call(a.children).filter(function (k) { return k.classList.contains('kart') && k.querySelector('.sik'); }) : [];
  }
  /* kasa modundaki sayfa kartları kapı açıldıktan sonra doldurur → kart gelene kadar bekle (en çok 30 sn) */
  function kartBekle() {
    return new Promise(function (tamam) {
      var n = 0;
      (function bak() { if (kartlar().length) return tamam(true); if (++n > 150) return tamam(false); setTimeout(bak, 200); })();
    });
  }
  function serit(metin, dugme, fn) {
    var s = document.getElementById('ttwSerit'); if (s) s.remove();
    s = document.createElement('div'); s.id = 'ttwSerit'; s.setAttribute('role', 'status');
    s.style.cssText = 'position:fixed;left:50%;transform:translateX(-50%);bottom:18px;z-index:2147480000;max-width:92%;' +
      'background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:999px;padding:8px 8px 8px 14px;' +
      'display:flex;align-items:center;gap:10px;font-size:14px;box-shadow:0 6px 20px color-mix(in srgb,var(--yazi) 20%,transparent)';
    var y = document.createElement('span'); y.textContent = metin; s.appendChild(y);
    if (dugme) {
      var b = document.createElement('button'); b.type = 'button'; b.textContent = dugme;
      b.style.cssText = 'font:inherit;font-weight:700;border:0;border-radius:999px;padding:6px 12px;background:var(--mavi);color:var(--ustYazi);cursor:pointer';
      b.onclick = function () { s.remove(); fn(); }; s.appendChild(b);
    }
    document.body.appendChild(s);
    setTimeout(function () { if (s.parentNode) s.remove(); }, 7000);
  }

  async function kur(sb, kullanici) {
    if (kuruldu || !YOL || !akis() || /\/kaydir\/vitrin\//.test(location.pathname)) return;
    kuruldu = true;
    try {
      if (!window.TTIlerleme) await yukle(KOK + 'mobil/uygulama/ilerleme.js');
    } catch (e) { return; }
    var IL = window.TTIlerleme; if (!IL) return;
    var uid = kullanici && kullanici.id;
    var tek = document.documentElement.hasAttribute('data-tek');
    var derin = /#s=\d+/.test(location.hash);

    /* 1) önce hesapla eşitle (başka cihazdaki kaldığın yer buraya gelsin), sonra kartları bekle */
    var esitleme = IL.esitle(sb, uid).catch(function () { return 'yerel'; });
    var hazir = await kartBekle();
    await esitleme;
    if (!hazir) return;

    var ks = kartlar(), a = akis();
    function sidK(k) { if (!k.__ttsid) { var q = k.querySelector('.soru'); k.__ttsid = IL.sid(q ? q.textContent : ''); } return k.__ttsid; }
    function simdiki() { if (!a.clientHeight) return -1; var i = Math.round(a.scrollTop / a.clientHeight); return i < ks.length ? i : ks.length - 1; }

    /* 2) hesaba yazma: cevaptan 4 sn sonra toplu, sayfadan çıkarken bir kez daha */
    var yazZam = null;
    function sonraEsitle() { clearTimeout(yazZam); yazZam = setTimeout(function () { IL.esitle(sb, uid); }, 4000); }
    document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden') IL.esitle(sb, uid); });

    /* 3) cevap kaydı: sayfanın kendi dinleyicisi şıkları boyadıktan SONRA sonucu okunur (uygulama-kaydir.js ile aynı) */
    ks.forEach(function (k, i) {
      [].forEach.call(k.querySelectorAll('.sik'), function (s) {
        s.addEventListener('click', function () {
          if (k.__ttcevap) return;
          setTimeout(function () {
            if (!k.querySelector('.sik.dogru')) return;
            k.__ttcevap = 1;
            var q = (typeof SORULAR !== 'undefined' && SORULAR[i]) || {};
            IL.cevapla(sidK(k), s.classList.contains('dogru'), YOL,
              { d: String(q.ders || '').slice(0, 80), k: String(q.konu || '').slice(0, 80), i: i });
            sonraEsitle();
          }, 0);
        });
      });
    });

    /* 4) kaldığın yer: tek kart modunda yazılmaz */
    if (tek) return;
    var konumZam = null;
    a.addEventListener('scroll', function () {
      clearTimeout(konumZam);
      konumZam = setTimeout(function () { var i = simdiki(); if (i >= 0) { IL.konumYaz(YOL, i); sonraEsitle(); } }, 500);
    }, { passive: true });
    if (derin) return;
    var hedef = IL.konumu(YOL);
    if (hedef > 0 && ks[hedef] && simdiki() < 1) {
      a.scrollTo({ top: ks[hedef].offsetTop, behavior: 'instant' });
      serit('Kaldığın yerden: ' + (hedef + 1) + '. soru', 'Baştan', function () { a.scrollTo({ top: 0, behavior: 'smooth' }); });
    }
  }

  window.ttIlerlemeWeb = { kur: kur };
})();
