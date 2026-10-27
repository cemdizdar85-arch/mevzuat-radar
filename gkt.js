/* gkt.js — GEÇENE KADAR TETİKTE kartlarının rakamları (27.10.2026). Rakam YALNIZ fiyat-motoru.js'ten (FIYAT, ERKEN_KAYIT,
   kdvHaric): sayfadaki yazılı rakam yalnız betik yüklenmezse görünen yedektir. Erken kayıt bitince (1 Kasım 23:59 TR)
   indirim rozeti ve "yerine" satırı kalkar, Tam Paket 2.988 yazar. Sınav günü geçince (22 Kasım) kampanya blokları gizlenir.
   ✕ gerektirmez: bildirim/katman değil, sayfa bölümü. */
(function(){
  if (typeof FIYAT === 'undefined') return;
  var erken = typeof erkenKayitAcik === 'function' && erkenKayitAcik();
  var tam = FIYAT.sgs.kurulus - (erken ? ERKEN_KAYIT.indirim : 0), yedi = FIYAT.son20Sgs.kurulus;
  function yaz(sec, metin){ var L = document.querySelectorAll(sec); for (var i = 0; i < L.length; i++) L[i].textContent = metin; }
  yaz('[data-gkt="tam"]', tl(tam) + ' TL');
  yaz('[data-gkt="tam-haric"]', kdvHaric(tam) + ' TL + KDV');
  yaz('[data-gkt="liste"]', tl(FIYAT.sgs.kurulus) + ' TL');
  yaz('[data-gkt="yedi"]', tl(yedi) + ' TL');
  yaz('[data-gkt="yedi-haric"]', kdvHaric(yedi) + ' TL + KDV');
  yaz('[data-gkt="indirim"]', tl(ERKEN_KAYIT.indirim) + ' TL');
  yaz('[data-gkt="kod"]', ERKEN_KAYIT.kod);
  var E = document.querySelectorAll('[data-gkt-erken]');
  for (var i = 0; i < E.length; i++) E[i].hidden = !erken;
  if (Date.now() >= Date.UTC(2026, 10, 21, 21, 0, 0)) {
    var B = document.querySelectorAll('[data-gkt-bolum]');
    for (var j = 0; j < B.length; j++) B[j].hidden = true;
  }
})();
