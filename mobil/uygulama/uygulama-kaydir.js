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
    '#akis .ust .seviye{flex:0 0 auto;white-space:nowrap}',
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

  function akis() { return document.getElementById('akis'); }
  function kartlar() { var a = akis(); return a ? [].slice.call(a.children).filter(function (k) { return k.classList.contains('kart') && k.querySelector('.sik'); }) : []; }
  function simdikiNo() { var a = akis(); return a && a.clientHeight ? Math.round(a.scrollTop / a.clientHeight) : 0; }

  /* numaralı soru listesi: renkler sayfanın kendi ilerleme noktalarından (.noktalar i.ok / .yan) okunur */
  function listeAc() {
    var l = document.getElementById('ttListe');
    if (!l) {
      l = document.createElement('div'); l.id = 'ttListe';
      l.innerHTML = '<div class="ic" role="dialog" aria-label="Soru listesi"><h3>Sorular</h3>' +
        '<p>Yeşil doğru, kırmızı yanlış cevapladıkların. Bir soruya dokun, oraya git.</p>' +
        '<div class="izgara"></div><button type="button" class="kapat">Kapat</button></div>';
      document.body.appendChild(l);
      l.addEventListener('click', function (e) { if (e.target === l || e.target.classList.contains('kapat')) l.classList.remove('acik'); });
    }
    var ks = kartlar(), sn = simdikiNo(), nok = document.querySelector('#akis .noktalar');
    var iz = l.querySelector('.izgara'); iz.innerHTML = '';
    ks.forEach(function (k, j) {
      var b = document.createElement('button'); b.type = 'button'; b.textContent = j + 1;
      var n = nok && nok.querySelector('i[data-j="' + j + '"]');
      if (n && n.classList.contains('ok')) b.className = 'ok';
      else if (n && n.classList.contains('yan')) b.className = 'yan';
      if (j === sn) b.classList.add('simdi');
      b.addEventListener('click', function () { l.classList.remove('acik'); k.scrollIntoView({ behavior: 'smooth' }); });
      iz.appendChild(b);
    });
    l.classList.add('acik');
  }

  /* her karta bir kez: "i / N" yazısını dokunulur düğmeye çevir, açıklama kartına küçült/aç çubuğu ekle */
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
    }
    var p = k.querySelector('.panel');
    if (p && !p.querySelector('.ttPanelBar')) {
      var bar = document.createElement('div'); bar.className = 'ttPanelBar';
      var dg = document.createElement('button'); dg.type = 'button'; dg.textContent = '▼ Soruyu gör';
      bar.appendChild(dg); p.insertBefore(bar, p.firstChild);
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
  }

  function kur() {
    var a = akis(); if (!a) return;
    kartlar().forEach(kartiDuzenle);
    try { new MutationObserver(function () { kartlar().forEach(kartiDuzenle); }).observe(a, { childList: true }); } catch (e) {}
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { setTimeout(kur, 0); });
  else setTimeout(kur, 0);
  /* kasa-yukle.js kartları sonradan (kilitli kasadan) kurabilir: kısa süre yeniden dene */
  var deneme = 0, zam = setInterval(function () { kur(); if (++deneme > 20) clearInterval(zam); }, 500);
})();
