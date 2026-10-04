/* calisma-ozet.js — 03.10.2026 (Cem, V2 madde 6-7-10-11-15 "hepsini yap")
   Panelin "Şimdi bunu yap" kartı, "Son durum" sayıları ve Yanlışlarım sayfası TEK yerden okur.

   KAYNAK (ölçüldü 03.10, yeni veri toplanmaz):
     kc_kayit  — ders sayfalarının son 500 cevabı {id,konu,ders,dogru,t}   (kaydir-coz şablonu cevapKaydet)
     kc_kutu   — yanlış kutusu {id,konu,ders,tur,due,yanlis}                (2 gün sonra vade, o gün doğruysa 7 gün)
     kc_ileri  — şablonun ileri sarma kaydırması (ms)
     sv_sonuclar / sv_sonuclar_yet — seviye testi geçmişi {gecme,gruplar:[{ad,dogru,soru}],tarih}
   Hepsi BU TARAYICIDA durur; üyeyse ilerleme-web.js hesaba taşır. Sayılar "son 500 cevap" diye yazılır.
   veri/soru-dizini.json — ders adı -> ders sayfası (kaydir/sgs/<ders>.html).

   Bu dosya hiçbir şeyi DOM'a yazmaz; sayfalar ttCalisma.ozet() / ttCalisma.oneri() çağırır.
   GÖRMEZ: başka cihazda çözülüp hesaba taşınmamış cevaplar; deneme.html'in cevap_kaydi tablosu. */
