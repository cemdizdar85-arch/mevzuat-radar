/* ============================================================================
   TEMA BAŞI (23.09.2026) — sitenin TEK tema kaynağı. <head>'de, stil dosyalarından ÖNCE, eşzamanlı yüklenir.

   NEDEN (Cem 23.09): "siteye girdiğimde beyazken başka sayfa siyah oluyor… renk sadece baş ekranda değil her
   yerde tümden değişsin, üstten değiştirsinler." Ölçüldü: iki habersiz düzen vardı —
     · genel sayfalar menu.js ile tt_tema ('acik'/'koyu'), düğme sağ altta;
     · Kaydır-Çöz / deneme / canlı deneme / tuzak kc_tema ('dark'/'light'), kendi düğmeleri.
   Birinde koyu seçen öbüründe beyaz görüyordu.

   KARAR: tek anahtar kc_tema ('dark' | 'light'). Kaydır-Çöz sayfaları (29 sayfa, motor/kaydir-coz.ps1 basar)
   zaten bunu okuyor; genel sayfalar ona taşındı. Eski tt_tema bir kez aktarılır (kc_tema yoksa).
   Varsayılan AÇIK / kırık beyaz (Cem 04.10, V2 madde 21; 24.09'daki "varsayılan koyu" kararının yerine geçti);
   koyu yalnız düğmeyle seçilir ve cihazda hatırlanır. İşletim sistemi İZLENMEZ (09.09 kararı).

   NASIL: açık tema stil-acik.css'ten gelir (sayfa sonunda bağlı, stil.css koyu tabanın üstüne).
   Koyu = o bağ(lar) devre dışı + <html data-theme="dark">. Bağ gövdede ayrıştırıldığı an MutationObserver
   kapatır (sayfa sonu beklenmez) - koyu seçen beyaz parlama görmesin. Düğme menu.js'tedir (üst şerit, Ara'nın
   yanı); o da bu dosyanın window.TetikteTema'sını kullanır. Değişim 'tt-tema' olayıyla duyurulur
   (ana sayfadaki günün sorusu iframe'i buna göre yenilenir).

   GÖRMEZ: stil-acik.css bağlı olmayan sayfalar (arsiv/kartlar-* gibi yalnız koyu olanlar) açık temaya
   geçemez - orada tema hiç değişmez. Kaydır-Çöz sayfalarının kendi düğmesi kendi yerinde kalır (aynı anahtar).
   ========================================================================== */
/* 04.10.2026 GİRİŞ DÖNÜŞÜ YEDEĞİ (Cem'in Google girişi ana sayfaya "#access_token=..." ile düştü; şeritte "Giriş yap" kaldı =
   giriş TAMAMLANMADI). Sebep: google-giris.js redirectTo = /ogrenci.html; Supabase'in izinli dönüş adresleri listesinde yoksa
   Site URL'e (kök) atar ve kök sayfa oturumu işlemez. Kalıcı çözüm panelde (Authentication -> URL Configuration -> Redirect URLs:
   https://tetikte.com/ogrenci.html). Bu satır her sayfanın başında: anahtarlı ya da hatalı dönüş hangi sayfaya düşerse düşsün,
   adres karması korunarak hesap sayfasına aktarılır (orada supabase-js oturumu kurar, google-giris.js ?sonra='yı geri koyar). */
