#!/usr/bin/env node
/* ============================================================================
 * CİHAZ AKIŞ PROVASI — uygulamayı WebView'in İÇİNDEN sürer (15.10.2026, Cem "soru ve ders akışını ölç")
 *
 * Neden: cihaz-prova.js uiautomator ile ekranı okuyordu; döküm tanıtım katmanını görmüyor, arkadaki gizli sayfayı
 * veriyor (15.10 üç koşu). Bu betik yalnız PROVA derlemesinde açılan WebView hata ayıklama soketine (CDP) bağlanır:
 *   - dokunuş GERÇEK dokunma olayıdır (Input.dispatchTouchEvent) ve önce o noktada en üstte hangi öğe var bakılır
 *     (elementFromPoint) → "bildirim tıklanmıyor" türü örtülme yakalanır;
 *   - her ekranda donma ölçülür: olay döngüsü gecikmesi (100 ms zamanlayıcı ne kadar gecikti) + en uzun kilit
 *     (PerformanceObserver longtask) + yakalanmamış JS hatası.
 * Akış: tanıtım (Başla → SGS → tempo → hatırlatma yok) → 4 sekme → Örnek sorular (şık seç, ✕'ler) →
 *       Seviye testi (3 soru) → Ders ders çöz → Denetim (girişsiz) → bulunan her ✕ örtülme + kapanma.
 * Günlüğe soru metni BASILMAZ (depo public): yalnız adım adı, sayı, seçici.
 *
 * GÖRMEZ: girişli/paketli üye akışı (giriş otomasyona verilmez) · 12 sn seviye bildirimi (yalnız girişli üyede) ·
 *         gerçek telefon başarımı (x86_64 emülatör, yazılım GPU) · iOS. Play derlemesinde hata ayıklama KAPALI.
 * Çıkış: 0 = hepsi geçti · 1 = en az bir adım düştü · 2 = WebView soketi yok.
 * ========================================================================== */
'use strict';
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PAKET = 'com.tetikte.app';
const KANIT = path.resolve(process.argv[2] || 'kanit');
fs.mkdirSync(KANIT, { recursive: true });
const DONMA_ESIK = 1500;   // ms: tek seferde bu kadar kilit = kullanıcı "takıldı" der
const sonuclar = []; let sira = 0;
const adb = (a) => execFileSync('adb', a, { encoding: 'utf8', maxBuffer: 64 << 20 });
const bekle = (ms) => new Promise((r) => setTimeout(r, ms));
function sonuc(ad, tamam, not) { sonuclar.push({ ad, tamam }); console.log((tamam ? 'GECTI ' : 'DUSTU ') + ad + (not ? '  — ' + not : '')); }
function goruntu(ad) {
  fs.writeFileSync(path.join(KANIT, String(++sira).padStart(2, '0') + '-' + ad + '.png'), execFileSync('adb', ['exec-out', 'screencap', '-p'], { maxBuffer: 64 << 20 }));
}

