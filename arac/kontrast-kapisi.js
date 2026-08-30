/* ============================================================================
   KONTRAST KAPISI — okunmayan metin yayina cikamaz.

   NEDEN VAR (25.08.2026)
   Site koyu temadan acik temaya gecti. Gecis gunu olculdu: 551 kontrast
   kirigi. Hepsi kapatildi, 58/58 sayfa temiz. Ama hicbir sey geri gelmesini
   engellemiyordu. Bir sonraki "su rengi biraz acalim" bu isi sessizce bozar
   ve haftalarca fark edilmez - cunku kimse her sayfayi her push'ta gozle
   kontrol etmiyor. Bu kapi o bosluğu kapatir.

   NE YAPAR
   Chrome'u basliksiz calistirir, her sayfayi ACAR, ekranda gercekten
   gorunen her metin ogesinin kontrastini olcer (WCAG 2.1 bagil parlaklik,
   alfa karisimi ust ogeye tirmanarak). Esik: normal metin 4,5 - buyuk
   metin 3,0. Kirik varsa 1 koduyla duser.

   IKINCI OLCUM — GORUNMEZ SINIR (29.08.2026 eklendi)
   Cem: "cok kucuk asagida kalmis, ben bile zor buldum". Sebep marka
   kartlarinin cercevesiydi: `rgba(255,255,255,.10)` yazilmisti (betik site
   KOYU temadayken yazilmis), site acik temaya gecince beyaz cerceve beyaz
   kartin uzerinde KAYBOLDU. Kartlar bes sayfada ve panelde cercevesiz
   metin yigini gibi duruyordu - ve bu kusur bir hafta boyunca bu kapinin
   YESIL kosularindan gecti: kapi METIN kontrastini olcuyordu, CERCEVE ve
   AYIRICI kontrastini degil (WCAG 1.4.11 metin-disi kontrast).

   NEDEN 3:1 DEGIL: WCAG 1.4.11 metin-disi sinir icin 3:1 ister. Bizim
   olculen dogru cercevemiz (#e6e2da / #fbfaf8) 1,24; Ahrefs ve Semrush
   dahil hicbir kart tasarimi 3:1 cerceve kullanmiyor. 3:1 esigi SUREKLI
   KIRMIZI bir kapi uretirdi - ve surekli kirmizi kapi kapi degildir.
   Bu yuzden olculen sey WCAG uyumu degil, NIYET-SONUC UYUSMAZLIGI:
   gelistirici cerceve YAZMIS ama ekranda hicbir sinir GORUNMUYOR.
   Kusur sayilmasi icin UC KIYASIN UCU birden esigin altinda olmali:
       cerceve x ic zemin · cerceve x dis zemin · ic zemin x dis zemin
   Yani kutunun kenari hicbir yoldan secilemiyorsa kusurdur. Olculen
   degerler: bozuk hal 1,00-1,04 · duzeltilmis hal 1,24-1,29. Esik 1,12
   ikisini temiz ayirir (ESIK_SINIR).

   ICINE GOMULEN IKI DERS (ikisi de 25.08'de canli yasandi)
   1. IFRAME'DE OLCME. 58 sayfayi gizli iframe'e yukleyip olcunce 22 SAHTE
      kusur cikti; ayni sayfalar sekmede dogrudan olculunce temizdi.
      Sebep: stil-acik.css cascade'i kazanmak icin <body> sonunda ve
      iframe'de gec uygulaniyor. Bu kapi her sayfayi KENDI SEKMESINDE acar.
   2. ONBELLEK. Onbellek basligi gondermeyen bir sunucudan olcerken bayat
      dosya okunur ve duzeltilmis sayfa "hala kirik" gorunur. Bu kapi
      arac/yerel-sunucu.js kullanir - o 'Cache-Control: no-store' gonderir.

   API maliyeti SIFIR. Dis baglanti YOK. Bagimlilik YOK (Node'un yerlesik
   fetch ve WebSocket'i + Chrome DevTools protokolu).

   Kullanim:  node arac/kontrast-kapisi.js
              node arac/kontrast-kapisi.js index.html gtip.html   (secili)
   ============================================================================ */
