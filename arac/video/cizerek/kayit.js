#!/usr/bin/env node
/* ============================================================================
   NÖBETÇİ ÇİZEREK ÇÖZÜYOR — sitenin GERÇEK ekran kaydı (21.10.2026, Cem "biz çizimle anlatıyoruz, Nöbetçi anlatsın,
   nasıl yaptığımızı gösterelim"). Canlı tetikte.com örnek soru sayfası telefon boyutunda açılır, yanlış şık seçilir,
   "Nöbetçi çizerek çözsün" açılır ve kalem adım adım ilerletilir. Adım geçişleri seslendirme sürelerine göre yapılır
   (zamanlama.json) → ses ile görüntü eş; videoya hız oynaması yapılmaz.
   Kullanım:
     node arac/video/cizerek/kayit.js --oku                 → adım adım alt yazıları listeler (kayıt yok)
     node arac/video/cizerek/kayit.js --zaman <json>        → kayıt (webm) + olaylar.json
   Siteye yazan tek şey sayaç ziyaretidir (?k=kontrol, iç etiket).
   🚫 GÖRMEZ: sitedeki çizimin doğruluğu (cizerek-coz.js'in kendi kapıları) · ağ yavaşlığı (bekleme süreleri sabit).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const URL = 'https://tetikte.com/kaydir/vitrin/ornek-smmm.html?k=kontrol';
const CIKTI = arg('--cikti') || 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi/nobetci-cizerek';
const OKU = process.argv.includes('--oku');
const bekle = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const tarayici = await chromium.launch();
  /* recordVideo cihaz piksel oranını yok sayıyor (DPR 2'de görüntü sol üst çeyrekte kaldı) ve CSS zoom kalemin işaret yerlerini
     kaydırıyor (zoom 1,5'te E'nin yuvarlağı karalamaya, A'nın çizgisi B'ye düştü; 21.10 ölçüldü) → telefonun kendi boyutu, DPR 1;
     büyütme kurguda (bas.js, lanczos) */
  const ctx = await tarayici.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true,
    locale: 'tr-TR', ...(OKU ? {} : { recordVideo: { dir: CIKTI, size: { width: 390, height: 844 } } }) });
  const t0 = Date.now(); const olay = [];
  const not = ad => { olay.push({ ad, ms: Date.now() - t0 }); };
  const sayfa = await ctx.newPage();
  await sayfa.goto(URL, { waitUntil: 'networkidle' });
  await bekle(1200); not('sayfa');
  const z = OKU ? null : JSON.parse(fs.readFileSync(arg('--zaman'), 'utf8'));
  /* 1) soru ekranı: izleyici soruyu görsün */
  await bekle(OKU ? 300 : z.soruBekle);
  /* 2) A şıkkı (sitede en çok seçilen yanlış) */
  await sayfa.locator('.sik, [data-h="A"], button').filter({ hasText: /^A\)/ }).first().click().catch(async () => {
    await sayfa.getByText('40.000 ₺ yüksek gösterilmiştir', { exact: false }).first().click(); });
  not('secim-A');
  await bekle(OKU ? 800 : z.sonucBekle);
  /* 3) "Nöbetçi çizerek çözsün" */
  const dug = sayfa.getByText('Nöbetçi çizerek çözsün', { exact: false }).first();
  await dug.scrollIntoViewIfNeeded(); await bekle(OKU ? 200 : 900); await dug.click(); not('cizim-acildi');
  await bekle(OKU ? 600 : z.cizimAcBekle);
  const kaydirici = async () => sayfa.evaluate(() => {   /* çizim penceresinin kaydırma kutusu */
    const el = [...document.querySelectorAll('*')].find(x => x.scrollHeight > x.clientHeight + 40 && /Karalama|KARALAMA/i.test(x.innerText || '') && getComputedStyle(x).overflowY !== 'visible');
    if (el) el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' }); return !!el; });
  const N = await sayfa.locator('.czSay').innerText().then(s => +((s.match(/\/\s*(\d+)/) || [])[1] || 0));
  if (OKU) { console.log('N=' + N + ' czSay=' + (await sayfa.locator('.czSay').innerText().catch(() => 'yok'))); await sayfa.screenshot({ path: path.join(CIKTI, 'oku.png') }); }
  const altlar = [];
  const ADIM = OKU ? N : Math.min(N, z.adimSayisi || N);
  for (let i = 0; i < ADIM; i++) {
    await sayfa.locator('.czIleri').click();
    if (OKU) await bekle(2500);
    const alt = (await sayfa.locator('.czAlt').innerText()).replace(/\s+/g, ' ').trim();
    altlar.push(alt); not('adim-' + (i + 1));
    if (!OKU && i === 0) { /* altı çizme bitince karalamayı göster */ }
    if (OKU) { await bekle(300); continue; }
    const dur = (z.adimMs[i] != null ? z.adimMs[i] : z.varsayilanAdimMs);
    if (i === z.kaydirAdim) { await bekle(Math.min(1500, dur / 3)); await kaydirici(); await bekle(dur - Math.min(1500, dur / 3)); }
    else await bekle(dur);
  }
  await bekle(OKU ? 0 : z.sonBekle); not('son');
  if (OKU) { altlar.forEach((a, i) => console.log(`${i + 1}/${N}: ${a}`)); }
  const video = OKU ? null : sayfa.video();
  await ctx.close(); await tarayici.close();
  if (video) {
    const yol = await video.path(); const hedef = path.join(CIKTI, 'kayit.webm');
    fs.renameSync(yol, hedef);
    fs.writeFileSync(path.join(CIKTI, 'olaylar.json'), JSON.stringify({ olay, altlar }, null, 1));
    console.log('kayıt: ' + hedef); console.log(olay.map(o => o.ad + '@' + (o.ms / 1000).toFixed(2)).join(' '));
  }
})().catch(e => { console.error(e); process.exit(1); });
