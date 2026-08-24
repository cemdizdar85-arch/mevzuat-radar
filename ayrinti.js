/* ============================================================================
   TETIKTE — AYRINTI KATMANI                          kuruldu 24.08.2026

   NEDEN VAR
   Olcum (24.08, tetikte.com): sitede 12 yerde tarih basiliyor ama TEK bir
   <time datetime> yok; GTIP kodu ve madde numarasi gosteriliyor ama kopyala
   yok. Ikisi de kucuk seyler, ama bir yazilimcinin sayfaya bakarken ilk
   fark ettikleri bunlardir. "En iyiler yapmis" hissi buradan gelir.

   NE YAPAR
   1) TARIH  — GG-AA-YYYY metnini <time datetime="YYYY-MM-DD"> icine alir.
      Makine, ekran okuyucu ve arama motoru artik tarihi okuyabilir.
   2) KOPYALA — [data-kopyala] veya <code> ogesine tiklaninca degeri panoya
      alir. Klavyeyle de calisir (tabindex + Enter/Space), sonucu aria-live
      ile duyurur.

   TASARIM KARARI
   Sayfa metnini kendiliginden TARAMAZ. Otomatik tarama, "20.08.2026" gibi
   gorunen ama tarih olmayan seyleri (surum no, olcu) bozar. Isaretlenmis
   ogeye dokunur, baskasina dokunmaz.
   ========================================================================== */

(function () {
  'use strict';

  /* ---- 1. TARIH ----------------------------------------------------------- */

  /* "20-08-2026" veya "20.08.2026" -> {iso:"2026-08-20", goster:"20.08.2026"} */
  function tarihCoz(s) {
    var m = String(s || '').trim().match(/^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})$/);
    if (!m) return null;
    var g = m[1].padStart(2, '0'), a = m[2].padStart(2, '0'), y = m[3];
    if (+a < 1 || +a > 12 || +g < 1 || +g > 31) return null;
    return { iso: y + '-' + a + '-' + g, goster: g + '.' + a + '.' + y };
  }

  /* Betiklerin dogrudan kullanmasi icin: veri -> hazir <time> HTML'i */
  window.tarihEtiketi = function (s, sinif) {
    var t = tarihCoz(s);
    if (!t) return String(s == null ? '' : s);
    return '<time datetime="' + t.iso + '"' + (sinif ? ' class="' + sinif + '"' : '') +
           '>' + t.goster + '</time>';
  };

  /* data-tarih="20-08-2026" tasiyan ogeyi <time>'a yukselt */
  function tarihleriYukselt(kok) {
    (kok || document).querySelectorAll('[data-tarih]:not([data-tarih-hazir])')
      .forEach(function (e) {
        var t = tarihCoz(e.getAttribute('data-tarih'));
        e.setAttribute('data-tarih-hazir', '1');
        if (!t) return;
        var z = document.createElement('time');
        z.dateTime = t.iso;
        z.textContent = e.textContent.trim() || t.goster;
        z.className = e.className;
        e.replaceWith(z);
      });
  }

  /* ---- 2. KOPYALA --------------------------------------------------------- */

  var duyuru;
  function duyur(metin) {
    if (!duyuru) {
      duyuru = document.createElement('div');
      duyuru.setAttribute('aria-live', 'polite');
      duyuru.className = 'ay-duyuru';
      document.body.appendChild(duyuru);
    }
    duyuru.textContent = metin;
  }

  function kopyala(oge) {
    var deger = oge.getAttribute('data-kopyala') || oge.textContent.trim();
    if (!deger) return;

    function bitti() {
      oge.classList.add('ay-kopyalandi');
      duyur(deger + ' panoya kopyalandı');
      setTimeout(function () { oge.classList.remove('ay-kopyalandi'); }, 1400);
    }
    function olmadi() { duyur('Kopyalanamadı, elle seçebilirsin'); }

    /* Eski yol: gizli textarea + execCommand. Modern API basarisiz olursa
       (guvensiz baglam, izin yok, kullanici hareketi sayilmadi) buna duseriz.
       Olculdu 24.08: writeText, kullanici hareketi olmadan REDDEDIYOR - tek
       basina birakmak "kopyalanamadi" demenin en kolay yoludur. */
    function eskiYol() {
      try {
        var a = document.createElement('textarea');
        a.value = deger;
        a.setAttribute('readonly', '');
        a.style.cssText = 'position:fixed;top:-1000px;opacity:0';
        document.body.appendChild(a);
        a.select();
        a.setSelectionRange(0, deger.length);          /* iOS bunu ister */
        var oldu = document.execCommand('copy');
        a.remove();
        oldu ? bitti() : olmadi();
      } catch (e) { olmadi(); }
    }

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(deger).then(bitti, eskiYol);   /* dusersek yedek */
    } else {
      eskiYol();
    }
  }

  /* Kopyalanabilir ogeyi klavyeye ve ekran okuyucuya tanit */
  function kopyalariHazirla(kok) {
    (kok || document).querySelectorAll('[data-kopyala]:not([data-kopyala-hazir])')
      .forEach(function (e) {
        e.setAttribute('data-kopyala-hazir', '1');
        e.classList.add('ay-kopya');
        if (!e.hasAttribute('tabindex')) e.tabIndex = 0;
        if (!e.hasAttribute('role')) e.setAttribute('role', 'button');
        if (!e.hasAttribute('title')) e.title = 'Kopyalamak için tıkla';
      });
  }

  /* Tek dinleyici, olay devri: sonradan gelen icerik de calisir. */
  document.addEventListener('click', function (e) {
    var o = e.target.closest('[data-kopyala]');
    if (o) { e.preventDefault(); kopyala(o); }
  });
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    var o = e.target.closest && e.target.closest('[data-kopyala]');
    if (o) { e.preventDefault(); kopyala(o); }
  });

  /* ---- 3. SONRADAN GELEN ICERIK -------------------------------------------
     Sitenin buyuk kismi (RG kartlari, GTIP sonucu, katalog) JS ile sonradan
     basiliyor. Tek seferlik kurulum yetmez; DOM degisince yeniden bakilir.  */
  function hepsiniHazirla(kok) { tarihleriYukselt(kok); kopyalariHazirla(kok); }

  function baslat() {
    hepsiniHazirla(document);
    if (!window.MutationObserver) return;
    var bekleyen = false;
    new MutationObserver(function () {
      if (bekleyen) return;
      bekleyen = true;
      /* toplu degisiklikte tek sefer calis - her dugum icin degil */
      requestAnimationFrame(function () { bekleyen = false; hepsiniHazirla(document); });
    }).observe(document.body, { childList: true, subtree: true });
  }

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', baslat);
  else baslat();
})();
