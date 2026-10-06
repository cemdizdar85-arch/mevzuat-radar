/* ============================================================================
   NÖBETÇİ OYNATICISI — yanlış cevabın anlatımını "video gibi" oynatır (06.10.2026, Cem: "alt alta değil,
   video kaydı gibi anlatır şekilde yapabilir miyiz" → GM önerisi 1 "oynatıcıyı kur").
   Video DEĞİL: metin sahne sahne açılır, açıklama harf harf yazılır. Bedel 0; soru onarılınca anlatım da kendiliğinden güncel.
   Sıra (her kart): soru → senin şıkkın + tuzak → doğru şık → açıklama cümle cümle (hesap adımları ayrı satır) → kural + dayanak.
   Üstte hikâye çubuğu (kart başına bir dilim), ⏸/▶, ⟨ ⟩, "metin olarak göster". Hareket azaltma tercihi olan cihazda düz metin açılır.

   KULLANIM: NobetciOynatici.kur(kap, kartlar, { son:{metin, dugme, href, sinif}, olay:function(ad){}, baslik, alt })
     kartlar: [{ ust, soru, tuzaklar ({harf:{ad,metin}} - o.etkilesim ile 'Sen çöz' aşaması açılır), siklar ({A..E}, varsa önce şıklar görünür, sonra işaretlenir), secim, sen_etiket (vars. "Senin cevabın"), secim_metin, tuzak_ad, tuzak_metin, dogru, dogru_metin, aciklama, kural, dayanak }]
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
      /* 06.10 Cem (telefon): "bir alta kayarak oynatıyor, aynı yerde oynaması lazım" - sahne SABİT boy, içerik içinde akar (takip) */
      '.no-sahne{position:relative;height:clamp(320px,60vh,460px);overflow-y:auto;overscroll-behavior:contain;scrollbar-width:none}.no-sahne::-webkit-scrollbar{display:none}.no-sahne.duz{height:auto;overflow:visible}' +
      /* 07.10 Cem ('soru bilgisayarda yarım görünüyor'): seçim aşamasında çerçeve sorunun tamamını gösterir; anlatım başlayınca sabit boya döner */
      '.no-sahne.secimde{height:auto!important;overflow:visible!important}' +
      /* 07.10 Cem "bu kadar boşluk": açılmamış blok yer KAPLAMAZ (önce yalnız saydamdı, kartın altında boşluk kalıyordu); açılınca kısa geçişle gelir */
      '.no-blok:not(.acik),.no-kural:not(.acik),.no-dayanak:not(.acik){display:none}@keyframes noAc{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}.no-blok.acik,.no-kural.acik,.no-dayanak.acik{animation:noAc .45s}' +
      '.no-soru{margin:0 0 12px;font-size:15px;font-weight:600;color:var(--ink);line-height:1.5}' +
      '.no-siklar{list-style:none;margin:0 0 12px;padding:0;display:grid;gap:6px}.no-siklar li{display:flex;gap:8px;align-items:flex-start;padding:7px 10px;border:1px solid var(--line);border-radius:8px;font-size:13.5px;line-height:1.45;color:var(--ink);transition:background .6s,border-color .6s}' +
      '.no-siklar.secilir li{cursor:pointer}.no-siklar.secilir li:hover{border-color:var(--ink)}.no-siklar.secilir li:focus-visible{outline:2px solid var(--accent);outline-offset:1px}' +
      '.no-davet{margin:0 0 8px;font-size:14px;font-weight:700;color:var(--amber,var(--ink))}.no-davet small{font-weight:500;color:var(--muted)}' +
      '.no-bekle{display:block;margin:8px 0 0;padding:6px 12px;border:1px solid var(--line);border-radius:999px;background:var(--panel,var(--bg));color:var(--ink);font:inherit;font-size:13px;font-weight:600;cursor:pointer}.no-bekle:hover{border-color:var(--amber,var(--ink))}' +
      '.no-siklar li b{flex:none}.no-siklar li em{margin-left:auto;padding-left:8px;flex:none;font-style:normal;font-size:12px;font-weight:800;white-space:nowrap}' +
      '.no-siklar li.sen{border-color:var(--red);background:color-mix(in srgb,var(--red) 8%,transparent)}.no-siklar li.sen em{color:var(--red)}' +
      '.no-siklar li.dogru{border-color:var(--green);background:color-mix(in srgb,var(--green) 9%,transparent)}.no-siklar li.dogru em{color:var(--green)}' +
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
    var ilkKartlar = kartlar.slice();
    var duz = hareketAz(), i = 0, adim = 0, plan = [], zaman = null, dur = false, yazilan = null, bitti = {};
    kap.innerHTML = (o.baslik ? '<h2 style="margin:0 0 6px">' + esc(o.baslik) + '</h2>' : '') + (o.alt ? '<p class="sv-alt" style="margin:0 0 14px">' + o.alt + '</p>' : '') +
      '<div class="no-kap" role="region" aria-label="Nöbetçi anlatımı"><div class="no-cubuk">' + kartlar.map(function () { return '<span class="no-dilim"><i></i></span>'; }).join('') + '</div>' +
      '<div class="no-ust"><span class="no-nobetci">🛡️ Nöbetçi anlatıyor <span class="no-sayac"></span></span><span class="no-dugmeler">' +
      '<button type="button" data-d="geri" aria-label="Önceki yanlış">⟨</button><button type="button" data-d="oyna" aria-label="Durdur">⏸</button><button type="button" data-d="ileri" aria-label="Sonraki yanlış">⟩</button></span></div>' +
      '<div class="no-sahne" aria-live="polite"></div><div class="no-alt"><span></span><button type="button" data-d="metin">Hepsini metin olarak göster</button></div></div>';
    var sahne = kap.querySelector('.no-sahne'), dilim = kap.querySelectorAll('.no-dilim i'), oynaD = kap.querySelector('[data-d="oyna"]');
    /* 06.10 Cem ("biraz yavaş kaysın"): sahnenin içi kendi animasyonuyla, ağır kayar (tarayıcının hızlı smooth'u değil) */
    /* 07.10 Cem ("yazarken alt kırılımda kalıyor, görünmüyor"): her harfte animasyonu BAŞTAN başlatıyordu (38 ms'de kesilip
       neredeyse hiç kaymıyordu). Artık tek, sürekli bir takip: hedef ilerledikçe çerçeve yumuşakça peşinden iner (kare başına
       kalan mesafenin %7'si, en az 1 px), kendini yeniden başlatmaz. */
    var kayHedef = 0, kayCalisiyor = false, kayAnim = 0;
    function kaydir(hedef) {
      kayHedef = Math.max(kayHedef, Math.min(hedef, sahne.scrollHeight - sahne.clientHeight));
      clearTimeout(kaydir.emniyet); kaydir.emniyet = setTimeout(function () { if (sahne.scrollTop < kayHedef - 1) sahne.scrollTop = kayHedef; }, 1400);   // animasyon karesi gelmese de hedefe varır
      if (kayCalisiyor) return; kayCalisiyor = true; var id = kayAnim;
      (function adimKay() { if (id !== kayAnim) { kayCalisiyor = false; return; }
        var d = kayHedef - sahne.scrollTop; if (Math.abs(d) < 1) { kayCalisiyor = false; return; }
        sahne.scrollTop += (d > 0 ? 1 : -1) * Math.max(1, Math.abs(d) * 0.07); requestAnimationFrame(adimKay); })();
    }
    function takip(e, blok) {
      if (duz || !e) return;
      var r = e.getBoundingClientRect(), s = sahne.getBoundingClientRect(), fark = r.bottom - s.bottom + 14;
      if (blok) fark = Math.min(fark, r.top - s.top - 8);   // blok açılınca üst kenarı sahnenin üstünden kaçmasın
      if (fark <= 0) return;
      if (blok) kaydir(sahne.scrollTop + fark);                    // blok açılışı: yumuşak iniş
      else { sahne.scrollTop += fark; kayHedef = Math.max(kayHedef, sahne.scrollTop); }   // yazarken: yeni satır başlarken çerçeve o satır kadar iner (gecikme yok)
    }
    function temizle() { if (zaman) { clearTimeout(zaman); zaman = null; } if (geriSay) { clearInterval(geriSay); geriSay = null; } }
    function kartHtml(k) {
      var ad = adimlar(k.aciklama);
      return '<p class="no-soru-ust" style="margin:0 0 6px;font-size:12px;color:var(--muted)">' + esc(k.ust || '') + '</p>' +
        (k.soru ? '<p class="no-soru">' + esc(k.soru) + '</p>' : '') +
        (secimVar(k) ? '<p class="no-davet">Sen olsan hangisini işaretlerdin? <small class="no-geri">Bir şıkka dokun.</small> <button type="button" class="no-bekle" data-d="bekle">Süreyi durdur, kendim çözeyim</button></p>' : '') +
        (k.siklar ? '<ol class="no-siklar' + (secimVar(k) ? ' secilir' : '') + '">' + Object.keys(k.siklar).sort().map(function (hf) { return '<li data-h="' + esc(hf) + '"' + (secimVar(k) ? ' tabindex="0" role="button"' : '') + '><b>' + esc(hf) + ')</b><span>' + esc(k.siklar[hf]) + '</span><em></em></li>'; }).join('') + '</ol>' : '') +
        '<div class="no-blok no-sen" data-a="sen">' + (k.secim ? '<b>' + esc(k.sen_etiket || 'Senin cevabın') + ' ' + esc(k.secim) + ')' + (k.siklar ? '' : ' ' + esc(k.secim_metin || '')) + '</b><p><b style="color:var(--ink)">' + esc(k.tuzak_ad || 'Tuzak') + ':</b> <span data-yaz="' + esc(k.tuzak_metin || '') + '"></span></p>'
          : '<b>Bu soruyu boş geçtin</b><p><span data-yaz="Doğrusunu ve nedenini birlikte görelim."></span></p>') + '</div>' +
        '<div class="no-blok no-dogru" data-a="dogru"><b>Doğrusu ' + esc(k.dogru) + ')' + (k.siklar ? '' : ' ' + esc(k.dogru_metin || '')) + '</b><p>' +
        ad.map(function (x) { return '<span class="no-adim' + (x.hesap ? ' hesap' : '') + '" data-yaz="' + esc(x.t) + '"></span>'; }).join('') + '</p></div>' +
        (k.kural ? '<p class="no-kural" data-a="kural"><b>Kural:</b> ' + esc(k.kural) + '</p>' : '') +
        (k.dayanak ? '<p class="no-dayanak" data-a="dayanak">📜 Dayanak: ' + esc(k.dayanak) + '</p>' : '');
    }
    /* adım planı: [tür, öğe, süre] - "ac" bloğu görünür yapar, "yaz" metni harf harf yazar (saniyede ~40 harf), "bekle" durur */
    function planKur() {
      var p = [], q = sahne.querySelector('.no-soru'), sl = sahne.querySelector('.no-siklar'), k = kartlar[i] || {};
      var okun = (q ? q.textContent.length : 0) + (sl ? sl.textContent.length : 0);
      var okuma = okun ? Math.min(sl ? 10000 : 4500, (sl ? 1800 : 1200) + okun * (sl ? 12 : 15)) : 800;
      if (secimVar(k)) p.push(['secim', null, Math.max(okuma, o.etkilesim || 12000)]);
      else if (!k.secilen) p.push(['bekle', null, okuma]);
      else p.push(['bekle', null, 600]);
      if (sl && k.secilen && k.secilen === k.dogru) p.push(['isaret', sl.querySelector('[data-h="' + k.dogru + '"]'), 1400, 'dogru']);   // doğruyu bilen anında görsün
      if (sl && k.secim) p.push(['isaret', sl.querySelector('[data-h="' + k.secim + '"]'), 1700, 'sen']);
      var sen = sahne.querySelector('[data-a="sen"]'); p.push(['ac', sen, 600]);
      sen.querySelectorAll('[data-yaz]').forEach(function (e) { p.push(['yaz', e]); }); p.push(['bekle', null, 1800]);
      if (sl) p.push(['isaret', sl.querySelector('[data-h="' + k.dogru + '"]'), 1500, 'dogru']);
      var dg = sahne.querySelector('[data-a="dogru"]'); p.push(['ac', dg, 700]);
      dg.querySelectorAll('[data-yaz]').forEach(function (e) { p.push(['yaz', e]); p.push(['bekle', null, e.classList.contains('hesap') ? 1100 : 500]); });
      ['kural', 'dayanak'].forEach(function (a) { var e = sahne.querySelector('[data-a="' + a + '"]'); if (e) p.push(['ac', e, a === 'kural' ? 1600 : 900]); });
      p.push(['bekle', null, 3500]);
      return p;
    }
    function isaretle(li, tur) { if (!li) return; li.classList.add(tur); var em = li.querySelector('em'), k0 = kartlar[i] || {}, bu = li.getAttribute('data-h') === k0.secilen;
      if (em) em.textContent = tur === 'dogru' ? (bu ? 'Doğru ✓ senin cevabın' : 'Doğru ✓') : (bu || (!k0.secilen && !k0.sen_etiket) ? 'Senin cevabın ✕' : 'En sık yanlış ✕'); }
    /* seçim aşaması: kartın tüm tuzakları varsa ve henüz seçilmediyse */
    function secimVar(k) { return !!(o.etkilesim && k && k.siklar && k.tuzaklar && !k.secilen && !k.secimBitti && !duz); }
    var geriSay = null;
    function sec(harf) {
      var k = kartlar[i]; if (!secimVar(k) || !k.siklar[harf]) return;
      var n = Object.assign({}, k, { secilen: harf });
      if (harf === k.dogru) { n.sen_etiket = 'Doğru bildin! Çoğu aday burada şuna düşüyor:'; olay('secti-dogru'); }
      else { var t = k.tuzaklar[harf] || {}; n.secim = harf; n.sen_etiket = 'Senin cevabın'; n.tuzak_ad = t.ad || ''; n.tuzak_metin = t.metin || 'Bu şık doğru değil; doğru cevabın hesabı aşağıda adım adım.'; olay('secti-yanlis'); }
      kartlar[i] = n; if (!basladi) { basladi = true; olay('basladi'); } oto = false; if (dur) { dur = false; oynaD.textContent = '⏸'; } kartAc(i);
    }
    function hepsiniAc() {
      var k0 = kartlar[i] || {}; sahne.querySelectorAll('.no-siklar').forEach(function (l) { if (k0.secim) isaretle(l.querySelector('[data-h="' + k0.secim + '"]'), 'sen'); isaretle(l.querySelector('[data-h="' + k0.dogru + '"]'), 'dogru'); });
      sahne.querySelectorAll('.no-blok,.no-kural,.no-dayanak').forEach(function (e) { e.classList.add('acik'); });
      sahne.querySelectorAll('[data-yaz]').forEach(function (e) { e.textContent = e.getAttribute('data-yaz'); e.classList.remove('no-imlec'); });
    }
    function cubuk() { for (var j = 0; j < dilim.length; j++) dilim[j].style.width = j < i ? '100%' : j > i ? '0' : Math.round(100 * adim / Math.max(1, plan.length)) + '%'; }
    function kartAc(n) {
      temizle(); i = n; adim = 0; yazilan = null;
      if (i >= kartlar.length) return sonEkran();
      sahne.classList.toggle('duz', !!duz); kayAnim++; kayHedef = 0; kayCalisiyor = false; sahne.scrollTop = 0;
      sahne.innerHTML = kartHtml(kartlar[i]); sahne.classList.toggle('secimde', secimVar(kartlar[i])); kap.querySelector('.no-sayac').textContent = '· ' + (i + 1) + ' / ' + kartlar.length;
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
          n = Math.min(tam.length, n + 1);   /* 06.10: ~26 harf/sn (okuma hızı; önce 44 idi, kart 18 sn de bitiyordu) */ e.textContent = tam.slice(0, n); takip(e, false);
          if (n < tam.length) { zaman = setTimeout(harf, 38); return; }
          e.classList.remove('no-imlec'); yazilan = null; adim++; cubuk(); zaman = setTimeout(ilerle, 250);
        })();
        return;
      }
      if (a[0] === 'secim') {
        var kalan = Math.round(a[2] / 1000), gs = sahne.querySelector('.no-geri');
        var yaz = function () { if (gs) gs.textContent = 'Seçmezsen Nöbetçi ' + kalan + ' sn sonra anlatmaya başlar.'; }; yaz();
        geriSay = setInterval(function () { kalan = Math.max(0, kalan - 1); yaz(); }, 1000);
        zaman = setTimeout(function () { secimBitir('secmedi'); }, a[2]);
        return;
      }
      if (a[0] === 'isaret' && a[1]) isaretle(a[1], a[3]);
      if (a[0] === 'ac') { a[1].classList.add('acik'); var el = a[1]; setTimeout(function () { takip(el, true); }, 60); }
      adim++; cubuk(); zaman = setTimeout(ilerle, a[2] || 400);
    }
    /* seçim aşaması biter: süre doldu ya da ziyaretçi "Nöbetçi anlatsın" dedi */
    function secimBitir(neden) { temizle(); var k = kartlar[i]; if (!secimVar(k)) return; kartlar[i] = Object.assign({}, k, { secimBitti: true }); olay(neden);
      var dv = sahne.querySelector('.no-davet'), sl = sahne.querySelector('.no-siklar'); if (dv) dv.hidden = true; if (sl) sl.classList.remove('secilir'); sahne.classList.remove('secimde');
      adim++; cubuk(); ilerle(); }
    /* 07.10 Cem: "sen çöz düğmesi yok, sadece saniye düşüyor" -> süre durdurulabilir; durunca Nöbetçi beklemez, ziyaretçi isterse anlatır */
    function secimBeklet() { var k = kartlar[i]; if (!secimVar(k)) return; temizle(); olay('bekletti');
      var gs = sahne.querySelector('.no-geri'), b = sahne.querySelector('.no-bekle');
      if (gs) gs.textContent = 'Süre durdu, acele yok. Bir şıkka dokun.';
      if (b) { b.textContent = 'Nöbetçi anlatsın →'; b.setAttribute('data-d', 'anlat'); } }
    function sonEkran() {
      temizle(); i = kartlar.length; sahne.classList.remove('duz'); sahne.classList.remove('secimde'); kayAnim++; kayHedef = 0; kayCalisiyor = false; sahne.scrollTop = 0; cubuk(); for (var j = 0; j < dilim.length; j++) dilim[j].style.width = '100%';
      kap.querySelector('.no-sayac').textContent = '';
      var s = o.son || {};
      sahne.innerHTML = '<div class="no-son"><p>' + (s.metin || 'Bankadaki her soru böyle anlatılır.') + '</p>' +
        (s.href ? '<a class="' + esc(s.sinif || 'sv-btn ana') + '" data-d="paket" style="text-decoration:none;display:inline-block" href="' + esc(s.href) + '">' + esc(s.dugme || 'Tam bankayı aç →') + '</a>' : '') +
        '<div style="margin-top:12px"><button type="button" data-d="bastan" style="background:none;border:0;color:var(--muted);text-decoration:underline;cursor:pointer">Baştan izle</button></div></div>';
      if (!bitti.son) { bitti.son = 1; olay('son'); }
    }
    function oynaDurdur(d, otomatik) { dur = d; oynaD.textContent = dur ? '▶' : '⏸'; oynaD.setAttribute('aria-label', dur ? 'Oynat' : 'Durdur'); if (dur) { temizle(); if (!otomatik) olay('durdur'); } else if (i < kartlar.length) ilerle(); }
    kap.addEventListener('keydown', function (ev) { var li = ev.target.closest && ev.target.closest('.no-siklar.secilir li[data-h]'); if (li && (ev.key === 'Enter' || ev.key === ' ')) { ev.preventDefault(); sec(li.getAttribute('data-h')); } });
    kap.addEventListener('click', function (ev) {
      var li = ev.target.closest('.no-siklar.secilir li[data-h]'); if (li) { sec(li.getAttribute('data-h')); return; }
      var b = ev.target.closest('[data-d]'); if (!b) return; var d = b.getAttribute('data-d');
      if (d === 'oyna') { oto = false; if (duz) { duz = false; dur = false; kartAc(i); oynaD.textContent = '⏸'; } else oynaDurdur(!dur); }
      else if (d === 'ileri') kartAc(Math.min(kartlar.length, i + 1));
      else if (d === 'geri') kartAc(Math.max(0, i - (i >= kartlar.length ? 1 : (adim > 2 ? 0 : 1))));
      else if (d === 'bastan') { duz = false; kartlar = ilkKartlar.slice(); oynaDurdur(false); kartAc(0); }   // baştan: seçim aşaması yeniden
      else if (d === 'paket') olay('paket');
      else if (d === 'bekle') secimBeklet();
      else if (d === 'anlat') { oto = false; if (dur) { dur = false; oynaD.textContent = '⏸'; } secimBitir('anlat'); }
      else if (d === 'metin') { olay('metin'); temizle(); duz = true; oynaD.textContent = '▶'; metinGorunum(); }
    });
    function metinGorunum() {
      var h = ''; kartlar.forEach(function (k) { h += '<div style="border-top:1px solid var(--line);padding-top:12px;margin-top:12px">' + kartHtml(k) + '</div>'; });
      sahne.classList.add('duz'); sahne.innerHTML = h; hepsiniAc(); kap.querySelector('.no-sayac').textContent = ''; for (var j = 0; j < dilim.length; j++) dilim[j].style.width = '100%';
      var s = o.son || {}; if (s.href) sahne.insertAdjacentHTML('beforeend', '<div class="no-son" style="padding:16px 0 4px"><p>' + (s.metin || '') + '</p><a class="' + esc(s.sinif || 'sv-btn ana') + '" data-d="paket" style="text-decoration:none;display:inline-block" href="' + esc(s.href) + '">' + esc(s.dugme || 'Tam bankayı aç →') + '</a></div>');
    }
    /* görünür olunca başlar (sayfanın altında kalmışsa boşa oynamasın) */
    var basladi = false;
    if (!duz && kartlar.length) { sahne.innerHTML = kartHtml(kartlar[0]); sahne.classList.toggle('secimde', secimVar(kartlar[0])); kap.querySelector('.no-sayac').textContent = '· 1 / ' + kartlar.length; }   // başlamadan önce soru görünsün (boş kart değil)
    function basla() { if (basladi) return; basladi = true; olay('basladi'); kartAc(0); }
    if (duz) { oynaD.textContent = '▶'; metinGorunum(); olay('metin-varsayilan'); return; }
    /* 06.10 Cem (telefon): kart ekranda büyük ölçüde görünmeden başlamaz; ekrandan çıkınca durur, geri gelince kaldığı yerden sürer
       (kullanıcının kendi ⏸'sine dokunmaz). */
    var oto = false;
    if ('IntersectionObserver' in window) { var g = new IntersectionObserver(function (x) { var o2 = x[0].intersectionRatio;
        var gerek = Math.min(0.6, (innerHeight * 0.8) / Math.max(1, kap.offsetHeight));   // kısa ekranda kart hiç %60 görünmeyebilir
        if (o2 >= gerek) { if (!basladi) basla(); else if (oto && dur) { oto = false; oynaDurdur(false, true); } }
        else if (o2 < 0.2 && basladi && !dur && !duz && i < kartlar.length) { oto = true; oynaDurdur(true, true); } }, { threshold: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1] }); g.observe(kap); }
    else basla();
  }
  kok.NobetciOynatici = { kur: kur, _adimlar: adimlar };
  if (typeof module !== 'undefined' && module.exports) module.exports = { _adimlar: adimlar };
})(typeof window !== 'undefined' ? window : this);
