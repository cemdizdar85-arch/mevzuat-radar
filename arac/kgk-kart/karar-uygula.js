// Doğrulayıcı kararını hazır dosyaya uygular: KALSIN-DUZELT → yalnız açıklama katmanı alanları (soru/siklar/dogru/konu/zorluk ASLA);
// INDIR → soru dosyadan çıkar (kopya basim/cikarilan/). Bedel 0. Önce yedek alır.
// node karar-uygula.js <grup>
'use strict';
const fs = require('fs'), path = require('path'); const IS = path.join(__dirname, '..'), B = path.join(IS, 'basim');
const grup = process.argv[2], FAB = 'C:/TETIKTE-CALISMA/kgk-basim/veri/fabrika/';
const YASAK = new Set(['soru', 'siklar', 'dogru', 'konu', 'zorluk']);
const K = JSON.parse(fs.readFileSync(path.join(B, '_anahtar-gizli', `karar-${grup}.json`), 'utf8'));
const yedek = path.join(B, 'yedek-' + grup + '-' + Date.now()); fs.mkdirSync(yedek, { recursive: true }); fs.mkdirSync(path.join(B, 'cikarilan'), { recursive: true });
let duz = 0, cik = 0;
for (const z of ['kolay', 'zor', 'cokzor']) {
  const f = FAB + `hazir-kgk-t10-${grup}-${z}.json`; const A = JSON.parse(fs.readFileSync(f, 'utf8')); fs.copyFileSync(f, path.join(yedek, path.basename(f)));
  const kalan = [];
  A.forEach((q, i) => {
    const k = K.find(x => x.id === `${grup}-${z}[${i}]`) || {};
    if (k.karar === 'INDIR') { fs.writeFileSync(path.join(B, 'cikarilan', `${grup}-${z}-${i}.json`), JSON.stringify({ karar: k, soru: q }, null, 1)); cik++; return; }
    if (k.karar === 'KALSIN-DUZELT' && k.duzelt) for (const [al, v] of Object.entries(k.duzelt)) { if (YASAK.has(al)) { console.log(`ATLANDI ${z}[${i}] yasak alan ${al}`); continue; } q[al] = v; duz++; }
    kalan.push(q);
  });
  fs.writeFileSync(f, JSON.stringify(kalan, null, 2) + '\n');
}
console.log(`düzeltilen alan ${duz} · çıkarılan soru ${cik} · yedek ${yedek}`);
