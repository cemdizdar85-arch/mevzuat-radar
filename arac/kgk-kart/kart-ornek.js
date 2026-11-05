// Kart okuyucusu için: bir konunun ÇIKMIŞ KGK sorularını (kök + şık + cevap + elle kalıp) gösterir. Bedel 0, salt okuma.
// Amaç kartın "ne sorar / çeldirici" alanını gerçek sorudan doldurmak — METİN KOPYALANMAZ (A1/B29).
// node kart-ornek.js "<konu>" [en çok]
'use strict';
const fs = require('fs'), path = require('path'); const IS = path.join(__dirname, '..');
const oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
const G = oku(path.join(IS, 'kalip', 'ayirici-girdi-yeni.json')), es = oku(path.join(IS, 'kgk-konu-es.json')).esleme, P = oku(path.join(IS, 'konu-profil-gercek.json')).konu;
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').trim();
const kume = k => { const e = es[katla(k)] || es[k]; return e ? e.k : k; };
const konu = process.argv[2], n = +(process.argv[3] || 12); if (!konu) { console.log('kullanım: node kart-ornek.js "<konu>" [n]'); process.exit(1); }
const p = P[konu]; if (!p) { console.log('profilde yok: ' + konu); process.exit(1); }
const kal = {}; for (const x of p.sorular) kal[`${x.donem}|${x.no}`] = x.kalip;
const L = G.filter(q => kume(q.konu) === konu && kal[`${q.donem}|${q.no}`] !== undefined).slice(-n);
console.log(`${konu} · ${p.modul} · ${p.sorular.length} çıkmış soru (gösterilen ${L.length})\n`);
for (const q of L) console.log(`[${q.donem} S${q.no} · kalıp ${kal[`${q.donem}|${q.no}`]} · cevap ${q.cevap}]\n${q.kok}\n${q.siklar.map((s, i) => '  ' + 'ABCDE'[i] + ') ' + s).join('\n')}\n`);