(function(){
  'use strict';
  var GUN = 86400000;
  function oku(k, v){ try{ var x = JSON.parse(localStorage.getItem(k) || 'null'); return x == null ? v : x; }catch(e){ return v; } }
  function kucuk(s){ return String(s || '').toLocaleLowerCase('tr-TR').replace(/\s+/g, ' ').trim(); }

  var __dizin = null;
  function dizin(){
    if(!__dizin){
      __dizin = fetch('veri/soru-dizini.json', { cache:'no-store' })
        .then(function(r){ return r.ok ? r.json() : null; })
        .catch(function(){ return null; });
    }
    return __dizin;
  }
  /* ders adı -> {ad, sayfa, sinav}. Birebir ad, olmazsa içerme. Bulunamazsa null (sayfa sınav listesine düşer). */
  function dersBul(d, ad){
    if(!d || !d.sinavlar || !ad) return null;
    var a = kucuk(ad), ilk = null;
    d.sinavlar.forEach(function(s){
      if(s.durum !== 'acik') return;
      (s.dersler || []).forEach(function(x){
        if(!x.sayfa) return;
        var b = kucuk(x.ad);
        if(!ilk && b === a) ilk = { ad:x.ad, sayfa:x.sayfa, sinav:s.kod };
      });
    });
    if(ilk) return ilk;
    d.sinavlar.forEach(function(s){
      if(s.durum !== 'acik') return;
      (s.dersler || []).forEach(function(x){
        if(!x.sayfa || ilk) return;
        var b = kucuk(x.ad);
        if(b.length > 3 && (a.indexOf(b) > -1 || b.indexOf(a) > -1)) ilk = { ad:x.ad, sayfa:x.sayfa, sinav:s.kod };
      });
    });
    return ilk;
  }

  function ozet(){
    var kayit = oku('kc_kayit', []), kutu = oku('kc_kutu', []), ileri = parseInt(localStorage.getItem('kc_ileri') || '0') || 0;
    if(!Array.isArray(kayit)) kayit = []; if(!Array.isArray(kutu)) kutu = [];
    var an = Date.now() + ileri;
    var dogru = kayit.filter(function(x){ return x && x.dogru; }).length;
    var vadeli = kutu.filter(function(x){ return x && x.due <= an; });
    /* konu ve ders başına doğruluk (en az 3 cevap) */
    var konu = {}, ders = {};
    kayit.forEach(function(x){
      if(!x) return;
      var k = (x.ders || '') + '|' + (x.konu || '');
      if(!konu[k]) konu[k] = { ders:x.ders || '', konu:x.konu || '', soru:0, dogru:0 };
      konu[k].soru++; if(x.dogru) konu[k].dogru++;
      var d = x.ders || '';
      if(!ders[d]) ders[d] = { ders:d, soru:0, dogru:0 };
      ders[d].soru++; if(x.dogru) ders[d].dogru++;
    });
    var oran = function(o){ return o.soru ? o.dogru / o.soru : 0; };
    var zorKonu = Object.keys(konu).map(function(k){ return konu[k]; })
      .filter(function(o){ return o.soru >= 3 && o.konu; })
      .sort(function(a, b){ return oran(a) - oran(b) || b.soru - a.soru; });
    var dersler = Object.keys(ders).map(function(k){ return ders[k]; }).filter(function(o){ return o.ders && o.soru >= 3; })
      .sort(function(a, b){ return oran(b) - oran(a); });
    /* kutu: ders başına bekleyen / vadesi gelen */
    var kutuDers = {};
    kutu.forEach(function(x){
      if(!x) return; var d = x.ders || 'Diğer';
      if(!kutuDers[d]) kutuDers[d] = { ders:d, toplam:0, bugun:0, enYakin:null };
      kutuDers[d].toplam++;
      if(x.due <= an) kutuDers[d].bugun++;
      else if(!kutuDers[d].enYakin || x.due < kutuDers[d].enYakin) kutuDers[d].enYakin = x.due;
    });
    var sv = oku('sv_sonuclar', []); if(!Array.isArray(sv)) sv = [];
    var svYet = oku('sv_sonuclar_yet', []); if(!Array.isArray(svYet)) svYet = [];
    return {
      cozulen: kayit.length, dogru: dogru, yanlis: kayit.length - dogru,
      dogruYuzde: kayit.length ? Math.round(100 * dogru / kayit.length) : null,
      kutuToplam: kutu.length, vadeli: vadeli.length,
      kutuDers: Object.keys(kutuDers).map(function(k){ return kutuDers[k]; }).sort(function(a, b){ return b.bugun - a.bugun || b.toplam - a.toplam; }),
      zorKonu: zorKonu.slice(0, 5),
      gucluDers: dersler.length ? dersler[0] : null,
      zayifDers: dersler.length ? dersler[dersler.length - 1] : null,
      sonSeviye: sv.length ? sv[sv.length - 1] : null,
      sonSeviyeYet: svYet.length ? svYet[svYet.length - 1] : null,
      /* 04.10 günlük görev (Cem "beş maddeyi yapalım", rakip BPP): bugün (yerel gün) çözülen cevap sayısı */
      bugunCozulen: kayit.filter(function(x){ return x && x.t && new Date(x.t).toDateString() === new Date(an).toDateString(); }).length,
      an: an
    };
  }

  /* "Şimdi bunu yap" — tek öneri. Sıra: vadesi gelen tekrar > en zor konu > seviye testindeki en zayıf ders > seviye testi.
     cb({baslik, metin, dugme, adres}) */
  function oneri(cb){
    var o = ozet();
    dizin().then(function(d){
      var sonuc;
      if(o.vadeli > 0){
        var ilk = o.kutuDers.filter(function(x){ return x.bugun > 0; })[0];
        var b = ilk ? dersBul(d, ilk.ders) : null;
        sonuc = { baslik:'Bugün tekrar zamanı', metin:'Yanlış kutunda vadesi gelen ' + o.vadeli + ' soru var' + (ilk && ilk.ders ? ' (en çok ' + ilk.ders + ')' : '') + '. Ders sayfasında 📥 yanlış kutusunu açıp "Şimdi çöz"e bas.',
                  dugme:'Tekrar et', adres: b ? b.sayfa : 'yanlislarim.html' };
      } else if(o.zorKonu.length && o.zorKonu[0].dogru / o.zorKonu[0].soru < 0.6){
        var z = o.zorKonu[0], zb = dersBul(d, z.ders);
        sonuc = { baslik:'Şimdi bunu yap', metin:(z.ders ? z.ders + ' / ' : '') + z.konu + ': son ' + z.soru + ' cevabının ' + z.dogru + ' tanesi doğru. Bu dersten 10 soru çöz, yaklaşık 15 dakika.',
                  dugme:'Başla', adres: zb ? zb.sayfa : 'sorular.html' };
      } else {
        var sv = o.sonSeviye || o.sonSeviyeYet;
        var gr = sv && Array.isArray(sv.gruplar) ? sv.gruplar.filter(function(g){ return g && g.soru; }) : [];
        if(gr.length){
          gr.sort(function(a, b){ return a.dogru / a.soru - b.dogru / b.soru; });
          var g = gr[0], gb = dersBul(d, g.ad);
          sonuc = { baslik:'Şimdi bunu yap', metin:'Son seviye testinde en zayıf alanın ' + g.ad + ' (' + g.dogru + '/' + g.soru + '). Bugün oradan 10 soru çöz, yaklaşık 15 dakika.',
                    dugme:'Başla', adres: gb ? gb.sayfa : 'sorular.html' };
        } else {
          sonuc = { baslik:'Şimdi bunu yap', metin:'30 soruluk seviye testini çöz; hangi derste ne kadar hazır olduğunu gör, sonra sana nereden başlayacağını söyleyelim.',
                    dugme:'Seviye testine başla', adres:'seviye-testi.html' };
        }
      }
      try{ cb(sonuc, o); }catch(e){}
    });
  }

  function tarihYazi(ms){
    if(!ms) return '';
    var gun = Math.ceil((ms - Date.now()) / GUN);
    if(gun <= 0) return 'bugün';
    if(gun === 1) return 'yarın';
    return gun + ' gün sonra';
  }

  window.ttCalisma = { ozet:ozet, oneri:oneri, dizin:dizin, dersBul:dersBul, tarihYazi:tarihYazi };
})();
