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
  /* 07.10: sinav ('sgs'|'smmm') verilirse yalnız o sınavda arar — Finansal Muhasebe / Maliyet / Meslek Hukuku iki sınavda da var,
     verilmezse eski davranış (ilk açık sınav). */
  function dersBul(d, ad, sinav){
    if(!d || !d.sinavlar || !ad) return null;
    var a = kucuk(ad), ilk = null;
    if(sinav) d = { sinavlar: d.sinavlar.filter(function(s){ return s.kod === sinav; }) };
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

  /* 07.10 NÖBETÇİ PLANI (Cem "1 ve 2 yap"): sınava kalan güne göre evre. Günlük görevin büyüklüğü ve "Şimdi bunu yap"
     sırası evreye bağlı. Sayılar (tekrar tavanı, yeni soru) bizim önerimizdir, sınav iddiası değildir.
     Son 3 gün ayrı sayfaya gitmez (songun.html gizli, site oturumu 07.10): içerik Hesabım'da = tekrar + sık çıkan konudan kısa set. */
  function evre(gun){
    if(gun == null || isNaN(gun) || gun < 0) return null;
    if(gun <= 3) return { kod:'songun', ad:'Son günler', tekrarTavan:9999, yeni:0, sik:15,
      metin:'Yeni konu açma. Yanlış kutunda ne varsa bitir, sonra en sık çıkan konulardan kısa bir set çöz.' };
    if(gun <= 15) return { kod:'hiz', ad:'Son 15 gün', tekrarTavan:40, yeni:30,
      metin:'Tempo arttı: her gün tekrar + 30 yeni soru, haftada en az bir sınav gibi deneme.' };
    if(gun <= 30) return { kod:'pekistir', ad:'Pekiştirme', tekrarTavan:30, yeni:20,
      metin:'Son ay: zayıf konularına dön, günlük yeni soru sayısı artıyor.' };
    return { kod:'yay', ad:'Konu yayma', tekrarTavan:20, yeni:10,
      metin:'Her gün yeni bir konuya dokun. Henüz hiç başlamadıkların aşağıda.' };
  }

  /* Bu kayıt Yeterlilik sorusu mu? Kimlik smmm-banka-esleme'de ya da "smmm-" önekli. Kalan = SGS.
     🚫 GÖRMEZ: öneksiz bir Yeterlilik kimliği (07.10'da eşlemede yok) SGS sayılır. */
  function yetMi(x, es){ var id = String(x && x.id || ''); return !!(es && es[id]) || /^smmm-/.test(id); }

  /* 07.10 "Hiç dokunmadığın konular".
     Yeterlilik: konu = çıkmış soruların METNİ okunarak bağlandığı konu (veri/sinav/smmm-konu-okuma.json, dönem + soru no kanıtı);
       öğrencinin çözdüğü soru o konulara veri/sinav/smmm-banka-esleme.json ile bağlanır (anahtar = kc_kayit.id).
       Yalnız bankada en az 3 sorusu olan konu önerilir (çalışılabilsin).
     SGS: soru → okunmuş konu bağı YOK (ölçüldü 07.10: düzenli ifade eşlemesi yanlış eşleşiyor) → DERS düzeyinde; konu listesi
       en-cok-cikan-konular-sgs.html'e bağlanır.
     🚫 GÖRMEZ: son 500 cevaptan eskisi (kc_kayit tavanı) · başka cihazda çözülüp hesaba taşınmamış cevap · eşlemeden sonra
       yayına girmiş Yeterlilik sorusu (dokunulmuş sayılmaz) · deneme/seviye testinde çözülen soru.
     cb({ sinav, tur:'konu'|'ders', liste, toplamSik, dokunulanSik, pencere, donem }) ya da cb(null) */
  var __yetVeri = null;
  function yetVeri(){
    if(!__yetVeri){
      var al = function(u){ return fetch(u, { cache:'force-cache' }).then(function(r){ return r.ok ? r.json() : null; }); };
      __yetVeri = Promise.all([al('veri/sinav/smmm-konu-okuma.json'), al('veri/sinav/smmm-banka-esleme.json')])
        .catch(function(){ return [null, null]; });
    }
    return __yetVeri;
  }
  function dokunulmamis(sinav, cb){
    var kayit = oku('kc_kayit', []); if(!Array.isArray(kayit)) kayit = [];
    var bitir = function(x){ try{ cb(x); }catch(e){} };
    if(sinav === 'yeterlilik'){
      Promise.all([yetVeri(), dizin()]).then(function(r){
        var ok = r[0][0], es = r[0][1] && r[0][1].sorular, d = r[1];
        if(!ok || !es || !Array.isArray(ok.kararlar)) return bitir(null);
        var smmm = d && d.sinavlar ? d.sinavlar.filter(function(s){ return s.kod === 'smmm'; })[0] : null, sayfa = {};
        (smmm && smmm.dersler || []).forEach(function(x){ if(x.sayfa) sayfa[x.ad] = x.sayfa; });
        var K = {};
        ok.kararlar.forEach(function(x){
          var k = x.ders + '|' + x.konu, r2 = K[k] || (K[k] = { ders:x.ders, konu:x.konu, don:{}, kanit:[], banka:0, dokundu:false });
          r2.don[x.donem] = 1;
          if(!r2.kanit.some(function(z){ return z.donem === x.donem && z.soru === x.soru; })) r2.kanit.push({ donem:x.donem, soru:x.soru });
        });
        Object.keys(es).forEach(function(id){ var e = es[id]; (e.konular || []).forEach(function(k){ var r2 = K[e.ders + '|' + k]; if(r2) r2.banka++; }); });
        var cozulen = 0;
        kayit.forEach(function(x){ var e = x && es[x.id]; if(!e) return; cozulen++; (e.konular || []).forEach(function(k){ var r2 = K[e.ders + '|' + k]; if(r2) r2.dokundu = true; }); });
        var srt = function(z){ var p = String(z).split('/'); return +p[0] * 10 + +p[1]; };
        var hepsi = Object.keys(K).map(function(k){ var r2 = K[k], dn = Object.keys(r2.don).sort(function(a, b){ return srt(a) - srt(b); });
          r2.kanit.sort(function(a, b){ return srt(a.donem) - srt(b.donem) || String(a.soru).localeCompare(String(b.soru), 'tr', { numeric:true }); });
          return { ders:r2.ders, konu:r2.konu.replace(/ › /g, ' — '), donSay:dn.length, son:dn[dn.length - 1], kanit:r2.kanit, banka:r2.banka, dokundu:r2.dokundu, sayfa:sayfa[r2.ders] || 'sorular.html#smmm' };
        }).filter(function(z){ return z.banka >= 3; })
          .sort(function(a, b){ return b.donSay - a.donSay || srt(b.son) - srt(a.son); });
        /* "sık çıkan" = her dersin en sık 5 konusu (en-cok-cikan-konular-yeterlilik.html ile aynı ölçü) */
        var dersSay = {}, sik = hepsi.filter(function(z){ dersSay[z.ders] = (dersSay[z.ders] || 0) + 1; return dersSay[z.ders] <= 5; });
        bitir({ sinav:'yeterlilik', tur:'konu', cozulen:cozulen, pencere:ok.pencere, donem:ok.donem,
          toplamSik:sik.length, dokunulanSik:sik.filter(function(z){ return z.dokundu; }).length,
          liste:sik.filter(function(z){ return !z.dokundu; }).sort(function(a, b){ return b.donSay - a.donSay || srt(b.son) - srt(a.son); }).slice(0, 6) });
      }, function(){ bitir(null); });
      return;
    }
    /* SGS konu düzeyi (07.10 ikinci adım): veri/deneme/sgs-sik-kimlik.json — motor/sik-konu-deneme-bas.js'in "Sık çıkan konular
       denemesi" setlerini kurduğu AYNI bağ (okuma ifadesi kökte + DARALT + ders şartı), havuzun tamamı. Konu listesi ve dönem sayısı
       en-cok-cikan-konular-sgs.html ile aynı (Matematik hariç en sık 20). Dosya yoksa ders düzeyine düşer.
       🚫 GÖRMEZ (ek): ifadesi kökte geçmeyen ama konuyu ölçen soru dokunulmuş sayılmaz (havuz alt sınır). */
    var sgsKimlik = fetch('veri/deneme/sgs-sik-kimlik.json', { cache:'no-cache' }).then(function(r){ return r.ok ? r.json() : null; }).catch(function(){ return null; });
    Promise.all([dizin(), sgsKimlik]).then(function(rr){
      var d = rr[0], sk = rr[1], es = null;
      var sgs = d && d.sinavlar ? d.sinavlar.filter(function(s){ return s.kod === 'sgs'; })[0] : null;
      if(!sgs) return bitir(null);
      if(sk && Array.isArray(sk.konular) && sk.kimlik){
        var dok = {}, coz = 0;
        kayit.forEach(function(x){ var i = x && sk.kimlik[x.id]; if(i == null) return; coz++; dok[i] = 1; });
        var kl = sk.konular.map(function(k, i){ var b = dersBul(d, k.ders, 'sgs');
          return { ders:k.ders, konu:k.konu, donSay:k.donem, son:k.son, kanit:k.kanit || [], dokundu:!!dok[i], sayfa:b ? b.sayfa : 'sorular.html#sgs' }; });
        return bitir({ sinav:'sgs', tur:'konu', cozulen:coz, pencere:sk.pencere, donem:sk.donem, toplamSik:kl.length,
          dokunulanSik:kl.filter(function(z){ return z.dokundu; }).length, liste:kl.filter(function(z){ return !z.dokundu; }).slice(0, 6) });
      }
      var say = {}, cozulen = 0;
      kayit.forEach(function(x){ if(!x || yetMi(x, es)) return; cozulen++; var k = kucuk(x.ders); say[k] = (say[k] || 0) + 1; });
      var dersler = (sgs.dersler || []).filter(function(x){ return x.sayfa; });
      /* sıra: sınavdaki soru payı büyük olan önce (veri/soru-dizini.json sinav_soru; ekranda rakam olarak YAZILMAZ) */
      var liste = dersler.filter(function(x){ return !say[kucuk(x.ad)]; }).sort(function(a, b){ return (b.sinav_soru || 0) - (a.sinav_soru || 0); })
        .map(function(x){ return { ders:x.ad, sayfa:x.sayfa }; });
      bitir({ sinav:'sgs', tur:'ders', cozulen:cozulen, liste:liste, toplamSik:dersler.length, dokunulanSik:dersler.length - liste.length });
    }, function(){ bitir(null); });
  }

  /* "Şimdi bunu yap" — tek öneri. Sıra: vadesi gelen tekrar > en zor konu > (son 15 gün: haftalık deneme) >
     (son 3 gün: sık çıkan konudan kısa set) > seviye testindeki en zayıf ders > seviye testi.
     bag (isteğe bağlı) = { sinav:'sgs'|'yeterlilik', gun:<sınava kalan gün>, sonDeneme:<ms|null> }
     cb({baslik, metin, dugme, adres}, ozet, evre|null) */
  function oneri(cb, bag){
    var o = ozet();
    bag = bag || {};
    var ev = evre(bag.gun), yet = bag.sinav === 'yeterlilik', kod = bag.sinav ? (yet ? 'smmm' : 'sgs') : null;
    var sikSayfa = yet ? 'en-cok-cikan-konular-yeterlilik.html' : 'en-cok-cikan-konular-sgs.html';
    dizin().then(function(d){
      var sonuc;
      if(o.vadeli > 0){
        var ilk = o.kutuDers.filter(function(x){ return x.bugun > 0; })[0];
        var b = ilk ? dersBul(d, ilk.ders, kod) : null;
        sonuc = { baslik:'Bugün tekrar zamanı', metin:'Yanlış kutunda vadesi gelen ' + o.vadeli + ' soru var' + (ilk && ilk.ders ? ' (en çok ' + ilk.ders + ')' : '') + '. Ders sayfasında 📥 yanlış kutusunu açıp "Şimdi çöz"e bas.',
                  dugme:'Tekrar et', adres: b ? b.sayfa : 'yanlislarim.html' };
      } else if(o.zorKonu.length && o.zorKonu[0].dogru / o.zorKonu[0].soru < 0.6){
        var z = o.zorKonu[0], zb = dersBul(d, z.ders, kod);
        sonuc = { baslik:'Şimdi bunu yap', metin:(z.ders ? z.ders + ' / ' : '') + z.konu + ': son ' + z.soru + ' cevabının ' + z.dogru + ' tanesi doğru. Bu dersten 10 soru çöz, yaklaşık 15 dakika.',
                  dugme:'Başla', adres: zb ? zb.sayfa : 'sorular.html' };
      } else if(ev && ev.kod === 'hiz' && !yet && !(bag.sonDeneme && o.an - bag.sonDeneme < 7 * GUN)){
        /* sinav-gibi.html yalnız SGS'dir */
        sonuc = { baslik:'Bu hafta deneme zamanı', metin:'Sınava ' + bag.gun + ' gün kaldı ve son 7 günde bitirdiğin bir deneme yok. 130 soruluk sınav gibi denemeyi gerçek süreyle çöz.',
                  dugme:'Denemeye başla', adres:'sinav-gibi.html' };
      } else if(ev && ev.kod === 'songun'){
        sonuc = { baslik:'Son günler', metin:'Yanlış kutunda bugün sırası gelen soru yok. Yeni konu açma: en sık çıkan konular listesinden ilk konulara göz at, her birinden birkaç soru çöz (toplam ' + ev.sik + ' soru).',
                  dugme:'Sık çıkan konular', adres:sikSayfa };
      } else {
        var sv = o.sonSeviye || o.sonSeviyeYet;
        var gr = sv && Array.isArray(sv.gruplar) ? sv.gruplar.filter(function(g){ return g && g.soru; }) : [];
        if(gr.length){
          gr.sort(function(a, b){ return a.dogru / a.soru - b.dogru / b.soru; });
          var g = gr[0], gb = dersBul(d, g.ad, kod);
          sonuc = { baslik:'Şimdi bunu yap', metin:'Son seviye testinde en zayıf alanın ' + g.ad + ' (' + g.dogru + '/' + g.soru + '). Bugün oradan 10 soru çöz, yaklaşık 15 dakika.',
                    dugme:'Başla', adres: gb ? gb.sayfa : 'sorular.html' };
        } else {
          sonuc = { baslik:'Şimdi bunu yap', metin:'30 soruluk seviye testini çöz; hangi derste ne kadar hazır olduğunu gör, sonra sana nereden başlayacağını söyleyelim.',
                    dugme:'Seviye testine başla', adres:'seviye-testi.html' };
        }
      }
      try{ cb(sonuc, o, ev); }catch(e){}
    });
  }

  /* 07.10 (Cem "burası doğru çalışıyor mu"): gün farkı saat farkından (ceil) hesaplanıyordu -> aynı gün akşam vadesi gelen
     soru "yarın" yazıyordu; ders sayfasının zaman kaydırması (kc_ileri) da yoktu. Artık TAKVİM günü: bugün/yarın/N gün sonra. */
  function tarihYazi(ms){
    if(!ms) return '';
    var ileri = parseInt(localStorage.getItem('kc_ileri') || '0') || 0;
    var g0 = new Date(Date.now() + ileri); g0.setHours(0, 0, 0, 0);
    var g1 = new Date(ms); g1.setHours(0, 0, 0, 0);
    var gun = Math.round((g1 - g0) / GUN);
    if(gun <= 0){ var s = new Date(ms - ileri); return 'bugün, saat ' + ('0' + s.getHours()).slice(-2) + ':' + ('0' + s.getMinutes()).slice(-2) + ' sonrası'; }   /* ek yok: '13:00'ten/20:00'den' ses uyumu */
    if(gun === 1) return 'yarın';
    return gun + ' gün sonra';
  }

  window.ttCalisma = { ozet:ozet, oneri:oneri, dizin:dizin, dersBul:dersBul, tarihYazi:tarihYazi, evre:evre, dokunulmamis:dokunulmamis };
})();
