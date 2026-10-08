#!/usr/bin/env node
/* ============================================================================
 *  SİTE YAYINI EŞDEĞERLİK PROVASI (08.10.2026) — beyaz listeli yayın, canlıdaki siteyi eksiksiz taşıyor mu?
 *
 *  Üç kip:
 *   --tara   tarayıcıyla (Chrome, arac/tarayici.js) siteyi gezer: her sayfa telefon (390) + masaüstü (1280)
 *            açılır, aynı kökenden yapılan BÜTÜN ağ istekleri (JS fetch dahil) durumuyla ve sayfadaki
 *            bağlantılar toplanır; bağlantılar --derinlik kadar izlenir. Önizleme kapısı (?kapi=) bir kez açılır.
 *              node arac/site-esdegerlik.js --tara --taban https://tetikte.com --tohum tohum.txt --derinlik 3 --cikti canli.json
 *   --sun    yayın klasörünü GitHub Pages gibi sunar (klasör/ -> index.html, uzantısız -> .html, yoksa 404.html + 404)
 *              node arac/site-esdegerlik.js --sun _site --port 8787
 *   --kiyas  canlı taramada 200 dönen HER yolu yeni yayında ister (200) + iç dosya listesini ister (404)
 *              node arac/site-esdegerlik.js --kiyas --canli canli.json --yeni http://127.0.0.1:8787 [--ic ic.txt] [--rapor r.json]
 *
 *  🚫 GÖRMEZ: oturum isteyen içerik (Hesabım, paketli soru) · tıklayınca açılan içerik · taramada hiç anılmayan
 *     ama dışarıdan (e-posta, Instagram) bağlantı verilen dosya (bunun için ayrıca --ek ile yol listesi verilir) ·
 *     başka kökene (Supabase, CDN) giden istek.
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), http = require('http');
const a = process.argv.slice(2), arg = (k, v) => { const i = a.indexOf(k); return i > -1 ? a[i + 1] : v; };

/* ------------------------------------------------------------------ SUN */
if (a.includes('--sun')) {
  const kok = path.resolve(arg('--sun')), port = +arg('--port', 8787);
  const TUR = { html: 'text/html; charset=utf-8', js: 'text/javascript', css: 'text/css', json: 'application/json', png: 'image/png', jpg: 'image/jpeg', svg: 'image/svg+xml', pdf: 'application/pdf', webmanifest: 'application/manifest+json', woff2: 'font/woff2', xml: 'application/xml', txt: 'text/plain' };
  http.createServer((q, s) => {
    let y; try { y = decodeURIComponent(new URL(q.url, 'http://x').pathname); } catch (e) { s.writeHead(400); return s.end(); }
    const dosya = p => { try { return fs.statSync(p).isFile() ? p : null; } catch (e) { return null; } };
    const klasor = p => { try { return fs.statSync(p).isDirectory(); } catch (e) { return false; } };
    const tam = path.join(kok, y);
    if (!tam.startsWith(kok)) { s.writeHead(403); return s.end(); }
    let bul = null;
    if (y.endsWith('/')) bul = dosya(path.join(tam, 'index.html'));
    else if (klasor(tam) && dosya(path.join(tam, 'index.html'))) { s.writeHead(301, { Location: y + '/' }); return s.end(); }
    else bul = dosya(tam) || (!path.extname(y) ? dosya(tam + '.html') : null);
    if (!bul) { const n = dosya(path.join(kok, '404.html')); s.writeHead(404, { 'Content-Type': TUR.html }); return s.end(n ? fs.readFileSync(n) : 'yok'); }
    s.writeHead(200, { 'Content-Type': TUR[path.extname(bul).slice(1).toLowerCase()] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    fs.createReadStream(bul).pipe(s);
  }).listen(port, '127.0.0.1', () => console.log('sunuluyor: http://127.0.0.1:' + port + ' <- ' + kok));
  return;
}

/* ---------------------------------------------------------------- KIYAS */
if (a.includes('--kiyas')) {
  (async () => {
    const canli = JSON.parse(fs.readFileSync(arg('--canli'), 'utf8')), YENI = arg('--yeni').replace(/\/$/, '');
    const ic = arg('--ic') ? fs.readFileSync(arg('--ic'), 'utf8').split(/\r?\n/).map(s => s.trim()).filter(Boolean) : [];
    const ek = arg('--ek') ? fs.readFileSync(arg('--ek'), 'utf8').split(/\r?\n/).map(s => s.trim()).filter(Boolean) : [];
    // canlıda 200 dönen yollar: tarayıcının gördüğü istekler + bağlantılar (bağlantının canlı durumu ayrıca sorulur)
    const istenen = new Set([...Object.keys(canli.istekDurum).filter(y => canli.istekDurum[y] === 200), ...canli.tumYol, ...ek]);
    const sor = async (taban, y) => { for (let i = 0; i < 3; i++) { try { const r = await fetch(taban + encodeURI(y), { redirect: 'follow', cache: 'no-store' }); return r.status; } catch (e) { if (i === 2) return 'HATA'; } } };
    const havuz = async (liste, f, n = 16) => { const o = []; let i = 0; await Promise.all(Array.from({ length: n }, async () => { while (i < liste.length) { const k = i++; o[k] = await f(liste[k]); } })); return o; };
    const CTABAN = canli.taban.replace(/\/$/, '');
    const yollar = [...istenen].filter(y => y.startsWith('/')).sort();
    // canlı durum: taramada görülmediyse canlıya sorulur
    const cd = await havuz(yollar, async y => (canli.istekDurum[y] !== undefined ? canli.istekDurum[y] : await sor(CTABAN, y)));
    const yd = await havuz(yollar, y => sor(YENI, y));
    // --bilerek: canlıda 200 olup hiçbir site sayfasının bağlanmadığı, BİLEREK yayından düşen yollar (gerekçe dosyada)
    const bilerek = new Set(arg('--bilerek') ? fs.readFileSync(arg('--bilerek'), 'utf8').split(/\r?\n/).map(s => s.replace(/#.*/, '').trim()).filter(Boolean) : []);
    const kayip = [], iyi = [], canliDegil = [], dusen = [];
    yollar.forEach((y, k) => {
      if (bilerek.has(y)) { dusen.push(y + '  canlı ' + cd[k] + ' / yeni ' + yd[k]); if (yd[k] !== 404) kayip.push(y + '  BİLEREK düşmeliydi, yeni ' + yd[k]); return; }
      if (cd[k] === 200 || cd[k] === 304) (yd[k] === 200 ? iyi : kayip).push(y + '  canlı ' + cd[k] + ' / yeni ' + yd[k]); else canliDegil.push(y + '  canlı ' + cd[k]);
    });
    const icd = await havuz(ic, y => sor(YENI, y));
    const sizan = ic.filter((y, k) => icd[k] !== 404).map((y, k) => y + ' -> ' + icd[ic.indexOf(y)]);
    const icCanli = arg('--ic-canli') ? await havuz(ic, y => sor(CTABAN, y)) : null;
    const rapor = { olcum: new Date().toISOString(), canli: CTABAN, yeni: YENI, canli_tarama: canli.olcum, canli_sayfa: canli.sayfaSayisi,
      site_yolu: yollar.length, canlida_200: iyi.length + kayip.length, yenide_200: iyi.length, KAYIP: kayip, canlida_200_degil: canliDegil.length,
      bilerek_dusen: dusen,
      ic_dosya: ic.length, ic_yenide_404: ic.length - sizan.length, IC_SIZAN: sizan,
      ic_canlida_200: icCanli ? icCanli.filter(x => x === 200).length : 'ölçülmedi' };
    if (arg('--rapor')) fs.writeFileSync(arg('--rapor'), JSON.stringify(rapor, null, 1));
    console.log('SİTE YOLU ' + yollar.length + ' · canlıda 200: ' + rapor.canlida_200 + ' · yenide 200: ' + iyi.length + ' · KAYIP ' + kayip.length + ' · (canlıda zaten 200 olmayan ' + canliDegil.length + ')');
    kayip.slice(0, 50).forEach(k => console.log('  KAYIP ' + k));
    if (dusen.length) console.log('BİLEREK DÜŞEN ' + dusen.length + ' (hiçbir site sayfası bağlanmıyor): ' + dusen.map(d => d.split('  ')[0]).join(' '));
    console.log('İÇ DOSYA ' + ic.length + ' · yenide 404: ' + rapor.ic_yenide_404 + ' · SIZAN ' + sizan.length + (icCanli ? ' · canlıda bugün 200: ' + rapor.ic_canlida_200 : ''));
    sizan.slice(0, 50).forEach(k => console.log('  SIZAN ' + k));
    console.log('EŞDEĞERLİK: ' + (kayip.length || sizan.length ? 'KIRMIZI' : 'YEŞİL'));
    process.exit(kayip.length || sizan.length ? 1 : 0);
  })().catch(e => { console.error(e); process.exit(2); });
  return;
}

/* ----------------------------------------------------------------- TARA */
if (!a.includes('--tara')) { console.log('kullanım: --tara | --sun | --kiyas (başlıktaki açıklama)'); process.exit(2); }
const { tarayiciAc, bekle } = require(path.join(__dirname, 'tarayici.js'));
const TABAN = arg('--taban').replace(/\/$/, ''), DER = +arg('--derinlik', 3), PAR = +arg('--paralel', 4), CIKTI = arg('--cikti');
const KAPI = arg('--kapi', 'tetikte2026');
const KOKEN = new URL(TABAN).origin;
const tohum = fs.readFileSync(arg('--tohum'), 'utf8').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
const norm = u => { try { const x = new URL(u, TABAN + '/'); if (x.origin !== KOKEN) return null; return decodeURI(x.pathname); } catch (e) { return null; } };
const sayfalar = {}, istekDurum = {}, kuyruk = [], gorulen = new Set();
function koy(y, d) { if (y == null || gorulen.has(y) || d > DER) return; if (!/(\.html?|\/)$/.test(y) && /\.[a-z0-9]+$/i.test(y)) return; gorulen.add(y); kuyruk.push([y, d]); }
tohum.forEach(t => koy(norm(t), 0));
(async () => {
  const t = await tarayiciAc(); if (t.hata) { console.error('TARAYICI', t); process.exit(2); }
  const olaylar = new Map();
  t.cdp.ws.addEventListener('message', e => { const m = JSON.parse(e.data); if (m.method && m.sessionId && olaylar.has(m.sessionId)) olaylar.get(m.sessionId)(m); });
  async function sekme() {
    const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
    const o = (await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true })).sessionId;
    await t.cdp.cagir('Page.enable', {}, o); await t.cdp.cagir('Network.enable', {}, o);
    await t.cdp.cagir('Network.setCacheDisabled', { cacheDisabled: true }, o);
    return { o };
  }
  async function ac(s, y) {
    const kayit = {}, ist = new Map();
    olaylar.set(s.o, m => {
      if (m.method === 'Network.requestWillBeSent') ist.set(m.params.requestId, m.params.request.url);
      if (m.method === 'Network.responseReceived') { const p = norm(m.params.response.url); if (p != null) kayit[p] = m.params.response.status; }
      if (m.method === 'Network.loadingFailed') { const p = norm(ist.get(m.params.requestId) || ''); if (p != null && !(p in kayit)) kayit[p] = 'HATA:' + m.params.errorText; }
    });
    let bag = [];
    try {
      await t.cdp.cagir('Page.navigate', { url: TABAN + encodeURI(y) }, s.o); await bekle(4500);
      await t.cdp.cagir('Runtime.evaluate', { expression: 'window.scrollTo(0,document.body?document.body.scrollHeight:0)' }, s.o); await bekle(1200);
      const r = await t.cdp.cagir('Runtime.evaluate', { returnByValue: true, expression:
        `(function(){var o=[];document.querySelectorAll('a[href],iframe[src],link[href],[src],meta[content]').forEach(function(e){var v=e.getAttribute('href')||e.getAttribute('src')||e.getAttribute('content');if(v&&(e.tagName!=='META'||/^(https?:|\\/)/.test(v)))o.push(new URL(v,location.href).href)});document.querySelectorAll('iframe').forEach(function(f){try{f.contentDocument.querySelectorAll('a[href]').forEach(function(e){o.push(e.href)})}catch(x){}});return o})()` }, s.o);
      bag = r.result.value || [];
    } catch (e) { kayit['__HATA__'] = String(e.message); }
    olaylar.delete(s.o);
    return { kayit, bag };
  }
  const sekmeler = []; for (let i = 0; i < PAR; i++) sekmeler.push(await sekme());
  await t.cdp.cagir('Page.navigate', { url: TABAN + '/index.html?kapi=' + KAPI }, sekmeler[0].o); await bekle(3000);
  async function isci(s) {
    while (kuyruk.length) {
      const [y, d] = kuyruk.shift();
      for (const tel of [false, true]) {
        await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: tel ? 390 : 1280, height: 844, deviceScaleFactor: 1, mobile: tel }, s.o);
        const { kayit, bag } = await ac(s, y);
        const k = sayfalar[y] || (sayfalar[y] = { derinlik: d, istekler: {}, baglantilar: [] });
        Object.assign(k.istekler, kayit); Object.assign(istekDurum, kayit);
        for (const b of bag) { const p = norm(b); if (p != null) { if (!k.baglantilar.includes(p)) k.baglantilar.push(p); koy(p, d + 1); } }
      }
      if (Object.keys(sayfalar).length % 20 === 0) process.stderr.write('sayfa ' + Object.keys(sayfalar).length + ' kuyruk ' + kuyruk.length + '\n');
    }
  }
  await Promise.all(sekmeler.map(isci));
  const tumYol = new Set(Object.keys(istekDurum).filter(y => y !== '__HATA__'));
  for (const k of Object.values(sayfalar)) k.baglantilar.forEach(b => tumYol.add(b));
  fs.writeFileSync(CIKTI, JSON.stringify({ taban: TABAN, olcum: new Date().toISOString(), sayfaSayisi: Object.keys(sayfalar).length, istekDurum, tumYol: [...tumYol].sort(), sayfalar }, null, 1));
  console.log('sayfa ' + Object.keys(sayfalar).length + ' · yol ' + tumYol.size);
  t.kapat(); process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
