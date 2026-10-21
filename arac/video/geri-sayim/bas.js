#!/usr/bin/env node
/* Geri Sayım · Tuzak N — Instagram karuseli (5 kare, 1080×1350). 21.10.2026.
   METİN KAPISI: karelerdeki her satır pazarlama/reklam/instagram-geri-sayim-tuzak-N.md'nin "## Kare k" bölümünden OKUNUR
   (reklam metni kapısından geçmiş metin = karedeki metin). Bölüm eksik ya da kare taşıyorsa basmaz (exit 3).
   Kullanım: node arac/video/geri-sayim/bas.js --tuzak 1 [--cikti <klasör>]  → geri-sayim-1-k1..k5.png
   🚫 GÖRMEZ: sorunun doğruluğu (md'deki iç not elle hesap) · yazının telefonda okunaklılığı (gözle bakılır). */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const N = arg('--tuzak') || '1';
const CIKTI = arg('--cikti') || path.join(KOK, 'gorsel', 'reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', `instagram-geri-sayim-tuzak-${N}.md`), 'utf8')
  .replace(/<!--[\s\S]*?-->\r?\n?/g, '');
function kare(k) {
  const m = new RegExp(`## Kare ${k}[^\\n]*\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md);
  if (!m) { console.error(`METİN KAPISI: "Kare ${k}" yok`); process.exit(3); }
  return m[1].split(/\r?\n/).map(s => s.trim()).filter(Boolean);
}
(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const rozet = kare(1)[0];
  const t = await chromium.launch();
  try {
    for (let k = 1; k <= 5; k++) {
      const p = await t.newPage({ viewport: { width: 1080, height: 1350 } });
      await p.goto('file:///' + path.join(__dirname, 'karusel.html').replace(/\\/g, '/'));
      const sigdi = await p.evaluate(([k, S, r]) => window.kur(k, S, r), [k, kare(k), rozet]);
      if (!sigdi) { console.error(`KARE TAŞIYOR: ${k}`); process.exit(3); }
      const dosya = path.join(CIKTI, `geri-sayim-${N}-k${k}.png`);
      await p.screenshot({ path: dosya }); await p.close(); console.log(`kare: ${dosya}`);
    }
  } finally { await t.close(); }
})().catch(e => { console.error(e); process.exit(1); });
