/* uygulama-karma.js — KISA SINAV ve EN ÇOK ÇIKANLAR (26.09.2026, Cem "gereken her şeyi yap")
 *
 * Kasa modundaki bir ders sayfası "kabuk" olarak kullanılır: ?karma=kisa|cok&n=10|20. kasa-yukle.js o sayfanın
 * sorularını çekmek yerine window.TTKarma.cek(sb)'yi çağırır (mobil/hazirla.js derlemede yamar; kapı ile ölçülür).
 *   kisa  paketindeki derslerden KARIŞIK n soru — dersler arasında sırayla, rastgele (dağılım dengeli).
 *   cok   en çok dönemde soru gelen konulardan n soru (veri.donem büyükten küçüğe ilk 3n içinden rastgele).
 * Kasa RLS'i yalnız hesabın açık derslerini verir: paketinde olmayan ders zaten gelmez.
 * Süre: soru başına 90 sn (10 soru = 15 dk). Süre biter ya da tüm sorular cevaplanınca KARNE: toplam + ders ders.
 * Cevaplar ilerleme kaydına sorunun GERÇEK dersiyle yazılır (uygulama-kaydir.js TTKarma.yol(i)); kaldığın yer
 * yazılmaz (rastgele deste). Kilitli cevap kalıbına dokunulmaz: sorular sayfanın kendi motoruyla çizilir.
 * BU DOSYA ŞUNU YAPMAZ: soru üretmez · sayı uydurmaz (karne yalnız bu oturumun cevapları).
 */
