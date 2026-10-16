#!/usr/bin/env node
/* ============================================================================
 * iOS CİHAZ AKIŞ PROVASI — iPhone simülatöründe uygulamayı WebView'in içinden sürer (16.10.2026, Cem "hepsini
 * deneyelim, Play Store gibi; çarpıya basıp kalmasınlar")
 *
 * cihaz-akis.js'in (Android, CDP) iOS ikizi. iOS'ta CDP yok → Appium XCUITest sürücüsüne düz HTTP (WebDriver) ile
 * bağlanır, ek npm paketi gerekmez:
 *   - sayfa okuma / ölçüm = prova-kumanda.js köprüsü (yalnız prova derlemesine prova-kumanda-kur.js ekler; Appium'un
 *     WEBVIEW bağlamı iOS 18.6 simülatöründe görünmedi, 16.10);
 *   - dokunuş GERÇEK iOS dokunuşudur (NATIVE_APP bağlamında "mobile: tap"; WebView tam ekran, contentInset never →
 *     CSS pikseli = ekran noktası, açılışta ölçülür). Önce o noktada en üstte hangi öğe var bakılır (elementFromPoint)
 *     → "✕ / bildirim tıklanmıyor" türü örtülme yakalanır;
 *   - donma: olay döngüsü gecikmesi + 2 sn boyunca 50 ms'lik saatin en uzun kayması (WebKit'te longtask yok);
 *   - JS hatası: kumanda her sayfanın başında error/unhandledrejection dinler, köprüye bildirir;
 *   - iPhone kuralı (Apple 3.1.1 / 2.1): görünür düğme/bağlantılarda satış çağrısı OLMAMALI.
 * Akış: tanıtım → 4 sekme → Örnek sorular (şık seç, ✕'ler) → Seviye testi (3 soru) → (varsa) Ders ders çöz →
 *       her ekranda ✕ örtülme + kapanma → uygulama hâlâ ön planda mı (çökme yok).
 * Günlüğe soru metni BASILMAZ (depo public): yalnız adım adı, sayı, seçici.
 *
 * GÖRMEZ: girişli üye akışı (giriş otomasyona verilmez) · 12 sn seviye bildirimi (yalnız girişli üyede) · gerçek
 *         telefon başarımı (simülatör, Mac işlemcisi) · iPad düzeni · (iOS 18 + iOS 26 simülatöründe
 *         koşar; mobil-ios-prova.yml matrisi) · Apple'ın imzalı App Store derlemesi (bu Debug
 *         değil Release yapılandırmalı ama imzasız simülatör derlemesi; içerik mobil-ios.yml ile AYNI hazirla.js).
 * Çıkış: 0 = hepsi geçti · 1 = en az bir adım düştü · 2 = sayfa köprüsü bağlanmadı.
 * Kullanım: node cihaz-akis-ios.js <kanitKlasoru>   (ortam: APPIUM=http://127.0.0.1:4723, UDID=<simülatör>)
 * ========================================================================== */
'use strict';
const fs = require('fs');
const path = require('path');

const PAKET = 'com.tetikte.app';
const APPIUM = process.env.APPIUM || 'http://127.0.0.1:4723';
const KANIT = path.resolve(process.argv[2] || 'kanit');
fs.mkdirSync(KANIT, { recursive: true });
const DONMA_ESIK = 1500;   // ms: tek seferde bu kadar kilit = kullanıcı "takıldı" der
const sonuclar = []; let sira = 0;
const bekle = (ms) => new Promise((r) => setTimeout(r, ms));
function sonuc(ad, tamam, not) { sonuclar.push({ ad, tamam }); console.log((tamam ? 'GECTI ' : 'DUSTU ') + ad + (not ? '  — ' + not : '')); }

