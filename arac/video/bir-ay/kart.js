#!/usr/bin/env node
/* Bir ay kaldı · akış görseli 4:5 (1080×1350). Metin pazarlama/reklam/meta-bir-ay-kaldi.md "Görsel 4:5 · <sınav>" bölümünden okunur
   (kapıdan geçen metin = karttaki metin); bölüm eksikse ya da kart taşıyorsa basmaz (exit 3).
   Kullanım: node arac/video/bir-ay/kart.js [--cikti <klasör>]  → bir-ay-sgs.png, bir-ay-yet.png */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const i = process.argv.indexOf('--cikti');
const CIKTI = i > -1 ? process.argv[i + 1] : path.join(KOK, 'gorsel', 'reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'meta-bir-ay-kaldi.md'), 'utf8');

function veri(ad) {
  const m = new RegExp(`## Görsel 4:5 · ${ad}\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md);
  if (!m) { console.error(`METİN KAPISI: "Görsel 4:5 · ${ad}" yok`); process.exit(3); }
  const al = k => { const x = new RegExp(`^${k}: (.+)$`, 'm').exec(m[1]); if (!x) { console.error(`METİN KAPISI: ${ad} "${k}" yok`); process.exit(3); } return x[1].trim(); };
  return { ust: al('Üst'), baslik: al('Başlık'), alt: al('Alt başlık'), dugme: al('Düğme'), dip: al('Alt satır'),
           maddeler: [...m[1].matchAll(/^- (.+)$/gm)].map(x => x[1].trim()) };
}
(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const t = await chromium.launch();
  try {
    for (const [kod, ad] of [['sgs', 'Staja Giriş'], ['yet', 'Yeterlilik']]) {
      const p = await t.newPage({ viewport: { width: 1080, height: 1350 } });
      await p.goto('file:///' + path.join(__dirname, 'kart.html').replace(/\\/g, '/'));
      const sigdi = await p.evaluate(v => window.kur(v), veri(ad));
      if (!sigdi) { console.error(`KART TAŞIYOR: ${kod}`); process.exit(3); }
      const dosya = path.join(CIKTI, `bir-ay-${kod}.png`);
      await p.screenshot({ path: dosya }); await p.close(); console.log(`kart: ${dosya}`);
    }
  } finally { await t.close(); }
})().catch(e => { console.error(e); process.exit(1); });
