// Gerçek KGK kök uzunluğu modül modül (konu-profil-gercek.json, 2018+): medyan · p75 · p90 · p95. 0 USD.
const fs = require('fs'), path = require('path');
const P = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'konu-profil-gercek.json'), 'utf8')).konu;
const M = {}; for (const p of Object.values(P)) (M[p.modul] = M[p.modul] || []).push(...p.sorular.map(x => x.uz));
const q = (a, r) => { const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(r * s.length))]; };
const t = {}; for (const [m, a] of Object.entries(M)) t[m] = { n: a.length, medyan: q(a, .5), p75: q(a, .75), p90: q(a, .9), p95: q(a, .95) };
console.table(t);