/* ---------- WebDriver (Appium) ---------- */
let OTURUM = '', WEB = '', olcek = 1;
/* node:http — fetch (undici) 300 sn'de keser; ilk oturumda WebDriverAgent derlemesi daha uzun sürüyor (16.10 koşu 38822058245) */
const http = require('http');
function wd(yontem, yol, govde) {
  const veri = govde ? JSON.stringify(govde) : '';
  return new Promise((res, rej) => {
    const q = http.request(APPIUM + '/session' + (OTURUM ? '/' + OTURUM : '') + yol, {
      method: yontem, headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(veri) } }, (r) => {
      let t = ''; r.setEncoding('utf8'); r.on('data', (c) => { t += c; });
      r.on('end', () => {
        let j; try { j = JSON.parse(t); } catch (e) { return rej(new Error('WD ' + yol + ': yanıt JSON değil (' + r.statusCode + ')')); }
        if (r.statusCode >= 300 || (j.value && j.value.error)) return rej(new Error('WD ' + yol + ': ' + String((j.value && (j.value.message || j.value.error)) || r.statusCode).split('\n')[0].slice(0, 200)));
        res(j.value);
      });
    });
    q.on('error', rej); q.setTimeout(0); q.end(veri);
  });
}
async function baglam(ad) { await wd('POST', '/context', { name: ad }); }

/* ---------- sayfa köprüsü (prova-kumanda.js) ----------
 * 16.10 koşu 38835785529: Appium WEBVIEW bağlamını iOS 18.6 simülatöründe GÖRMEDİ (yalnız NATIVE_APP; uygulama ön
 * planda, ayar açık). Sayfayı okumak için prova derlemesine eklenen kumanda bu sunucuya uzun yoklama yapar:
 * GET /al → sıradaki JS ifadesi · POST /ver → sonuç · POST /hata → sayfa açıldığı andan itibaren JS hataları.
 * Dokunuş + ekran görüntüsü Appium'da (NATIVE_APP) kalır. */
const KOPRU_PORT = 8777;
const sira2 = []; const bekleyenJs = new Map(); let alici = null; let sonYoklama = 0; let jsNo = 0;
const sayfaHatalari = [];
function teslim() {
  if (alici && sira2.length) { const a = alici; alici = null; clearTimeout(a.z); a.res.end(JSON.stringify(sira2.shift())); }
}
const kopru = http.createServer((q, r) => {
  r.setHeader('Access-Control-Allow-Origin', '*'); r.setHeader('Access-Control-Allow-Headers', '*');
  if (q.method === 'OPTIONS') return r.end();
  sonYoklama = Date.now();
  if (q.url.startsWith('/al')) {
    if (alici) { clearTimeout(alici.z); alici.res.end('{}'); }   // eski sayfanın yoklaması boşa döner
    alici = { res: r, z: setTimeout(() => { if (alici && alici.res === r) { alici = null; r.end('{}'); } }, 20000) };
    return teslim();
  }
  let t = ''; q.setEncoding('utf8'); q.on('data', (c) => { t += c; });
  q.on('end', () => {
    r.end('1');
    let v; try { v = JSON.parse(t); } catch (e) { return; }
    if (q.url.startsWith('/ver')) { const b = bekleyenJs.get(v.id); if (b) { bekleyenJs.delete(v.id); b(v); } }
    else if (q.url.startsWith('/hata')) sayfaHatalari.push(v.h + ' @' + v.s);
  });
});
function jsBir(ifade, sn) {
  return new Promise((res, rej) => {
    const id = ++jsNo;
    const z = setTimeout(() => { bekleyenJs.delete(id); const i = sira2.findIndex((k) => k.id === id); if (i >= 0) sira2.splice(i, 1); rej(new Error('köprü zaman aşımı')); }, (sn || 30) * 1000);
    bekleyenJs.set(id, (v) => { clearTimeout(z); v.h ? rej(new Error('JS: ' + v.h.slice(0, 200))) : res(v.v); });
    sira2.push({ id, ifade }); teslim();
  });
}
/* JS ifadesi (Promise olabilir) → değer. Sayfa geçişinde komut eski sayfada kalırsa bir kez yeniden dener. */
async function js(ifade) {
  try { return await jsBir(ifade, 15); }
  catch (e) { if (/^JS: /.test(e.message)) throw e; await bekle(1500); return jsBir(ifade, 30); }
}
async function webBul() {   // köprü bağlı mı (sayfa yoklama yapıyor mu)
  const son = Date.now() + 90000;
  while (Date.now() < son) { try { await jsBir('1', 5); return true; } catch (e) { await bekle(1000); } }
  return false;
}
const hataToplayici = '1';   // hata toplama kumandada (sayfa başında kurulur)
async function sayfaHatalariniAl() { }
async function goruntu(ad) {
  try { fs.writeFileSync(path.join(KANIT, String(++sira).padStart(2, '0') + '-' + ad + '.png'), Buffer.from(await wd('GET', '/screenshot'), 'base64')); } catch (e) { }
}

