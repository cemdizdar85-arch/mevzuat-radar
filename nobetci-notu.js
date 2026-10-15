/* nobetci-notu.js — HER 10 CEVAPTA NÖBETÇİ NOTU (12.10.2026, Cem "1.2.3" → "1 yap"; bedel 0)
 *
 * Kim görür: bitirme (Yeterlilik) ders sayfasını açan üye — sitede ilerleme-web.js (yalnız kapı açılmış sayfa, vitrin hariç),
 *   uygulamada uygulama-kaydir.js (vitrin hariç). Bugüne kadar ara karne yalnız ücretsiz vitrinde vardı (satış ekranı).
 * Ne zaman: sayfada her 10 cevapta bir kez (sayaç sayfa başına, cihazda: tt_nn_<yol>). 20. cevapta ders denemesi daveti.
 * Kart: "10'da X doğru" · bu 10'daki en zayıf konu (en çok yanlış; eşitlikte sınavda daha sık sorulan) · konunun okunmuş
 *   çıkmış sorulardaki dönem sayısı + kanıtı (dönem · soru no). SINAV RAKAMI KANITLI kuralı: rakam YALNIZ
 *   veri/deneme/smmm-konu-kanit.json listesinden sayılır (motor/sik-konu-deneme-bas.js, kaynak smmm-konu-okuma.json — soru
 *   metni okunarak sayılmış); listesi yoksa rakam yazılmaz. Düğmeler: "Bu konudan 10 soru" (sana özel deneme, konu süzgeci) ·
 *   "Yanlışlarımı yeniden çöz" (sayfanın kendi yolu) · "Devam". Satış dili ve "paket" kelimesi YOK.
 * iPhone (TT.yalnizUcretsiz): deneme bağlantıları gösterilmez (deneme sayfası ücretli içerik).
 * Konu bağı: veri/deneme/smmm-ders-havuz.json (kimlik → okunmuş konu). Uygulama bu dosyaları veri köprüsüyle siteden okur.
 * 🚫 GÖRMEZ: başka cihazda verilen cevap (sayaç cihazda) · havuzda olmayan (konusuz) soru — zayıf konu seçiminde sayılmaz ·
 *   tek okuyucu konu eşlemesinin hatası.
 * Öz-sınav: node arac/nobetci-notu-sinavi.js (saf işlevler bu dosyadan, kopya yok; mutasyon --mutasyon).
 */