'use strict';
const { spawn } = require('child_process');
const fs   = require('fs');
const path = require('path');
const os   = require('os');

const KOK      = path.resolve(__dirname, '..');
const PORT     = 8137;                 // olcum sunucusu (gunluk kullanimla cakismasin)
const ESIK_NRM = 4.5;
const ESIK_BYK = 3.0;
const ESIK_SINIR = 1.12;               // gorunmez sinir esigi - gerekcesi baslikta
const BEKLE_MS = 1200;                 // JS ile basilan stiller (menu.js vb.) yerlessin

/* --- Chrome'u bul ------------------------------------------------------- */
/* Nereye baktigi RAPORA yazilir; bulunamazsa "bulamadim" demek yetmez,
   NEREYE baktigini da soylemeli - yoksa CI'da tesahis edilemez. */
const BAKILAN_YOLLAR = [];
function chromeBul(){
  const dene = (y) => {
    if(!y) return false;
    BAKILAN_YOLLAR.push(y);
    try { return fs.existsSync(y); } catch(e){ return false; }
  };
  /* 1) acikca verilen yol */
  for(const ev of ['CHROME_PATH','CHROME_BIN','GOOGLE_CHROME_BIN']){
    if(process.env[ev] && dene(process.env[ev])) return process.env[ev];
  }
  /* 2) bilinen kurulum yerleri */
  const adaylar = [
    '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable',
    '/opt/google/chrome/chrome', '/opt/google/chrome/google-chrome',
    '/usr/bin/chromium-browser', '/usr/bin/chromium',
    '/snap/bin/chromium',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    path.join(os.homedir(), 'AppData\\Local\\Google\\Chrome\\Application\\chrome.exe'),
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  ];
  for(const a of adaylar) if(dene(a)) return a;
  /* 3) PATH uzerinde ara - runner imaji yeri degistirirse yine bulunur */
  const parcalar = (process.env.PATH||'').split(path.delimiter).filter(Boolean);
  const adlar = process.platform==='win32'
    ? ['chrome.exe','msedge.exe']
    : ['google-chrome','google-chrome-stable','chromium','chromium-browser'];
  for(const d of parcalar) for(const ad of adlar){
    const y = path.join(d, ad);
    if(dene(y)) return y;
  }
  return null;
}