/* ---------- ölçüler ---------- */
async function donma(ad) {
  await js(hataToplayici);
  const g = await js('new Promise(function(r){var t=performance.now();setTimeout(function(){r(Math.round(performance.now()-t-100));},100);})');
  const u = await js('new Promise(function(r){var s=performance.now(),m=0,i=setInterval(function(){var n=performance.now();if(n-s-50>m)m=n-s-50;s=n;},50);' +
    'setTimeout(function(){clearInterval(i);r(Math.round(m));},2000);})');
  sonuc(ad + ': sayfa donmuyor (gecikme ' + g + ' ms, en uzun kayma ' + u + ' ms)', g < DONMA_ESIK && u < DONMA_ESIK * 2);
}
/* görünür öğe bul: seçici + (isteğe bağlı) metin deseni; merkezi + üstteki öğe kendisi mi */
async function bul(secici, metin) {
  return js(`(function(){var re=${metin ? metin.toString() : 'null'};
    var l=[].slice.call(document.querySelectorAll(${JSON.stringify(secici)})).filter(function(e){var r=e.getBoundingClientRect();
      return r.width>0&&r.height>0&&getComputedStyle(e).visibility!=='hidden'&&(!re||re.test((e.innerText||e.getAttribute('aria-label')||'').trim()));});
    if(!l.length) return null; var e=l[0]; var r=e.getBoundingClientRect();
    if(r.bottom>innerHeight||r.top<0){ e.scrollIntoView({block:'center'}); r=e.getBoundingClientRect(); }
    var x=r.left+r.width/2, y=r.top+r.height/2;
    var u=document.elementFromPoint(x,y); var k=u&&(u===e||e.contains(u));
    return {x:x,y:y,ustte:k,ortu:k?'':(u?(u.id?'#'+u.id:'')+(u.className&&typeof u.className==='string'?'.'+u.className.split(' ')[0]:'')+'<'+u.tagName+'>':'yok'),adet:l.length};})()`);
}
async function dokun(o) {   // gerçek iOS dokunuşu (oturum hep NATIVE_APP bağlamında)
  await wd('POST', '/execute/sync', { script: 'mobile: tap', args: [{ x: Math.round(o.x * olcek), y: Math.round(o.y * olcek) }] });
}
async function bekleBul(secici, metin, sn) {
  const son = Date.now() + sn * 1000;
  while (Date.now() < son) { try { const o = await bul(secici, metin); if (o) return o; } catch (e) { } await bekle(700); }
  return null;
}
async function bas(ad, secici, metin, sn) {
  const o = await bekleBul(secici, metin, sn || 20);
  if (!o) { sonuc(ad + ' bulundu', false, secici); return false; }
  if (!o.ustte) { sonuc(ad + ' dokunulabilir (örtülü değil)', false, 'üstünde ' + o.ortu); return false; }
  await dokun(o); await bekle(1500); return true;
}
async function adres() { return js('location.pathname.replace(/^.*\\/(www\\/)?/,"/")+location.search'); }

