/* son20-kart.js — SON 20 GÜN KARTININ ORTAK VERİSİ (28.10.2026, Cem "Hesabım ve Soru çöz sadeleşsin, Son 20 Gün kartı eklensin")
 *
 * NEDEN: Son 20 Gün kartı yalnız sorular.html son20Ciz()'de ve yalnız "Sadece 7 Deneme" üyesine çiziliyordu (fed7c791). Tam Paket
 *   üyesi hiçbir sayfada Son 20 Gün'e bağlantı görmüyordu; görebildiği tek deneme "Toplu sınav"dı ve o söze SAYILMAZ.
 *   Kart artık tek yerden hesaplanır; Soru çöz (sorular.html), Hesabım (ogrenci.html) ve deneme sayfası (sinav-gibi.html) bunu okur.
 *
 * VERİ: SGS → sunucu s20_liste() (erişim + 7 denemenin ders ders ilk çözümü + çalışma görevleri). Deneme bitti = bütün ders testleri
 *   çözüldü; doğru oranı = toplam doğru / toplam soru (son-20-gun.html puan() ile AYNI hesap). Yeterlilik → sunucu verisi yok
 *   (son-20-gun.html yetCiz statik): kart yalnız açılış + söz şartı; uygunluğu çağıran sayfa söyler (paket bilgisi uye-durumu.js'te).
 * GÖRÜNÜR: SGS 21 Kasım 2026 sınav gününün sonuna, Yeterlilik 28 Kasım 2026'nın sonuna kadar (veri/sinav-takvimi.json).
 *   Söz metinleri son-20-gun.html #sozNot ile aynı; şart orada değişirse BURADA DA değişir.
 * 🚫 GÖRMEZ: Yeterlilik'te kişinin deneme ilerlemesi (sunucuda yok) · girişsiz ziyaretçi (kart çizilmez) · s20_liste hatası (kart
 *   çizilmez, sayfa olağan akar).
 */
(function(){
  var SINIR={ sgs:{ acilis:'2026-11-01T00:00:00+03:00', son:'2026-11-22T00:00:00+03:00', gun:'1' },
              yet:{ acilis:'2026-11-08T00:00:00+03:00', son:'2026-11-29T00:00:00+03:00', gun:'8' } };
  var KURAL={ sgs:'Söze yalnız bu 7 deneme sayılır: 7\'sini bitir, en az 5\'inde %60 ve üstü doğru yap (ilk çözüm sayılır), çalışma görevlerini tamamla.',
              yet:'Söz her ders için ayrı: o dersin 5 denemesini bitir, en az 3\'ünde %60 ve üstü doğru yap (ilk çözüm sayılır), çalışma görevlerini tamamla; hepsi 28 Kasım\'dan önce.' };
  var bekleyen=null;
  function kalanGun(t){ return Math.max(0, Math.ceil((t-Date.now())/864e5)); }
  function puan(d){ var top=0,dog=0,bitti=!!(d.dersler&&d.dersler.length);
    (d.dersler||[]).forEach(function(x){ if(!x.sonuc) bitti=false; else { dog+=+x.sonuc.dogru||0; top+=+x.sonuc.toplam||0; } });
    return { bitti:bitti, basladi:(d.dersler||[]).some(function(x){ return !!x.sonuc; }), puan: bitti&&top? Math.round(dog*1000/top)/10 : null }; }

  function sgsAl(){
    if(bekleyen) return bekleyen;
    bekleyen=new Promise(function(coz){
      var U=window.TetikteUye, bekle=(U&&U.hazir)?U.hazir:Promise.resolve(null);
      bekle.then(function(){ var sb=window.__pkSb; if(!sb||!sb.rpc) return coz(null);
        sb.rpc('s20_liste').then(function(r){ coz(r&&!r.error&&r.data?r.data:null); },function(){ coz(null); });
      },function(){ coz(null); });
    });
    return bekleyen;
  }

  /* tur: 'sgs' | 'yet'. yetUygun: Yeterlilik'te kişinin paketi Son 20 Gün'ü kapsıyor mu (çağıran bilir).
     Döner: null (kart yok) ya da { tur, once, baslik, metin, kural, dugme, adres, acik } */
  function durum(tur, yetUygun){
    var S=SINIR[tur]; if(!S) return Promise.resolve(null);
    var acT=Date.parse(S.acilis), sonT=Date.parse(S.son), simdi=Date.now();
    if(simdi>=sonT) return Promise.resolve(null);
    var once=simdi<acT, g=kalanGun(acT), adres=tur==='yet'?'son-20-gun.html?sinav=yeterlilik':'son-20-gun.html';
    var acilisYazi='Denemelerin '+S.gun+' Kasım\'da açılıyor'+(g>1?' · '+g+' gün kaldı':' · yarın');
    if(tur==='yet'){
      if(!yetUygun) return Promise.resolve(null);
      return Promise.resolve({ tur:'yet', once:once, acik:!once, adres:adres, kural:KURAL.yet,
        baslik:'Son 20 Gün · Yeterlilik denemeleri', metin:once?acilisYazi:'Denemelerin açık; her ders ayrı sınav.',
        dugme:once?'Son 20 Gün sayfası →':'Denemelere git →' });
    }
    return sgsAl().then(function(L){
      if(!L||!L.oturum||!L.erisim) return null;
      var byNo={}; (L.denemeler||[]).forEach(function(d){ byNo[d.no]=d; });
      var biten=0, alt=0, sira=null, yarim=null, liste=[];
      for(var no=1; no<=7; no++){ var d=byNo[no]; if(!d){ if(!sira) sira={no:no,acik:false}; liste.push({no:no,durum:'kapali'}); continue; }
        var p=puan(d); if(p.bitti){ biten++; if(p.puan>=60) alt++; liste.push({no:no,durum:'bitti',puan:p.puan}); continue; }
        if(!sira) sira={no:no,acik:!!d.acik}; if(p.basladi&&!yarim&&d.acik) yarim=no;
        liste.push({no:no,durum:!d.acik?'kapali':p.basladi?'yarim':'acik'}); }
      var gorevAcik=(L.gorevler||[]).some(function(x){ return !x.tamam; });
      var o={ tur:'sgs', once:once, adres:adres, kural:KURAL.sgs, biten:biten, alt60:alt, liste:liste, baslik:'Son 20 Gün · 7 deneme' };
      if(once){ o.acik=false; o.metin=acilisYazi; o.dugme='Son 20 Gün sayfası →'; return o; }
      o.acik=true;
      o.metin='Deneme '+biten+'/7 bitti · %60 ve üstü: '+Math.min(alt,5)+'/5';
      if(biten>=7) o.dugme='Sonuçlarını gör →';
      else if(gorevAcik) o.dugme='Önce çalışma görevlerin →';
      else if(yarim) o.dugme='Devam: Deneme '+yarim+' →';
      else if(sira&&sira.acik) o.dugme='Sıradaki: Deneme '+sira.no+' →';
      else { o.dugme='Son 20 Gün sayfası →'; if(sira) o.metin+=' · Deneme '+sira.no+' yakında açılır'; }
      return o;
    });
  }
  window.ttSon20={ durum:durum, KURAL:KURAL };
})();
