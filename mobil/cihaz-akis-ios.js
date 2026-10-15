#!/usr/bin/env node
/* ============================================================================
 * iOS CİHAZ AKIŞ PROVASI — iPhone simülatöründe uygulamayı WebView'in içinden sürer (16.10.2026, Cem "hepsini
 * deneyelim, Play Store gibi; çarpıya basıp kalmasınlar")
 *
 * cihaz-akis.js'in (Android, CDP) iOS ikizi. iOS'ta CDP yok → Appium XCUITest sürücüsüne düz HTTP (WebDriver) ile
 * bağlanır, ek npm paketi gerekmez:
 *   - sayfa okuma / ölçüm = WEBVIEW bağlamında JS (yalnız prova derlemesinde ios.webContentsDebuggingEnabled açık);
 *   - dokunuş GERÇEK iOS dokunuşudur (NATIVE_APP bağlamında "mobile: tap"; WebView tam ekran, contentInset never →
 *     CSS pikseli = ekran noktası, açılışta ölçülür). Önce o noktada en üstte hangi öğe var bakılır (elementFromPoint)
 *     → "✕ / bildirim tıklanmıyor" türü örtülme yakalanır;
 *   - donma: olay döngüsü gecikmesi + 2 sn boyunca 50 ms'lik saatin en uzun kayması (WebKit'te longtask yok);
 *   - JS hatası: Safari konsol günlüğü (showSafariConsoleLog) + sayfaya kurulan onerror toplayıcı;
 *   - iPhone kuralı (Apple 3.1.1 / 2.1): görünür düğme/bağlantılarda satış çağrısı OLMAMALI.
 * Akış: tanıtım → 4 sekme → Örnek sorular (şık seç, ✕'ler) → Seviye testi (3 soru) → (varsa) Ders ders çöz →
 *       her ekranda ✕ örtülme + kapanma → uygulama hâlâ ön planda mı (çökme yok).
 * Günlüğe soru metni BASILMAZ (depo public): yalnız adım adı, sayı, seçici.
 *
 * GÖRMEZ: girişli üye akışı (giriş otomasyona verilmez) · 12 sn seviye bildirimi (yalnız girişli üyede) · gerçek
 *         telefon başarımı (simülatör, Mac işlemcisi) · iPad düzeni · Apple'ın imzalı App Store derlemesi (bu Debug
 *         değil Release yapılandırmalı ama imzasız simülatör derlemesi; içerik mobil-ios.yml ile AYNI hazirla.js).
 * Çıkış: 0 = hepsi geçti · 1 = en az bir adım düştü · 2 = WebView bağlamı yok.
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
async function webBul() {
  for (let i = 0; i < 30; i++) {
    const l = await wd('GET', '/contexts');
    const w = l.filter((c) => /^WEBVIEW/.test(typeof c === 'string' ? c : c.id)).map((c) => (typeof c === 'string' ? c : c.id));
    if (w.length) { WEB = w[w.length - 1]; await baglam(WEB); return true; }
    await bekle(2000);
  }
  return false;
}
/* JS ifadesi (Promise olabilir) → değer. Sayfa değişince bağlam düşerse bir kez yeniden bağlanır. */
async function js(ifade) {
  const govde = { script: 'var cb=arguments[arguments.length-1];Promise.resolve().then(function(){return (' + ifade + ');})' +
    '.then(function(v){cb({v:v});},function(e){cb({h:String(e&&e.message||e)});});', args: [] };
  let r;
  try { r = await wd('POST', '/execute/async', govde); }
  catch (e) { await webBul(); r = await wd('POST', '/execute/async', govde); }
  if (r && r.h) throw new Error('JS: ' + r.h.slice(0, 200));
  return r ? r.v : null;
}
const hataToplayici = 'window.__ttH||(window.__ttH=[],window.addEventListener("error",function(e){window.__ttH.push(String(e.message||e).slice(0,160));}),' +
  'window.addEventListener("unhandledrejection",function(e){window.__ttH.push(String(e.reason&&e.reason.message||e.reason).slice(0,160));}),true)';