const X = '.tuKapat,[aria-label="Kapat"],.ttSeritX,.pk-x,#kutuKapat,.oyunX,.kagitKapat';
const gorunurX = `[].slice.call(document.querySelectorAll(${JSON.stringify(X)})).filter(function(e){var r=e.getBoundingClientRect();return r.width>0&&r.height>0&&r.top<innerHeight&&r.bottom>0;}).length`;
/* bütün görünür ✕'ler: örtülü mü, gerçek dokunuşla kapanıyor mu */
async function xler(ad) {
  const say = await js(gorunurX);
  if (!say) { console.log('BILGI ' + ad + ': açık ✕ yok'); return; }
  for (let i = 0; i < say; i++) {
    const o = await bul(X); if (!o) break;
    if (!o.ustte) { sonuc(ad + ': ✕ dokunulabilir', false, 'üstünde ' + o.ortu); return; }
    await dokun(o); await bekle(1200);
  }
  const kalan = await js(gorunurX);
  sonuc(ad + ': ' + say + ' ✕ dokunulabilir ve kapandı', kalan < say, say + ' → ' + kalan);
}
/* iPhone kuralı: görünür düğme/bağlantıda satış çağrısı yok (Apple 3.1.1; 08.10 reddi "kilitli yollar") */
async function satisYok(ad) {
  const l = await js(`[].slice.call(document.querySelectorAll('button,a,[role=button]')).filter(function(e){var r=e.getBoundingClientRect();
    return r.width>0&&r.height>0&&/satın al|paket seç|paketi al|paketinde yok|tam paket|₺/i.test(e.innerText||'');}).map(function(e){return (e.id?'#'+e.id:e.tagName)+':'+(e.innerText||'').trim().slice(0,30);})`);
  sonuc(ad + ': iPhone\'da satış düğmesi yok', !l.length, l.length ? l.slice(0, 3).join(' | ') : '');
}
async function anaSayfa() { await js('(location.href=location.origin+"/index.html",1)'); await bekle(4000); await webBul(); }
async function sekme(ad) {
  const ok = await bas('sekme ' + ad, '#sekmeCubugu button', new RegExp('^' + ad + '$'), 10);
  if (!ok) return false;
  const secili = await js(`[].slice.call(document.querySelectorAll('#sekmeCubugu button')).some(function(b){return b.innerText.trim()===${JSON.stringify(ad)}&&b.getAttribute('aria-selected')==='true';})`);
  sonuc('sekme ' + ad + ' seçildi', !!secili); return true;
}
/* 16.10 (Cem "ölç"): örnek soruda cevaptan sonra "Sonraki" / "Daha fazla" ekranın alt kenarında, ana ekran çizgisi
   hizasında görünüyordu (koşu 38838202866 görüntü 10). Ölçülen: ilk görünümde güvenli alana (home indicator) taşıyor mu,
   kaydırınca tamamı güvenli alanın üstüne geliyor ve en üstteki öğe kendisi mi, "Sonraki"ye gerçek dokunuş soruyu ilerletiyor mu. */
