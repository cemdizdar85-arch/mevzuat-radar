// donusum.js öz-sınavı (29.09.2026): gerçek Chromium, gerçek sayfa (index.html perdesi), dış uçlar taklit, ağa çıkmaz.
// Koşu: node arac/donusum-sinavi.js   (Playwright: yerelde C:\Users\cemdi\.claude\araclar\kayit ya da npm i playwright)
// Mutasyon provası (29.09): 'karar yokken pikseli yükle' bozması -> 'reddet: Meta'ya istek YOK' KALDI (yakalandı).
const path = require('path'), fs = require('fs'), http = require('http');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = process.env.KOK || path.join(__dirname, '..');
const TIP = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css', '.svg': 'image/svg+xml', '.json': 'application/json' };
const sunucu = http.createServer((q, r) => {
  let p = decodeURIComponent(q.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
  const f = path.join(KOK, p);
  fs.readFile(f, (e, b) => { if (e) { r.writeHead(404); r.end(); return; } r.writeHead(200, { 'Content-Type': TIP[path.extname(f)] || 'application/octet-stream' }); r.end(b); });
}).listen(0);
const PORT = () => sunucu.address().port;

let hata = 0; const yaz = (ok, m) => { console.log((ok ? 'GEÇTİ ' : 'KALDI ') + m); if (!ok) hata++; };

async function senaryo(ad, pikselId, karar) {
  const tarayici = await chromium.launch();
  const bag = await tarayici.newContext();
  const kayit = { fb: [], capi: [], gc: [], form: 0 };
  await bag.route('**/*', async (rt) => {
    const u = rt.request().url();
    if (u.includes('gc.zgo.at/count.js')) return rt.fulfill({ contentType: 'text/javascript', body: 'window.goatcounter={count:function(o){window.__gc=(window.__gc||[]);window.__gc.push(o.path);}};' });
    if (u.includes('connect.facebook.net')) { kayit.fb.push(u); return rt.fulfill({ contentType: 'text/javascript', body: 'fbq.callMethod=function(){window.__fb=(window.__fb||[]);window.__fb.push(Array.prototype.slice.call(arguments));};fbq.queue.forEach(function(a){fbq.callMethod.apply(null,a)});' }); }
    if (u.includes('/functions/v1/meta-olay')) { kayit.capi.push(JSON.parse(rt.request().postData() || '{}')); return rt.fulfill({ status: 200, contentType: 'application/json', body: '{"success":true}' }); }
    if (u.includes('/functions/v1/quick-task')) { kayit.form++; return rt.fulfill({ status: 200, contentType: 'application/json', body: '{"success":true}' }); }
    if (u.endsWith('/donusum.js') && pikselId) {
      const b = fs.readFileSync(path.join(KOK, 'donusum.js'), 'utf8').replace("var PIKSEL_ID = '';", "var PIKSEL_ID = '" + pikselId + "';");
      return rt.fulfill({ contentType: 'text/javascript', body: b });
    }
    if (u.startsWith('http://127.0.0.1')) return rt.continue();
    return rt.fulfill({ status: 204, body: '' });   // öbür dış uçlar (supabase-js vb.) sessiz
  });
  const s = await bag.newPage();
  const konsol = []; s.on('pageerror', e => konsol.push(String(e)));
  await s.goto(`http://127.0.0.1:${PORT()}/index.html`, { waitUntil: 'load' });
  await s.waitForTimeout(1200);
  const bant = await s.$('#ttReklamBant');
  if (karar !== null && bant) { await s.click(`#ttReklamBant button[data-k="${karar}"]`); await s.waitForTimeout(500); }
  // perde formu → Lead
  await s.fill('#mrPerdeForm input[type=email]', 'Deneme@Ornek.com ');
  await s.check('#mrPerdeForm input[type=checkbox]');
  await s.click('#mrPerdeForm button');
  await s.waitForTimeout(1500);
  const gc = await s.evaluate(() => window.__gc || []);
  const fb = await s.evaluate(() => window.__fb || []);
  const cerezler = (await bag.cookies()).map(c => c.name);
  await tarayici.close();
  return { ad, bantVar: !!bant, kayit, gc, fb, cerezler, konsol };
}

(async () => {
  const bos = await senaryo('PIKSEL_ID boş', '', null);
  yaz(!bos.bantVar, 'boş: onay bandı ÇIKMIYOR');
  yaz(bos.kayit.fb.length === 0 && bos.kayit.capi.length === 0, 'boş: Meta\'ya istek YOK (fb ' + bos.kayit.fb.length + ', capi ' + bos.kayit.capi.length + ')');
  yaz(bos.kayit.form === 1, 'boş: perde formu yine gidiyor (' + bos.kayit.form + ')');
  yaz(bos.gc.includes('donusum/Lead/perde'), 'boş: GoatCounter Lead/perde yazıldı ' + JSON.stringify(bos.gc));
  yaz(bos.konsol.length === 0, 'boş: sayfa hatası yok ' + JSON.stringify(bos.konsol));

  const ret = await senaryo('Reddet', '123456789', '0');
  yaz(ret.bantVar, 'reddet: bant çıktı');
  yaz(ret.kayit.fb.length === 0 && ret.kayit.capi.length === 0, 'reddet: Meta\'ya istek YOK');
  yaz(ret.gc.includes('donusum/Lead/perde'), 'reddet: GoatCounter yine sayıyor');

  const kab = await senaryo('Kabul', '123456789', '1');
  yaz(kab.kayit.fb.length === 1, 'kabul: fbevents.js yüklendi');
  const adlar = kab.fb.map(a => a[0] + ':' + a[1]);
  yaz(adlar.includes('init:123456789') && adlar.includes('track:PageView') && adlar.includes('track:Lead'), 'kabul: fbq init+PageView+Lead ' + JSON.stringify(adlar));
  const lead = kab.kayit.capi.find(c => c.olay === 'Lead');
  const fbLead = kab.fb.find(a => a[1] === 'Lead');
  yaz(!!lead && fbLead && fbLead[3] && fbLead[3].eventID === lead.event_id, 'kabul: CAPI Lead aynı event_id ile');
  const beklenen = require('crypto').createHash('sha256').update('deneme@ornek.com').digest('hex');
  yaz(!!lead && lead.em === beklenen, 'kabul: e-posta yalnız SHA-256 özeti (küçük harf, kırpılmış)');
  yaz(!!lead && !JSON.stringify(lead).includes('@'), 'kabul: CAPI gövdesinde açık e-posta YOK');
  yaz(kab.konsol.length === 0, 'kabul: sayfa hatası yok ' + JSON.stringify(kab.konsol));

  sunucu.close();
  console.log(hata ? `SONUÇ: ${hata} KALDI` : 'SONUÇ: HEPSİ GEÇTİ');
  process.exit(hata ? 1 : 0);
})();
