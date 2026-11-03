// Gizli iz eşik kalibrasyonu: gerçek KGK (konu-profil-gercek.json) rastgele 21'lik gruplar ↔ fabrikadaki hazır gruplarımız. 0 USD.
const fs = require('fs'), path = require('path');
const { olc } = require('../konu-profil.js');
const P = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'konu-profil-gercek.json'), 'utf8')).konu;
const L = Object.values(P).flatMap(p => p.sorular);
const med = a => { const s = [...a].sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; };
const q = (a, r) => { const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(r * s.length))]; };
let rnd = 3; const R = () => (rnd = (rnd * 16807) % 2147483647) / 2147483647;
const gy = [], gs = [];
for (let i = 0; i < 2000; i++) { const G = Array.from({ length: 21 }, () => L[Math.floor(R() * L.length)]); gy.push(G.filter(x => x.yil).length); gs.push(med(G.map(x => x.sor))); }
console.log(`GERÇEK tek tek: yıl %${Math.round(100 * L.filter(x => x.yil).length / L.length)} · tek harf ${L.filter(x => x.tek).length}/${L.length} · şık oranı medyan ${med(L.map(x => x.sor))}`);
console.log(`GERÇEK 21'lik grup: yıllı kök p50 ${q(gy, .5)} · p95 ${q(gy, .95)} · p99 ${q(gy, .99)} | şık oranı medyanı p1 ${q(gs, .01)} · p5 ${q(gs, .05)} · p50 ${q(gs, .5)}`);
const FAB = 'C:/TETIKTE-CALISMA/kgk-cizim/veri/fabrika', B = {};
for (const f of fs.readdirSync(FAB).filter(x => /^hazir-kgk-t\d-.+-(kolay|zor|cokzor)\.json$/.test(x))) {
  const g = f.replace(/^hazir-kgk-|-(kolay|zor|cokzor)\.json$/g, ''); let A; try { A = JSON.parse(fs.readFileSync(path.join(FAB, f), 'utf8').replace(/^\uFEFF/, '')); } catch (e) { continue; }
  (B[g] = B[g] || []).push(...A.map(x => olc(String(x.soru || ''), Object.values(x.siklar || {}))));
}
const sat = {}; for (const [g, A] of Object.entries(B)) { const d = g.split('-')[0]; const s = sat[d] = sat[d] || { grup: 0, yilGrup: [], sor: [], tek: 0, n: 0 }; s.grup++; s.n += A.length; s.tek += A.filter(x => x.tek).length; s.yilGrup.push(Math.round(21 * A.filter(x => x.yil).length / A.length)); s.sor.push(med(A.map(x => x.sor))); }
for (const [d, s] of Object.entries(sat)) console.log(`BİZ ${d}: ${s.grup} grup · tek harf ${s.tek}/${s.n} · 21'e ölçekli yıllı kök medyan ${med(s.yilGrup)} · şık oranı medyanı ${med(s.sor)}`);
