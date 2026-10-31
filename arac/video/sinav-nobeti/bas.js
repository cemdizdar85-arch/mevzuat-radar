#!/usr/bin/env node
/* Sınav Nöbeti kural karuseli (1080×1350). 21.10.2026.
   METİN KAPISI: her karenin satırları pazarlama/reklam/<md>.md "## Kare k" bölümünden OKUNUR (reklam metni kapısından geçen
   metin = karedeki metin); kare taşarsa basmaz (exit 3).
   Kullanım: node arac/video/sinav-nobeti/bas.js --md instagram-sinav-nobeti-sgs-kilavuz [--cikti <klasör>]
   🚫 GÖRMEZ: kuralın resmî metne uygunluğu (md iç notunda sayfa sayfa elle) · telefonda okunaklılık (gözle). */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const AD = arg('--md') || 'instagram-sinav-nobeti-sgs-kilavuz';
const CIKTI = arg('--cikti') || path.join(KOK, 'gorsel', 'reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', AD + '.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const kareler = [...md.matchAll(/## Kare (\d+)[^\n]*\r?\n([\s\S]*?)(?=\r?\n## )/g)]
  .map(m => m[2].split(/\r?\n/).map(s => s.trim()).filter(Boolean));
if (kareler.length < 2) { console.error('METİN KAPISI: kare bulunamadı'); process.exit(3); }
(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const t = await chromium.launch();
  try {
    for (let k = 1; k <= kareler.length; k++) {
      const p = await t.newPage({ viewport: { width: 1080, height: 1350 } });
      await p.goto('file:///' + path.join(__dirname, 'kural.html').replace(/\\/g, '/'));
      const sigdi = await p.evaluate(([k, n, S, u]) => window.kur(k, n, S, u), [k, kareler.length, kareler[k - 1], 'SINAV NÖBETİ']);
      if (!sigdi) { console.error(`KARE TAŞIYOR: ${k}`); process.exit(3); }
      const dosya = path.join(CIKTI, `${AD}-k${k}.png`);
      await p.screenshot({ path: dosya }); await p.close(); console.log(`kare: ${dosya}`);
    }
  } finally { await t.close(); }
})().catch(e => { console.error(e); process.exit(1); });
