/* ============================================================================
   SEVİYE MODELİ — "20 soruda geçme ihtimalini ölç" (seviye-testi.html) hesabı.
   Tarayıcıda window.SeviyeModel, Node'da module.exports (öz-sınav: node seviye-model.js --sinav).

   KARAR (13.09.2026): Cem "geçme olasılığı vermek istiyorum" · GM üç seçenek sundu
   (şimdi seviye bandı + veri gelince yüzde / aralıklı yüzde / tek yüzde), tek yüzdeyi
   önermedi (bugün gerçek sınav sonucu verisi yok) · Cem "Şimdi tek yüzde" seçti.
   Bu dosya o yüzdeyi RASTGELE değil, AÇIK VARSAYIMLI bir hesapla üretir; varsayımlar
   sayfada "Nasıl hesaplandı?" altında yazılıdır.

   MODEL
   1) Yetenek θ: Rasch (1PL) - P(doğru) = 1 / (1 + e^-(θ - b)).
      Zorluk b, soruyu üretirken verilen etiketten: kolay -1 · zor 0 · çok zor +1.
      VARSAYIM: etiketler gerçek adaylarla ölçülmedi.
      Önsel θ ~ N(0, 1); sonsal ızgara üzerinde (-4..4, 161 nokta) hesaplanır.
   2) 130 soruda beklenen doğru oranı p(θ): sınav havuzundaki zorluk karışımıyla
      (SGS havuzu 13.09: kolay 1.290 · zor 1.193 · çok zor 1.127) ağırlıklı ortalama.
   3) Geçme sınırı s (doğru oranı): TESMER Uygulama Yönergesi - "soruların %80'ini doğru
      cevaplayanların başarılı sayıldığı sınavlar olduğu gibi %60'ını doğru cevaplayanların
      başarısız bulunduğu sınavlar da olmuştur". VARSAYIM: s ~ N(0,70 ; 0,07), [0,50 ; 0,90]
      aralığına kırpılır. (Bağıl değerlendirmede sınır dönemin aday kitlesine göre değişir;
      resmî sınır yayımlanmaz.)
   4) Geçme ihtimali = Σ_θ sonsal(θ) · P(s ≤ p(θ)). Ekranda %5 ile %95 arasında tutulur:
      20 soruyla "kesin" denmez.
   KALİBRASYON (açık iş): 21.11.2026 sınavından sonra deneme çözenlerin gerçek puanı
   toplanıp b değerleri ve s dağılımı yeniden kestirilir.
============================================================================ */
(function(kok){
  'use strict';
  var ZORLUK_B = { kolay:-1, zor:0, cokzor:1 };
  var KARISIM = { kolay:1290, zor:1193, cokzor:1127 };   // SGS havuzu, 13.09.2026 ölçümü
  var ESIK_ORT = 0.70, ESIK_SS = 0.07, ESIK_ALT = 0.50, ESIK_UST = 0.90;
  var TABAN = 0.05, TAVAN = 0.95;

  function lojistik(x){ return 1/(1+Math.exp(-x)); }
  function izgara(){ var g=[]; for(var i=0;i<=160;i++) g.push(-4+i*0.05); return g; }
  var IZGARA = izgara();
  function normalYogunluk(x,ort,ss){ var z=(x-ort)/ss; return Math.exp(-0.5*z*z); }
  // standart normal birikimli dağılım (Abramowitz-Stegun 26.2.17)
  function normalBirikimli(z){
    var t=1/(1+0.2316419*Math.abs(z)), d=0.3989423*Math.exp(-z*z/2);
    var p=d*t*(0.3193815+t*(-0.3565638+t*(1.781478+t*(-1.821256+t*1.330274))));
    return z>0?1-p:p;
  }
  // kırpılmış normalde P(s <= p)
  function esikAltinda(p){
    if(p<=ESIK_ALT) return 0; if(p>=ESIK_UST) return 1;
    var a=normalBirikimli((ESIK_ALT-ESIK_ORT)/ESIK_SS), b=normalBirikimli((ESIK_UST-ESIK_ORT)/ESIK_SS);
    return (normalBirikimli((p-ESIK_ORT)/ESIK_SS)-a)/(b-a);
  }

  /* cevaplar: [{zorluk:'kolay'|'zor'|'cokzor', dogru:true|false}] */
  function sonsal(cevaplar){
    var agirlik=IZGARA.map(function(t){
      var lp=Math.log(normalYogunluk(t,0,1));
      (cevaplar||[]).forEach(function(c){
        var b=ZORLUK_B[c.zorluk]; if(b===undefined) b=0;
        var pr=lojistik(t-b); lp+=Math.log(c.dogru?pr:1-pr);
      });
      return lp;
    });
    var enb=Math.max.apply(null,agirlik), top=0;
    var w=agirlik.map(function(l){ var v=Math.exp(l-enb); top+=v; return v; });
    return w.map(function(v){ return v/top; });
  }
  function beklenenOran(t){
    var top=0, n=0; for(var k in KARISIM){ top+=KARISIM[k]*lojistik(t-ZORLUK_B[k]); n+=KARISIM[k]; }
    return top/n;
  }
  function tahmin(cevaplar){
    var w=sonsal(cevaplar), ort=0, oran=0, gecme=0;
    IZGARA.forEach(function(t,i){ ort+=w[i]*t; var p=beklenenOran(t); oran+=w[i]*p; gecme+=w[i]*esikAltinda(p); });
    var gorunen=Math.min(TAVAN,Math.max(TABAN,gecme));
    return { theta:ort, oran:oran, dogru130:Math.round(oran*130), gecmeHam:gecme, gecme:Math.round(gorunen*100) };
  }
  /* uyarlama: sıradaki sorunun zorluğu, o anki yetenek tahminine en yakın etiket */
  function sonrakiZorluk(cevaplar){
    var t=tahmin(cevaplar).theta;
    return t < -0.5 ? 'kolay' : (t > 0.5 ? 'cokzor' : 'zor');
  }
  var API = { tahmin:tahmin, sonrakiZorluk:sonrakiZorluk, beklenenOran:beklenenOran, esikAltinda:esikAltinda,
    VARSAYIM:{ ZORLUK_B:ZORLUK_B, KARISIM:KARISIM, ESIK_ORT:ESIK_ORT, ESIK_SS:ESIK_SS, TABAN:TABAN, TAVAN:TAVAN } };

  if(typeof module!=='undefined' && module.exports){
    module.exports = API;
    if(require.main===module && process.argv.indexOf('--sinav')>-1){
      var hata=0; function bekle(ad,kosul){ console.log((kosul?'  geçti  ':'  DÜŞTÜ  ')+ad); if(!kosul) hata++; }
      var z=['kolay','zor','cokzor'];
      function uret(n,dogruFn){ var c=[]; for(var i=0;i<n;i++) c.push({zorluk:z[i%3], dogru:dogruFn(i)}); return c; }
      // "orta" vaka %70 doğru (14/20): sınır dağılımının ortası. %50 doğru bilerek orta vaka DEĞİL -
      // sınır en az %50 kabul edildiği için orada ihtimal zaten tabana iner (ilk sürümde yanlış beklenti yazılmıştı).
      var hepsi=tahmin(uret(20,function(){return true;})), hic=tahmin(uret(20,function(){return false;})), yarim=tahmin(uret(20,function(i){return i<14;}));
      bekle('20/20 doğru -> üst sınırda (%95)', hepsi.gecme===95);
      bekle('0/20 doğru -> alt sınırda (%5)', hic.gecme===5);
      bekle('14/20 (%70) doğru -> ikisinin arasında', yarim.gecme>5 && yarim.gecme<95);
      var onceki=-1, tekduze=true;
      for(var k=0;k<=20;k++){ var r=tahmin(uret(20,function(i){return i<k;})).gecmeHam; if(r<onceki-1e-9) tekduze=false; onceki=r; }
      bekle('doğru sayısı arttıkça ihtimal azalmaz (0..20)', tekduze);
      var kolayDogru=tahmin([{zorluk:'kolay',dogru:true}]).theta, cokzorDogru=tahmin([{zorluk:'cokzor',dogru:true}]).theta;
      bekle('çok zor soruyu bilmek kolayı bilmekten fazla yükseltir', cokzorDogru>kolayDogru);
      bekle('eşik: %50 doğru -> sınırı geçme 0, %90 -> 1, %70 -> 0,5', esikAltinda(0.5)===0 && esikAltinda(0.9)===1 && Math.abs(esikAltinda(0.7)-0.5)<0.01);
      bekle('uyarlama: hep doğru -> çok zor, hep yanlış -> kolay', sonrakiZorluk(uret(6,function(){return true;}))==='cokzor' && sonrakiZorluk(uret(6,function(){return false;}))==='kolay');
      console.log('SEVİYE MODELİ öz-sınav: '+(7-hata)+'/7'+'  · örnek: 20/20 -> %'+hepsi.gecme+' ('+hepsi.dogru130+'/130), 14/20 -> %'+yarim.gecme+' ('+yarim.dogru130+'/130), 0/20 -> %'+hic.gecme+' ('+hic.dogru130+'/130)');
      process.exit(hata?1:0);
    }
  } else { kok.SeviyeModel = API; }
})(typeof window!=='undefined'?window:this);