async function altDugmeler(ad) {
  const olc = (desen) => js(`(function(){var pr=document.createElement('div');pr.style.cssText='position:fixed;bottom:0;height:env(safe-area-inset-bottom);width:1px;pointer-events:none';
    document.body.appendChild(pr);var g=pr.offsetHeight;pr.remove();var sinir=innerHeight-g;
    var b=[].slice.call(document.querySelectorAll('button,a')).filter(function(e){var r=e.getBoundingClientRect();return r.width>0&&r.height>0&&${desen}.test((e.innerText||'').trim());})[0];
    if(!b) return null; var r=b.getBoundingClientRect(); var x=r.left+r.width/2,y=Math.min(r.top+r.height/2,innerHeight-1);var u=document.elementFromPoint(x,y);
    return {alt:Math.round(r.bottom),ust:Math.round(r.top),sinir:Math.round(sinir),guvenli:g,ic:innerHeight,tasma:Math.max(0,Math.round(r.bottom-sinir)),x:x,y:r.top+r.height/2,ustte:!!u&&(u===b||b.contains(u))};})()`);
  const kaydir = (desen) => js(`(function(){var b=[].slice.call(document.querySelectorAll('button,a')).filter(function(e){var r=e.getBoundingClientRect();return r.width>0&&r.height>0&&${desen}.test((e.innerText||'').trim());})[0];
    if(b) b.scrollIntoView({block:'end'}); window.scrollTo(0,document.scrollingElement.scrollHeight); return !!b;})()`);
  for (const [etiket, desen] of [['Sonraki', '/^Sonraki/'], ['Daha fazla', '/Daha fazla/']]) {
    const ilk = await olc(desen);
    if (!ilk) { console.log('BILGI ' + ad + ': "' + etiket + '" düğmesi yok'); continue; }
    console.log('BILGI ' + ad + ' "' + etiket + '" ilk görünüm: alt ' + ilk.alt + ' · güvenli sınır ' + ilk.sinir + ' (alt boşluk ' + ilk.guvenli + ', ekran ' + ilk.ic + ') · taşma ' + ilk.tasma + ' px');
    await kaydir(desen); await bekle(800);
    const son = await olc(desen);
    await goruntu('alt-' + etiket.replace(/\s/g, ''));
    sonuc(ad + ': "' + etiket + '" kaydırınca tamamı ana ekran çizgisinin üstünde', son && son.tasma === 0 && son.ust >= 0, son ? 'alt ' + son.alt + ' / sınır ' + son.sinir + ' · taşma ' + son.tasma + ' px' : 'kayboldu');
    sonuc(ad + ': "' + etiket + '" dokunulabilir (örtülü değil)', !!(son && son.ustte));
  }
  /* "Sonraki" gerçekten ilerletiyor mu (üstteki "1/5" sayacı) */
  const sayac = () => js(`(function(){var e=[].slice.call(document.querySelectorAll('body *')).filter(function(e){return e.children.length===0&&/^\\d+\\/\\d+$/.test((e.textContent||'').trim())&&e.getBoundingClientRect().height>0;})[0];return e?e.textContent.trim():null;})()`);
  const once = await sayac();
  const s = await olc('/^Sonraki/');
  if (s && s.ustte && s.tasma === 0) {
    await dokun(s); await bekle(2000);
    const sonra = await sayac();
    await goruntu('sonraki-dokunuldu');
    sonuc(ad + ': "Sonraki"ye dokununca sonraki soruya geçti', !!once && !!sonra && once !== sonra, once + ' → ' + sonra);
  }
}
/* kartın içindeki Başla/Devam düğmesi (yoksa kartın kendisi) */
async function kartDugmesi(desen, dugme) {
  return js(`(function(){var k=[].slice.call(document.querySelectorAll('button,a')).find(function(e){return ${desen}.test(e.innerText)&&e.getBoundingClientRect().height>0;}); if(!k) return null;
    var kap=k.closest('.kart,.satir,li,section,div')||k; var b=[].slice.call(kap.querySelectorAll('button,a')).find(function(e){return ${dugme}.test(e.innerText.trim());})||k;
    b.scrollIntoView({block:'center'}); var r=b.getBoundingClientRect(); var x=r.left+r.width/2,y=r.top+r.height/2; var u=document.elementFromPoint(x,y); return {x:x,y:y,ustte:u===b||b.contains(u)};})()`);
}

