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
  var KONULAR = [
    ['Gümrük ve ithalat', [
      ['GTİP · Kaç vergi öderim?', 'gtip.html', 'gtip tarife gumruk vergi ithalat kod'],
      ['Beyanname risk taraması', 'risk-taramasi.html', 'beyanname ceza risk gumruk'],
      ['Nereden alsam?', 'senaryo-raporu.html', 'mense ulke karsilastirma tedarik'],
      ['Toplu GTİP kontrolü', 'toplu-gtip.html', 'excel toplu liste gtip'],
      ['Credit / Debit Note', 'fiyatfarki.html', 'fiyat farki sonradan gelen fatura'],
      ['Yurt dışı hizmet faturası', 'hizmet.html', 'stopaj 2 nolu kdv yurtdisi yazilim']
    ]],
    ['Vergi ve ceza', [
      ['Ceza Asistanı', 'ceza-asistani.html', 'ceza uzlasma indirim dava vuk'],
      ['KDV iade rehberi', 'kdv-iade-rehberi.html', 'kdv iade istisna mahsup'],
      ['Asgari kurumlar vergisi', 'asgari-kv.html', 'asgari kurumlar vergisi yuzde 10'],
      ['Eşik rehberi', 'sayfalar/index.html', 'esik calisan sayisi ciro zorunluluk'],
      ['Net Cevap', 'soru-cevap.html', 'soru sor cevap madde mevzuat'],
      ['Bilgi Havuzu', 'bilgi.html', 'ozet konu anlatim kaynak']
    ]],
    ['Şirket kuruluşu', [
      ['Şirket kuruluşu rehberi', 'kurulus.html', 'sahis limited anonim kurulus tur'],
      ['Kuruluş evrak çantası', 'kurulus-evrak.html', 'evrak belge kurulus dilekce'],
      ['Yükümlülük karnesi', 'karne.html', 'karne yukumluluk firma profil']
    ]],
    ['Teşvik ve destek', [
      ['Yatırım teşvik sihirbazı', 'tesvik-sihirbazi.html', 'tesvik yatirim belge 9903 il sektor'],
      ['Ar-Ge kapısı hesabı', 'arge-kapi-hesabi.html', 'arge merkez teknokent tubitak 5746 4691'],
      ['Destek Radarı', 'destekler.html', 'kosgeb hibe destek cagri eximbank']
    ]],
    ['İhale', [
      ['İhale Radarı', 'ihale-radari.html', 'ihale ekap ted ilan kamu'],
      ['Rakip firma analizi', 'firma-analizi.html', 'rakip firma ihale gecmis'],
      ['İdare analizi', 'idare-analizi.html', 'idare kurum ihale istatistik']
    ]],
    ['Marka', [
      ['Marka Radarı', 'marka-radari.html', 'marka yenileme turkpatent'],
      ['Marka itiraz ve benzerlik', 'marka-itiraz.html', 'itiraz benzerlik marka smk'],
      ['Marka izleme radarı', 'marka-izleme.html', 'izleme benzer basvuru marka'],
      ['Marka portföyü', 'marka-portfoy.html', 'portfoy marka liste'],
      ['Markanla ne yapabilirsin', 'marka-varlik.html', 'lisans devir rehin marka varlik']
    ]],
    ['Alacak ve risk', [
      ['Alacak Radarı', 'alacak-radari.html', 'konkordato iflas alacak musteri risk'],
      ['İcradan fırsat', 'radar-app.html?niyet=firsat', 'icra satis makine stok firsat']
    ]],
    ['Mevzuat nöbeti', [
      ['Bugün Resmî Gazete\'de', 'radar.html', 'resmi gazete rg degisiklik bugun'],
      ['Günün hap kartları', 'kartlar.html', 'hap kart ozet gunluk'],
      ['Süre hatırlatıcı', 'hatirlatici.html', 'sure tarih hatirlatma diib kdv sgk']
    ]],
    ['Büro ve evrak', [
      ['Fiş Fabrikası', 'fis-fabrikasi.html', 'fis luca ekstre muhasebe kayit musavir smmm buro'],
      ['Evrak Radarı', 'evrak-radari.html', 'evrak mukellef takip musavir smmm buro'],
      ['Belge Kasası', 'belge-kasasi.html', 'belge kasa sure takip arsiv musavir buro']
    ]],
    ['SMMM sınavları', [
      ['Sınav takvimi ve soru bankası', 'genc.html', 'sgs staja giris yeterlilik sinav takvim ogrenci stajyer aday musavir smmm'],
      ['Deneme sınavı', 'deneme.html', 'deneme soru test cozum ogrenci stajyer sinav'],
      ['Canlı deneme', 'canli-deneme.html', 'canli deneme yuzdelik siralama ogrenci sinav'],
      ['Dönem planı', 'donem-plani.html', 'plan calisma program hafta ogrenci sinav'],
      ['Son gün 5 saat', 'songun.html', 'son gun tekrar sinav sabahi ogrenci']
    ]],
    ['Hesap ve sayfalar', [
      ['Müşavir paneli', 'radar-app.html?niyet=musavir', 'musavir smmm buro panel coklu mukellef'],
      ['Giriş / üye ol', 'radar-app.html', 'giris uye kayit hesap oturum'],
      ['Fiyatlar ve paketler', 'fiyat.html', 'fiyat paket abonelik ucret kac para maliyet'],
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
                 'spellcheck="false" placeholder="Ara: marka, ceza, GTİP kodu, sınav…">' +
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
      liste.innerHTML = '<li class="kp-yok">Eşleşme yok. Katalogda aramayı dene.</li>';
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