(function () {
  var q = location.search, tur = (q.match(/[?&]karma=(kisa|cok)\b/) || [])[1];
  if (!tur) return;
  var n = Math.min(40, Math.max(5, +((q.match(/[?&]n=(\d+)/) || [])[1] || (tur === 'cok' ? 20 : 10))));
  var kok = document.documentElement, sayfa = kok.getAttribute('data-kasa-sayfa') || '';
  var SINAV = /^kaydir\/sgs\//.test(sayfa) ? 'sgs' : 'smmm';
  var SURE = n * 90;   // saniye
  var PARCA = 1000;
  var secilen = [];     // [{ yol, ders }] — kartlar ile aynı sırada
  var sonuc = {};       // i -> true/false
  var ALT = 'max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px))';
  var UST = 'max(env(safe-area-inset-top),var(--safe-area-inset-top,0px))';

  function karistir(a) { for (var i = a.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var t = a[i]; a[i] = a[j]; a[j] = t; } return a; }

  async function hepsi(sb, sutun) {
    var satir = [], bas = 0;
    for (;;) {
      var r = await sb.from('paket_soru').select(sutun).eq('sinav', SINAV).order('id', { ascending: true }).range(bas, bas + PARCA - 1);
      if (r.error) throw r.error;
      satir = satir.concat(r.data);
      if (r.data.length < PARCA) break;
      bas += PARCA;
    }
    return satir;
  }

  function sec(liste) {
    if (tur === 'cok') {
      liste.sort(function (a, b) { return (+b.donem || 0) - (+a.donem || 0); });
      return karistir(liste.slice(0, n * 3)).slice(0, n);
    }
    /* kisa: ders ders gruplar, karışık sırayla birer birer */
    var g = {};
    karistir(liste).forEach(function (x) { (g[x.ders] = g[x.ders] || []).push(x); });
    var dersler = karistir(Object.keys(g)), s = [];
    while (s.length < n && dersler.some(function (d) { return g[d].length; })) {
      dersler.forEach(function (d) { if (s.length < n && g[d].length) s.push(g[d].shift()); });
    }
    return karistir(s);
  }

  window.TTKarma = {
    tur: tur,
    yol: function (i) { return secilen[i] ? secilen[i].yol : null; },
    cek: async function (sb) {
      var liste = await hepsi(sb, tur === 'cok' ? 'id,ders,sayfa,donem:veri->donem' : 'id,ders,sayfa');
      var s = sec(liste);
      if (!s.length) return [];
      var ids = s.map(function (x) { return x.id; }), veri = {};
      for (var i = 0; i < ids.length; i += 50) {
        var r = await sb.from('paket_soru').select('id,veri').in('id', ids.slice(i, i + 50));
        if (r.error) throw r.error;
        r.data.forEach(function (x) { veri[x.id] = x.veri; });
      }
      s = s.filter(function (x) { return veri[x.id]; });
      secilen = s.map(function (x) { return { yol: x.sayfa, ders: x.ders }; });
      setTimeout(baslat, 400);
      return s.map(function (x) { return veri[x.id]; });
    }
  };

  /* ---------- süre + karne ---------- */
  var st = document.createElement('style');
  st.textContent = [
    '#ttSure{position:fixed;left:50%;transform:translateX(-50%);top:calc(' + UST + ' + 58px);z-index:2147480000;font:600 12px/1 -apple-system,"Segoe UI",system-ui,sans-serif;' +
      'letter-spacing:.08em;padding:6px 10px;border-radius:6px;background:rgba(0,0,0,.72);color:#f4f4f5;border:1px solid rgba(255,255,255,.16);font-variant-numeric:tabular-nums}',
    '#ttSure.az{color:#ffb4a8;border-color:#ff6b5e}',
    '#ttKarne{position:fixed;inset:0;z-index:2147481600;background:#000;color:#f4f4f5;overflow:auto;padding:calc(' + UST + ' + 28px) 20px calc(' + ALT + ' + 24px);' +
      'font-family:-apple-system,"Segoe UI",system-ui,Roboto,sans-serif}',
    '#ttKarne .etk{font-size:11px;font-weight:600;letter-spacing:.16em;text-transform:uppercase;color:#8b8b93;margin:0 0 10px}',
    '#ttKarne h2{font-size:28px;font-weight:600;letter-spacing:-.02em;margin:0 0 6px}',
    '#ttKarne .buyuk{font-size:64px;font-weight:300;letter-spacing:-.03em;line-height:1;margin:14px 0 4px;font-variant-numeric:tabular-nums}',
    '#ttKarne .buyuk small{font-size:24px;color:#8b8b93}',
    '#ttKarne .alt{color:#a1a1aa;margin:0 0 24px}',
    '#ttKarne .sat{display:flex;justify-content:space-between;gap:12px;padding:12px 0;border-top:1px solid rgba(255,255,255,.1);font-size:15px}',
    '#ttKarne .sat b{font-weight:400;font-variant-numeric:tabular-nums;color:#d4d4d8}',
    '#ttKarne .bar{height:2px;background:rgba(255,255,255,.1);margin-top:8px}',
    '#ttKarne .bar i{display:block;height:100%;background:#f4f4f5}',
    '#ttKarne a,#ttKarne button{display:block;width:100%;box-sizing:border-box;text-align:center;text-decoration:none;font:600 15px/1.2 inherit;padding:15px;border-radius:8px;margin-top:10px;cursor:pointer}',
    '#ttKarne .birinci{background:#f4f4f5;color:#000;border:0;margin-top:26px}',
    '#ttKarne .ikinci{background:transparent;color:#f4f4f5;border:1px solid rgba(255,255,255,.18)}'
  ].join('\n');
  document.head.appendChild(st);

  var bitis = 0, zam = null, bitti = false;
  function kartlar() { var a = document.getElementById('akis'); return a ? [].slice.call(a.children).filter(function (k) { return k.classList.contains('kart') && k.querySelector('.sik'); }) : []; }
  function iki(x) { return (x < 10 ? '0' : '') + x; }
  function baslat() {
    var ks = kartlar();
    if (!ks.length) return setTimeout(baslat, 300);
    ks.forEach(function (k, i) {
      [].forEach.call(k.querySelectorAll('.sik'), function (s) {
        s.addEventListener('click', function () {
          if (i in sonuc || bitti) return;
          setTimeout(function () {
            if (!k.querySelector('.sik.dogru')) return;
            sonuc[i] = s.classList.contains('dogru');
            if (Object.keys(sonuc).length >= ks.length) setTimeout(karne, 1800);
          }, 0);
        });
      });
    });
    var e = document.createElement('div'); e.id = 'ttSure'; document.body.appendChild(e);
    bitis = Date.now() + SURE * 1000;
    var tik = function () {
      var kalan = Math.max(0, Math.round((bitis - Date.now()) / 1000));
      e.textContent = (tur === 'cok' ? 'EN ÇOK ÇIKANLAR' : 'KISA SINAV') + ' · ' + iki(Math.floor(kalan / 60)) + ':' + iki(kalan % 60);
      e.classList.toggle('az', kalan <= 60);
      if (!kalan) karne();
    };
    tik(); zam = setInterval(tik, 1000);
  }

  function karne() {
    if (bitti) return; bitti = true; clearInterval(zam);
    var s = document.getElementById('ttSure'); if (s) s.remove();
    var top = kartlar().length, cevap = Object.keys(sonuc).length, ok = 0, d = {};
    Object.keys(sonuc).forEach(function (i) { if (sonuc[i]) ok++; });
    secilen.forEach(function (x, i) {
      var r = d[x.ders] = d[x.ders] || { ok: 0, n: 0, bos: 0 };
      if (i in sonuc) { r.n++; if (sonuc[i]) r.ok++; } else r.bos++;
    });
    var gecen = Math.round((SURE * 1000 - Math.max(0, bitis - Date.now())) / 60000);
    var h = '<div class="etk">' + (tur === 'cok' ? 'En çok çıkanlar' : 'Kısa sınav') + ' · karne</div>' +
      '<div class="buyuk">' + ok + '<small> / ' + top + ' doğru</small></div>' +
      '<p class="alt">' + cevap + ' soru cevaplandı' + (top - cevap ? ', ' + (top - cevap) + ' boş' : '') + ' · ' + gecen + ' dk</p>';
    Object.keys(d).sort().forEach(function (ad) {
      var r = d[ad], y = r.n ? Math.round(r.ok / r.n * 100) : 0;
      h += '<div class="sat"><span>' + ad.replace(/[<>&]/g, '') + '<div class="bar"><i style="width:' + y + '%"></i></div></span><b>' +
        r.ok + ' / ' + (r.n + r.bos) + '</b></div>';
    });
    h += '<a class="birinci" href="' + location.pathname + location.search.replace(/[?&]_=\d+/, '') + '">Yeni ' + (tur === 'cok' ? 'set' : 'kısa sınav') + '</a>' +
      '<button type="button" class="ikinci" data-inceleme="1">Cevapları incele</button>' +
      '<a class="ikinci" href="../../index.html">Ana ekran</a>';
    var e = document.createElement('div'); e.id = 'ttKarne'; e.setAttribute('role', 'dialog'); e.innerHTML = h; document.body.appendChild(e);
    e.querySelector('[data-inceleme]').onclick = function () { e.remove(); var a = document.getElementById('akis'); if (a) a.scrollTo({ top: 0 }); };
    if (window.TTOlay) window.TTOlay.say(tur === 'cok' ? 'karma_cok' : 'karma_kisa');
  }
})();