/* --- olcum islevi: tarayicinin icinde kosar ----------------------------- */
/* Sayfa icine string olarak gonderilir; disaridan degisken almaz.          */
const OLCUM_KAYNAK = function(ESIK_NRM, ESIK_BYK, ESIK_SINIR){
  function lum(r,g,b){
    const a=[r,g,b].map(function(v){ v/=255;
      return v<=0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); });
    return 0.2126*a[0] + 0.7152*a[1] + 0.0722*a[2];
  }
  /* 30.08 KUSUR: bu ayiklayici YALNIZ rgb()/rgba() taniyordu.
     Chrome, color-mix(in srgb, ...) sonucunu "color(srgb r g b / a)" diye
     raporluyor - 0-1 arasi ondalik, virgul yok. O bicim gelince null donuyor,
     null donunce: zemin yiginda o katman ATLANIYOR (alfa karisimi hic
     hesaplanmiyor), metin renginde ise oge TUMDEN olcum disi kaliyor.
     Yani kapi "temiz" diyordu ama o ogelere HIC BAKMAMISTI.
     Bugun color-mix pano.html, fark.html ve menu.js'e girdigi icin kor nokta
     buyuyecekti. Ayrica modern Chrome "rgb(0 0 0 / .5)" (bosluklu, virgulsuz)
     bicimini de kullanabiliyor; eski split(',') onda da patliyordu. */
  function ayikla(s){
    const t=String(s);
    let m=t.match(/^color\(srgb\s+([\d.eE+-]+)\s+([\d.eE+-]+)\s+([\d.eE+-]+)(?:\s*\/\s*([\d.eE+-]+))?\s*\)/);
    if(m) return { r:parseFloat(m[1])*255, g:parseFloat(m[2])*255, b:parseFloat(m[3])*255,
                   a:m[4]!==undefined ? parseFloat(m[4]) : 1 };
    m=t.match(/rgba?\(([^)]+)\)/); if(!m) return null;
    const p=m[1].split(/[,\s\/]+/).filter(function(x){ return x!==''; }).map(parseFloat);
    if(p.length<3 || p.some(isNaN)) return null;
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
        const duraklar=(bi.match(/color\(srgb[^)]+\)|rgba?\([^)]+\)/g)||[]).map(ayikla).filter(c=>c&&c.a>0);
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
        metinAdaylari = (bi.match(/color\(srgb[^)]+\)|rgba?\([^)]+\)/g)||[]).map(ayikla).filter(c=>c&&c.a>0);
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
        iz: String(el.outerHTML||'').replace(/\s+/g,' ').slice(0,110),
        zemin: 'rgb('+Math.round(arka.r)+','+Math.round(arka.g)+','+Math.round(arka.b)+')'
      });
    }
  }

  /* ======================================================================
     IKINCI TUR — GORUNMEZ SINIR (metin disi kontrast)
     Gerekcesi ve esigin neden 3:1 olmadigi dosya basliginda yazili.
     Kusur = gelistirici cerceve YAZMIS ama ekranda sinir GORUNMUYOR.
     ====================================================================== */
  const sinirKirik=[]; let sinirBakilan=0;
  const YAN=[['Top','ust'],['Right','sag'],['Bottom','alt'],['Left','sol']];
  for(let i=0;i<hepsi.length;i++){
    const el=hepsi[i];
    const st=getComputedStyle(el);
    if(st.display==='none'||st.visibility==='hidden'||parseFloat(st.opacity)===0) continue;
    const r=el.getBoundingClientRect();
    /* Cok kucuk ogeler (ikon cizgisi, sus) sinir tasimaz sayilir; kutu ve
       ayirici ariyoruz. Yatay ayirici (hr) yuksekligi 0 olabilir -> genislik
       yeterse kabul edilir. */
    if(!(r.width>=24 && (r.height>=24 || r.width>=120))) continue;

    /* Bu ogenin GERCEK cerceveleri: sifir genislik / none / seffaf sayilmaz */
    const yanlar=[];
    for(const [Y,ad] of YAN){
      const kal=parseFloat(st['border'+Y+'Width']);
      const bicim=st['border'+Y+'Style'];
      if(!(kal>=1) || bicim==='none' || bicim==='hidden') continue;
      const c=ayikla(st['border'+Y+'Color']);
      if(!c || c.a<=0.02) continue;
      yanlar.push({ad, renk:c, kal});
    }
    if(!yanlar.length) continue;

    /* ic = ogenin kendi zemini (cerceve bunun UZERINE boyanir, cunku
       background varsayilan olarak border-box'a kadar uzanir)
       dis = ust ogenin zemini */
    const icAdaylar  = zeminAdaylari(el, false);
    const disAdaylar = zeminAdaylari(el, true);
    if(!icAdaylar.length || !disAdaylar.length) continue;

    /* Zeminlerin kendi arasindaki EN GORUNUR farki: kutu, cerceve olmasa
       bile zemin farkiyla secilebiliyorsa kusur yoktur. */
    let zeminFarki=0;
    for(const ic of icAdaylar) for(const ds of disAdaylar){
      const d=oran(ic,ds); if(d>zeminFarki) zeminFarki=d;
    }

    sinirBakilan++;
    for(const y of yanlar){
      let enGorunur=zeminFarki, ornekIc=icAdaylar[0], ornekEf=null;
      for(const ic of icAdaylar){
        const ef = y.renk.a<1 ? kat(y.renk, ic) : {r:y.renk.r,g:y.renk.g,b:y.renk.b};
        const dIc=oran(ef,ic);
        if(dIc>enGorunur){ enGorunur=dIc; ornekIc=ic; ornekEf=ef; }
        for(const ds of disAdaylar){
          const dDis=oran(ef,ds);
          if(dDis>enGorunur){ enGorunur=dDis; ornekIc=ic; ornekEf=ef; }
        }
      }
      if(enGorunur<ESIK_SINIR){
        const ef = ornekEf || (y.renk.a<1 ? kat(y.renk, ornekIc) : y.renk);
        const sinif=(el.className && typeof el.className==='string')
          ? '.'+el.className.trim().split(/\s+/)[0] : '';
        sinirKirik.push({
          /* KIMLIK: kusuru bulup duzeltebilmek icin etiket+sinif yetmiyor
             (29.08: rapor "input" diyordu, sayfada uc ayri input vardi).
             id ve ust ogenin sinifi da yazilir. */
          oge: el.tagName.toLowerCase()+sinif,
          kimlik: (el.id?('#'+el.id):'')
                  +(el.parentElement && el.parentElement.className && typeof el.parentElement.className==='string'
                    ? (' < .'+el.parentElement.className.trim().split(/\s+/)[0]) : ''),
          iz: String(el.outerHTML||'').replace(/\s+/g,' ').slice(0,110),
          yan: y.ad,
          oran: Math.round(enGorunur*1000)/1000,
          esik: ESIK_SINIR,
          cerceve: 'rgba('+Math.round(y.renk.r)+','+Math.round(y.renk.g)+','+Math.round(y.renk.b)+','+y.renk.a+')',
          gorunen: 'rgb('+Math.round(ef.r)+','+Math.round(ef.g)+','+Math.round(ef.b)+')',
          zemin: 'rgb('+Math.round(ornekIc.r)+','+Math.round(ornekIc.g)+','+Math.round(ornekIc.b)+')'
        });
        break;   /* oge basina tek kayit yeter - kenar zaten gorunmuyor */
      }
    }
  }

  return { bakilan: bakilan, kirik: kirik,
           sinirBakilan: sinirBakilan, sinirKirik: sinirKirik };
};

