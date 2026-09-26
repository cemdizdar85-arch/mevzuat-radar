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

  /* 5) Tema: sayfanın kendi tema betiği (kc_tema) bu dosyadan SONRA çalışır; telefonun ayarını ona yazarız. */
  try {
    var koyu = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    localStorage.setItem('kc_tema', koyu ? 'dark' : 'light');
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
    '.ttBayrak{font:inherit;font-size:.95em;line-height:1;background:var(--kart);border:1px solid var(--cizgi);border-radius:14px;padding:3px 7px;cursor:pointer;opacity:.75}',
    '.ttBayrak.acik{opacity:1;border-color:var(--altin,#f5a524);background:color-mix(in srgb,var(--altin,#f5a524) 22%,var(--kart))}',
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
    '#ttListe .izgara button.bay:after{content:"🔖";position:absolute;top:-6px;right:-4px;font-size:12px}',
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
        '<p>Yeşil doğru, kırmızı yanlış, 🔖 işaretlediklerin. Bir soruya dokun, oraya git.</p>' +
        '<div class="sekmeler"><button type="button" data-s="tum">Tümü</button><button type="button" data-s="yan">Yanlışlar</button><button type="button" data-s="bay">İşaretliler</button></div>' +
        '<div class="izgara"></div>' +
        '<button type="button" class="dugme ana tekrar" style="width:100%;margin-top:14px">↻ Yanlışlarımı tekrar çöz</button>' +
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
      });
    }
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
      var bay = IL && IL.veri().bayrak[sidK(k)]; if (bay) b.classList.add('bay');
      if (k === su) b.classList.add('simdi');
      var goster = listeSuzgec === 'tum' || (listeSuzgec === 'yan' && d === 'yan') || (listeSuzgec === 'bay' && bay);
      if (!goster || k.classList.contains('ttDisarda')) b.classList.add('gizli'); else gosterilen++;
      b.addEventListener('click', function () { l.classList.remove('acik'); k.scrollIntoView({ behavior: 'smooth' }); });
      iz.appendChild(b);
    });
    if (!gosterilen) { var bos = document.createElement('div'); bos.className = 'bos'; bos.textContent = listeSuzgec === 'bay' ? 'Henüz işaretlediğin soru yok. Sorunun üstündeki 🔖 ile işaretle.' : 'Bu listede soru yok.'; iz.appendChild(bos); }
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
      e.innerHTML = '<div class="ic"><h3 style="margin:0 0 8px">📝 Bu soruya notun</h3><textarea maxlength="2000" placeholder="Kendi cümlenle kural, tuzak, hatırlatma…"></textarea>' +
        '<div class="satir"><button type="button" class="vaz">Vazgeç</button><button type="button" class="ana kay">Kaydet</button></div></div>';
      document.body.appendChild(e);
      e.addEventListener('click', function (ev) { if (ev.target === e || ev.target.classList.contains('vaz')) e.classList.remove('acik'); });
    }
    var ta = e.querySelector('textarea'), n = IL && IL.veri().not[sidK(k)];
    ta.value = n ? n.m : '';
    e.querySelector('.kay').onclick = function () { if (IL) IL.notYaz(sidK(k), ta.value, YOL, kartlar().indexOf(k)); e.classList.remove('acik'); notCiz(k); };
    e.classList.add('acik'); setTimeout(function () { ta.focus(); }, 50);
  }
  function notCiz(k) {
    var p = k.querySelector('.panel'); if (!p) return;
    var kutu = p.querySelector('.ttNotKutu'), n = IL && IL.veri().not[sidK(k)];
    if (!n) { if (kutu) kutu.remove(); return; }
    if (!kutu) { kutu = document.createElement('div'); kutu.className = 'ttNotKutu'; var bar = p.querySelector('.ttPanelBar'); p.insertBefore(kutu, bar ? bar.nextSibling : p.firstChild); }
    kutu.textContent = '📝 Notun: ' + n.m;
  }

  /* her karta bir kez: "i / N" düğmesi, 🔖 bayrak, açıklama kartına küçült/aç + 📝 not, cevap kaydı */
  function kartiDuzenle(k) {
    if (k.__tt) return; k.__tt = 1;
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
        var bay = document.createElement('button'); bay.type = 'button'; bay.className = 'ttBayrak'; bay.textContent = '🔖';
        bay.setAttribute('aria-label', 'Soruyu işaretle');
        bay.classList.toggle('acik', !!IL.veri().bayrak[sidK(k)]);
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
      if (IL) { var nb = document.createElement('button'); nb.type = 'button'; nb.textContent = '📝 Not'; nb.addEventListener('click', function (e) { e.stopPropagation(); notAc(k); }); bar.appendChild(nb); }
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
          IL.cevapla(sidK(k), s.classList.contains('dogru'), YOL);
          var g = IL.veri().gun[IL.bugun()] || 0, h = IL.veri().ayar.hedef || 10;
          if (g === h) serit('🎯 Günlük hedef tamam: ' + h + ' soru. Seri ' + IL.seri() + ' gün 🔥', null, null, 3500);
        }, 0);
      });
    });
  }

  /* kaldığın yerden devam: kaydırmada konum yazılır; açılışta (derin bağlantı yoksa) o karta gidilir */
  var konumKuruldu = false, izleyici = null, konumZam = null;
  function konumKur() {
    if (konumKuruldu || !IL || !YOL) return;
    var a = akis(), ks = kartlar(); if (!a || !ks.length) return;
    konumKuruldu = true;
    var tekrarda = tekrarKur();
    a.addEventListener('scroll', function () {
      clearTimeout(konumZam);
      konumZam = setTimeout(function () { var k = simdikiKart(); if (k && !tekrarda) IL.konumYaz(YOL, kartlar().indexOf(k)); }, 400);
    }, { passive: true });
    if (tekrarda || /#s=\d+/.test(location.hash)) return;
    var i = IL.veri().konum[YOL] || 0;
    if (i > 0 && ks[i]) {
      setTimeout(function () { a.style.scrollBehavior = 'auto'; ks[i].scrollIntoView(); a.style.scrollBehavior = ''; }, 50);
      serit('Kaldığın yerden: ' + (i + 1) + '. soru', 'Baştan', function () { a.scrollTo({ top: 0, behavior: 'smooth' }); }, 6000);
    } else IL.konumYaz(YOL, 0);
  }

  function kur() {
    var a = akis(); if (!a) return;
    kartlar().forEach(kartiDuzenle);
    if (!izleyici) { try { izleyici = new MutationObserver(function () { kartlar().forEach(kartiDuzenle); konumKur(); }); izleyici.observe(a, { childList: true }); } catch (e) {} }
    konumKur();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { setTimeout(kur, 0); });
  else setTimeout(kur, 0);
  window.addEventListener('load', function () { setTimeout(kur, 60); });
  /* kasa-yukle.js kartları sonradan (kilitli kasadan) kurabilir: kısa süre yeniden dene */
  var deneme = 0, zam = setInterval(function () { kur(); if (++deneme > 20) clearInterval(zam); }, 500);
})();
