/* ============================================================================
   TETIKTE — KOMUT PALETI  (Ctrl+K / Cmd+K)          kuruldu 24.08.2026

   NEDEN VAR
   Sitede 40 arac ve 10 konu var. Cem'in tespiti dogruydu: bu kadar farkli
   konunun oldugu yerde ziyaretci kendi konusunu goremiyor. Menu buyudukce
   sorun buyur; arama kutusu ise sayfanin ortasinda kalir.
   Komut paleti iki sorunu birden kapatir: nerede olursan ol Ctrl+K, yaz, git.

   NEDEN BOYLE YAZILDI
   - Bagimlilik yok, cerceve yok. Tek dosya, ~9 KB, onbellege girer.
   - Arac dizini dosyanin icinde: fazladan ag istegi YOK.
   - Turkce arama gercekten Turkce: "musavir" yazan "Musavir"i de bulur,
     "İ" ile "I" ayni sayilir. Bu, Turkiye'de en cok atlanan ayrintidir.
   - Klavye tam: ok tuslari, Enter, Esc, Tab tuzagi, odak geri verilir.
   - Erisilebilir: role=dialog, aria-modal, aria-activedescendant, canli sayim.
   - Sayfa JS'siz de calisir; palet bir EK'tir, gezinmenin sarti degildir.
   ========================================================================== */

