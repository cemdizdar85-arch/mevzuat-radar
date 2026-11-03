// Bağ denetimi: kitapçık metni ↔ etiket konusu doğru eşleşiyor mu? Konunun modülü (kgk-konu-es d) ile soru metninin
// anahtar kelime modülü karşılaştırılır; dönem başına uyuşmazlık oranı. Yüksek oranlı dönem konu tablosundan çıkar. 0 USD.
const fs = require('fs'), path = require('path');
const D = __dirname, oku = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c');
const kk = s => katla(s).replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const es = JSON.parse(fs.readFileSync(path.join(D, '..', 'kgk-konu-es.json'), 'utf8').replace(/^﻿/, '')).esleme;
// yalnız kesin işaretler (yanlış alarmı az): kanun no / standart adı
// YALNIZ kesin kimlik: kanun numarası ya da standart numarası (anahtar kelime değil — "denetçi" KY komite sorusunda da geçer)
const ISARET = [['ç', /\b6362 sayili/], ['d', /\b5411 sayili/], ['e', /\b(5684|4632) sayili/],
  ['a', /\b(tms|tfrs) ?\d{1,2}\b/], ['b', /\bbds ?\d{3}\b/], ['f', /\btsrs ?[12]\b/], ['g', /\bgds ?\d{4}\b/]];
const MH = d => (String(d || '').match(/^([a-gç])\)/) || [])[1];
const g = []; for (const f of (process.argv[2] ? [process.argv[2]] : ['ayirici-girdi.json', 'ayirici-girdi-hepsi.json'])) g.push(...oku(f));
const R = {};
for (const q of g) {
  const e = es[kk(q.konu)]; const km = e ? MH(e.d) : null; const t = katla(q.kok); let tm = null; for (const [m, re] of ISARET) if (re.test(t)) { tm = m; break; }
  const dn = q.kimlik.split('|')[0]; const r = R[dn] = R[dn] || { n: 0, olc: 0, uyusmaz: 0 };
  r.n++; if (!km || !tm) continue; if (km === 'c' || tm === 'c') continue; r.olc++; if (km !== tm) r.uyusmaz++;
}
const out = Object.fromEntries(Object.entries(R).map(([d, r]) => [d, { n: r.n, olculen: r.olc, uyusmaz: r.uyusmaz, oran: r.olc ? '%' + Math.round(100 * r.uyusmaz / r.olc) : '-' }]));
console.table(out); fs.writeFileSync(path.join(D, 'bag-denetim.json'), JSON.stringify(out, null, 1));
