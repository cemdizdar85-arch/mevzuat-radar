// ÖNBELLEK BÖLÜCÜ (08.09, Tur 1 hız kazası): kalip-parti-<etiket>.json içindeki soru kayıtlarını iki dosyaya ayırır ki iki üretici süreci
// aynı etiketin kalan fazlarını (adım, giriş, ikiz, sim, hakem, kör, hakem2) PARALEL koşabilsin. Aynı dosyaya iki süreç yazamaz (CacheYaz bütünü yazar).
//   A yarısı  : orijinal dosyada kalır  → koşucu satırı `pilot` = A id'leri
//   B yarısı  : <etiket>-b dosyasına gider → yeni koşucu satırı, aynı konu dosyası (id numaralama korunur), `pilot` = B id'leri
// Neden node: PS 5.1 ConvertTo-Json iç dizileri {value,Count} sarmalına çevirir (07.09 kazası) — fabrika json'u PS ile yeniden yazılmaz.
// Kullanım: node arac/onbellek-bol.js veri/fabrika/kalip-parti-sgs-t1-fmuh-kolay.json  → stdout: JSON {a:[ids], b:[ids]}
const fs = require('fs');
const yol = process.argv[2];
if (!yol) { console.error('kullanım: node onbellek-bol.js <kalip-parti-etiket.json>'); process.exit(1); }
const ham = fs.readFileSync(yol, 'utf8').replace(/^﻿/, '');
const c = JSON.parse(ham);
const ids = Object.keys(c).filter(k => c[k] && c[k].soru);
ids.sort((x, y) => x.localeCompare(y, 'en', { numeric: true }));
const yarim = Math.ceil(ids.length / 2);
const a = ids.slice(0, yarim), b = ids.slice(yarim);
const ca = {}, cb = {};
for (const k of Object.keys(c)) { if (b.includes(k)) cb[k] = c[k]; else ca[k] = c[k]; }
const bYol = yol.replace(/\.json$/i, '-b.json');
if (fs.existsSync(bYol)) { console.error('B dosyası zaten var, bölünmedi: ' + bYol); process.exit(2); }
fs.writeFileSync(yol + '.bolme-yedek', ham, 'utf8');
fs.writeFileSync(bYol, JSON.stringify(cb, null, 2), 'utf8');
fs.writeFileSync(yol, JSON.stringify(ca, null, 2), 'utf8');
console.log(JSON.stringify({ toplam: ids.length, a, b, bYol }));