(function (kok) {
  var ARA = 10, DAVET = 20;
  var MUT = (typeof process !== 'undefined' && process.env && process.env.NN_MUTASYON) || '';

  /* ---- SAF İŞLEVLER (Node öz-sınavı bunları çağırır) ---- */
  /* durum {n, son:[[id, 1|0]...] (en çok 10), davet} + yeni cevap → {durum, goster} */
  function ilerle(durum, id, dogru) {
    var d = { n: (durum && +durum.n) || 0, son: ((durum && durum.son) || []).slice(), davet: !!(durum && durum.davet) };
    d.n++; d.son.push([String(id), dogru ? 1 : 0]); if (d.son.length > ARA) d.son = d.son.slice(-ARA);
    var goster = MUT === 'her-cevap' ? true : d.n % ARA === 0;
    return { durum: d, goster: goster, davet: goster && d.n >= DAVET && !d.davet };
  }
  /* son 10 → {dogru, toplam, zayif:{konu, yanlis}|null}. zayıf = en çok yanlış; eşitlikte kanıtı çok olan (sınavda sık) */
  function ozet(son, idKonu, kanit) {
    var dogru = 0, yan = {};
    son.forEach(function (x) {
      if (x[1]) { dogru++; return; }
      var k = idKonu[x[0]]; if (!k) return;
      yan[k] = (yan[k] || 0) + 1;
    });
    var z = null;
    Object.keys(yan).forEach(function (k) {
      var kd = donemSay(kanit && kanit[k]);
      if (!z || yan[k] > z.yanlis || (MUT !== 'esitlik' && yan[k] === z.yanlis && kd > z.kd)) z = { konu: k, yanlis: yan[k], kd: kd };
    });
    return { dogru: dogru, toplam: son.length, zayif: z ? { konu: z.konu, yanlis: z.yanlis } : null };
  }
  /* kanıt [[dönem, soru]...] → farklı dönem sayısı (rakamın TEK kaynağı) */
  function donemSay(liste) {
    if (!liste || !liste.length) return 0;
    if (MUT === 'satir-say') return liste.length;
    var s = {}; liste.forEach(function (x) { s[x[0]] = 1; }); return Object.keys(s).length;
  }
  /* kanıt metni: "2026/2: soru 1, 2 · 2026/1: soru 4" (yeniden eskiye, dosyadaki sıra) */
  function kanitMetni(liste) {
    var g = [], i = {};
    (liste || []).forEach(function (x) { if (!(x[0] in i)) { i[x[0]] = g.length; g.push([x[0], []]); } g[i[x[0]]][1].push(x[1]); });
    return g.map(function (y) { return y[0] + ': soru ' + y[1].join(', '); }).join(' · ');
  }
  /* Türkçe yönelme/bulunma eki: 25'inde, 3'ünde, 6'sında … (sayının okunuşuna göre) */
  function ek(n) {
    var son = n % 10, on = n % 100;
    var okunus = on === 0 ? 'ı' : son === 0 ? ({ 10: 'u', 20: 'si', 30: 'u', 40: 'ı', 50: 'si', 60: 'ı', 70: 'i', 80: 'i', 90: 'ı' }[on] || 'u') : null;
    if (okunus) return ({ 'ı': 'ında', 'u': 'unda', 'si': 'sinde', 'i': 'inde' })[okunus];
    return ({ 1: 'inde', 2: 'sinde', 3: 'ünde', 4: 'ünde', 5: 'inde', 6: 'sında', 7: 'sinde', 8: 'inde', 9: 'unda' })[son];
  }
  var SAF = { ilerle: ilerle, ozet: ozet, donemSay: donemSay, kanitMetni: kanitMetni, ek: ek, ARA: ARA, DAVET: DAVET };
  if (typeof module !== 'undefined' && !kok.document) { module.exports = SAF; return; }

  /* ---- SAYFA ---- */
  var A = null, veri = null, bekle = null;
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function trk(s) { return String(s || '').toLocaleLowerCase('tr-TR').replace(/\s+/g, ' ').trim(); }
  function jsonAl(u) { return fetch(u, { cache: 'no-store' }).then(function (y) { return y.ok ? y.json() : null; }).catch(function () { return null; }); }
  function veriAl() {
    if (veri) return Promise.resolve(veri);
    if (bekle) return bekle;
    bekle = Promise.all([jsonAl(A.kok + 'veri/deneme/smmm-ders-havuz.json'), jsonAl(A.kok + 'veri/deneme/smmm-konu-kanit.json')]).then(function (r) {
      var hv = r[0], kn = r[1], idKonu = {}, kanit = {}, ders = A.ders, pencere = '', donem = 0, ad = '';
      if (hv && hv.dersler) {
        ad = Object.keys(hv.dersler).filter(function (x) { return trk(x) === trk(ders); })[0] || '';
        var h = ad && hv.dersler[ad];
        if (h) h.sorular.forEach(function (x) { var k = h.konular[x[1]]; if (k) idKonu[String(x[0])] = k; });
      }
      if (kn && kn.dersler && ad) { kanit = kn.dersler[ad] || {}; pencere = kn.pencere || ''; donem = +kn.donem || 0; }
      veri = { idKonu: idKonu, kanit: kanit, pencere: pencere, donem: donem, ders: ad || ders };
      bekle = null; return veri;
    });
    return bekle;
  }
  function anahtar() { return 'tt_nn_' + A.yol; }
  function oku() { try { return JSON.parse(localStorage.getItem(anahtar()) || 'null'); } catch (e) { return null; } }
  function yaz(d) { try { localStorage.setItem(anahtar(), JSON.stringify(d)); } catch (e) {} }

  function stil() {
    if (document.getElementById('ttNnStil')) return;
    var s = document.createElement('style'); s.id = 'ttNnStil';
    s.textContent = [
      '#ttNn{position:fixed;inset:0;z-index:2147480001;display:none;align-items:flex-end;justify-content:center;background:color-mix(in srgb,var(--yazi) 35%,transparent)}',
      '#ttNn.acik{display:flex}',
      '#ttNn .k{width:100%;max-width:460px;max-height:88vh;overflow:auto;background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:18px 18px 0 0;padding:20px 18px calc(18px + env(safe-area-inset-bottom));font-family:inherit;box-sizing:border-box}',
      '@media(min-width:600px){#ttNn{align-items:center}#ttNn .k{border-radius:18px}}',
      '#ttNn .etk{font-size:13px;font-weight:700;color:var(--dim);letter-spacing:.02em}',
      '#ttNn .buyuk{font-size:34px;font-weight:800;margin:4px 0 10px}',
      '#ttNn p{margin:0 0 10px;line-height:1.55;font-size:15px}',
      '#ttNn details{margin:0 0 12px;font-size:13px;color:var(--dim)}#ttNn summary{cursor:pointer}',
      '#ttNn .dav{border:1px solid var(--cizgi);border-radius:12px;padding:10px 12px;margin:0 0 12px}',
      '#ttNn .d{display:grid;gap:8px;margin-top:6px}',
      '#ttNn .d a,#ttNn .d button{display:block;width:100%;box-sizing:border-box;text-align:center;font:inherit;font-weight:700;font-size:15px;padding:12px 14px;border-radius:12px;border:1px solid var(--cizgi);background:transparent;color:var(--yazi);text-decoration:none;cursor:pointer}',
      '#ttNn .d .ana{background:var(--mavi);color:var(--ustYazi);border-color:var(--mavi)}',
      /* 15.10 Cem ("x işareti olmayan bir şey istemiyorum"): sağ üstte ✕, 44 px dokunma alanı */
      '#ttNn .k{position:relative}#ttNn .nnX{position:absolute;top:6px;right:6px;width:44px;height:44px;display:flex;align-items:center;justify-content:center;border:0;background:none;color:var(--yazi);font:20px/1 system-ui,sans-serif;cursor:pointer}#ttNn .etk{padding-right:44px}'
    ].join('\n');
    document.head.appendChild(s);
  }
  function kapat() { var e = document.getElementById('ttNn'); if (e) e.classList.remove('acik'); }
  if (typeof document !== 'undefined') document.addEventListener('keydown', function (x) { if (x.key === 'Escape') kapat(); });
  function goster(d, davet) {
    veriAl().then(function (v) {
      var o = ozet(d.son, v.idKonu, v.kanit), z = o.zayif, h = '';
      var deneme = A.kok + 'sinav-gibi.html?tur=ders&sinav=smmm&ders=' + encodeURIComponent(v.ders);
      h += '<div class="etk">🧭 Nöbetçi notu · ' + d.n + '. soru</div>';
      h += '<div class="buyuk">' + o.toplam + '\'da ' + o.dogru + ' doğru</div>';
      if (z) {
        var kl = v.kanit[z.konu], ds = donemSay(kl);
        h += '<p>Bu ' + o.toplam + ' soruda en çok <b>' + esc(z.konu) + '</b> konusunda zorlandın (' + z.yanlis + ' yanlış).</p>';
        if (ds && v.pencere && v.donem) {
          h += '<p>Bu konu ' + esc(v.pencere.replace('-', '–')) + ' arasındaki ' + v.donem + ' sınavın <b>' + ds + '</b>\'' + ek(ds) + ' soruldu.</p>';
          h += '<details><summary>Kanıt: hangi sınav, kaçıncı soru</summary>' + esc(kanitMetni(kl)) + '</details>';
        }
      } else if (o.dogru === o.toplam) h += '<p>Bu ' + o.toplam + ' soruda yanlışın yok. Böyle devam.</p>';
      else h += '<p>Yanlışların farklı konulara dağılmış; tek bir konuda yığılma yok.</p>';
      if (davet && !A.ios) h += '<div class="dav"><p style="margin:0 0 8px"><b>Ders denemesine hazırsın.</b> Gerçek sınav düzeni: 20 soru, 45 dakika, yanlış doğrunun 0,25\'ini götürür.</p>'
        + '<div class="d" style="margin:0"><a class="ana" href="' + esc(deneme) + '">Ders denemesini başlat →</a></div></div>';
      h += '<div class="d">';
      if (z && !A.ios) h += '<a class="' + (davet ? '' : 'ana') + '" href="' + esc(deneme + '&konu=' + encodeURIComponent(z.konu) + '&adet=10') + '">Bu konudan 10 soru →</a>';
      if (o.dogru < o.toplam && typeof A.tekrar === 'function') h += '<button type="button" data-nn="tekrar">Yanlışlarımı yeniden çöz</button>';
      h += '<button type="button" data-nn="devam"' + (z || davet ? '' : ' class="ana"') + '>Devam</button></div>';
      stil();
      var e = document.getElementById('ttNn');
      if (!e) { e = document.createElement('div'); e.id = 'ttNn'; e.setAttribute('role', 'dialog'); e.setAttribute('aria-modal', 'true'); e.setAttribute('aria-label', 'Nöbetçi notu'); document.body.appendChild(e);
        e.addEventListener('click', function (x) { if (x.target === e) kapat(); }); }
      e.innerHTML = '<div class="k"><button type="button" class="nnX" aria-label="Kapat">✕</button>' + h + '</div>';
      e.classList.add('acik');
      e.querySelector('.nnX').onclick = kapat;
      var t = e.querySelector('[data-nn="tekrar"]'); if (t) t.onclick = function () { kapat(); try { A.tekrar(); } catch (x) {} };
      e.querySelector('[data-nn="devam"]').onclick = kapat;
      var ilk = e.querySelector('.d a, .d button'); if (ilk) try { ilk.focus({ preventScroll: true }); } catch (x) {}
    });
  }

  kok.ttNobetciNotu = {
    saf: SAF,
    /* o: {yol, kok, ders, tekrar?: fn, ios?: bool} */
    kur: function (o) {
      if (A || !o || !o.yol || !/^kaydir\/smmm\//.test(o.yol)) return;
      A = { yol: o.yol, kok: o.kok || '', ders: o.ders || '', tekrar: o.tekrar || null, ios: !!o.ios };
      veriAl();
    },
    cevap: function (id, dogru) {
      if (!A || id == null) return;
      var r = ilerle(oku(), id, dogru);
      if (r.davet) r.durum.davet = true;
      yaz(r.durum);
      if (r.goster) setTimeout(function () { goster(r.durum, r.davet); }, 1400);
    }
  };
})(typeof window !== 'undefined' ? window : this);
