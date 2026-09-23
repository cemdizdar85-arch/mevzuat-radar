/* ============================================================================
   SEVİYE MODELİ — YETERLİLİK (seviye-testi.html?sinav=yeterlilik) hesabı.
   Tarayıcıda window.SeviyeModelYet, Node'da module.exports (öz-sınav: node seviye-model-yet.js --sinav).

   KARAR (23.09.2026, Cem): her sınavın seviye testi SABİT 30 soru (veri/seviye/smmm-set.json);
   ders payı FM 5 · Maliyet 5 · FTA 4 · Vergi 4 · diğer 4 ders 3'er. Cem "önerimden" -> puanlama GM önerisi:
   ders ders Güçlü / Sınırda / Riskli + tek geçme ihtimali.

   GERÇEK KURAL (3568 Sınav Yönetmeliği m.16/b, veri/mevzuat-hazir/smmm-sinav-yon.txt satır 128-130):
     her konudan 100 üzerinden en az 50 VE tüm konuların aritmetik ortalaması en az 60; staj tezkiye notu
     ayrı bir ders gibi ortalamaya girer (sınava kabul için tezkiye >= 80, m.9). 2026 test biçiminde her ders
     20 soru (veri/smmm-analiz.json 2026/1 ve 2026/2 ölçümü) -> ders puanı = doğru × 5.

   MODEL
   1) Genel yetenek θg: Rasch (1PL), P(doğru) = 1/(1+e^-(θ-b)); b etiketten: kolay -1 · zor 0 · çok zor +1.
      Önsel θg ~ N(0,1), ızgara -4..4. Tüm 30 cevap.
   2) Ders yeteneği θd: önsel N(E[θg], TAU² + Var[θg]) + yalnız o dersin cevapları. TAU = 1,0 (öz-sınavla seçildi 23.09: 0,6 ve 0,8'de güçlü adayın 0/5 Maliyet'i "Sınırda" görünüyordu; 1,0 en sıkı değer ki 0/5 Riskli, zayıf adayın 3/3'ü ~53 puan): ders başına
      3-5 soruyla ham yüzde yanıltır (3/3 ≠ 100 puan); az soruda tahmin genel seviyeye doğru çekilir.
      Zorluk düzeltmesi Rasch'ın kendisidir: çok zor soruyu bilmek θ'yı kolay sorudan fazla yükseltir.
   3) Gerçek sınav: her ders 20 soru; zorluk karışımı GERCEK_KARISIM. Monte Carlo (N_MC, tohumlu RNG ->
      aynı cevaplar aynı sonucu verir): θd sonsaldan çekilir, 20 soru oynatılır, puan = doğru × 5;
      geçti = her ders >= 50 ve ortalama(8 ders + tezkiye) >= 60.
   4) Ders durumu: P(ders puanı >= 50) >= 0,80 Güçlü · >= 0,50 Sınırda · altı Riskli.
   5) Geçme ihtimali ekranda %5-%95 arasında (30 soruyla "kesin" denmez).

   VARSAYIMLAR (ÖLÇÜLMEDİ - sayfada "Nasıl hesaplandı?" altında yazılı):
   · b değerleri (etiketler gerçek adaylarla ölçülmedi) · TAU · GERCEK_KARISIM (Cem 21.09 "banka sınavdan zor
     olacak" -> gerçek sınav bankadan kolay kabul edildi) · tezkiye verilmezse 80 (en düşük kabul notu).
   KALİBRASYON (açık iş): 28.11.2026 sınavından sonra sonucunu paylaşanlarla b, TAU ve karışım yeniden kestirilir.
============================================================================ */
(function(kok){
  'use strict';
  var ZORLUK_B = { kolay:-1, zor:0, cokzor:1 };
  var GERCEK_KARISIM = { kolay:0.35, zor:0.45, cokzor:0.20 };   // VARSAYIM
  var TAU = 1.0, DERS_SORU = 20, N_MC = 3000, TEZKIYE_VARSAYILAN = 80;
  var TABAN = 5, TAVAN = 95, GUCLU = 0.80, SINIRDA = 0.50;

  function lojistik(x){ return 1/(1+Math.exp(-x)); }
  var IZGARA = []; for(var i=0;i<=160;i++) IZGARA.push(-4+i*0.05);

  /* ızgarada sonsal: önsel N(ort, ss) + cevaplar -> normalize ağırlıklar */
  function sonsal(cevaplar, ort, ss){
    var lp = IZGARA.map(function(t){
      var z=(t-ort)/ss, l=-0.5*z*z;
      cevaplar.forEach(function(c){ var b=ZORLUK_B[c.zorluk]; if(b===undefined) b=0; var p=lojistik(t-b); l+=Math.log(c.dogru?p:1-p); });
      return l;
    });
    var m=Math.max.apply(null,lp), w=lp.map(function(x){ return Math.exp(x-m); }), s=w.reduce(function(a,b){return a+b;},0);
    return w.map(function(x){ return x/s; });
  }
  function ortVar(w){ var o=0,v=0; w.forEach(function(p,i){ o+=p*IZGARA[i]; }); w.forEach(function(p,i){ v+=p*(IZGARA[i]-o)*(IZGARA[i]-o); }); return { ort:o, vr:v }; }
  /* tohumlu RNG (mulberry32): aynı cevaplar -> aynı yüzde; sayfa yenilenince sayı oynamaz */
  function rng(tohum){ var a=tohum>>>0; return function(){ a=(a+0x6D2B79F5)>>>0; var t=a; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; }
  function cek(w, r){ var u=r(), s=0; for(var i=0;i<w.length;i++){ s+=w[i]; if(u<=s) return IZGARA[i]; } return IZGARA[IZGARA.length-1]; }
  /* θ'da gerçek sınavdaki bir sorunun doğru olasılığı (zorluk karışımı ortalaması) */
  function pGercek(t){ var p=0; for(var z in GERCEK_KARISIM) p+=GERCEK_KARISIM[z]*lojistik(t-ZORLUK_B[z]); return p; }

  /* cevaplar: [{ders, zorluk:'kolay'|'zor'|'cokzor', dogru:bool}] · secenek: {tezkiye:80..100, dersler:[ad sırası]} */
  function tahmin(cevaplar, secenek){
    secenek = secenek || {};
    var tez = Number(secenek.tezkiye); if(!(tez>=80 && tez<=100)) tez = TEZKIYE_VARSAYILAN;
    var genel = ortVar(sonsal(cevaplar, 0, 1));
    var adlar = secenek.dersler || []; cevaplar.forEach(function(c){ if(adlar.indexOf(c.ders)<0) adlar.push(c.ders); });
    var dersW = adlar.map(function(ad){
      return sonsal(cevaplar.filter(function(c){ return c.ders===ad; }), genel.ort, Math.sqrt(TAU*TAU + genel.vr));
    });
    var tohum = 2166136261; cevaplar.forEach(function(c){ tohum = Math.imul(tohum ^ (c.dogru?1:0) ^ (ZORLUK_B[c.zorluk]+2)*7 ^ c.ders.length*131, 16777619); });
    var r = rng(tohum), gecti = 0, ellI = adlar.map(function(){ return 0; }), puanTop = adlar.map(function(){ return 0; });
    for(var n=0;n<N_MC;n++){
      var hepsi50 = true, top = tez;
      for(var d=0; d<adlar.length; d++){
        var p = pGercek(cek(dersW[d], r)), dog = 0;
        for(var q=0;q<DERS_SORU;q++) if(r()<p) dog++;
        var puan = dog*100/DERS_SORU; puanTop[d]+=puan; top+=puan;
        if(puan>=50) ellI[d]++; else hepsi50=false;
      }
      if(hepsi50 && top/(adlar.length+1) >= 60) gecti++;
    }
    var dersler = adlar.map(function(ad,d){
      var c = cevaplar.filter(function(x){ return x.ders===ad; }), p50 = ellI[d]/N_MC;
      return { ad:ad, soru:c.length, dogru:c.filter(function(x){ return x.dogru; }).length,
               puan:Math.round(puanTop[d]/N_MC), p50:Math.round(p50*100), durum: p50>=GUCLU?'guclu':p50>=SINIRDA?'sinirda':'riskli' };
    });
    var g = Math.round(100*gecti/N_MC);
    return { gecme: Math.min(TAVAN, Math.max(TABAN, g)), ham: g, tezkiye: tez, dersler: dersler };
  }

  var dis = { tahmin:tahmin, VARSAYIM:{ ZORLUK_B:ZORLUK_B, GERCEK_KARISIM:GERCEK_KARISIM, TAU:TAU, DERS_SORU:DERS_SORU, TEZKIYE:TEZKIYE_VARSAYILAN } };
  if(typeof module!=='undefined' && module.exports) module.exports = dis; else kok.SeviyeModelYet = dis;

  /* ÖZ-SINAV: node seviye-model-yet.js --sinav */
  if(typeof process!=='undefined' && process.argv && process.argv.indexOf('--sinav')>=0){
    var PLAN = [['FM',5],['Maliyet',5],['FTA',4],['Vergi',4],['Denetim',3],['Hukuk',3],['Meslek',3],['SPK',3]];
    var ZS = ['kolay','zor','zor','cokzor','zor','cokzor','kolay','zor','cokzor','zor'];
    function kur(dogruMu){ var c=[], k=0; PLAN.forEach(function(p){ for(var i=0;i<p[1];i++){ c.push({ders:p[0], zorluk:ZS[k%ZS.length], dogru:dogruMu(p[0],i,k)}); k++; } }); return c; }
    var hata = 0, t = function(ad, kosul, bilgi){ console.log((kosul?'  geçti: ':'  DÜŞTÜ: ')+ad+(bilgi?' ('+bilgi+')':'')); if(!kosul) hata++; };
    var hepsi = tahmin(kur(function(){ return true; })), hic = tahmin(kur(function(){ return false; }));
    t('hepsi doğru -> yüksek', hepsi.gecme>=80, '%'+hepsi.gecme);
    t('hiç doğru yok -> taban', hic.gecme===TABAN, '%'+hic.gecme);
    var yari = tahmin(kur(function(d,i,k){ return k%2===0; }));
    t('yarı yarıya -> ham ikisinin arası', yari.ham>=hic.ham && yari.ham<hepsi.ham, 'ham %'+yari.ham);
    // tek ders sıfır: güçlü adayın Maliyet'i 0/5 -> ihtimal düşer, Maliyet Riskli
    var tekZayif = tahmin(kur(function(d){ return d!=='Maliyet'; }));
    var mal = tekZayif.dersler.filter(function(x){ return x.ad==='Maliyet'; })[0];
    t('tek ders 0/5 -> ihtimal düşer', tekZayif.gecme < hepsi.gecme, '%'+tekZayif.gecme+' < %'+hepsi.gecme);
    t('tek ders 0/5 -> o ders Riskli', mal.durum==='riskli', mal.durum+' p50 %'+mal.p50);
    // az soru: 3/3 Meslek, ama genel zayıf -> Meslek "100 puan" sayılmaz
    var meslek = tahmin(kur(function(d){ return d==='Meslek'; })).dersler.filter(function(x){ return x.ad==='Meslek'; })[0];
    t('3/3 ama genel zayıf -> tahmini puan 100 değil', meslek.puan < 90, 'tahmini '+meslek.puan);
    // zorluk düzeltmesi: aynı sayıda doğru, çok zorları bilen > kolayları bilen
    var zorBilen = tahmin(kur(function(d,i,k){ var z=ZS[k%ZS.length]; return z!=='kolay'; }));
    var kolayBilen = tahmin(kur(function(d,i,k){ var z=ZS[k%ZS.length]; return z==='kolay' || (z==='zor' && k%3===0); }));
    var nz = kur(function(d,i,k){ return ZS[k%ZS.length]!=='kolay'; }).filter(function(c){return c.dogru;}).length;
    t('tohum: aynı cevap aynı sonuç', tahmin(kur(function(d,i,k){ return k%3!==0; })).gecme === tahmin(kur(function(d,i,k){ return k%3!==0; })).gecme);
    t('tezkiye 100 >= tezkiye 80', tahmin(kur(function(d,i,k){ return k%3!==0; }),{tezkiye:100}).ham >= tahmin(kur(function(d,i,k){ return k%3!==0; }),{tezkiye:80}).ham);
    t('çok zor bilen > kolay bilen (zorluk düzeltmesi)', zorBilen.ham > kolayBilen.ham, '%'+zorBilen.ham+' vs %'+kolayBilen.ham+', zor bilen '+nz+' doğru');
    // tekdüzelik: bir yanlışı doğruya çevirmek ihtimali düşürmemeli (±2 MC gürültüsü)
    var bozuk = 0; for(var j=0;j<30;j+=3){ var a=tahmin(kur(function(d,i,k){ return k%2===0 && k!==j; })).ham, b=tahmin(kur(function(d,i,k){ return k%2===0 || k===j; })).ham; if(b < a-2) bozuk++; }
    t('tekdüzelik: fazladan doğru ihtimali düşürmez', bozuk===0, bozuk+' ihlal');
    console.log(hata ? 'SEVİYE MODELİ (YETERLİLİK) ÖZ-SINAVI DÜŞTÜ: '+hata : 'SEVİYE MODELİ (YETERLİLİK) ÖZ-SINAVI GEÇTİ');
    if(hata) process.exit(1);
  }
})(typeof window!=='undefined'?window:this);
