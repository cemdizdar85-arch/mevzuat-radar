/* ============================================================================
   ANLIK TEKLİF — 12.10.2026 (Cem: "tek ders için 200 TL" · "süre olmasın, anlık gibi olsun")
   Yeterlilik seviye testi ve Sınav Provası (YET-*) sonucunun hemen altında EN ZAYIF derse tek ders teklifi.

   Kurallar:
   - Rakamlar fiyat-motoru.js'ten (anlikTeklifFiyat): kuruluş fiyatı ve ANLIK_TEKLIF.indirim. Elle rakam yok.
   - SAYAÇ YOK, süre/kıtlık cümlesi YOK. Teklif o sonuç için BİR KEZ çizilir: cihazda işaret (tt_anlik_teklif_goruldu,
     çizmeden ÖNCE yazılır → yenileme/geri gelişte çıkmaz) + girişliyse hesapta işaret (anlik_teklif_al, (hesap, sonuç) tekil).
   - "Dersini aç" → satin-al.html?paket=…&dersler=…&t=<belirteç>. Belirteç SUNUCUDA üretilir, hesaba bağlı, tek kullanımlık
     (radar-app/sql/2026-10-12-anlik-teklif.sql). Girişsiz ziyaretçide belirteç yoktur: teklif bu sekmede (sessionStorage)
     bekler, satin-al.html giriş yapınca aynı sonuç için belirteci alır. Sekme kapanınca bekleyen teklif de gider.
   - Sınav ekranının yük kuralı (5k kişi): ağa yalnız girişli kişide TEK istek; Auth'a gidilmez (cihazdaki oturum okunur,
     süresi dolmuşsa sayfada supabase istemcisi varsa o yeniler, yoksa girişsiz yola düşülür).
   🚫 GÖRMEZ: başka cihazda açılmış ama işareti bu cihaza gelmemiş, girişsiz gösterim (hesap işareti girişte konur).
   ============================================================================ */
