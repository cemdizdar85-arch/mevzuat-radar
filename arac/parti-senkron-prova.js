// arac/parti-senkron-prova.js — parti indirmenin HIZLI yolu ile ESKİ yolunun eşdeğerlik kıyası (03.10.2026)
// node arac/parti-senkron-prova.js <eskiKlasor> <yeniKlasor> [--mutasyon]
// Her iki klasördeki kalip-parti-*.json dosyaları AYRIŞTIRILIR ve alan alan (derin) kıyaslanır. Biçim (girinti, \u kaçışı)
// farkı sayılmaz; değer farkı sayılır. Eski yol PS ConvertTo-Json -Depth 20 ile yazar: 20'den derin yapı orada metne
// dönüşür - böyle bir fark çıkarsa "ESKI-DERINLIK" diye ayrı raporlanır (hızlı yolun düzelttiği, eski yolun kusuru).
// Çıkış 0: hepsi aynı (ya da yalnız ESKI-DERINLIK) · 1: değer farkı ya da eksik dosya.
'use strict';
const fs = require('fs'), path = require('path');
const [eski, yeni] = process.argv.slice(2, 4); const MUT = process.argv.includes('--mutasyon');
if (!eski || !yeni) { console.log('kullanim: node arac/parti-senkron-prova.js <eskiKlasor> <yeniKlasor>'); process.exit(2); }
const liste = d => fs.readdirSync(d).filter(f => /^kalip-parti-.*\.json$/.test(f)).sort();
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
function fark(a, b, yol, sonuc) {
  if (sonuc.length > 3) return;
  if (typeof a !== typeof b || Array.isArray(a) !== Array.isArray(b) || (a === null) !== (b === null)) {
    if (typeof a === 'string' && b && typeof b === 'object' && /^System\.|^@\{/.test(a)) sonuc.push(['ESKI-DERINLIK', yol]); else sonuc.push(['DEGER', yol]);
    return;
  }
  if (a && typeof a === 'object') {
    const ka = Object.keys(a), kb = Object.keys(b);
    for (const k of new Set([...ka, ...kb])) { if (!(k in a) || !(k in b)) { sonuc.push(['ALAN', yol + '.' + k]); continue; } fark(a[k], b[k], yol + '.' + k, sonuc); }
    return;
  }
  if (a !== b) sonuc.push(['DEGER', yol]);
}
const le = liste(eski), ly = liste(yeni);
let ayni = 0, derin = 0, kotu = 0; const ornek = [];
const eksik = le.filter(f => !ly.includes(f)).concat(ly.filter(f => !le.includes(f)));
for (const f of le.filter(f => ly.includes(f))) {
  let a, b; try { a = oku(path.join(eski, f)); b = oku(path.join(yeni, f)); } catch (e) { kotu++; ornek.push(f + ' AYRISTIRILAMADI ' + e.message.slice(0, 60)); continue; }
  if (MUT && ayni === 0) { const k = Object.keys(b)[0]; if (k) b[k] = { bozuk: true }; }
  const s = []; fark(a, b, '', s);
  if (!s.length) ayni++;
  else if (s.every(x => x[0] === 'ESKI-DERINLIK')) { derin++; if (ornek.length < 6) ornek.push(f + ' ESKI-DERINLIK ' + s[0][1]); }
  else { kotu++; if (ornek.length < 6) ornek.push(f + ' ' + s.map(x => x[0] + ' ' + x[1]).join(' ; ')); }
}
console.log('PARTI SENKRON PROVASI: eski ' + le.length + ' · yeni ' + ly.length + ' · aynı ' + ayni + ' · eski-derinlik ' + derin + ' · FARK ' + kotu + ' · eksik ' + eksik.length);
ornek.forEach(x => console.log('  ' + x)); eksik.slice(0, 5).forEach(x => console.log('  EKSIK ' + x));
process.exit(kotu || eksik.length ? 1 : 0);
