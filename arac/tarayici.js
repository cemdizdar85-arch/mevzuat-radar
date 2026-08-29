/* ============================================================================
   TARAYICI SURUCUSU — ORTAK MODUL

   Chrome'u basliksiz calistirir ve Chrome DevTools protokolunu konusur.
   BAGIMLILIK YOK: Node'un yerlesik fetch + WebSocket'i kullanilir.

   Iki kapi bunu paylasir (arac/kontrast-kapisi.js, arac/etkilesim-kapisi.js).
   Kopyalansaydi burada ogrenilen ayrintilar yalniz birine girerdi.

   OGRENILEN AYRINTILAR
   - Chrome nereye kuruluysa bulunur (CHROME_PATH/CHROME_BIN, bilinen yollar,
     PATH taramasi). Bulunamazsa NEREYE bakildigi da soylenir.
   - Windows'ta DevToolsActivePort dosyasi Chrome yazarken KILITLI olabilir
     (EBUSY); var/yok bakmak yetmez, OKUMA denemesi de try icinde olmali.
   - Soguk runner'da ilk acilis yavas: 20 sn beklenir.
   - Chrome'un stderr'i TOPLANIR. Acilmazsa sebebi (eksik kutuphane, sandbox,
     /dev/shm) orada yazar; toplanmazsa kimse ogrenemez.
   ============================================================================ */
'use strict';

const { spawn } = require('child_process');
const fs   = require('fs');
const path = require('path');
const os   = require('os');

const bekle = (ms) => new Promise(r => setTimeout(r, ms));

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

/* --- Chrome'u ac, CDP baglantisini kur ---------------------------------- */
/* Doner: {cdp, kapat, chrome} · Chrome yoksa {hata:'chrome-yok', bakilan}
   · acilmazsa {hata:'port-yok', chrome, stderr} */
async function tarayiciAc(){
  const chrome = chromeBul();
  if(!chrome) return { hata:'chrome-yok', bakilan: BAKILAN_YOLLAR.slice() };

  const profil = fs.mkdtempSync(path.join(os.tmpdir(), 'kontrast-'));
  const cp = spawn(chrome, [
    '--headless=new','--disable-gpu','--no-sandbox','--disable-dev-shm-usage',
    '--hide-scrollbars','--window-size=1280,900',
    '--remote-debugging-port=0', '--user-data-dir=' + profil,
    'about:blank'
  ], { stdio:['ignore','ignore','pipe'] });

  let stderr = '';
  cp.stderr.on('data', d => { if(stderr.length < 4000) stderr += d.toString(); });
  cp.on('error', e => { stderr += '\nspawn hatasi: ' + e.message; });

  const temizle = () => {
    try{ cp.kill(); }catch(e){}
    try{ fs.rmSync(profil, {recursive:true, force:true}); }catch(e){}
  };

  let dvPort = null;
  for(let i=0;i<200;i++){
    try{
      const s = fs.readFileSync(path.join(profil,'DevToolsActivePort'),'utf8').split('\n');
      if(s[0] && s[0].trim()){ dvPort = s[0].trim(); break; }
    }catch(e){ /* henuz yok ya da kilitli */ }
    await bekle(100);
  }
  if(!dvPort){ temizle(); return { hata:'port-yok', chrome, stderr: stderr.trim() }; }

  const surum = await (await fetch('http://127.0.0.1:'+dvPort+'/json/version')).json();
  const cdp = await Cdp.ac(surum.webSocketDebuggerUrl);
  return { cdp, chrome, kapat: () => { cdp.kapat(); temizle(); } };
}

module.exports = { chromeBul, BAKILAN_YOLLAR, Cdp, tarayiciAc, bekle };
