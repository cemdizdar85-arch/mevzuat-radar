// DAR KAPIYI GECEN YENI TEBLIGLERI gtip-durum.json'a EKLER + 2025/9 duzeltmesi.
// Kapilar (hicbiri atlanmaz, atlanan kayit RAPORLANIR):
//   K1 teblig sitede zaten varsa DOKUNMA (elle okunmus veri daha zengin)
//   K2 kod + teblig cifti zaten varsa EKLEME (mukerrer olmaz)
//   K3 kod resmi Tarife Cetveli'nde yoksa EKLEME (uydurma kod girmesin)
//   K4 deger sayiya cevrilemiyorsa EKLEME
const fs = require('fs');
const KOK = (process.argv[2] || '.') + '/';
const HASAT = process.argv[3] || 'gozetim-hasat.json';
const J = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, ''));
const ham = J(HASAT);
const durum = J(KOK + 'veri/gtip-durum.json');
const tanim = J(KOK + 'veri/gtip-tanim.json');

const varOlanTeblig = new Set();
for (const k in durum) for (const r of (durum[k] || [])) if (r && r.teblig) varOlanTeblig.add(r.teblig);

const sayiya = s => { const m = String(s || '').match(/\d{1,3}(?:\.\d{3})*(?:,\d+)?|\d+(?:,\d+)?/); return m ? parseFloat(m[0].replace(/\./g, '').replace(',', '.')) : null; };
const url = mno => 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=' + mno + '&MevzuatTur=9&MevzuatTertip=5';

const yeni = Object.keys(ham).filter(t => ham[t].durum === 'OK' && !varOlanTeblig.has(t));
let eklenen = 0, atlanan = { mukerrer: 0, tgtcYok: [], degerYok: 0 }, tebligSay = 0;

for (const teb of yeni.sort()) {
  const h = ham[teb];
  const birim = (h.birim || 'ABD Doları/Kg').replace(/\*/g, '').replace(/Dolari/g, 'Doları').trim();
  let bu = 0;
  for (const kod in h.tablo) {
    if (!tanim[kod]) { atlanan.tgtcYok.push(teb + ':' + kod); continue; }
    if (sayiya(h.tablo[kod]) === null) { atlanan.degerYok++; continue; }
    durum[kod] = durum[kod] || [];
    if (durum[kod].some(r => r && r.teblig === teb)) { atlanan.mukerrer++; continue; }
    durum[kod].push({ deger: h.tablo[kod] + ' ' + birim, teblig: teb, kaynak: url(h.mno) });
    eklenen++; bu++;
  }
  if (bu) tebligSay++;
  console.log(teb.padEnd(9) + ' +' + bu + ' kod  (' + birim + ')');
}

// ---- 2025/9 DUZELTMESI (resmi birlesik metinden, RG-11/7/2026-33307 tablosu) ----
const D9 = {
  '4011.20.10.00.19': '6',
  '4011.20.90.00.11': '5',
  '4011.20.90.00.19': '5,5',
  '4011.40.00.00.00': '5'
};
let duzeltilen = 0;
for (const kod in D9) {
  for (const r of (durum[kod] || [])) {
    if (r && r.teblig === '2025/9' && sayiya(r.deger) !== sayiya(D9[kod])) {
      console.log('DUZELT ' + kod + ': "' + r.deger + '" → "' + D9[kod] + ' ABD Doları/Kg"');
      r.deger = D9[kod] + ' ABD Doları/Kg';
      duzeltilen++;
    }
  }
}
// TGTC'de olmayan kod: 4013.90.00.00.10 → resmi metinde 4013.90.00.00.11, 6 ABD Doları/Kg
if (durum['4013.90.00.00.10']) {
  const kalan = durum['4013.90.00.00.10'].filter(r => !r || r.teblig !== '2025/9');
  const cikan = durum['4013.90.00.00.10'].length - kalan.length;
  if (kalan.length) durum['4013.90.00.00.10'] = kalan; else delete durum['4013.90.00.00.10'];
  console.log('SIL 4013.90.00.00.10 (Tarife Cetveli\'nde yok) — ' + cikan + ' kayit');
  duzeltilen += cikan;
}
for (const [kod, deg] of [['4013.20.00.00.00', '3,5'], ['4013.90.00.00.11', '6']]) {
  durum[kod] = durum[kod] || [];
  if (!durum[kod].some(r => r && r.teblig === '2025/9')) {
    durum[kod].push({ deger: deg + ' ABD Doları/Kg', teblig: '2025/9', kaynak: url(42662) });
    console.log('EKLE ' + kod + ' → ' + deg + ' ABD Doları/Kg (2025/9)');
    duzeltilen++;
  }
}

fs.writeFileSync(KOK + 'veri/gtip-durum.json', JSON.stringify(durum));
const tebligler = new Set();
for (const k in durum) for (const r of (durum[k] || [])) if (r && r.teblig) tebligler.add(r.teblig);
console.log('\n=== SONUC ===');
console.log('yeni teblig: ' + tebligSay + ' | eklenen kayit: ' + eklenen + ' | duzeltme: ' + duzeltilen);
console.log('atlanan → mukerrer: ' + atlanan.mukerrer + ' | TGTC\'de yok: ' + atlanan.tgtcYok.length + (atlanan.tgtcYok.length ? ' (' + atlanan.tgtcYok.join(', ') + ')' : '') + ' | degersiz: ' + atlanan.degerYok);
console.log('gtip-durum.json → kod: ' + Object.keys(durum).length + ' | teblig: ' + tebligler.size);
