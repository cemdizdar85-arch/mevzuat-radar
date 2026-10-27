/* EN ÇOK ÇIKAN KONULARDAN SORULAR — ortak betik (28.10.2026: sayfa içinden çıkarıldı, üç sayfa paylaşır).
   <body data-sinav="yeterlilik|sgs"> sınavı SABİTLER (reklam açılış sayfaları); yoksa ?sinav= okunur (en-cok-cikan-sorular.html). */
(function(){
  var $=function(i){ return document.getElementById(i); };
  var esc=function(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); };
  var trk=function(s){ return String(s||'').toLocaleLowerCase('tr-TR').replace(/\s+/g,' ').trim(); };
  var Q=new URLSearchParams(location.search), SABIT=document.body.getAttribute('data-sinav');
  var SECILI=SABIT||(/^(sgs|staja)/i.test(Q.get('sinav')||'')?'sgs':'yeterlilik');
  var K=Q.get('k')?('&k='+encodeURIComponent(Q.get('k'))):'';   /* reklam kaynağı fiyat bağlantısına taşınır */
  /* sabit sayfada sekmeler öteki sınavın sayfasına bağlantıdır; ?k= oraya da taşınır */
  if(SABIT&&K) document.querySelectorAll('.ec-sekme a[href]').forEach(function(a){ var h=a.getAttribute('href'); if(h.indexOf('k=')<0) a.setAttribute('href', h+(h.indexOf('?')<0?'?':'&')+K.slice(1)); });
  var VERI={}, PAKET={};   /* PAKET[s] = null (yok) | {dersler:null|[...]} */
  var AYAR={
    yeterlilik:{ dizin:'veri/deneme/smmm-sik-dizin.json', kanit:'en-cok-cikan-konular-yeterlilik.html', fiyat:'fiyat.html?sinav=yeterlilik', ornek:'kaydir/vitrin/ornek-smmm.html',
      git:function(d){ return 'sinav-gibi.html?tur=sik&sinav=smmm&ders='+encodeURIComponent(d); },
      cip:['Ders başına en sık 5 konu','20 soru · 45 dakika','gerçek 2026 düzeni','bitince konu konu karne'] },
    sgs:{ dizin:'veri/deneme/sgs-sik-dizin.json', kanit:'en-cok-cikan-konular-sgs.html', fiyat:'fiyat.html?sinav=sgs', ornek:'kaydir/vitrin/ornek-sgs.html',
      git:function(d){ return 'sinav-gibi.html?tur=sik&ders='+encodeURIComponent(d); },
      cip:['En sık 20 konu, ders ders','20 soru · 25 dakika','önce görmediğin sorular','bitince konu konu karne'] } };
  /* 19.10 (Cem: "Google'dan gelenin satın alma oranını artıralım"): Google arama ziyaretçisi buraya iner, aramış ve almaya
     yakın; kutuda fiyat yoktu, yalnız "Paketler" vardı. Fiyat satırı + doğrudan satın al. Rakamlar YALNIZ fiyat-motoru.js'ten
     (paketBul + fiyatAna/fiyatDahilNot + HARC; Cem kuralı "fiyat her yerde aynı"). Motor yüklenmezse satır ve düğme hiç çizilmez. */
  function fiyatCiz(s){
    var f=$('ecFiyat'), a=$('ecAlA');
    if(typeof paketBul!=='function'||typeof fiyatAna!=='function'){ f.hidden=true; a.hidden=true; return; }
    var id=s==='sgs'?'sgs':'yeterlilik-1', p=paketBul(id); if(!p||!p.acik){ f.hidden=true; a.hidden=true; return; }
    var dahil=function(i,n){ var d=fiyatDahilNot(i,n); return d?' <small>('+esc(d)+')</small>':''; };
    var h;
    if(s==='sgs'){
      /* 28.10 (Cem "hemen başla"): Geçene Kadar Tetikte erken kayıt fiyatı burada da (satın al ?paket=sgs ERKEN kodu kendisi
         uygular; bu sayfa 2.988 gösterirken satın alma 2.388 diyordu). Tutar + bitiş YALNIZ fiyat-motoru.js ERKEN_KAYIT'tan;
         süre dolunca erkenKayitAcik() false → eski satır kendiliğinden döner. Sadece 7 Deneme: paket son20-sgs açıksa. */
      var erken=typeof erkenKayitAcik==='function'&&erkenKayitAcik()&&typeof ERKEN_KAYIT==='object';
      if(erken){
        var net=p.fiyat-ERKEN_KAYIT.indirim, bit=new Date(ERKEN_KAYIT.bitis);
        var bitY=bit.toLocaleDateString('tr-TR',{day:'numeric',month:'long',timeZone:'Europe/Istanbul'})+' '+bit.toLocaleTimeString('tr-TR',{hour:'2-digit',minute:'2-digit',timeZone:'Europe/Istanbul'});
        h='<span class="ana">Tam Paket '+esc(fiyatAna(id,net))+'</span> <small>(KDV dahil '+tl(net)+' TL · '+tl(p.fiyat)+' TL yerine, '+esc(bitY)+'\'a kadar)</small>'
          +'<br>'+esc(p.erisim||'Sınavına kadar')+' · sınırsız soru';
      } else {
        h='<span class="ana">'+esc(fiyatAna(id,p.fiyat))+'</span>'+dahil(id,p.fiyat)+'<br>'+esc(p.erisim||'Sınavına kadar')+' · sınırsız soru';
      }
      var s7=paketBul('son20-sgs');
      if(s7&&s7.acik) h+='<br><a href="satin-al.html?paket=son20-sgs'+K+'">Sadece 7 Deneme '+esc(fiyatAna('son20-sgs',s7.fiyat))+'</a>'+dahil('son20-sgs',s7.fiyat);
    } else {
      var t=paketBul('yeterlilik-tum');
      h='<span class="ana">1 ders '+esc(fiyatAna(id,p.fiyat))+'</span>'+dahil(id,p.fiyat)+'<br>Bir dersin sınav ücreti '+tl(HARC.yeterlilik.ders)+' TL'
        +(t&&t.acik?' · tüm dersler '+esc(fiyatAna('yeterlilik-tum',t.fiyat))+dahil('yeterlilik-tum',t.fiyat):'');
    }
    h+='<br><small>Açılış fiyatı ilk '+tl(p.kota)+' ödeyene; sonra '+esc(fiyatAna(id,p.liste))+'. Kartla ödersen paketin hemen açılır.</small>';
    f.innerHTML=h; f.hidden=false;
    a.href='satin-al.html?paket='+id+K; a.textContent=s==='sgs'?'Satın al →':'Dersini seç, satın al →'; a.hidden=false;
  }
  function dersAcik(s,d){ var p=PAKET[s]; if(!p) return false; if(!p.dersler||!p.dersler.length) return true; return p.dersler.some(function(x){ return trk(x)===trk(d); }); }
  function ciz(){
    var s=SECILI, A=AYAR[s], v=VERI[s];
    document.querySelectorAll('.ec-sekme button').forEach(function(b){ b.setAttribute('aria-pressed', String(b.getAttribute('data-s')===s)); });
    $('ecEt').textContent=(s==='sgs'?'SMMM STAJA GİRİŞ':'SMMM YETERLİLİK')+' · SINAVDA EN ÇOK ÇIKAN KONULAR';
    $('ecCipler').innerHTML=A.cip.map(function(c){ return '<span>'+esc(c)+'</span>'; }).join('');
    var pk=!!PAKET[s];
    $('ecSatis').hidden=pk; $('ecSatisA').href=A.fiyat+K; $('ecOrnekA').href=A.ornek;
    /* 28.10 söz şeridi (Geçene Kadar Tetikte): yalnız Staja Giriş, paketsize, 21 Kasım 2026 sınavı başlayana kadar
       (söz o dönem içindir; koşullar kampanya-son-20-gun.html). Yeterlilik'te söz YOK (ölçüt Cem kararında). */
    var sz=$('ecSoz'); if(sz) sz.hidden=!(s==='sgs'&&!pk&&Date.now()<Date.UTC(2026,10,20,21,0,0));
    fiyatCiz(s);
    if(!v){ $('ecDersler').innerHTML='<p class="ec-bilgi">Dersler şu an okunamadı. Sayfayı yenilemeyi dene.</p>'; return; }
    var G={}, S=[];
    (v.konular||[]).forEach(function(k){ if(!G[k.ders]){ G[k.ders]=[]; S.push(k.ders); } G[k.ders].push(k); });
    /* Yeterlilik: yalnız hazır seti olan dersler · Staja Giriş: en sık konusu en çok dönem çıkan ders önce */
    if(s==='yeterlilik'){ var setD={}; (v.setler||[]).forEach(function(x){ if(x.ders) setD[x.ders]=(setD[x.ders]||0)+1; }); S=S.filter(function(d){ return setD[d]; }); }
    S.sort(function(a,b){ var ma=Math.max.apply(null,G[a].map(function(k){ return +k.donem||0; })), mb=Math.max.apply(null,G[b].map(function(k){ return +k.donem||0; })); return mb-ma; });
    /* 18.10 Yeterlilik: konular PUAN önceliğiyle (k.oncelik: sınavda dönem başına getirdiği puan, motor/sik-konu-deneme-bas.js) */
    var setSay={}; (v.setler||[]).forEach(function(x){ if(x.ders) setSay[x.ders]=(setSay[x.ders]||0)+1; });
    $('ecDersler').innerHTML=S.map(function(d){
      var L=G[d].slice().sort(function(a,b){ return (a.oncelik&&b.oncelik)?a.oncelik-b.oncelik:(+b.donem||0)-(+a.donem||0); }), ac=dersAcik(s,d);
      var ns=s==='yeterlilik'?setSay[d]||0:0;
      return '<section class="ec-ders"><h2>'+esc(d)+'</h2>'+(ns?'<p class="ec-set">'+ns+' test · '+(ns*20)+' soru · sınavda daha çok puan getiren konu önde</p>':'')+'<ol>'+L.map(function(k){ return '<li>'+esc(k.konu)+' <small>· son 10 yılda '+(+k.donem||0)+' sınavda soruldu</small></li>'; }).join('')+'</ol>'
        +(ac?'<a class="ec-dug" href="'+esc(A.git(d))+'">Bu dersten sık konu sorularını çöz →</a>'
            :'<a class="ec-dug kilit" href="'+esc(A.fiyat+K)+'">🔒 Pakete dahil'+(pk?' · bu ders paketinde yok':'')+'</a>')+'</section>';
    }).join('');
    $('ecNot').innerHTML=esc(v.not||'')+' <a href="'+A.kanit+'">Konu listesi ve kanıtı: hangi sınav, kaçıncı soru →</a>';
  }
  document.querySelectorAll('.ec-sekme button').forEach(function(b){ b.addEventListener('click',function(){ SECILI=b.getAttribute('data-s'); try{ history.replaceState(null,'',location.pathname+'?sinav='+SECILI+K); }catch(e){} ciz(); }); });
  /* paket: önce önbellek (ilk çizim kilitsiz görünsün), sonra sunucu */
  function paketAl(d){ ['sgs','yeterlilik'].forEach(function(s){ var o=d&&d.sinavlar&&d.sinavlar[s]; PAKET[s]=(o&&o.durum==='aktif')?{dersler:o.dersler||null}:null; }); }
  try{ if(window.TetikteUye&&TetikteUye.onbellek) paketAl(TetikteUye.onbellek); }catch(e){}
  try{ if(window.TetikteUye&&TetikteUye.hazir) TetikteUye.hazir.then(function(d){ if(d&&!d.hata){ paketAl(d); ciz(); } }); }catch(e){}
  Promise.all(['yeterlilik','sgs'].map(function(s){ return fetch(AYAR[s].dizin,{cache:'no-cache'}).then(function(y){ return y.ok?y.json():null; }).catch(function(){ return null; }).then(function(j){ VERI[s]=j; }); }))
    .then(ciz);
})();
