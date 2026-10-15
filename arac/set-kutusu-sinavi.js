// arac/set-kutusu-sinavi.js — 15.10.2026 (Cem "1.2.3"): set kutusu zayıf konu satırı + "Bu konuyu çalış" + konu çalışması + GoatCounter olayları.
// Çalıştır: node arac/set-kutusu-sinavi.js [depo kökü] [ekran görüntüsü klasörü]   (Playwright; ağ dışarı çıkmaz, kasa taklit)
// 🚫 GÖRMEZ: gerçek kasa (Supabase) cevabı · gerçek GoatCounter sayımı · kasa dışı/eski (parçalı) yükleme yolu.
const path = require('path'), fs = require('fs'), http = require('http');
const { chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright');
const kok = process.argv[2] || path.join(__dirname, '..'), cikti = process.argv[3] || require('os').tmpdir();
// vitrin sayfalarındaki şıklı sorular kalıp; deneme için çoğaltılır (kimlik + konu etiketi deneme verisi, yalnız bellekte)
const K = [];
for (const f of ['sgs', 'smmm', 'ornek-sgs', 'ornek-smmm']) {
  const satir = fs.readFileSync(path.join(kok, 'kaydir/vitrin/' + f + '.html'), 'utf8').split('\n').find(l => l.startsWith('const SORULAR='));
  JSON.parse(satir.slice('const SORULAR='.length).replace(/;\s*$/, '')).filter(s => s.siklar && s.dogru && !(s.oyun && s.oyun.tur)).forEach(s => K.push(s));
}
const X = 'İşletme Sermayesi Deneme Konusu';
const kopya = (s, n, konu) => Object.assign(JSON.parse(JSON.stringify(s)), { id: 'deneme-' + n + '/' + s.id, konu });
const x = [], digerleri = [];
for (let n = 0; n < 7; n++) x.push(kopya(K[n % K.length], 'x' + n, X));
for (let n = 0; n < 50; n++) digerleri.push(kopya(K[n % K.length], 'd' + n, 'Diğer konu ' + (n % 9)));
// sıra: ilk 20'nin 3'ü X (0, 5, 9), kalan X'ler 20'den sonra
const sira = []; let xi = 0, di = 0;
for (let i = 0; i < 20; i++) sira.push([0, 5, 9].includes(i) ? x[xi++] : digerleri[di++]);
while (di < digerleri.length && sira.length < 60) sira.push(digerleri[di++]);
while (xi < x.length) sira.push(x[xi++]);
const fih = sira.map((s, i) => ({ id: s.id, sira: i + 1, ders: s.ders, konu: s.konu, donem: String(s.donem || ''), zorluk: s.zorluk || null, toplam: sira.length }));
const veri = {}; sira.forEach(s => { veri[s.id] = s; });
console.log('konu X =', X, '| X soru', x.length, '| toplam', sira.length);

const STUB = `(function(){ var F=${JSON.stringify(fih)}, V=${JSON.stringify(veri)};
 window.__pkKapi=Promise.resolve({acik:true,tur:'uye',sb:{rpc:function(ad,p){
  if(ad==='kasa_ders_fihrist') return Promise.resolve({data:F,error:null});
  if(ad==='kasa_soru_parca') return Promise.resolve({data:p.p_ids.map(function(id){return {id:id,veri:V[id]};}),error:null});
  return Promise.resolve({data:null,error:null}); }, from:function(){ return {select:function(){return this;},eq:function(){return this;},then:function(r){r({data:[],error:null});}}; } }}); })();`;
const GC = 'window.goatcounter={count:function(o){console.log("GC "+o.path+" event="+o.event);}};';

const sunucu = http.createServer((q, r) => {
  const u = decodeURIComponent(q.url.split('?')[0]); const d = path.join(kok, u);
  if (!d.startsWith(kok) || !fs.existsSync(d) || fs.statSync(d).isDirectory()) { r.writeHead(404); return r.end(); }
  const t = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json' }[path.extname(d)] || 'application/octet-stream';
  r.writeHead(200, { 'content-type': t + '; charset=utf-8' }); fs.createReadStream(d).pipe(r);
}).listen(0);
const port = sunucu.address().port, ADRES = 'http://127.0.0.1:' + port + '/kaydir/sgs/turkce.html';

(async () => {
  const tar = await chromium.launch(); let hata = 0;
  const kontrol = (ad, kosul, ek) => { console.log((kosul ? 'GEÇTİ ' : 'KALDI ') + ad + (ek ? ' :: ' + ek : '')); if (!kosul) hata++; };
  for (const [cihaz, vp] of [['telefon', { width: 390, height: 844 }], ['bilgisayar', { width: 1366, height: 860 }]]) {
    const ctx = await tar.newContext({ viewport: vp, isMobile: cihaz === 'telefon', hasTouch: cihaz === 'telefon' });
    const sayfa = await ctx.newPage(); const gc = [], konsolHata = [];
    sayfa.on('console', m => { const t = m.text(); if (t.startsWith('GC ')) gc.push(t.slice(3).split(' ')[0]); else if (m.type() === 'error') konsolHata.push(t); });
    sayfa.on('pageerror', e => konsolHata.push('pageerror ' + e.message));
    await sayfa.route('**/*', rt => {
      const u = rt.request().url();
      if (/\/paket-kapisi\.js/.test(u)) return rt.fulfill({ contentType: 'text/javascript', body: STUB });
      if (u.includes('gc.zgo.at/count.js')) return rt.fulfill({ contentType: 'text/javascript', body: GC });
      if (!u.startsWith('http://127.0.0.1:' + port)) return rt.fulfill({ status: 204, body: '' });
      return rt.continue();
    });
    await sayfa.addInitScript(() => { try { if (!sessionStorage.getItem('dnm')) { sessionStorage.setItem('dnm', '1'); localStorage.setItem('kc_kayit', '[]'); localStorage.setItem('kc_kutu', '[]'); } } catch (e) {} });
    await sayfa.goto(ADRES); await sayfa.waitForSelector('#akis > .kart', { timeout: 15000 });
    // ilk 20 soru: X konusu yanlış, ötekiler doğru
    for (let i = 0; i < 20; i++) {
      await sayfa.evaluate(i => { const k = document.querySelectorAll('#akis > .kart')[i]; k.scrollIntoView(); }, i);
      const s = sira[i], yanlis = s.konu === X || i === 13; const h = yanlis ? Object.keys(s.siklar).sort().find(h => h !== s.dogru) : s.dogru;
      await sayfa.evaluate(([i, h]) => { const k = document.querySelectorAll('#akis > .kart')[i]; k.querySelector('.sik[data-h="' + h + '"]').click(); }, [i, h]);
    }
    await sayfa.evaluate(() => { const a = document.getElementById('akis'); a.scrollTop = a.clientHeight * 20; a.dispatchEvent(new Event('scroll')); });
    await sayfa.waitForSelector('.setOzet', { timeout: 5000 }).catch(() => {});
    const kutu = await sayfa.evaluate(() => { const d = document.querySelector('.setOzet'); return d ? { metin: d.innerText, konuB: !!d.querySelector('.setKonuB'), konuSatir: (d.querySelector('.setKonu') || {}).innerText || '' } : null; });
    kontrol(cihaz + ': set kutusu açıldı', !!kutu);
    kontrol(cihaz + ': zayıf konu satırı X', kutu && kutu.konuSatir.includes(X) && /3 yanlış/.test(kutu.konuSatir), kutu && kutu.konuSatir);
    kontrol(cihaz + ': "Bu konuyu çalış" düğmesi', kutu && kutu.konuB);
    await sayfa.screenshot({ path: path.join(cikti, 'set-kutusu-' + cihaz + '.png') });
    await sayfa.waitForTimeout(300);
    await Promise.all([sayfa.waitForNavigation(), sayfa.click('.setKonuB')]);
    kontrol(cihaz + ': olay goster + konu sayıldı', gc.some(p => p === 'set-kutusu/sgs/turkce/goster') && gc.some(p => p === 'set-kutusu/sgs/turkce/konu'), gc.join(' | '));
    await sayfa.waitForSelector('#akis > .kart', { timeout: 15000 }); await sayfa.waitForTimeout(800);
    const km = await sayfa.evaluate(() => ({ url: location.search, konu: window.__KASA_KONU, kartlar: [...document.querySelectorAll('#akis > .kart')].filter(k => +k.dataset.i >= 0).map(k => k.querySelector('.ust span').textContent), serit: (document.querySelector('.konuSerit') || {}).innerText || '', sayac: (document.querySelector('.setSay') || {}).textContent, sira: window.__KASA_SORULAR.map(s => s.id) }));
    kontrol(cihaz + ': konu adresi', km.url.startsWith('?konu='), km.url);
    kontrol(cihaz + ': bütün kartlar X', km.kartlar.length === x.length && km.kartlar.every(k => k === X), km.kartlar.length + ' kart');
    const cozulmus = sira.slice(0, 20).filter(s => s.konu === X).map(s => s.id);
    kontrol(cihaz + ': çözülmemişler önde, çözülenler sonda', km.sira.slice(-cozulmus.length).every(id => cozulmus.includes(id)) && !km.sira.slice(0, x.length - cozulmus.length).some(id => cozulmus.includes(id)));
    kontrol(cihaz + ': konu şeridi', km.serit.includes(X) && km.serit.includes('Tüm ders'), km.serit);
    kontrol(cihaz + ': sayaç konu sayısına göre', km.sayac === '1/' + Math.min(20, x.length) || km.sayac === 'Set 1 · 1/' + Math.min(20, x.length), km.sayac);
    kontrol(cihaz + ': olay konu-calis/ac', gc.some(p => p === 'konu-calis/sgs/turkce/ac'), gc.join(' | '));
    await sayfa.screenshot({ path: path.join(cikti, 'konu-calisma-' + cihaz + '.png') });
    // yanlış ad: bütün ders açılır, şerit yok
    await sayfa.goto(ADRES + '?konu=olmayan%20konu'); await sayfa.waitForSelector('#akis > .kart', { timeout: 15000 }); await sayfa.waitForTimeout(600);
    const yk = await sayfa.evaluate(() => ({ n: window.__KASA_SORULAR.length, serit: !!document.querySelector('.konuSerit'), konu: window.__KASA_KONU }));
    kontrol(cihaz + ': tutmayan konu → bütün ders, şerit yok', yk.n === Math.min(40, sira.length) && !yk.serit && !yk.konu, JSON.stringify(yk));
    kontrol(cihaz + ': konsol hatası yok', konsolHata.length === 0, konsolHata.slice(0, 3).join(' | '));
    await ctx.close();
  }
  await tar.close(); sunucu.close();
  console.log(hata ? 'SONUÇ: KIRMIZI (' + hata + ')' : 'SONUÇ: YEŞİL'); process.exit(hata ? 1 : 0);
})().catch(e => { console.log('ÇÖKTÜ', e.message); process.exit(2); });
