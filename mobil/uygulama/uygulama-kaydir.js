/* uygulama-kaydir.js — KAYDIR-ÇÖZ SORU EKRANININ TELEFON DÜZENİ (26.09.2026, Cem "yap hepsini")
 *
 * Sitedeki Kaydır-Çöz sayfası uygulamaya olduğu gibi gömülür (mobil/hazirla.js); bu dosya YALNIZ
 * uygulamada, sayfanın üstüne bir düzen katmanı ekler. Sitedeki sayfaya ve cevap kalıbına dokunmaz
 * (STANDART-CEVAP-KALIBI.md kilitli): hiçbir soru/açıklama metni değişmez, yalnız yerleşim ve gezinme.
 *
 * Neyi çözer (26.09 telefon incelemesi + rakip incelemesi: UWorld, Pocket Prep, AMBOSS, Magoosh):
 *   1) Kenar taşması: Android 15+ uygulamayı ekranın en üstünden başlatır; üst şerit saatin, alt
 *      düğmeler hareket çubuğunun altında kalıyordu → güvenli alan (safe-area) boşlukları.
 *   2) Kalabalık üst şerit: konu tek satır, ilerleme noktaları gizli, "1 / 30" tek satır ve DOKUNULUNCA
 *      numaralı soru listesi açılır (doğru yeşil / yanlış kırmızı) → istenen soruya atlanır.
 *   3) Cevaptan sonra soru görünmüyordu: açıklama kartı şıkları örtüyor, aşağı çekilemiyordu. Artık kartın
 *      başında "▼ Soruyu gör" var; aşağı kaydırınca da küçülür, soru ve renkli şıklar görünür; "▲ Açıklama"
 *      ile geri açılır (rakiplerde açıklama sorunun altında, soru hiç kaybolmaz).
 *   4) "Kâğıt" düğmesi "Sonraki" düğmesinin üstüne biniyordu → cevaptan sonra gizli ("Kâğıdım" zaten kartta).
 *   5) İki ayrı görünüm: soru ekranı hep koyu, ana ekran telefona göre açık/koyu → soru ekranı da TELEFONUN
 *      ayarını izler; sayfadaki tema düğmesi uygulamada gizli.
 * BU DOSYA ŞUNU YAPMAZ: soru sırasını, puanlamayı, kayıtları değiştirmez; sitede yüklenmez.
 */
