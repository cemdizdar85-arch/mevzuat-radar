/* ============================================================================
   KONTRAST OLCUMU — ORTAK MODUL

   NEDEN AYRI DOSYA (25.08.2026)
   Iki kapi bu olcumu kullaniyor:
     arac/kontrast-kapisi.js    sayfayi ACIP olcer (acilistaki hal)
     arac/etkilesim-kapisi.js   ETKILESIMDEN SONRA olcer (arama sonucu,
                                acilan blok, odaklanan oge)
   Olcumun icinde bugune kadar UC kor nokta bulundu ve kapatildi. Kod iki
   yere kopyalansaydi bir sonraki duzeltme yalnizca birine girer, digeri
   sessizce kor kalirdi. Tek kaynak, tek duzeltme.

   KAPATILAN KOR NOKTALAR
   1. DEGRADE ZEMIN: getComputedStyle degrade icin backgroundColor'i
      'rgba(0,0,0,0)' dondurur. Yalniz ona bakan olcum, koyu degrade
      uzerindeki koyu yaziyi UST ogenin acik zeminiyle kiyaslar ve KACIRIR.
      -> degradenin her duragi ayri ZEMIN adayi sayilir.
   2. KENDI OPAK DEGRADESI (yanlis pozitif freni): oge kendi opak
      degradesini boyuyorsa arkasindaki ata zemini GORUNMEZ. Amber logo
      rozeti koyu seritte "1,09" diye kirmizi veriyordu; oysa rozetin
      amberi seridi tamamen kapatiyor. -> katmanlar ustten alta toplanip
      ILK OPAK katmanda kesilir.
   3. background-clip:text — "-webkit-text-fill-color:transparent" oldugunda
      gorunen renk "color" DEGIL degradenin kendisidir. Bir baslik acik
      kagitta BEYAZ yaziliyordu (1,04) ve olcum "temiz" diyordu.
      -> klipliyse ogenin kendi degrade duraklari METIN adayi sayilir,
      zemin UST ogeden alinir.

   Yargi: her METIN adayi x her ZEMIN adayi ciftinin EN KOTUSU. Degradenin
   bir ucu okunmuyorsa kusurdur - ortalama almak kusuru gizler.
   ============================================================================ */
'use strict';

const ESIK_NRM = 4.5;   /* WCAG 2.1 AA - normal metin */
const ESIK_BYK = 3.0;   /* WCAG 2.1 AA - buyuk metin (>=24px, ya da >=18.66px kalin) */

/* Tarayicinin ICINDE kosar. Disaridan degisken almaz - kaynagi string'e
   cevrilip Runtime.evaluate ile gonderilir. */
