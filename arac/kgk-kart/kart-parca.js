// Kartları okuyucu parçalarına böler / doldurulmuş parçaları kartlara geri birleştirir. Bedel 0.
// node kart-parca.js bol <KOD> <parçaBoyu> [--son10 2]   → parca/<KOD>-<n>.json (son10 eşiği altındaki kartlar bölünmez)
// node kart-parca.js birlestir                          → parca/*.json içindeki dolu 4 alanı kartlar/<KOD>.json'a yazar (yalnız o 4 alan; ölçülen alan değişmişse UYARI)
'use strict';
const fs = require('fs'), path = require('path'); const D = __dirname, oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
const [kip, kod, boyS] = process.argv.slice(2); const i = process.argv.indexOf('--son10'), esik = i >= 0 ? +process.argv[i + 1] : 0;
const ALAN = ['ne_sorar', 'dayanak', 'celdirici', 'yazim_notu'];
fs.mkdirSync(path.join(D, 'parca'), { recursive: true });
if (kip === 'bol') {
  const A = oku(path.join(D, 'kartlar', `${kod}.json`)).filter(c => (c.son10 || 0) >= esik && !c.dayanak); const boy = +boyS;
  for (let p = 0; p * boy < A.length; p++) { const f = path.join(D, 'parca', `${kod}-${p + 1}.json`); if (fs.existsSync(f)) { console.log('VAR, atlandı: ' + f); continue; } fs.writeFileSync(f, JSON.stringify(A.slice(p * boy, (p + 1) * boy), null, 1) + '\n'); console.log(`${kod}-${p + 1}: ${A.slice(p * boy, (p + 1) * boy).length} kart`); }
} else if (kip === 'birlestir') {
  const K = {}; for (const f of fs.readdirSync(path.join(D, 'kartlar'))) K[f.replace('.json', '')] = oku(path.join(D, 'kartlar', f));
  let dolu = 0, bos = 0, uyari = 0;
  for (const f of fs.readdirSync(path.join(D, 'parca')).filter(f => f.endsWith('.json'))) {
    const kd = f.replace(/-\d+\.json$/, ''); const P = oku(path.join(D, 'parca', f));
    for (const c of P) { const h = (K[kd] || []).find(x => x.konu === c.konu); if (!h) { console.log(`UYARI ${f}: kart yok ${c.konu}`); uyari++; continue; }
      for (const k of Object.keys(h)) if (!ALAN.includes(k) && JSON.stringify(h[k]) !== JSON.stringify(c[k])) { console.log(`UYARI ${f}: ${c.konu} ölçülen alan değişmiş (${k}) — yok sayıldı`); uyari++; }
      if (ALAN.every(k => String(c[k] || '').trim())) { ALAN.forEach(k => h[k] = c[k]); dolu++; } else bos++; }
  }
  for (const [kd, a] of Object.entries(K)) fs.writeFileSync(path.join(D, 'kartlar', `${kd}.json`), JSON.stringify(a, null, 1) + '\n');
  console.log(`birleştirildi: dolu ${dolu} · eksik ${bos} · uyarı ${uyari}`);
} else console.log('kullanım: bol <KOD> <boy> [--son10 n] | birlestir');