const sayfaHatalari = [];
async function sayfaHatalariniAl() {
  try { const l = await js('(window.__ttH||[]).splice(0)'); if (l) sayfaHatalari.push(...l); } catch (e) { }
}
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
async function dokun(o) {   // gerçek iOS dokunuşu
  await baglam('NATIVE_APP');
  try { await wd('POST', '/execute/sync', { script: 'mobile: tap', args: [{ x: Math.round(o.x * olcek), y: Math.round(o.y * olcek) }] }); }
  finally { await webBul(); }
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
/* kartın içindeki Başla/Devam düğmesi (yoksa kartın kendisi) */
async function kartDugmesi(desen, dugme) {
  return js(`(function(){var k=[].slice.call(document.querySelectorAll('button,a')).find(function(e){return ${desen}.test(e.innerText)&&e.getBoundingClientRect().height>0;}); if(!k) return null;
    var kap=k.closest('.kart,.satir,li,section,div')||k; var b=[].slice.call(kap.querySelectorAll('button,a')).find(function(e){return ${dugme}.test(e.innerText.trim());})||k;
    b.scrollIntoView({block:'center'}); var r=b.getBoundingClientRect(); var x=r.left+r.width/2,y=r.top+r.height/2; var u=document.elementFromPoint(x,y); return {x:x,y:y,ustte:u===b||b.contains(u)};})()`);
}

/* ================================================================ */
(async () => {
  OTURUM = '';
  const s = await wd('POST', '', { capabilities: { alwaysMatch: {
    platformName: 'iOS', 'appium:automationName': 'XCUITest', 'appium:udid': process.env.UDID, 'appium:bundleId': PAKET,
    'appium:noReset': true, 'appium:showSafariConsoleLog': true, 'appium:webviewConnectTimeout': 30000,
    'appium:wdaLaunchTimeout': 600000, 'appium:newCommandTimeout': 600, 'appium:includeSafariInWebviews': false } } });
  OTURUM = s.sessionId;
  await bekle(6000);
  if (!(await webBul())) { console.log('WEBVIEW BAGLAMI YOK (prova derlemesinde ios.webContentsDebuggingEnabled acik mi?)'); process.exit(2); }
  /* CSS pikseli ↔ ekran noktası: WebView tam ekran olmalı */
  await baglam('NATIVE_APP'); const pen = await wd('GET', '/window/rect'); await webBul();
  const ic = await js('({w:innerWidth,h:innerHeight})');
  olcek = pen.width / ic.w;
  console.log('BILGI bağlandı · ' + WEB + ' · ekran ' + pen.width + 'x' + pen.height + ' · sayfa ' + ic.w + 'x' + ic.h + ' · adres ' + (await adres()));
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
  await baglam('NATIVE_APP');
  const st = await wd('POST', '/execute/sync', { script: 'mobile: queryAppState', args: [{ bundleId: PAKET }] });
  sonuc('uygulama hâlâ ön planda (çökme yok)', st === 4, 'durum ' + st);
  await webBul(); await sayfaHatalariniAl();
  let konsol = [];
  try { konsol = (await wd('POST', '/se/log', { type: 'safariConsole' })) || []; } catch (e) { console.log('BILGI safari konsolu okunamadı: ' + e.message); }
  const konsolHata = konsol.map((k) => { try { const m = JSON.parse(k.message); return m.level === 'error' ? String(m.text || '') : ''; } catch (e) { return /error/i.test(k.level || '') ? String(k.message) : ''; } })
    .filter(Boolean).map((t) => t.split('\n')[0].slice(0, 160));
  const tekil = [...new Set([...sayfaHatalari, ...konsolHata])];
  for (const h of tekil.slice(0, 12)) console.log('JSHATA ' + h);
  sonuc('yakalanmamış JS hatası yok', sayfaHatalari.length === 0, tekil.length + ' farklı hata (konsol hataları bilgi)');

  const dus = sonuclar.filter((x) => !x.tamam).length;
  console.log('CIHAZ-AKIS-IOS: ' + (dus ? 'KIRMIZI' : 'YESIL') + ' — ' + (sonuclar.length - dus) + '/' + sonuclar.length);
  try { await wd('DELETE', ''); } catch (e) { }
  process.exit(dus ? 1 : 0);
})().catch((e) => { console.log('BETIK HATASI ' + String(e && e.message || e).slice(0, 300)); process.exit(1); });
