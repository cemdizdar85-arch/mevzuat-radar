#!/usr/bin/env node
// tema-bas.js'teki ERKEN açık tema katmanı (siyah parlama önlemi, 05.10.2026) ile stil-acik.css :root değerleri aynı mı?
// Kayma olursa sayfa açılışında ilk kareler eski renkle görünür (yüklenince stil-acik.css doğrusunu verir).
// Kullanım: node arac/tema-erken-esitlik.js  → fark varsa çıkış 1.   GÖRMEZ: :root dışındaki açık tema kuralları.
'use strict';
const fs = require('fs'), path = require('path'), K = path.join(__dirname, '..');
const s = fs.readFileSync(path.join(K, 'stil-acik.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
const re = /(^|\n)\s*:root\s*\{([^}]*)\}/g; let m; const v = {};
while ((m = re.exec(s))) for (const d of m[2].split(';')) { const x = d.match(/^\s*(--[\w-]+)\s*:\s*(.+?)\s*$/); if (x) v[x[1]] = x[2]; }
const t = fs.readFileSync(path.join(K, 'tema-bas.js'), 'utf8');
const blok = (t.match(/TEMA-ERKEN-BASLA[\s\S]*?TEMA-ERKEN-BITIR/) || [''])[0];
const fark = Object.entries(v).filter(([k, x]) => !blok.includes(k + ':' + x));
if (fark.length) { console.error('KIRMIZI: tema-bas.js erken katmanı stil-acik.css ile ayrışmış: ' + fark.map(([k]) => k).join(', ')); process.exit(1); }
console.log('tema erken katmanı eşit: ' + Object.keys(v).length + ' değer');
