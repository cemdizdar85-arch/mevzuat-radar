/* gkt.js — GEÇENE KADAR TETİKTE kartlarının rakamları (27.10.2026). Rakam YALNIZ fiyat-motoru.js'ten (FIYAT, ERKEN_KAYIT,
   kdvHaric): sayfadaki yazılı rakam yalnız betik yüklenmezse görünen yedektir. Erken kayıt bitince (1 Kasım 23:59 TR)
   indirim rozeti ve "yerine" satırı kalkar, Tam Paket 2.988 yazar. Sınav günü geçince (22 Kasım) kampanya blokları gizlenir.
   01.11 Cem ("23.59 tüm kampanya bitecek, siteyi o saatte robot değiştirsin"): yönetim kurulu kararı (şartsız söz) da aynı saatte
   biter → [data-yk="once"] gizlenir, [data-yk="sonra"] görünür. Robot (zamanlanmış iş) 15–60 dk gecikebildiği için geçiş tarayıcıda,
   saate bakarak; sayfa o an açıksa 23:59:59'da yenilemeden döner. Sınama: window.ttGktUygula(<ms zaman damgası>).
   ✕ gerektirmez: bildirim/katman değil, sayfa bölümü. */
(function(){
  if (typeof FIYAT === 'undefined') return;
  var YK_BITIS = Date.UTC(2026, 10, 1, 21, 4, 59); // 1 Kasım 2026 23:59:59 TR — erken kayıtla aynı an (ERKEN_KAYIT.bitis)
  var SINAV_SONU = Date.UTC(2026, 10, 21, 21, 0, 0);
  function yaz(sec, metin){ var L = document.querySelectorAll(sec); for (var i = 0; i < L.length; i++) L[i].textContent = metin; }
  function gizle(sec, gizli){ var L = document.querySelectorAll(sec); for (var i = 0; i < L.length; i++) L[i].hidden = gizli; }
  function uygula(simdi){
    simdi = simdi || Date.now();
    var erken = simdi < ERKEN_KAYIT.bitis;
    var tam = FIYAT.sgs.kurulus - (erken ? ERKEN_KAYIT.indirim : 0), yedi = FIYAT.son20Sgs.kurulus;
    yaz('[data-gkt="tam"]', tl(tam) + ' TL');
    yaz('[data-gkt="tam-haric"]', kdvHaric(tam) + ' TL + KDV');
    yaz('[data-gkt="liste"]', tl(FIYAT.sgs.kurulus) + ' TL');
    yaz('[data-gkt="yedi"]', tl(yedi) + ' TL');
    yaz('[data-gkt="yedi-haric"]', kdvHaric(yedi) + ' TL + KDV');
    yaz('[data-gkt="indirim"]', tl(ERKEN_KAYIT.indirim) + ' TL');
    yaz('[data-gkt="kod"]', ERKEN_KAYIT.kod);
    gizle('[data-gkt-erken]', !erken);
    var yk = simdi <= YK_BITIS;
    gizle('[data-yk="once"]', !yk);
    gizle('[data-yk="sonra"]', yk);
    if (simdi >= SINAV_SONU) gizle('[data-gkt-bolum]', true);
    return { erken: erken, yk: yk };
  }
  // sayfa CSS'i display verdiyse hidden ezilmesin (ör. .yk-karar, .ks-not)
  var st = document.createElement('style'); st.textContent = '[data-yk][hidden],[data-gkt-erken][hidden]{display:none!important}';
  document.head.appendChild(st);
  window.ttGktUygula = uygula;
  uygula();
  var kalan = Math.max(YK_BITIS, ERKEN_KAYIT.bitis) - Date.now() + 1500;
  if (kalan > 0 && kalan < 864e5) setTimeout(function(){ uygula(); }, kalan);
})();