/* ---------- CDP bağlantısı ---------- */
let ws, kimlik = 0; const bekleyen = new Map(); const hatalar = [];
function cdp(method, params) {
  return new Promise((res, rej) => {
    const id = ++kimlik; bekleyen.set(id, { res, rej });
    ws.send(JSON.stringify({ id, method, params: params || {} }));
    setTimeout(() => { if (bekleyen.has(id)) { bekleyen.delete(id); rej(new Error('CDP zaman aşımı: ' + method)); } }, 30000);
  });
}
async function js(ifade) {
  const r = await cdp('Runtime.evaluate', { expression: ifade, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error('JS: ' + (r.exceptionDetails.exception && r.exceptionDetails.exception.description || r.exceptionDetails.text).slice(0, 200));
  return r.result.value;
}
async function baglan() {
  let soket = '';
  for (let i = 0; i < 30 && !soket; i++) {
    const m = adb(['shell', 'cat', '/proc/net/unix']).match(/@(webview_devtools_remote_\d+)/);
    if (m) soket = m[1]; else await bekle(2000);
  }
  if (!soket) return false;
  adb(['forward', 'tcp:9333', 'localabstract:' + soket]);
  let sayfa = null;
  for (let i = 0; i < 20 && !sayfa; i++) {
    try { sayfa = (await (await fetch('http://127.0.0.1:9333/json')).json()).find((p) => p.type === 'page'); } catch (e) { }
    if (!sayfa) await bekle(1500);
  }
  if (!sayfa) return false;
  ws = new WebSocket(sayfa.webSocketDebuggerUrl);
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  ws.onmessage = (m) => {
    const v = JSON.parse(m.data);
    if (v.id && bekleyen.has(v.id)) { const b = bekleyen.get(v.id); bekleyen.delete(v.id); v.error ? b.rej(new Error(v.error.message)) : b.res(v.result); return; }
    if (v.method === 'Runtime.exceptionThrown') hatalar.push(((v.params.exceptionDetails.exception || {}).description || v.params.exceptionDetails.text || '').split('\n')[0].slice(0, 160));
  };
  await cdp('Runtime.enable'); await cdp('Page.enable');
  /* her yeni belgede: en uzun kilit ölçeri */
  await cdp('Page.addScriptToEvaluateOnNewDocument', { source:
    'window.__ttUzun=0;try{new PerformanceObserver(function(l){l.getEntries().forEach(function(e){if(e.duration>window.__ttUzun)window.__ttUzun=e.duration;});}).observe({type:"longtask",buffered:true});}catch(e){}' });
  return true;
}

/* ---------- ölçüler ---------- */
async function donma(ad) {   // olay döngüsü gecikmesi + o belgedeki en uzun kilit
  const g = await js('new Promise(r=>{const t=performance.now();setTimeout(()=>r(Math.round(performance.now()-t-100)),100)})');
  const u = Math.round(await js('window.__ttUzun||0'));
  sonuc(ad + ': sayfa donmuyor (gecikme ' + g + ' ms, en uzun kilit ' + u + ' ms)', g < DONMA_ESIK && u < DONMA_ESIK * 2);
}
/* görünür öğe bul: seçici + (isteğe bağlı) metin deseni; merkezi + üstteki öğe kendisi mi */
async function bul(secici, metin) {
  return js(`(()=>{const re=${metin ? metin.toString() : 'null'};
    const l=[...document.querySelectorAll(${JSON.stringify(secici)})].filter(e=>{const r=e.getBoundingClientRect();
      return r.width>0&&r.height>0&&getComputedStyle(e).visibility!=='hidden'&&(!re||re.test((e.innerText||e.getAttribute('aria-label')||'').trim()));});
    if(!l.length) return null; const e=l[0]; let r=e.getBoundingClientRect();
    /* ekran dışındaysa önce görünür alana kaydır (kullanıcı da kaydırır); 15.10: "Cevapla" alt kenarın altındaydı */
    if(r.bottom>innerHeight||r.top<0){ e.scrollIntoView({block:'center'}); r=e.getBoundingClientRect(); }
    const x=r.left+r.width/2, y=r.top+r.height/2;
    const u=document.elementFromPoint(x,y); const k=u&&(u===e||e.contains(u));
    return {x,y,ustte:k,ortu:k?'':(u?(u.id?'#'+u.id:'')+(u.className&&typeof u.className==='string'?'.'+u.className.split(' ')[0]:'')+'<'+u.tagName+'>':'yok'),adet:l.length};})()`);
}
async function dokun(o) {
  const t = [{ x: o.x, y: o.y }];
  await cdp('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: t });
  await cdp('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
}
async function bekleBul(secici, metin, sn) {
  const son = Date.now() + sn * 1000;
  while (Date.now() < son) { try { const o = await bul(secici, metin); if (o) return o; } catch (e) { } await bekle(700); }
  return null;
}
/* bul → örtülü mü → dokun; örtülüyse DUSTU (asıl aradığımız hata) */
async function bas(ad, secici, metin, sn) {
  const o = await bekleBul(secici, metin, sn || 20);
  if (!o) { sonuc(ad + ' bulundu', false, secici); return false; }
  if (!o.ustte) { sonuc(ad + ' dokunulabilir (örtülü değil)', false, 'üstünde ' + o.ortu); return false; }
  await dokun(o); await bekle(1500); return true;
}
async function adres() { return js('location.pathname.replace(/^.*\\/(www\\/)?/,"/")+location.search'); }

/* bütün görünür ✕'ler + çıkışsız katmanlar (28.10: ortak katman-tarama.js; eski 7 sınıflık liste ✕'i metinden tanımıyordu,
   ✕'siz kaplayan katmanı hiç aramıyordu — Cem "çarpı geldi basamadık ilerleyemedik olmasın") */
const KT = require('./katman-tarama');
const A = { js: (e) => js(e), bul: (s, m) => bul(s, m), dokun: (o) => dokun(o), bekle: (ms) => bekle(ms), sonuc: (a, t, n) => sonuc(a, t, n) };
async function xler(ad) { return KT.katmanTara(A, ad); }
async function anaSayfa() {
  await js('location.href=location.origin+"/index.html"'); await bekle(4000);
}
async function sekme(ad) {
  const ok = await bas('sekme ' + ad, '#sekmeCubugu button', new RegExp('^' + ad + '$'), 10);
  if (!ok) return false;
  const secili = await js(`[...document.querySelectorAll('#sekmeCubugu button')].some(b=>b.innerText.trim()===${JSON.stringify(ad)}&&b.getAttribute('aria-selected')==='true')`);
  sonuc('sekme ' + ad + ' seçildi', !!secili); return true;
}

/* ================================================================ */
(async () => {
  adb(['logcat', '-c']);
  adb(['shell', 'am', 'broadcast', '-a', 'android.intent.action.CLOSE_SYSTEM_DIALOGS']);
  adb(['shell', 'monkey', '-p', PAKET, '-c', 'android.intent.category.LAUNCHER', '1']);
  await bekle(6000);
  if (!(await baglan())) { console.log('WEBVIEW SOKETI YOK (prova derlemesinde webContentsDebuggingEnabled acik mi?)'); process.exit(2); }
  console.log('BILGI bağlandı · adres ' + (await adres()));

  // 1) tanıtım
  if (await bas('tanıtım Başla', '.kAlt .ana', /^Başla$/, 30)) {
    goruntu('tanitim-1');
    if (await bas('tanıtım SGS kartı', '.sinavKart[data-v="sgs"]', null, 10)) {
      goruntu('tanitim-2');
      if (await bas('tanıtım tempo 20', '.tKart[data-v="20"]', null, 10)) {
        goruntu('tanitim-3');
        const hic = await bekleBul('.hic', null, 5); if (hic) { await dokun(hic); await bekle(1500); }
      }
    }
  }
  await bekle(2000); goruntu('tanitim-bitti');
  sonuc('tanıtımdan sonra alt menü görünür', !!(await bekleBul('#sekmeCubugu button', /^Sınavlar$/, 15)));
  await donma('ana ekran');

  // 2) sekmeler
  for (const s of ['Sınavlar', 'Karnem', 'Hesap', 'Bugün']) { await sekme(s); goruntu('sekme-' + s.normalize('NFD').replace(/[^\w]/g, '')); }
  await xler('ana ekran');
  /* 28.10: sürüm şeridi gerçek telefonda eski sürümde çıkar, provada hiç görünmüyordu → eski sürüm taklidiyle zorla aç + ✕ */
  await anaSayfa(); await KT.surumSeridi(A);

  // 3) örnek sorular → şık seç
  await sekme('Sınavlar');
  const ornekKart = await bekleBul('button,a', /Örnek sorular/, 10);
  let girdi = false;
  if (ornekKart) {
    // kartın içindeki düğme (Başla / Devam et) ya da kartın kendisi
    const d = await js(`(()=>{const k=[...document.querySelectorAll('button,a')].find(e=>/Örnek sorular/.test(e.innerText)&&e.getBoundingClientRect().height>0);
      const kap=k.closest('.kart,.satir,li,section,div')||k; const b=[...kap.querySelectorAll('button,a')].find(e=>/^(Başla|Devam et)/.test(e.innerText.trim()))||k;
      const r=b.getBoundingClientRect(); const x=r.left+r.width/2,y=r.top+r.height/2; const u=document.elementFromPoint(x,y); return {x,y,ustte:u===b||b.contains(u)};})()`);
    if (d.ustte) { await dokun(d); girdi = true; } else sonuc('örnek sorular düğmesi dokunulabilir', false);
  } else sonuc('örnek sorular kartı bulundu', false);
  if (girdi) {
    const sik = await bekleBul('.sik', null, 45);
    goruntu('ornek-soru');
    sonuc('örnek soru 45 sn içinde yüklendi', !!sik, 'adres ' + (await adres()));
    if (sik) {
      await donma('örnek soru');
      const once = await js('document.querySelector(".sik").parentElement.innerHTML.length+"|"+document.querySelectorAll(".dogru,.yanlis,.secildi,.acik").length');
      const ok = await bas('şık A', '.sik[data-h="A"]', null, 5);
      await bekle(1500); goruntu('ornek-sik-secildi');
      const sonra = await js('document.querySelector(".sik").parentElement.innerHTML.length+"|"+document.querySelectorAll(".dogru,.yanlis,.secildi,.acik").length');
      sonuc('şıkka dokununca cevap işlendi (ekran değişti)', ok && sonra !== once, once + ' → ' + sonra);
      await donma('örnek soru cevap sonrası');
      await xler('örnek soru');
    }
  }

  // 4) seviye testi (girişsiz ilk sorular)
  await anaSayfa(); await sekme('Sınavlar');
  const sv = await js(`(()=>{const k=[...document.querySelectorAll('button,a')].find(e=>/seviyeni ölç/i.test(e.innerText)&&e.getBoundingClientRect().height>0); if(!k) return null;
      const kap=k.closest('.kart,.satir,li,section,div')||k; const b=[...kap.querySelectorAll('button,a')].find(e=>/^Başla/.test(e.innerText.trim()))||k;
      const r=b.getBoundingClientRect(); const x=r.left+r.width/2,y=r.top+r.height/2; const u=document.elementFromPoint(x,y); return {x,y,ustte:u===b||b.contains(u)};})()`);
  /* 28.10: 30 soruluk seviye testi kartı 27.10'da bilerek kapandı (246eeb30, uygulama-sinavlar.js `if (false && …)`; Cem 17.10 "30 soru
     çözdürmeyelim, 5 örnek soru"). Kartın YOKLUĞU artık beklenen durum; geri gelirse aşağıdaki akış yine sınar. */
  if (!sv) sonuc('30 soruluk seviye testi kartı yok (17.10 kararı; giriş 5 örnek soru)', true);
  else if (!sv.ustte) sonuc('seviye testi düğmesi dokunulabilir', false);
  else {
    await dokun(sv); await bekle(4000);
    // seviye sayfasında başlat düğmesi olabilir
    const bas1 = await bekleBul('button', /^(Başla|Teste başla|Hadi başla|Başlat)/, 8); if (bas1 && bas1.ustte) { await dokun(bas1); await bekle(3000); }
    goruntu('seviye-acildi');
    /* 15.10 dördüncü koşu: eski döngü aynı soruya 3 kez dokunup "3/3" diyordu (görüntüde Soru 1/30 kaldı) → artık
       şık + "Cevapla" ve sayaç (#svNo) GERÇEKTEN ilerlemeli. */
    const no = async () => +(await js('(document.getElementById("svNo")||{}).textContent||0'));
    const ilk = await no(); let son = ilk;
    for (let i = 0; i < 3; i++) {
      const once = await no();
      if (!(await bas('seviye şık A (soru ' + once + ')', '.sv-sik[data-h="A"]', null, 30))) break;
      if (!(await bas('seviye Cevapla', '#svCevapla', null, 5))) break;
      for (let j = 0; j < 10 && (await no()) === once; j++) {   // geri bildirim + "Sonraki" olabilir
        const ileri = await bul('button', /^(Sonraki|Devam|İleri)/); if (ileri && ileri.ustte) await dokun(ileri);
        await bekle(1000);
      }
      son = await no(); if (son === once) break;
    }
    goruntu('seviye-3-soru');
    sonuc('seviye testinde sayaç 3 soru ilerledi', son - ilk === 3, ilk + ' → ' + son + ' · adres ' + (await adres()));
    await donma('seviye testi');
    await xler('seviye testi');
  }

  // 4b) 31.10 1.9.1 (Ders ders çöz’den ÖNCE: o adım Sınavlar sekmesini ders listesinde bırakıyor, ilk koşu 41214243165 satırı bulamadı): Son 20 Gün (Sınavlar → "Son 20 Gün denemeleri" → son-20-gun.html; denemeler sunucudan s20_liste)
  await anaSayfa(); await sekme('Sınavlar');
  if (!(await bekleBul('a', /Son 20 Gün denemeleri/, 10))) console.log('BILGI Son 20 Gün yok · sınavlar ekranı: ' + String(await js('(document.getElementById("sinavUst")||{}).innerText||""')).replace(/s+/g, ' ').slice(0, 300));
  if (await bas('Son 20 Gün satırı', 'a', /Son 20 Gün denemeleri/, 10)) {
    const dn = await bekleBul('#denemeler .dn', null, 30);
    await bekle(1500); goruntu('son-20-gun');
    const d = await js(`({a:location.pathname.replace(/^.*\\//,''), dn:document.querySelectorAll('#denemeler .dn').length,
      satis:[...document.querySelectorAll('a')].filter(a=>/satin-al|fiyat\\.html|gktPaket/.test(a.getAttribute('href')||'')).length,
      paket:[...document.querySelectorAll('#kapi a')].map(a=>a.getAttribute('href')).join(',')})`);
    sonuc('Son 20 Gün sayfası açıldı, 7 deneme sunucudan geldi', d.a === 'son-20-gun.html' && d.dn === 7 && !!dn, JSON.stringify(d));
    sonuc('Son 20 Gün: site satış bağı yok, giriş/paket uygulama içinde', d.satis === 0 && /index\.html#giris/.test(d.paket) && /index\.html#paketler/.test(d.paket), d.paket);
    await donma('Son 20 Gün');
    await xler('Son 20 Gün');
  }

  // 5) Ders ders çöz → Denetim (girişsiz)
  await anaSayfa(); await sekme('Sınavlar');
  if (await bas('Ders ders çöz', 'button,a', /Ders ders çöz/, 10)) {
    goruntu('ders-listesi');
    if (await bas('ders Denetim', 'button,a,li', /^Denetim\b/, 15)) {
      await bekle(8000); goruntu('denetim');
      console.log('BILGI denetim adres ' + (await adres()) + ' · şık ' + (await js('document.querySelectorAll(".sik").length')) +
        ' · perde ' + (await js('!!document.querySelector(".pk-perde,.ttPerde,[class*=perde]")')));
      await donma('Denetim ders sayfası');
      await xler('Denetim ders sayfası');
    }
  }

  // 6) çökme / ANR / JS hataları
  const log = adb(['logcat', '-d', '-b', 'crash,main,system']);
  sonuc('çökme yok (FATAL EXCEPTION)', !/FATAL EXCEPTION[\s\S]{0,200}com\.tetikte/.test(log));
  sonuc('donma yok (ANR in com.tetikte)', !/ANR in com\.tetikte/.test(log));
  const tekil = [...new Set(hatalar)];
  for (const h of tekil.slice(0, 12)) console.log('JSHATA ' + h);
  sonuc('yakalanmamış JS hatası yok', tekil.length === 0, tekil.length + ' farklı hata');

  const dus = sonuclar.filter((s) => !s.tamam).length;
  console.log('CIHAZ-AKIS: ' + (dus ? 'KIRMIZI' : 'YESIL') + ' — ' + (sonuclar.length - dus) + '/' + sonuclar.length);
  try { ws.close(); } catch (e) { }
  process.exit(dus ? 1 : 0);
})().catch((e) => { console.log('BETIK HATASI ' + String(e && e.message || e).slice(0, 300)); process.exit(1); });
