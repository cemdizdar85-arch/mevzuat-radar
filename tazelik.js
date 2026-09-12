/* ============================================================================
   TAZELİK — tazelik iddiası kuran her sayfanın paylaştığı tazeleme motoru
   12.09.2026, Cem "1.2.3 üçünü de yap"

   NİYE VAR (ölçülmüş arıza, tahmin değil):
   Ana sayfadaki Nöbetçi kutusu "son robot koşusu 07.09 — 5 gün önce" yazıp
   KIRMIZI yanıyordu. Robot hiç gün atlamamıştı: veri/uyari-ozet.json damga izi
   04.09–12.09 arası günde iki koşu, boşluk yok; canlı dosya 12.09 09:20'ydi.
   Cem'in ekranındaki gövde 07.09 21:49'du — parmak izi "2 değişiklik"
   (rg_karti=2 YALNIZ 5eef7e5f commit'inde; canlıda 1, HTML yedeğinde 3).

   KÖK NEDEN: sayfa veriyi açılışta BİR KEZ çekiyordu (ne setInterval, ne
   visibilitychange, ne pageshow) ama bayatlık hükmünü O ANKI SAATLE kuruyordu.
   Tarayıcıda kalmış eski bir kopya bugünün saatiyle kıyaslanınca "5 gün önce"
   yazıyor ve robotu suçluyordu. Sağlam bir robota iftira atmak, bozuk veriden
   pahalıdır: güven yalnız kutuya değil verinin tamamına kaybedilir.

   KURAL: İDDİA İLE KANIT AYNI ANDA TAZELENİR.

   Bu dosya o kuralın TEK uygulaması. Dördüncü sayfada dördüncü kez elle
   yazılırsa dördüncü kez aynı hata çıkar; onun için ortak.
   Mekanik bekçisi: arac/tazelik-kapisi.js (CI'da koşar).

   KULLANIM
   --------
     Tazelik.kur({
       ad: 'nöbet kutusu',              // teşhis adı (zorunlu)
       cek: function(){ ... },           // veriyi çeken işlev (zorunlu)
       aralik: 600000                    // ms, varsayılan 10 dk (istege bagli)
     });

   `cek` içinde URL'ler Tazelik.url() ile sarılır:
     fetch(Tazelik.url('veri/uyari-ozet.json'), {cache:'no-store'})

   NİYE `cek`'i sayfa veriyor: her sayfanın hata toleransı farklı. durum.html
   dokuz raporu AYRI AYRI karşılıyor (biri yoksa tablo boş kalmaz), ana sayfa
   tek dosya okuyor. Promise.all'ü buraya gömmek durum.html'i bozardı.
   Motor yalnız NE ZAMAN çekileceğini yönetir; NASIL çekileceğini sayfa bilir.
   ============================================================================ */
(function(){
  'use strict';

  var KAYIT = [];
  var FREN  = 30000;   /* focus + visibilitychange birlikte gelirse tek çekim */

  function cek(k, zorla){
    var ms = Date.now();
    if(!zorla && (ms - k.sonCekim) < FREN) return;
    k.sonCekim = ms;
    try { k.cek(); }
    catch(h){ if(window.console && console.warn) console.warn('Tazelik/' + k.ad, h); }
  }

  function hepsi(zorla){
    for(var i=0;i<KAYIT.length;i++){ cek(KAYIT[i], zorla); }
  }

  window.Tazelik = {
    /* ÖNBELLEK KIRICI. cache:'no-store' YETMİYOR — 07.09 gövdesi beş gün
       bunun yokluğunda yaşadı. Damga dosyaları küçük; her çekimde tek
       istek, ölçülen bedel yok. */
    url: function(y){
      return y + (y.indexOf('?') < 0 ? '?' : '&') + 't=' + Date.now();
    },

    kur: function(a){
      if(!a || typeof a.cek !== 'function'){
        if(window.console) console.error('Tazelik.kur: cek işlevi zorunlu');
        return null;
      }
      var k = { ad: a.ad || '(adsız)', cek: a.cek, aralik: a.aralik || 600000, sonCekim: 0 };
      KAYIT.push(k);
      cek(k, true);
      setInterval(function(){ if(!document.hidden) cek(k, true); }, k.aralik);
      return k;
    },

    /* ÇEKİM DÜŞERSE SUÇ ROBOTTA DEĞİL SAYFADA ARANIR. Eskiden sessizce
       HTML'deki eski değer kalıyordu; ziyaretçi eski sayıyı TAZE sanıyordu. */
    dusme: function(oge, metin){
      var e = (typeof oge === 'string') ? document.getElementById(oge) : oge;
      if(!e) return;
      e.textContent = metin || 'Bu sayfadaki sayılar tazelenemedi — sayfayı yenile.';
      e.classList.add('nd-bayat');
    },

    /* KIRMIZI GERİ ALINABİLİR OLMAK ZORUNDA: tazeleme eklendiği için aynı
       sayfa ikinci kez ölçüyor. Veri tazeye döndüyse bayat satırı SİLİNİR,
       yoksa düzelen robot ekranda hâlâ bozuk görünür. */
    duzeldi: function(oge, ilkMetin){
      var e = (typeof oge === 'string') ? document.getElementById(oge) : oge;
      if(!e) return;
      if(typeof ilkMetin === 'string') e.textContent = ilkMetin;
      e.classList.remove('nd-bayat');
    }
  };

  /* sekmeye dönüş · pencereye odak · bfcache'ten geri gelme */
  document.addEventListener('visibilitychange', function(){ if(!document.hidden) hepsi(false); });
  window.addEventListener('focus', function(){ hepsi(false); });
  window.addEventListener('pageshow', function(e){ if(e.persisted) hepsi(true); });
})();