/* --- kucuk CDP istemcisi (yerlesik WebSocket) --------------------------- */
class Cdp {
  constructor(ws){ this.ws=ws; this.no=0; this.bekleyen=new Map();
    ws.addEventListener('message', (e)=>{
      const m=JSON.parse(e.data);
      if(m.id && this.bekleyen.has(m.id)){
        const {coz,red}=this.bekleyen.get(m.id); this.bekleyen.delete(m.id);
        m.error ? red(new Error(m.error.message)) : coz(m.result);
      }
    });
  }
  static async ac(url){
    const ws=new WebSocket(url);
    await new Promise((coz,red)=>{ ws.addEventListener('open',coz,{once:true});
                                   ws.addEventListener('error',()=>red(new Error('WS acilmadi')),{once:true}); });
    return new Cdp(ws);
  }
  cagir(yontem, parametre={}, sessionId){
    const id=++this.no;
    const paket={id, method:yontem, params:parametre};
    if(sessionId) paket.sessionId=sessionId;
    return new Promise((coz,red)=>{
      this.bekleyen.set(id,{coz,red});
      this.ws.send(JSON.stringify(paket));
      setTimeout(()=>{ if(this.bekleyen.has(id)){ this.bekleyen.delete(id); red(new Error(yontem+' zaman asimi')); } }, 30000);
    });
  }
  kapat(){ try{ this.ws.close(); }catch(e){} }
}

const bekle=(ms)=>new Promise(r=>setTimeout(r,ms));

/* --- rapor: kor kalma kurali -------------------------------------------
   Kapi CI'da dustugunde gunlugu okumak icin depo yoneticisi yetkisi gerekiyor;
   yetkisi olmayan (ben dahil) NEDEN dustugunu goremiyor. Bu yuzden kapi her
   kosuda kendi raporunu depoya yazar - yesil de olsa kirmizi da olsa. */
const RAPOR_YOL = path.join(KOK, 'veri', 'kontrast-raporu.json');
function raporYaz(icerik){
  try{
    fs.mkdirSync(path.dirname(RAPOR_YOL), {recursive:true});
    fs.writeFileSync(RAPOR_YOL, JSON.stringify(icerik, null, 2) + '\n');
  }catch(e){ /* rapor yazilamazsa kapinin kendisi durmasin */ }
}