(function () {
  'use strict';

  /* ---- ARAC DIZINI ---------------------------------------------------------
     Konu adlari ve arac adlari katalogdan okundu, uydurulmadi.
     'e' alani = ek arama kelimeleri (kisaltma, es anlam, halk agzi).      */
  /* 30.09 Cem "site sadece SMMM başlama + bitirme": işletme araçları dizinden çıktı (sayfalar yerinde,
     menu.js GIZLI listesinde). Eski dizin git geçmişinde (bu committen önceki komut.js). */
  var KONULAR = [
    ['SMMM sınavları', [
      ['Soru çöz', 'sorular.html', 'soru coz banka sgs staja giris yeterlilik bitirme ders'],
      ['Geçme ihtimalini ölç', 'seviye-testi.html', 'seviye test olcum puan ucretsiz'],
      ['Deneme sınavı', 'deneme.html', 'deneme soru test cozum ogrenci stajyer sinav'],
      ['Canlı deneme', 'canli-deneme.html', 'canli deneme yuzdelik siralama ogrenci sinav'],
      /* 02.10 gizli: ['Günün tuzağı', 'tuzak.html', 'tuzak gunun sorusu'], */
      /* 07.10 Cem ("ulaşamasın bunlara"): genc · donem-plani · songun · karsilastirma GİZLİ; sayfalar silinmedi. */
    ]],
    ['Hesap ve sayfalar', [
      ['Hesabım / öğrenci girişi', 'ogrenci.html', 'giris uye kayit hesap oturum'],
      ['Fiyatlar ve paketler', 'fiyat.html', 'fiyat paket ucret kac para'],
      ['İletişim', 'iletisim.html', 'iletisim mail telefon ulas destek yardim'],
      ['Aydınlatma metni (KVKK)', 'kvkk.html', 'kvkk gizlilik veri guvenlik aydinlatma kisisel']
    ]]
  ];


  /* ---- TURKCE KATLAMA ------------------------------------------------------
     Aramada "musavir" -> "müşavir", "IHALE" -> "ihale" eslesmeli.
     toLocaleLowerCase('tr') tek basina yetmez: kullanici Turkce harfleri
     genelde ASCII yazar. Iki tarafi da ASCII'ye indiriyoruz.               */
  var HARF = { 'ı':'i','İ':'i','I':'i','ş':'s','Ş':'s','ğ':'g','Ğ':'g',
               'ü':'u','Ü':'u','ö':'o','Ö':'o','ç':'c','Ç':'c' };
  function katla(s) {
    s = String(s == null ? '' : s);
    var o = '', i, c;
    for (i = 0; i < s.length; i++) { c = s[i]; o += (HARF[c] || c); }
    return o.toLowerCase();
  }

  /* ---- DIZINI DUZLESTIR ---------------------------------------------------- */
  var KAYIT = [];
  KONULAR.forEach(function (k) {
    k[1].forEach(function (a) {
      KAYIT.push({ ad: a[0], yol: a[1], konu: k[0], ara: katla(a[0] + ' ' + a[2] + ' ' + k[0]) });
    });
  });

  /* 04.10 site turu (Cem "her tuşa bas"): "amortisman" yazan "Eşleşme yok" görüyordu - dizinde ders/konu yoktu.
     Açık sınavların dersleri ve konu adları soru dizininden (veri/soru-dizini.json, sorular.html ile aynı kaynak)
     palet ilk açıldığında bir kez yüklenir. Ders sayfası paketsize paket kapısını gösterir (giriş / paketler). */
  var dizinYuklendi = false;
  function dersleriYukle() {
    if (dizinYuklendi) return; dizinYuklendi = true;
    try {
      fetch('/veri/soru-dizini.json', { cache: 'no-store' }).then(function (r) { return r.ok ? r.json() : null; }).then(function (d) {
        if (!d || !d.sinavlar) return;
        d.sinavlar.forEach(function (s) {
          if (s.durum !== 'acik') return;
          (s.dersler || []).forEach(function (x) {
            if (!x.sayfa) return;
            var konular = (x.konular || []).map(function (k) { return k.ad; }).join(' ');
            KAYIT.push({ ad: x.ad, yol: '/' + x.sayfa, konu: s.ad + ' dersleri', ara: katla(x.ad + ' ' + konular + ' ' + (x.ara || '') + ' ' + s.ad + ' ' + (s.uzun || '')) });
          });
        });
        if (acik && girdi) ciz(girdi.value);
      }).catch(function () {});
    } catch (e) {}
  }

  /* ---- ESLESTIRME ----------------------------------------------------------
     Puanlama: adin basindan eslesme > ad icinde > ek kelimelerde.
     Boylece "marka" yazinca "Marka Radari" once, "Markanla ne
     yapabilirsin" sonra gelir.                                            */
  function ara(q) {
    var t = katla(q).trim();
    if (!t) return KAYIT.slice();
    var parca = t.split(/\s+/);
    return KAYIT.map(function (r) {
      var ad = katla(r.ad), puan = 0, hepsi = true;
      parca.forEach(function (p) {
        var i = r.ara.indexOf(p);
        if (i < 0) { hepsi = false; return; }
        if (ad.indexOf(p) === 0) puan += 100;
        else if (ad.indexOf(p) > -1) puan += 50;
        else puan += 10;
      });
      return hepsi ? { r: r, puan: puan } : null;
    }).filter(Boolean).sort(function (a, b) { return b.puan - a.puan; })
      .map(function (x) { return x.r; });
  }

  /* GTIP kodu yazildiysa dogrudan sorguya goturen ozel satir uretilir.
     Gumruk tarife pozisyonu 4, 6, 8, 10 veya 12 hanelidir; nokta serbest. */
  function gtipSatiri(q) {
    return null; /* 30.09: GTİP gizli (site yalnız SMMM sınavları) */
    var rakam = q.replace(/[.\s]/g, '');
    if (!/^\d{4}(\d{2})?(\d{2})?(\d{2})?(\d{2})?$/.test(rakam)) return null;
    return { ad: rakam + ' kodunu sorgula', yol: 'gtip.html?kod=' + rakam,
             konu: 'Doğrudan işlem', vurgu: true };
  }

  /* ---- ARAYUZ -------------------------------------------------------------- */
  var kok, girdi, liste, sayim, acik = false, sonuc = [], secili = 0, oncekiOdak = null;

  function kur() {
    kok = document.createElement('div');
    kok.className = 'kp-ort';
    kok.hidden = true;
    kok.innerHTML =
      '<div class="kp-perde" data-kapat="1"></div>' +
      '<div class="kp" role="dialog" aria-modal="true" aria-label="Komut paleti">' +
        '<div class="kp-ust">' +
          '<input class="kp-girdi" type="text" role="combobox" aria-expanded="true" ' +
                 'aria-controls="kp-liste" aria-autocomplete="list" autocomplete="off" ' +
                 'spellcheck="false" placeholder="Ara: ders, konu, sayfa… (ör. amortisman)">' +
          '<kbd class="kp-esc">esc</kbd>' +
        '</div>' +
        '<ul class="kp-liste" id="kp-liste" role="listbox" aria-label="Sonuçlar"></ul>' +
        '<div class="kp-alt">' +
          '<span><kbd>↑</kbd><kbd>↓</kbd> gez</span>' +
          '<span><kbd>enter</kbd> aç</span>' +
          '<span class="kp-sayim" aria-live="polite"></span>' +
        '</div>' +
      '</div>';
    document.body.appendChild(kok);
    girdi = kok.querySelector('.kp-girdi');
    liste = kok.querySelector('.kp-liste');
    sayim = kok.querySelector('.kp-sayim');

    girdi.addEventListener('input', function () { ciz(girdi.value); });
    kok.addEventListener('mousedown', function (e) { if (e.target.dataset.kapat) kapat(); });
    liste.addEventListener('click', function (e) {
      var li = e.target.closest('li[data-yol]');
      if (li) git(li.dataset.yol);
    });
    liste.addEventListener('mousemove', function (e) {
      var li = e.target.closest('li[data-yol]');
      if (li && +li.dataset.i !== secili) { secili = +li.dataset.i; imle(); }
    });
  }

  function ciz(q) {
    sonuc = ara(q);
    var ozel = gtipSatiri(q.trim());
    if (ozel) sonuc.unshift(ozel);
    secili = 0;

    if (!sonuc.length) {
      liste.innerHTML = '<li class="kp-yok">Eşleşme yok.</li><li class="kp-satir" role="option" id="kp-s0" data-i="0" data-yol="/sorular.html" aria-selected="false"><span>Bütün dersler: Sınavlar sayfası</span></li>';
      sonuc = [{ ad: 'Bütün dersler', yol: '/sorular.html', konu: '' }];
      sayim.textContent = 'sonuç yok';
      return;
    }
    var oncekiKonu = null, html = '';
    sonuc.forEach(function (r, i) {
      if (r.konu !== oncekiKonu) {
        html += '<li class="kp-konu" role="presentation">' + kacir(r.konu) + '</li>';
        oncekiKonu = r.konu;
      }
      html += '<li class="kp-satir' + (r.vurgu ? ' kp-vurgu' : '') + '" role="option" ' +
              'id="kp-s' + i + '" data-i="' + i + '" data-yol="' + kacir(r.yol) + '" ' +
              'aria-selected="false"><span>' + kacir(r.ad) + '</span>' +
              '<kbd class="kp-git">↵</kbd></li>';
    });
    liste.innerHTML = html;
    sayim.textContent = sonuc.length + ' sonuç';
    imle();
  }

  function kacir(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c];
    });
  }

  function imle() {
    var satirlar = liste.querySelectorAll('.kp-satir');
    satirlar.forEach(function (li) {
      var s = +li.dataset.i === secili;
      li.classList.toggle('secili', s);
      li.setAttribute('aria-selected', s ? 'true' : 'false');
      if (s) {
        girdi.setAttribute('aria-activedescendant', li.id);
        var lr = li.getBoundingClientRect(), kr = liste.getBoundingClientRect();
        if (lr.bottom > kr.bottom) liste.scrollTop += lr.bottom - kr.bottom;
        else if (lr.top < kr.top) liste.scrollTop -= kr.top - lr.top;
      }
    });
  }

  function ac() {
    if (acik) return;
    if (!kok) kur();
    oncekiOdak = document.activeElement;
    acik = true;
    kok.hidden = false;
    document.documentElement.classList.add('kp-kilit');
    girdi.value = '';
    ciz('');
    dersleriYukle();
    girdi.focus();
  }

  function kapat() {
    if (!acik) return;
    acik = false;
    kok.hidden = true;
    document.documentElement.classList.remove('kp-kilit');
    if (oncekiOdak && oncekiOdak.focus) oncekiOdak.focus();   /* odagi geri ver */
  }

  function git(yol) { if (yol) location.href = yol; }

  /* ---- KLAVYE --------------------------------------------------------------
     Ctrl+K her yerden acar. Kullanici bir metin kutusuna yaziyorsa
     kisayol yine calisir (Ctrl+K yazi yazarken kullanilan bir tus degil),
     ama tek basina "/" gibi bir kisayol koymuyoruz - o, form doldururken
     kullaniciyi bogar.                                                     */
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
      e.preventDefault();
      acik ? kapat() : ac();
      return;
    }
    if (!acik) return;

    if (e.key === 'Escape') { e.preventDefault(); kapat(); return; }
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (!sonuc.length) return;
      secili = (secili + (e.key === 'ArrowDown' ? 1 : -1) + sonuc.length) % sonuc.length;
      imle();
      return;
    }
    if (e.key === 'Home') { e.preventDefault(); secili = 0; imle(); return; }
    if (e.key === 'End')  { e.preventDefault(); secili = sonuc.length - 1; imle(); return; }
    if (e.key === 'Enter') {
      e.preventDefault();
      if (sonuc[secili]) git(sonuc[secili].yol);
      return;
    }
    /* Tab tuzagi: palet acikken odak disari kacmasin. Icinde tek odaklanabilir
       oge var (girdi), o yuzden Tab'i girdiye geri baglamak yeterli. */
    if (e.key === 'Tab') { e.preventDefault(); girdi.focus(); }
  });

  /* ---- ACMA DUGMESI --------------------------------------------------------
     Kisayolu bilmeyen de gorsun diye. Dokunmatik cihazda klavye yok, orada
     dugme tek yoldur; bu yuzden dugme her zaman durur.                     */
  function dugmeKur() {
    if (document.querySelector('.kp-dugme')) return;          /* iki kez kurulmasin */

    /* Sitede iki ayri ust yapi var (olculdu 24.08): ana sayfada nav.navlinks,
       45 arac sayfasinda .top seridi. 12 sayfada hicbiri yok - oralarda dugme
       KONMAZ, kisayol yine calisir. Yazdirilan sayfalara da dugme konmaz. */
    var yer = document.querySelector('[data-komut-dugme]') ||
              document.querySelector('nav .navlinks') ||
              document.querySelector('.top');
    if (!yer) return;

    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'kp-dugme';
    b.setAttribute('aria-keyshortcuts', 'Control+K');
    b.innerHTML = '<span>Ara</span><kbd>Ctrl</kbd><kbd>K</kbd>';
    b.addEventListener('click', ac);

    if (yer.classList.contains('top')) yer.appendChild(b);    /* serit: sona */
    else yer.insertBefore(b, yer.firstChild);                 /* nav: basa */
  }

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', dugmeKur);
  else dugmeKur();

  /* disaridan da acilabilsin (ornegin sayfa icindeki bir baglantidan) */
  window.TetikteKomut = { ac: ac, kapat: kapat };
})();