(function(){
  'use strict';
  var SB = 'https://bjrleanjpyujtajmazxn.supabase.co', KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var ISARET = 'tt_anlik_teklif_goruldu', BEKLEYEN = 'tt_anlik_teklif';
  var esc = function(s){ return String(s == null ? '' : s).replace(/[&<>"]/g, function(c){ return { '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;' }[c]; }); };

  function gorulduMu(s){ try{ var a = JSON.parse(localStorage.getItem(ISARET) || '[]'); return Array.isArray(a) && a.indexOf(s) > -1; }catch(e){ return false; } }
  function isaretle(s){
    try{ var a = JSON.parse(localStorage.getItem(ISARET) || '[]'); if(!Array.isArray(a)) a = [];
      if(a.indexOf(s) < 0) a.push(s); localStorage.setItem(ISARET, JSON.stringify(a.slice(-50))); }catch(e){}
  }
  /* cihazdaki supabase oturumu (sb-<proje>-auth-token) — ağa gitmez */
  function oturum(){
    try{
      for(var i = 0; i < localStorage.length; i++){
        var k = localStorage.key(i); if(!/^sb-[a-z0-9]+-auth-token$/.test(k)) continue;
        var v = JSON.parse(localStorage.getItem(k) || 'null'), s = v && (v.access_token ? v : v.currentSession);
        if(s && s.access_token) return s;
      }
    }catch(e){}
    return null;
  }
  function erisim(){
    var s = oturum(); if(!s) return Promise.resolve(null);
    if(s.expires_at && s.expires_at * 1000 > Date.now() + 60000) return Promise.resolve(s.access_token);
    var sb = window.__pkSb || window.sb;
    if(sb && sb.auth && sb.auth.getSession){
      return sb.auth.getSession().then(function(r){ var x = r && r.data && r.data.session; return x ? x.access_token : null; }).catch(function(){ return null; });
    }
    return Promise.resolve(null);
  }
  function stilKur(){
    if(document.getElementById('atStil')) return;
    var st = document.createElement('style'); st.id = 'atStil';
    st.textContent = '.at-kutu{background:var(--panel);border:2px solid var(--amber);border-radius:14px;padding:18px 18px 14px;margin:16px 0}'
      + '.at-bas{font-size:18px;font-weight:800;margin:0 0 6px;color:var(--ink);letter-spacing:-.2px}'
      + '.at-metin{font-size:14.5px;line-height:1.55;margin:0 0 10px;color:var(--ink)}'
      + '.at-fiyat{font-size:16px;margin:0 0 12px;color:var(--ink);font-variant-numeric:tabular-nums}'
      + '.at-fiyat .at-once{color:var(--muted)}.at-fiyat b{font-size:20px;color:var(--ink)}.at-fiyat small{color:var(--muted);font-size:12px}'
      + '.at-btn{display:block;text-align:center;background:var(--amber-dolgu);color:var(--amber-uzeri);font-weight:800;font-size:15.5px;padding:13px 18px;border-radius:11px;text-decoration:none}'
      + '.at-btn:focus-visible{outline:2px solid var(--ink);outline-offset:2px}'
      + '@media(min-width:560px){.at-btn{display:inline-block}}'
      + '.at-not{font-size:12.5px;color:var(--muted);margin:10px 0 0}'
      + '.at-ikili{display:grid;gap:12px}@media(min-width:700px){.at-ikili{grid-template-columns:1fr 1fr}}'
      + '.at-sec{position:relative;border:1px solid var(--line);border-radius:12px;padding:14px;display:flex;flex-direction:column}'
      + '.at-sec .at-btn{margin-top:auto;display:block}.at-sec.at-oner{border:2px solid var(--amber)}'
      + '.at-sb{font-size:16px;margin:0 0 4px;color:var(--ink)}'
      + '.at-rozet{position:absolute;top:-11px;right:12px;background:var(--amber-dolgu);color:var(--amber-uzeri);font-size:11.5px;font-weight:800;padding:2px 9px;border-radius:999px;letter-spacing:.2px}'
      + '.at-fiyat s{text-decoration-thickness:1px}';
    document.head.appendChild(st);
  }
  function satinAlAdres(o, pid, t){
    return 'satin-al.html?paket=' + encodeURIComponent(pid) + (pid === o.paket ? '&dersler=' + encodeURIComponent(o.ders) : '')
      + '&t=' + encodeURIComponent(t && t.belirtec ? t.belirtec : 'giris');
  }
  /* 12.10 (Cem "evet bunları yapalım"): iki seçenek - en zayıf ders (−200) ve tüm 8 ders (−600, önerilen). Çizili rakam yalnız
     sitedeki GÜNCEL kuruluş fiyatı (o fiyattan satış yapılıyor; m.14/3'teki sahte eski fiyat değil). */
  function ciz(kap, o, f, t){
    stilKur();
    var tum = (typeof anlikTeklifTum === 'function') ? anlikTeklifTum(o.sinav) : null;
    var d = document.createElement('div');
    d.className = 'at-kutu'; d.id = 'anlikTeklif'; d.setAttribute('data-sonuc', o.sonuc); d.setAttribute('role', 'region'); d.setAttribute('aria-label', 'Sana özel teklif');
    var secenek = function(pid, baslik, metin, x, dugme, onerilen){
      return '<div class="at-sec' + (onerilen ? ' at-oner' : '') + '">'
        + (onerilen ? '<span class="at-rozet">Önerilen</span>' : '')
        + '<p class="at-sb">' + baslik + '</p><p class="at-metin">' + metin + '</p>'
        + '<p class="at-fiyat"><s class="at-once">' + tl(x.once) + ' TL</s> → <b>Şimdi ' + tl(x.simdi) + ' TL</b> <small>KDV dahil</small></p>'
        + '<a class="at-btn" data-pk="' + esc(pid) + '" href="' + esc(satinAlAdres(o, pid, t)) + '">' + dugme + '</a></div>';
    };
    d.innerHTML = '<p class="at-bas">Eksiğini sınavdan önce kapat.</p><div class="at-ikili">'
      + secenek(f.paket, '<b>' + esc(o.ders) + '</b> dersi', 'Tüm sorular, her yanlışın nedeni ve kanun maddesi, ders denemeleri (20 soru, 45 dk, yanlış 0,25 götürür).', f, esc(o.ders) + ' dersini aç', false)
      + (tum ? secenek(tum.paket, '<b>Tüm 8 ders</b>', 'Sınavdaki sekiz dersin hepsinde aynı içerik: tüm sorular, yanlışın nedeni ve kanun maddesi, ders denemeleri.', tum, 'Tüm dersleri aç', true) : '')
      + '</div><p class="at-not">Bu teklif yalnız bu ekranda geçerli; sayfadan çıkınca kalkar.</p>';
    Array.prototype.forEach.call(d.querySelectorAll('.at-btn'), function(btn){ btn.addEventListener('click', function(){
      /* teklif yalnız bu sekmeye taşınır; satin-al.html okur. Belirteç yoksa (girişsiz) girişten sonra alınır. */
      var pk = btn.getAttribute('data-pk');
      try{ sessionStorage.setItem(BEKLEYEN, JSON.stringify({ sonuc:o.sonuc, kaynak:o.kaynak, paket:o.paket, secilen:pk, ders:o.ders,
        belirtec:(t && t.belirtec) || '', t:Date.now() })); }catch(e){}
      try{ if(window.goatcounter && typeof window.goatcounter.count === 'function') window.goatcounter.count({ path:'anlik-teklif/' + o.kaynak + '/tik/' + pk, title:'Anlık teklif: düğme', event:true }); }catch(e){}
    }); });
    if(o.once && o.once.parentNode === kap) kap.insertBefore(d, o.once); else kap.appendChild(d);
    /* 12.10: ekranda TEK fiyat kalsın - sayfanın kendi fiyat kutusu (ör. seviye testinde "Riskli derslerini Nöbetçi'yle kapat") gizlenir */
    if(o.gizle) try{ o.gizle.hidden = true; }catch(e){}
    try{ if(window.goatcounter && typeof window.goatcounter.count === 'function') window.goatcounter.count({ path:'anlik-teklif/' + o.kaynak + '/goster', title:'Anlık teklif: gösterildi', event:true }); }catch(e){}
  }

  /* o = { kap: kapsayıcı öğe, once: (isteğe bağlı) önüne konacak öğe, gizle: (isteğe bağlı) teklif çizilince gizlenecek fiyat kutusu, kaynak:'seviye'|'prova', sonuc:'<tekil sonuç kimliği>',
         sinav:'yeterlilik', ders:'<en zayıf ders>' } */
  function goster(o){
    try{
      if(!o || !o.kap || !o.ders || !o.sonuc || typeof anlikTeklifFiyat !== 'function') return;
      var f = anlikTeklifFiyat(o.sinav); if(!f) return;
      o.paket = f.paket;
      if(document.getElementById('anlikTeklif') || gorulduMu(o.sonuc)) return;
      isaretle(o.sonuc);   /* çizmeden önce: yenilenirse bir daha çıkmaz */
      var bitti = false, son = function(t){ if(bitti) return; bitti = true; if(t !== false) ciz(o.kap, o, f, t); };
      erisim().then(function(tok){
        if(!tok){ son(null); return; }
        var z = setTimeout(function(){ son(null); }, 8000);
        fetch(SB + '/rest/v1/rpc/anlik_teklif_al', { method:'POST',
          headers:{ apikey:KEY, Authorization:'Bearer ' + tok, 'Content-Type':'application/json' },
          body:JSON.stringify({ p_sonuc:o.sonuc, p_kaynak:o.kaynak, p_ders:o.ders }) })
          .then(function(r){ if(!r.ok) throw 0; return r.json(); })
          .then(function(j){ clearTimeout(z); son(j && j.belirtec ? j : false); })   /* null = hesapta zaten gösterildi / paketi var → çizme */
          .catch(function(){ clearTimeout(z); son(null); });                        /* sunucu yoksa girişsiz yol: satin-al girişte alır */
      });
    }catch(e){}
  }
  window.AnlikTeklif = { goster:goster, BEKLEYEN:BEKLEYEN };
})();