/* --- ana akis ----------------------------------------------------------- */
(async function(){
  const secili=process.argv.slice(2).filter(a=>a.endsWith('.html'));
  const sayfalar = secili.length ? secili
    : fs.readdirSync(KOK).filter(f=>f.endsWith('.html'))
        .filter(f=>!/-yedek|^_/.test(f)).sort();

  if(!sayfalar.length){ console.log('KONTRAST KAPISI: kokte .html yok, atlandi.'); process.exit(0); }

  const ci = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';
  const chrome=chromeBul();
  if(!chrome){
    /* Kor kalma kurali: olcemedigimizde "temiz" demeyiz, KOR deriz.
       CI'da Chrome hazir gelir - orada yoklugu ARIZADIR, sessizce gecilmez.
       Yoksa kapi aylarca kor koşar ve yesil sanilir (mevzuat.yml 164 kez
       boyle kirmizi koştu, kimse bakmadi). */
    console.log('KONTRAST KAPISI: KOR — Chrome bulunamadi, olcum YAPILAMADI.');
    console.log('  Bakilan yollar (' + BAKILAN_YOLLAR.length + '):');
    for(const y of BAKILAN_YOLLAR.slice(0,14)) console.log('    ' + y);
    console.log('  Yerelde: CHROME_PATH=<yol> node arac/kontrast-kapisi.js');
    raporYaz({ durum:'KOR', sebep:'chrome-bulunamadi', ci:ci,
               platform:process.platform, bakilan_yol_sayisi:BAKILAN_YOLLAR.length,
               bakilan_yollar:BAKILAN_YOLLAR.slice(0,20) });
    process.exit(ci ? 1 : 0);
  }

  /* 1) olcum sunucusu (no-store gonderir) */
  const sunucu=spawn(process.execPath, [path.join(KOK,'arac','yerel-sunucu.js')],
    { env:{...process.env, PORT:String(PORT)}, stdio:'ignore' });
  await bekle(700);

  /* 2) Chrome */
  const profil=fs.mkdtempSync(path.join(os.tmpdir(),'kontrast-'));
  const cp=spawn(chrome, [
    '--headless=new','--disable-gpu','--no-sandbox','--disable-dev-shm-usage',
    '--hide-scrollbars','--window-size=1280,900',
    '--remote-debugging-port=0', '--user-data-dir='+profil,
    'about:blank'
  ], { stdio:['ignore','ignore','pipe'] });

  /* Chrome'un stderr'i toplanir: acilmazsa SEBEBI burada yazar
     (eksik kutuphane, sandbox, /dev/shm...). Toplanmazsa kapi "acilmadi"
     der ve nedenini kimse ogrenemez. */
  let chromeHata = '';
  cp.stderr.on('data', (d)=>{ if(chromeHata.length < 4000) chromeHata += d.toString(); });
  cp.on('error', (e)=>{ chromeHata += '\nspawn hatasi: ' + e.message; });

  const bitir=(kod)=>{ try{cp.kill();}catch(e){} try{sunucu.kill();}catch(e){}
                       try{fs.rmSync(profil,{recursive:true,force:true});}catch(e){}
                       process.exit(kod); };

  /* Chrome gercek portu DevToolsActivePort dosyasina yazar */
  /* Windows'ta Chrome dosyayi yazarken kilitli tutabiliyor (EBUSY) -
     var/yok bakmak yetmez, OKUMA denemesi de try icinde olmali. */
  /* Soguk runner'da ilk acilis yavas olabilir - 20 sn bekle. */
  let dvPort=null;
  for(let i=0;i<200;i++){
    try{
      const s=fs.readFileSync(path.join(profil,'DevToolsActivePort'),'utf8').split('\n');
      if(s[0] && s[0].trim()){ dvPort=s[0].trim(); break; }
    }catch(e){ /* henuz yok ya da kilitli - beklemeye devam */ }
    await bekle(100);
  }
  if(!dvPort){
    console.log('KONTRAST KAPISI: KOR — Chrome acildi ama baglanilamadi, olcum YAPILAMADI.');
    console.log('  chrome  : ' + chrome);
    if(chromeHata.trim()){
      console.log('  Chrome stderr:');
      for(const s of chromeHata.trim().split('\n').slice(0,12)) console.log('    ' + s);
    } else {
      console.log('  Chrome stderr: (bos)');
    }
    raporYaz({ durum:'KOR', sebep:'devtools-portu-acilmadi', ci:ci,
               chrome:chrome, chrome_stderr:chromeHata.trim().slice(0,2000) });
    bitir(1);
  }

  const surum=await (await fetch('http://127.0.0.1:'+dvPort+'/json/version')).json();
  const cdp=await Cdp.ac(surum.webSocketDebuggerUrl);

  console.log('KONTRAST KAPISI: '+sayfalar.length+' sayfa, esik '+ESIK_NRM+' (buyuk metin '+ESIK_BYK+').');

  const sonuc=[]; let toplamKirik=0, olculemeyen=0, toplamSinir=0;
  const olcumIfade='('+OLCUM_KAYNAK.toString()+')('+ESIK_NRM+','+ESIK_BYK+','+ESIK_SINIR+')';

  for(const sayfa of sayfalar){
    let hedef=null, oturum=null;
    try{
      const t=await cdp.cagir('Target.createTarget', { url:'about:blank' });
      hedef=t.targetId;
      const a=await cdp.cagir('Target.attachToTarget', { targetId:hedef, flatten:true });
      oturum=a.sessionId;
      await cdp.cagir('Page.enable', {}, oturum);
      await cdp.cagir('Page.navigate',
        { url:'http://127.0.0.1:'+PORT+'/'+sayfa+'?kapi='+Date.now() }, oturum);
      await bekle(BEKLE_MS);
      const r=await cdp.cagir('Runtime.evaluate',
        { expression:olcumIfade, returnByValue:true, awaitPromise:true }, oturum);
      if(r.exceptionDetails) throw new Error(r.exceptionDetails.text||'sayfa ici hata');
      const v=r.result.value;
      /* Hic metin gormediysek olcmus sayilmayiz - ucuncu sonuc: OLCULEMEDI */
      if(!v || !v.bakilan){ olculemeyen++; sonuc.push({sayfa, olculemedi:true}); }
      else {
        toplamKirik+=v.kirik.length;
        toplamSinir+=(v.sinirKirik||[]).length;
        sonuc.push({sayfa, bakilan:v.bakilan, kirik:v.kirik,
                    sinirBakilan:v.sinirBakilan||0, sinirKirik:v.sinirKirik||[]});
      }
    }catch(e){
      olculemeyen++; sonuc.push({sayfa, olculemedi:true, sebep:String(e.message).slice(0,60)});
    }finally{
      if(hedef) try{ await cdp.cagir('Target.closeTarget',{targetId:hedef}); }catch(e){}
    }
  }
  cdp.kapat();

  /* --- rapor ------------------------------------------------------------ */
  const kirikSayfalar=sonuc.filter(s=>s.kirik && s.kirik.length);
  const temiz=sonuc.filter(s=>s.kirik && !s.kirik.length).length;

  const sinirSayfalar=sonuc.filter(s=>s.sinirKirik && s.sinirKirik.length);

  raporYaz({
    durum: (toplamKirik||toplamSinir) ? 'KIRMIZI' : (olculemeyen ? 'KOR' : 'YESIL'),
    ci: ci,
    chrome: chrome,
    sayfa: sayfalar.length,
    temiz_sayfa: temiz,
    denetlenen_metin: sonuc.reduce((t,s)=>t+(s.bakilan||0),0),
    toplam_kirik: toplamKirik,
    denetlenen_sinir: sonuc.reduce((t,s)=>t+(s.sinirBakilan||0),0),
    toplam_gorunmez_sinir: toplamSinir,
    olculemeyen: olculemeyen,
    esik: { normal: ESIK_NRM, buyuk: ESIK_BYK, sinir: ESIK_SINIR },
    gorunmez_sinir_sayfalar: sinirSayfalar.map(s=>({
      sayfa: s.sayfa,
      adet: s.sinirKirik.length,
      ornekler: s.sinirKirik.slice(0,6)
    })),
    olculemeyenler: sonuc.filter(s=>s.olculemedi).map(s=>({ sayfa:s.sayfa, sebep:s.sebep||'bilinmiyor' })),
    kirik_sayfalar: kirikSayfalar.map(s=>({
      sayfa: s.sayfa,
      adet: s.kirik.length,
      ornekler: s.kirik.slice(0,6).map(k=>({ oge:k.oge, yazi:k.yazi, oran:k.oran, esik:k.esik, renk:k.renk, zemin:k.zemin, iz:k.iz }))
    }))
  });
  console.log('  Denetlenen metin ogesi: '+sonuc.reduce((t,s)=>t+(s.bakilan||0),0)
              +'   sinir tasiyan oge: '+sonuc.reduce((t,s)=>t+(s.sinirBakilan||0),0));
  console.log('  Temiz sayfa: '+temiz+'/'+sayfalar.length+'   Kirik: '+toplamKirik
              +'   Gorunmez sinir: '+toplamSinir
              +(olculemeyen?('   OLCULEMEDI: '+olculemeyen):''));

  if(olculemeyen){
    console.log('');
    console.log('  KOR — su sayfalar olculemedi (temiz DEGIL, bilinmiyor):');
    for(const s of sonuc.filter(x=>x.olculemedi))
      console.log('    '+s.sayfa+(s.sebep?('  <- '+s.sebep):''));
  }

  if(toplamKirik){
    console.log('');
    console.log('  KIRMIZI — okunmayan metin var:');
    for(const s of kirikSayfalar){
      console.log('    '+s.sayfa+'  ('+s.kirik.length+')');
      for(const k of s.kirik.slice(0,5))
        console.log('      '+k.oran+' / '+k.esik+'  '+k.oge+'  ['+k.yazi+']');
      if(s.kirik.length>5) console.log('      ... '+(s.kirik.length-5)+' tane daha');
    }
    console.log('');
    console.log('  Renk sabit yazilmis olabilir. Tema jetonlarini kullan:');
    console.log('    metin  -> var(--ink) / var(--muted) / var(--dim) / var(--amber)');
    console.log('    zemin  -> var(--taban) / var(--yuzey) / var(--kagit) / var(--amber-dolgu)');
    console.log('  Degrade YEDEK rengi de sayilir:  linear-gradient(...),#0d141e  <- bu da kirar.');
  }

  if(toplamSinir){
    console.log('');
    console.log('  KIRMIZI — GORUNMEZ SINIR: cerceve yazilmis ama ekranda kenar yok.');
    for(const s of sinirSayfalar){
      console.log('    '+s.sayfa+'  ('+s.sinirKirik.length+')');
      for(const k of s.sinirKirik.slice(0,5))
        console.log('      '+k.oran+' / '+k.esik+'  '+k.oge+'  '+k.yan
                    +'  cerceve '+k.cerceve+' -> gorunen '+k.gorunen+'  zemin '+k.zemin);
      if(s.sinirKirik.length>5) console.log('      ... '+(s.sinirKirik.length-5)+' tane daha');
    }
    console.log('');
    console.log('  Sebep genelde SABIT renk: rgba(255,255,255,...) koyu temada yazilir,');
    console.log('  acik temada beyaz zeminde kaybolur. Tema jetonunu kullan:');
    console.log('    cerceve -> var(--line) / var(--line2)     zemin -> var(--panel) / var(--yuzey)');
  }

  if(toplamKirik || toplamSinir) bitir(1);

  if(olculemeyen && !toplamKirik){
    console.log('');
    console.log('  Olculebilenler temiz, ama '+olculemeyen+' sayfa olculemedi.');
    bitir(1);
  }

  console.log('  Temiz - okunmayan metin ve gorunmez sinir yok.');
  bitir(0);
})().catch(e=>{ console.log('KONTRAST KAPISI: KOR — '+e.message); process.exit(0); });