const OLCUM_KAYNAK = function(ESIK_NRM, ESIK_BYK){
  function lum(r,g,b){
    const a=[r,g,b].map(function(v){ v/=255;
      return v<=0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); });
    return 0.2126*a[0] + 0.7152*a[1] + 0.0722*a[2];
  }
  function ayikla(s){
    const m=String(s).match(/rgba?\(([^)]+)\)/); if(!m) return null;
    const p=m[1].split(',').map(parseFloat);
    return { r:p[0], g:p[1], b:p[2], a:p.length>3 ? p[3] : 1 };
  }
  function kat(ust, alt){   /* ust rengi altin uzerine karistir */
    return { r:ust.r*ust.a+alt.r*(1-ust.a),
             g:ust.g*ust.a+alt.g*(1-ust.a),
             b:ust.b*ust.a+alt.b*(1-ust.a), a:1 };
  }
  /* gercek zemin: seffafsa ust ogeye tirman, alfa varsa karistir */
  function zemin(el){
    const yigin=[]; let n=el;
    while(n){
      const c=ayikla(getComputedStyle(n).backgroundColor);
      if(c && c.a>0){ yigin.push(c); if(c.a>=1) break; }
      n=n.parentElement;
    }
    if(!yigin.length) return {r:255,g:255,b:255};
    let alt=yigin[yigin.length-1];
    if(alt.a<1) alt={r:255,g:255,b:255};
    let o={r:alt.r, g:alt.g, b:alt.b};
    for(let i=yigin.length-2;i>=0;i--) o=kat(yigin[i], o);
    return o;
  }

  /* DEGRADE KOR NOKTASI (25.08'de tam bu hata sinifi canliyi bozdu)
     backgroundColor degrade icin 'rgba(0,0,0,0)' doner; yalniz ona bakan
     olcum degrade'in ustundeki yaziyi UST ogenin zeminiyle karsilastirir
     ve kusuru KACIRIR. Ornek:
       background:linear-gradient(180deg,#0b1119,#0a0f17)   <- koyu
     Acik temada uzerindeki var(--ink) okunmaz ama olcum "temiz" der.

     Cozum: zemini TEK renk degil ADAY LISTESI olarak hesapla - degradenin
     her duragi ayri bir adaydir - ve en kotusuyle yargila. Degradenin bir
     ucunda okunmayan yazi kusurdur.

     YANLIS POZITIF FRENI: oge KENDI opak degradesini boyuyorsa arkasindaki
     ata zemini GORUNMEZ, aday sayilmaz. (Amber logo rozeti koyu seritte
     "1,09" diye kirmizi veriyordu; oysa rozetin kendi amberi seridi tamamen
     kapatiyor.) Bu yuzden katmanlar alttan ustte dogru toplanir. */
  function zeminAdaylari(el, kendiniAtla){
    /* 1) ustten alta katmanlari topla, ilk OPAK katmanda dur */
    const katmanlar=[];   /* [0] = en ustteki */
    let n = kendiniAtla ? el.parentElement : el;
    let derinlik=0;
    while(n && derinlik<12){
      const st=getComputedStyle(n);
      const bi=st.backgroundImage;
      let opakDegrade=false;
      if(bi && bi!=='none' && /gradient/.test(bi)){
        const duraklar=(bi.match(/rgba?\([^)]+\)/g)||[]).map(ayikla).filter(c=>c&&c.a>0);
        if(duraklar.length){
          katmanlar.push({tur:'degrade', duraklar});
          opakDegrade=duraklar.every(c=>c.a>=1);
        }
      }
      const kc=ayikla(st.backgroundColor);
      if(kc && kc.a>0){
        katmanlar.push({tur:'renk', renk:kc});
        if(kc.a>=1) break;          /* opak renk: arkasi gorunmez */
      }
      if(opakDegrade) break;        /* opak degrade: arkasi gorunmez */
      n=n.parentElement; derinlik++;
    }

    /* 2) alttan uste karistir; degrade her adimda adaylari cogaltir */
    let adaylar=[{r:255,g:255,b:255}];   /* hicbir sey yoksa kagit beyazi */
    for(let i=katmanlar.length-1;i>=0;i--){
      const k=katmanlar[i];
      const yeni=[];
      if(k.tur==='renk'){
        if(k.renk.a>=1) yeni.push({r:k.renk.r,g:k.renk.g,b:k.renk.b});
        else for(const a of adaylar) yeni.push(kat(k.renk,a));
      }else{
        for(const d of k.duraklar){
          if(d.a>=1) yeni.push({r:d.r,g:d.g,b:d.b});
          else for(const a of adaylar) yeni.push(kat(d,a));
        }
      }
      adaylar = yeni.length ? yeni.slice(0,24) : adaylar;   /* patlamayi engelle */
    }
    return adaylar;
  }
  function oran(a,b){
    const L1=lum(a.r,a.g,a.b), L2=lum(b.r,b.g,b.b);
    return (Math.max(L1,L2)+0.05)/(Math.min(L1,L2)+0.05);
  }

  const kirik=[]; let bakilan=0;
  const hepsi=document.querySelectorAll('body *');
  for(let i=0;i<hepsi.length;i++){
    const el=hepsi[i];
    /* yalniz DOGRUDAN metin tasiyan ogeler - yoksa ayni yazi ust ogelerde tekrar sayilir */
    let metin='';
    for(let j=0;j<el.childNodes.length;j++)
      if(el.childNodes[j].nodeType===3) metin+=el.childNodes[j].nodeValue;
    metin=metin.replace(/\s+/g,' ').trim();
    if(metin.length<2) continue;

    const st=getComputedStyle(el);
    if(st.display==='none'||st.visibility==='hidden'||parseFloat(st.opacity)===0) continue;
    const r=el.getBoundingClientRect();
    if(!r.width||!r.height) continue;

    /* METNIN GERCEK RENGI — ucuncu kor nokta (25.08'de ihale-radari'nda cikti)
       Baslik "background-clip:text" ile boyanmisti:
         h1{background:linear-gradient(100deg,#fff 30%,...);background-clip:text;
            -webkit-text-fill-color:transparent}
       Bu durumda "color" ozelligi HICBIR SEY ifade etmez - gorunen renk
       DEGRADENIN KENDISIDIR. Yalniz st.color'a bakan olcum, mirasla gelen
       koyu murekkebi okur ve "temiz" der; oysa basligin ilk %30'u acik
       kagit uzerinde BEYAZ yaziliyordu (olculdu: 1,04:1).
       Ayrica -webkit-text-fill-color, seffaf olmasa bile color'i EZER. */
    const clip = st.webkitBackgroundClip || st.backgroundClip;
    const metinKlipli = (clip === 'text');
    let metinAdaylari = [];
    if(metinKlipli){
      const bi = st.backgroundImage;
      if(bi && bi!=='none'){
        metinAdaylari = (bi.match(/rgba?\([^)]+\)/g)||[]).map(ayikla).filter(c=>c&&c.a>0);
      }
    }
    if(!metinAdaylari.length){
      const dolgu = st.webkitTextFillColor;
      const ham = ayikla(dolgu && !/rgba\(0,\s*0,\s*0,\s*0\)/.test(dolgu) ? dolgu : st.color);
      if(ham) metinAdaylari = [ham];
    }
    if(!metinAdaylari.length) continue;
    /* metin klipliyse ogenin KENDI zemini metni boyuyor demektir - arka plan
       olarak ust ogenin zemini alinir, yoksa metni kendisiyle kiyaslariz. */
    const adaylar=zeminAdaylari(el, metinKlipli);

    bakilan++;
    const px=parseFloat(st.fontSize);
    const kalin=parseInt(st.fontWeight,10)>=700;
    const buyuk=(px>=24)||(px>=18.66 && kalin);
    const esik=buyuk?ESIK_BYK:ESIK_NRM;

    /* EN KOTU ciftle yargila: her metin adayi x her zemin adayi.
       Degradenin bir ucu okunmuyorsa kusurdur - ortalama almak kusuru gizler. */
    let o=Infinity, arka=adaylar[0], on=metinAdaylari[0];
    for(const ad of adaylar){
      for(const m of metinAdaylari){
        const mm = m.a<1 ? kat(m, ad) : m;
        const d = oran(mm, ad);
        if(d<o){ o=d; arka=ad; on=mm; }
      }
    }
    if(o<esik){
      const sinif=(el.className && typeof el.className==='string')
        ? '.'+el.className.trim().split(/\s+/)[0] : '';
      kirik.push({
        oge: el.tagName.toLowerCase()+sinif,
        yazi: metin.slice(0,40),
        oran: Math.round(o*100)/100,
        esik: esik,
        renk: st.color,
        zemin: 'rgb('+Math.round(arka.r)+','+Math.round(arka.g)+','+Math.round(arka.b)+')'
      });
    }
  }
  return { bakilan: bakilan, kirik: kirik };
};

module.exports = { OLCUM_KAYNAK, ESIK_NRM, ESIK_BYK };
