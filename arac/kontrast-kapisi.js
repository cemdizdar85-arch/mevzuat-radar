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
const BEKLE_MS = 1200;                 // JS ile basilan stiller (menu.js vb.) yerlessin

/* --- Chrome'u bul ------------------------------------------------------- */
function chromeBul(){
  if(process.env.CHROME_PATH && fs.existsSync(process.env.CHROME_PATH)) return process.env.CHROME_PATH;
  const adaylar = [
    '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser', '/usr/bin/chromium',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    path.join(os.homedir(), 'AppData\\Local\\Google\\Chrome\\Application\\chrome.exe'),
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  ];
  for(const a of adaylar) if(fs.existsSync(a)) return a;
  return null;
}

/* --- olcum islevi: tarayicinin icinde kosar ----------------------------- */
/* Sayfa icine string olarak gonderilir; disaridan degisken almaz.          */
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
  function zeminAdaylari(el){
    /* 1) ustten alta katmanlari topla, ilk OPAK katmanda dur */
    const katmanlar=[];   /* [0] = en ustteki */
    let n=el, derinlik=0;
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

    const onHam=ayikla(st.color); if(!onHam) continue;
    const adaylar=zeminAdaylari(el);

    bakilan++;
    const px=parseFloat(st.fontSize);
    const kalin=parseInt(st.fontWeight,10)>=700;
    const buyuk=(px>=24)||(px>=18.66 && kalin);
    const esik=buyuk?ESIK_BYK:ESIK_NRM;

    /* en kotu aday zeminle yargila - degrade'in bir ucu okunmuyorsa kusurdur */
    let o=Infinity, arka=adaylar[0];
    for(const ad of adaylar){
      const on = onHam.a<1 ? kat(onHam, ad) : onHam;
      const d=oran(on, ad);
      if(d<o){ o=d; arka=ad; }
    }
    const on = onHam.a<1 ? kat(onHam, arka) : onHam;
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

/* --- ana akis ----------------------------------------------------------- */
(async function(){
  const secili=process.argv.slice(2).filter(a=>a.endsWith('.html'));
  const sayfalar = secili.length ? secili
    : fs.readdirSync(KOK).filter(f=>f.endsWith('.html'))
        .filter(f=>!/-yedek|^_/.test(f)).sort();

  if(!sayfalar.length){ console.log('KONTRAST KAPISI: kokte .html yok, atlandi.'); process.exit(0); }

  const chrome=chromeBul();
  if(!chrome){
    /* Kor kalma kurali: olcemedigimizde "temiz" demeyiz, KOR deriz.
       CI'da Chrome hazir gelir - orada yoklugu ARIZADIR, sessizce gecilmez.
       Yoksa kapi aylarca kor koşar ve yesil sanilir (mevzuat.yml 164 kez
       boyle kirmizi koştu, kimse bakmadi). */
    const ci = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';
    console.log('KONTRAST KAPISI: KOR — Chrome bulunamadi, olcum YAPILAMADI.');
    console.log('  ubuntu-latest\'te hazir gelir. Yerelde: CHROME_PATH=<yol> node arac/kontrast-kapisi.js');
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

  const bitir=(kod)=>{ try{cp.kill();}catch(e){} try{sunucu.kill();}catch(e){}
                       try{fs.rmSync(profil,{recursive:true,force:true});}catch(e){}
                       process.exit(kod); };

  /* Chrome gercek portu DevToolsActivePort dosyasina yazar */
  /* Windows'ta Chrome dosyayi yazarken kilitli tutabiliyor (EBUSY) -
     var/yok bakmak yetmez, OKUMA denemesi de try icinde olmali. */
  let dvPort=null;
  for(let i=0;i<80;i++){
    try{
      const s=fs.readFileSync(path.join(profil,'DevToolsActivePort'),'utf8').split('\n');
      if(s[0] && s[0].trim()){ dvPort=s[0].trim(); break; }
    }catch(e){ /* henuz yok ya da kilitli - beklemeye devam */ }
    await bekle(100);
  }
  if(!dvPort){ console.log('KONTRAST KAPISI: KOR — Chrome acildi ama baglanilamadi, olcum YAPILAMADI.'); bitir(1); }

  const surum=await (await fetch('http://127.0.0.1:'+dvPort+'/json/version')).json();
  const cdp=await Cdp.ac(surum.webSocketDebuggerUrl);

  console.log('KONTRAST KAPISI: '+sayfalar.length+' sayfa, esik '+ESIK_NRM+' (buyuk metin '+ESIK_BYK+').');

  const sonuc=[]; let toplamKirik=0, olculemeyen=0;
  const olcumIfade='('+OLCUM_KAYNAK.toString()+')('+ESIK_NRM+','+ESIK_BYK+')';

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
      else { toplamKirik+=v.kirik.length; sonuc.push({sayfa, bakilan:v.bakilan, kirik:v.kirik}); }
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
  console.log('  Denetlenen metin ogesi: '+sonuc.reduce((t,s)=>t+(s.bakilan||0),0));
  console.log('  Temiz sayfa: '+temiz+'/'+sayfalar.length+'   Kirik: '+toplamKirik
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
    bitir(1);
  }

  if(olculemeyen && !toplamKirik){
    console.log('');
    console.log('  Olculebilenler temiz, ama '+olculemeyen+' sayfa olculemedi.');
    bitir(1);
  }

  console.log('  Temiz - okunmayan metin yok.');
  bitir(0);
})().catch(e=>{ console.log('KONTRAST KAPISI: KOR — '+e.message); process.exit(0); });
