/* paket-kartlari.js — 28.10.2026 Cem ("tüm fiyatlar sekmesi ilk sayfadaki gibi olsun, nerede fiyat göster varsa"):
   paket kartlarının TEK kaynağı. index.html ve fiyat.html aynı kartları, aynı rakamı, aynı süzgeci kullanır; kart içeriği ya da
   fiyat yazımı yalnız burada değişir. Rakamlar fiyat-motoru.js'ten (önce o yüklenir). Biçim: paket-kartlari.css.
   Kullanım: <section id="paketler"> içinde <p id="paketBas"> + <div class="pk-kartlar" data-pk-kartlar></div>;
   PaketKartlari.kur() bir kez, PaketKartlari.suz('sgs'|'yeterlilik'|'kgk') her sınav seçiminde. */
(function(){
  /* 17.10 SGS Tam Paket + 28.10 Sadece 7 Deneme · 18.10 Yeterlilik ders sayısı seçicili kart · 28.10 Yeterlilik Son 20 Gün
     (son20-yet, 8 Kasım = 28 Kasım − 20; kalan gün [data-yet20-gun]). Üstü çizili fiyat YOK (25.09 kararı).
     28.10 Cem şart onayı: Yeterlilik kartlarında ders ders devam sözü satırları (kampanya-son-20-gun.html 5. madde). */
  var KARTLAR =
    '<article class="pk-kart" data-paket="sgs"><p class="pk-sinav">SMMM Staja Giriş</p><h3>Tam Paket</h3>'
  + '<p class="pk-fiyat" data-fiyat>—</p><p class="pk-alt" data-dahil></p>'
  + '<ul><li>Sınırsız soru: bankanın tamamı</li><li>Son 20 Gün: 7 deneme + konu görevleri</li><li>Her sorunun dayandığı madde altında yazar</li></ul>'
  + '<a class="pk-al" href="satin-al.html?paket=sgs">Satın al</a><p class="pk-sonra" data-sonra></p></article>'
  + '<article class="pk-kart" data-paket="son20-sgs"><p class="pk-sinav">SMMM Staja Giriş · Son 20 Gün</p><h3>Sadece 7 Deneme</h3>'
  + '<p class="pk-fiyat" data-fiyat>—</p><p class="pk-alt" data-dahil></p>'
  + '<ul><li>7 deneme, ders ders testler</li><li>Konu görevleri ve açıklamalar</li><li>Kalırsan sonraki dönemin Son 20 Gün paketi ücretsiz</li></ul>'
  + '<a class="pk-al" href="satin-al.html?paket=son20-sgs">Şimdi kaydol · 1 Kasım\'da başla</a><p class="pk-sonra" data-sonra></p></article>'
  + '<article class="pk-kart" data-paket="yeterlilik-1"><p class="pk-sinav">SMMM Yeterlilik</p><h3>Seçtiğin dersler</h3>'
  + '<div class="pk-ders" role="group" aria-label="Kaç ders seçiyorsun?"><button type="button" data-n="1" aria-pressed="true">1 ders</button><button type="button" data-n="2" aria-pressed="false">2 ders</button><button type="button" data-n="3" aria-pressed="false">3 ders</button><button type="button" data-n="4" aria-pressed="false">4 ders</button></div>'
  + '<p class="pk-fiyat" data-fiyat>—</p><p class="pk-alt" data-dahil></p>'
  + '<ul><li>Yalnız kaldığın sınav dersleri</li><li>Son 20 Gün: seçtiğin her dersin 5 denemesi</li><li>Kalırsan o ders geçene kadar ücretsiz</li></ul>'
  + '<a class="pk-al" href="satin-al.html?paket=yeterlilik-1">Satın al</a><p class="pk-sonra" data-sonra></p></article>'
  + '<article class="pk-kart pk-one" data-paket="yeterlilik-tum"><p class="pk-sinav">SMMM Yeterlilik</p><h3>Tüm dersler</h3>'
  + '<p class="pk-fiyat" data-fiyat>—</p><p class="pk-alt" data-dahil></p>'
  + '<ul><li>Sınırsız soru: sekiz dersin tamamı</li><li>Son 20 Gün: 8 ders × 5 deneme</li><li>Kalırsan kaldığın dersler geçene kadar ücretsiz</li></ul>'
  + '<a class="pk-al" href="satin-al.html?paket=yeterlilik-tum">Satın al</a><p class="pk-sonra" data-sonra></p></article>'
  + '<article class="pk-kart" data-paket="son20-yet"><p class="pk-sinav">SMMM Yeterlilik · Son 20 Gün</p><h3>Sadece Denemeler</h3>'
  + '<p class="pk-fiyat" data-fiyat>—</p><p class="pk-alt" data-dahil></p>'
  + '<ul><li>8 dersin her birinde 5 deneme</li><li>Konu görevleri ve açıklamalar</li><li>Kalırsan sonraki dönemin Son 20 Gün paketi ücretsiz</li></ul>'
  + '<a class="pk-al" href="satin-al.html?paket=son20-yet">Satın al · 8 Kasım\'da başla</a><p class="pk-sonra" data-yet20-gun></p></article>';

  function tlx(n){ return typeof tl === 'function' ? tl(n) : String(n); }

  /* kart çizimi (17.10 ana sayfadan taşındı): ana rakam + KDV yazımı, erken kayıt, ön satış */
  function ciz(k){
    var p = paketBul(k.getAttribute('data-paket')); if(!p){ k.hidden = true; return; }
    var hr = KDV_HARIC_GOSTER[p.id], a = k.querySelector('.pk-al');
    if(p.id === 'son20-sgs' || p.id === 'son20-yet'){   /* Son 20 Gün kartları KDV dahil (kampanya kartlarıyla aynı dil) */
      k.querySelector('[data-fiyat]').innerHTML = tlx(p.fiyat) + ' <small>TL</small>';
      k.querySelector('[data-dahil]').textContent = 'KDV dahil · ' + kdvHaric(p.fiyat) + ' TL + KDV · denemeler ' + (p.id === 'son20-yet' ? '8' : '1') + ' Kasım\'da açılır';
      var ds = k.querySelector('[data-sonra]'); if(ds) ds.innerHTML = ''; return;
    }
    if(typeof erkenYetInd === 'function' && erkenYetInd(p.id)){   /* Yeterlilik erken kayıt (tüm + ders ders) */
      var yn = erkenNet(p);
      k.querySelector('[data-fiyat]').innerHTML = kdvHaric(yn) + ' <small>TL + KDV</small>';
      k.querySelector('[data-dahil]').textContent = 'KDV dahil ' + tlx(yn) + ' TL · ' + tlx(p.fiyat) + ' TL yerine · 7 Kasım 23:59\'a kadar erken kayıt';
      k.querySelector('[data-sonra]').innerHTML = '';
      a.textContent = 'Satın al'; a.setAttribute('href', 'satin-al.html?paket=' + p.id); a.removeAttribute('aria-disabled');
      return;
    }
    /* 28.10 Cem ("burada 2388 yazıyor başka yerde farklı fiyatlar"): erken kayıtta SGS Tam Paketin TEK büyük rakamı KDV dahil */
    if(p.id === 'sgs' && typeof erkenKayitAcik === 'function' && erkenKayitAcik()){
      var ek = p.fiyat - ERKEN_KAYIT.indirim;
      k.querySelector('[data-fiyat]').innerHTML = tlx(ek) + ' <small>TL</small>';
      k.querySelector('[data-dahil]').textContent = 'KDV dahil · ' + tlx(p.fiyat) + ' TL yerine · ' + kdvHaric(ek) + ' TL + KDV · 1 Kasım 23:59\'a kadar';
      k.querySelector('[data-sonra]').innerHTML = '';
      a.textContent = 'Satın al'; a.setAttribute('href', 'satin-al.html?paket=sgs'); a.removeAttribute('aria-disabled');
      return;
    }
    k.querySelector('[data-fiyat]').innerHTML = hr ? tlx(Math.round(p.fiyat / (1 + KDV_ORAN))) + ' <small>TL + KDV</small>' : tlx(p.fiyat) + ' <small>TL</small>';
    k.querySelector('[data-dahil]').textContent = (hr ? fiyatDahilNot(p.id, p.fiyat) : '') + (p.kota && p.liste > p.fiyat ? (hr ? ' · ' : '') + 'açılış fiyatı · ilk ' + tlx(p.kota) + ' üye' : '');
    k.querySelector('[data-sonra]').innerHTML = p.liste > p.fiyat ? (p.kota ? 'İlk ' + tlx(p.kota) + ' üyeden sonra ' : 'Sonra ') + fiyatAnaHtml(p.id, p.liste) + fiyatDahilHtml(p.id, p.liste) : '';
    if(!p.acik){ a.textContent = 'Yakında'; a.removeAttribute('href'); a.setAttribute('aria-disabled', 'true'); }
    else { a.textContent = 'Satın al'; a.setAttribute('href', 'satin-al.html?paket=' + p.id); a.removeAttribute('aria-disabled'); }
  }

  function sinavi(id){ return (id === 'sgs' || id === 'son20-sgs') ? 'sgs' : (id.indexOf('yeterlilik') === 0 || id === 'son20-yet') ? 'yeterlilik' : 'kgk'; }

  /* seçili sınavın kartları; başlık ve Yeterlilik Son 20 Gün kalan günü */
  function suz(sec){
    var bol = document.getElementById('paketler'); if(!bol) return; var gor = 0;
    [].forEach.call(bol.querySelectorAll('.pk-kart[data-paket]'), function(k){
      k.hidden = sinavi(k.getAttribute('data-paket')) !== sec; if(!k.hidden) gor++; });
    var g = bol.querySelector('[data-yet20-gun]');
    if(g){ var kal = Math.ceil((Date.parse('2026-11-08T00:00:00+03:00') - Date.now()) / 864e5);
      g.textContent = kal > 1 ? 'Açılışa ' + kal + ' gün var' : kal === 1 ? 'Yarın açılıyor' : 'Denemeler açıldı'; }
    bol.hidden = !gor;
    var b = document.getElementById('paketBas'); if(b) b.textContent = sec === 'yeterlilik' ? 'SMMM Yeterlilik paketleri' : 'SMMM Staja Giriş paketleri';
  }

  var kuruldu = false;
  function kur(){
    if(kuruldu) return; kuruldu = true;
    var kap = document.querySelector('[data-pk-kartlar]');
    if(kap && !kap.children.length) kap.innerHTML = KARTLAR;
    try{
      [].forEach.call(document.querySelectorAll('.pk-kart[data-paket]'), ciz);
      [].forEach.call(document.querySelectorAll('.pk-ders button'), function(b){ b.addEventListener('click', function(){
        var k = b.closest('.pk-kart'); k.setAttribute('data-paket', 'yeterlilik-' + b.getAttribute('data-n'));
        [].forEach.call(k.querySelectorAll('.pk-ders button'), function(x){ x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); });
        ciz(k);
      }); });
    }catch(e){}
  }

  window.PaketKartlari = { kur:kur, suz:suz, ciz:ciz };
  /* betik sayfa sonunda yüklenir: kap varsa hemen kur (sayfanın süzgeci suz'u ilk çizimde çağırabilsin) */
  if(document.querySelector('[data-pk-kartlar]')) kur(); else document.addEventListener('DOMContentLoaded', kur);
})();
