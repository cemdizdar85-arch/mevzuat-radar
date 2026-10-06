/* ============================================================================
   NÖBETÇİ OYNATICISI — yanlış cevabın anlatımını "video gibi" oynatır (06.10.2026, Cem: "alt alta değil,
   video kaydı gibi anlatır şekilde yapabilir miyiz" → GM önerisi 1 "oynatıcıyı kur").
   Video DEĞİL: metin sahne sahne açılır, açıklama harf harf yazılır. Bedel 0; soru onarılınca anlatım da kendiliğinden güncel.
   Sıra (her kart): soru → senin şıkkın + tuzak → doğru şık → açıklama cümle cümle (hesap adımları ayrı satır) → kural + dayanak.
   Üstte hikâye çubuğu (kart başına bir dilim), ⏸/▶, ⟨ ⟩, "metin olarak göster". Hareket azaltma tercihi olan cihazda düz metin açılır.

   KULLANIM: NobetciOynatici.kur(kap, kartlar, { son:{metin, dugme, href}, olay:function(ad){}, baslik, alt })
     kartlar: [{ ust, soru, secim, secim_metin, tuzak_ad, tuzak_metin, dogru, dogru_metin, aciklama, kural, dayanak }]
     olay adları: basladi · kart-N · son · paket · metin · durdur
   Renkler yalnız tema jetonu (stil.css). 🚫 GÖRMEZ: anlatımın doğruluğu (o vitrin kalite listesinin işi).
============================================================================ */
(function (kok) {
  'use strict';
  var stilEklendi = false;
  function stil() {
    if (stilEklendi) return; stilEklendi = true;
    var s = document.createElement('style');
    s.textContent =
      '.no-kap{position:relative;background:var(--panel);border:1px solid var(--line);border-radius:16px;padding:14px 16px 16px;margin:0 0 14px;overflow:hidden}' +
      '.no-cubuk{display:flex;gap:4px;margin:0 0 12px}.no-dilim{flex:1;height:4px;border-radius:2px;background:color-mix(in srgb,var(--ink) 14%,transparent);overflow:hidden}' +
      '.no-dilim i{display:block;height:100%;width:0;background:var(--accent);transition:width .4s linear}' +
      '.no-ust{display:flex;align-items:center;justify-content:space-between;gap:8px;margin:0 0 8px;font-size:12px;color:var(--muted)}' +
      '.no-dugmeler{display:flex;gap:6px}.no-dugmeler button{border:1px solid var(--line);background:transparent;color:var(--ink);border-radius:8px;min-width:34px;height:30px;font-size:14px;cursor:pointer}' +
      '.no-dugmeler button:focus-visible{outline:2px solid var(--accent);outline-offset:2px}' +
      '.no-sahne{min-height:260px}.no-soru{margin:0 0 12px;font-size:15px;font-weight:600;color:var(--ink);line-height:1.5}' +
      '.no-blok{padding:10px 12px;border-radius:0 8px 8px 0;margin:0 0 10px;opacity:0;transform:translateY(8px);transition:opacity .45s,transform .45s}' +
      '.no-blok.acik{opacity:1;transform:none}' +
      '.no-sen{border-left:3px solid var(--red);background:color-mix(in srgb,var(--red) 7%,transparent)}.no-sen>b{color:var(--red)}' +
      '.no-dogru{border-left:3px solid var(--green);background:color-mix(in srgb,var(--green) 8%,transparent)}.no-dogru>b{color:var(--green)}' +
      '.no-blok p{margin:6px 0 0;font-size:14px;color:var(--ink);line-height:1.55}.no-adim{display:block;margin:4px 0 0}' +
      '.no-adim.hesap{font-variant-numeric:tabular-nums;font-weight:600}' +
      '.no-kural{margin:0 0 6px;font-size:14px;opacity:0;transition:opacity .45s}.no-dayanak{margin:0;font-size:13px;color:var(--muted);opacity:0;transition:opacity .45s}' +
      '.no-kural.acik,.no-dayanak.acik{opacity:1}' +
      '.no-imlec::after{content:"▍";margin-left:1px;color:var(--muted);animation:noYan 1s steps(1) infinite}@keyframes noYan{50%{opacity:0}}' +
      '.no-nobetci{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;color:var(--ink)}' +
      '.no-son{text-align:center;padding:30px 8px}.no-son p{margin:0 0 14px;font-size:16px;color:var(--ink)}' +
      '.no-alt{display:flex;justify-content:space-between;align-items:center;margin-top:10px;font-size:13px}' +
      '.no-alt button{background:none;border:0;color:var(--muted);text-decoration:underline;cursor:pointer;font-size:13px;padding:4px 0}' +
      '@media (prefers-reduced-motion:reduce){.no-blok,.no-kural,.no-dayanak{transition:none}.no-imlec::after{animation:none}}';
    document.head.appendChild(s);
  }
  var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  /* açıklama → adımlar: cümle sonunda böl; sayı + işlem (=, ÷, ×, +, -, %) taşıyan cümle "hesap" adımı. Ondalık/binlik noktası bölünmez. */
  function adimlar(t) {
    var p = String(t || '').replace(/\s+/g, ' ').trim().split(/(?<=[.!?;])\s+(?=[A-ZÇĞİÖŞÜ(0-9])/);
    return p.filter(Boolean).map(function (x) { return { t: x, hesap: /\d/.test(x) && /[=÷×*\/]|\d\s*[-+]\s*\d/.test(x) }; });
  }
  function hareketAz() { try { return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches; } catch (e) { return false; } }

  function kur(kap, kartlar, o) {
    o = o || {}; stil();
    var olay = function (ad) { try { o.olay && o.olay(ad); } catch (e) {} };
    var duz = hareketAz(), i = 0, adim = 0, plan = [], zaman = null, dur = false, yazilan = null, bitti = {};
    kap.innerHTML = (o.baslik ? '<h2 style="margin:0 0 6px">' + esc(o.baslik) + '</h2>' : '') + (o.alt ? '<p class="sv-alt" style="margin:0 0 14px">' + o.alt + '</p>' : '') +
      '<div class="no-kap" role="region" aria-label="Nöbetçi anlatımı"><div class="no-cubuk">' + kartlar.map(function () { return '<span class="no-dilim"><i></i></span>'; }).join('') + '</div>' +
      '<div class="no-ust"><span class="no-nobetci">🛡️ Nöbetçi anlatıyor <span class="no-sayac"></span></span><span class="no-dugmeler">' +
      '<button type="button" data-d="geri" aria-label="Önceki yanlış">⟨</button><button type="button" data-d="oyna" aria-label="Durdur">⏸</button><button type="button" data-d="ileri" aria-label="Sonraki yanlış">⟩</button></span></div>' +
      '<div class="no-sahne" aria-live="polite"></div><div class="no-alt"><span></span><button type="button" data-d="metin">Hepsini metin olarak göster</button></div></div>';
    var sahne = kap.querySelector('.no-sahne'), dilim = kap.querySelectorAll('.no-dilim i'), oynaD = kap.querySelector('[data-d="oyna"]');
    function temizle() { if (zaman) { clearTimeout(zaman); zaman = null; } }
    function kartHtml(k) {
      var ad = adimlar(k.aciklama);
      return '<p class="no-soru-ust" style="margin:0 0 6px;font-size:12px;color:var(--muted)">' + esc(k.ust || '') + '</p>' +
        (k.soru ? '<p class="no-soru">' + esc(k.soru) + '</p>' : '') +
        '<div class="no-blok no-sen" data-a="sen">' + (k.secim ? '<b>Senin cevabın ' + esc(k.secim) + ') ' + esc(k.secim_metin || '') + '</b><p><b style="color:var(--ink)">' + esc(k.tuzak_ad || 'Tuzak') + ':</b> <span data-yaz="' + esc(k.tuzak_metin || '') + '"></span></p>'
          : '<b>Bu soruyu boş geçtin</b><p><span data-yaz="Doğrusunu ve nedenini birlikte görelim."></span></p>') + '</div>' +
        '<div class="no-blok no-dogru" data-a="dogru"><b>Doğrusu ' + esc(k.dogru) + ') ' + esc(k.dogru_metin || '') + '</b><p>' +
        ad.map(function (x) { return '<span class="no-adim' + (x.hesap ? ' hesap' : '') + '" data-yaz="' + esc(x.t) + '"></span>'; }).join('') + '</p></div>' +
        (k.kural ? '<p class="no-kural" data-a="kural"><b>Kural:</b> ' + esc(k.kural) + '</p>' : '') +
        (k.dayanak ? '<p class="no-dayanak" data-a="dayanak">📜 Dayanak: ' + esc(k.dayanak) + '</p>' : '');
    }
    /* adım planı: [tür, öğe, süre] - "ac" bloğu görünür yapar, "yaz" metni harf harf yazar (saniyede ~40 harf), "bekle" durur */
    function planKur() {
      var p = [], q = sahne.querySelector('.no-soru');
      p.push(['bekle', null, q ? Math.min(4500, 1200 + q.textContent.length * 15) : 800]);
      var sen = sahne.querySelector('[data-a="sen"]'); p.push(['ac', sen, 500]);
      sen.querySelectorAll('[data-yaz]').forEach(function (e) { p.push(['yaz', e]); }); p.push(['bekle', null, 1400]);
      var dg = sahne.querySelector('[data-a="dogru"]'); p.push(['ac', dg, 700]);
      dg.querySelectorAll('[data-yaz]').forEach(function (e) { p.push(['yaz', e]); p.push(['bekle', null, e.classList.contains('hesap') ? 1100 : 500]); });
      ['kural', 'dayanak'].forEach(function (a) { var e = sahne.querySelector('[data-a="' + a + '"]'); if (e) p.push(['ac', e, a === 'kural' ? 1600 : 900]); });
      p.push(['bekle', null, 2600]);
      return p;
    }
    function hepsiniAc() {
      sahne.querySelectorAll('.no-blok,.no-kural,.no-dayanak').forEach(function (e) { e.classList.add('acik'); });
      sahne.querySelectorAll('[data-yaz]').forEach(function (e) { e.textContent = e.getAttribute('data-yaz'); e.classList.remove('no-imlec'); });
    }
    function cubuk() { for (var j = 0; j < dilim.length; j++) dilim[j].style.width = j < i ? '100%' : j > i ? '0' : Math.round(100 * adim / Math.max(1, plan.length)) + '%'; }
    function kartAc(n) {
      temizle(); i = n; adim = 0; yazilan = null;
      if (i >= kartlar.length) return sonEkran();
      sahne.innerHTML = kartHtml(kartlar[i]); kap.querySelector('.no-sayac').textContent = '· ' + (i + 1) + ' / ' + kartlar.length;
      plan = planKur(); cubuk();
      if (duz || dur) { if (duz) { hepsiniAc(); adim = plan.length; cubuk(); } return; }
      ilerle();
    }
    function ilerle() {
      temizle(); if (dur) return;
      if (adim >= plan.length) { if (!bitti[i]) { bitti[i] = 1; olay('kart-' + (i + 1)); } return kartAc(i + 1); }
      var a = plan[adim];
      if (a[0] === 'yaz') {
        var e = a[1], tam = e.getAttribute('data-yaz'), n = yazilan && yazilan.e === e ? yazilan.n : 0; e.classList.add('no-imlec');
        (function harf() {
          if (dur) { yazilan = { e: e, n: n }; return; }
          n = Math.min(tam.length, n + 2); e.textContent = tam.slice(0, n);
          if (n < tam.length) { zaman = setTimeout(harf, 45); return; }
          e.classList.remove('no-imlec'); yazilan = null; adim++; cubuk(); zaman = setTimeout(ilerle, 250);
        })();
        return;
      }
      if (a[0] === 'ac') a[1].classList.add('acik');
      adim++; cubuk(); zaman = setTimeout(ilerle, a[2] || 400);
    }
    function sonEkran() {
      temizle(); i = kartlar.length; cubuk(); for (var j = 0; j < dilim.length; j++) dilim[j].style.width = '100%';
      kap.querySelector('.no-sayac').textContent = '';
      var s = o.son || {};
      sahne.innerHTML = '<div class="no-son"><p>' + (s.metin || 'Bankadaki her soru böyle anlatılır.') + '</p>' +
        (s.href ? '<a class="sv-btn ana" data-d="paket" style="text-decoration:none;display:inline-block" href="' + esc(s.href) + '">' + esc(s.dugme || 'Tam bankayı aç →') + '</a>' : '') +
        '<div style="margin-top:12px"><button type="button" data-d="bastan" style="background:none;border:0;color:var(--muted);text-decoration:underline;cursor:pointer">Baştan izle</button></div></div>';
      if (!bitti.son) { bitti.son = 1; olay('son'); }
    }
    function oynaDurdur(d) { dur = d; oynaD.textContent = dur ? '▶' : '⏸'; oynaD.setAttribute('aria-label', dur ? 'Oynat' : 'Durdur'); if (dur) { temizle(); olay('durdur'); } else if (i < kartlar.length) ilerle(); }
    kap.addEventListener('click', function (ev) {
      var b = ev.target.closest('[data-d]'); if (!b) return; var d = b.getAttribute('data-d');
      if (d === 'oyna') { if (duz) { duz = false; dur = false; kartAc(i); oynaD.textContent = '⏸'; } else oynaDurdur(!dur); }
      else if (d === 'ileri') kartAc(Math.min(kartlar.length, i + 1));
      else if (d === 'geri') kartAc(Math.max(0, i - (i >= kartlar.length ? 1 : (adim > 2 ? 0 : 1))));
      else if (d === 'bastan') { duz = false; oynaDurdur(false); kartAc(0); }
      else if (d === 'paket') olay('paket');
      else if (d === 'metin') { olay('metin'); temizle(); duz = true; oynaD.textContent = '▶'; metinGorunum(); }
    });
    function metinGorunum() {
      var h = ''; kartlar.forEach(function (k) { h += '<div style="border-top:1px solid var(--line);padding-top:12px;margin-top:12px">' + kartHtml(k) + '</div>'; });
      sahne.innerHTML = h; hepsiniAc(); kap.querySelector('.no-sayac').textContent = ''; for (var j = 0; j < dilim.length; j++) dilim[j].style.width = '100%';
      var s = o.son || {}; if (s.href) sahne.insertAdjacentHTML('beforeend', '<div class="no-son" style="padding:16px 0 4px"><p>' + (s.metin || '') + '</p><a class="sv-btn ana" data-d="paket" style="text-decoration:none;display:inline-block" href="' + esc(s.href) + '">' + esc(s.dugme || 'Tam bankayı aç →') + '</a></div>');
    }
    /* görünür olunca başlar (sayfanın altında kalmışsa boşa oynamasın) */
    var basladi = false;
    function basla() { if (basladi) return; basladi = true; olay('basladi'); kartAc(0); }
    if (duz) { oynaD.textContent = '▶'; metinGorunum(); olay('metin-varsayilan'); return; }
    if ('IntersectionObserver' in window) { var g = new IntersectionObserver(function (x) { if (x[0].isIntersecting) { g.disconnect(); basla(); } }, { threshold: 0.35 }); g.observe(kap); }
    else basla();
  }
  kok.NobetciOynatici = { kur: kur, _adimlar: adimlar };
  if (typeof module !== 'undefined' && module.exports) module.exports = { _adimlar: adimlar };
})(typeof window !== 'undefined' ? window : this);
