// kart-bas.js <html> <cikti-klasoru> [genislik] [yukseklik]
// Sayfadaki her .kart elementini ayri PNG olarak basar (Instagram carousel).
// Playwright bu makinede C:\Users\cemdi\.claude\araclar\kayit\node_modules altinda kurulu (depoda node_modules yok).
let chromium;
try { ({ chromium } = require('playwright')); }
catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const path = require('path');
const fs = require('fs');

(async () => {
  const [html, cikti, gStr, yStr, saydamStr] = process.argv.slice(2);
  const saydam = saydamStr === 'saydam';   // video katmani icin arka plansiz PNG
  if (!html || !cikti) { console.error('kullanim: node kart-bas.js <html> <cikti-klasoru> [g] [y]'); process.exit(1); }
  const G = parseInt(gStr || '1080', 10);
  const Y = parseInt(yStr || '1350', 10);
  fs.mkdirSync(cikti, { recursive: true });

  const tarayici = await chromium.launch();
  const sayfa = await tarayici.newPage({ viewport: { width: G, height: Y }, deviceScaleFactor: 1 });
  await sayfa.goto('file:///' + path.resolve(html).replace(/\\/g, '/'), { waitUntil: 'networkidle' });
  await sayfa.waitForTimeout(1200); // font yuklensin

  const kartlar = await sayfa.$$('.kart');
  console.log('kart sayisi: ' + kartlar.length);
  let n = 0;
  for (const kart of kartlar) {
    n++;
    const ad = (await kart.getAttribute('id')) || ('kart' + String(n).padStart(2, '0'));
    const yol = path.join(cikti, ad + '.png');
    await kart.screenshot({ path: yol, omitBackground: saydam });
    const kb = Math.round(fs.statSync(yol).size / 1024);
    console.log('  ' + ad + '.png  ' + kb + ' KB');
  }
  await tarayici.close();
  console.log('bitti -> ' + cikti);
})();