(function () {
  var kok = document.documentElement;

  /* 5) Tema: sayfanın kendi tema betiği (kc_tema) bu dosyadan SONRA çalışır; uygulamanın görünüm tercihini
        (ilerleme.js TTGorunum — varsayılan açık) ona yazarız; durum çubuğu ikonları da zemine göre. */
  try {
    var koyu = window.TTGorunum ? window.TTGorunum.koyu() : false;
    localStorage.setItem('kc_tema', koyu ? 'dark' : 'light');
    if (window.TTGorunum) window.TTGorunum.cubuk();
  } catch (e) {}

  /* Kenar payları: Capacitor 8 SystemBars (varsayılan "css") Android'de --safe-area-inset-* değişkenlerini
     yazar; iOS ve yeni Chromium'da env() doğru döner. İkisinden büyüğü alınır. */
  var UST = 'max(env(safe-area-inset-top),var(--safe-area-inset-top,0px))';
  var ALT = 'max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px))';
  var st = document.createElement('style');
  st.textContent = [
    /* 1) güvenli alan — soru kartı */
    '#akis>.kart{padding-top:calc(14px + ' + UST + ')!important}',
    '#akis>.kart .panel{padding-bottom:calc(20px + ' + ALT + ')!important}',
    '#akis>.kart .ipucu{bottom:calc(14px + ' + ALT + ')!important}',
    '#akis>.kart .kagitAc{bottom:calc(44px + ' + ALT + ')!important}',
    /* tam ekran açılan katmanlar: 🎬 Nöbetçi anlatsın (.ders, altında Geri/İleri), ⚖️ Sen çöz (.oyun),
       📥 yanlış kutusu (.kutuIc). 26.09 Cem: "İleri tuşu telefonun geri tuşuna yakın geliyor". */
    '.ders{padding-top:calc(12px + ' + UST + ')!important}',
    '.ders .altc{padding-bottom:calc(18px + ' + ALT + ')!important}',
    '.oyun{padding-top:calc(14px + ' + UST + ')!important;padding-bottom:calc(18px + ' + ALT + ')!important}',
    '.kutuIc{padding-bottom:calc(22px + ' + ALT + ')!important}',
    '#ttGeri{top:calc(10px + ' + UST + ')!important}',
    /* tam ekran katman açıkken sol üstteki "‹" başlığın üstüne binmesin (katmanın kendi ✕ düğmesi var) */
    'body:has(.ders.acik) #ttGeri,body:has(.oyun.acik) #ttGeri,body:has(#ttListe.acik) #ttGeri{display:none!important}',
    '#temaB{display:none!important}',
    /* 2) üst şerit: tek satır */
    '#ttGeri{padding:0!important;width:36px;height:36px;display:flex!important;align-items:center;justify-content:center;font-size:20px!important;line-height:1!important}',
    '#akis .ust{padding-left:48px!important;flex-wrap:nowrap!important;gap:8px;min-height:36px}',
    '#akis .ust>span:first-child{flex:1 1 auto;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}',
    '#akis .ust .noktalar{display:none!important}',
    '#akis .ust .seviye{display:none!important}',   /* Nöbet/Isınma etiketi telefonda yer kaplıyordu (26.09) */
    '#akis .ust .ustSag{flex:0 0 auto;white-space:nowrap;gap:6px}',
    '.ttNo{font:inherit;font-weight:700;color:var(--yazi);background:var(--kart);border:1px solid var(--cizgi);border-radius:14px;padding:3px 9px;cursor:pointer;white-space:nowrap}',
    '.ttNo:after{content:" ▾";font-size:.8em;opacity:.7}',
    /* 3) açıklama kartı: küçülür / açılır */
    '.ttPanelBar{position:sticky;top:-12px;z-index:2;display:flex;justify-content:center;margin:-12px -14px 8px;padding:10px 14px 8px;background:var(--kart);border-bottom:1px solid var(--cizgi)}',
    '.ttPanelBar button{font:inherit;font-size:.9em;font-weight:700;color:var(--yazi);background:transparent;border:1px solid var(--cizgi);border-radius:999px;padding:6px 16px;cursor:pointer}',
    '#akis>.kart .panel.acik.ttKucuk{transform:translateY(calc(100% - 58px - ' + ALT + '))!important;overflow:hidden!important}',
    '#akis>.kart .panel.acik.ttKucuk .ttPanelBar{border-bottom:0}',
    /* 4) cevaptan sonra yüzen Kâğıt düğmesi gizli */
    '#akis>.kart.cevaplandi .kagitAc{display:none!important}',
    /* Kâğıt düğmesi uzun sorularda E şıkkının yazısını örtüyordu (26.09) → yalnız kalem ikonlu küçük yuvarlak (emoji yok) */
    '#akis>.kart .kagitAc{font-size:0!important;width:44px;height:44px;padding:0!important;border-radius:50%!important;display:flex;align-items:center;justify-content:center;right:10px!important}',
    '#akis>.kart .kagitAc:before{content:"";width:18px;height:18px;background:currentColor;-webkit-mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.7%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Cpath d=%27M4 20h4L19 9l-4-4L4 16z%27/%3E%3Cpath d=%27m13.5 6.5 4 4%27/%3E%3C/svg%3E") center/contain no-repeat;mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.7%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Cpath d=%27M4 20h4L19 9l-4-4L4 16z%27/%3E%3Cpath d=%27m13.5 6.5 4 4%27/%3E%3C/svg%3E") center/contain no-repeat}',
    /* numaralı soru listesi */
    '#ttListe{position:fixed;inset:0;z-index:2147481000;background:rgba(0,0,0,.55);display:none;align-items:flex-end;justify-content:center}',
    '#ttListe.acik{display:flex}',
    '#ttListe .ic{width:min(100%,560px);max-height:75%;overflow-y:auto;background:var(--kart);color:var(--yazi);border-radius:18px 18px 0 0;padding:16px 16px calc(18px + ' + ALT + ')}',
    '#ttListe h3{margin:0 0 4px;font-size:1.05em}',
    '#ttListe p{margin:0 0 12px;font-size:.82em;color:var(--dim)}',
    '#ttListe .izgara{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}',
    '#ttListe .izgara button{font:inherit;font-weight:700;aspect-ratio:1;border-radius:12px;border:1px solid var(--cizgi);background:var(--bg);color:var(--yazi);cursor:pointer}',
    '#ttListe .izgara button.ok{background:color-mix(in srgb,var(--yesil) 25%,var(--bg));border-color:var(--yesil)}',
    '#ttListe .izgara button.yan{background:color-mix(in srgb,var(--kirmizi) 25%,var(--bg));border-color:var(--kirmizi)}',
    '#ttListe .izgara button.simdi{outline:2px solid var(--mavi);outline-offset:2px}',
    '#ttListe .kapat{display:block;width:100%;margin-top:14px;font:inherit;font-weight:700;padding:11px;border-radius:12px;border:1px solid var(--cizgi);background:transparent;color:var(--yazi);cursor:pointer}'
  ].join('\n');
  (document.head || kok).appendChild(st);

  /* ---- çalışma özellikleri (26.09 "eksiklerin hepsi"): ilerleme.js kaydına dayanır ---- */
  var IL = window.TTIlerleme || null;
  var YOL = (location.pathname.match(/kaydir\/[^?#]+\.html$/) || [''])[0];
  var st2 = document.createElement('style');
  st2.textContent = [
    /* 26.09 (Cem "yapay zekâ gibi durmasın"): başlık çiplerinin emojisi silinir (cipTemizle), yerine çizgi ikon */
    '.ustCip.skorCip:before,.ustCip.kutuCip:before{content:"";display:inline-block;width:14px;height:14px;margin-right:5px;vertical-align:-2px;background:currentColor}',
    '.ustCip.skorCip:before{-webkit-mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.8%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Ccircle cx=%2712%27 cy=%2712%27 r=%278%27/%3E%3Ccircle cx=%2712%27 cy=%2712%27 r=%273.5%27/%3E%3C/svg%3E") center/contain no-repeat;mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.8%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Ccircle cx=%2712%27 cy=%2712%27 r=%278%27/%3E%3Ccircle cx=%2712%27 cy=%2712%27 r=%273.5%27/%3E%3C/svg%3E") center/contain no-repeat}',
    '.ustCip.kutuCip:before{-webkit-mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.8%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Cpath d=%27M3.5 13.5 6 5h12l2.5 8.5V19H3.5z%27/%3E%3Cpath d=%27M3.5 13.5H9l1 2h4l1-2h5.5%27/%3E%3C/svg%3E") center/contain no-repeat;mask:url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27black%27 stroke-width=%271.8%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Cpath d=%27M3.5 13.5 6 5h12l2.5 8.5V19H3.5z%27/%3E%3Cpath d=%27M3.5 13.5H9l1 2h4l1-2h5.5%27/%3E%3C/svg%3E") center/contain no-repeat}',
    '.govde .rozet:before{content:"";display:inline-block;width:6px;height:6px;margin-right:8px;vertical-align:2px;background:currentColor}',
    '.ttBayrak{display:inline-flex;align-items:center;justify-content:center;line-height:1;background:transparent;border:1px solid var(--cizgi);border-radius:8px;padding:4px 7px;cursor:pointer;color:var(--dim,#8b8b93)}',
    '.ttBayrak svg{fill:none;stroke:currentColor;stroke-width:1.7;stroke-linejoin:round}',
    '.ttBayrak.acik{color:var(--altin,#f5a524);border-color:var(--altin,#f5a524)}',
    '.ttBayrak.acik svg{fill:currentColor}',
    '.ttPanelBar{gap:8px}',
    '.ttNotKutu{margin:10px 0 4px;padding:10px 12px;border:1px dashed var(--cizgi);border-radius:12px;font-size:.9em;white-space:pre-wrap}',
    '#ttNotEkran{position:fixed;inset:0;z-index:2147481500;background:rgba(0,0,0,.55);display:none;align-items:flex-end;justify-content:center}',
    '#ttNotEkran.acik{display:flex}',
    '#ttNotEkran .ic{width:min(100%,560px);background:var(--kart);color:var(--yazi);border-radius:18px 18px 0 0;padding:16px 16px calc(16px + ' + ALT + ')}',
    '#ttNotEkran textarea{width:100%;min-height:140px;box-sizing:border-box;font:inherit;padding:10px;border-radius:12px;border:1px solid var(--cizgi);background:var(--bg);color:var(--yazi)}',
    '#ttNotEkran .satir{display:flex;gap:8px;margin-top:10px}',
    '#ttNotEkran .satir button,#ttListe .dugme{flex:1;font:inherit;font-weight:700;padding:11px;border-radius:12px;border:1px solid var(--cizgi);background:transparent;color:var(--yazi);cursor:pointer}',
    '#ttNotEkran .satir .ana,#ttListe .dugme.ana{background:var(--mavi);color:var(--ustYazi,#fff);border-color:transparent}',
    '#ttListe .sekmeler{display:flex;gap:6px;margin:0 0 12px}',
    '#ttListe .sekmeler button{flex:1;font:inherit;font-size:.85em;font-weight:700;padding:7px 4px;border-radius:999px;border:1px solid var(--cizgi);background:transparent;color:var(--dim);cursor:pointer}',
    '#ttListe .sekmeler button.secili{color:var(--yazi);border-color:var(--yazi)}',
    '#ttListe .izgara button{position:relative}',
    '#ttListe .izgara button.bay:after{content:"";position:absolute;top:3px;right:3px;width:6px;height:6px;background:var(--altin,#f5a524)}',
    '#ttListe .izgara button.gizli{display:none}',
    '#ttListe .yazi{display:flex;align-items:center;gap:8px;margin:14px 0 0;font-size:.9em;color:var(--dim)}',
    '#ttListe .yazi button{font:inherit;font-weight:800;min-width:44px;padding:6px 10px;border-radius:10px;border:1px solid var(--cizgi);background:transparent;color:var(--yazi);cursor:pointer}',
    '#ttListe .bos{grid-column:1/-1;color:var(--dim);font-size:.9em;padding:8px 0}',
    '#ttSerit{position:fixed;left:50%;transform:translateX(-50%);top:calc(58px + ' + UST + ');z-index:2147480000;max-width:92%;background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:999px;padding:8px 8px 8px 14px;display:flex;align-items:center;gap:10px;font-size:.85em;box-shadow:0 6px 20px rgba(0,0,0,.3)}',
    '#ttSerit button{font:inherit;font-weight:700;border:0;border-radius:999px;padding:6px 12px;background:var(--mavi);color:var(--ustYazi,#fff);cursor:pointer}',
    '#akis>.kart.ttDisarda,#akis>.ttDisarda{display:none!important}',
    /* yazı boyutu: soru + şıklar + açıklama birlikte büyür */
    '#akis .govde,#akis .panel{zoom:var(--ttYazi,1)}'
  ].join('\n');
  (document.head || kok).appendChild(st2);
  function yaziUygula() { var z = IL ? (IL.veri().ayar.yazi || 1) : 1; kok.style.setProperty('--ttYazi', String(z)); }
  yaziUygula();

  function akis() { return document.getElementById('akis'); }
  function kartlar() { var a = akis(); return a ? [].slice.call(a.children).filter(function (k) { return k.classList.contains('kart') && k.querySelector('.sik'); }) : []; }
  function gorunen() { return kartlar().filter(function (k) { return !k.classList.contains('ttDisarda'); }); }
  function simdikiKart() { var a = akis(); if (!a || !a.clientHeight) return null; var g = gorunen(); return g[Math.round(a.scrollTop / a.clientHeight)] || null; }
  /* karne için sorunun bilgisi (26.09): ders, konu, süre, düşülen tuzak, çıkmış dönem, sıra. Kaynak: sayfanın kendi
     SORULAR dizisi ve durum.sn (sayfa motoru cevap anında saniyeyi yazar). Bulunamazsa alan boş kalır (uydurma yok). */
  function kartBilgi(k, sik) {
    try {
      var i = +k.getAttribute('data-i'), q = (typeof SORULAR !== 'undefined' && SORULAR[i]) || null, h = sik.getAttribute('data-h');
      var sn = (typeof durum !== 'undefined' && durum.sn && durum.sn[i] != null) ? durum.sn[i] : null;
      if (!q) return { sn: sn };
      var tz = (!sik.classList.contains('dogru') && q.tuzak && q.tuzak[h] && q.tuzak[h].ad) ? String(q.tuzak[h].ad).slice(0, 80) : null;
      var p = Math.max(+q.donem || 0, (q.cikmis && q.cikmis.donemler) ? q.cikmis.donemler.length : 0);
      return { d: String(q.ders || '').slice(0, 80), k: String(q.konu || '').slice(0, 80), sn: sn, tz: tz, p: p || null, i: window.TTKarma ? null : i };
    } catch (e) { return null; }
  }
  /* karma (kısa sınav): kart hangi dersin sayfasından geldiyse o yol (uygulama-karma.js) */
  function kartYol(k) { return (window.TTKarma && window.TTKarma.yol(kartlar().indexOf(k))) || YOL; }
  function sidK(k) { if (!k.__sid) { var q = k.querySelector('.soru'); k.__sid = IL ? IL.sid(q ? q.textContent : '') : ''; } return k.__sid; }
  function durumK(k) { var c = IL && IL.veri().cevap[sidK(k)]; return c ? c.s : null; }
  function serit(metin, dugme, fn, sure) {
    var s = document.getElementById('ttSerit'); if (s) s.remove();
    s = document.createElement('div'); s.id = 'ttSerit'; s.innerHTML = '<span></span>';
    s.firstChild.textContent = metin;
    if (dugme) { var b = document.createElement('button'); b.type = 'button'; b.textContent = dugme; b.onclick = function () { s.remove(); fn(); }; s.appendChild(b); }
    document.body.appendChild(s);
    if (sure) setTimeout(function () { if (s.parentNode) s.remove(); }, sure);
    return s;
  }

  /* numaralı soru listesi: Tümü / Yanlışlar / İşaretliler + yanlışları tekrar çöz + yazı boyutu.
     Renkler kalıcı kayıttan (önceki oturumlar dahil); kayıt yoksa sayfanın ilerleme noktalarından. */
  var listeSuzgec = 'tum';
  function listeAc() {
    var l = document.getElementById('ttListe');
    if (!l) {
      l = document.createElement('div'); l.id = 'ttListe';
      l.innerHTML = '<div class="ic" role="dialog" aria-label="Soru listesi"><h3>Sorular</h3>' +
        '<p>Yeşil doğru, kırmızı yanlış; köşesinde nokta olanlar işaretlediklerin. Bir soruya dokun, oraya git.</p>' +
        '<div class="sekmeler"><button type="button" data-s="tum">Tümü</button><button type="button" data-s="yan">Yanlışlar</button><button type="button" data-s="bay">İşaretliler</button></div>' +
        '<div class="izgara"></div>' +
        '<button type="button" class="dugme ana tekrar" style="width:100%;margin-top:14px">Yanlışlarımı tekrar çöz</button>' +
        '<div class="ttAraclar"><button type="button" data-arac="kutu"><b>Yanlış kutusu</b><span></span></button>' +
        '<button type="button" data-arac="skor"><b>Hazırlık skoru</b><span></span></button></div>' +
        '<div class="yazi">Yazı boyutu <button type="button" data-z="-1">A−</button><button type="button" data-z="0">A</button><button type="button" data-z="1">A+</button></div>' +
        '<button type="button" class="kapat">Kapat</button></div>';
      document.body.appendChild(l);
      l.addEventListener('click', function (e) {
        var t = e.target;
        if (t === l || t.classList.contains('kapat')) return l.classList.remove('acik');
        if (t.dataset.s) { listeSuzgec = t.dataset.s; return listeCiz(l); }
        if (t.dataset.z !== undefined && IL) {
          var z = IL.veri().ayar.yazi || 1, d = +t.dataset.z;
          z = d === 0 ? 1 : Math.max(0.85, Math.min(1.5, Math.round((z + d * 0.1) * 100) / 100));
          IL.ayarYaz({ yazi: z }); yaziUygula(); return;
        }
        if (t.classList.contains('tekrar')) return tekrarBaslat();
        var arac = t.closest && t.closest('[data-arac]');
        if (arac) {   /* sayfanın kendi çipine dokun: yanlış kutusu / skor açıklaması sayfa motorunda açılır */
          l.classList.remove('acik');
          var kk = simdikiKart() || kartlar()[0], cp = kk && kk.querySelector(arac.dataset.arac === 'kutu' ? '.kutuCip' : '.skorCip');
          if (cp) cp.click();
        }
      });
    }
    /* araçların güncel değeri: sayfanın çip yazısı (emoji zaten silinmiş) */
    var kc = document.querySelector('.ustCip.kutuCip'), sc = document.querySelector('.ustCip.skorCip');
    l.querySelector('[data-arac=kutu] span').textContent = kc ? kc.textContent.trim() : '';
    l.querySelector('[data-arac=skor] span').textContent = sc ? sc.textContent.trim() : '';
    listeCiz(l);
    l.classList.add('acik');
  }
  function listeCiz(l) {
    [].forEach.call(l.querySelectorAll('.sekmeler button'), function (b) { b.classList.toggle('secili', b.dataset.s === listeSuzgec); });
    var ks = kartlar(), su = simdikiKart(), nok = document.querySelector('#akis .noktalar');
    var iz = l.querySelector('.izgara'); iz.innerHTML = '';
    var yanlisVar = false, gosterilen = 0;
    ks.forEach(function (k, j) {
      var b = document.createElement('button'); b.type = 'button'; b.textContent = j + 1;
      var d = durumK(k);
      if (!d) { var n = nok && nok.querySelector('i[data-j="' + j + '"]'); d = n && n.classList.contains('ok') ? 'ok' : n && n.classList.contains('yan') ? 'yan' : null; }
      if (d) b.classList.add(d);
      if (d === 'yan') yanlisVar = true;
      var bay = IL && IL.bayrakVar(sidK(k)); if (bay) b.classList.add('bay');
      if (k === su) b.classList.add('simdi');
      var goster = listeSuzgec === 'tum' || (listeSuzgec === 'yan' && d === 'yan') || (listeSuzgec === 'bay' && bay);
      if (!goster || k.classList.contains('ttDisarda')) b.classList.add('gizli'); else gosterilen++;
      b.addEventListener('click', function () { l.classList.remove('acik'); k.scrollIntoView({ behavior: 'smooth' }); });
      iz.appendChild(b);
    });
    if (!gosterilen) { var bos = document.createElement('div'); bos.className = 'bos'; bos.textContent = listeSuzgec === 'bay' ? 'Henüz işaretlediğin soru yok. Sorunun üstündeki işaret düğmesiyle işaretle.' : 'Bu listede soru yok.'; iz.appendChild(bos); }
    l.querySelector('.tekrar').hidden = !yanlisVar;
  }

  /* yanlışları tekrar çöz: sayfa cevapları bellekte tuttuğu için yeniden yüklenir, yalnız yanlış kartlar görünür */
  var TEKRAR = 'tt_tekrar';
  function tekrarBaslat() {
    var liste = []; kartlar().forEach(function (k) { if (durumK(k) === 'yan') liste.push(sidK(k)); });
    if (!liste.length) return;
    try { sessionStorage.setItem(TEKRAR, JSON.stringify({ yol: YOL, sid: liste })); } catch (e) {}
    history.replaceState(null, '', location.pathname + location.search); location.reload();
  }
  function tekrarKur() {
    var t = null; try { t = JSON.parse(sessionStorage.getItem(TEKRAR) || 'null'); } catch (e) {}
    if (!t || t.yol !== YOL) return false;
    var ks = kartlar(); if (!ks.length) return false;
    var kalan = 0;
    ks.forEach(function (k) { var ic = t.sid.indexOf(sidK(k)) >= 0; k.classList.toggle('ttDisarda', !ic); if (ic) kalan++; });
    [].forEach.call(akis().children, function (x) { if (!x.querySelector('.sik')) x.classList.add('ttDisarda'); });
    serit('Yanlışlarını tekrar çözüyorsun: ' + kalan + ' soru', 'Bitir', function () {
      try { sessionStorage.removeItem(TEKRAR); } catch (e) {} location.reload();
    });
    akis().scrollTop = 0;
    return true;
  }

  function notAc(k) {
    var e = document.getElementById('ttNotEkran');
    if (!e) {
      e = document.createElement('div'); e.id = 'ttNotEkran';
      e.innerHTML = '<div class="ic"><h3 style="margin:0 0 8px">Bu soruya notun</h3><textarea maxlength="2000" placeholder="Kendi cümlenle kural, tuzak, hatırlatma…"></textarea>' +
        '<div class="satir"><button type="button" class="vaz">Vazgeç</button><button type="button" class="ana kay">Kaydet</button></div></div>';
      document.body.appendChild(e);
      e.addEventListener('click', function (ev) { if (ev.target === e || ev.target.classList.contains('vaz')) e.classList.remove('acik'); });
    }
    var ta = e.querySelector('textarea'), n = IL && IL.notu(sidK(k));
    ta.value = n ? n.m : '';
    e.querySelector('.kay').onclick = function () { if (IL) IL.notYaz(sidK(k), ta.value, YOL, kartlar().indexOf(k)); e.classList.remove('acik'); notCiz(k); };
    e.classList.add('acik'); setTimeout(function () { ta.focus(); }, 50);
  }
  function notCiz(k) {
    var p = k.querySelector('.panel'); if (!p) return;
    var kutu = p.querySelector('.ttNotKutu'), n = IL && IL.notu(sidK(k));
    if (!n) { if (kutu) kutu.remove(); return; }
    if (!kutu) { kutu = document.createElement('div'); kutu.className = 'ttNotKutu'; var bar = p.querySelector('.ttPanelBar'); p.insertBefore(kutu, bar ? bar.nextSibling : p.firstChild); }
    kutu.textContent = 'Notun: ' + n.m;
  }

  /* her karta bir kez: "i / N" düğmesi, işaret (bayrak), açıklama kartına küçült/aç + not, cevap kaydı */
  function kartiDuzenle(k) {
    if (k.__tt) return; k.__tt = 1;
    /* şık harfi rozette yalnız harf: "A)" → "A" (görünüm; data-h ve içerik aynı) */
    [].forEach.call(k.querySelectorAll('.sik>b'), function (b) { b.textContent = b.textContent.replace(/[)\s]+$/, ''); });
    var sag = k.querySelector('.ustSag');
    if (sag) {
      for (var i = sag.childNodes.length - 1; i >= 0; i--) {
        var d = sag.childNodes[i];
        if (d.nodeType === 3 && /\d+\s*\/\s*\d+/.test(d.textContent)) {
          var b = document.createElement('button'); b.type = 'button'; b.className = 'ttNo';
          b.textContent = d.textContent.replace(/\s+/g, ' ').trim();
          b.setAttribute('aria-label', 'Soru listesini aç');
          b.addEventListener('click', function (e) { e.stopPropagation(); listeAc(); });
          sag.replaceChild(b, d); break;
        }
      }
      if (IL) {
        var bay = document.createElement('button'); bay.type = 'button'; bay.className = 'ttBayrak';
        bay.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M6.5 3.5h11v17l-5.5-4-5.5 4z"/></svg>';
        bay.setAttribute('aria-label', 'Soruyu işaretle');
        bay.classList.toggle('acik', IL.bayrakVar(sidK(k)));
        bay.addEventListener('click', function (e) {
          e.stopPropagation();
          var acik = IL.bayrakDegis(sidK(k), YOL, kartlar().indexOf(k)); bay.classList.toggle('acik', acik);
          serit(acik ? 'İşaretlendi. Listede "İşaretliler"de bulursun.' : 'İşaret kaldırıldı.', null, null, 2200);
        });
        sag.insertBefore(bay, sag.firstChild);
      }
    }
    var p = k.querySelector('.panel');
    if (p && !p.querySelector('.ttPanelBar')) {
      var bar = document.createElement('div'); bar.className = 'ttPanelBar';
      var dg = document.createElement('button'); dg.type = 'button'; dg.textContent = '▼ Soruyu gör';
      bar.appendChild(dg);
      if (IL) { var nb = document.createElement('button'); nb.type = 'button'; nb.textContent = 'Not'; nb.addEventListener('click', function (e) { e.stopPropagation(); notAc(k); }); bar.appendChild(nb); }
      p.insertBefore(bar, p.firstChild);
      notCiz(k);
      var kucult = function (evet) { p.classList.toggle('ttKucuk', evet); dg.textContent = evet ? '▲ Açıklamayı aç' : '▼ Soruyu gör'; if (!evet) p.scrollTop = 0; };
      dg.addEventListener('click', function (e) { e.stopPropagation(); kucult(!p.classList.contains('ttKucuk')); });
      /* aşağı çekme: açıklamanın başındayken parmak aşağı giderse küçül; küçükken yukarı çekince aç */
      var y0 = null;
      p.addEventListener('touchstart', function (e) { y0 = e.touches[0].clientY; }, { passive: true });
      p.addEventListener('touchmove', function (e) {
        if (y0 === null) return;
        var dy = e.touches[0].clientY - y0;
        if (!p.classList.contains('ttKucuk') && p.scrollTop <= 0 && dy > 60) { kucult(true); y0 = null; }
        else if (p.classList.contains('ttKucuk') && dy < -40) { kucult(false); y0 = null; }
      }, { passive: true });
      p.addEventListener('touchend', function () { y0 = null; }, { passive: true });
      /* kart yeniden açılınca (Tekrar / sıfırla) küçük hâl kalmasın */
      try { new MutationObserver(function () { if (!p.classList.contains('acik')) kucult(false); }).observe(p, { attributes: true, attributeFilter: ['class'] }); } catch (e2) {}
    }
    /* cevap kaydı: sayfanın kendi dinleyicisi şıkları boyadıktan SONRA sonucu okuruz */
    if (IL) [].forEach.call(k.querySelectorAll('.sik'), function (s) {
      s.addEventListener('click', function () {
        if (k.__cevaplandi) return;
        setTimeout(function () {
          if (!k.querySelector('.sik.dogru')) return;
          k.__cevaplandi = 1;
          IL.cevapla(sidK(k), s.classList.contains('dogru'), kartYol(k), kartBilgi(k, s));
          if (window.TTHis) { if (s.classList.contains('dogru')) window.TTHis.dogru(); else window.TTHis.yanlis(); }
          cevapSonrasi();
          var g = IL.veri().gun[IL.bugun()] || 0, h = IL.veri().ayar.hedef || 10;
          if (g === h) serit('Günlük hedef tamam · ' + h + ' soru · seri ' + IL.seri() + ' gün', null, null, 3500);
        }, 0);
      });
    });
  }

  /* kaldığın yerden devam: kaydırmada konum yazılır; açılışta (derin bağlantı yoksa) o karta gidilir */
  var konumKuruldu = false, izleyici = null, konumZam = null;
  function konumKur() {
    /* tek kart modu (günün sorusu): kaldığın yer yazılmaz, "Devam et" oraya gitmesin */
    if (konumKuruldu || !IL || !YOL || kok.hasAttribute('data-tek') || window.TTKarma) return;
    var a = akis(), ks = kartlar(); if (!a || !ks.length) return;
    konumKuruldu = true;
    var tekrarda = tekrarKur();
    a.addEventListener('scroll', function () {
      clearTimeout(konumZam);
      konumZam = setTimeout(function () { var k = simdikiKart(); if (k && !tekrarda) IL.konumYaz(YOL, kartlar().indexOf(k)); }, 400);
    }, { passive: true });
    if (tekrarda || /#s=\d+/.test(location.hash)) return;
    var i = IL.konumu(YOL);
    if (i > 0 && ks[i]) {
      setTimeout(function () { a.style.scrollBehavior = 'auto'; ks[i].scrollIntoView(); a.style.scrollBehavior = ''; }, 50);
      serit('Kaldığın yerden: ' + (i + 1) + '. soru', 'Baştan', function () { a.scrollTo({ top: 0, behavior: 'smooth' }); }, 6000);
    } else IL.konumYaz(YOL, 0);
  }

  /* sayfanın kendi yazdığı çip/rozet metnindeki baştaki emojiyi sil (sayfa çipi her cevaptan sonra yeniden yazar) */
  var EMOJI = /^[\u2190-\u2BFF\uFE0F\s]*(?:[\uD83C-\uD83E][\uDC00-\uDFFF][\uFE0F\s]*)*/;
  function cipTemizle(kok) {
    [].forEach.call((kok || document).querySelectorAll('.ustCip.skorCip,.ustCip.kutuCip,.govde .rozet'), function (el) {
      var t = el.textContent, y = t.replace(EMOJI, '');
      if (y !== t && el.children.length === 0) el.textContent = y;
      else if (y !== t && el.firstChild && el.firstChild.nodeType === 3) el.firstChild.textContent = el.firstChild.textContent.replace(EMOJI, '');
    });
  }
  var cipIzleyici = null;
  /* iskelet yükleme: kasa-yukle.js'in "Sorular yükleniyor…" durum kutusu yerine sayfa biçiminde gri çubuklar */
  (function () {
    function iskelet() {
      var a = document.getElementById('akis'); if (!a) return;
      var d = a.firstElementChild;
      if (d && d.getAttribute && d.getAttribute('role') === 'status' && /yükleniyor/i.test(d.textContent || '') && !d.__tt) {
        d.__tt = 1; d.className = 'ttIskelet'; d.removeAttribute('style'); d.setAttribute('aria-label', 'Sorular yükleniyor');
        d.innerHTML = '<i></i><i></i><i></i><i class="s"></i><i class="s"></i><i class="s"></i><i class="s"></i><i class="s"></i>';
      }
    }
    try { var a0 = document.getElementById('akis'); if (a0) new MutationObserver(iskelet).observe(a0, { childList: true }); } catch (e) {}
    document.addEventListener('DOMContentLoaded', iskelet);
  })();

  /* ---------- UYGULAMA GÖRÜNÜM KATMANI (26.09.2026, Cem "uygulamada yap") ----------
     Ana ekranla aynı dil: lacivert zemin, beyaz ana düğme, marka turuncusu, emoji YOK.
     Sitenin dosyasına ve SORU İÇERİĞİNE dokunulmaz: yalnız renk jetonları ezilir ve metin düğümlerinin
     BAŞINDAKİ emoji ekranda silinir (kalıbın düğme adları ve sırası aynen kalır).
     KORUNAN (kalıbın renk dili, anlam taşır): --yesil doğru · --kirmizi yanlış · --mavi kaynak rakam · --altin bulunan rakam.
     Geri almak: bu bloğu silmek yeter; soru verisi etkilenmez. */
  var st4 = document.createElement('style');
  st4.textContent = [
    ':root[data-theme="dark"]{--bg:#0b0b0d;--bg2:#1f1f22;--kart:#1a1a1d;--cizgi:#2c2c30;--yazi:#f5f5f7;--metin:#f5f5f7;--dim:#98989f;--ustYazi:#111113}',
    ':root{color-scheme:light}:root[data-theme="dark"]{color-scheme:dark}',
    ':root:not([data-theme="dark"]){--bg:#f8fafc;--bg2:#f1f5f9;--kart:#ffffff;--cizgi:#e2e8f0;--yazi:#0f172a;--metin:#0f172a;--dim:#64748b;--ustYazi:#ffffff}',
    'html,body{font-family:-apple-system,"SF Pro Text","Segoe UI",system-ui,Roboto,sans-serif!important}',
    /* düğmeler: yuvarlak hap yerine teknik köşe; ana eylem zıt renk, öğrenme eylemi marka turuncusu */
    '.cip2,.btn{border-radius:8px!important}',
    '.cip2.ana,.btn.ana{background:var(--yazi)!important;color:var(--bg)!important}',
    '.cip2.birincil{background:#f5a524!important;color:#0b0b0c!important}',
    '.sik{border-radius:10px!important}',
    /* emoji yerine başlıklarda küçük turuncu kare (sitenin lambası) */
    '.panel h3:before,.basl:before,.sek:before,.et:before,.hap:before{content:"";display:inline-block;width:6px;height:6px;margin-right:8px;vertical-align:2px;background:#f5a524}',
    '.basl span:before{content:none!important}',
    /* 26.09 (3) tüm uygulama denetimi — soru ekranı */
    '.ustCip.skorCip,.ustCip.kutuCip{display:none!important}',
    '.ilerleme{height:3px!important;border-radius:3px;background:var(--cizgi)!important}',
    '.ilerleme i{background:#f5a524!important;border-radius:3px}',
    '.ttNo{font-weight:700!important;border-radius:999px!important}',
    '.ttBayrak{border-radius:999px!important}',
    '.soru{font-size:1.08em;line-height:1.55!important;letter-spacing:-.003em}',
    '.sik{display:flex!important;align-items:center;gap:12px;min-height:56px;padding:12px 44px 12px 12px!important;box-shadow:0 1px 2px rgba(0,0,0,.04)}',
    '.sik>b{flex:none;width:28px;height:28px;display:grid;place-items:center;margin:0!important;border-radius:8px;border:1px solid var(--cizgi);' +
      'font-size:13px;font-weight:700;color:var(--yazi)!important;background:var(--bg);font-variant-numeric:tabular-nums}',
    '.sik.dogru>b{background:var(--yesil);border-color:var(--yesil);color:#fff!important}',
    '.sik.yanlis>b{background:var(--kirmizi);border-color:var(--kirmizi);color:#fff!important}',
    '.sik.dogru,.sik.yanlis{box-shadow:none}',
    '.konuK{background:var(--bg2)!important;border:0!important;border-radius:12px!important}',
    '.panel .geri{border-radius:12px!important}',
    '.cip2.bDaha{border-style:solid!important}',
    '.btn.mavi,.dugme.ana,#ttListe .tekrar{background:var(--yazi)!important;color:var(--bg)!important;border:0!important;border-radius:10px!important}',
    '#ttListe .ic{border-radius:22px 22px 0 0!important}',
    '#ttListe h3{font-family:-apple-system,\"SF Pro Display\",Inter,\"Segoe UI\",Roboto,system-ui,sans-serif;font-weight:800;letter-spacing:-.03em;font-size:1.6em;margin:4px 0 6px}',
    '#ttListe .izgara button.simdi,#ttListe .izgara button[aria-current]{outline:2px solid #f5a524!important;outline-offset:1px}',
    '.ttAraclar{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px}',
    '.ttAraclar button{display:flex;flex-direction:column;align-items:flex-start;gap:2px;padding:12px;border-radius:12px;border:1px solid var(--cizgi);background:var(--bg);color:var(--yazi);font:inherit;text-align:left}',
    '.ttAraclar b{font-size:.9em}.ttAraclar span{font-size:.82em;color:var(--dim)}',
    /* YÖN 1 · başparmak bölgesi: soru metni üstte, şıklar kartın ALTINA yaslanır (kısa soruda boşluk ortada kalır) */
    '#akis>.kart .govde{display:flex!important;flex-direction:column}',
    /* 27.09 kurumsal keskinlik (uygulama 1.5.3 ile aynı dil): kart 1px çelik çizgi + ince gölge, şık hizalı rakam, basınca mikro tepki */
    ':root:not([data-theme="dark"]) #akis>.kart{border:1px solid var(--cizgi)!important;box-shadow:0 1px 2px rgba(15,23,42,.04),0 4px 16px rgba(15,23,42,.05)!important}',
    ':root:not([data-theme="dark"]) .sik{border:1px solid var(--cizgi)!important;background:#fff}',
    '.soru,.sik{font-variant-numeric:tabular-nums}',
    '.sik{transition:transform .15s cubic-bezier(.2,.9,.3,1.2),border-color .15s}',
    '.sik:active{transform:scale(.98)}',
    /* dönem rozeti: ana sayfadaki frekans rozetiyle aynı — beyaz kapsül, yeşil sinyal noktası */
    '.govde .rozet{display:inline-flex!important;align-self:flex-start;width:fit-content;align-items:center;gap:0;border:1px solid var(--cizgi)!important;background:var(--kart)!important;color:var(--yazi)!important;font-weight:600;border-radius:999px!important}',
    '.govde .rozet:before{width:7px!important;height:7px!important;border-radius:50%;background:#059669!important;vertical-align:0!important}',
    '@media (prefers-reduced-motion:reduce){.sik:active{transform:none}}',
    '#akis>.kart .siklar{margin-top:auto;padding-top:14px}',
    /* açıklama paneli yaylı açılır (yeni sayfa/pencere yok, aynı kartta) */
    '#akis>.kart .panel{transition:transform .46s cubic-bezier(.2,1.12,.3,1),visibility 0s linear .46s!important;border-radius:26px 26px 0 0!important}',
    '#akis>.kart .panel.acik{transition:transform .46s cubic-bezier(.2,1.12,.3,1),visibility 0s!important}',
    '.cip2,.btn{border-radius:999px!important}',
    '.sik{border-radius:16px!important}',
    /* iskelet yükleme (kasa-yukle.js "Sorular yükleniyor" kutusunun yerine) */
    '@keyframes ttNabiz{0%,100%{opacity:.5}50%{opacity:1}}',
    '.ttIskelet{max-width:560px;margin:0 auto;padding:calc(70px + ' + UST + ') 18px 0;display:grid;gap:12px}',
    '.ttIskelet i{display:block;height:16px;border-radius:8px;background:var(--bg2);animation:ttNabiz 1.2s ease-in-out infinite}',
    '.ttIskelet i.s{height:58px;border-radius:16px;margin-top:6px}',
    '.ttIskelet i:nth-child(2){width:86%}.ttIskelet i:nth-child(3){width:64%;margin-bottom:28px}'
  ].join('\n');
  document.head.appendChild(st4);
  var BAS_EMOJI = /^(\s*)(?:[←-⇿⌀-⏿①-➿⤀-⯿]️?\s*|(?:[\uD83C-\uD83E][\uDC00-\uDFFF]|‍|️)+\s*)+/;
  var KORU = /^[▲▼◀▶←-↓]/;   /* ▲ ▼ ◀ ▶ ← ↑ → ↓ yön okları kalır (düğmenin anlamı) */
  function emojiSil(kok) {
    if (!kok || !document.createTreeWalker) return;
    var w = document.createTreeWalker(kok, 4 /* SHOW_TEXT */), d, deg = [];
    while ((d = w.nextNode())) {
      var p = d.parentNode; if (!p || /^(SCRIPT|STYLE|TEXTAREA)$/.test(p.nodeName)) continue;
      var v = d.nodeValue; if (!v || KORU.test(v.replace(/^\s+/, ''))) continue;
      var m = v.match(BAS_EMOJI);
      if (m && m[0].trim()) {
        var y = m[1] + v.slice(m[0].length);
        /* yalnız emojiden oluşan parça: öğede başka yazı varsa silinir ("✅ Doğrusu"), yoksa işarettir, kalır (🏁) */
        if (y.trim() || (p.textContent || '').replace(v, '').trim()) deg.push([d, y]);
      }
    }
    deg.forEach(function (x) { x[0].nodeValue = x[1]; });
  }
  var gorunumIzleyici = null;
  function gorunumKur() {
    emojiSil(document.body);
    if (gorunumIzleyici || !window.MutationObserver) return;
    gorunumIzleyici = new MutationObserver(function (kayit) {
      kayit.forEach(function (k) {
        if (k.type === 'characterData') emojiSil(k.target.parentNode);
        else [].forEach.call(k.addedNodes, function (n) { if (n.nodeType === 1) emojiSil(n); else if (n.nodeType === 3) emojiSil(n.parentNode); });
      });
    });
    gorunumIzleyici.observe(document.body, { childList: true, subtree: true, characterData: true });
  }

  /* ---------- ÜCRETSİZ SORULARDA ÜYELİK KAPISI + ARA KARNE (26.09.2026, Cem "kur") ----------
     Kurgu: 3 soru hesapsız → "ücretsiz üye ol" kapısı (geçilmez) → 30 soru → her 10 soruda ara karne + tam paket.
     Yalnız vitrin (ücretsiz) sayfalarında; tek kart modu (günün sorusu) kapıdan muaf. Giriş durumu ana ekrandan
     (uygulama.js durumBildir → localStorage tt_uyg_girisli). Bu kapı PAZARLAMA kapısıdır, güvenlik değil:
     30 ücretsiz soru zaten açık (sitede de açık); kilitli içerik paket_soru RLS'inde. */
  var VITRIN = /^kaydir\/vitrin\//.test(YOL), HESAPSIZ = 3, ARA = 10;
  var SINAV = /smmm/.test(YOL) ? 'yeterlilik' : 'sgs';
  var ANA = '../../index.html';
  function olay(ad, tek) { if (window.TTOlay) window.TTOlay.say(ad, tek); }
  function girisli() { try { return localStorage.getItem('tt_uyg_girisli') === '1'; } catch (e) { return false; } }
  function sayac() { var r = IL ? IL.dersSonucu(YOL) : { ok: 0, yan: 0 }; return { ok: r.ok, n: r.ok + r.yan }; }
  function cevapliMi(k) { return !!(IL && IL.veri().cevap[sidK(k)]); }
  function simdiki() {
    var a = akis(); if (!a) return null;
    var b = a.getBoundingClientRect(), el = document.elementFromPoint(b.left + b.width / 2, b.top + b.height / 2);
    return el && el.closest ? el.closest('#akis>.kart') : null;
  }
  function paketOzet() { try { return (JSON.parse(localStorage.getItem('tt_uyg_paket_ozet') || '{}') || {})[SINAV] || null; } catch (e) { return null; } }
  var st3 = document.createElement('style');
  st3.textContent = [
    '.ttPerde{position:fixed;inset:0;z-index:2147481500;background:radial-gradient(120% 420px at 50% -60px,rgba(245,165,36,.08),transparent 70%) no-repeat,var(--bg);color:var(--yazi);display:none;flex-direction:column;justify-content:flex-end;' +
      'padding:24px 20px calc(24px + ' + ALT + ');font-family:-apple-system,"Segoe UI",system-ui,Roboto,sans-serif}',
    '.ttPerde.acik{display:flex}',
    '.ttPerde .etk{font-size:12px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:#b86e00;margin-bottom:12px}',
    '.ttPerde .etk i{display:block;height:4px;border-radius:4px;background:var(--bg2);margin-top:10px}',
    '.ttPerde .etk i b{display:block;height:100%;border-radius:4px;background:#f5a524}',
    '.ttPerde h2{font-family:-apple-system,\"SF Pro Display\",Inter,\"Segoe UI\",Roboto,system-ui,sans-serif;font-size:34px;font-weight:800;letter-spacing:-.035em;line-height:1.04;margin:0 0 10px;color:var(--yazi)}',
    '.ttPerde p{color:var(--dim);margin:0 0 20px;line-height:1.5}',
    '.ttPerde .buyuk{font-family:-apple-system,\"SF Pro Display\",Inter,\"Segoe UI\",Roboto,system-ui,sans-serif;font-size:64px;font-weight:700;letter-spacing:-.03em;line-height:1;margin:4px 0 14px;font-variant-numeric:tabular-nums}',
    '.ttPerde .buyuk small{font-size:22px;color:var(--dim);font-family:inherit}',
    '.ttPerde a,.ttPerde button{display:block;width:100%;box-sizing:border-box;text-align:center;text-decoration:none;font:600 15px/1.2 inherit;padding:15px;border-radius:8px;margin-top:10px;cursor:pointer}',
    '.ttPerde .birinci{background:var(--yazi);color:var(--bg);border:0;border-radius:999px!important;font-weight:600}',
    '.ttPerde .ikinci{background:transparent;color:var(--yazi);border:1px solid var(--cizgi);border-radius:999px!important}',
    '.ttPerde .ucuncu{background:none;border:0;color:var(--dim);font-weight:500}'
  ].join('\n');
  document.head.appendChild(st3);
  function perde(id, html) {
    var e = document.getElementById(id);
    if (!e) { e = document.createElement('div'); e.id = id; e.className = 'ttPerde'; e.setAttribute('role', 'dialog'); document.body.appendChild(e); }
    e.innerHTML = html; e.classList.add('acik'); return e;
  }
  function perdeKapat(id) { var e = document.getElementById(id); if (e) e.classList.remove('acik'); }

  /* kapı: hesapsız kişi 3 soruyu çözdüyse, cevaplanmamış karta geldiğinde */
  function kapiDenetle() {
    if (!VITRIN || !IL || kok.hasAttribute('data-tek') || girisli()) { perdeKapat('ttKapi'); return; }
    var n = sayac().n, k = simdiki();
    if (n < HESAPSIZ || !k || cevapliMi(k)) { perdeKapat('ttKapi'); return; }
    var e = document.getElementById('ttKapi');
    if (e && e.classList.contains('acik')) return;
    var top = kartlar().length, kalan = Math.max(top - n, 0), i = kartlar().indexOf(k);
    e = perde('ttKapi', '<div class="etk">' + n + ' / ' + top + ' soru<i><b style="width:' + Math.round(n / top * 100) + '%"></b></i></div>' +
      '<h2>' + (kalan > 0 ? 'Kalan ' + kalan + ' soru ücretsiz' : 'Karnen ve ilerlemen hesabında') + '</h2>' +
      '<p>' + (kalan > 0 ? 'Ücretsiz üye ol: soruların, açıklamaları ve karnen açılsın. ' : 'Devam etmek için giriş yap ya da ücretsiz üye ol. ') +
      'İlerlemen tüm cihazlarında saklanır. Kart bilgisi istenmez.</p>' +
      '<a class="birinci" href="' + ANA + '#uyeol">Ücretsiz üye ol</a>' +
      '<a class="ikinci" href="' + ANA + '#giris">Hesabım var, giriş yap</a>' +
      '<button type="button" class="ucuncu">Çözdüğüm sorulara dön</button>');
    olay('kapi', true);
    [].forEach.call(e.querySelectorAll('a'), function (a) {
      a.addEventListener('click', function () {
        try { sessionStorage.setItem('tt_uyg_donus', YOL + '#s=' + Math.max(i, 0)); sessionStorage.setItem('tt_uyg_sekme', 'hesap'); } catch (x) {}
      });
    });
    e.querySelector('.ucuncu').onclick = function () { perdeKapat('ttKapi'); var a = akis(); if (a) a.scrollTo({ top: 0, behavior: 'smooth' }); };
  }

  /* ara karne: her 10 cevapta bir kez (sayfa başına), sonuncuda tam karne */
  function araKarne(n, ok, top) {
    var anahtar = 'tt_ara_' + YOL, goruldu = [];
    try { goruldu = JSON.parse(localStorage.getItem(anahtar) || '[]'); } catch (e) {}
    if (goruldu.indexOf(n) >= 0) return;
    goruldu.push(n); try { localStorage.setItem(anahtar, JSON.stringify(goruldu)); } catch (e) {}
    var bitti = n >= top, p = paketOzet();
    if (bitti) olay('soru_30', true); else if (n === ARA) olay('soru_10', true);
    olay('ara_karne');
    var e = perde('ttAra', '<div class="etk">' + (bitti ? 'Ücretsiz sorular bitti' : 'Ara karne · ' + n + ' soru') + '</div>' +
      '<div class="buyuk">' + ok + '<small> / ' + n + ' doğru</small></div>' +
      '<h2>' + (bitti ? 'Şimdi tamamına geç' : 'Gerçek sınav bundan çok daha geniş') + '</h2>' +
      '<p>Tam pakette' + (p && p.ders ? ' ' + p.ders + ' dersin tüm soruları;' : ' tüm dersler;') +
      ' ders ders çözme, kısa sınav, en çok çıkanlar ve sınav gibi deneme var.</p>' +
      '<a class="birinci" href="' + ANA + '">Tam paketi incele</a>' +
      (bitti ? '' : '<button type="button" class="ikinci">Ücretsiz sorulara devam et</button>'));
    e.querySelector('a').addEventListener('click', function () {
      olay('tam_paket_bak');
      try { sessionStorage.setItem('tt_uyg_sekme', 'sinav'); sessionStorage.setItem('tt_uyg_sinavgor', JSON.stringify({ g: 'sinav', s: SINAV })); sessionStorage.setItem('tt_uyg_odeme', SINAV); } catch (x) {}
    });
    var d = e.querySelector('.ikinci'); if (d) d.onclick = function () { perdeKapat('ttAra'); };
  }

  function cevapSonrasi() {
    if (!VITRIN || kok.hasAttribute('data-tek')) return;
    var c = sayac(), top = kartlar().length;
    if (c.n === 1) olay('soru_1', true);
    if (c.n === HESAPSIZ) olay('soru_3', true);
    if (girisli() && c.n > 0 && (c.n % ARA === 0 || c.n >= top)) setTimeout(function () { araKarne(c.n, c.ok, top); }, 1600);
  }
  var kapiZam = null;
  function kapiIzle() {
    var a = akis(); if (!a || a.__ttKapi || !VITRIN) return; a.__ttKapi = 1;
    a.addEventListener('scroll', function () { clearTimeout(kapiZam); kapiZam = setTimeout(kapiDenetle, 120); }, { passive: true });
    kapiDenetle();
  }
  function kur() {
    var a = akis(); if (!a) return;
    kartlar().forEach(kartiDuzenle);
    if (!izleyici) { try { izleyici = new MutationObserver(function () { kartlar().forEach(kartiDuzenle); konumKur(); }); izleyici.observe(a, { childList: true }); } catch (e) {} }
    konumKur();
    kapiIzle();
    gorunumKur();
    cipTemizle(a);
    if (!cipIzleyici) { try { cipIzleyici = new MutationObserver(function () { cipTemizle(a); }); cipIzleyici.observe(a, { childList: true, subtree: true }); } catch (e) {} }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { setTimeout(kur, 0); });
  else setTimeout(kur, 0);
  window.addEventListener('load', function () { setTimeout(kur, 60); });
  /* kasa-yukle.js kartları sonradan (kilitli kasadan) kurabilir: kısa süre yeniden dene */
  var deneme = 0, zam = setInterval(function () { kur(); if (++deneme > 20) clearInterval(zam); }, 500);
})();
