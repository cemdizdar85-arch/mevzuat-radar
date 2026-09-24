/* ============================================================================
   TEMA BAŞI (23.09.2026) — sitenin TEK tema kaynağı. <head>'de, stil dosyalarından ÖNCE, eşzamanlı yüklenir.

   NEDEN (Cem 23.09): "siteye girdiğimde beyazken başka sayfa siyah oluyor… renk sadece baş ekranda değil her
   yerde tümden değişsin, üstten değiştirsinler." Ölçüldü: iki habersiz düzen vardı —
     · genel sayfalar menu.js ile tt_tema ('acik'/'koyu'), düğme sağ altta;
     · Kaydır-Çöz / deneme / canlı deneme / tuzak kc_tema ('dark'/'light'), kendi düğmeleri.
   Birinde koyu seçen öbüründe beyaz görüyordu.

   KARAR: tek anahtar kc_tema ('dark' | 'light'). Kaydır-Çöz sayfaları (29 sayfa, motor/kaydir-coz.ps1 basar)
   zaten bunu okuyor; genel sayfalar ona taşındı. Eski tt_tema bir kez aktarılır (kc_tema yoksa).
   Varsayılan KOYU (Cem 24.09: "ekran hep bu renk gelsin, isteyen beyaz yapsın, sitenin rengi bu olsun");
   beyaz yalnız düğmeyle seçilir ve cihazda hatırlanır. İşletim sistemi İZLENMEZ (09.09 kararı).

   NASIL: açık tema stil-acik.css'ten gelir (sayfa sonunda bağlı, stil.css koyu tabanın üstüne).
   Koyu = o bağ(lar) devre dışı + <html data-theme="dark">. Bağ gövdede ayrıştırıldığı an MutationObserver
   kapatır (sayfa sonu beklenmez) - koyu seçen beyaz parlama görmesin. Düğme menu.js'tedir (üst şerit, Ara'nın
   yanı); o da bu dosyanın window.TetikteTema'sını kullanır. Değişim 'tt-tema' olayıyla duyurulur
   (ana sayfadaki günün sorusu iframe'i buna göre yenilenir).

   GÖRMEZ: stil-acik.css bağlı olmayan sayfalar (arsiv/kartlar-* gibi yalnız koyu olanlar) açık temaya
   geçemez - orada tema hiç değişmez. Kaydır-Çöz sayfalarının kendi düğmesi kendi yerinde kalır (aynı anahtar).
   ========================================================================== */
(function(){
  if (window.TetikteTema) return;
  var KEY = 'kc_tema', d = document.documentElement;
  function oku(){
    try{
      var t = localStorage.getItem(KEY);
      if (t === 'dark' || t === 'light') return t;
      var eski = localStorage.getItem('tt_tema');            /* 16.09 menü düğmesinin anahtarı -> bir kez aktar */
      if (eski === 'koyu' || eski === 'acik') { t = eski === 'koyu' ? 'dark' : 'light'; localStorage.setItem(KEY, t); return t; }
    }catch(e){}
    return 'dark';   /* 24.09 Cem: site rengi koyu; seçim yoksa koyu */
  }
  function acikBaglar(){ return [].slice.call(document.querySelectorAll('link[rel="stylesheet"]')).filter(function(l){ return /stil-acik\.css/.test(l.getAttribute('href')||''); }); }
  var gozcu = null;
  function uygula(t){
    var koyu = t === 'dark';
    if (koyu) d.setAttribute('data-theme', 'dark'); else d.removeAttribute('data-theme');
    acikBaglar().forEach(function(l){ l.disabled = koyu; });
    var cs = document.querySelector('meta[name="color-scheme"]'); if (cs) cs.setAttribute('content', koyu ? 'dark' : 'light');
    /* ayrıştırma sürerken sonradan gelen stil-acik bağını geldiği an kapat */
    if (koyu && !gozcu && window.MutationObserver && document.readyState === 'loading') {
      gozcu = new MutationObserver(function(ks){
        ks.forEach(function(k){ [].forEach.call(k.addedNodes, function(n){
          if (n.tagName === 'LINK' && /stil-acik\.css/.test(n.getAttribute('href')||'') && d.getAttribute('data-theme') === 'dark') n.disabled = true;
          if (n.tagName === 'META' && n.getAttribute('name') === 'color-scheme' && d.getAttribute('data-theme') === 'dark') n.setAttribute('content', 'dark');
        }); });
      });
      gozcu.observe(d, { childList:true, subtree:true });
      document.addEventListener('DOMContentLoaded', function(){ if (gozcu) { gozcu.disconnect(); gozcu = null; } uygula(oku()); });
    }
  }
  function yaz(t){
    t = t === 'dark' ? 'dark' : 'light';
    try{ localStorage.setItem(KEY, t); localStorage.removeItem('tt_tema'); }catch(e){}
    uygula(t);
    try{ document.dispatchEvent(new CustomEvent('tt-tema', { detail:t })); }catch(e){}
  }
  /* başka sekmede değişirse bu sekme de uyar */
  window.addEventListener('storage', function(e){ if (e.key === KEY) { uygula(oku()); try{ document.dispatchEvent(new CustomEvent('tt-tema', { detail:oku() })); }catch(x){} } });
  window.TetikteTema = { oku:oku, yaz:yaz, uygula:uygula, koyuMu:function(){ return oku() === 'dark'; } };
  uygula(oku());
})();
