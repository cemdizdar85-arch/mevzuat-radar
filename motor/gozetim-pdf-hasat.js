// GOZETIM HASAT v3 — DAR KAPI.
// v2 sinavda 242 degeri dogru, 28'ini yanlis okudu. Yanlislarin hepsi ayni
// aileden: tabloda 12 haneli kodun yaninda POZISYON satiri (70.05, 70.06) ve
// "(... haric)" istisnalari var; deger o satirlara ait, alt kodlara degil.
// Bu yuzden v3 yalnizca BASIT tabloyu kabul eder:
//   - her kodun degeri KENDI satirinda olacak (tasima/devretme YOK)
//   - tablo bolgesinde pozisyon satiri (nn.nn) ya da "haric" gecmeyecek
//   - en az 1 kod cikacak
// Kapiyi gecemeyen teblig "ELLE OKUNACAK" diye ayrilir; uydurma yapilmaz.
const fs = require('fs'), cp = require('child_process'), path = require('path');
const KOK = process.argv[2] || '.';
const PDFDIR = process.argv[3] || 'pdf';
const CIKTI = process.argv[4] || 'gozetim-hasat.json';
const esleme = JSON.parse(fs.readFileSync(KOK + '/motor/hafiza/eslesme-gozetim.json', 'utf8').replace(/^\uFEFF/, '')).esleme;

const KOD = /(\d{4}\.\d{2}\.\d{2}\.\d{2}\.\d{2})/;
const POZ = /(^|\s)\d{4}\.\d{2}(\s|$)/;              // 7005.29 gibi pozisyon satiri
const POZ2 = /(^|\s)\d{2}\.\d{2}(\s|$)/;             // 70.05 gibi pozisyon satiri
const SAYI = /(\d{1,3}(?:\.\d{3})*(?:,\d+)?|\d+(?:,\d+)?)\s*$/;

function metin(mno) {
  const f = path.join(PDFDIR, mno + '.pdf');
  if (!fs.existsSync(f) || fs.statSync(f).size === 0) return null;
  try { return cp.execSync('pdftotext -enc UTF-8 -table "' + f + '" -', { encoding: 'utf8', maxBuffer: 1e9 }); }
  catch (e) { return null; }
}
function birimBul(t) {
  const m = t.match(/\(\s*(ABD\s*Dolar[ıi]\s*\/[^)\n]{1,40})\)/i);
  return m ? m[1].replace(/\s+/g, ' ').trim() : null;
}
// tablo bolgesi: ilk 12 haneli koddan, son 12 haneli kodun 2 satir sonrasina
function tabloBolgesi(t) {
  const satir = t.split(/\r?\n/);
  let ilk = -1, son = -1;
  satir.forEach((s, i) => { if (KOD.test(s)) { if (ilk < 0) ilk = i; son = i; } });
  return ilk < 0 ? [] : satir.slice(ilk, son + 3);
}

const sonuc = {};
for (const teb of Object.keys(esleme).filter(t => esleme[t])) {
  const mno = String(esleme[teb]);
  const t = metin(mno);
  if (!t || t.length < 200) { sonuc[teb] = { mno, durum: 'PDF-YOK' }; continue; }
  const no = teb.replace('/', '\\s*/\\s*');
  if (!new RegExp('NO\\s*:?\\s*' + no, 'i').test(t)) { sonuc[teb] = { mno, durum: 'KIMLIK-TUTMADI' }; continue; }

  const bolge = tabloBolgesi(t);
  const gerekce = [];
  if (!bolge.length) gerekce.push('tablo bulunamadi');
  const tablo = {};
  let tasima = 0;
  for (const s of bolge) {
    const k = s.match(KOD);
    if (!k) {
      if (POZ.test(s) || POZ2.test(s)) gerekce.push('pozisyon satiri');
      continue;
    }
    const sonrasi = s.slice(s.indexOf(k[1]) + k[1].length);
    const d = sonrasi.match(SAYI);
    if (d) tablo[k[1]] = d[1]; else tasima++;
  }
  const metinBolge = bolge.join('\n');
  if (/har[iı]ç/i.test(metinBolge)) gerekce.push('haric istisnasi');
  if (tasima > 0) gerekce.push(tasima + ' kod kendi satirinda degersiz');
  if (!Object.keys(tablo).length) gerekce.push('deger cikmadi');

  sonuc[teb] = gerekce.length
    ? { mno, durum: 'ELLE-OKUNACAK', gerekce: [...new Set(gerekce)], kismiKod: Object.keys(tablo).length }
    : { mno, durum: 'OK', birim: birimBul(t), kodAdedi: Object.keys(tablo).length, tablo };
}
fs.writeFileSync(CIKTI, JSON.stringify(sonuc, null, 1));
const say = {};
for (const t in sonuc) say[sonuc[t].durum] = (say[sonuc[t].durum] || 0) + 1;
console.log('BITTI ' + JSON.stringify(say));