try {
  if (/(?:^#|&)(?:access_token|refresh_token|error_description)=/.test(location.hash) && !/\/ogrenci\.html$/i.test(location.pathname)) {
    location.replace('/ogrenci.html' + location.hash);
  }
} catch (e) {}

/* 04.10.2026 ELÇİ İZİ (Cem: "ne kadarı elçi ile geldi"): elçi linki (?e=KOD) hangi sayfaya düşerse düşsün kod cihazda
   saklanır (tt_elci); satin-al.html indirimde, ogrenci.html / google-giris.js üyelik kaydında kullanır. Kodun geçerliliği
   burada DENETLENMEZ (indirim sunucuda elci_kodu_kontrol ile); yalnız biçim. */
try {
  var elciQ = (location.search.match(/[?&]e=([A-Za-z0-9]{3,12})(?:&|$)/) || [])[1];
  if (elciQ) localStorage.setItem('tt_elci', elciQ.toUpperCase());
} catch (e) {}

/* 07.10.2026 ESKİ İZ SATIRI PARLAMASI (Cem: "bir yerde başka şey görünüyor sonra kayboluyor"): alt sayfaların .top iz satırı
   ("Tetikte · Soru çöz · Hesabım") menu.js ustSeritKur() onu silip ortak şeridi koyana dek ~0,3-1 sn görünüyordu (canlı ölçüm:
   sorular 290->663 ms, deneme 736->1137 ms). menu.js'in dokunduğu sayfalarda (ana sayfa ve kaydir/ hariç) .top baştan gizlenir;
   menu.js kur() işareti kaldırır. menu.js hiç gelmezse 2,5 sn sonra kendiliğinden açılır (iz satırı kaybolmasın). */
try {
  if (!/\/kaydir\//.test(location.pathname) && !/(^|\/)(index\.html)?$/i.test(location.pathname)) {
    document.documentElement.classList.add('tt-ust-bekle');
    var ustBekleStil = document.createElement('style');
    /* .top yer KAPLAMAZ, gövdenin tepesinde ortak şeridin yüksekliği (64 + 1 px çizgi) kadar yer ayrılır: şerit geldiğinde
       içerik kımıldamaz (canlı ölçüm 07.10: şerit 2-5 sn'de gelip içeriği 65 px itiyordu - satin-al 0,24, yanlislarim 0,03-0,09). */
    ustBekleStil.textContent = 'html.tt-ust-bekle .top{display:none}html.tt-ust-bekle body{padding-top:65px}';
    (document.head || document.documentElement).appendChild(ustBekleStil);
    setTimeout(function(){ document.documentElement.classList.remove('tt-ust-bekle'); }, 2500);
  }
} catch (e) {}

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
    return 'light';  /* 04.10 Cem (V2 madde 21, 'kırık beyaz'): seçim yoksa AÇIK. 24.09'daki 'koyu' kararının yerine geçti; koyu seçen cihaz koyu kalır (kc_tema). */
  }
  function acikBaglar(){ return [].slice.call(document.querySelectorAll('link[rel="stylesheet"]')).filter(function(l){ return /stil-acik\.css/.test(l.getAttribute('href')||''); }); }
  var gozcu = null;
  function uygula(t){
    var koyu = t === 'dark';
    if (koyu) d.setAttribute('data-theme', 'dark'); else d.removeAttribute('data-theme');
    acikBaglar().forEach(function(l){ l.disabled = koyu; });
    var cs = document.querySelector('meta[name="color-scheme"]'); if (cs) cs.setAttribute('content', koyu ? 'dark' : 'light');
    /* 05.10 SİYAH PARLAMA (Cem: "beyaz ekrandayız, bir yere basınca siyah ekran görünüyor"): stil.css koyu TABANLA başlıyor
       (--bg #06090f), açık tema stil-acik.css sayfa SONUNDA bağlı → tarayıcı sona varmadan ilk kareyi koyu boyuyordu.
       Açık temada ilk kareden itibaren zemin ve yazı rengi açık temanınkiyle (stil-acik.css :root --bg #fbfaf8, --ink #0f1b2d)
       boyanır; sayfa tamamen yüklenince (load) bu erken kat kaldırılır, gerisini stil-acik.css taşır.
       Özgüllük (0,1,1)/(0,1,2): stil.css'in html/body kuralını !important olmadan geçer. Koyu temada hiç eklenmez/silinir. */
    var erken = document.getElementById('tt-erken-acik');
    if (!koyu && !erken && document.readyState !== 'complete') {
      erken = document.createElement('style'); erken.id = 'tt-erken-acik';
      /* TEMA-ERKEN-BASLA (stil-acik.css :root degerleri; esitligi arac/tema-erken-esitlik.js denetler) */
      erken.textContent = 'html:not([data-theme="dark"]){--marka-lamba-1:#f5a524;--marka-lamba-2:#ffc24b;--bg:#fbfaf8;--bg2:#f4f2ee;--panel:#ffffff;--panel2:#f7f5f1;--line:#e6e2da;--line2:#d5d0c6;--ink:#0f1b2d;--muted:#3d4b63;--dim:#5f6875;--accent:#8a6224;--accent2:#92400e;--grad:linear-gradient(135deg,#f5a524 0%,#ffc24b 100%);--red:#b91c1c;--amber:#8a6224;--amber-dolgu:#f5a524;--amber-uzeri:var(--ink);--green:#146f35;--link:#1d4ed8;--taban:#fbfaf8;--yuzey:#f4f2ee;--kagit:#ffffff;--kart:#ffffff;--slate:#5b6672;--slate-bg:#eef0f3;--red-bg:#fdecea;--amber-bg:#fff6e0;--green-bg:#e8f6ec;--shadow:0 1px 2px rgba(20,25,30,.05),0 8px 24px -16px rgba(20,25,30,.18);background:#fbfaf8;color-scheme:light}html:not([data-theme="dark"]) body{background:#fbfaf8;color:#0f1b2d}';
      /* TEMA-ERKEN-BITIR */
      (document.head || d).appendChild(erken);
      window.addEventListener('load', function(){ var e = document.getElementById('tt-erken-acik'); if (e) e.remove(); });
    } else if (koyu && erken) { erken.remove(); }
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