/* ================================================================ */
(async () => {
  await new Promise((r) => kopru.listen(KOPRU_PORT, '127.0.0.1', r));
  OTURUM = '';
  const s = await wd('POST', '', { capabilities: { alwaysMatch: {
    platformName: 'iOS', 'appium:automationName': 'XCUITest', 'appium:udid': process.env.UDID, 'appium:bundleId': PAKET,
    'appium:noReset': true, 'appium:wdaLaunchTimeout': 600000,
    /* WDA Xcode 16.4 ile önceden derlenip simülatöre kuruldu (Xcode 26 simülatör platformunda derlenemiyor, 16.10) */
    ...(process.env.WDA_APP ? { 'appium:usePreinstalledWDA': true, 'appium:prebuiltWDAPath': process.env.WDA_APP } : {}), 'appium:simulatorStartupTimeout': 600000, 'appium:newCommandTimeout': 600 } } });
  OTURUM = s.sessionId;
  await bekle(4000);
  try { console.log('BILGI uygulama durumu ' + (await wd('POST', '/execute/sync', { script: 'mobile: queryAppState', args: [{ bundleId: PAKET }] }))); } catch (e) { }
  if (!(await webBul())) {
    await goruntu('kopru-yok');
    console.log('SAYFA KOPRUSU YOK · son yoklama ' + (sonYoklama ? Math.round((Date.now() - sonYoklama) / 1000) + ' sn önce' : 'hiç') +
      ' · sayfa hataları ' + JSON.stringify(sayfaHatalari.slice(0, 3)));
    process.exit(2);
  }
  /* CSS pikseli ↔ ekran noktası: WebView tam ekran olmalı */
  const pen = await wd('GET', '/window/rect');
  const ic = await js('({w:innerWidth,h:innerHeight})');
  olcek = pen.width / ic.w;
  console.log('BILGI bağlandı (sayfa köprüsü) · ekran ' + pen.width + 'x' + pen.height + ' · sayfa ' + ic.w + 'x' + ic.h + ' · adres ' + (await adres()));
  sonuc('WebView tam ekran (dokunuş koordinatı doğru)', Math.abs(olcek - 1) < 0.02 && Math.abs(pen.height - ic.h * olcek) < 2, 'ölçek ' + olcek.toFixed(3));
  await js(hataToplayici);
  sonuc('uygulama iOS kipinde (yalnız ücretsiz)', !!(await js('!!(window.TT&&TT.yalnizUcretsiz&&TT.yalnizUcretsiz())')));

  // 1) tanıtım
  if (await bas('tanıtım Başla', '.kAlt .ana', /^Başla$/, 30)) {
    await goruntu('tanitim-1');
    if (await bas('tanıtım SGS kartı', '.sinavKart[data-v="sgs"]', null, 10)) {
      await goruntu('tanitim-2');
      if (await bas('tanıtım tempo 20', '.tKart[data-v="20"]', null, 10)) {
        await goruntu('tanitim-3');
        const hic = await bekleBul('.hic', null, 5); if (hic) { await dokun(hic); await bekle(1500); }
      }
    }
  }
  await bekle(2000); await goruntu('tanitim-bitti');
  sonuc('tanıtımdan sonra alt menü görünür', !!(await bekleBul('#sekmeCubugu button', /^Sınavlar$/, 15)));
  await donma('ana ekran');

  // 2) sekmeler
  for (const s2 of ['Sınavlar', 'Karnem', 'Hesap', 'Bugün']) {
    await sekme(s2); await goruntu('sekme-' + s2.normalize('NFD').replace(/[^\w]/g, '')); await satisYok('sekme ' + s2);
  }
  await xler('ana ekran');

  // 3) örnek sorular → şık seç
  await sekme('Sınavlar');
  const d = await kartDugmesi('/Örnek sorular/', '/^(Başla|Devam et)/');
  let girdi = false;
  if (!d) sonuc('örnek sorular kartı bulundu', false);
  else if (!d.ustte) sonuc('örnek sorular düğmesi dokunulabilir', false);
  else { await dokun(d); girdi = true; }
  if (girdi) {
    const sik = await bekleBul('.sik', null, 45);
    await goruntu('ornek-soru');
    sonuc('örnek soru 45 sn içinde yüklendi', !!sik, 'adres ' + (await adres()));
    if (sik) {
      await donma('örnek soru');
      const durum = '(function(){var s=document.querySelector(".sik");return s.parentElement.innerHTML.length+"|"+document.querySelectorAll(".dogru,.yanlis,.secildi,.acik").length;})()';
      const once = await js(durum);
      const ok = await bas('şık A', '.sik[data-h="A"]', null, 5);
      await bekle(1500); await goruntu('ornek-sik-secildi');
      const sonra = await js(durum);
      sonuc('şıkka dokununca cevap işlendi (ekran değişti)', ok && sonra !== once, once + ' → ' + sonra);
      await donma('örnek soru cevap sonrası');
      await satisYok('örnek soru');
      await altDugmeler('örnek soru cevap sonrası');
      await xler('örnek soru');
    }
  }

  // 4) seviye testi (girişsiz ilk sorular)
  await anaSayfa(); await sekme('Sınavlar');
  const sv = await kartDugmesi('/seviyeni ölç/i', '/^Başla/');
  if (!sv) sonuc('seviye testi kartı bulundu', false);
  else if (!sv.ustte) sonuc('seviye testi düğmesi dokunulabilir', false);
  else {
    await dokun(sv); await bekle(4000);
    const bas1 = await bekleBul('button', /^(Başla|Teste başla|Hadi başla|Başlat)/, 8); if (bas1 && bas1.ustte) { await dokun(bas1); await bekle(3000); }
    await goruntu('seviye-acildi');
    const no = async () => +(await js('(document.getElementById("svNo")||{}).textContent||0'));
    const ilk = await no(); let son = ilk;
    for (let i = 0; i < 3; i++) {
      const once = await no();
      if (!(await bas('seviye şık A (soru ' + once + ')', '.sv-sik[data-h="A"]', null, 30))) break;
      if (!(await bas('seviye Cevapla', '#svCevapla', null, 5))) break;
      for (let j = 0; j < 10 && (await no()) === once; j++) {
        const ileri = await bul('button', /^(Sonraki|Devam|İleri)/); if (ileri && ileri.ustte) await dokun(ileri);
        await bekle(1000);
      }
      son = await no(); if (son === once) break;
    }
    await goruntu('seviye-3-soru');
    sonuc('seviye testinde sayaç 3 soru ilerledi', son - ilk === 3, ilk + ' → ' + son + ' · adres ' + (await adres()));
    await donma('seviye testi');
    await satisYok('seviye testi');
    await xler('seviye testi');
  }

  // 5) Ders ders çöz (iPhone'da kilitli dersler gizli olabilir → yoksa bilgi)
  await anaSayfa(); await sekme('Sınavlar');
  if (await bekleBul('button,a', /Ders ders çöz/, 6)) {
    if (await bas('Ders ders çöz', 'button,a', /Ders ders çöz/, 5)) {
      await goruntu('ders-listesi'); await satisYok('ders listesi');
      if (await bekleBul('button,a,li', /^Denetim\b/, 8) && await bas('ders Denetim', 'button,a,li', /^Denetim\b/, 5)) {
        await bekle(8000); await goruntu('denetim');
        await donma('Denetim ders sayfası'); await satisYok('Denetim ders sayfası'); await xler('Denetim ders sayfası');
      }
    }
  } else console.log('BILGI iPhone\'da "Ders ders çöz" görünmüyor (yalnız ücretsiz kip)');

  // 6) çökme / JS hataları
  const st = await wd('POST', '/execute/sync', { script: 'mobile: queryAppState', args: [{ bundleId: PAKET }] });
  sonuc('uygulama hâlâ ön planda (çökme yok)', st === 4, 'durum ' + st);
  const tekil = [...new Set(sayfaHatalari)];
  for (const h of tekil.slice(0, 12)) console.log('JSHATA ' + h);
  sonuc('yakalanmamış JS hatası yok', tekil.length === 0, tekil.length + ' farklı hata');

  const dus = sonuclar.filter((x) => !x.tamam).length;
  console.log('CIHAZ-AKIS-IOS: ' + (dus ? 'KIRMIZI' : 'YESIL') + ' — ' + (sonuclar.length - dus) + '/' + sonuclar.length);
  try { await wd('DELETE', ''); } catch (e) { }
  process.exit(dus ? 1 : 0);
})().catch((e) => { console.log('BETIK HATASI ' + String(e && e.message || e).slice(0, 300)); process.exit(1); });
