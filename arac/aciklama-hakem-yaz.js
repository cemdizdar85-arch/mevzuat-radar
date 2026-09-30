#!/usr/bin/env node
// arac/aciklama-hakem-yaz.js — açıklama hakemi kararını parti kayıtlarına yazar (30.09.2026, Cem "b yap")
// PowerShell ConvertTo-Json dizileri bozduğu için yazım Node'da (arac/onarim-hatti.js ile aynı biçim: BOM korunur, 4 boşluk girinti).
//   node arac/aciklama-hakem-yaz.js <kararlar.json>     kararlar: { "<etiket>": { "<kp>": {karar, kusurlar, model, tarih} } }
//   node arac/aciklama-hakem-yaz.js --sinav            öz-sınav (geçici klasörde)
// Yalnız 'aciklama_hakem' alanı eklenir/değişir; kaydın başka hiçbir alanına dokunulmaz (yazmadan önce ölçülür, fark varsa DURUR).
// Ekrana yalnız sayı basılır (günlük public olabilir). 🚫 GÖRMEZ: kararın doğruluğu (hakemin işi).
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const KOK = path.resolve(__dirname, '..');
const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
function yaz(kararlar, fabrika) {
  const s = { yazilan: 0, parti: 0, kayit_yok: 0 };
  for (const et of Object.keys(kararlar)) {
    const pf = path.join(fabrika, 'kalip-parti-' + et + '.json');
    if (!fs.existsSync(pf)) { s.kayit_yok += Object.keys(kararlar[et]).length; continue; }
    const ham = fs.readFileSync(pf, 'utf8'), bom = ham.charCodeAt(0) === 0xfeff, j = JSON.parse(ham.replace(/^﻿/, ''));
    const once = JSON.parse(JSON.stringify(j)); let n = 0;
    for (const kp of Object.keys(kararlar[et])) { if (!j[kp]) { s.kayit_yok++; continue; } j[kp].aciklama_hakem = kararlar[et][kp]; if (process.env.AHYAZ_MUTASYON === 'baska-alan') j[kp].soru = 'bozuk'; n++; }
    if (!n) continue;
    // güvenlik: aciklama_hakem dışında hiçbir şey değişmemeli
    for (const kp of Object.keys(once)) { const a = Object.assign({}, once[kp]), b = Object.assign({}, j[kp]); if (a && typeof a === 'object') { delete a.aciklama_hakem; delete b.aciklama_hakem; }
      if (JSON.stringify(kan(a)) !== JSON.stringify(kan(b))) throw new Error('beklenmeyen fark: ' + et + '/' + kp); }
    fs.writeFileSync(pf, (bom ? '﻿' : '') + JSON.stringify(j, null, 4)); s.yazilan += n; s.parti++;
  }
  return s;
}
if (process.argv[2] === '--sinav') {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ahyaz-')); let g = 0, t = 0; const T = (ad, ok) => { t++; if (ok) g++; console.log((ok ? '  ✓ ' : '  ✗ ') + ad); };
  const P = { 'kp-01': { soru: 'x', siklar: { A: '1' }, adimlar: [{ a: 1 }], bosluk: [[0, 1]] }, 'kp-02': { soru: 'y', aciklama_hakem: { karar: 'KUSURLU' } } };
  fs.writeFileSync(path.join(d, 'kalip-parti-et1.json'), '﻿' + JSON.stringify(P, null, 4));
  const r = yaz({ et1: { 'kp-01': { karar: 'TEMIZ' }, 'kp-02': { karar: 'TEMIZ' }, 'kp-99': { karar: 'TEMIZ' } }, yok: { 'kp-01': {} } }, d);
  const Y = JSON.parse(fs.readFileSync(path.join(d, 'kalip-parti-et1.json'), 'utf8').replace(/^﻿/, ''));
  T('iki kayıt yazıldı, olmayanlar sayıldı', r.yazilan === 2 && r.kayit_yok === 2);
  T('karar yazıldı / üstüne yazıldı', Y['kp-01'].aciklama_hakem.karar === 'TEMIZ' && Y['kp-02'].aciklama_hakem.karar === 'TEMIZ');
  T('diziler korundu (tek elemanlı dizi)', Array.isArray(Y['kp-01'].adimlar) && Array.isArray(Y['kp-01'].bosluk[0]));
  T('BOM korundu', fs.readFileSync(path.join(d, 'kalip-parti-et1.json'), 'utf8').charCodeAt(0) === 0xfeff);
  let dur = false; try { process.env.AHYAZ_MUTASYON = 'baska-alan'; yaz({ et1: { 'kp-01': { karar: 'KUSURLU' } } }, d); } catch (e) { dur = /beklenmeyen fark/.test(e.message); } finally { delete process.env.AHYAZ_MUTASYON; }
  T('başka alanı değiştiren yazım DURDURULUR (mutasyon)', dur && JSON.parse(fs.readFileSync(path.join(d, 'kalip-parti-et1.json'), 'utf8').replace(/^﻿/, ''))['kp-01'].soru === 'x');
  fs.rmSync(d, { recursive: true, force: true });
  console.log('AH-YAZ-SINAVI: ' + (g === t ? 'YESIL' : 'KIRMIZI') + ' — ' + g + '/' + t); process.exit(g === t ? 0 : 1);
}
if (require.main === module) {
  const k = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^﻿/, ''));
  const s = yaz(k, path.join(KOK, 'veri', 'fabrika'));
  console.log('AÇIKLAMA HAKEMİ YAZ: ' + s.yazilan + ' kayıt · ' + s.parti + ' parti · kayıtsız ' + s.kayit_yok);
}
module.exports = { yaz };
